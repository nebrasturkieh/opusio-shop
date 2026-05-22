<template>
  <v-app class="app-shell">
    <v-app-bar
      v-if="!isAdminRoute"
      ref="appBarEl"
      height="80"
      elevation="0"
      class="appbar"
      :class="{ 'appbar--visible': showAppBar }"
    >
      <!-- LEFT -->
      <div class="appbar-side appbar-left">
        <v-btn
          variant="text"
          class="contact-btn"
          density="comfortable"
          @click="routerInstance.push({ name: 'contact' })"
        >
          <span class="contact-plus">+</span>
          <span class="contact-label">Contact Us</span>
        </v-btn>
      </div>

      <!-- CENTER -->
      <v-app-bar-title class="text-center">
        <div ref="navLogoAnchor" class="nav-logo-anchor">
          <v-img :src="logoUrl" alt="Opusio" height="80" contain @click="goHome" />
        </div>
      </v-app-bar-title>

      <!-- RIGHT -->
      <div class="appbar-side appbar-right luxury-icons">
        <v-btn icon variant="text" aria-label="Wishlist" class="icon-btn" @click="goWishlist">
          <v-icon :icon="wishlistCount ? 'mdi-heart' : 'mdi-heart-outline'" />
          <span v-if="wishlistCount" class="bag-badge">{{ wishlistCount }}</span>
        </v-btn>

        <v-btn icon variant="text" aria-label="Bag" class="icon-btn" @click="goCart">
          <v-icon icon="mdi-bag-personal-outline" />
          <span v-if="cartCount" class="bag-badge">{{ cartCount }}</span>
        </v-btn>

        <v-btn
          v-if="!auth.isAuthenticated"
          icon
          variant="text"
          aria-label="Account"
          class="icon-btn"
          @click="authDialog = true"
        >
          <v-icon icon="mdi-account-outline" />
        </v-btn>

        <v-menu v-else>
          <template #activator="{ props }">
            <v-btn v-bind="props" icon variant="text" aria-label="Account" class="icon-btn">
              <v-icon icon="mdi-account-outline" />
            </v-btn>
          </template>

          <div class="account-menu">
            <button class="account-menu-item" @click="goProfile">My Profile</button>
            <button class="account-menu-item" @click="handleSignOut">Sign out</button>
          </div>
        </v-menu>

        <v-btn icon variant="text" aria-label="Search" class="icon-btn" @click="searchOpen = true">
          <v-icon icon="mdi-magnify" />
        </v-btn>

        <v-btn variant="text" class="menu-btn" aria-label="Menu" @click="menuOpen = true">
          <v-icon icon="mdi-menu" />
          <span class="menu-label">MENU</span>
        </v-btn>
      </div>
    </v-app-bar>

    <v-main :class="isAdminRoute ? 'main-admin' : 'main-white'">
      <RouterView />
    </v-main>
    <template v-if="!isAdminRoute">
      <LuxuryAuthDialog v-model="authDialog" @register="openRegister" />
      <RegisterDialog v-model="registerDialog" @back="reopenAuth" />
      <!-- sliding cart drawer -->
      <CartDrawer />
      <SearchOverlay v-model="searchOpen" />
      <MenuDrawer v-model="menuOpen" />
    </template>
    <ToastBar />
  </v-app>
</template>

<script setup>
import { RouterView, useRouter, useRoute } from 'vue-router'
import { ref, provide, nextTick, computed, watch, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useCartStore } from '@/stores/cart'
import { useWishlistStore } from '@/stores/wishlist'
import logoUrl from '@/assets/opusio-logo.png'
import CartDrawer from '@/components/CartDrawer.vue'
import LuxuryAuthDialog from '@/components/LuxuryAuthDialog.vue'
import RegisterDialog from '@/components/RegisterDialog.vue'
import ToastBar from '@/components/ToastBar.vue'
import SearchOverlay from '@/components/SearchOverlay.vue'
import MenuDrawer from '@/components/MenuDrawer.vue'

const showAppBar = ref(false)
const navLogoAnchor = ref(null)

// cart badge
const cart = useCartStore()
const wishlist = useWishlistStore()

const cartCount = computed(() => cart.totalItems)
const wishlistCount = computed(() => wishlist.count)

// disable scrolling when drawer is open
watch(
  () => cart.drawerOpen,
  (open) => {
    document.body.style.overflow = open ? 'hidden' : ''
  },
)

const routerInstance = useRouter()
const route = useRoute()

const isAdminRoute = computed(() => route.path.startsWith('/admin'))
const auth = useAuthStore()
const authDialog = ref(false)
const registerDialog = ref(false)
const searchOpen = ref(false)
const menuOpen = ref(false)

onMounted(() => {
  auth.init().catch(() => {
    // ignore init errors; router guard and later auth actions will retry naturally
  })
})

function openRegister() {
  registerDialog.value = true
}

function reopenAuth() {
  authDialog.value = true
}

watch(
  () => auth.isAuthenticated,
  (isAuthenticated) => {
    if (!isAuthenticated) return

    authDialog.value = false
    registerDialog.value = false

    const redirect = route.query.redirect
    if (redirect && typeof redirect === 'string') {
      routerInstance.push(redirect)
    } else if (route.name === 'auth') {
      routerInstance.push({ name: 'profile' })
    }
  },
)

function goProfile() {
  routerInstance.push({ name: 'profile' })
}

async function handleSignOut() {
  try {
    await auth.signOut()
    routerInstance.push({ name: 'home' })
  } catch {
    // ignore
  }
}

function goCart() {
  cart.openDrawer()
}

function goHome() {
  // Navigate to home and jump directly to the catalog section using a hash.
  // The router's scrollBehavior will handle scrolling without flashing the hero.
  routerInstance.push({ name: 'home', hash: '#catalog' })
}

function goWishlist() {
  routerInstance.push({ name: 'wishlist' })
}

// if user navigates to /cart, open drawer instead and stay on current page
watch(
  () => route.name,
  (name) => {
    // Keep hero-driven navbar behavior on home only.
    // All other routes should show the navbar immediately.
    showAppBar.value = name !== 'home'
  },
  { immediate: true },
)

async function getNavLogoRect() {
  if (!showAppBar.value) return null
  await nextTick()
  const el = navLogoAnchor.value
  if (!el) return null
  return el.getBoundingClientRect()
}

provide('showAppBar', showAppBar)
provide('getNavLogoRect', getNavLogoRect)
provide('openAuthDialog', () => {
  authDialog.value = true
})
</script>
<style scoped>
/* ===============================
   GLOBAL WHITE BACKGROUND
================================ */
.app-shell,
.main-white {
  background: #fff !important;
}

/* ===============================
   APP BAR
================================ */
.appbar {
  background: #fff !important;
  backdrop-filter: none !important;
  border-bottom: 1px solid rgba(0, 0, 0, 0.12);
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

/* ===============================
   LAYOUT
================================ */
.appbar-side {
  display: flex;
  align-items: center;
  height: 80px;
  flex: 0 0 auto;
}

/* badge on bag icon — luxury, minimal design */
.bag-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #b8996a;
  color: #fff;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 400;
  line-height: 1;
  border-radius: 50%;
  letter-spacing: 0.01em;
  box-shadow: 0 2px 6px rgba(184, 153, 106, 0.24);
}
.appbar-left {
  width: 185px;
  justify-content: flex-start;
  padding-left: 22px;
}

.appbar-right {
  width: 220px;
  justify-content: flex-end;

  position: relative; /* for badge positioning */
  padding-right: 22px;
  gap: 14px;
}

.nav-logo-anchor {
  height: 80px;
  width: 140px;
  margin: 0 auto;
}

/* ===============================
   GOLD HOVER COLOR (LOCAL)
================================ */
.app-shell {
  --lux-gold-hover: rgba(184, 153, 106, 0.12);
}

/* ===============================
   FIX VUETIFY OPACITY (CRITICAL)
================================ */
.appbar :deep(*) {
  --v-high-emphasis-opacity: 1 !important;
  --v-medium-emphasis-opacity: 1 !important;
  --v-disabled-opacity: 1 !important;
}

/* ===============================
   FORCE TRUE BLACK TEXT & ICONS
================================ */
.appbar :deep(.v-btn),
.appbar :deep(.v-btn__content),
.appbar :deep(.v-btn__content *),
.appbar :deep(.v-icon),
.appbar :deep(.menu-label),
.appbar :deep(.contact-label) {
  color: #1a1a1a !important;
  opacity: 1 !important;
}

/* ===============================
   FIX: STOP TEXT FROM FADING ON HOVER
================================ */
.appbar :deep(.v-btn:hover),
.appbar :deep(.v-btn:hover .v-btn__content),
.appbar :deep(.v-btn:hover .v-btn__content *),
.appbar :deep(.v-btn:hover .contact-label),
.appbar :deep(.v-btn:hover .contact-plus) {
  opacity: 1 !important;
}

/* ===============================
   VUETIFY HOVER OVERLAY (PREMIUM SUBTLE)
================================ */
.appbar :deep(.v-btn .v-btn__overlay) {
  background: transparent;
  opacity: 0;
}

.appbar :deep(.v-btn:hover .v-btn__overlay) {
  opacity: 0;
}

/* ===============================
   CONTACT US
================================ */
.contact-btn {
  text-transform: none !important;
  letter-spacing: 0.06em;
  font-size: 12px;
  padding-left: 0;
  padding-right: 0;
}

.contact-plus {
  margin-right: 6px;
  font-weight: 500;
}

.contact-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  text-transform: none !important;
}

/* ===============================
   ICON BUTTONS — PREMIUM HOVER
================================ */
.icon-btn {
  position: relative;
  transition: all 0.18s ease !important;
}

.icon-btn :deep(.v-icon) {
  font-size: 20px;
  transition: color 0.18s ease;
}

.icon-btn:hover :deep(.v-icon) {
  color: #b8996a !important;
}

/* ===============================
   NAV LOGO
================================ */
.nav-logo-anchor {
  cursor: pointer;
}
.menu-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding-right: 0;
  text-transform: none !important;
}

.menu-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  font-weight: 400;
  line-height: 1;
  text-transform: uppercase;
}

/* ===============================
   ACCOUNT MENU (DROPDOWN)
================================ */
.account-menu {
  background: #fff;
  border: 1px solid rgba(0, 0, 0, 0.08);
  padding: 8px 0;
  min-width: 160px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}

.account-menu-item {
  display: block;
  width: 100%;
  padding: 12px 20px;
  background: transparent;
  border: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  text-align: left;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 400;
  color: #1a1a1a;
  letter-spacing: 0.04em;
  cursor: pointer;
  transition: background 0.15s ease;
  line-height: 1.4;
}

.account-menu-item:last-child {
  border-bottom: none;
}

.account-menu-item:hover {
  background: rgba(184, 153, 106, 0.06);
}
</style>
