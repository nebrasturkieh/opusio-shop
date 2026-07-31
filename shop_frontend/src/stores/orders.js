import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useOrdersStore = defineStore('orders', () => {
  const orders = ref([])
  const loading = ref(false)
  const error = ref(null)

  async function fetchOrders(userId) {
    if (!userId) return
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase
        .from('orders')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
      if (err) throw err
      orders.value = data ?? []
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function createOrder({ items, shippingAddress, idempotencyKey }) {
    // The caller (checkout boundary) must generate and own the idempotency
    // key for its logical checkout attempt. This store never generates one
    // itself, so a caller bug can't silently create a fresh key per retry.
    if (typeof idempotencyKey !== 'string' || idempotencyKey.trim() === '') {
      throw new Error('MISSING_IDEMPOTENCY_KEY')
    }
    const { data, error: err } = await supabase.rpc('place_order_atomic', {
      p_items: items,
      p_shipping: shippingAddress,
      p_idempotency_key: idempotencyKey,
      p_currency: 'EUR',
    })
    if (err) throw err
    // data = { id, total_cents, idempotent }
    return data
  }

  function clear() {
    orders.value = []
    error.value = null
  }

  return { orders, loading, error, fetchOrders, createOrder, clear }
})
