<template>
  <div class="auth-page">
    <div class="auth-wrap">
      <div class="auth-brand">OPUSIO</div>
      <p class="auth-hint">A sign-in window is opening&hellip;</p>
      <button class="auth-reopen-btn" type="button" @click="open">
        Click here if it did not appear
      </button>
    </div>
  </div>
</template>

<script setup>
import { inject, onMounted } from 'vue'

const openAuthDialog = inject('openAuthDialog', null)

function open() {
  openAuthDialog?.()
}

onMounted(() => {
  open()
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.auth-page {
  background: #fff;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
}

.auth-wrap {
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.auth-brand {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 18px;
  font-weight: 400;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: #1a1a1a;
}

.auth-hint {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #7a6a59;
  margin: 0;
  letter-spacing: 0.02em;
  line-height: 1.7;
}

.auth-reopen-btn {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  background: transparent;
  border: 1px solid rgba(0, 0, 0, 0.2);
  padding: 12px 28px;
  cursor: pointer;
  border-radius: 0;
  transition: background 0.15s;
}

.auth-reopen-btn:hover {
  background: rgba(0, 0, 0, 0.03);
}
</style>
