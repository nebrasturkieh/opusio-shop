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

  async function createOrder({ items, shippingAddress }) {
    const idempotencyKey = crypto.randomUUID()
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
