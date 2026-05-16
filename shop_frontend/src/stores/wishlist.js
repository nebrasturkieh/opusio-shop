import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { showToast } from '@/lib/toast'

export const useWishlistStore = defineStore('wishlist', () => {
  const items = ref(JSON.parse(localStorage.getItem('wishlist_items') || '[]'))
  let _userId = null
  let _syncing = false

  // ── Getters ───────────────────────────────────────────────────────────────
  const count = computed(() => items.value.length)
  const hasProduct = computed(() => (id) => items.value.some((p) => String(p.id) === String(id)))
  const getProduct = computed(() => (id) => items.value.find((p) => String(p.id) === String(id)))

  // ── Local persistence (guests only) ──────────────────────────────────────
  function _saveLocal() {
    if (_userId) return
    try {
      localStorage.setItem('wishlist_items', JSON.stringify(items.value))
    } catch (e) {
      console.warn('Could not persist wishlist', e)
    }
  }

  // ── Called by auth store after confirmed login ────────────────────────────
  async function syncWithUser(userId) {
    if (_syncing || _userId === userId) return
    _syncing = true
    _userId = userId
    try {
      const guestItems = JSON.parse(localStorage.getItem('wishlist_items') || '[]')

      const { data: remoteRows, error } = await supabase
        .from('wishlist_items')
        .select('*')
        .eq('user_id', userId)

      if (error) throw error

      const remoteMap = {}
      for (const row of remoteRows ?? []) remoteMap[row.product_id] = row

      // Merge guest items not already in remote (no duplicates for wishlist)
      if (guestItems.length > 0) {
        const newItems = guestItems.filter((p) => !remoteMap[String(p.id)])
        if (newItems.length > 0) {
          const upserts = newItems.map((product) => ({
            user_id: userId,
            product_id: String(product.id),
            product_snapshot: product,
          }))
          const { error: upsertError } = await supabase
            .from('wishlist_items')
            .upsert(upserts, { onConflict: 'user_id,product_id' })
          if (upsertError) throw upsertError
          for (const product of newItems) {
            remoteMap[String(product.id)] = {
              product_id: String(product.id),
              product_snapshot: product,
            }
          }
        }
      }

      items.value = Object.values(remoteMap).map((row) => row.product_snapshot)
      localStorage.removeItem('wishlist_items')
    } catch (e) {
      console.warn('Wishlist sync error:', e)
      _userId = null // allow retry
    } finally {
      _syncing = false
    }
  }

  // ── Called by auth store on sign-out ──────────────────────────────────────
  function clearForUser() {
    _userId = null
    items.value = []
    localStorage.removeItem('wishlist_items')
  }

  // ── Wishlist operations ───────────────────────────────────────────────────
  async function add(product) {
    if (!product || !product.id) return
    if (hasProduct.value(product.id)) return
    items.value.push(product)
    showToast('Saved to your wishlist')
    _saveLocal()
    if (_userId) {
      await supabase
        .from('wishlist_items')
        .upsert(
          { user_id: _userId, product_id: String(product.id), product_snapshot: product },
          { onConflict: 'user_id,product_id' },
        )
    }
  }

  async function remove(productId) {
    items.value = items.value.filter((p) => String(p.id) !== String(productId))
    showToast('Removed from wishlist', 'info')
    _saveLocal()
    if (_userId) {
      await supabase
        .from('wishlist_items')
        .delete()
        .eq('user_id', _userId)
        .eq('product_id', String(productId))
    }
  }

  async function toggle(product) {
    if (!product || !product.id) return
    if (hasProduct.value(product.id)) await remove(product.id)
    else await add(product)
  }

  async function clear() {
    items.value = []
    localStorage.removeItem('wishlist_items')
    if (_userId) await supabase.from('wishlist_items').delete().eq('user_id', _userId)
  }

  return {
    items,
    count,
    hasProduct,
    getProduct,
    syncWithUser,
    clearForUser,
    add,
    remove,
    toggle,
    clear,
  }
})
