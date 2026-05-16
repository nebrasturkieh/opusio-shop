<script setup>
import { inject, onMounted, onUnmounted, ref, computed } from 'vue'
import { useProductsStore } from '@/stores/products'
import ProductCard from '@/components/ProductCard.vue'
import logoUrl from '@/assets/opusio-logo.png'

const productsStore = useProductsStore()

// Provided by App.vue
const showAppBar = inject('showAppBar', null)

// Hero animation
const COLLAPSE_DISTANCE = 260
const scrollY = ref(0)

const progress = computed(() => {
  const p = scrollY.value / COLLAPSE_DISTANCE
  return Math.min(1, Math.max(0, p))
})

function onScroll() {
  scrollY.value = window.scrollY || 0
  if (showAppBar) showAppBar.value = progress.value > 0.82
}

// Products UI state
const viewMode = ref('grid') // 'grid' | 'feed'
const sortBy = ref('recommended') // recommended | high | low

const selected = ref({
  category: null,
  collection: null,
  material: null,
  paving: null,
})

// Dialogs (center popups)
const sortDialog = ref(false)
const filterDialog = ref(false)

function openSort() {
  sortDialog.value = true
}
function openFilter() {
  filterDialog.value = true
}
function clearFilters() {
  selected.value.category = null
  selected.value.collection = null
  selected.value.material = null
  selected.value.paving = null
}

// Helpers
function getField(p, key) {
  const v = p?.[key]
  if (v === null || v === undefined || v === '') return null
  return String(v)
}

function priceNumber(p) {
  // supports "0.25 'EUR'" etc.
  const raw = String(p?.price ?? p?.price_eur ?? p?.amount ?? '')
  const n = parseFloat(raw.replace(',', '.').replace(/[^\d.]/g, ''))
  return Number.isFinite(n) ? n : 0
}

const allProducts = computed(() => productsStore.activeItems || [])

const options = computed(() => {
  const uniq = (arr) =>
    Array.from(new Set(arr))
      .filter(Boolean)
      .sort((a, b) => a.localeCompare(b))

  const cats = uniq(allProducts.value.map((p) => getField(p, 'category') || 'Other'))
  const colls = uniq(allProducts.value.map((p) => getField(p, 'collection')))
  const mats = uniq(allProducts.value.map((p) => getField(p, 'material')))
  const pavs = uniq(allProducts.value.map((p) => getField(p, 'paving')))

  return {
    category: cats,
    collection: colls,
    material: mats,
    paving: pavs,
  }
})

const filteredProducts = computed(() => {
  let items = [...allProducts.value]

  const apply = (key, value) => {
    if (!value) return
    items = items.filter((p) => {
      const v = getField(p, key)
      if (!v) return value === 'Other' && key === 'category'
      return v === value
    })
  }

  apply('category', selected.value.category)
  apply('collection', selected.value.collection)
  apply('material', selected.value.material)
  apply('paving', selected.value.paving)

  if (sortBy.value === 'high') {
    items.sort((a, b) => priceNumber(b) - priceNumber(a))
  } else if (sortBy.value === 'low') {
    items.sort((a, b) => priceNumber(a) - priceNumber(b))
  } else if (sortBy.value === 'recommended') {
    // Recommended: Sort by newest first (most recent created_at)
    items.sort((a, b) => {
      const dateA = new Date(a.created_at || 0)
      const dateB = new Date(b.created_at || 0)
      return dateB - dateA // Newest first
    })
  }

  return items
})

const modelCountLabel = computed(() => `${filteredProducts.value.length} Models`)

const heroVars = computed(() => ({
  '--p': progress.value,
}))

async function loadProducts() {
  await productsStore.fetchProducts()
}

onMounted(async () => {
  await loadProducts()
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
})

onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
})
</script>

<template>
  <!-- HERO -->
  <section class="hero" :style="heroVars">
    <div class="hero-content">
      <img :src="logoUrl" alt="Opusio" class="hero-logo" />

      <div class="hero-text">
        <h1 class="hero-title">Handcrafted pieces. Modern soul.</h1>
        <p class="hero-subtitle">Scroll to explore the collection.</p>
        <div class="scroll-hint">↓</div>
      </div>
    </div>
  </section>

  <!-- CATALOG -->
  <v-container id="catalog" class="catalog" fluid>
    <div class="catalog-inner">
      <v-row align="start" class="catalog-row">
        <!-- LEFT: minimal triggers -->
        <v-col cols="12" md="3" lg="3" class="rail">
          <div class="rail-block">
            <button class="rail-trigger" @click="openSort">
              <span class="rail-trigger__label">Sort</span>
              <v-icon icon="mdi-sort" size="18" />
            </button>

            <button class="rail-trigger" @click="openFilter">
              <span class="rail-trigger__label">Filter</span>
              <v-icon icon="mdi-tune-variant" size="18" />
            </button>
          </div>
        </v-col>

        <!-- RIGHT CONTENT -->
        <v-col cols="12" md="9" lg="9" class="content">
          <div class="content-top">
            <div class="models">{{ modelCountLabel }}</div>

            <div class="view-toggle">
              <button
                class="toggle"
                :class="{ active: viewMode === 'grid' }"
                @click="viewMode = 'grid'"
              >
                GRID
                <v-icon icon="mdi-view-grid-outline" size="18" />
              </button>

              <button
                class="toggle"
                :class="{ active: viewMode === 'feed' }"
                @click="viewMode = 'feed'"
              >
                FEED
                <v-icon icon="mdi-view-day-outline" size="18" />
              </button>
            </div>
          </div>

          <div v-if="productsStore.error" class="error">
            {{ productsStore.error }}
          </div>

          <div v-if="productsStore.loading" class="loading">Loading…</div>

          <!-- GRID -->
          <v-row v-if="viewMode === 'grid'" class="products-grid" dense>
            <v-col
              v-for="p in filteredProducts"
              :key="p.id"
              cols="12"
              sm="6"
              md="4"
              lg="3"
              class="product-col"
            >
              <ProductCard :product="p" />
            </v-col>
          </v-row>

          <!-- FEED -->
          <div v-else class="products-feed">
            <div v-for="p in filteredProducts" :key="p.id" class="feed-item">
              <ProductCard :product="p" />
            </div>
          </div>
        </v-col>
      </v-row>

      <!-- SORT DIALOG (CENTER) -->
      <v-dialog v-model="sortDialog" width="520" class="lux-dialog">
        <div class="lux-card">
          <div class="lux-head">
            <div class="lux-title">Sort</div>
            <button class="lux-close" @click="sortDialog = false">
              <v-icon icon="mdi-close" size="18" />
            </button>
          </div>

          <div class="lux-body">
            <div class="lux-section-title">Sort by</div>

            <v-radio-group v-model="sortBy" class="lux-radio" hide-details>
              <v-radio value="recommended" label="Recommended" />
              <v-radio value="high" label="Price: High to Low" />
              <v-radio value="low" label="Price: Low to High" />
            </v-radio-group>
          </div>

          <div class="lux-actions">
            <button class="lux-btn lux-btn--ghost" @click="sortDialog = false">Close</button>
            <button class="lux-btn" @click="sortDialog = false">Apply</button>
          </div>
        </div>
      </v-dialog>

      <!-- FILTER DIALOG (CENTER) -->
      <v-dialog v-model="filterDialog" width="720" class="lux-dialog">
        <div class="lux-card">
          <div class="lux-head">
            <div class="lux-title">Filter</div>
            <button class="lux-close" @click="filterDialog = false">
              <v-icon icon="mdi-close" size="18" />
            </button>
          </div>

          <div class="lux-body">
            <div class="lux-grid">
              <!-- CATEGORY -->
              <div class="lux-block">
                <div class="lux-section-title">Category</div>
                <div class="lux-chiplist">
                  <button
                    class="lux-chip"
                    :class="{ active: selected.category === null }"
                    @click="selected.category = null"
                  >
                    All
                  </button>
                  <button
                    v-for="c in options.category"
                    :key="c"
                    class="lux-chip"
                    :class="{ active: selected.category === c }"
                    @click="selected.category = c"
                  >
                    {{ c }}
                  </button>
                </div>
              </div>

              <!-- COLLECTION -->
              <div class="lux-block">
                <div class="lux-section-title">Collection</div>
                <div class="lux-chiplist">
                  <button
                    class="lux-chip"
                    :class="{ active: selected.collection === null }"
                    @click="selected.collection = null"
                  >
                    All
                  </button>
                  <button
                    v-for="c in options.collection"
                    :key="c"
                    class="lux-chip"
                    :class="{ active: selected.collection === c }"
                    @click="selected.collection = c"
                  >
                    {{ c }}
                  </button>
                </div>
              </div>

              <!-- MATERIAL -->
              <div class="lux-block">
                <div class="lux-section-title">Material</div>
                <div class="lux-chiplist">
                  <button
                    class="lux-chip"
                    :class="{ active: selected.material === null }"
                    @click="selected.material = null"
                  >
                    All
                  </button>
                  <button
                    v-for="m in options.material"
                    :key="m"
                    class="lux-chip"
                    :class="{ active: selected.material === m }"
                    @click="selected.material = m"
                  >
                    {{ m }}
                  </button>
                </div>
              </div>

              <!-- PAVING -->
              <div class="lux-block">
                <div class="lux-section-title">Paving</div>
                <div class="lux-chiplist">
                  <button
                    class="lux-chip"
                    :class="{ active: selected.paving === null }"
                    @click="selected.paving = null"
                  >
                    All
                  </button>
                  <button
                    v-for="p in options.paving"
                    :key="p"
                    class="lux-chip"
                    :class="{ active: selected.paving === p }"
                    @click="selected.paving = p"
                  >
                    {{ p }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="lux-actions">
            <button class="lux-btn lux-btn--ghost" @click="clearFilters()">Clear</button>
            <button class="lux-btn lux-btn--ghost" @click="filterDialog = false">Close</button>
            <button class="lux-btn" @click="filterDialog = false">Apply</button>
          </div>
        </div>
      </v-dialog>
    </div>
  </v-container>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

/* HERO (unchanged) */
.hero {
  min-height: 100vh;
  display: grid;
  place-items: center;
  text-align: center;
  padding: 24px;
}
.hero-content {
  max-width: 720px;
  width: 100%;
  position: relative;
}
.hero-logo {
  width: 360px;
  transform-origin: center;
  will-change: transform, opacity;
  transform: translateY(calc(var(--p) * -300px)) scale(calc(1 - (var(--p) * 0.78)));
  opacity: calc(1 - (max(0, (var(--p) - 0.88)) * 8));
}
.hero-text {
  margin-top: 28px;
  will-change: opacity, transform;
  opacity: calc(1 - (var(--p) * 1.35));
  transform: translateY(calc(var(--p) * 14px));
  pointer-events: none;
  font-family: 'Lora', 'Georgia', serif;
}

.hero-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 32px;
  font-weight: 400;
  letter-spacing: 0.08em;
  color: #1a1a1a;
  margin: 0 0 12px;
  line-height: 1.4;
}

.hero-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  font-weight: 400;
  letter-spacing: 0.02em;
  color: #6b5b4a;
  margin: 0 0 24px;
  line-height: 1.7;
}
.scroll-hint {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 20px;
  color: #1a1a1a;
  opacity: 0.4;
  animation: float 1.6s ease-in-out infinite;
  margin-top: 32px;
}
@keyframes float {
  0% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(8px);
  }
  100% {
    transform: translateY(0px);
  }
}

/* CATALOG */
.catalog {
  background: #fff;
}
.catalog-inner {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px 22px 80px;
}
.catalog-row {
  margin-top: 10px;
}

/* LEFT TRIGGERS */
.rail {
  padding-right: 34px;
}
.rail-block {
  position: sticky;
  top: 112px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.rail-trigger {
  all: unset;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;

  padding: 12px 12px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.12);

  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  opacity: 0.9;

  border-radius: 0;
  transition:
    background-color 160ms ease,
    opacity 160ms ease;
}

.rail-trigger:hover {
  background: rgba(184, 153, 106, 0.08);
  opacity: 1;
}

.rail-trigger__label {
  color: #1a1a1a;
}

/* TOP LINE (models + toggles) */
.content-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0 22px;
}
.models {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  opacity: 0.9;
}

.view-toggle {
  display: flex;
  align-items: center;
  gap: 18px;
}

.toggle {
  all: unset;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  opacity: 0.65;
  padding: 6px 2px;
  transition: opacity 160ms ease;
}
.toggle:hover {
  opacity: 0.92;
}
.toggle.active {
  opacity: 1;
  position: relative;
}
.toggle.active::after {
  content: '';
  position: absolute;
  left: 0;
  bottom: -6px;
  width: 44px;
  height: 2px;
  background: #b8996a;
  border-radius: 0;
}

.products-grid {
  margin-top: 6px;
}
.product-col {
  padding-top: 18px;
}

.products-feed {
  display: grid;
  gap: 18px;
  margin-top: 10px;
}

.error {
  font-family: 'Lora', 'Georgia', serif;
  margin: 10px 0 16px;
  font-size: 13px;
  color: #6b5b4a;
  opacity: 0.8;
}
.loading {
  font-family: 'Lora', 'Georgia', serif;
  margin: 10px 0 16px;
  font-size: 13px;
  color: #6b5b4a;
  opacity: 0.7;
}

/* ==========================
   LUX DIALOG (CENTER POPUP)
========================== */
.lux-dialog :deep(.v-overlay__content) {
  border-radius: 0;
}

/* soften backdrop a touch */
.lux-dialog :deep(.v-overlay__scrim) {
  opacity: 0.28;
}

.lux-card {
  background: #fff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  border-radius: 0;
  overflow: hidden;
}

.lux-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 18px 14px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.lux-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  font-weight: 400;
}

.lux-close {
  all: unset;
  cursor: pointer;
  border-radius: 0;
  padding: 6px;
  color: #b8996a;
  transition: color 0.15s;
}
.lux-close:hover {
  color: #1a1a1a;
}

.lux-body {
  padding: 20px 18px 18px;
}

.lux-section-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  opacity: 0.8;
  margin-bottom: 14px;
  color: #1a1a1a;
  font-weight: 400;
}

/* Radio labels */
.lux-radio :deep(.v-label) {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  letter-spacing: 0.01em;
  opacity: 0.9;
  color: #1a1a1a;
}

/* Filter layout */
.lux-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px 22px;
}
@media (max-width: 900px) {
  .lux-grid {
    grid-template-columns: 1fr;
  }
}

.lux-chiplist {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.lux-chip {
  all: unset;
  cursor: pointer;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  opacity: 0.72;
  padding: 8px 10px;
  border-radius: 0;
  transition:
    background-color 160ms ease,
    opacity 160ms ease;
  color: #1a1a1a;
}

.lux-chip:hover {
  background: rgba(184, 153, 106, 0.08);
  opacity: 0.95;
}

.lux-chip.active {
  opacity: 1;
  text-decoration: none;
  position: relative;
  background: rgba(184, 153, 106, 0.06);
  border-bottom: 2px solid #b8996a;
}

.lux-chip.active::after {
  content: none;
}

/* Actions */
.lux-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 16px 18px 18px;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
}

.lux-btn {
  all: unset;
  cursor: pointer;
  height: 40px;
  padding: 0 18px;
  background: #1a1a1a;
  color: #fff;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  border: 1px solid #1a1a1a;
  border-radius: 0;
  transition: all 0.15s ease;
  font-weight: 400;
  display: flex;
  align-items: center;
  justify-content: center;
}

.lux-btn--ghost {
  background: transparent;
  color: #1a1a1a;
  border: 1px solid #1a1a1a;
}

.lux-btn:hover {
  background: #2a2a2a;
  border-color: #2a2a2a;
}

.lux-btn--ghost:hover {
  background: rgba(0, 0, 0, 0.04);
}
</style>
