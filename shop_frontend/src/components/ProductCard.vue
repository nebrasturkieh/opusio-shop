<template>
  <div
    class="p-card"
    :class="{ 'p-card--wishlist': isWishlist }"
    role="link"
    tabindex="0"
    @click="openDetails"
    @keydown.enter="openDetails"
    @mouseenter="hover = !isWishlist"
    @mouseleave="onLeave"
  >
    <div class="p-media">
      <!-- Heart (hover only, not in wishlist) or X for remove in wishlist -->
      <button
        v-if="!isWishlist"
        class="p-heart"
        :class="{ 'p-heart--show': hover, 'p-heart--active': isWishlisted }"
        type="button"
        :aria-label="isWishlisted ? 'Remove from wishlist' : 'Add to wishlist'"
        @click="toggleWishlist"
      >
        <v-icon :icon="isWishlisted ? 'mdi-heart' : 'mdi-heart-outline'" size="18" />
      </button>

      <button
        v-else
        class="p-remove"
        type="button"
        aria-label="Remove from wishlist"
        @click.stop="handleRemove"
      >
        <v-icon icon="mdi-close" size="18" />
      </button>

      <!-- Carousel arrows (hover only, only if multiple images) -->
      <button
        v-if="hasCarousel"
        class="p-nav p-nav--left"
        :class="{ 'p-nav--show': hover || isWishlist }"
        type="button"
        aria-label="Previous image"
        @click.stop="prev"
      >
        <v-icon icon="mdi-chevron-left" size="18" />
      </button>

      <button
        v-if="hasCarousel"
        class="p-nav p-nav--right"
        :class="{ 'p-nav--show': hover || isWishlist }"
        type="button"
        aria-label="Next image"
        @click.stop="next"
      >
        <v-icon icon="mdi-chevron-right" size="18" />
      </button>

      <!-- Image (switches on hover carousel) -->
      <img :src="currentImage" alt="" class="p-img" />

      <!-- Optional: tiny progress bar like Cartier (hover only) -->
      <div
        v-if="hasCarousel"
        class="p-progress"
        :class="{ 'p-progress--show': hover || isWishlist }"
      >
        <span class="p-progress-fill" :style="{ width: progressWidth }" />
      </div>
    </div>

    <div class="p-body">
      <div class="p-title">{{ product.name }}</div>
      <div class="p-sub">{{ product.material || ' ' }}</div>

      <!-- Price always visible (as you requested) -->
      <div class="p-price">{{ formatPrice(product) }}</div>

      <!-- Low stock warning -->
      <div
        v-if="
          product.stock_quantity != null &&
          product.stock_quantity <= 5 &&
          product.stock_quantity > 0
        "
        class="p-stock-warn"
      >
        Only {{ product.stock_quantity }} left
      </div>

      <!-- reserved space: NEVER changes height -->
      <div class="p-actions">
        <button
          class="p-btn"
          :class="{ 'p-btn--show': hover || isWishlist, 'p-btn--oos': !inStock }"
          :disabled="!inStock"
          @click="addToBag"
        >
          {{ inStock ? 'ADD TO BAG' : 'OUT OF STOCK' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useCartStore } from '@/stores/cart'
import { useWishlistStore } from '@/stores/wishlist'

const router = useRouter()
const wishlist = useWishlistStore()

const props = defineProps({
  product: { type: Object, required: true },
  isWishlist: { type: Boolean, default: false },
  onRemove: { type: Function, default: null },
})

function openDetails() {
  router.push({ name: 'product', params: { id: props.product.id } })
}
const hover = ref(false)
const idx = ref(0)

const isWishlisted = computed(() => wishlist.hasProduct(props.product.id))

const inStock = computed(() => {
  const stock = props.product?.stock_quantity
  if (stock == null) return true // NULL = unlimited
  const cartItem = cart.getItem(props.product.id)
  const inCartQty = cartItem?.quantity ?? 0
  return stock > inCartQty
})

function toggleWishlist(event) {
  event.stopPropagation()
  wishlist.toggle(props.product)
}

const images = computed(() => {
  const p = props.product || {}

  // Try common fields
  const arr =
    (Array.isArray(p.images) && p.images) || (Array.isArray(p.image_urls) && p.image_urls) || []

  // Normalize + fallback
  const normalized = arr.filter(Boolean)
  if (normalized.length > 0) return normalized

  return p.image_url ? [p.image_url] : []
})

const hasCarousel = computed(() => images.value.length > 1)

const currentImage = computed(() => {
  if (images.value.length === 0) return ''
  const safe = ((idx.value % images.value.length) + images.value.length) % images.value.length
  return images.value[safe]
})

const progressWidth = computed(() => {
  const n = images.value.length
  if (n <= 1) return '0%'
  const safe = ((idx.value % n) + n) % n
  return `${((safe + 1) / n) * 100}%`
})

function prev() {
  idx.value = idx.value - 1
}
function next() {
  idx.value = idx.value + 1
}

function onLeave() {
  hover.value = false
  idx.value = 0 // optional: reset to first image (Cartier-like)
}

function handleRemove(event) {
  // stop propagation just in case; ensure clicking X only removes
  event.stopPropagation()
  if (props.onRemove && props.product) {
    props.onRemove(props.product.id)
  }
}

// cart logic
const cart = useCartStore()
function addToBag(event) {
  // prevent the card click handler from firing
  event.stopPropagation()
  if (props.product && inStock.value) {
    cart.add(props.product)
  }
}

function formatPrice(p) {
  if (p == null) return ''
  // determine numeric euro amount
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
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

/* Card: border exists BEFORE hover (soft) */
.p-card {
  background: #fff;
  border-radius: 0;
  overflow: hidden;
  border: 1px solid rgba(0, 0, 0, 0.06);

  transition:
    border-color 260ms ease,
    box-shadow 260ms ease,
    transform 260ms ease;
}

.p-card:hover {
  border-color: rgba(0, 0, 0, 0.12);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}

.p-card--wishlist:hover {
  border-color: rgba(0, 0, 0, 0.14);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.04);
  transform: translateY(-1px);
}

.p-card--wishlist {
  border-radius: 8px;
  border: 1px solid rgba(0, 0, 0, 0.08);
}

/* Media */
.p-media {
  position: relative;
  background: #ffffff;
  padding: 26px;
}

.p-card--wishlist .p-media {
  padding: 18px;
}

.p-card--wishlist .p-img {
  max-height: 120px;
}

.p-img {
  width: 100%;
  display: block;
  object-fit: contain;
}

/* Heart (top-right) */
.p-heart {
  position: absolute;
  top: 14px;
  right: 14px;

  width: 34px;
  height: 34px;
  border-radius: 999px;

  border: 1px solid rgba(0, 0, 0, 0.1);
  background: rgba(255, 255, 255, 0.9);
  color: rgba(0, 0, 0, 0.72);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);

  display: grid;
  place-items: center;

  opacity: 0;
  transform: translateY(-6px);
  pointer-events: none;

  transition:
    opacity 220ms ease,
    transform 220ms ease,
    color 220ms ease,
    background 220ms ease,
    border-color 220ms ease,
    box-shadow 220ms ease;
}

.p-heart:hover {
  background: rgba(255, 255, 255, 0.98);
  border-color: rgba(0, 0, 0, 0.2);
}

.p-heart--show {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.p-heart--active {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
  background: rgba(212, 175, 55, 0.14);
  border-color: rgba(212, 175, 55, 0.45);
  color: #8a6a2a;
  box-shadow: 0 4px 12px rgba(138, 106, 42, 0.2);
}

/* Remove button for wishlist */
.p-remove {
  position: absolute;
  top: 12px;
  right: 12px;

  width: 30px;
  height: 30px;
  border-radius: 999px;

  border: 1px solid rgba(0, 0, 0, 0.12);
  background: rgba(255, 255, 255, 0.9);
  box-shadow: none;

  display: grid;
  place-items: center;

  opacity: 1;
  transform: none;
  pointer-events: auto;

  transition:
    opacity 220ms ease,
    transform 220ms ease,
    color 220ms ease,
    background 220ms ease,
    border-color 220ms ease;
}

.p-remove:hover {
  background: rgba(0, 0, 0, 0.04);
  border-color: rgba(0, 0, 0, 0.2);
}

/* Carousel arrows */
.p-nav {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);

  width: 34px;
  height: 34px;
  border-radius: 999px;

  border: 0;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);

  display: grid;
  place-items: center;

  opacity: 0;
  pointer-events: none;

  transition: opacity 220ms ease;
}

.p-nav--left {
  left: 14px;
}
.p-nav--right {
  right: 14px;
}

.p-nav--show {
  opacity: 1;
  pointer-events: auto;
}

/* Tiny bottom progress bar (hover only) */
.p-progress {
  position: absolute;
  left: 26px;
  right: 26px;
  bottom: 10px;

  height: 2px;
  background: rgba(0, 0, 0, 0.18);

  opacity: 0;
  transition: opacity 220ms ease;
}
.p-progress--show {
  opacity: 1;
}
.p-progress-fill {
  display: block;
  height: 100%;
  background: rgba(0, 0, 0, 0.75);
  width: 0%;
  transition: width 220ms ease;
}

/* Body */
.p-body {
  padding: 16px 18px 18px;
  text-align: center;
}

.p-card--wishlist .p-body {
  padding: 12px 14px 14px;
}

.p-card--wishlist .p-title {
  font-size: 11px;
  letter-spacing: 0.1em;
  margin-top: 4px;
}

.p-card--wishlist .p-sub {
  font-size: 10px;
  margin-top: 6px;
  color: #7a6a59;
}

.p-card--wishlist .p-price {
  font-size: 12px;
  margin-top: 10px;
}

.p-card--wishlist .p-actions {
  height: 46px;
  margin-top: 14px;
}

.p-card--wishlist .p-btn {
  height: 38px;
  max-width: 220px;
  font-size: 11px;
  letter-spacing: 0.12em;
}

.p-title {
  font-family: 'Lora', 'Georgia', serif;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-size: 12px;
  font-weight: 400;
  line-height: 1.35;
  margin-top: 2px;
  color: #1a1a1a;
}

.p-sub {
  margin-top: 6px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  opacity: 1;
}

.p-price {
  margin-top: 10px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  font-weight: 400;
  letter-spacing: 0.02em;
  color: #1a1a1a;
}

.p-stock-warn {
  margin-top: 4px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 9px;
  color: #b8996a;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

/* Reserved slot so hover NEVER pushes other cards */
.p-actions {
  height: 52px;
  margin-top: 14px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.p-btn {
  width: 100%;
  max-width: 240px;
  height: 46px;

  border: 1px solid #000;
  background: #000;
  color: #fff;

  letter-spacing: 0.14em;
  text-transform: uppercase;
  font-size: 12px;

  opacity: 0;
  transform: translateY(10px);
  pointer-events: none;

  transition:
    opacity 240ms ease,
    transform 240ms ease;
}

.p-btn--show {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.p-btn--oos {
  background: #999;
  border-color: #999;
  cursor: not-allowed;
}
</style>
