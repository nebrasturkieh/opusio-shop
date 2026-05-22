<template>
  <v-container class="profile" fluid>
    <div class="profile-inner">
      <header class="profile-header">
        <h1 class="profile-title">MY PROFILE</h1>
        <p class="profile-subtitle">
          Keep your account details curated and up to date for a seamless Opusio experience.
        </p>
      </header>

      <div v-if="auth.loading" class="loading-state">Loading your profile...</div>

      <div v-else class="profile-surface">
        <ProfileSetup
          v-if="isEditing || !auth.profile"
          :initial-full-name="auth.profile?.full_name || ''"
          :can-cancel="Boolean(auth.profile)"
          @saved="handleSaved"
          @cancel="cancelEdit"
        />

        <section v-else class="profile-card">
          <div class="profile-identity">
            <div class="identity-copy">
              <h2 class="name-text">{{ auth.profile.full_name || 'No name yet' }}</h2>
              <p class="role-text">Account tier: {{ auth.profile.role || 'user' }}</p>
            </div>
            <dl class="profile-details">
              <template v-if="auth.profile.phone">
                <dt>Phone</dt>
                <dd>{{ auth.profile.phone }}</dd>
              </template>
              <template v-if="auth.profile.address || auth.profile.city || auth.profile.country">
                <dt>Address</dt>
                <dd>
                  {{
                    [auth.profile.address, auth.profile.city, auth.profile.country]
                      .filter(Boolean)
                      .join(', ')
                  }}
                </dd>
              </template>
            </dl>
          </div>

          <div class="profile-actions">
            <button type="button" class="edit-btn" @click="edit">EDIT PROFILE</button>
          </div>
        </section>
      </div>

      <!-- Order history -->
      <section class="orders-section">
        <h2 class="orders-title">ORDER HISTORY</h2>

        <div v-if="ordersStore.loading" class="orders-loading">Loading orders...</div>

        <div v-else-if="ordersStore.error" class="orders-error">{{ ordersStore.error }}</div>

        <div v-else-if="ordersStore.orders.length === 0" class="orders-empty">
          No orders yet. When you place an order it will appear here.
        </div>

        <ul v-else class="orders-list">
          <li v-for="order in ordersStore.orders" :key="order.id" class="order-row">
            <div class="order-col order-ref">
              <span class="order-label">Order</span>
              <span class="order-val">#{{ order.id.split('-')[0].toUpperCase() }}</span>
            </div>
            <div class="order-col order-date">
              <span class="order-label">Date</span>
              <span class="order-val">{{ formatDate(order.created_at) }}</span>
            </div>
            <div class="order-col order-items">
              <span class="order-label">Items</span>
              <span class="order-val">{{ itemCount(order) }}</span>
            </div>
            <div class="order-col order-total">
              <span class="order-label">Total</span>
              <span class="order-val">{{ formatTotal(order.total_cents) }}</span>
            </div>
            <div class="order-col order-status">
              <span :class="['status-pill', 'status-pill--' + order.status]">{{
                order.status
              }}</span>
            </div>
            <div class="order-col order-action">
              <router-link
                :to="{ name: 'order-confirm', params: { id: order.id } }"
                class="order-view-link"
                >VIEW</router-link
              >
            </div>
          </li>
        </ul>
      </section>
    </div>
  </v-container>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useOrdersStore } from '@/stores/orders'
import ProfileSetup from '@/components/ProfileSetup.vue'

const auth = useAuthStore()
const ordersStore = useOrdersStore()
const isEditing = ref(false)

onMounted(async () => {
  if (!auth.user && !auth.loading) {
    await auth.init()
  }
  if (auth.user) {
    await ordersStore.fetchOrders(auth.user.id)
  }
})

function formatDate(iso) {
  try {
    return new Intl.DateTimeFormat(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    }).format(new Date(iso))
  } catch {
    return iso?.slice(0, 10) ?? ''
  }
}

function formatTotal(cents) {
  if (cents == null) return ''
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2,
    }).format(cents / 100)
  } catch {
    return `€${(cents / 100).toFixed(2)}`
  }
}

function itemCount(order) {
  const snap = order.items_snapshot
  if (!Array.isArray(snap)) return 0
  return snap.reduce((acc, i) => acc + (i.quantity ?? 1), 0)
}

function edit() {
  isEditing.value = true
}

function cancelEdit() {
  isEditing.value = false
}

function handleSaved() {
  isEditing.value = false
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.profile {
  background: #fff;
  min-height: 100vh;
  padding: 72px 0 100px;
}

.profile-inner {
  max-width: 1000px;
  margin: 0 auto;
  padding: 0 24px;
}

/* ── header ── */
.profile-header {
  text-align: center;
  margin-bottom: 52px;
}

.profile-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  font-weight: 400;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 12px;
}

.profile-subtitle {
  margin: 0 auto;
  max-width: 620px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  line-height: 1.8;
  color: #6b5b4a;
  letter-spacing: 0.01em;
}

.loading-state {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #6b5b4a;
  text-align: center;
  padding: 60px 20px;
}

.profile-surface {
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: linear-gradient(180deg, #fff 0%, #fbfaf8 100%);
  padding: 40px;
}

.profile-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 32px;
}

.profile-identity {
  display: flex;
  align-items: flex-start;
  gap: 0;
  flex-direction: column;
  flex: 1;
}

.identity-copy {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.name-text {
  margin: 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  font-weight: 500;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #1a1a1a;
}

.role-text {
  margin: 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #7a6a59;
}

.profile-details {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 10px 20px;
  margin: 20px 0 0;
  padding: 20px 0 0;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
  align-items: baseline;
}

.profile-details dt {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #7a6a59;
}

.profile-details dd {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  margin: 0;
  line-height: 1.5;
}

.profile-actions {
  flex-shrink: 0;
  padding-top: 4px;
}

.edit-btn {
  background: #000;
  color: #fff;
  border: none;
  padding: 13px 32px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  cursor: pointer;
  transition: background 0.2s ease;
  border-radius: 0;
  white-space: nowrap;
}

.edit-btn:hover {
  background: #1f1f1f;
}

@media (max-width: 768px) {
  .profile-inner {
    margin-top: 42px;
  }

  .profile-surface {
    padding: 24px;
  }

  .profile-card {
    flex-direction: column;
    align-items: flex-start;
    gap: 24px;
  }

  .name-text {
    font-size: 18px;
  }

  .edit-btn {
    width: 100%;
  }
}

@media (max-width: 520px) {
  .profile-surface {
    padding: 20px;
  }
}

/* ── orders section ── */
.orders-section {
  margin-top: 52px;
}

.orders-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 24px;
  padding-bottom: 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.orders-loading,
.orders-empty {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
  padding: 32px 0;
  text-align: center;
}

.orders-error {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #c0392b;
  padding: 32px 0;
  text-align: center;
}

.orders-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0;
}

.order-row {
  display: grid;
  grid-template-columns: 1.5fr 1.5fr 1fr 1.2fr 1fr auto;
  align-items: center;
  gap: 16px;
  padding: 18px 0;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.order-col {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.order-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #7a6a59;
}

.order-val {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
}

/* status pill */
.status-pill {
  display: inline-block;
  padding: 3px 10px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  border: 1px solid;
  border-radius: 0;
}

.status-pill--pending {
  color: #7a6a59;
  border-color: rgba(122, 106, 89, 0.3);
  background: rgba(122, 106, 89, 0.06);
}
.status-pill--paid {
  color: #2c6e49;
  border-color: rgba(44, 110, 73, 0.3);
  background: rgba(44, 110, 73, 0.06);
}
.status-pill--shipped {
  color: #1d4e89;
  border-color: rgba(29, 78, 137, 0.3);
  background: rgba(29, 78, 137, 0.06);
}
.status-pill--cancelled {
  color: #8e2134;
  border-color: rgba(142, 33, 52, 0.3);
  background: rgba(142, 33, 52, 0.06);
}

.order-view-link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  text-decoration: none;
  border-bottom: 1px solid currentColor;
  padding-bottom: 1px;
  white-space: nowrap;
  transition: color 0.15s;
}
.order-view-link:hover {
  color: #b8996a;
}

@media (max-width: 640px) {
  .order-row {
    grid-template-columns: 1fr 1fr;
    gap: 12px 16px;
  }

  .order-action {
    grid-column: 1 / -1;
  }
}
</style>
