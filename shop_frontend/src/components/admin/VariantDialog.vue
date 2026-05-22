<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="600"
    :persistent="false"
  >
    <div class="dialog-card">
      <h2 class="dialog-title">{{ isEdit ? 'Edit Variant' : 'New Variant' }}</h2>

      <div class="form-grid">
        <label class="field-label">
          SKU *
          <input v-model="form.sku" class="field-input" placeholder="e.g. RIV-RING-YG-52" />
        </label>

        <label class="field-label">
          Material Type
          <input
            v-model="form.material_type"
            class="field-input"
            placeholder="e.g. 18k Yellow Gold"
          />
        </label>

        <label class="field-label">
          Material / Color
          <input v-model="form.material_color" class="field-input" placeholder="e.g. Yellow Gold" />
        </label>

        <label class="field-label">
          Size
          <input v-model="form.size" class="field-input" placeholder="e.g. 52" />
        </label>

        <label class="field-label">
          Finish
          <input v-model="form.finish" class="field-input" placeholder="e.g. Polished" />
        </label>

        <label class="field-label">
          Stone
          <input v-model="form.stone" class="field-input" placeholder="e.g. Diamond" />
        </label>

        <label class="field-label">
          Price (cents) *
          <input
            v-model.number="form.price_cents"
            type="number"
            min="0"
            class="field-input"
            placeholder="e.g. 129900"
          />
          <span v-if="form.price_cents" class="field-hint"
            >= {{ formatPrice(form.price_cents) }}</span
          >
        </label>

        <label class="field-label">
          Stock Quantity
          <input
            v-model.number="form.stock_quantity"
            type="number"
            min="0"
            class="field-input"
            placeholder="e.g. 10"
          />
        </label>

        <div class="field-label">
          Cover Image
          <ImageUploader v-model="form.image_url" :path-prefix="uploadPathPrefix" />
        </div>

        <label class="field-label">
          Weight (grams)
          <input
            v-model.number="form.weight_grams"
            type="number"
            min="0"
            step="0.01"
            class="field-input"
          />
        </label>

        <label class="field-label">
          Width (mm)
          <input
            v-model.number="form.width_mm"
            type="number"
            min="0"
            step="0.01"
            class="field-input"
          />
        </label>

        <label class="field-label">
          Length (mm)
          <input
            v-model.number="form.length_mm"
            type="number"
            min="0"
            step="0.01"
            class="field-input"
          />
        </label>

        <label class="field-label field-check">
          <input type="checkbox" v-model="form.is_active" />
          Active
        </label>
      </div>

      <div v-if="error" class="dialog-error">{{ error }}</div>

      <div class="dialog-actions">
        <button class="btn-ghost" @click="close">Cancel</button>
        <button
          class="btn-primary"
          :disabled="saving || !form.sku || !form.price_cents"
          @click="save"
        >
          {{ saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Add Variant' }}
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
  variant: { type: Object, default: null },
  productId: { type: [Number, String], default: null },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const admin = useAdminStore()
const saving = ref(false)
const error = ref(null)

const isEdit = computed(() => !!props.variant?.id)
const uploadPathPrefix = computed(() =>
  props.variant?.id ? `variants/${props.variant.id}` : 'variants/new',
)

const defaultForm = () => ({
  sku: '',
  material_type: '',
  material_color: '',
  size: '',
  finish: '',
  stone: '',
  price_cents: null,
  stock_quantity: 0,
  image_url: '',
  weight_grams: null,
  width_mm: null,
  length_mm: null,
  is_active: true,
})

const form = ref(defaultForm())

watch(
  () => props.variant,
  (v) => {
    if (v) {
      form.value = {
        sku: v.sku ?? '',
        material_type: v.material_type ?? '',
        material_color: v.material_color ?? '',
        size: v.size ?? '',
        finish: v.finish ?? '',
        stone: v.stone ?? '',
        price_cents: v.price_cents ?? null,
        stock_quantity: v.stock_quantity ?? 0,
        image_url: v.image_url ?? '',
        weight_grams: v.weight_grams ?? null,
        width_mm: v.width_mm ?? null,
        length_mm: v.length_mm ?? null,
        is_active: v.is_active ?? true,
      }
    } else {
      form.value = defaultForm()
    }
  },
  { immediate: true },
)

const formatPrice = (cents) =>
  new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)

function close() {
  error.value = null
  emit('update:modelValue', false)
}

async function save() {
  saving.value = true
  error.value = null
  try {
    if (isEdit.value) {
      await admin.updateVariant(props.variant.id, form.value)
    } else {
      await admin.createVariant({ ...form.value, product_id: props.productId })
    }
    emit('saved')
    close()
  } catch (e) {
    // Surface SKU uniqueness violation clearly
    if (e.message?.includes('unique') || e.message?.includes('duplicate')) {
      error.value = 'That SKU is already in use. Please choose a unique SKU.'
    } else {
      error.value = e.message
    }
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
  max-height: 90vh;
  overflow-y: auto;
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

.field-hint {
  font-size: 11px;
  color: #9a9087;
  text-transform: none;
  letter-spacing: 0;
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
