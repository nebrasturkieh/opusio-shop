import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { showToast } from '@/lib/toast'

export const useCartStore = defineStore('cart', () => {
  const items = ref(JSON.parse(localStorage.getItem('cart_items') || '[]'))
  const drawerOpen = ref(false)
  let _userId = null // null = guest; set after successful sync
  let _syncing = false

  // ── Getters ───────────────────────────────────────────────────────────────
  const totalItems = computed(() => items.value.reduce((sum, i) => sum + i.quantity, 0))
  const totalPrice = computed(() =>
    items.value.reduce((sum, i) => {
      const p = i.product
      let price = 0
      if (p?.price_cents != null) price = Number(p.price_cents) / 100
      else if (p?.price != null) price = Number(p.price)
      return sum + price * i.quantity
    }, 0),
  )
  const hasProduct = computed(
    () => (id) => items.value.some((i) => String(i.product.id) === String(id)),
  )
  const getItem = computed(
    () => (id) => items.value.find((i) => String(i.product.id) === String(id)),
  )

  // ── Local persistence (guests only) ──────────────────────────────────────
  function _saveLocal() {
    if (_userId) return // authenticated users persist via Supabase only
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
    _userId = userId // set early so subsequent add/remove go to Supabase
    try {
      const guestItems = JSON.parse(localStorage.getItem('cart_items') || '[]')

      const { data: remoteRows, error } = await supabase
        .from('cart_items')
        .select('*')
        .eq('user_id', userId)

      if (error) throw error // don't wipe local state on failure

      const remoteMap = {}
      for (const row of remoteRows ?? []) remoteMap[row.product_id] = row

      // Batch-merge guest items into remote
      if (guestItems.length > 0) {
        const upserts = guestItems.map((guestItem) => {
          const pid = String(guestItem.product.id)
          const existing = remoteMap[pid]
          const mergedQty = existing ? existing.quantity + guestItem.quantity : guestItem.quantity
          remoteMap[pid] = {
            ...(existing ?? {}),
            product_id: pid,
            quantity: mergedQty,
            product_snapshot: guestItem.product,
          }
          return {
            user_id: userId,
            product_id: pid,
            quantity: mergedQty,
            product_snapshot: guestItem.product,
            updated_at: new Date().toISOString(),
          }
        })
        const { error: upsertError } = await supabase
          .from('cart_items')
          .upsert(upserts, { onConflict: 'user_id,product_id' })
        if (upsertError) throw upsertError
      }

      items.value = Object.values(remoteMap).map((row) => ({
        product: row.product_snapshot,
        quantity: row.quantity,
      }))
      localStorage.removeItem('cart_items')
    } catch (e) {
      console.warn('Cart sync error:', e)
      _userId = null // allow retry on next call
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

  // ── Cart operations ───────────────────────────────────────────────────────
  async function add(product, quantity = 1) {
    if (!product || !product.id || quantity <= 0) return
    const existing = items.value.find((i) => String(i.product.id) === String(product.id))
    const stock = product?.stock_quantity
    let newQty
    if (existing) {
      const uncapped = existing.quantity + quantity
      newQty = stock != null ? Math.min(uncapped, stock) : uncapped
      if (newQty === existing.quantity) return // already at cap, don't toast
      existing.quantity = newQty
    } else {
      newQty = stock != null ? Math.min(quantity, stock) : quantity
      items.value.push({ product, quantity: newQty })
    }
    showToast('Added to your bag')
    _saveLocal()
    if (_userId) {
      await supabase.from('cart_items').upsert(
        {
          user_id: _userId,
          product_id: String(product.id),
          quantity: newQty,
          product_snapshot: product,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,product_id' },
      )
    }
  }

  async function remove(productId) {
    items.value = items.value.filter((i) => String(i.product.id) !== String(productId))
    _saveLocal()
    if (_userId) {
      await supabase
        .from('cart_items')
        .delete()
        .eq('user_id', _userId)
        .eq('product_id', String(productId))
    }
  }

  async function setQuantity(productId, quantity) {
    if (quantity <= 0) {
      await remove(productId)
      return
    }
    const item = items.value.find((i) => String(i.product.id) === String(productId))
    if (item) {
      item.quantity = quantity
      _saveLocal()
      if (_userId) {
        await supabase.from('cart_items').upsert(
          {
            user_id: _userId,
            product_id: String(productId),
            quantity,
            product_snapshot: item.product,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'user_id,product_id' },
        )
      }
    }
  }

  async function increment(productId, amount = 1) {
    const item = items.value.find((i) => String(i.product.id) === String(productId))
    if (!item) return
    const stock = item.product?.stock_quantity
    if (stock != null && item.quantity >= stock) return // cap at available stock
    await setQuantity(productId, item.quantity + amount)
  }

  async function decrement(productId, amount = 1) {
    const item = items.value.find((i) => String(i.product.id) === String(productId))
    if (item) await setQuantity(productId, item.quantity - amount)
  }

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
    hasProduct,
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
