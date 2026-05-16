import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'

export const useProductsStore = defineStore('products', {
  state: () => ({
    items: [],
    loading: false,
    error: null,
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
        this.items = data ?? []
      }

      this.loading = false
    },
  },
})
