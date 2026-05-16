import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useCartStore } from './cart'
import { useWishlistStore } from './wishlist'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const session = ref(null)
  const profile = ref(null)
  const loading = ref(false)
  const initialized = ref(false)
  let authStateSubscription = null

  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => (profile.value && profile.value.role === 'admin') || false)

  function normalizeText(value) {
    if (typeof value !== 'string') return null
    const trimmed = value.trim()
    return trimmed || null
  }

  function getProfileSeed(targetUser) {
    const metadata = targetUser?.user_metadata ?? {}
    const firstName = normalizeText(metadata.first_name) ?? ''
    const lastName = normalizeText(metadata.last_name) ?? ''
    const fallbackFullName = `${firstName} ${lastName}`.trim()
    const fullName = normalizeText(metadata.full_name) || fallbackFullName || null

    return {
      full_name: fullName,
      role: 'user',
    }
  }

  async function ensureProfile(targetUser = user.value) {
    if (!targetUser?.id) return null

    const existingProfile = await fetchProfile(targetUser.id)
    if (existingProfile) return existingProfile

    const row = {
      id: targetUser.id,
      ...getProfileSeed(targetUser),
    }

    const { data, error } = await supabase
      .from('profiles')
      .upsert(row, { onConflict: 'id' })
      .select()
      .single()

    if (error) throw error

    profile.value = data
    return data
  }

  function _triggerSync(userId) {
    try {
      void useCartStore().syncWithUser(userId)
      void useWishlistStore().syncWithUser(userId)
    } catch {
      // sync errors are non-fatal
    }
  }

  async function refreshSession() {
    const {
      data: { session: curSession },
    } = await supabase.auth.getSession()

    session.value = curSession ?? null
    user.value = curSession?.user ?? null

    if (user.value) {
      try {
        await ensureProfile(user.value)
      } catch {
        // Keep auth session usable even if profile sync fails temporarily.
        profile.value = null
      }
      _triggerSync(user.value.id)
    } else {
      profile.value = null
    }
  }

  async function init() {
    if (initialized.value) return
    loading.value = true
    // get initial session
    try {
      await refreshSession()

      // listen to auth state changes
      if (!authStateSubscription) {
        const { data } = supabase.auth.onAuthStateChange((event, newSession) => {
          session.value = newSession ?? null
          user.value = newSession?.user ?? null
          if (user.value) {
            void ensureProfile(user.value).catch(() => {
              profile.value = null
            })
            if (event === 'SIGNED_IN') {
              _triggerSync(user.value.id)
            }
          } else {
            profile.value = null
          }
        })
        authStateSubscription = data.subscription
      }

      initialized.value = true
    } finally {
      loading.value = false
    }
  }

  async function signUpWithPassword(email, password) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      })
      if (error) throw error
      return data
    } finally {
      loading.value = false
    }
  }

  async function signInWithPassword(email, password) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })
      if (error) throw error
      return data
    } finally {
      loading.value = false
    }
  }

  async function resetPassword(email) {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/callback?type=recovery`,
    })
    if (error) throw error
  }

  async function signOut() {
    try {
      useCartStore().clearForUser()
      useWishlistStore().clearForUser()
    } catch {
      // ignore
    }
    await supabase.auth.signOut()
    user.value = null
    session.value = null
    profile.value = null
  }

  async function fetchProfile(id) {
    if (!id) return null
    loading.value = true
    try {
      const { data, error } = await supabase.from('profiles').select('*').eq('id', id).single()
      if (error && error.code !== 'PGRST116') {
        // ignore no rows
        // console.warn('fetchProfile error', error)
      }
      profile.value = data ?? null
      return profile.value
    } finally {
      loading.value = false
    }
  }

  async function upsertProfile(payload) {
    if (!user.value) throw new Error('No authenticated user')
    const row = {
      id: user.value.id,
      full_name: normalizeText(payload.full_name),
      phone: normalizeText(payload.phone),
      address: normalizeText(payload.address),
      city: normalizeText(payload.city),
      country: normalizeText(payload.country),
      role: payload.role ?? 'user',
    }
    const { data, error } = await supabase
      .from('profiles')
      .upsert(row, { returning: 'representation' })
      .select()
      .single()
    if (error) throw error
    profile.value = data
    return data
  }

  return {
    user,
    session,
    profile,
    loading,
    initialized,
    init,
    refreshSession,
    ensureProfile,
    signUpWithPassword,
    signInWithPassword,
    signOut,
    resetPassword,
    fetchProfile,
    upsertProfile,
    isAuthenticated,
    isAdmin,
  }
})
