import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { showToast } from '@/lib/toast'

// Item shape: { variant: { ...product_variants cols, variant_images: [] }, product: { ...products cols }, quantity: N }
// Keyed on variant.id throughout.

export const useCartStore = defineStore('cart', () => {
  // Discard any old product_id-keyed items from localStorage on load
  const _stored = JSON.parse(localStorage.getItem('cart_items') || '[]')
  const items = ref(_stored.filter((i) => i.variant?.id != null))

  const drawerOpen = ref(false)
  let _userId = null
  let _syncing = false

  // ── Getters ───────────────────────────────────────────────────────────────
  const totalItems = computed(() => items.value.reduce((sum, i) => sum + i.quantity, 0))
  const totalPrice = computed(() =>
    items.value.reduce((sum, i) => sum + (Number(i.variant.price_cents) / 100) * i.quantity, 0),
  )
  const hasVariant = computed(
    () => (variantId) => items.value.some((i) => String(i.variant.id) === String(variantId)),
  )
  const getItem = computed(
    () => (variantId) => items.value.find((i) => String(i.variant.id) === String(variantId)),
  )

  // ── Local persistence (guests only) ──────────────────────────────────────
  function _saveLocal() {
    if (_userId) return
    try {
      localStorage.setItem('cart_items', JSON.stringify(items.value))
    } catch (e) {
      console.warn('Could not persist cart', e)
    }
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  function openDrawer() {
    drawerOpen.value = true
  }
  function closeDrawer() {
    drawerOpen.value = false
  }
  function toggleDrawer() {
    drawerOpen.value = !drawerOpen.value
  }

  // ── Called by auth store after confirmed login ────────────────────────────
  async function syncWithUser(userId) {
    if (_syncing || _userId === userId) return
    _syncing = true
    _userId = userId
    try {
      const guestItems = items.value.filter((i) => i.variant?.id != null)

      const { data: remoteRows, error } = await supabase
        .from('cart_items')
        .select(
          'variant_id, quantity, variant:product_variants(*, variant_images(image_url, alt_text, role, sort_order), product:products(*))',
        )
        .eq('user_id', userId)
        .not('variant_id', 'is', null)

      if (error) throw error

      const remoteMap = {}
      for (const row of remoteRows ?? []) {
        if (!row.variant) continue
        remoteMap[row.variant_id] = {
          variant: row.variant,
          product: row.variant.product,
          quantity: row.quantity,
        }
      }

      // Merge guest items into remote, preferring higher quantity
      if (guestItems.length > 0) {
        const upserts = guestItems.map((guestItem) => {
          const vid = guestItem.variant.id
          const existing = remoteMap[vid]
          const mergedQty = existing ? existing.quantity + guestItem.quantity : guestItem.quantity
          remoteMap[vid] = {
            variant: guestItem.variant,
            product: guestItem.product,
            quantity: mergedQty,
          }
          return {
            user_id: userId,
            variant_id: vid,
            quantity: mergedQty,
            product_snapshot: guestItem.product,
            updated_at: new Date().toISOString(),
          }
        })
        const { error: upsertError } = await supabase
          .from('cart_items')
          .upsert(upserts, { onConflict: 'user_id,variant_id' })
        if (upsertError) throw upsertError
      }

      items.value = Object.values(remoteMap)
      localStorage.removeItem('cart_items')
    } catch (e) {
      console.warn('Cart sync error:', e)
      _userId = null
    } finally {
      _syncing = false
    }
  }

  // ── Called by auth store on sign-out ──────────────────────────────────────
  function clearForUser() {
    _userId = null
    items.value = []
    localStorage.removeItem('cart_items')
  }

  // ── add ──────────────────────────────────────────────────────────────────
  async function add(variant, product, quantity = 1) {
    if (!variant?.id || quantity <= 0) return
    const existing = items.value.find((i) => String(i.variant.id) === String(variant.id))
    const stock = variant.stock_quantity
    let newQty

    if (existing) {
      const uncapped = existing.quantity + quantity
      newQty = Math.min(uncapped, stock)
      if (newQty === existing.quantity) return // already at cap
      existing.quantity = newQty
    } else {
      newQty = Math.min(quantity, stock)
      items.value.push({ variant, product, quantity: newQty })
    }

    showToast('Added to your bag')
    _saveLocal()

    if (_userId) {
      await supabase.from('cart_items').upsert(
        {
          user_id: _userId,
          variant_id: variant.id,
          quantity: newQty,
          product_snapshot: product,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,variant_id' },
      )
    }
  }

  // ── remove ────────────────────────────────────────────────────────────────
  async function remove(variantId) {
    items.value = items.value.filter((i) => String(i.variant.id) !== String(variantId))
    _saveLocal()
    if (_userId) {
      await supabase.from('cart_items').delete().eq('user_id', _userId).eq('variant_id', variantId)
    }
  }

  // ── setQuantity ───────────────────────────────────────────────────────────
  async function setQuantity(variantId, quantity) {
    if (quantity <= 0) {
      await remove(variantId)
      return
    }
    const item = items.value.find((i) => String(i.variant.id) === String(variantId))
    if (item) {
      item.quantity = quantity
      _saveLocal()
      if (_userId) {
        await supabase.from('cart_items').upsert(
          {
            user_id: _userId,
            variant_id: variantId,
            quantity,
            product_snapshot: item.product,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'user_id,variant_id' },
        )
      }
    }
  }

  // ── increment / decrement ─────────────────────────────────────────────────
  async function increment(variantId, amount = 1) {
    const item = items.value.find((i) => String(i.variant.id) === String(variantId))
    if (!item) return
    if (item.quantity >= item.variant.stock_quantity) return
    await setQuantity(variantId, item.quantity + amount)
  }

  async function decrement(variantId, amount = 1) {
    const item = items.value.find((i) => String(i.variant.id) === String(variantId))
    if (item) await setQuantity(variantId, item.quantity - amount)
  }

  // ── clear ─────────────────────────────────────────────────────────────────
  async function clear() {
    items.value = []
    localStorage.removeItem('cart_items')
    if (_userId) await supabase.from('cart_items').delete().eq('user_id', _userId)
  }

  return {
    items,
    drawerOpen,
    totalItems,
    totalPrice,
    hasVariant,
    getItem,
    openDrawer,
    closeDrawer,
    toggleDrawer,
    syncWithUser,
    clearForUser,
    add,
    remove,
    setQuantity,
    increment,
    decrement,
    clear,
  }
})
