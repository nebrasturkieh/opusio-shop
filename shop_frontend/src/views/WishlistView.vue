<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useWishlistStore } from '@/stores/wishlist'
import ProductCard from '@/components/ProductCard.vue'

const wishlist = useWishlistStore()

const items = computed(() => wishlist.items)

function remove(productId) {
  wishlist.remove(productId)
}
</script>

<template>
  <section class="wishlist">
    <div class="wishlist-inner">
      <header class="wishlist-header">
        <h1 class="wishlist-title">
          MY WISHLIST
          <span class="wishlist-count"
            >({{ items.length }} {{ items.length === 1 ? 'Saved Item' : 'Saved Items' }})</span
          >
        </h1>
        <p class="wishlist-desc">
          Save the pieces that inspire you. Your selection is reserved here for a seamless return to
          the collection.
        </p>
      </header>

      <div v-if="items.length === 0" class="wishlist-empty">
        <h2 class="empty-title">Your wishlist is empty</h2>
        <p class="empty-copy">Discover our curated collections and add your favourites.</p>
        <RouterLink to="/#catalog" class="empty-link">Continue shopping</RouterLink>
      </div>

      <v-container v-else fluid class="wishlist-grid-wrap">
        <v-row class="wishlist-row" align="stretch">
          <v-col v-for="product in items" :key="product.id" cols="12" sm="6" md="4" lg="3">
            <ProductCard :product="product" :isWishlist="true" :onRemove="remove" />
          </v-col>
        </v-row>

        <!-- Continue shopping -->
        <div class="wishlist-continue">
          <RouterLink to="/#catalog" class="wishlist-continue-link">‹ CONTINUE SHOPPING</RouterLink>
        </div>
      </v-container>
    </div>
  </section>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.wishlist {
  background: #fff;
  padding: 72px 0 100px;
}

.wishlist-inner {
  max-width: 1000px;
  margin: 0 auto;
  padding: 0 24px;
}

/* ── header ── */
.wishlist-header {
  text-align: center;
  margin-bottom: 52px;
}

.wishlist-title {
  margin: 0 0 12px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 22px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-weight: 400;
  color: #1a1a1a;
}

.wishlist-count {
  font-family: 'Lora', 'Georgia', serif;
  font-weight: 400;
  color: #7a6a59;
  margin-left: 8px;
  font-size: 22px;
  letter-spacing: 0.12em;
}

.wishlist-desc {
  margin: 0 auto;
  max-width: 620px;
  font-family: 'Lora', 'Georgia', serif;
  color: #6b5b4a;
  font-size: 13px;
  line-height: 1.8;
  letter-spacing: 0.01em;
}

/* ── empty state ── */
.wishlist-empty {
  border: none;
  background: transparent;
  padding: 120px 0 80px;
  text-align: center;
}

.empty-title {
  margin: 0 0 12px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 18px;
  font-weight: 400;
  letter-spacing: 0.08em;
  color: #1a1a1a;
}

.empty-copy {
  margin: 0 0 32px;
  max-width: 600px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #7a6a59;
  line-height: 1.8;
}

.empty-link {
  display: inline-block;
  margin-top: 32px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: #1a1a1a;
  text-decoration: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.3);
  padding-bottom: 2px;
  opacity: 1;
  transition: opacity 0.15s;
}

.empty-link:hover {
  opacity: 0.6;
}

.wishlist-grid-wrap {
  padding: 0 !important;
}

.wishlist-row {
  margin-top: 0;
  margin-bottom: 28px;
}

.wishlist-row :deep(.v-col) {
  padding: 0;
}

.wishlist-row :deep(.v-col) > div {
  padding-right: 0;
  padding-bottom: 0;
}

.wishlist-row :deep(.v-col):not(:last-child) > div {
  margin-right: 24px;
  margin-bottom: 24px;
}

.wishlist-row :deep(.v-col:last-child) > div {
  margin-bottom: 0;
}
.wishlist-continue {
  padding-top: 28px;
  border-top: 1px solid rgba(0, 0, 0, 0.06);
}

.wishlist-continue-link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: #1a1a1a;
  text-decoration: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.3);
  padding-bottom: 2px;
  transition: opacity 0.15s;
}

.wishlist-continue-link:hover {
  opacity: 0.6;
}

/* ── responsive ── */
@media (max-width: 880px) {
  .wishlist-header {
    margin-bottom: 40px;
  }
}

@media (max-width: 520px) {
  .wishlist {
    padding: 60px 0 80px;
  }

  .wishlist-inner {
    padding: 0 20px;
  }

  .wishlist-header {
    margin-bottom: 40px;
  }

  .wishlist-title {
    font-size: 18px;
  }
}
</style>
