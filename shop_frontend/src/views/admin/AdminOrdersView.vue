<template>
  <div class="orders-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Orders</h1>
        <p class="page-sub">{{ admin.orders.length }} orders</p>
      </div>
      <button class="btn-ghost" @click="admin.fetchOrders()">Refresh</button>
    </header>

    <!-- Filters -->
    <div class="filters">
      <button
        v-for="s in ['all', ...admin.ORDER_STATUSES]"
        :key="s"
        :class="['filter-btn', statusFilter === s && 'filter-btn--active']"
        @click="statusFilter = s"
      >
        {{ s === 'all' ? 'All' : capitalize(s) }}
        <span class="filter-count">{{ countByStatus(s) }}</span>
      </button>
    </div>

    <div v-if="admin.ordersLoading" class="loading">Loading…</div>
    <div v-else-if="admin.ordersError" class="error">{{ admin.ordersError }}</div>

    <table v-else class="orders-table">
      <thead>
        <tr>
          <th>Order ID</th>
          <th>Date</th>
          <th>Customer</th>
          <th>Items</th>
          <th>Total</th>
          <th>Status</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <template v-if="!filteredOrders.length">
          <tr>
            <td colspan="7" style="text-align: center; padding: 40px; color: #9a9087">
              No orders.
            </td>
          </tr>
        </template>
        <template v-else>
          <tr v-for="order in filteredOrders" :key="order.id">
            <td class="mono">{{ order.id.slice(0, 8) }}…</td>
            <td>{{ formatDate(order.created_at) }}</td>
            <td>{{ order.profiles?.full_name || '—' }}</td>
            <td>{{ order.items_snapshot?.length ?? '?' }}</td>
            <td>{{ formatPrice(order.total_cents) }}</td>
            <td>
              <select
                class="status-select"
                :class="`status-select--${order.status}`"
                :value="order.status"
                @change="changeStatus(order, $event.target.value)"
              >
                <option v-for="s in admin.ORDER_STATUSES" :key="s" :value="s">
                  {{ capitalize(s) }}
                </option>
              </select>
            </td>
            <td>
              <button class="btn-ghost" @click="showOrder(order)">View</button>
            </td>
          </tr>
        </template>
      </tbody>
    </table>

    <!-- Order detail panel -->
    <v-dialog v-model="detailOpen" max-width="560" :persistent="false">
      <div class="detail-card" v-if="detailOrder">
        <h3 class="detail-title">Order Details</h3>
        <div class="detail-id">{{ detailOrder.id }}</div>
        <div class="detail-meta">
          <span>{{ formatDate(detailOrder.created_at) }}</span>
          <span>{{ detailOrder.profiles?.full_name || 'Unknown customer' }}</span>
        </div>

        <div class="detail-items">
          <div class="detail-item" v-for="(item, i) in detailOrder.items_snapshot ?? []" :key="i">
            <img
              v-if="item.image_url"
              :src="item.image_url"
              class="item-thumb"
              :alt="item.product_name"
            />
            <div v-else class="item-thumb item-thumb--empty" />
            <div class="item-info">
              <div class="item-name">{{ item.product_name || '—' }}</div>
              <div class="item-sub">
                {{ item.material_color || '' }} {{ item.size ? `· ${item.size}` : '' }}
              </div>
            </div>
            <div class="item-price">
              {{ item.quantity }}× {{ formatPrice(item.unit_price_cents) }}
            </div>
          </div>
        </div>

        <div class="detail-total">Total: {{ formatPrice(detailOrder.total_cents) }}</div>

        <div v-if="detailOrder.shipping_address" class="detail-address">
          <div class="detail-section-label">Shipping Address</div>
          <pre class="address-pre">{{ formatAddress(detailOrder.shipping_address) }}</pre>
        </div>

        <div class="detail-footer">
          <button class="btn-ghost" @click="detailOpen = false">Close</button>
        </div>
      </div>
    </v-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAdminStore } from '@/stores/admin'
import { showToast } from '@/lib/toast'

const admin = useAdminStore()
const statusFilter = ref('all')

const detailOpen = ref(false)
const detailOrder = ref(null)

onMounted(() => admin.fetchOrders())

const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1)

const formatPrice = (cents) =>
  cents != null
    ? new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)
    : '—'

const formatDate = (iso) =>
  new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })

const filteredOrders = computed(() =>
  statusFilter.value === 'all'
    ? admin.orders
    : admin.orders.filter((o) => o.status === statusFilter.value),
)

function countByStatus(s) {
  return s === 'all' ? admin.orders.length : admin.orders.filter((o) => o.status === s).length
}

async function changeStatus(order, newStatus) {
  try {
    await admin.updateOrderStatus(order.id, newStatus)
    showToast(`Order status updated to "${newStatus}"`, 'success')
  } catch (e) {
    showToast(e?.message || 'Failed to update order status', 'error')
  }
}

function showOrder(order) {
  detailOrder.value = order
  detailOpen.value = true
}

function formatAddress(addr) {
  if (typeof addr === 'string') return addr
  if (!addr) return '—'
  const parts = [addr.full_name, addr.phone, addr.address, addr.city, addr.country]
  return parts.filter(Boolean).join('\n')
}
</script>

<style scoped>
.orders-page {
  padding: 40px 48px;
  font-family: 'Lora', 'Georgia', serif;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.page-title {
  font-size: 26px;
  font-weight: 500;
  color: #1a1a1a;
  letter-spacing: 0.04em;
  margin: 0 0 4px;
}

.page-sub {
  font-size: 13px;
  color: #6b5b4a;
  margin: 0;
}

.filters {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

.filter-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  border: 1px solid #e8e2d8;
  background: #fff;
  padding: 6px 14px;
  font-size: 12px;
  letter-spacing: 0.06em;
  font-family: inherit;
  color: #6b5b4a;
  cursor: pointer;
}

.filter-btn:hover {
  border-color: #b8996a;
  color: #1a1a1a;
}

.filter-btn--active {
  background: #1a1a1a;
  border-color: #1a1a1a;
  color: #fff;
}

.filter-count {
  font-size: 10px;
  background: rgba(255, 255, 255, 0.2);
  padding: 1px 5px;
}

.filter-btn--active .filter-count {
  background: rgba(255, 255, 255, 0.2);
}
.filter-btn:not(.filter-btn--active) .filter-count {
  background: #f0ece6;
  color: #9a9087;
}

.loading,
.error {
  padding: 40px;
  text-align: center;
  font-size: 14px;
  color: #6b5b4a;
}
.error {
  color: #c0392b;
}

.orders-table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e8e2d8;
}

.orders-table th,
.orders-table td {
  padding: 11px 14px;
  text-align: left;
  font-size: 13px;
  border-bottom: 1px solid #f0ece6;
  vertical-align: middle;
}

.orders-table th {
  font-size: 10px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #9a9087;
  background: #faf9f7;
}

.mono {
  font-family: 'Courier New', monospace;
  font-size: 12px;
}

.status-select {
  border: 1px solid #e8e2d8;
  background: #faf9f7;
  padding: 4px 8px;
  font-size: 12px;
  font-family: inherit;
  color: #1a1a1a;
  cursor: pointer;
  outline: none;
}

.status-select--pending {
  color: #9a7a3a;
}
.status-select--paid {
  color: #2d4fa0;
}
.status-select--processing {
  color: #5a3fa0;
}
.status-select--shipped {
  color: #1a6b4a;
}
.status-select--delivered {
  color: #2d7a2d;
}
.status-select--cancelled {
  color: #c0392b;
}
.status-select--refunded {
  color: #8b4513;
}

.btn-ghost {
  background: none;
  border: 1px solid #e8e2d8;
  color: #1a1a1a;
  padding: 5px 12px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
}
.btn-ghost:hover {
  border-color: #1a1a1a;
}

/* Detail dialog */
.detail-card {
  background: #fff;
  padding: 36px;
  font-family: 'Lora', 'Georgia', serif;
  max-height: 90vh;
  overflow-y: auto;
}

.detail-title {
  font-size: 20px;
  font-weight: 500;
  color: #1a1a1a;
  margin: 0 0 6px;
}

.detail-id {
  font-family: 'Courier New', monospace;
  font-size: 11px;
  color: #9a9087;
  margin-bottom: 8px;
}

.detail-meta {
  display: flex;
  gap: 20px;
  font-size: 12px;
  color: #6b5b4a;
  margin-bottom: 24px;
}

.detail-items {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 20px;
}

.detail-item {
  display: flex;
  align-items: center;
  gap: 12px;
  border: 1px solid #f0ece6;
  padding: 8px;
}

.item-thumb {
  width: 52px;
  height: 52px;
  object-fit: cover;
  flex-shrink: 0;
}

.item-thumb--empty {
  background: #f0ece6;
}

.item-info {
  flex: 1;
}

.item-name {
  font-size: 13px;
  color: #1a1a1a;
  font-weight: 500;
}

.item-sub {
  font-size: 11px;
  color: #9a9087;
  margin-top: 2px;
}

.item-price {
  font-size: 13px;
  color: #1a1a1a;
  white-space: nowrap;
}

.detail-total {
  font-size: 15px;
  font-weight: 500;
  color: #1a1a1a;
  text-align: right;
  border-top: 1px solid #e8e2d8;
  padding-top: 12px;
  margin-bottom: 20px;
}

.detail-section-label {
  font-size: 10px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #9a9087;
  margin-bottom: 6px;
}

.address-pre {
  font-family: inherit;
  font-size: 13px;
  color: #1a1a1a;
  margin: 0 0 24px;
  white-space: pre-wrap;
}

.detail-footer {
  display: flex;
  justify-content: flex-end;
}
</style>
