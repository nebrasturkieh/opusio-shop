<template>
  <div class="admin-shell">
    <!-- Sidebar -->
    <nav class="admin-nav">
      <div class="admin-nav-brand">
        <span class="brand-name">OPUSIO</span>
        <span class="brand-tag">ADMIN</span>
      </div>

      <div class="admin-nav-links">
        <router-link
          :to="{ name: 'admin-dashboard' }"
          class="nav-link"
          active-class="nav-link--active"
        >
          <v-icon size="16">mdi-view-dashboard-outline</v-icon>
          Dashboard
        </router-link>
        <router-link
          :to="{ name: 'admin-products' }"
          class="nav-link"
          active-class="nav-link--active"
        >
          <v-icon size="16">mdi-diamond-outline</v-icon>
          Products
        </router-link>
        <router-link
          :to="{ name: 'admin-orders' }"
          class="nav-link"
          active-class="nav-link--active"
        >
          <v-icon size="16">mdi-receipt-text-outline</v-icon>
          Orders
        </router-link>
      </div>

      <div class="admin-nav-bottom">
        <router-link to="/" class="nav-link">
          <v-icon size="16">mdi-storefront-outline</v-icon>
          View Shop
        </router-link>
        <button class="nav-link nav-link--btn" @click="handleSignOut">
          <v-icon size="16">mdi-logout</v-icon>
          Sign Out
        </button>
      </div>
    </nav>

    <!-- Main content -->
    <main class="admin-main">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const router = useRouter()

async function handleSignOut() {
  await auth.signOut()
  router.push({ name: 'home' })
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.admin-shell {
  display: flex;
  min-height: 100vh;
  background: #f5f3f0;
  font-family: 'Lora', 'Georgia', serif;
}

/* Sidebar */
.admin-nav {
  width: 220px;
  min-height: 100vh;
  background: #1a1a1a;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  position: sticky;
  top: 0;
  align-self: flex-start;
  height: 100vh;
}

.admin-nav-brand {
  padding: 28px 24px 24px;
  border-bottom: 1px solid #2e2e2e;
}

.brand-name {
  display: block;
  font-size: 13px;
  letter-spacing: 0.25em;
  color: #e8e2d8;
  font-weight: 500;
}

.brand-tag {
  font-size: 9px;
  letter-spacing: 0.3em;
  color: #b8996a;
  font-weight: 400;
}

.admin-nav-links {
  flex: 1;
  padding: 20px 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.admin-nav-bottom {
  padding: 16px 0 24px;
  border-top: 1px solid #2e2e2e;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.nav-link {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 24px;
  color: #9a9087;
  text-decoration: none;
  font-size: 12px;
  letter-spacing: 0.08em;
  transition:
    color 0.15s,
    background 0.15s;
}

.nav-link:hover {
  color: #e8e2d8;
  background: #242424;
}

.nav-link--active {
  color: #b8996a !important;
  background: #242424;
}

.nav-link--btn {
  background: none;
  border: none;
  cursor: pointer;
  width: 100%;
  text-align: left;
  font-family: inherit;
}

/* Main area */
.admin-main {
  flex: 1;
  min-width: 0;
  padding: 0;
  overflow-y: auto;
}
</style>
