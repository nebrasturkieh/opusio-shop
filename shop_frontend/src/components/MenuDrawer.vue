<template>
  <teleport to="body">
    <transition name="menu-slide">
      <div v-if="modelValue" class="menu-overlay" @click.self="close">
        <nav class="menu-drawer" :aria-hidden="!modelValue">
          <div class="menu-top">
            <button class="menu-drawer-close" type="button" aria-label="Close menu" @click="close">
              ✕
            </button>
          </div>

          <ul class="menu-nav">
            <li>
              <button class="menu-nav-item" @click="go('home', '#catalog')">Collection</button>
            </li>
            <li><button class="menu-nav-item" @click="go('wishlist')">Wishlist</button></li>
            <li><button class="menu-nav-item" @click="go('cart')">My Bag</button></li>
            <li v-if="auth.isAuthenticated">
              <button class="menu-nav-item" @click="go('profile')">My Profile</button>
            </li>
            <li v-if="auth.isAuthenticated">
              <button class="menu-nav-item" @click="go('profile')">My Orders</button>
            </li>
            <li><button class="menu-nav-item" @click="go('about')">About Opusio</button></li>
            <li><button class="menu-nav-item" @click="go('contact')">Contact Us</button></li>
          </ul>

          <div class="menu-divider" />

          <div class="menu-footer">
            <a href="mailto:hello@opusio.com" class="menu-contact-link">hello@opusio.com</a>
            <p class="menu-tagline">Handcrafted pieces. Modern soul.</p>
          </div>
        </nav>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

defineProps({
  modelValue: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue'])

const router = useRouter()
const auth = useAuthStore()

function close() {
  emit('update:modelValue', false)
}

function go(name, hash) {
  close()
  router.push(hash ? { name, hash } : { name })
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.menu-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.36);
  z-index: 2500;
  display: flex;
  justify-content: flex-end;
}

.menu-drawer {
  width: 320px;
  max-width: 90vw;
  background: #fff;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 0 0 40px;
  box-shadow: -4px 0 32px rgba(0, 0, 0, 0.1);
}

.menu-top {
  display: flex;
  justify-content: flex-end;
  padding: 22px 24px 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.menu-drawer-close {
  background: transparent;
  border: none;
  cursor: pointer;
  font-size: 14px;
  color: #7a6a59;
  padding: 4px;
  line-height: 1;
  transition: color 0.15s;
}
.menu-drawer-close:hover {
  color: #1a1a1a;
}

.menu-nav {
  list-style: none;
  padding: 24px 0;
  margin: 0;
  flex: 1;
}

.menu-nav-item {
  display: block;
  width: 100%;
  text-align: left;
  background: transparent;
  border: none;
  padding: 16px 32px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  font-weight: 400;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  cursor: pointer;
  transition:
    color 0.15s,
    background 0.15s;
  border-radius: 0;
}
.menu-nav-item:hover {
  color: #b8996a;
  background: rgba(184, 153, 106, 0.04);
}

.menu-divider {
  height: 1px;
  background: rgba(0, 0, 0, 0.06);
  margin: 0 32px;
}

.menu-footer {
  padding: 28px 32px 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.menu-contact-link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #6b5b4a;
  letter-spacing: 0.04em;
  text-decoration: none;
  transition: color 0.15s;
}
.menu-contact-link:hover {
  color: #1a1a1a;
}

.menu-tagline {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #b8b2ab;
  margin: 0;
  font-style: italic;
  letter-spacing: 0.02em;
}

/* transition */
.menu-slide-enter-active,
.menu-slide-leave-active {
  transition: opacity 0.22s ease;
}
.menu-slide-enter-active .menu-drawer,
.menu-slide-leave-active .menu-drawer {
  transition: transform 0.28s cubic-bezier(0.22, 1, 0.36, 1);
}
.menu-slide-enter-from,
.menu-slide-leave-to {
  opacity: 0;
}
.menu-slide-enter-from .menu-drawer,
.menu-slide-leave-to .menu-drawer {
  transform: translateX(100%);
}
</style>
