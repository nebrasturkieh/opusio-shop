<template>
  <teleport to="body">
    <transition-group name="toast" tag="ul" class="toast-list" aria-live="polite">
      <li
        v-for="toast in toastState.items"
        :key="toast.id"
        :class="['toast-item', 'toast-item--' + toast.type]"
      >
        <span class="toast-dot" />
        <span class="toast-msg">{{ toast.message }}</span>
      </li>
    </transition-group>
  </teleport>
</template>

<script setup>
import { toastState } from '@/lib/toast'
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500&display=swap');

.toast-list {
  position: fixed;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  z-index: 9999;
  pointer-events: none;
}

.toast-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 13px 22px;
  background: #1a1a1a;
  color: #f5f2ee;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  letter-spacing: 0.04em;
  white-space: nowrap;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.18);
  border-radius: 0;
}

.toast-item--error {
  background: #2d1014;
  color: #f8d0d5;
}

.toast-item--info {
  background: #1a1a2e;
  color: #d0d8f8;
}

.toast-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  flex-shrink: 0;
  background: #b8996a;
}

.toast-item--error .toast-dot {
  background: #e87a8a;
}

.toast-item--info .toast-dot {
  background: #7a9ae8;
}

/* transitions */
.toast-enter-active {
  transition:
    opacity 0.22s ease,
    transform 0.22s ease;
}
.toast-leave-active {
  transition:
    opacity 0.28s ease,
    transform 0.28s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateY(10px);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(6px);
}
</style>
