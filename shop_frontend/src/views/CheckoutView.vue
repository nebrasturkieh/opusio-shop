<template>
  <div class="checkout-page">
    <div class="checkout-wrap">
      <header class="checkout-header">
        <h1 class="checkout-title">CHECKOUT</h1>
        <router-link to="/cart" class="checkout-back">‹ Back to bag</router-link>
      </header>

      <div class="checkout-body">
        <!-- LEFT: steps -->
        <div class="checkout-main">
          <!-- Step 1: Delivery address -->
          <section class="checkout-section">
            <h2 class="section-title"><span class="section-num">1</span> DELIVERY ADDRESS</h2>

            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Full name</label>
                <input
                  v-model="form.full_name"
                  class="form-input"
                  type="text"
                  autocomplete="name"
                  required
                />
                <span v-if="fieldErrors.full_name" class="field-error">{{
                  fieldErrors.full_name
                }}</span>
              </div>
              <div class="form-group">
                <label class="form-label">Phone</label>
                <input v-model="form.phone" class="form-input" type="tel" autocomplete="tel" />
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">Street address</label>
              <input
                v-model="form.address"
                class="form-input"
                type="text"
                autocomplete="street-address"
                required
              />
              <span v-if="fieldErrors.address" class="field-error">{{ fieldErrors.address }}</span>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label class="form-label">City</label>
                <input
                  v-model="form.city"
                  class="form-input"
                  type="text"
                  autocomplete="address-level2"
                  required
                />
                <span v-if="fieldErrors.city" class="field-error">{{ fieldErrors.city }}</span>
              </div>
              <div class="form-group">
                <label class="form-label">Country</label>
                <input
                  v-model="form.country"
                  class="form-input"
                  type="text"
                  autocomplete="country-name"
                  required
                />
                <span v-if="fieldErrors.country" class="field-error">{{
                  fieldErrors.country
                }}</span>
              </div>
            </div>

            <label class="save-address-row">
              <input v-model="saveAddress" type="checkbox" class="save-checkbox" />
              <span class="save-label">Save address to my profile</span>
            </label>
          </section>

          <!-- Step 2: Payment -->
          <section class="checkout-section">
            <h2 class="section-title"><span class="section-num">2</span> PAYMENT</h2>

            <div class="payment-notice">
              <p class="payment-notice-text">
                This is a demo store. No real payment is processed. Clicking "Place Order" will
                create a <strong>pending</strong> order.
              </p>
            </div>

            <div class="form-group">
              <label class="form-label">Card number</label>
              <input class="form-input" type="text" placeholder="4242 4242 4242 4242" disabled />
            </div>

            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Expiry</label>
                <input class="form-input" type="text" placeholder="MM / YY" disabled />
              </div>
              <div class="form-group">
                <label class="form-label">CVC</label>
                <input class="form-input" type="text" placeholder="•••" disabled />
              </div>
            </div>
          </section>

          <p v-if="submitError" class="inline-feedback inline-feedback-error">{{ submitError }}</p>

          <button class="place-order-btn" type="button" :disabled="placing" @click="placeOrder">
            {{ placing ? 'PLACING ORDER...' : 'PLACE ORDER' }}
          </button>
        </div>

        <!-- RIGHT: order summary -->
        <aside class="checkout-summary">
          <h2 class="summary-title">ORDER SUMMARY</h2>

          <ul class="summary-lines">
            <li v-for="item in items" :key="item.variant.id" class="summary-line">
              <div class="summary-line-img-wrap">
                <img
                  :src="item.variant.image_url || item.product?.image_url || ''"
                  :alt="item.product?.name"
                  class="summary-line-img"
                />
                <span class="summary-line-qty">{{ item.quantity }}</span>
              </div>
              <div class="summary-line-info">
                <div class="summary-line-name">{{ item.product?.name }}</div>
                <div
                  v-if="item.variant.material_color || item.variant.size"
                  class="summary-line-meta"
                >
                  {{ [item.variant.material_color, item.variant.size].filter(Boolean).join(' · ') }}
                </div>
              </div>
              <div class="summary-line-price">{{ linePrice(item) }}</div>
            </li>
          </ul>

          <div class="summary-divider"></div>

          <div class="summary-row">
            <span class="summary-label">Subtotal</span>
            <span class="summary-amount">{{ totalFormatted }}</span>
          </div>
          <div class="summary-row">
            <span class="summary-label">Shipping</span>
            <span class="summary-amount summary-free">FREE</span>
          </div>

          <div class="summary-divider summary-divider--thick"></div>

          <div class="summary-row summary-total">
            <span class="summary-label">TOTAL</span>
            <span class="summary-amount">{{ totalFormatted }}</span>
          </div>
          <div class="summary-vat">Includes VAT</div>
        </aside>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import { useCartStore } from '@/stores/cart'
import { useAuthStore } from '@/stores/auth'
import { useOrdersStore } from '@/stores/orders'

const router = useRouter()
const cart = useCartStore()
const auth = useAuthStore()
const ordersStore = useOrdersStore()

const { items, totalPrice } = storeToRefs(cart)

const placing = ref(false)
const submitError = ref('')
const saveAddress = ref(true)
const fieldErrors = reactive({})

// Pre-fill from profile
const form = reactive({
  full_name: '',
  phone: '',
  address: '',
  city: '',
  country: '',
})

onMounted(() => {
  cart.closeDrawer()
  const p = auth.profile
  if (p) {
    form.full_name = p.full_name || ''
    form.phone = p.phone || ''
    form.address = p.address || ''
    form.city = p.city || ''
    form.country = p.country || ''
  }
})

const totalFormatted = computed(() => {
  const amount = totalPrice.value
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2,
    }).format(amount)
  } catch {
    return `€${amount.toFixed(2)}`
  }
})

function linePrice(item) {
  const amount = (item.variant.price_cents / 100) * item.quantity
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2,
    }).format(amount)
  } catch {
    return `€${amount.toFixed(2)}`
  }
}

function validate() {
  Object.keys(fieldErrors).forEach((k) => delete fieldErrors[k])
  let ok = true
  if (!form.full_name.trim()) {
    fieldErrors.full_name = 'Required'
    ok = false
  }
  if (!form.address.trim()) {
    fieldErrors.address = 'Required'
    ok = false
  }
  if (!form.city.trim()) {
    fieldErrors.city = 'Required'
    ok = false
  }
  if (!form.country.trim()) {
    fieldErrors.country = 'Required'
    ok = false
  }
  return ok
}

function parseOrderError(message) {
  if (!message) return 'Unable to place order. Please try again.'
  if (message.includes('INSUFFICIENT_STOCK')) {
    return 'One or more items in your bag no longer have sufficient stock. Please review your bag and try again.'
  }
  if (message.includes('VARIANT_UNAVAILABLE') || message.includes('PRODUCT_UNAVAILABLE')) {
    return 'One or more items in your bag are no longer available. Please review your bag.'
  }
  if (message.includes('VARIANT_NOT_FOUND')) {
    return 'One or more items could not be found. Please refresh and try again.'
  }
  if (message.includes('VARIANT_PRICE_MISSING')) {
    return 'One or more items are missing a price. Please contact support.'
  }
  if (message.includes('INVALID_QUANTITY')) {
    return 'An invalid quantity was detected. Please review your bag.'
  }
  if (message.includes('EMPTY_ORDER')) {
    return 'Your bag is empty. Please add items before placing an order.'
  }
  if (message.includes('UNSUPPORTED_CURRENCY')) {
    return 'An unsupported currency was detected. Please contact support.'
  }
  if (message.includes('UNAUTHENTICATED')) {
    router.push({ name: 'auth', query: { redirect: '/checkout' } })
    return ''
  }
  return 'Unable to place order. Please try again.'
}

async function placeOrder() {
  submitError.value = ''
  if (!validate()) return

  if (!auth.isAuthenticated) {
    router.push({ name: 'auth', query: { redirect: '/checkout' } })
    return
  }

  placing.value = true
  try {
    const shippingAddress = {
      full_name: form.full_name,
      phone: form.phone,
      address: form.address,
      city: form.city,
      country: form.country,
    }

    const result = await ordersStore.createOrder({
      items: items.value.map((i) => ({ variant_id: i.variant.id, quantity: i.quantity })),
      shippingAddress,
    })

    // Optionally persist address back to profile
    if (saveAddress.value) {
      await auth.upsertProfile({
        full_name: form.full_name,
        phone: form.phone,
        address: form.address,
        city: form.city,
        country: form.country,
      })
    }

    await cart.clear()
    router.push({ name: 'order-confirm', params: { id: result.id } })
  } catch (e) {
    submitError.value = parseOrderError(e?.message)
  } finally {
    placing.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.checkout-page {
  background: #fff;
  min-height: 100vh;
  padding: 72px 0 100px;
}

.checkout-wrap {
  max-width: 1100px;
  margin: 0 auto;
  padding: 0 24px;
}

/* ── header ── */
.checkout-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 48px;
}

.checkout-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  font-weight: 400;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0;
}

.checkout-back {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #6b5b4a;
  text-decoration: none;
  letter-spacing: 0.04em;
  transition: color 0.15s;
}
.checkout-back:hover {
  color: #1a1a1a;
}

/* ── two-column layout ── */
.checkout-body {
  display: grid;
  grid-template-columns: 1fr 380px;
  gap: 52px;
  align-items: flex-start;
}

/* ── section ── */
.checkout-section {
  margin-bottom: 40px;
  padding-bottom: 40px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}
.checkout-section:last-of-type {
  border-bottom: none;
}

.section-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 400;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 28px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border: 1px solid rgba(0, 0, 0, 0.12);
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #1a1a1a;
  flex-shrink: 0;
}

/* ── form ── */
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0 28px;
}

.form-group {
  margin-bottom: 22px;
  display: flex;
  flex-direction: column;
}

.form-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #888;
  margin-bottom: 10px;
}

.form-input {
  width: 100%;
  border: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.2);
  padding: 10px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  background: transparent;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
}
.form-input:focus {
  border-bottom-color: #000;
}
.form-input:disabled {
  color: #bbb;
  cursor: not-allowed;
}

.field-error {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #8e2134;
  margin-top: 6px;
}

.save-address-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 4px;
  cursor: pointer;
}

.save-checkbox {
  width: 14px;
  height: 14px;
  accent-color: #1a1a1a;
  cursor: pointer;
}

.save-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #6b5b4a;
  letter-spacing: 0.02em;
}

/* ── payment notice ── */
.payment-notice {
  background: rgba(184, 153, 106, 0.06);
  border: 1px solid rgba(184, 153, 106, 0.2);
  padding: 14px 18px;
  margin-bottom: 24px;
}

.payment-notice-text {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #6b5b4a;
  margin: 0;
  line-height: 1.7;
}

/* ── feedback ── */
.inline-feedback {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  line-height: 1.6;
  margin: 0 0 18px;
  padding: 12px 14px;
  border-radius: 0;
}

.inline-feedback-error {
  color: #8e2134;
  border: 1px solid rgba(196, 30, 58, 0.25);
  background: rgba(196, 30, 58, 0.06);
}

/* ── CTA ── */
.place-order-btn {
  width: 100%;
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 18px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  cursor: pointer;
  transition: background 0.18s;
  border-radius: 0;
}
.place-order-btn:hover:not(:disabled) {
  background: #2a2a2a;
}
.place-order-btn:disabled {
  background: #b8b2ab;
  color: #f5f2ee;
  cursor: not-allowed;
}

/* ── summary sidebar ── */
.checkout-summary {
  background: #faf9f7;
  border: 1px solid rgba(0, 0, 0, 0.06);
  padding: 32px;
  position: sticky;
  top: 100px;
}

.summary-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 24px;
}

.summary-lines {
  list-style: none;
  padding: 0;
  margin: 0 0 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.summary-line {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.summary-line-img-wrap {
  position: relative;
  width: 56px;
  height: 56px;
  flex-shrink: 0;
  background: #f0ede8;
}

.summary-line-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.summary-line-qty {
  position: absolute;
  top: -6px;
  right: -6px;
  background: #1a1a1a;
  color: #fff;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  width: 18px;
  height: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
}

.summary-line-info {
  flex: 1;
  min-width: 0;
}

.summary-line-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  letter-spacing: 0.04em;
  color: #1a1a1a;
  text-transform: uppercase;
  line-height: 1.4;
}

.summary-line-meta {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  margin-top: 3px;
}

.summary-line-price {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  white-space: nowrap;
}

.summary-divider {
  height: 1px;
  background: rgba(0, 0, 0, 0.06);
  margin: 16px 0;
}

.summary-divider--thick {
  height: 1px;
  background: rgba(0, 0, 0, 0.12);
  margin: 16px 0;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 10px;
}

.summary-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #6b5b4a;
}

.summary-amount {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
}

.summary-free {
  color: #7a6a59;
  font-size: 11px;
  letter-spacing: 0.08em;
}

.summary-total .summary-label,
.summary-total .summary-amount {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
}

.summary-vat {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  text-align: right;
  margin-top: -4px;
}

/* ── responsive ── */
@media (max-width: 880px) {
  .checkout-body {
    grid-template-columns: 1fr;
  }

  .checkout-summary {
    position: static;
    order: -1;
  }
}

@media (max-width: 520px) {
  .checkout-header {
    flex-direction: column;
    gap: 12px;
    align-items: flex-start;
  }

  .form-row {
    grid-template-columns: 1fr;
    gap: 0;
  }

  .checkout-wrap {
    padding: 0 16px;
  }
}
</style>
