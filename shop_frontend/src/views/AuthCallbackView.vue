<template>
  <v-container class="callback" fluid>
    <div class="callback-card">
      <!-- Recovery: set new password form -->
      <template v-if="mode === 'recovery'">
        <h2 class="callback-title">SET NEW PASSWORD</h2>

        <p v-if="recoveryState === 'idle'" class="callback-subtitle">
          Choose a new password for your account.
        </p>

        <form
          v-if="recoveryState === 'idle'"
          @submit.prevent="submitNewPassword"
          class="recovery-form"
        >
          <p v-if="recoveryError" class="recovery-error">{{ recoveryError }}</p>

          <div class="recovery-group">
            <label class="recovery-label">New Password</label>
            <input
              v-model="newPassword"
              type="password"
              class="recovery-input"
              autocomplete="new-password"
              minlength="8"
              required
            />
          </div>

          <div class="recovery-group">
            <label class="recovery-label">Confirm Password</label>
            <input
              v-model="confirmPassword"
              type="password"
              class="recovery-input"
              autocomplete="new-password"
              minlength="8"
              required
            />
          </div>

          <button type="submit" class="callback-btn-plain" :disabled="recoverySaving">
            {{ recoverySaving ? 'SAVING...' : 'UPDATE PASSWORD' }}
          </button>
        </form>

        <div v-else-if="recoveryState === 'success'" class="callback-success">
          <p class="callback-subtitle">Your password has been updated successfully.</p>
          <v-btn class="callback-btn" @click="goToProfile">Go to my account</v-btn>
        </div>

        <div v-else class="callback-success">
          <p class="callback-subtitle">Something went wrong. Please request a new reset link.</p>
          <v-btn class="callback-btn" @click="goToSignIn">Back to sign in</v-btn>
        </div>
      </template>

      <!-- Email confirmation flow -->
      <template v-else>
        <h2 class="callback-title">EMAIL CONFIRMED</h2>
        <p class="callback-subtitle" v-if="state === 'loading'">
          Securing your Opusio session and preparing your account.
        </p>
        <p class="callback-subtitle" v-else-if="state === 'success'">
          Your email is confirmed and your account is now active. You can return to your original
          Opusio window.
        </p>
        <p class="callback-subtitle" v-else>
          We could not complete sign in from this link. Please return to the app and sign in.
        </p>

        <div class="spinner-wrap" v-if="state === 'loading'">
          <v-progress-circular indeterminate :size="22" :width="2" color="black" />
        </div>

        <div v-if="state === 'success'" class="action-row">
          <v-btn class="callback-btn" @click="goToProfile">Open my account</v-btn>
          <button type="button" class="text-link-btn" @click="closeThisTab">Close this tab</button>
        </div>

        <v-btn v-if="state === 'error'" class="callback-btn" @click="goToSignIn"
          >Go to sign in</v-btn
        >
      </template>
    </div>
  </v-container>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const state = ref('loading')

const mode = ref('confirm') // 'confirm' | 'recovery'

// Recovery state
const recoveryState = ref('idle') // 'idle' | 'success' | 'error'
const newPassword = ref('')
const confirmPassword = ref('')
const recoveryError = ref('')
const recoverySaving = ref(false)

function goToSignIn() {
  router.replace({ name: 'auth' })
}

function goToProfile() {
  router.replace({ name: 'profile' })
}

function closeThisTab() {
  window.close()
}

async function submitNewPassword() {
  recoveryError.value = ''
  if (newPassword.value !== confirmPassword.value) {
    recoveryError.value = 'Passwords do not match.'
    return
  }
  if (newPassword.value.length < 8) {
    recoveryError.value = 'Password must be at least 8 characters.'
    return
  }
  recoverySaving.value = true
  try {
    const { error } = await supabase.auth.updateUser({ password: newPassword.value })
    if (error) throw error
    recoveryState.value = 'success'
  } catch (e) {
    recoveryError.value = e?.message || 'Could not update password. Please try again.'
    recoverySaving.value = false
  }
}

onMounted(async () => {
  // Supabase appends the session tokens as URL hash fragments on redirect.
  // Calling init()/refreshSession() causes the Supabase client to exchange them.
  try {
    await auth.init()
    await auth.refreshSession()

    if (route.query.type === 'recovery') {
      mode.value = 'recovery'
      return
    }

    if (auth.isAuthenticated) {
      state.value = 'success'
      return
    }

    state.value = 'error'
  } catch {
    state.value = 'error'
  }
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.callback {
  min-height: 64vh;
  display: grid;
  place-items: center;
  padding: 28px 16px;
}

.callback-card {
  width: 100%;
  max-width: 540px;
  text-align: center;
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: linear-gradient(180deg, #fff 0%, #fbfaf8 100%);
  padding: 48px 40px;
}

.callback-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 14px 0;
}

.callback-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  line-height: 1.7;
  color: #4b4035;
  margin: 0;
}

.spinner-wrap {
  margin-top: 24px;
  display: flex;
  justify-content: center;
}

.callback-btn {
  margin-top: 24px;
  background: #000 !important;
  color: #fff !important;
  font-family: 'Lora', 'Georgia', serif;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  border-radius: 1px;
  box-shadow: none;
}

.action-row {
  margin-top: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
}

.action-row .callback-btn {
  margin-top: 0;
}

.text-link-btn {
  border: none;
  background: transparent;
  color: #1a1a1a;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  text-decoration: underline;
  text-underline-offset: 3px;
  opacity: 0.7;
  cursor: pointer;
  padding: 0;
}

@media (max-width: 600px) {
  .callback-card {
    padding: 36px 24px;
  }
}

/* Recovery form */
.recovery-form {
  width: 100%;
  margin-top: 24px;
}

.recovery-group {
  margin-bottom: 20px;
}

.recovery-label {
  display: block;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin-bottom: 8px;
}

.recovery-input {
  width: 100%;
  border: none;
  border-bottom: 1px solid #1a1a1a;
  padding: 10px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  background: transparent;
  outline: none;
  box-sizing: border-box;
}

.recovery-input:focus {
  border-bottom-color: #b8996a;
}

.recovery-error {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #c0392b;
  margin-bottom: 16px;
}

.callback-btn-plain {
  background: #000;
  color: #fff;
  border: none;
  padding: 13px 28px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.11em;
  text-transform: uppercase;
  cursor: pointer;
  width: 100%;
  margin-top: 8px;
  transition: background 0.2s ease;
}

.callback-btn-plain:hover {
  background: #222;
}

.callback-btn-plain:disabled {
  background: #999;
  cursor: not-allowed;
}

.callback-success {
  margin-top: 16px;
}
</style>
