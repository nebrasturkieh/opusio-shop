<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useProductsStore } from '@/stores/products'
import { useCartStore } from '@/stores/cart'

const route = useRoute()
const router = useRouter()
const productsStore = useProductsStore()
const cart = useCartStore()

const id = computed(() => String(route.params.id ?? ''))
const quantity = ref(1)

// Reset qty when product changes
watch(id, () => {
  quantity.value = 1
})

// Stock helpers
const stockQty = computed(() => {
  const s = product.value?.stock_quantity
  return s == null ? Infinity : Number(s)
})
const inStock = computed(() => stockQty.value > 0)
const lowStock = computed(
  () => stockQty.value !== Infinity && stockQty.value <= 5 && stockQty.value > 0,
)

// Ensure we have products if user opens /product/:id directly
onMounted(async () => {
  if (!productsStore.activeItems?.length) {
    await productsStore.fetchProducts()
  }
})

// Find product
const product = computed(() =>
  (productsStore.activeItems || []).find((p) => String(p.id) === id.value),
)

watch(
  product,
  (p) => {
    if (p?.name) document.title = `${p.name} — Opusio`
  },
  { immediate: true },
)

const relatedItems = computed(() => {
  const current = product.value
  if (!current) return []

  const pool = (productsStore.activeItems || []).filter((p) => String(p.id) !== String(current.id))

  const sameCategory = pool.filter(
    (p) => p.category && current.category && p.category === current.category,
  )
  const sameCollection = pool.filter(
    (p) =>
      p.collection &&
      current.collection &&
      p.collection === current.collection &&
      !sameCategory.includes(p),
  )
  const rest = pool.filter((p) => !sameCategory.includes(p) && !sameCollection.includes(p))

  return [...sameCategory, ...sameCollection, ...rest].slice(0, 4)
})

// Normalize images
const images = computed(() => {
  const p = product.value || {}
  const arr =
    (Array.isArray(p.images) && p.images) || (Array.isArray(p.image_urls) && p.image_urls) || []
  const normalized = arr.filter(Boolean)
  if (normalized.length) return normalized
  return p.image_url ? [p.image_url] : []
})

// Gallery state
const activeIndex = ref(0)

watch(images, (imgs) => {
  // reset when product changes
  if (!imgs?.length) activeIndex.value = 0
  else activeIndex.value = Math.min(activeIndex.value, imgs.length - 1)
})

const activeImage = computed(() => images.value[activeIndex.value] || '')

function prev() {
  if (!images.value.length) return
  activeIndex.value = (activeIndex.value - 1 + images.value.length) % images.value.length
}
function next() {
  if (!images.value.length) return
  activeIndex.value = (activeIndex.value + 1) % images.value.length
}

function formatPrice(p) {
  if (p == null) return ''
  let amount = 0
  if (p.price_cents != null) {
    amount = Number(p.price_cents) / 100
  } else if (p.price != null) {
    amount = Number(p.price)
  }
  if (isNaN(amount)) return ''
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: 'EUR',
    currencyDisplay: 'symbol',
    minimumFractionDigits: 2,
  }).format(amount)
}

function goBack() {
  router.back()
}

function addToBag() {
  if (product.value && inStock.value) {
    cart.add(product.value, quantity.value)
    quantity.value = 1
  }
}

function goToProduct(productId) {
  router.push({ name: 'product', params: { id: productId } })
}
</script>

<template>
  <v-container class="pdp" fluid>
    <div class="pdp-inner">
      <div v-if="!product" class="pdp-loading">Loading…</div>

      <div v-else class="pdp-grid">
        <div class="pdp-toolbar">
          <button class="pdp-back" type="button" @click="goBack">Back to collection</button>
        </div>

        <!-- LEFT: Gallery -->
        <div class="pdp-gallery">
          <!-- main image -->
          <div class="pdp-main">
            <button
              v-if="images.length > 1"
              class="pdp-nav pdp-nav--left"
              type="button"
              aria-label="Previous"
              @click="prev"
            >
              ‹
            </button>

            <button
              v-if="images.length > 1"
              class="pdp-nav pdp-nav--right"
              type="button"
              aria-label="Next"
              @click="next"
            >
              ›
            </button>

            <img :src="activeImage" alt="" class="pdp-img" />
          </div>

          <!-- thumbnails -->
          <div v-if="images.length > 1" class="pdp-thumbs">
            <button
              v-for="(img, i) in images"
              :key="img + i"
              class="thumb"
              :class="{ active: i === activeIndex }"
              type="button"
              @click="activeIndex = i"
            >
              <img :src="img" alt="" />
            </button>
          </div>
        </div>

        <!-- RIGHT: Product info -->
        <div class="pdp-info">
          <div class="pdp-name">{{ product.name }}</div>
          <div class="pdp-sub">{{ product.material || product.category || '' }}</div>

          <div class="pdp-price">{{ formatPrice(product) }}</div>

          <!-- Quantity selector -->
          <div class="pdp-qty">
            <span class="pdp-qty-label">QTY</span>
            <div class="pdp-qty-control">
              <button
                class="pdp-qty-btn"
                type="button"
                :disabled="quantity <= 1"
                aria-label="Decrease quantity"
                @click="quantity > 1 && quantity--"
              >
                −
              </button>
              <span class="pdp-qty-num">{{ quantity }}</span>
              <button
                class="pdp-qty-btn"
                type="button"
                aria-label="Increase quantity"
                :disabled="quantity >= stockQty"
                @click="quantity < stockQty && quantity++"
              >
                +
              </button>
            </div>
          </div>

          <div class="pdp-meta">
            <div class="pdp-meta-item">
              <span class="pdp-meta-label">Material</span>
              <span class="pdp-meta-value">{{ product.material || 'Fine jewelry' }}</span>
            </div>
            <div class="pdp-meta-item">
              <span class="pdp-meta-label">Collection</span>
              <span class="pdp-meta-value">{{ product.collection || 'Signature' }}</span>
            </div>
          </div>

          <div class="pdp-divider"></div>

          <div class="pdp-desc">
            {{ product.description || 'No description yet.' }}
          </div>

          <button class="pdp-btn" type="button" :disabled="!inStock" @click="addToBag">
            {{ inStock ? 'ADD TO BAG' : 'OUT OF STOCK' }}
          </button>
          <p v-if="lowStock" class="pdp-stock-warn">Only {{ stockQty }} left</p>
        </div>
      </div>

      <section v-if="product && relatedItems.length" class="pdp-related">
        <div class="pdp-related-head">
          <h2 class="pdp-related-title">You may also like</h2>
          <p class="pdp-related-sub">Curated pieces selected from the same universe.</p>
        </div>

        <div class="pdp-related-grid">
          <article
            v-for="item in relatedItems"
            :key="item.id"
            class="pdp-related-card"
            @click="goToProduct(item.id)"
          >
            <div class="pdp-related-media">
              <img :src="item.image_url || item.images?.[0] || ''" alt="" class="pdp-related-img" />
            </div>
            <div class="pdp-related-name">{{ item.name }}</div>
            <div class="pdp-related-price">{{ formatPrice(item) }}</div>
          </article>
        </div>
      </section>
    </div>
  </v-container>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.pdp {
  background: #fff;
}
.pdp-inner {
  max-width: 1240px;
  margin: 0 auto;
  padding: 34px 22px 90px;
}

.pdp-loading {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #6b5b4a;
  opacity: 0.9;
}

.pdp-grid {
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 48px;
  align-items: start;
}

.pdp-toolbar {
  grid-column: 1 / -1;
  margin-bottom: -6px;
}

@media (max-width: 960px) {
  .pdp-grid {
    grid-template-columns: 1fr;
    gap: 26px;
  }

  .pdp-toolbar {
    margin-bottom: 0;
  }
}

/* ===== Gallery ===== */
.pdp-main {
  position: relative;
  background: linear-gradient(180deg, #fdfdfc 0%, #f8f7f5 100%);
  border: 1px solid rgba(0, 0, 0, 0.08);
  border-radius: 0;
  padding: 34px;
}

.pdp-img {
  width: 100%;
  display: block;
  object-fit: contain;
}

/* nav arrows */
.pdp-nav {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 34px;
  height: 34px;
  border-radius: 999px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  background: rgba(255, 255, 255, 0.92);
  box-shadow: 0 6px 14px rgba(0, 0, 0, 0.06);
  cursor: pointer;
  font-size: 20px;
  line-height: 34px;
  transition: all 0.2s ease;
}

.pdp-nav:hover {
  background: #fff;
  border-color: rgba(0, 0, 0, 0.2);
}

.pdp-nav--left {
  left: 14px;
}
.pdp-nav--right {
  right: 14px;
}

/* back */
.pdp-back {
  border: 0;
  background: transparent;
  cursor: pointer;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  opacity: 0.68;
  padding: 0;
  text-decoration: underline;
  text-underline-offset: 3px;
  transition: opacity 0.2s ease;
}

.pdp-back:hover {
  opacity: 1;
}

/* thumbs */
.pdp-thumbs {
  margin-top: 16px;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.thumb {
  width: 64px;
  height: 64px;
  border-radius: 0;
  border: 1px solid rgba(0, 0, 0, 0.1);
  background: #fff;
  padding: 8px;
  cursor: pointer;
  opacity: 0.78;
  transition:
    opacity 180ms ease,
    border-color 180ms ease;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

.thumb:hover {
  opacity: 1;
}

.thumb.active {
  opacity: 1;
  border-color: rgba(212, 175, 55, 0.6);
}

/* ===== Info ===== */
.pdp-info {
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: linear-gradient(180deg, #fff 0%, #fbfaf8 100%);
  padding: 34px 30px;
}

.pdp-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 17px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #111;
}

.pdp-sub {
  margin-top: 10px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  letter-spacing: 0.08em;
  color: #6b5b4a;
}

.pdp-price {
  margin-top: 18px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 17px;
  letter-spacing: 0.03em;
  color: #111;
}

/* quantity selector */
.pdp-qty {
  margin-top: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.pdp-qty-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #7a6a59;
}

.pdp-qty-control {
  display: flex;
  align-items: center;
  border: 1px solid rgba(0, 0, 0, 0.14);
}

.pdp-qty-btn {
  width: 36px;
  height: 36px;
  background: transparent;
  border: none;
  cursor: pointer;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 16px;
  color: #1a1a1a;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s;
  border-radius: 0;
}
.pdp-qty-btn:hover:not(:disabled) {
  background: rgba(0, 0, 0, 0.04);
}
.pdp-qty-btn:disabled {
  color: #ccc;
  cursor: not-allowed;
}

.pdp-qty-num {
  width: 36px;
  text-align: center;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  border-left: 1px solid rgba(0, 0, 0, 0.1);
  border-right: 1px solid rgba(0, 0, 0, 0.1);
  line-height: 36px;
  user-select: none;
}

.pdp-meta {
  margin-top: 16px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.pdp-meta-item {
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: rgba(255, 255, 255, 0.72);
  padding: 10px 12px;
}

.pdp-meta-label {
  display: block;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.09em;
  color: #7a6a59;
  margin-bottom: 6px;
}

.pdp-meta-value {
  display: block;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
}

.pdp-divider {
  height: 1px;
  background: rgba(0, 0, 0, 0.12);
  margin: 20px 0 22px;
}

.pdp-desc {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  line-height: 1.75;
  color: #5e5145;
}

.pdp-btn {
  margin-top: 26px;
  width: 100%;
  height: 46px;
  border: 1px solid #000;
  background: #000;
  color: #fff;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.pdp-btn:hover:not(:disabled) {
  background: #1f1f1f;
}

.pdp-btn:disabled {
  background: #9e9e9e;
  border-color: #9e9e9e;
  cursor: not-allowed;
}

.pdp-stock-warn {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  letter-spacing: 0.08em;
  color: #b8996a;
  text-transform: uppercase;
  margin: 10px 0 0;
  text-align: center;
}

.pdp-related {
  grid-column: 1 / -1;
  margin-top: 34px;
}

.pdp-related-head {
  margin-bottom: 14px;
}

.pdp-related-title {
  margin: 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 0.13em;
  color: #1a1a1a;
}

.pdp-related-sub {
  margin: 8px 0 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
}

.pdp-related-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.pdp-related-card {
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: linear-gradient(180deg, #fff 0%, #fbfaf8 100%);
  padding: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.pdp-related-card:hover {
  border-color: rgba(212, 175, 55, 0.5);
  transform: translateY(-1px);
}

.pdp-related-media {
  background: #f9f8f6;
  padding: 10px;
}

.pdp-related-img {
  width: 100%;
  height: 120px;
  object-fit: contain;
  display: block;
}

.pdp-related-name {
  margin-top: 12px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.09em;
  color: #1a1a1a;
}

.pdp-related-price {
  margin-top: 8px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #5e5145;
}

@media (max-width: 960px) {
  .pdp-inner {
    padding-top: 24px;
  }

  .pdp-main {
    padding: 24px;
  }

  .pdp-info {
    padding: 28px 22px;
  }

  .pdp-related-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 600px) {
  .thumb {
    width: 56px;
    height: 56px;
  }

  .pdp-meta {
    grid-template-columns: 1fr;
  }

  .pdp-related-grid {
    grid-template-columns: 1fr;
  }
}
</style>
