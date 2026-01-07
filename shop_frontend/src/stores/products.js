import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'

function devDuplicateProducts(items, times = 12) {
  if (!import.meta.env.DEV) return items
  if (!items?.length) return items

  const base = items[0]
  const out = []

  for (let i = 0; i < times; i++) {
    out.push({
      ...base,
      id: `${base.id}-dev-${i}`, // unique key for Vue
      name: `${base.name} (${i + 1})`, // so you see different cards
      slug: `${base.slug}-${i + 1}`,
    })
  }

  return out
}

export const useProductsStore = defineStore('products', {
  state: () => ({
    items: [], // array of products
    loading: false, // true while fetching
    error: null, // error message or null
  }),

  getters: {
    activeItems: (state) => state.items.filter((p) => p.is_active),
  },

  actions: {
    async fetchProducts() {
      this.loading = true
      this.error = null

      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        this.error = error.message
        this.items = []
      } else {
        // this.items = data ?? []
        this.items = devDuplicateProducts(data, 16)
      }

      this.loading = false
    },
  },
})
