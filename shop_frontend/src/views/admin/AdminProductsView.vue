<template>
  <div class="products-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Products</h1>
        <p class="page-sub">
          {{ filteredProducts.length }} of {{ admin.products.length }} products
        </p>
      </div>
      <button class="btn-primary" @click="openCreate">+ New Product</button>
    </header>

    <!-- Search + filter bar -->
    <div class="filter-bar">
      <div class="search-wrap">
        <v-icon size="16" class="search-icon">mdi-magnify</v-icon>
        <input
          v-model="searchQuery"
          class="search-input"
          placeholder="Search by name, collection, category…"
          type="search"
        />
      </div>
      <select v-model="statusFilter" class="status-select">
        <option value="all">All statuses</option>
        <option value="active">Active</option>
        <option value="draft">Draft</option>
      </select>
    </div>

    <div v-if="admin.productsLoading" class="loading">Loading…</div>
    <div v-else-if="admin.productsError" class="error">{{ admin.productsError }}</div>

    <table v-else class="products-table">
      <thead>
        <tr>
          <th>Image</th>
          <th>Name</th>
          <th>Collection</th>
          <th>Category</th>
          <th>Variants</th>
          <th>Status</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="!filteredProducts.length">
          <td colspan="7" class="empty-row">
            {{
              admin.products.length === 0
                ? "No products yet. Click '+ New Product' to get started."
                : 'No products match your search.'
            }}
          </td>
        </tr>
        <tr v-for="product in filteredProducts" :key="product.id">
          <td>
            <img
              v-if="product.image_url || product.images?.[0]"
              :src="product.image_url || product.images?.[0]"
              class="thumb"
              :alt="product.name"
            />
            <div v-else class="thumb thumb--empty" />
          </td>
          <td>
            <router-link
              :to="{ name: 'admin-product-detail', params: { id: product.id } }"
              class="product-name-link"
            >
              {{ product.name }}
            </router-link>
          </td>
          <td class="text-muted">{{ product.collection || '—' }}</td>
          <td class="text-muted">{{ product.category || '—' }}</td>
          <td>{{ product.product_variants?.length ?? 0 }}</td>
          <td>
            <span
              :class="[
                'status-badge',
                product.is_active ? 'status-badge--active' : 'status-badge--inactive',
              ]"
            >
              {{ product.is_active ? 'Active' : 'Draft' }}
            </span>
          </td>
          <td class="actions">
            <router-link
              :to="{ name: 'admin-product-detail', params: { id: product.id } }"
              class="btn-ghost"
              >Manage</router-link
            >
            <button class="btn-ghost" @click="openEdit(product)">Edit</button>
            <button
              :class="product.is_active ? 'btn-danger' : 'btn-ghost'"
              @click="toggleActive(product)"
            >
              {{ product.is_active ? 'Deactivate' : 'Activate' }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Product dialog (create / edit) -->
    <ProductDialog v-model="dialogOpen" :product="editing" @saved="admin.fetchProducts()" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAdminStore } from '@/stores/admin'
import ProductDialog from '@/components/admin/ProductDialog.vue'

const admin = useAdminStore()

const dialogOpen = ref(false)
const editing = ref(null)
const searchQuery = ref('')
const statusFilter = ref('all')

const filteredProducts = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  return admin.products.filter((p) => {
    const matchesStatus =
      statusFilter.value === 'all' ||
      (statusFilter.value === 'active' && p.is_active) ||
      (statusFilter.value === 'draft' && !p.is_active)
    if (!matchesStatus) return false
    if (!q) return true
    return (
      p.name?.toLowerCase().includes(q) ||
      p.collection?.toLowerCase().includes(q) ||
      p.category?.toLowerCase().includes(q)
    )
  })
})

onMounted(() => admin.fetchProducts())

function openCreate() {
  editing.value = null
  dialogOpen.value = true
}

function openEdit(product) {
  editing.value = { ...product }
  dialogOpen.value = true
}

async function toggleActive(product) {
  await admin.updateProduct(product.id, { is_active: !product.is_active })
}
</script>

<style scoped>
.products-page {
  padding: 40px 48px;
  font-family: 'Lora', 'Georgia', serif;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
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

/* Filter bar */
.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  align-items: center;
}

.search-wrap {
  position: relative;
  flex: 1;
  max-width: 380px;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #9a9087;
  pointer-events: none;
}

.search-input {
  width: 100%;
  border: 1px solid #e8e2d8;
  padding: 8px 12px 8px 32px;
  font-size: 13px;
  font-family: inherit;
  color: #1a1a1a;
  background: #faf9f7;
  outline: none;
  box-sizing: border-box;
}

.search-input:focus {
  border-color: #b8996a;
}

.status-select {
  border: 1px solid #e8e2d8;
  padding: 8px 12px;
  font-size: 12px;
  font-family: inherit;
  color: #1a1a1a;
  background: #faf9f7;
  outline: none;
  cursor: pointer;
}

.status-select:focus {
  border-color: #b8996a;
}

.empty-row {
  text-align: center;
  padding: 40px !important;
  color: #9a9087;
  font-size: 13px;
}

/* Table */
.products-table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e8e2d8;
}

.products-table th,
.products-table td {
  padding: 12px 16px;
  text-align: left;
  font-size: 13px;
  border-bottom: 1px solid #f0ece6;
  vertical-align: middle;
}

.products-table th {
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #9a9087;
  background: #faf9f7;
}

.thumb {
  width: 44px;
  height: 44px;
  object-fit: cover;
  display: block;
}

.thumb--empty {
  background: #f0ece6;
}

.product-name-link {
  color: #1a1a1a;
  text-decoration: none;
  font-weight: 500;
}

.product-name-link:hover {
  color: #b8996a;
}

.text-muted {
  color: #9a9087;
}

.status-badge {
  display: inline-block;
  padding: 2px 8px;
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.status-badge--active {
  background: #eef5ec;
  color: #2d7a2d;
}
.status-badge--inactive {
  background: #f5f0e8;
  color: #9a7a3a;
}

.actions {
  white-space: nowrap;
}

/* Buttons */
.btn-primary {
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 10px 24px;
  font-size: 12px;
  letter-spacing: 0.1em;
  font-family: inherit;
  cursor: pointer;
}

.btn-primary:hover {
  background: #b8996a;
}

.btn-ghost {
  background: none;
  border: 1px solid #e8e2d8;
  color: #1a1a1a;
  padding: 6px 14px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
  margin-right: 6px;
  text-decoration: none;
  display: inline-block;
}

.btn-ghost:hover {
  border-color: #1a1a1a;
}

.btn-danger {
  background: none;
  border: 1px solid #e0a0a0;
  color: #c0392b;
  padding: 6px 14px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
}

.btn-danger:hover {
  background: #fdf0f0;
}
.btn-danger:disabled {
  opacity: 0.5;
  cursor: default;
}

/* Confirm card */
.confirm-card {
  background: #fff;
  padding: 32px;
  font-family: 'Lora', 'Georgia', serif;
}

.confirm-title {
  font-size: 18px;
  font-weight: 500;
  color: #1a1a1a;
  margin: 0 0 12px;
}

.confirm-body {
  font-size: 14px;
  color: #1a1a1a;
  margin: 0 0 24px;
}

.confirm-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.confirm-error {
  margin-top: 12px;
  font-size: 12px;
  color: #c0392b;
}
</style>
