<template>
  <div class="detail-page">
    <!-- Back -->
    <router-link :to="{ name: 'admin-products' }" class="back-link">← Products</router-link>

    <div v-if="!product && !admin.productsLoading" class="not-found">Product not found.</div>
    <div v-else-if="admin.productsLoading" class="loading">Loading…</div>

    <template v-else-if="product">
      <!-- Product header -->
      <div class="detail-header">
        <div>
          <h1 class="detail-title">{{ product.name }}</h1>
          <span
            :class="[
              'status-badge',
              product.is_active ? 'status-badge--active' : 'status-badge--inactive',
            ]"
          >
            {{ product.is_active ? 'Active' : 'Draft' }}
          </span>
        </div>
        <button class="btn-ghost" @click="editProduct">Edit Product</button>
      </div>

      <!-- Variants section -->
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Variants</h2>
          <button class="btn-primary" @click="openCreateVariant">+ Add Variant</button>
        </div>

        <div v-if="!product.product_variants?.length" class="empty">No variants yet.</div>

        <table v-else class="variants-table">
          <thead>
            <tr>
              <th>SKU</th>
              <th>Material / Color</th>
              <th>Size</th>
              <th>Finish</th>
              <th>Stone</th>
              <th>Price</th>
              <th>Stock</th>
              <th>Status</th>
              <th>Images</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="variant in product.product_variants" :key="variant.id">
              <td class="mono">{{ variant.sku || '—' }}</td>
              <td>{{ variant.material_color || '—' }}</td>
              <td>{{ variant.size || '—' }}</td>
              <td>{{ variant.finish || '—' }}</td>
              <td>{{ variant.stone || '—' }}</td>
              <td>{{ formatPrice(variant.price_cents) }}</td>
              <td>{{ variant.stock_quantity ?? '—' }}</td>
              <td>
                <span
                  :class="[
                    'status-badge',
                    variant.is_active ? 'status-badge--active' : 'status-badge--inactive',
                  ]"
                >
                  {{ variant.is_active ? 'Active' : 'Off' }}
                </span>
              </td>
              <td>{{ variant.variant_images?.length ?? 0 }}</td>
              <td class="actions">
                <button class="btn-ghost" @click="openEditVariant(variant)">Edit</button>
                <button class="btn-ghost" @click="openImages(variant)">Images</button>
                <button
                  :class="variant.is_active ? 'btn-danger' : 'btn-ghost'"
                  @click="toggleVariantActive(variant)"
                >
                  {{ variant.is_active ? 'Deactivate' : 'Activate' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </section>
    </template>

    <!-- Dialogs -->
    <ProductDialog v-model="productDialogOpen" :product="product" @saved="admin.fetchProducts()" />

    <VariantDialog
      v-model="variantDialogOpen"
      :variant="editingVariant"
      :product-id="product?.id"
      @saved="admin.fetchProducts()"
    />

    <VariantImagesPanel
      v-model="imagesDialogOpen"
      :variant="imagesVariant"
      @saved="admin.fetchProducts()"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAdminStore } from '@/stores/admin'
import ProductDialog from '@/components/admin/ProductDialog.vue'
import VariantDialog from '@/components/admin/VariantDialog.vue'
import VariantImagesPanel from '@/components/admin/VariantImagesPanel.vue'

const props = defineProps({ id: { type: String, required: true } })

const admin = useAdminStore()

const product = computed(
  () => admin.products.find((p) => String(p.id) === String(props.id)) ?? null,
)

onMounted(() => {
  if (!admin.products.length) admin.fetchProducts()
})

const formatPrice = (cents) =>
  cents != null
    ? new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)
    : '—'

// Product edit
const productDialogOpen = ref(false)
function editProduct() {
  productDialogOpen.value = true
}

// Variant create/edit
const variantDialogOpen = ref(false)
const editingVariant = ref(null)

function openCreateVariant() {
  editingVariant.value = null
  variantDialogOpen.value = true
}

function openEditVariant(variant) {
  editingVariant.value = { ...variant }
  variantDialogOpen.value = true
}

// Variant images
const imagesDialogOpen = ref(false)
const imagesVariant = ref(null)

function openImages(variant) {
  imagesVariant.value = variant
  imagesDialogOpen.value = true
}

async function toggleVariantActive(variant) {
  await admin.updateVariant(variant.id, { is_active: !variant.is_active })
}
</script>

<style scoped>
.detail-page {
  padding: 36px 48px;
  font-family: 'Lora', 'Georgia', serif;
}

.back-link {
  font-size: 12px;
  letter-spacing: 0.08em;
  color: #b8996a;
  text-decoration: none;
  display: inline-block;
  margin-bottom: 24px;
}

.back-link:hover {
  color: #1a1a1a;
}

.not-found,
.loading {
  padding: 60px;
  text-align: center;
  font-size: 14px;
  color: #6b5b4a;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 36px;
  gap: 16px;
}

.detail-title {
  font-size: 26px;
  font-weight: 500;
  color: #1a1a1a;
  margin: 0 0 8px;
  letter-spacing: 0.04em;
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

.section {
  margin-bottom: 40px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-size: 16px;
  font-weight: 500;
  color: #1a1a1a;
  letter-spacing: 0.06em;
  margin: 0;
}

.empty {
  padding: 32px;
  text-align: center;
  font-size: 13px;
  color: #9a9087;
  background: #fff;
  border: 1px solid #e8e2d8;
}

.variants-table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e8e2d8;
  font-size: 13px;
}

.variants-table th,
.variants-table td {
  padding: 10px 14px;
  text-align: left;
  border-bottom: 1px solid #f0ece6;
  vertical-align: middle;
}

.variants-table th {
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

.actions {
  white-space: nowrap;
}

/* Buttons */
.btn-primary {
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 9px 22px;
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
  padding: 5px 12px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
  margin-right: 4px;
}
.btn-ghost:hover {
  border-color: #1a1a1a;
}

.btn-danger {
  background: none;
  border: 1px solid #e0a0a0;
  color: #c0392b;
  padding: 5px 12px;
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

/* Confirm */
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
