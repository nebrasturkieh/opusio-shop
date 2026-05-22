<template>
  <div class="products-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Products</h1>
        <p class="page-sub">{{ admin.products.length }} products</p>
      </div>
      <button class="btn-primary" @click="openCreate">+ New Product</button>
    </header>

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
        <tr v-for="product in admin.products" :key="product.id">
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
            <button class="btn-danger" @click="confirmDelete(product)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Product dialog (create / edit) -->
    <ProductDialog v-model="dialogOpen" :product="editing" @saved="admin.fetchProducts()" />

    <!-- Delete confirmation dialog -->
    <v-dialog v-model="deleteDialog" max-width="400" :persistent="false">
      <div class="confirm-card">
        <h3 class="confirm-title">Delete Product</h3>
        <p class="confirm-body">
          Delete <strong>{{ deleting?.name }}</strong
          >? This will also delete all its variants and images.
        </p>
        <div class="confirm-actions">
          <button class="btn-ghost" @click="deleteDialog = false">Cancel</button>
          <button class="btn-danger" :disabled="deleteLoading" @click="doDelete">
            {{ deleteLoading ? 'Deleting…' : 'Delete' }}
          </button>
        </div>
        <div v-if="deleteError" class="confirm-error">{{ deleteError }}</div>
      </div>
    </v-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAdminStore } from '@/stores/admin'
import ProductDialog from '@/components/admin/ProductDialog.vue'

const admin = useAdminStore()

const dialogOpen = ref(false)
const editing = ref(null)

const deleteDialog = ref(false)
const deleting = ref(null)
const deleteLoading = ref(false)
const deleteError = ref(null)

onMounted(() => admin.fetchProducts())

function openCreate() {
  editing.value = null
  dialogOpen.value = true
}

function openEdit(product) {
  editing.value = { ...product }
  dialogOpen.value = true
}

function confirmDelete(product) {
  deleting.value = product
  deleteError.value = null
  deleteDialog.value = true
}

async function doDelete() {
  if (!deleting.value) return
  deleteLoading.value = true
  deleteError.value = null
  try {
    await admin.deleteProduct(deleting.value.id)
    deleteDialog.value = false
  } catch (e) {
    deleteError.value = e.message
  } finally {
    deleteLoading.value = false
  }
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
  margin-bottom: 32px;
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
