<template>
  <teleport to="body">
    <transition name="search-fade">
      <div v-if="modelValue" class="search-overlay" @keydown.esc="close" @click.self="close">
        <div class="search-panel">
          <!-- Search input -->
          <div class="search-bar">
            <svg
              class="search-icon"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <circle cx="8.5" cy="8.5" r="5.5" stroke="#1a1a1a" stroke-width="1.3" />
              <line
                x1="12.7"
                y1="12.7"
                x2="17.5"
                y2="17.5"
                stroke="#1a1a1a"
                stroke-width="1.3"
                stroke-linecap="square"
              />
            </svg>
            <input
              ref="inputEl"
              v-model="query"
              class="search-input"
              type="text"
              placeholder="Search pieces, materials, collections…"
              autocomplete="off"
              @keydown.enter="goFirst"
            />
            <button class="search-close" type="button" aria-label="Close search" @click="close">
              ✕
            </button>
          </div>

          <!-- Results -->
          <div class="search-results-wrap">
            <p v-if="query.length > 0 && results.length === 0" class="search-empty">
              No pieces found for "<em>{{ query }}</em
              >"
            </p>

            <ul v-else-if="results.length > 0" class="search-results">
              <li
                v-for="product in results"
                :key="product.id"
                class="search-result"
                @click="goToProduct(product)"
              >
                <div class="result-img-wrap">
                  <img :src="resultImage(product)" alt="" class="result-img" />
                </div>
                <div class="result-info">
                  <div class="result-name">{{ product.name }}</div>
                  <div class="result-meta">{{ product.category || '' }}</div>
                </div>
                <div class="result-price">{{ formatPrice(product) }}</div>
              </li>
            </ul>

            <!-- Idle state: show trending categories -->
            <div v-else class="search-idle">
              <p class="idle-label">BROWSE BY CATEGORY</p>
              <ul class="idle-cats">
                <li v-for="cat in categories" :key="cat" class="idle-cat" @click="queryCat(cat)">
                  {{ cat }}
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useProductsStore } from '@/stores/products'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue'])

const router = useRouter()
const productsStore = useProductsStore()
const inputEl = ref(null)
const query = ref('')

function close() {
  emit('update:modelValue', false)
}

// Focus input when opened
watch(
  () => props.modelValue,
  async (open) => {
    if (open) {
      query.value = ''
      await nextTick()
      inputEl.value?.focus()
    }
  },
)

const allProducts = computed(() => productsStore.activeItems || [])

const categories = computed(() => {
  const uniq = new Set(allProducts.value.map((p) => p.category).filter(Boolean))
  return [...uniq].sort()
})

const results = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return []
  return allProducts.value
    .filter((p) => {
      return (
        p.name?.toLowerCase().includes(q) ||
        p.collection?.toLowerCase().includes(q) ||
        p.category?.toLowerCase().includes(q) ||
        p.description?.toLowerCase().includes(q)
      )
    })
    .slice(0, 12)
})

function firstActiveVariant(product) {
  return (product.product_variants ?? []).find((v) => v.is_active) ?? null
}

function resultImage(product) {
  const v = firstActiveVariant(product)
  if (v?.image_url) return v.image_url
  // fallback: product-level images kept as SEO/hero fallback
  if (product.image_url) return product.image_url
  if (Array.isArray(product.images) && product.images.length) return product.images[0]
  return ''
}

function formatPrice(product) {
  const vs = (product.product_variants ?? []).filter((v) => v.is_active)
  const cents = vs.length
    ? Math.min(...vs.map((v) => v.price_cents).filter((c) => c != null))
    : null
  if (cents == null || !isFinite(cents)) return ''
  const prefix = vs.length > 1 ? 'from ' : ''
  try {
    return (
      prefix +
      new Intl.NumberFormat(undefined, {
        style: 'currency',
        currency: 'EUR',
        minimumFractionDigits: 2,
      }).format(cents / 100)
    )
  } catch {
    return `${prefix}€${(cents / 100).toFixed(2)}`
  }
}

function goToProduct(product) {
  close()
  router.push({ name: 'product', params: { id: product.id } })
}

function goFirst() {
  if (results.value.length) goToProduct(results.value[0])
}

function queryCat(cat) {
  query.value = cat
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

/* overlay */
.search-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.46);
  z-index: 3000;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 80px;
}

.search-panel {
  width: 100%;
  max-width: 680px;
  background: #fff;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.16);
}

/* search bar */
.search-bar {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px 24px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.search-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
  opacity: 0.5;
}

.search-input {
  flex: 1;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  border: none;
  outline: none;
  background: transparent;
  letter-spacing: 0.02em;
}

.search-input::placeholder {
  color: #b8b2ab;
  font-style: italic;
}

.search-close {
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 14px;
  color: #7a6a59;
  padding: 4px;
  line-height: 1;
  transition: color 0.15s;
  flex-shrink: 0;
}
.search-close:hover {
  color: #1a1a1a;
}

/* results area */
.search-results-wrap {
  max-height: 420px;
  overflow-y: auto;
  overscroll-behavior: contain;
}

.search-results {
  list-style: none;
  padding: 0;
  margin: 0;
}

.search-result {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 24px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: background 0.12s;
}
.search-result:hover {
  background: rgba(184, 153, 106, 0.05);
}
.search-result:last-child {
  border-bottom: none;
}

.result-img-wrap {
  width: 52px;
  height: 52px;
  flex-shrink: 0;
  background: #f5f3f0;
}

.result-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.result-info {
  flex: 1;
  min-width: 0;
}

.result-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: #1a1a1a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.result-meta {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  margin-top: 3px;
}

.result-price {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  white-space: nowrap;
  flex-shrink: 0;
}

/* empty */
.search-empty {
  padding: 28px 24px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
  text-align: center;
  margin: 0;
}

/* idle / categories */
.search-idle {
  padding: 24px;
}

.idle-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #7a6a59;
  margin: 0 0 14px;
}

.idle-cats {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.idle-cat {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #1a1a1a;
  padding: 7px 14px;
  border: 1px solid rgba(0, 0, 0, 0.12);
  cursor: pointer;
  transition:
    border-color 0.15s,
    background 0.15s;
  border-radius: 0;
}
.idle-cat:hover {
  border-color: #b8996a;
  background: rgba(184, 153, 106, 0.05);
}

/* transition */
.search-fade-enter-active,
.search-fade-leave-active {
  transition: opacity 0.2s ease;
}
.search-fade-enter-from,
.search-fade-leave-to {
  opacity: 0;
}
</style>
