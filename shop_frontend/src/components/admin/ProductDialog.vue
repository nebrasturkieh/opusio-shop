<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="560"
    :persistent="false"
  >
    <div class="dialog-card">
      <h2 class="dialog-title">{{ isEdit ? 'Edit Product' : 'New Product' }}</h2>

      <div class="form-grid">
        <label class="field-label">
          Name *
          <input v-model="form.name" class="field-input" placeholder="e.g. Riviera Ring" />
        </label>

        <label class="field-label">
          Slug *
          <input v-model="form.slug" class="field-input" placeholder="e.g. riviera-ring" />
        </label>

        <label class="field-label" style="grid-column: 1 / -1">
          Description
          <textarea
            v-model="form.description"
            class="field-input field-textarea"
            rows="3"
            placeholder="Short description…"
          />
        </label>

        <label class="field-label">
          Collection
          <input v-model="form.collection" class="field-input" placeholder="e.g. Riviera" />
        </label>

        <label class="field-label">
          Category
          <input v-model="form.category" class="field-input" placeholder="e.g. Rings" />
        </label>

        <div class="field-label" style="grid-column: 1 / -1">
          Cover Image
          <ImageUploader v-model="form.image_url" :path-prefix="uploadPathPrefix" />
        </div>

        <label class="field-label field-check">
          <input type="checkbox" v-model="form.is_active" />
          Active (visible in shop)
        </label>
      </div>

      <div v-if="error" class="dialog-error">{{ error }}</div>

      <div class="dialog-actions">
        <button class="btn-ghost" @click="close">Cancel</button>
        <button class="btn-primary" :disabled="saving || !form.name || !form.slug" @click="save">
          {{ saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Create Product' }}
        </button>
      </div>
    </div>
  </v-dialog>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { useAdminStore } from '@/stores/admin'
import ImageUploader from '@/components/admin/ImageUploader.vue'

const props = defineProps({
  modelValue: Boolean,
  product: { type: Object, default: null },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const admin = useAdminStore()
const saving = ref(false)
const error = ref(null)

const isEdit = computed(() => !!props.product?.id)
const uploadPathPrefix = computed(() =>
  props.product?.id ? `products/${props.product.id}` : 'products/new',
)

const defaultForm = () => ({
  name: '',
  slug: '',
  description: '',
  collection: '',
  category: '',
  image_url: '',
  is_active: true,
})

const form = ref(defaultForm())

watch(
  () => form.value.name,
  (name) => {
    if (!isEdit.value) {
      form.value.slug = name
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '')
        .replace(/[\s_]+/g, '-')
        .replace(/^-+|-+$/g, '')
    }
  },
)

watch(
  () => props.product,
  (p) => {
    if (p) {
      form.value = {
        name: p.name ?? '',
        slug: p.slug ?? '',
        description: p.description ?? '',
        collection: p.collection ?? '',
        category: p.category ?? '',
        image_url: p.image_url ?? '',
        is_active: p.is_active ?? true,
      }
    } else {
      form.value = defaultForm()
    }
  },
  { immediate: true },
)

function close() {
  error.value = null
  emit('update:modelValue', false)
}

async function save() {
  saving.value = true
  error.value = null
  try {
    if (isEdit.value) {
      await admin.updateProduct(props.product.id, form.value)
    } else {
      await admin.createProduct(form.value)
    }
    emit('saved')
    close()
  } catch (e) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.dialog-card {
  background: #fff;
  padding: 36px;
  font-family: 'Lora', 'Georgia', serif;
}

.dialog-title {
  font-size: 20px;
  font-weight: 500;
  color: #1a1a1a;
  margin: 0 0 28px;
  letter-spacing: 0.04em;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 20px;
}

.field-label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 11px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #6b5b4a;
}

.field-input {
  border: 1px solid #e8e2d8;
  padding: 9px 12px;
  font-size: 13px;
  font-family: inherit;
  color: #1a1a1a;
  background: #faf9f7;
  outline: none;
}

.field-input:focus {
  border-color: #b8996a;
}

.field-textarea {
  resize: vertical;
}

.field-check {
  flex-direction: row;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  text-transform: none;
  letter-spacing: 0;
  color: #1a1a1a;
}

.dialog-error {
  font-size: 12px;
  color: #c0392b;
  margin-bottom: 16px;
}

.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-primary {
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 10px 28px;
  font-size: 12px;
  letter-spacing: 0.1em;
  font-family: inherit;
  cursor: pointer;
}

.btn-primary:hover:not(:disabled) {
  background: #b8996a;
}
.btn-primary:disabled {
  opacity: 0.5;
  cursor: default;
}

.btn-ghost {
  background: none;
  border: 1px solid #e8e2d8;
  color: #1a1a1a;
  padding: 10px 24px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
}

.btn-ghost:hover {
  border-color: #1a1a1a;
}
</style>
