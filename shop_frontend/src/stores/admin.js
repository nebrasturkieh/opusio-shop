import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAdminStore = defineStore('admin', () => {
  // ── Products ──────────────────────────────────────────────────────────────
  const products = ref([])
  const productsLoading = ref(false)
  const productsError = ref(null)

  async function fetchProducts() {
    productsLoading.value = true
    productsError.value = null
    const { data, error } = await supabase
      .from('products')
      .select('*, product_variants(*, variant_images(image_url, alt_text, role, sort_order))')
      .order('created_at', { ascending: false })
    productsLoading.value = false
    if (error) {
      productsError.value = error.message
      return
    }
    products.value = data
  }

  async function createProduct(payload) {
    const { data, error } = await supabase.from('products').insert([payload]).select().single()
    if (error) throw error
    await fetchProducts()
    return data
  }

  async function updateProduct(id, payload) {
    const { data, error } = await supabase
      .from('products')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    await fetchProducts()
    return data
  }

  async function deleteProduct(id) {
    const { error } = await supabase.from('products').delete().eq('id', id)
    if (error) throw error
    await fetchProducts()
  }

  // ── Storage ───────────────────────────────────────────────────────────────
  const BUCKET = 'product-images'

  async function uploadImage(file, pathPrefix = 'products') {
    const ext = file.name.split('.').pop().toLowerCase()
    const uid = `${Date.now()}-${Math.random().toString(36).slice(2)}`
    const path = `${pathPrefix}/${uid}.${ext}`
    const { error } = await supabase.storage.from(BUCKET).upload(path, file, {
      cacheControl: '3600',
      upsert: false,
    })
    if (error) throw error
    const { data } = supabase.storage.from(BUCKET).getPublicUrl(path)
    return data.publicUrl
  }

  // ── Variants ─────────────────────────────────────────────────────────────
  async function createVariant(payload) {
    const { data, error } = await supabase
      .from('product_variants')
      .insert([payload])
      .select()
      .single()
    if (error) throw error
    await fetchProducts()
    return data
  }

  async function updateVariant(id, payload) {
    const { data, error } = await supabase
      .from('product_variants')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    await fetchProducts()
    return data
  }

  async function deleteVariant(id) {
    const { error } = await supabase.from('product_variants').delete().eq('id', id)
    if (error) throw error
    await fetchProducts()
  }

  // ── Variant images ────────────────────────────────────────────────────────
  async function addVariantImage(payload) {
    // payload: { variant_id, image_url, alt_text?, role?, sort_order? }
    const { data, error } = await supabase
      .from('variant_images')
      .insert([payload])
      .select()
      .single()
    if (error) throw error
    await fetchProducts()
    return data
  }

  async function updateVariantImage(id, payload) {
    const { data, error } = await supabase
      .from('variant_images')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    await fetchProducts()
    return data
  }

  async function deleteVariantImage(id) {
    const { error } = await supabase.from('variant_images').delete().eq('id', id)
    if (error) throw error
    await fetchProducts()
  }

  // ── Orders ────────────────────────────────────────────────────────────────
  const orders = ref([])
  const ordersLoading = ref(false)
  const ordersError = ref(null)

  const ORDER_STATUSES = [
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  ]

  async function fetchOrders() {
    ordersLoading.value = true
    ordersError.value = null
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false })
    if (error) {
      ordersError.value = error.message
      ordersLoading.value = false
      return
    }

    // Fetch profile names separately — no FK exists between orders and profiles
    // (both reference auth.users.id, but PostgREST needs an explicit FK to join)
    const userIds = [...new Set(data.map((o) => o.user_id).filter(Boolean))]
    let profileMap = {}
    if (userIds.length) {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, full_name')
        .in('id', userIds)
      if (profiles) {
        profileMap = Object.fromEntries(profiles.map((p) => [p.id, p]))
      }
    }

    orders.value = data.map((o) => ({
      ...o,
      profiles: profileMap[o.user_id] ?? null,
    }))
    ordersLoading.value = false
  }

  async function updateOrderStatus(id, status) {
    const { data, error } = await supabase.rpc('admin_update_order_status', {
      p_order_id: id,
      p_status: status,
    })
    if (error) throw error
    const order = orders.value.find((o) => o.id === id)
    if (order) {
      order.status = data.status
      order.updated_at = data.updated_at
    }
  }

  // ── Dashboard stats ───────────────────────────────────────────────────────
  const stats = computed(() => ({
    totalProducts: products.value.length,
    activeProducts: products.value.filter((p) => p.is_active).length,
    totalOrders: orders.value.length,
    pendingOrders: orders.value.filter((o) => o.status === 'pending').length,
    revenue: orders.value
      .filter((o) => o.status !== 'cancelled')
      .reduce((sum, o) => sum + (o.total_cents ?? 0), 0),
  }))

  return {
    // products
    products,
    productsLoading,
    productsError,
    fetchProducts,
    createProduct,
    updateProduct,
    deleteProduct,
    // variants
    createVariant,
    updateVariant,
    deleteVariant,
    // images
    addVariantImage,
    updateVariantImage,
    deleteVariantImage,
    // storage
    uploadImage,
    // orders
    orders,
    ordersLoading,
    ordersError,
    ORDER_STATUSES,
    fetchOrders,
    updateOrderStatus,
    // dashboard
    stats,
  }
})
