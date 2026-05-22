<template>
  <!-- backdrop fades -->
  <transition name="fade">
    <div class="drawer-backdrop" v-if="cart.drawerOpen" @click="cart.closeDrawer"></div>
  </transition>

  <!-- drawer slides -->
  <transition name="drawer">
    <aside class="cart-drawer" v-if="cart.drawerOpen">
      <!-- header fixed -->
      <header class="drawer-header">
        <h2 class="drawer-title">
          SHOPPING BAG <span class="drawer-count">({{ totalItems }})</span>
        </h2>
        <button class="close-btn" @click="cart.closeDrawer" aria-label="Close">×</button>
      </header>

      <!-- scrollable body -->
      <div class="drawer-body">
        <div v-if="items.length" class="items-list">
          <div v-for="item in items" :key="item.variant.id" class="drawer-item">
            <button class="item-remove" @click="remove(item.variant.id)" aria-label="Remove item">
              ×
            </button>
            <div class="item-media">
              <img
                :src="item.variant.image_url || item.product?.image_url || ''"
                alt=""
                class="item-img"
              />
            </div>
            <div class="item-details">
              <div class="item-name">{{ item.product?.name }}</div>
              <div v-if="item.variant.material_color || item.variant.size" class="item-attr">
                {{ [item.variant.material_color, item.variant.size].filter(Boolean).join(' · ') }}
              </div>
              <div
                v-if="item.variant.stock_quantity != null && item.variant.stock_quantity <= 5"
                class="item-stock-warn"
              >
                Only {{ item.variant.stock_quantity }} left
              </div>
              <div class="item-bottom">
                <div class="item-qty">
                  <button class="qty-btn" @click="decrement(item.variant.id)">−</button>
                  <span class="qty-val">{{ item.quantity }}</span>
                  <button
                    class="qty-btn"
                    :disabled="item.quantity >= item.variant.stock_quantity"
                    @click="increment(item.variant.id)"
                  >
                    +
                  </button>
                </div>
                <div class="item-price">{{ formatCurrency(item.variant.price_cents / 100) }}</div>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="drawer-empty">
          <p>Your bag is empty</p>
        </div>
      </div>

      <!-- footer fixed -->
      <footer class="drawer-footer">
        <div class="subtotal-row">
          <span class="subtotal-label">SUBTOTAL</span>
          <span class="subtotal-amount">{{ totalPriceFormatted }}</span>
        </div>
        <div class="vat-note">Includes VAT</div>

        <div class="footer-divider"></div>

        <div class="trust-section">
          <div class="trust-item">
            <span class="trust-icon">⚿</span>
            <span>Secured payment</span>
          </div>
          <div class="trust-item">
            <span class="trust-icon">↺</span>
            <span>30-day free returns</span>
          </div>
          <div class="trust-item">
            <span class="trust-icon">⇥</span>
            <span>Free express delivery</span>
          </div>
        </div>

        <button class="checkout-btn" @click="goCheckout">Continue to shopping bag</button>
      </footer>
    </aside>
  </transition>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useCartStore } from '@/stores/cart'

const cart = useCartStore()
const router = useRouter()
const items = computed(() => cart.items)
const totalItems = computed(() => cart.totalItems)
const totalPriceFormatted = computed(() => formatCurrency(cart.totalPrice))

function formatCurrency(value) {
  if (value == null || isNaN(Number(value))) return ''
  const num = Number(value)
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: 'EUR',
      currencyDisplay: 'symbol',
      minimumFractionDigits: 2,
    }).format(num)
  } catch {
    return `€${num.toFixed(2)}`
  }
}

function increment(variantId) {
  cart.increment(variantId)
}
function decrement(variantId) {
  cart.decrement(variantId)
}
function remove(variantId) {
  cart.remove(variantId)
}

function goCheckout() {
  cart.closeDrawer()
  router.push({ name: 'cart' })
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

/* ── transitions ── */
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 200ms ease;
}

.drawer-enter-from,
.drawer-leave-to {
  transform: translateX(100%);
}

.drawer-enter-active,
.drawer-leave-active {
  transition: transform 300ms ease;
}

/* ── backdrop ── */
.drawer-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.28);
  z-index: 2990;
}

/* ── drawer ── */
.cart-drawer {
  position: fixed;
  top: 0;
  right: 0;
  width: 420px;
  max-width: 100%;
  height: 100%;
  background: #fff;
  display: flex;
  flex-direction: column;
  z-index: 3000;
}

/* ── header ── */
.drawer-header {
  position: relative;
  padding: 24px 28px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  flex-shrink: 0;
}

.drawer-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 16px;
  font-weight: 400;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0;
}

.drawer-count {
  font-size: 14px;
  color: #7a6a59;
  margin-left: 6px;
}

.close-btn {
  position: absolute;
  right: 20px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 28px;
  background: none;
  border: none;
  cursor: pointer;
  color: #b8996a;
  padding: 0;
  transition: color 0.15s;
}

.close-btn:hover {
  color: #1a1a1a;
}

/* ── body ── */
.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding: 20px 28px;
}

.items-list {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.drawer-item {
  position: relative;
  display: flex;
  gap: 16px;
  padding: 20px 0;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.item-remove {
  position: absolute;
  top: 16px;
  right: 0;
  background: none;
  border: none;
  font-size: 16px;
  color: #b8996a;
  cursor: pointer;
  padding: 0;
  transition: color 0.15s;
}

.item-remove:hover {
  color: #1a1a1a;
}

.item-media {
  width: 80px;
  height: 80px;
  flex-shrink: 0;
  background: #faf9f7;
  border: 1px solid rgba(0, 0, 0, 0.04);
  display: flex;
  align-items: center;
  justify-content: center;
}

.item-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.item-details {
  flex: 1;
  padding-right: 28px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.item-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  font-weight: 400;
  text-transform: uppercase;
  letter-spacing: 0.11em;
  color: #1a1a1a;
}

.item-desc {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.item-attr {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 9px;
  color: #9a8a79;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.item-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 8px;
  gap: 12px;
}

.item-qty {
  display: flex;
  align-items: center;
  gap: 0;
  border: 1px solid rgba(0, 0, 0, 0.1);
  background: #faf9f7;
}

.qty-btn {
  width: 28px;
  height: 28px;
  background: none;
  border: none;
  cursor: pointer;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #1a1a1a;
  transition: background 0.12s;
}

.qty-btn:hover {
  background: rgba(0, 0, 0, 0.04);
}

.qty-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.item-stock-warn {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 9px;
  color: #b8996a;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-top: 4px;
}

.qty-val {
  width: 32px;
  text-align: center;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
}

.item-price {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #1a1a1a;
  letter-spacing: 0.02em;
  flex-shrink: 0;
}

.drawer-empty {
  text-align: center;
  padding: 40px 20px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
}

.drawer-empty p {
  margin: 0;
}

/* ── footer ── */
.drawer-footer {
  padding: 20px 28px;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
  flex-shrink: 0;
}

.subtotal-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 6px;
}

.subtotal-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: #5e4e3d;
}

.subtotal-amount {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 16px;
  color: #1a1a1a;
  letter-spacing: 0.01em;
}

.vat-note {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  color: #b8996a;
  margin-bottom: 12px;
  letter-spacing: 0.04em;
}

.footer-divider {
  height: 1px;
  background: rgba(0, 0, 0, 0.08);
  margin-bottom: 12px;
}

.trust-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 16px;
}

.trust-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  color: #6b5b4a;
  letter-spacing: 0.03em;
}

.trust-icon {
  font-size: 11px;
  color: #9a8a79;
  width: 16px;
  text-align: center;
  flex-shrink: 0;
}

.checkout-btn {
  width: 100%;
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 13px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  cursor: pointer;
  transition: background 0.18s;
  display: block;
}

.checkout-btn:hover {
  background: #2a2a2a;
}

/* ── responsive ── */
@media (max-width: 640px) {
  .cart-drawer {
    width: 100%;
    max-width: 100%;
  }

  .drawer-header {
    padding: 20px 20px;
  }

  .drawer-body {
    padding: 16px 20px;
  }

  .drawer-footer {
    padding: 16px 20px;
  }

  .item-media {
    width: 70px;
    height: 70px;
  }

  .item-details {
    padding-right: 20px;
  }
}
</style>
