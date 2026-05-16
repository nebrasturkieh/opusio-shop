<template>
  <section class="profile-setup">
    <h3 class="setup-title">PROFILE DETAILS</h3>
    <p class="setup-subtitle">Refine your information for a more personal Opusio experience.</p>

    <form class="setup-form" @submit.prevent="save">
      <p v-if="errorMessage" class="inline-feedback inline-feedback-error">{{ errorMessage }}</p>

      <!-- Name -->
      <div class="form-group">
        <label class="form-label">Full name</label>
        <input
          v-model="fields.full_name"
          class="form-input"
          type="text"
          autocomplete="name"
          required
        />
      </div>

      <!-- Phone -->
      <div class="form-group">
        <label class="form-label">Phone number</label>
        <input v-model="fields.phone" class="form-input" type="tel" autocomplete="tel" />
      </div>

      <div class="form-divider"><span class="form-divider-label">DELIVERY ADDRESS</span></div>

      <!-- Address -->
      <div class="form-group">
        <label class="form-label">Street address</label>
        <input
          v-model="fields.address"
          class="form-input"
          type="text"
          autocomplete="street-address"
        />
      </div>

      <!-- City + Country side by side -->
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">City</label>
          <input
            v-model="fields.city"
            class="form-input"
            type="text"
            autocomplete="address-level2"
          />
        </div>
        <div class="form-group">
          <label class="form-label">Country</label>
          <input
            v-model="fields.country"
            class="form-input"
            type="text"
            autocomplete="country-name"
          />
        </div>
      </div>

      <div class="actions">
        <button class="primary-btn" type="submit" :disabled="loading">
          {{ loading ? 'SAVING...' : 'SAVE PROFILE' }}
        </button>

        <button
          v-if="canCancel"
          class="secondary-link"
          type="button"
          :disabled="loading"
          @click="emit('cancel')"
        >
          Cancel
        </button>
      </div>
    </form>
  </section>
</template>

<script setup>
import { reactive, watch } from 'vue'
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({
  initialFullName: { type: String, default: '' },
  canCancel: { type: Boolean, default: true },
})

const emit = defineEmits(['saved', 'cancel'])

const auth = useAuthStore()

const fields = reactive({
  full_name: props.initialFullName,
  phone: auth.profile?.phone || '',
  address: auth.profile?.address || '',
  city: auth.profile?.city || '',
  country: auth.profile?.country || '',
})

const loading = ref(false)
const errorMessage = ref('')

watch(
  () => auth.profile,
  (p) => {
    if (!p) return
    fields.full_name = p.full_name || ''
    fields.phone = p.phone || ''
    fields.address = p.address || ''
    fields.city = p.city || ''
    fields.country = p.country || ''
  },
)

watch(
  () => props.initialFullName,
  (value) => {
    fields.full_name = value || ''
  },
)

async function save() {
  if (!fields.full_name.trim()) {
    errorMessage.value = 'Please enter your full name.'
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    const savedProfile = await auth.upsertProfile({ ...fields })
    emit('saved', savedProfile)
  } catch (e) {
    errorMessage.value = e?.message || 'Unable to save profile at the moment. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.profile-setup {
  border: 1px solid rgba(0, 0, 0, 0.08);
  background: linear-gradient(180deg, #fff 0%, #fbfaf8 100%);
  padding: 38px 34px;
}

.setup-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 10px 0;
}

.setup-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
  line-height: 1.7;
  margin: 0 0 28px 0;
}

.setup-form {
  display: flex;
  flex-direction: column;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0 28px;
}

.form-divider {
  display: flex;
  align-items: center;
  gap: 16px;
  margin: 8px 0 24px;
}

.form-divider::before,
.form-divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: rgba(0, 0, 0, 0.08);
}

.form-divider-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.14em;
  color: #7a6a59;
  white-space: nowrap;
}

.form-group {
  margin-bottom: 22px;
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
  padding: 11px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  background: transparent;
  outline: none;
  transition: border-color 0.2s ease;
}

.form-input:focus {
  border-bottom-color: #000;
}

.actions {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 14px;
  margin-top: 8px;
}

.primary-btn {
  background: #000;
  color: #fff;
  border: none;
  padding: 13px 28px;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  cursor: pointer;
  transition: all 0.2s ease;
  border-radius: 0;
  min-width: 220px;
}

.primary-btn:hover {
  background: #1f1f1f;
}

.primary-btn:disabled {
  background: #b8b2ab;
  color: #f5f2ee;
  cursor: not-allowed;
}

.secondary-link {
  border: none;
  background: transparent;
  color: #1a1a1a;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  text-decoration: underline;
  opacity: 0.65;
  cursor: pointer;
  padding: 0;
}

.secondary-link:hover {
  opacity: 0.95;
}

.secondary-link:disabled {
  cursor: not-allowed;
}

.inline-feedback {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  line-height: 1.6;
  margin: 0 0 18px 0;
  padding: 12px 14px;
  border-radius: 0;
}

.inline-feedback-error {
  color: #8e2134;
  border: 1px solid rgba(196, 30, 58, 0.25);
  background: rgba(196, 30, 58, 0.06);
}

@media (max-width: 640px) {
  .profile-setup {
    padding: 28px 22px;
  }

  .form-row {
    grid-template-columns: 1fr;
    gap: 0;
  }

  .primary-btn {
    min-width: 0;
    width: 100%;
  }
}
</style>
