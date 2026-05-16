<template>
  <div class="confirm-page">
    <div class="confirm-wrap">
      <div v-if="loading" class="confirm-loading">Loading order details...</div>

      <template v-else-if="order">
        <!-- Hero confirmation -->
        <div class="confirm-hero">
          <div class="confirm-check">✓</div>
          <h1 class="confirm-title">ORDER PLACED</h1>
          <p class="confirm-subtitle">
            Thank you, <strong>{{ order.shipping_address?.full_name }}</strong
            >.<br />
            Your order has been received and is being prepared.
          </p>
          <div class="confirm-ref">
            Order reference: <span class="confirm-ref-val">{{ shortId }}</span>
          </div>
        </div>

        <div class="confirm-body">
          <!-- Items summary -->
          <section class="confirm-section">
            <h2 class="confirm-section-title">ITEMS ORDERED</h2>
            <ul class="confirm-lines">
              <li v-for="item in order.items_snapshot" :key="item.product.id" class="confirm-line">
                <div class="confirm-line-img-wrap">
                  <img
                    :src="lineImage(item.product)"
                    :alt="item.product.name"
                    class="confirm-line-img"
                  />
                </div>
                <div class="confirm-line-info">
                  <div class="confirm-line-name">{{ item.product.name }}</div>
                  <div v-if="item.product.material" class="confirm-line-meta">
                    {{ item.product.material }}
                  </div>
                  <div class="confirm-line-qty">Qty: {{ item.quantity }}</div>
                </div>
                <div class="confirm-line-price">{{ linePrice(item) }}</div>
              </li>
            </ul>
          </section>

          <div class="confirm-cols">
            <!-- Shipping address -->
            <section class="confirm-section">
              <h2 class="confirm-section-title">DELIVERY ADDRESS</h2>
              <address class="confirm-address">
                <span v-if="order.shipping_address?.full_name">{{
                  order.shipping_address.full_name
                }}</span>
                <span v-if="order.shipping_address?.phone">{{ order.shipping_address.phone }}</span>
                <span v-if="order.shipping_address?.address">{{
                  order.shipping_address.address
                }}</span>
                <span v-if="order.shipping_address?.city || order.shipping_address?.country">
                  {{
                    [order.shipping_address.city, order.shipping_address.country]
                      .filter(Boolean)
                      .join(', ')
                  }}
                </span>
              </address>
            </section>

            <!-- Order totals -->
            <section class="confirm-section">
              <h2 class="confirm-section-title">ORDER TOTAL</h2>
              <div class="confirm-totals">
                <div class="confirm-total-row">
                  <span class="confirm-total-label">Subtotal</span>
                  <span class="confirm-total-val">{{ totalFormatted }}</span>
                </div>
                <div class="confirm-total-row">
                  <span class="confirm-total-label">Shipping</span>
                  <span class="confirm-total-val confirm-free">FREE</span>
                </div>
                <div class="confirm-total-row confirm-total-row--grand">
                  <span class="confirm-total-label">TOTAL</span>
                  <span class="confirm-total-val">{{ totalFormatted }}</span>
                </div>
                <div class="confirm-vat">Includes VAT</div>
              </div>
            </section>
          </div>
        </div>

        <div class="confirm-actions">
          <router-link to="/profile" class="confirm-btn confirm-btn--ghost"
            >VIEW MY ORDERS</router-link
          >
          <router-link to="/#catalog" class="confirm-btn">CONTINUE SHOPPING</router-link>
        </div>
      </template>

      <div v-else class="confirm-not-found">
        <p>Order not found.</p>
        <router-link to="/" class="confirm-btn">GO HOME</router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const order = ref(null)
const loading = ref(true)

onMounted(async () => {
  const { data, error } = await supabase
    .from('orders')
    .select('*')
    .eq('id', route.params.id)
    .single()
  if (!error) order.value = data
  loading.value = false
})

const shortId = computed(() => order.value?.id?.split('-')[0]?.toUpperCase() ?? '')

const totalFormatted = computed(() => {
  if (!order.value) return ''
  const amount = order.value.total_cents / 100
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
  // Prefer server-verified line_total_cents stored in enriched snapshot
  const cents =
    item.line_total_cents ??
    (item.product?.price_cents != null ? Number(item.product.price_cents) * item.quantity : null)
  if (cents == null || isNaN(cents)) return ''
  const amount = Number(cents) / 100
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

function lineImage(product) {
  if (product.image_url) return product.image_url
  if (Array.isArray(product.images) && product.images.length) return product.images[0]
  return ''
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.confirm-page {
  background: #fff;
  min-height: 100vh;
  padding: 72px 0 100px;
}

.confirm-wrap {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 24px;
}

.confirm-loading {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #6b5b4a;
  text-align: center;
  padding: 80px 0;
}

/* ── hero ── */
.confirm-hero {
  text-align: center;
  padding-bottom: 52px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  margin-bottom: 52px;
}

.confirm-check {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 52px;
  height: 52px;
  border: 1px solid #b8996a;
  color: #b8996a;
  font-size: 22px;
  margin-bottom: 24px;
}

.confirm-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  font-weight: 400;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 14px;
}

.confirm-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #6b5b4a;
  line-height: 1.8;
  margin: 0 0 18px;
}

.confirm-ref {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.confirm-ref-val {
  color: #1a1a1a;
  font-weight: 600;
}

/* ── body ── */
.confirm-section {
  margin-bottom: 40px;
}

.confirm-section-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #7a6a59;
  margin: 0 0 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

/* items */
.confirm-lines {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.confirm-line {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.confirm-line-img-wrap {
  width: 64px;
  height: 64px;
  flex-shrink: 0;
  background: #f0ede8;
}

.confirm-line-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.confirm-line-info {
  flex: 1;
  min-width: 0;
}

.confirm-line-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: #1a1a1a;
}

.confirm-line-meta,
.confirm-line-qty {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  margin-top: 4px;
}

.confirm-line-price {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  white-space: nowrap;
}

/* two-col below items */
.confirm-cols {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 40px;
}

/* address */
.confirm-address {
  font-style: normal;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.confirm-address span {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  line-height: 1.6;
}

/* totals */
.confirm-total-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.confirm-total-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #6b5b4a;
}

.confirm-total-val {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
}

.confirm-free {
  font-size: 11px;
  color: #7a6a59;
  letter-spacing: 0.08em;
}

.confirm-total-row--grand .confirm-total-label,
.confirm-total-row--grand .confirm-total-val {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
}

.confirm-vat {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #7a6a59;
  text-align: right;
}

/* ── actions ── */
.confirm-actions {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
  padding-top: 40px;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
  margin-top: 12px;
}

.confirm-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 46px;
  padding: 0 32px;
  background: #1a1a1a;
  color: #fff;
  border: 1px solid #1a1a1a;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  text-decoration: none;
  cursor: pointer;
  transition: background 0.15s;
  border-radius: 0;
}
.confirm-btn:hover {
  background: #2a2a2a;
  border-color: #2a2a2a;
}

.confirm-btn--ghost {
  background: transparent;
  color: #1a1a1a;
}
.confirm-btn--ghost:hover {
  background: rgba(0, 0, 0, 0.04);
}

.confirm-not-found {
  text-align: center;
  padding: 80px 0;
  font-family: 'Lora', 'Georgia', serif;
  color: #6b5b4a;
}

/* ── responsive ── */
@media (max-width: 640px) {
  .confirm-cols {
    grid-template-columns: 1fr;
    gap: 0;
  }

  .confirm-actions {
    flex-direction: column;
  }

  .confirm-btn {
    width: 100%;
  }
}
</style>
