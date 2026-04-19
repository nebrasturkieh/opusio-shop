<template>
  <v-container class="auth" fluid>
    <div class="auth-inner">
      <h2>Sign in</h2>
      <form @submit.prevent="sendMagicLink">
        <v-text-field v-model="email" label="Email" type="email" required />
        <v-btn :loading="loading" type="submit">Send magic link</v-btn>
      </form>

      <div v-if="message" class="message">{{ message }}</div>
    </div>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const email = ref('')
const message = ref('')
const auth = useAuthStore()

const loading = computed(() => auth.loading)

async function sendMagicLink() {
  message.value = ''
  try {
    await auth.signInWithMagicLink(email.value)
    message.value = 'Magic link sent — check your email.'
  } catch (e) {
    message.value = e.message || 'Error sending magic link.'
  }
}
</script>

<style scoped>
.auth-inner {
  max-width: 420px;
  margin: 60px auto;
}
.message {
  margin-top: 12px;
  color: #2e7d32;
}
</style>
