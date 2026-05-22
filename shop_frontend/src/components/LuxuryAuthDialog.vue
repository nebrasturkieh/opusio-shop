<template>
  <v-dialog v-model="internalModel" width="1000" :persistent="false">
    <v-card class="auth-card">
      <div class="auth-container">
        <!-- Sign In Column -->
        <div class="auth-column signin-column">
          <div class="column-content">
            <!-- Reset Password Mode -->
            <template v-if="resetMode">
              <h2 class="auth-title">RESET YOUR PASSWORD</h2>
              <p class="auth-subtitle">
                Enter your email address and we will send you a link to reset your password.
              </p>

              <form @submit.prevent="sendReset" class="auth-form">
                <p v-if="authMessage" class="inline-feedback" :class="authMessageTypeClass">
                  {{ authMessage }}
                </p>

                <div class="form-group">
                  <label class="form-label">Email Address</label>
                  <input
                    v-model="resetEmail"
                    type="email"
                    class="form-input"
                    autocomplete="email"
                    required
                  />
                </div>

                <button type="submit" class="submit-btn" :disabled="resetSending">
                  {{ resetSending ? 'SENDING...' : 'SEND RESET LINK' }}
                </button>

                <div class="form-links reset-back">
                  <a href="#" @click.prevent="cancelReset" class="link">Back to sign in</a>
                </div>
              </form>
            </template>

            <!-- Sign In Mode -->
            <template v-else>
              <h2 class="auth-title">ALREADY REGISTERED?</h2>
              <p class="auth-subtitle">If you are already registered, sign in below.</p>

              <form @submit.prevent="handleSignIn" class="auth-form">
                <p v-if="authMessage" class="inline-feedback" :class="authMessageTypeClass">
                  {{ authMessage }}
                </p>

                <div class="form-group">
                  <label class="form-label">Email Address</label>
                  <input
                    v-model="email"
                    type="email"
                    class="form-input"
                    autocomplete="email"
                    required
                  />
                </div>

                <div class="form-group">
                  <label class="form-label">Password</label>
                  <div class="password-wrapper">
                    <input
                      v-model="password"
                      :type="showPassword ? 'text' : 'password'"
                      class="form-input password-input"
                      autocomplete="current-password"
                      required
                    />
                    <button type="button" class="show-hide-btn" @click="togglePassword">
                      {{ showPassword ? 'Hide' : 'Show' }}
                    </button>
                  </div>
                </div>

                <div class="form-links">
                  <a href="#" @click.prevent="forgotPassword" class="link">Forgot your password?</a>
                </div>

                <p class="form-privacy">
                  For further information about how we use your personal information, please see our
                  <a href="#" class="link">Privacy Policy</a>.
                </p>

                <button type="submit" class="submit-btn">LOG IN</button>
              </form>
            </template>
          </div>
        </div>

        <!-- Vertical Divider -->
        <div class="divider"></div>

        <!-- Register Column -->
        <div class="auth-column register-column">
          <div class="column-content">
            <h2 class="auth-title">CREATE YOUR ACCOUNT</h2>
            <p class="auth-subtitle">
              Register now and make the most of Opusio. You will be able to:
            </p>

            <ul class="benefits-list">
              <li>Manage your profile information</li>
              <li>Save your shipping addresses</li>
              <li>Check your orders</li>
              <li>Manage your Collection and service orders</li>
            </ul>

            <button type="button" class="submit-btn create-btn" @click="createAccount">
              CREATE MY ACCOUNT
            </button>
          </div>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'register'])

const internalModel = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const auth = useAuthStore()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const authMessage = ref('')
const authMessageType = ref('error')
const resetMode = ref(false)
const resetEmail = ref('')
const resetSending = ref(false)

const authMessageTypeClass = computed(() => {
  return authMessageType.value === 'success' ? 'inline-feedback-success' : 'inline-feedback-error'
})

function togglePassword() {
  showPassword.value = !showPassword.value
}

function forgotPassword() {
  resetEmail.value = email.value // pre-fill if already typed
  resetMode.value = true
  authMessage.value = ''
}

function cancelReset() {
  resetMode.value = false
  authMessage.value = ''
}

async function handleSignIn() {
  authMessage.value = ''
  try {
    await auth.signInWithPassword(email.value.trim(), password.value)
    internalModel.value = false
    email.value = ''
    password.value = ''
  } catch (e) {
    authMessageType.value = 'error'
    authMessage.value = e?.message || 'Invalid email or password. Please try again.'
  }
}

function createAccount() {
  internalModel.value = false
  emit('register')
}

async function sendReset() {
  authMessage.value = ''
  if (!resetEmail.value.trim()) {
    authMessageType.value = 'error'
    authMessage.value = 'Please enter your email address.'
    return
  }
  resetSending.value = true
  try {
    await auth.resetPassword(resetEmail.value.trim())
    authMessageType.value = 'success'
    authMessage.value =
      'A password reset link has been sent to your inbox. Please check your email.'
    resetMode.value = false
  } catch (e) {
    authMessageType.value = 'error'
    authMessage.value = e?.message || 'Could not send reset email. Please try again.'
  } finally {
    resetSending.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

/* ==========================================
   CARD & CONTAINER
============================================= */
.auth-card {
  background: #fff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: none !important;
  border-radius: 0;
}

.auth-container {
  display: flex;
  align-items: stretch;
  min-height: 520px;
  position: relative;
}

/* ==========================================
   COLUMNS
============================================= */
.auth-column {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px 48px;
}

.signin-column {
  padding-right: 54px;
}

.register-column {
  padding-left: 54px;
}

.column-content {
  width: 100%;
  max-width: 360px;
}

/* ==========================================
   DIVIDER
============================================= */
.divider {
  width: 1px;
  background: rgba(0, 0, 0, 0.08);
  margin: 0;
}

/* ==========================================
   TYPOGRAPHY
============================================= */
.auth-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 14px 0;
  line-height: 1.3;
}

.auth-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  font-weight: 400;
  color: #6b5b4a;
  margin: 0 0 28px 0;
  line-height: 1.6;
  letter-spacing: 0.01em;
}

/* ==========================================
   FORM STRUCTURE
============================================= */
.auth-form {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.form-group {
  margin-bottom: 24px;
}

.form-label {
  display: block;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #888;
  margin-bottom: 10px;
}

.form-input {
  width: 100%;
  border: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  padding: 12px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  background: transparent;
  outline: none;
  transition: border-color 0.3s ease;
}

.form-input:focus {
  border-bottom-color: #000;
}

.form-input::placeholder {
  color: #d0d0d0;
}

/* ==========================================
   PASSWORD FIELD
============================================= */
.password-wrapper {
  display: flex;
  align-items: center;
  gap: 12px;
}

.password-input {
  flex: 1;
}

.show-hide-btn {
  background: transparent;
  border: none;
  padding: 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 500;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: #333;
  cursor: pointer;
  transition: color 0.2s ease;
  flex-shrink: 0;
}

.show-hide-btn:hover {
  color: #000;
}

/* ==========================================
   LINKS & PRIVACY
============================================= */
.form-links {
  margin: 12px 0 28px 0;
}

.link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #1a1a1a;
  text-decoration: underline;
  transition: color 0.2s ease;
}

.link:hover {
  color: #666;
}

.form-privacy {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #888;
  line-height: 1.6;
  margin: 0 0 28px 0;
}

.form-privacy .link {
  font-size: 12px;
  color: #1a1a1a;
}

.inline-feedback {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  line-height: 1.6;
  margin: 0 0 20px 0;
  padding: 12px 14px;
  border-radius: 0;
}

.inline-feedback-error {
  color: #8e2134;
  border: 1px solid rgba(196, 30, 58, 0.25);
  background: rgba(196, 30, 58, 0.06);
}

.inline-feedback-success {
  color: #295842;
  border: 1px solid rgba(41, 88, 66, 0.25);
  background: rgba(41, 88, 66, 0.08);
}

/* ==========================================
   BUTTONS
============================================= */
.submit-btn {
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
  transition: background 0.2s ease;
  border-radius: 0;
  width: 240px;
  margin: 0 auto;
  display: block;
}

.submit-btn:hover {
  background: #222;
}

.submit-btn:active {
  background: #000;
}

.submit-btn:disabled {
  background: #999;
  cursor: not-allowed;
}

.reset-back {
  margin-top: 20px;
  text-align: center;
}

/* ==========================================
   REGISTER COLUMN
============================================= */
.benefits-list {
  list-style: none;
  padding-left: 0;
  margin: 24px 0 32px 0;
  font-family: 'Lora', 'Georgia', serif;
}

.benefits-list li {
  font-size: 14px;
  color: #333;
  line-height: 1.8;
  margin-bottom: 12px;
  position: relative;
  padding-left: 18px;
}

.benefits-list li:before {
  content: '•';
  position: absolute;
  left: 0;
  color: #1a1a1a;
}

/* ==========================================
   RESPONSIVE
============================================= */
@media (max-width: 768px) {
  .auth-container {
    flex-direction: column;
    min-height: auto;
  }

  .divider {
    width: 100%;
    height: 1px;
    margin: 0;
  }

  .auth-column {
    padding: 40px 32px;
  }

  .signin-column {
    padding-right: 32px;
  }

  .register-column {
    padding-left: 32px;
  }

  .column-content {
    max-width: 100%;
  }

  .auth-title {
    font-size: 13px;
  }

  .auth-subtitle {
    font-size: 13px;
    margin-bottom: 20px;
  }

  .form-group {
    margin-bottom: 20px;
  }

  .submit-btn {
    padding: 12px 24px;
    font-size: 11px;
  }
}

@media (max-width: 480px) {
  .auth-column {
    padding: 30px 20px;
  }

  .auth-title {
    font-size: 12px;
    margin-bottom: 10px;
  }

  .auth-subtitle {
    font-size: 12px;
    margin-bottom: 16px;
  }

  .form-label {
    font-size: 10px;
    margin-bottom: 8px;
  }

  .form-input {
    padding: 10px 0;
    font-size: 13px;
  }

  .password-wrapper {
    gap: 8px;
  }

  .show-hide-btn {
    padding: 6px 8px;
    font-size: 9px;
  }

  .form-privacy {
    font-size: 11px;
  }

  .benefits-list li {
    font-size: 13px;
    margin-bottom: 10px;
  }
}

/* Dialog container & overlay */
:deep(.v-overlay__content) {
  border-radius: 0 !important;
}

:deep(.v-overlay__scrim) {
  opacity: 0.28;
}
</style>
