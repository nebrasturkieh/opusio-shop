<template>
  <div class="cart-page">
    <div class="cart-wrap">
      <!-- Header -->
      <header class="cart-header">
        <h1 class="cart-header-title">
          SHOPPING BAG
          <span class="cart-header-count"
            >({{ totalItems }} {{ totalItems === 1 ? 'Item' : 'Items' }})</span
          >
        </h1>
        <p class="cart-header-notice">
          Free exchange &amp; return within <strong>30 days</strong>.
        </p>
      </header>

      <!-- Filled cart -->
      <div v-if="items && items.length" class="cart-body">
        <!-- Line items -->
        <div class="cart-lines">
          <article v-for="item in items" :key="item.product.id" class="cart-line">
            <button
              class="cart-line-remove"
              type="button"
              aria-label="Remove"
              @click="remove(item.product.id)"
            >
              ×
            </button>

            <div class="cart-line-media">
              <img :src="lineImage(item.product)" :alt="item.product.name" class="cart-line-img" />
            </div>

            <div class="cart-line-info">
              <div class="cart-line-name">{{ item.product.name }}</div>
              <div v-if="item.product.description" class="cart-line-desc">
                {{ item.product.description }}
              </div>
              <div v-if="item.product.material" class="cart-line-attr">
                {{ item.product.material }}
              </div>
              <div v-if="item.product.collection" class="cart-line-attr">
                {{ item.product.collection }}
              </div>

              <div class="cart-line-bottom">
                <div class="cart-qty">
                  <button class="cart-qty-btn" type="button" @click="decrement(item.product.id)">
                    −
                  </button>
                  <span class="cart-qty-val">{{ item.quantity }}</span>
                  <button
                    class="cart-qty-btn"
                    type="button"
                    :disabled="
                      item.product.stock_quantity != null &&
                      item.quantity >= item.product.stock_quantity
                    "
                    @click="increment(item.product.id)"
                  >
                    +
                  </button>
                </div>
                <div class="cart-line-price">{{ formatPrice(item.product, item.quantity) }}</div>
              </div>
              <p
                v-if="
                  item.product.stock_quantity != null &&
                  item.product.stock_quantity <= 5 &&
                  item.product.stock_quantity > 0
                "
                class="cart-stock-warn"
              >
                Only {{ item.product.stock_quantity }} left
              </p>
            </div>
          </article>

          <!-- Continue shopping -->
          <div class="cart-continue">
            <router-link to="/#catalog" class="cart-continue-link">‹ CONTINUE SHOPPING</router-link>
          </div>
        </div>

        <!-- Sticky summary -->
        <aside class="cart-summary">
          <div class="cart-summary-row cart-summary-subtotal">
            <span class="cart-summary-label">SUBTOTAL</span>
            <span class="cart-summary-amount">{{ totalPriceFormatted }}</span>
          </div>
          <div class="cart-summary-vat">Includes VAT</div>

          <div class="cart-summary-divider"></div>

          <div class="cart-trust">
            <div class="cart-trust-item">
              <span class="cart-trust-icon">⚿</span>
              <span>Secured payment</span>
            </div>
            <div class="cart-trust-item">
              <span class="cart-trust-icon">↺</span>
              <span>30-day free returns &amp; exchanges</span>
            </div>
            <div class="cart-trust-item">
              <span class="cart-trust-icon">⇥</span>
              <span>Free express delivery</span>
            </div>
          </div>

          <button class="cart-checkout-btn" type="button" @click="goToCheckout">
            PROCEED TO CHECKOUT
          </button>
        </aside>
      </div>

      <!-- Empty state -->
      <div v-else class="cart-empty">
        <div class="cart-empty-title">Your bag is empty</div>
        <p class="cart-empty-sub">Discover our curated collections and add your favourites.</p>
        <router-link to="/#catalog" class="cart-empty-link">‹ CONTINUE SHOPPING</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import { useCartStore } from '@/stores/cart'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const cart = useCartStore()
const auth = useAuthStore()
const { items, totalItems, totalPrice } = storeToRefs(cart)

// Ensure the drawer is never blocking this page
onMounted(() => {
  cart.closeDrawer()
})

function goToCheckout() {
  if (!auth.isAuthenticated) {
    router.push({ name: 'auth', query: { redirect: '/checkout' } })
    return
  }
  router.push({ name: 'checkout' })
}

const totalPriceFormatted = computed(() =>
  formatPrice({ price_cents: totalPrice.value * 100, currency: 'EUR' }),
)

function lineImage(product) {
  if (product.image_url) return product.image_url
  if (Array.isArray(product.images) && product.images.length) return product.images[0]
  return ''
}

function formatPrice(p, qty = 1) {
  if (!p) return ''
  let cents = null
  if (p.price_cents != null) cents = Number(p.price_cents)
  else if (p.price != null) cents = Number(p.price) * 100
  if (cents == null || isNaN(cents)) return ''
  const amount = (cents / 100) * qty
  if (isNaN(amount)) return ''
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2,
    }).format(amount)
  } catch (e) {
    console.warn('Currency format error:', e)
    return `€${amount.toFixed(2)}`
  }
}

function increment(id) {
  cart.increment(id)
}
function decrement(id) {
  cart.decrement(id)
}
function remove(id) {
  cart.remove(id)
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.cart-page {
  background: #fff;
  min-height: 100vh;
  font-family: 'Lora', 'Georgia', serif;
}

.cart-wrap {
  max-width: 1000px;
  margin: 0 auto;
  padding: 72px 24px 100px;
}

/* ── header ── */
.cart-header {
  margin-bottom: 52px;
  text-align: center;
  padding-bottom: 0;
  border-bottom: none;
}

.cart-header-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  font-weight: 400;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 14px;
}

.cart-header-count {
  font-weight: 400;
  color: #7a6a59;
  margin-left: 8px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  letter-spacing: 0.12em;
}

.cart-header-notice {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
  margin: 0;
  letter-spacing: 0.01em;
  font-weight: 400;
}

.cart-header-notice strong {
  font-weight: 500;
  color: #5e4e3d;
}

/* ── two-column layout ── */
.cart-body {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 40px;
  align-items: start;
}

/* ── line items ── */
.cart-lines {
  display: flex;
  flex-direction: column;
  margin-bottom: 28px;
}

.cart-line {
  position: relative;
  display: flex;
  gap: 28px;
  padding: 32px 0;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.cart-line-remove {
  position: absolute;
  top: 32px;
  right: 0;
  background: none;
  border: none;
  font-size: 18px;
  color: #b8996a;
  cursor: pointer;
  line-height: 1;
  padding: 0;
  transition: color 0.15s;
}

.cart-line-remove:hover {
  color: #1a1a1a;
}

.cart-line-media {
  flex-shrink: 0;
  width: 100px;
  height: 100px;
  background: #f9f8f6;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(0, 0, 0, 0.04);
}

.cart-line-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

.cart-line-info {
  flex: 1;
  padding-right: 40px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.cart-line-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 400;
  text-transform: uppercase;
  letter-spacing: 0.11em;
  color: #1a1a1a;
  margin-bottom: 2px;
}

.cart-line-desc {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #7a6a59;
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.cart-line-attr {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  color: #9a8a79;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.cart-line-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 12px;
  gap: 16px;
}

.cart-line-price {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  letter-spacing: 0.02em;
}

/* ── qty ── */
.cart-qty {
  display: flex;
  align-items: center;
  gap: 0;
  border: 1px solid rgba(0, 0, 0, 0.1);
  background: #faf9f7;
}

.cart-qty-btn {
  width: 32px;
  height: 32px;
  background: none;
  border: none;
  cursor: pointer;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  transition: background 0.12s;
}

.cart-qty-btn:hover:not(:disabled) {
  background: rgba(0, 0, 0, 0.04);
}

.cart-qty-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.cart-stock-warn {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  letter-spacing: 0.08em;
  color: #b8996a;
  text-transform: uppercase;
  margin: 6px 0 0;
}

.cart-qty-val {
  width: 36px;
  text-align: center;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  border-left: 1px solid rgba(0, 0, 0, 0.08);
  border-right: 1px solid rgba(0, 0, 0, 0.08);
  line-height: 32px;
}

/* ── continue shopping ── */
.cart-continue {
  padding-top: 28px;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
}

.cart-continue-link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: #1a1a1a;
  text-decoration: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.3);
  padding-bottom: 2px;
  transition: opacity 0.15s;
}

.cart-continue-link:hover {
  opacity: 0.6;
}

/* ── summary sidebar ── */
.cart-summary {
  position: sticky;
  top: 24px;
  background: #faf9f7;
  border: 1px solid rgba(0, 0, 0, 0.06);
  padding: 32px 28px 28px;
}

.cart-summary-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.cart-summary-subtotal {
  margin-bottom: 10px;
}

.cart-summary-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: #5e4e3d;
}

.cart-summary-amount {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 18px;
  color: #1a1a1a;
  letter-spacing: 0.01em;
}

.cart-summary-vat {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  color: #b8996a;
  margin-bottom: 22px;
  letter-spacing: 0.04em;
}

.cart-summary-divider {
  height: 1px;
  background: rgba(0, 0, 0, 0.08);
  margin-bottom: 24px;
}

/* ── trust badges ── */
.cart-trust {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 28px;
}

.cart-trust-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #6b5b4a;
  letter-spacing: 0.03em;
}

.cart-trust-icon {
  font-size: 13px;
  color: #9a8a79;
  width: 18px;
  text-align: center;
  flex-shrink: 0;
}

/* ── checkout btn ── */
.cart-checkout-btn {
  width: 100%;
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 16px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  cursor: pointer;
  transition: background 0.18s;
  display: block;
}

.cart-checkout-btn:hover {
  background: #2a2a2a;
}

/* ── empty state ── */
.cart-empty {
  padding: 120px 0 80px;
  text-align: center;
}

.cart-empty-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 18px;
  font-weight: 400;
  letter-spacing: 0.08em;
  color: #1a1a1a;
  margin-bottom: 12px;
}

.cart-empty-sub {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #7a6a59;
  margin: 0 0 32px;
  line-height: 1.8;
}

.cart-empty-link {
  display: inline-block;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: #1a1a1a;
  text-decoration: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.3);
  padding-bottom: 2px;
  transition: opacity 0.15s;
}

.cart-empty-link:hover {
  opacity: 0.6;
}

/* ── responsive ── */
@media (max-width: 880px) {
  .cart-body {
    grid-template-columns: 1fr;
  }

  .cart-summary {
    position: static;
  }
}

@media (max-width: 520px) {
  .cart-wrap {
    padding: 60px 20px 80px;
  }

  .cart-header {
    margin-bottom: 40px;
  }

  .cart-header-title {
    font-size: 18px;
  }

  .cart-line {
    gap: 16px;
    padding: 24px 0;
  }

  .cart-line-media {
    width: 80px;
    height: 80px;
  }

  .cart-line-bottom {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
}
</style>
