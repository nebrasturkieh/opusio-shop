<template>
  <div class="dash">
    <header class="dash-header">
      <h1 class="dash-title">Dashboard</h1>
      <p class="dash-sub">Overview of the shop</p>
    </header>

    <div class="stat-grid">
      <div class="stat-card" v-for="stat in statCards" :key="stat.label">
        <div class="stat-value">{{ stat.value }}</div>
        <div class="stat-label">{{ stat.label }}</div>
      </div>
    </div>

    <div class="dash-links">
      <router-link :to="{ name: 'admin-products' }" class="dash-link">
        Manage Products →
      </router-link>
      <router-link :to="{ name: 'admin-orders' }" class="dash-link"> Manage Orders → </router-link>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useAdminStore } from '@/stores/admin'

const admin = useAdminStore()

onMounted(async () => {
  await Promise.all([admin.fetchProducts(), admin.fetchOrders()])
})

const formatEur = (cents) =>
  new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)

const statCards = computed(() => [
  { label: 'Total Products', value: admin.stats.totalProducts },
  { label: 'Active Products', value: admin.stats.activeProducts },
  { label: 'Total Orders', value: admin.stats.totalOrders },
  { label: 'Pending Orders', value: admin.stats.pendingOrders },
  { label: 'Revenue', value: formatEur(admin.stats.revenue) },
])
</script>

<style scoped>
.dash {
  padding: 40px 48px;
  font-family: 'Lora', 'Georgia', serif;
}

.dash-header {
  margin-bottom: 36px;
}

.dash-title {
  font-size: 26px;
  font-weight: 500;
  color: #1a1a1a;
  letter-spacing: 0.04em;
  margin: 0 0 4px;
}

.dash-sub {
  font-size: 13px;
  color: #6b5b4a;
  margin: 0;
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 16px;
  margin-bottom: 40px;
}

.stat-card {
  background: #fff;
  border: 1px solid #e8e2d8;
  padding: 24px 20px;
}

.stat-value {
  font-size: 28px;
  font-weight: 500;
  color: #1a1a1a;
  margin-bottom: 6px;
}

.stat-label {
  font-size: 11px;
  letter-spacing: 0.12em;
  color: #9a9087;
  text-transform: uppercase;
}

.dash-links {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.dash-link {
  font-size: 13px;
  color: #b8996a;
  text-decoration: none;
  letter-spacing: 0.04em;
}

.dash-link:hover {
  color: #1a1a1a;
}
</style>
