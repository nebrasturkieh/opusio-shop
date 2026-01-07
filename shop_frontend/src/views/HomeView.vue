<script setup>
import { inject, onMounted, onUnmounted, ref, computed } from 'vue'
import { useProductsStore } from '@/stores/products'
import ProductCard from '@/components/ProductCard.vue'
import logoUrl from '@/assets/opusio-logo.png'

const productsStore = useProductsStore()

// Provided by App.vue
const showAppBar = inject('showAppBar', null)

// how many px to “complete” the hero -> nav animation
const COLLAPSE_DISTANCE = 260

const scrollY = ref(0)

const progress = computed(() => {
  // 0..1
  const p = scrollY.value / COLLAPSE_DISTANCE
  return Math.min(1, Math.max(0, p))
})

function onScroll() {
  scrollY.value = window.scrollY || 0

  // Show the AppBar only when we're near the end of the hero animation
  // (prevents the “instant logo pop” while hero is still visible)
  if (showAppBar) showAppBar.value = progress.value > 0.82
}

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

// Bind CSS variables for smooth animation in CSS
const heroVars = computed(() => ({
  '--p': progress.value,
}))
</script>

<template>
  <!-- HERO -->
  <section class="hero" :style="heroVars">
    <div class="hero-content">
      <!-- Animated logo (gets smaller and moves upward as you scroll) -->
      <img :src="logoUrl" alt="Opusio" class="hero-logo" />

      <!-- Text fades out early so logo never overlaps it when scrolling back up -->
      <div class="hero-text">
        <div class="text-h5 font-weight-regular">Handcrafted pieces. Modern soul.</div>
        <div class="text-body-1 text-medium-emphasis mt-2">Scroll to explore the collection.</div>
        <div class="scroll-hint mt-8">↓</div>
      </div>
    </div>
  </section>

  <!-- PRODUCTS -->
  <v-container class="py-10" style="max-width: 1200px">
    <div class="d-flex align-center justify-space-between mb-6">
      <div class="text-h4 font-weight-medium">Products</div>

      <v-btn
        @click="productsStore.fetchProducts()"
        :loading="productsStore.loading"
        :disabled="productsStore.loading"
        variant="tonal"
      >
        Refresh
      </v-btn>
    </div>

    <v-alert v-if="productsStore.error" type="error" variant="tonal" class="mb-4">
      {{ productsStore.error }}
    </v-alert>

    <v-progress-linear v-if="productsStore.loading" indeterminate class="mb-6" />

    <v-row>
      <v-col v-for="p in productsStore.activeItems" :key="p.id" cols="12" sm="6" md="4" lg="3">
        <ProductCard :product="p" />
      </v-col>
    </v-row>
  </v-container>
</template>

<style scoped>
.hero {
  min-height: 100vh;
  display: grid;
  place-items: center;
  text-align: center;
  padding: 24px;
}

/* keep content nicely centered */
.hero-content {
  max-width: 720px;
  width: 100%;
  position: relative;
}

/*
  p = 0..1 (scroll progress)

  We animate the logo:
  - scale: 1 -> 0.22 (smaller than before)
  - translateY: 0 -> -220px (moves upward toward the appbar area)
  - opacity: stays visible (we keep it classy, not popping)
*/
.hero-logo {
  width: 360px;
  transform-origin: center;
  will-change: transform, opacity;

  transform: translateY(calc(var(--p) * -300px)) scale(calc(1 - (var(--p) * 0.78)));

  opacity: calc(1 - (max(0, (var(--p) - 0.88)) * 8));
}

/*
  Fade the text earlier so when you scroll back up fast,
  the logo doesn't visually sit on top of the tagline.
*/
.hero-text {
  margin-top: 28px;
  will-change: opacity, transform;

  opacity: calc(1 - (var(--p) * 1.35));
  transform: translateY(calc(var(--p) * 14px));
}

/* hide text completely after it’s faded */
.hero-text {
  pointer-events: none;
}

/* nice subtle hint */
.scroll-hint {
  font-size: 22px;
  opacity: 0.35;
  animation: float 1.6s ease-in-out infinite;
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
</style>
