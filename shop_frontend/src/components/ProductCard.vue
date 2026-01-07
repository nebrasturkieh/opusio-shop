<script setup>
defineProps({
  product: {
    type: Object,
    required: true,
  },
})
</script>

<template>
  <v-card rounded="lg" elevation="2">
    <v-card-title class="text-subtitle-1">
      {{ product.name }}
    </v-card-title>
    <v-img
      :src="product.image_url || undefined"
      aspect-ratio="1"
      height="160"
      cover
      class="rounded-t-lg"
    >
      <template #placeholder>
        <div class="d-flex align-center justify-center fill-height text-medium-emphasis">
          No image
        </div>
      </template>
    </v-img>

    <v-card-text>
      <div class="text-body-2 mb-2" style="min-height: 44px">
        {{ product.description || 'No description' }}
      </div>

      <div class="d-flex align-center justify-space-between">
        <div class="text-h6">
          {{ (product.price_cents / 100).toFixed(2) }} {{ product.currency }}
        </div>

        <v-chip size="small" variant="tonal">
          {{ product.slug }}
        </v-chip>
      </div>
    </v-card-text>

    <v-card-actions>
      <v-btn variant="tonal" block> Add to cart </v-btn>
    </v-card-actions>
  </v-card>
</template>
