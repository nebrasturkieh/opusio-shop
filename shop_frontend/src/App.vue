<template>
  <v-app>
    <!-- Keep app-bar always mounted -->
    <v-app-bar
      ref="appBarEl"
      height="80"
      elevation="0"
      class="appbar"
      :class="{ 'appbar--visible': showAppBar }"
    >
      <!-- LEFT: + Contact Us (inset to the right) -->
      <div class="appbar-side appbar-left">
        <v-btn variant="text" class="contact-btn" density="comfortable">
          <span class="contact-plus">+</span>
          <span>Contact Us</span>
        </v-btn>
      </div>

      <!-- CENTER: logo -->
      <v-app-bar-title class="text-center">
        <div ref="navLogoAnchor" class="nav-logo-anchor">
          <v-img :src="logoUrl" alt="Opusio" height="80" contain />
        </div>
      </v-app-bar-title>

      <!-- RIGHT: icons (inset to the left) -->
      <div class="appbar-side appbar-right luxury-icons">
        <v-btn icon variant="text" aria-label="Bag">
          <v-icon icon="mdi-bag-personal-outline" />
        </v-btn>

        <v-btn icon variant="text" aria-label="Account">
          <v-icon icon="mdi-account-outline" />
        </v-btn>

        <v-btn icon variant="text" aria-label="Search">
          <v-icon icon="mdi-magnify" />
        </v-btn>

        <v-btn variant="text" class="menu-btn" aria-label="Menu">
          <v-icon icon="mdi-menu" />
          <span class="menu-label">Menu</span>
        </v-btn>
      </div>
    </v-app-bar>

    <v-main>
      <RouterView />
    </v-main>
  </v-app>
</template>

<script setup>
import { RouterView } from 'vue-router'
import { ref, provide, nextTick } from 'vue'
import logoUrl from '@/assets/opusio-logo.png'

const showAppBar = ref(false)

const navLogoAnchor = ref(null)

async function getNavLogoRect() {
  if (!showAppBar.value) return null
  await nextTick()
  const el = navLogoAnchor.value
  if (!el) return null
  return el.getBoundingClientRect()
}

provide('showAppBar', showAppBar)
provide('getNavLogoRect', getNavLogoRect)
</script>

<style scoped>
.appbar {
  background-color: #ffffff !important;
  backdrop-filter: none;

  /* subtle luxury divider */
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);

  z-index: 2000;

  opacity: 0;
  transform: translateY(-12px);
  pointer-events: none;

  transition:
    opacity 420ms cubic-bezier(0.22, 1, 0.36, 1),
    transform 420ms cubic-bezier(0.22, 1, 0.36, 1);
}

.appbar--visible {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.appbar,
.appbar * {
  color: #000000 !important;
}

.appbar :deep(.v-icon) {
  color: #000000 !important;
}

.appbar-side {
  display: flex;
  align-items: center;
  height: 80px;
  flex: 0 0 auto;
}

.appbar-left {
  width: 170px;
  justify-content: flex-start;
  padding-left: 22px;
}

.appbar-right {
  width: 190px;
  justify-content: flex-end;
  padding-right: 22px;
  gap: 14px;
}

.nav-logo-anchor {
  height: 80px;
  width: 120px;
  margin: 0 auto;
}

.luxury-icons :deep(.v-icon) {
  font-size: 20px;
  opacity: 1;
  transition: opacity 200ms ease;
}

.luxury-icons :deep(.v-btn:hover) .v-icon {
  opacity: 0.75;
}

.contact-btn {
  text-transform: none !important;
  font-size: 13px;
  letter-spacing: 0.08em;
  opacity: 0.9;
}

.menu-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding-right: 0;
  opacity: 0.9;
}

.menu-label {
  font-size: 12px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  opacity: 0.9;
  line-height: 1;
}
</style>
