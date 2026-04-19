import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const session = ref(null)
  const profile = ref(null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const isAdmin = computed(() => (profile.value && profile.value.role === 'admin') || false)

  async function init() {
    loading.value = true
    // get initial session
    try {
      const {
        data: { session: curSession },
      } = await supabase.auth.getSession()
      session.value = curSession ?? null
      user.value = curSession?.user ?? null

      if (user.value) await fetchProfile(user.value.id)

      // listen to auth state changes
      supabase.auth.onAuthStateChange((_event, newSession) => {
        session.value = newSession ?? null
        user.value = newSession?.user ?? null
        if (user.value) {
          fetchProfile(user.value.id)
        } else {
          profile.value = null
        }
      })
    } finally {
      loading.value = false
    }
  }

  async function signInWithMagicLink(email) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signInWithOtp({ email })
      if (error) throw error
      return data
    } finally {
      loading.value = false
    }
  }

  async function signOut() {
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
      full_name: payload.full_name ?? null,
      avatar_url: payload.avatar_url ?? null,
      role: payload.role ?? 'user',
    }
    const { data, error } = await supabase.from('profiles').upsert(row, { returning: 'representation' }).select().single()
    if (error) throw error
    profile.value = data
    return data
  }

  return {
    user,
    session,
    profile,
    loading,
    init,
    signInWithMagicLink,
    signOut,
    fetchProfile,
    upsertProfile,
    isAuthenticated,
    isAdmin,
  }
})

export default useAuthStore
