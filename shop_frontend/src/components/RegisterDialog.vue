<template>
  <v-dialog v-model="internalModel" width="780" :persistent="false" scrollable>
    <v-card class="register-card">
      <div class="register-container">
        <div class="register-content">
          <template v-if="!showEmailConfirmationState">
            <h2 class="register-title">CREATE YOUR ACCOUNT</h2>
            <p class="register-subtitle">
              Create your Opusio account to view your orders, save your favourites, and enjoy a more
              personal experience.
            </p>

            <form @submit.prevent="handleRegister" class="register-form">
              <p v-if="submitError" class="inline-feedback inline-feedback-error">
                {{ submitError }}
              </p>

              <!-- First Name -->
              <div class="form-group">
                <label class="form-label">First name</label>
                <input
                  v-model="formData.firstName"
                  type="text"
                  class="form-input"
                  autocomplete="given-name"
                  required
                />
                <span v-if="errors.firstName" class="error-text">{{ errors.firstName }}</span>
              </div>

              <!-- Last Name -->
              <div class="form-group">
                <label class="form-label">Last name</label>
                <input
                  v-model="formData.lastName"
                  type="text"
                  class="form-input"
                  autocomplete="family-name"
                  required
                />
                <span v-if="errors.lastName" class="error-text">{{ errors.lastName }}</span>
              </div>

              <!-- Email -->
              <div class="form-group">
                <label class="form-label">Email address</label>
                <input
                  v-model="formData.email"
                  type="email"
                  class="form-input"
                  autocomplete="email"
                  required
                />
                <span v-if="errors.email" class="error-text">{{ errors.email }}</span>
              </div>

              <!-- Confirm Email -->
              <div class="form-group">
                <label class="form-label">Confirm email address</label>
                <input
                  v-model="formData.emailConfirm"
                  type="email"
                  class="form-input"
                  autocomplete="email"
                  required
                />
                <span v-if="errors.emailConfirm" class="error-text">{{ errors.emailConfirm }}</span>
              </div>

              <!-- Password -->
              <div class="form-group">
                <label class="form-label">Password</label>
                <div class="password-wrapper">
                  <input
                    v-model="formData.password"
                    :type="showPassword ? 'text' : 'password'"
                    class="form-input password-input"
                    autocomplete="new-password"
                    required
                  />
                  <button type="button" class="show-hide-btn" @click="showPassword = !showPassword">
                    {{ showPassword ? 'Hide' : 'Show' }}
                  </button>
                </div>
                <span v-if="errors.password" class="error-text">{{ errors.password }}</span>
              </div>

              <!-- Confirm Password -->
              <div class="form-group">
                <label class="form-label">Confirm password</label>
                <div class="password-wrapper">
                  <input
                    v-model="formData.passwordConfirm"
                    :type="showPasswordConfirm ? 'text' : 'password'"
                    class="form-input password-input"
                    autocomplete="new-password"
                    required
                  />
                  <button
                    type="button"
                    class="show-hide-btn"
                    @click="showPasswordConfirm = !showPasswordConfirm"
                  >
                    {{ showPasswordConfirm ? 'Hide' : 'Show' }}
                  </button>
                </div>
                <span v-if="errors.passwordConfirm" class="error-text">{{
                  errors.passwordConfirm
                }}</span>
              </div>

              <!-- Password Rules -->
              <div class="password-rules">
                <p class="rules-title">Your password must include a minimum of 10 characters.</p>
                <ul class="rules-list">
                  <li>Contain at least a number</li>
                  <li>Contain at least one lower case and an upper case letter</li>
                  <li>Not contain spaces</li>
                  <li>Cannot contain the same character more than two times in a row</li>
                  <li>Is restricted to the following symbols: !*$():-_/[];,.</li>
                </ul>
              </div>

              <!-- Privacy Text -->
              <p class="privacy-text">
                For further information about how we use your personal information, please see our
                <a href="#" class="link">Privacy Policy</a>.
              </p>

              <!-- Submit Button -->
              <button type="submit" class="submit-btn" :disabled="isSubmitting">
                {{ isSubmitting ? 'CREATING ACCOUNT...' : 'CREATE MY ACCOUNT' }}
              </button>

              <!-- Back Link -->
              <div class="back-link">
                <a href="#" @click.prevent="goBack" class="link">Back to sign in</a>
              </div>
            </form>
          </template>

          <div v-else class="email-confirmation-state">
            <h2 class="register-title">CHECK YOUR EMAIL</h2>
            <p class="register-subtitle confirmation-subtitle">
              We have sent a confirmation link to
              <strong class="confirmation-email">{{ confirmationEmail }}</strong
              >.
            </p>

            <p class="confirmation-body">
              Please open your inbox and confirm your email address before signing in. Once your
              email is verified, return here and log in with your credentials.
            </p>

            <p v-if="resendFeedback" class="inline-feedback inline-feedback-success">
              {{ resendFeedback }}
            </p>

            <p v-if="submitError" class="inline-feedback inline-feedback-error">
              {{ submitError }}
            </p>

            <div class="confirmation-actions">
              <button
                type="button"
                class="submit-btn confirm-primary-btn"
                :disabled="isSubmitting || isResending"
                @click="handleResendConfirmation"
              >
                {{ isResending ? 'SENDING...' : 'RESEND CONFIRMATION EMAIL' }}
              </button>

              <button
                type="button"
                class="text-action-btn"
                :disabled="isSubmitting"
                @click="goBack"
              >
                BACK TO SIGN IN
              </button>
            </div>
          </div>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref, computed, watch, onBeforeUnmount } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'back'])

const internalModel = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const auth = useAuthStore()

const formData = ref({
  firstName: '',
  lastName: '',
  email: '',
  emailConfirm: '',
  password: '',
  passwordConfirm: '',
})

const errors = ref({})
const showPassword = ref(false)
const showPasswordConfirm = ref(false)
const submitError = ref('')
const resendFeedback = ref('')
const confirmationEmail = ref('')
const showEmailConfirmationState = ref(false)
const isSubmitting = ref(false)
const isResending = ref(false)
let confirmationPollingInterval = null

function resetForm() {
  Object.assign(formData.value, {
    firstName: '',
    lastName: '',
    email: '',
    emailConfirm: '',
    password: '',
    passwordConfirm: '',
  })
  errors.value = {}
  showPassword.value = false
  showPasswordConfirm.value = false
}

function openEmailConfirmationState(email) {
  confirmationEmail.value = email
  showEmailConfirmationState.value = true
  resendFeedback.value = ''
  submitError.value = ''
  // Keep only the email context for resend and UI messaging.
  formData.value.password = ''
  formData.value.passwordConfirm = ''
}

function clearConfirmationPolling() {
  if (confirmationPollingInterval) {
    clearInterval(confirmationPollingInterval)
    confirmationPollingInterval = null
  }
}

function closeConfirmationStateAfterAuth() {
  showEmailConfirmationState.value = false
  submitError.value = ''
  resendFeedback.value = ''
  confirmationEmail.value = ''
  resetForm()
  internalModel.value = false
}

async function syncConfirmationStateWithSession() {
  if (!internalModel.value || !showEmailConfirmationState.value) return
  try {
    await auth.refreshSession()
    if (auth.isAuthenticated) {
      closeConfirmationStateAfterAuth()
    }
  } catch {
    // ignore transient session refresh errors while polling
  }
}

function toReadableAuthError(error) {
  const message = error?.message || 'Registration failed. Please try again.'
  const normalized = message.toLowerCase()

  if (normalized.includes('already registered') || normalized.includes('user already exists')) {
    return 'This email is already registered. Please sign in or use a different email address.'
  }

  if (normalized.includes('invalid login credentials')) {
    return 'Your account exists, but the credentials are invalid. Please check your details and try again.'
  }

  if (normalized.includes('email not confirmed')) {
    return 'Your account is almost ready. Please confirm your email before signing in.'
  }

  if (
    normalized.includes('email rate limit exceeded') ||
    normalized.includes('rate limit exceeded') ||
    normalized.includes('too many requests')
  ) {
    return 'Too many email requests. Please wait a few minutes before requesting another confirmation email.'
  }

  return message
}

function validatePassword(pwd) {
  if (!pwd) return 'Password is required'
  if (pwd.length < 10) return 'Password must be at least 10 characters'
  if (!/[a-z]/.test(pwd)) return 'Password must contain lowercase letters'
  if (!/[A-Z]/.test(pwd)) return 'Password must contain uppercase letters'
  if (!/\d/.test(pwd)) return 'Password must contain at least one number'
  if (/ /.test(pwd)) return 'Password cannot contain spaces'
  if (/(.)\1{2,}/.test(pwd))
    return 'Password cannot contain the same character more than twice in a row'
  return ''
}

function validate() {
  errors.value = {}

  if (!formData.value.firstName?.trim()) {
    errors.value.firstName = 'First name is required'
  }

  if (!formData.value.lastName?.trim()) {
    errors.value.lastName = 'Last name is required'
  }

  if (!formData.value.email?.trim()) {
    errors.value.email = 'Email is required'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.value.email)) {
    errors.value.email = 'Invalid email format'
  }

  if (formData.value.email !== formData.value.emailConfirm) {
    errors.value.emailConfirm = 'Email addresses do not match'
  }

  const pwdError = validatePassword(formData.value.password)
  if (pwdError) {
    errors.value.password = pwdError
  }

  if (formData.value.password !== formData.value.passwordConfirm) {
    errors.value.passwordConfirm = 'Passwords do not match'
  }

  return Object.keys(errors.value).length === 0
}

async function handleRegister() {
  if (!validate()) return

  try {
    submitError.value = ''
    resendFeedback.value = ''
    isSubmitting.value = true

    // 1. Sign up user with email and password
    const redirectTo =
      typeof window !== 'undefined' ? `${window.location.origin}/auth/callback` : undefined
    const { data: authData, error: signupError } = await supabase.auth.signUp({
      email: formData.value.email,
      password: formData.value.password,
      options: {
        data: {
          first_name: formData.value.firstName.trim(),
          last_name: formData.value.lastName.trim(),
          full_name: `${formData.value.firstName} ${formData.value.lastName}`.trim(),
        },
        emailRedirectTo: redirectTo,
      },
    })

    if (signupError) throw signupError
    if (!authData.user) throw new Error('Signup failed: no user data')

    // 2. In Supabase, session is null when email confirmation is required.
    if (!authData.session) {
      openEmailConfirmationState(formData.value.email)
      return
    }

    // 3. If no confirmation is required, ensure the app profile exists immediately.
    await auth.ensureProfile(authData.user)

    // 4. Close dialog and reset form
    internalModel.value = false
    resetForm()
  } catch (e) {
    console.error('Registration error:', e)
    submitError.value = toReadableAuthError(e)
    if ((e?.message || '').toLowerCase().includes('email not confirmed')) {
      openEmailConfirmationState(formData.value.email)
    }
  } finally {
    isSubmitting.value = false
  }
}

async function handleResendConfirmation() {
  if (!confirmationEmail.value) {
    submitError.value = 'Missing email address. Please return to sign in and try again.'
    return
  }

  try {
    submitError.value = ''
    resendFeedback.value = ''
    isResending.value = true

    const { error } = await supabase.auth.resend({
      type: 'signup',
      email: confirmationEmail.value,
      options: {
        emailRedirectTo:
          typeof window !== 'undefined' ? `${window.location.origin}/auth/callback` : undefined,
      },
    })

    if (error) throw error

    resendFeedback.value = 'A new confirmation email has been sent. Please check your inbox.'
  } catch (e) {
    submitError.value = toReadableAuthError(e)
  } finally {
    isResending.value = false
  }
}

function goBack() {
  clearConfirmationPolling()
  showEmailConfirmationState.value = false
  submitError.value = ''
  resendFeedback.value = ''
  confirmationEmail.value = ''
  resetForm()
  internalModel.value = false
  emit('back')
}

watch(
  () => auth.isAuthenticated,
  (isAuthenticated) => {
    if (isAuthenticated && internalModel.value && showEmailConfirmationState.value) {
      closeConfirmationStateAfterAuth()
    }
  },
)

watch(
  () => [internalModel.value, showEmailConfirmationState.value],
  ([dialogOpen, confirmationOpen]) => {
    if (dialogOpen && confirmationOpen) {
      syncConfirmationStateWithSession()
      clearConfirmationPolling()
      confirmationPollingInterval = setInterval(syncConfirmationStateWithSession, 5000)
      return
    }

    clearConfirmationPolling()
  },
)

onBeforeUnmount(() => {
  clearConfirmationPolling()
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.register-card {
  background: #fff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: none !important;
  border-radius: 0;
}

.register-card::-webkit-scrollbar {
  width: 6px;
}

.register-card::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 0;
}

.register-container {
  padding: 60px 48px;
}

.register-content {
  max-width: 580px;
  margin: 0 auto;
}

.register-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 14px 0;
  line-height: 1.3;
}

.register-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  font-weight: 400;
  color: #6b5b4a;
  margin: 0 0 32px 0;
  line-height: 1.6;
  letter-spacing: 0.01em;
}

.register-form {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.email-confirmation-state {
  max-width: 520px;
  margin: 0 auto;
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: linear-gradient(180deg, #fff 0%, #fbfaf8 100%);
  padding: 48px 40px;
  text-align: center;
}

.confirmation-body {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #4b4035;
  line-height: 1.7;
  margin: 0 0 22px 0;
}

.confirmation-actions {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  margin-top: 18px;
}

.confirmation-subtitle {
  margin: 0 0 18px 0;
}

.confirmation-email {
  font-weight: 600;
  letter-spacing: 0.015em;
}

.confirm-primary-btn {
  width: 252px;
  margin: 0;
  transition: all 0.2s ease;
}

.confirm-primary-btn:hover {
  background: #1f1f1f;
  transform: translateY(-1px);
}

.text-action-btn {
  border: none;
  background: transparent;
  color: #1a1a1a;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 400;
  letter-spacing: 0.02em;
  text-decoration: underline;
  text-underline-offset: 3px;
  opacity: 0.6;
  cursor: pointer;
  padding: 0;
  transition:
    color 0.2s ease,
    opacity 0.2s ease;
}

.text-action-btn:hover {
  color: #1a1a1a;
  opacity: 0.9;
}

.text-action-btn:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.form-group {
  margin-bottom: 28px;
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
  border-bottom: 1px solid rgba(0, 0, 0, 0.2);
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

/* Password Wrapper */
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

/* Password Rules */
.password-rules {
  background: rgba(0, 0, 0, 0.03);
  border: none;
  padding: 20px;
  margin: 28px 0;
  border-radius: 0;
}

.rules-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0 0 12px 0;
}

.rules-list {
  list-style: none;
  padding: 0;
  margin: 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #555;
  line-height: 1.8;
}

.rules-list li {
  margin-bottom: 6px;
}

/* Privacy Text */
.privacy-text {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #777;
  line-height: 1.6;
  margin: 24px 0;
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

/* Submit Button */
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
  transition: all 0.2s ease;
  border-radius: 0;
  width: 240px;
  margin: 32px auto 0;
  display: block;
}

.submit-btn:hover {
  background: #222;
}

.submit-btn:disabled {
  background: #b8b2ab;
  color: #f5f2ee;
  cursor: not-allowed;
}

.submit-btn:active {
  background: #000;
}

/* Back Link */
.back-link {
  text-align: center;
  margin-top: 20px;
}

.back-link .link {
  font-size: 12px;
  opacity: 0.7;
  text-decoration: underline;
}

/* Error Text */
.error-text {
  display: block;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #c41e3a;
  margin-top: 6px;
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

/* Responsive */
@media (max-width: 768px) {
  .register-container {
    padding: 40px 32px;
  }

  .register-title {
    font-size: 14px;
  }

  .register-subtitle {
    font-size: 13px;
    margin-bottom: 24px;
  }

  .form-group {
    margin-bottom: 24px;
  }

  .password-rules {
    padding: 16px;
    margin: 24px 0;
  }

  .email-confirmation-state {
    padding: 40px 30px;
  }

  .rules-title {
    font-size: 12px;
  }

  .rules-list {
    font-size: 12px;
  }

  .submit-btn {
    margin: 28px auto 0;
  }
}

@media (max-width: 480px) {
  .register-container {
    padding: 30px 20px;
  }

  .register-title {
    font-size: 13px;
  }

  .register-subtitle {
    font-size: 12px;
  }

  .submit-btn {
    width: 100%;
    padding: 12px 20px;
    font-size: 11px;
    margin: 24px auto 0;
  }

  .confirm-primary-btn {
    width: 240px;
  }

  .text-action-btn {
    margin: 0;
  }

  .back-link .link {
    font-size: 11px;
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
