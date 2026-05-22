<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    max-width="640"
    :persistent="false"
  >
    <div class="panel-card">
      <h2 class="panel-title">Variant Images</h2>
      <p class="panel-sub" v-if="variant">{{ variant.sku || `Variant #${variant.id}` }}</p>

      <!-- Existing images -->
      <div class="images-list" v-if="images.length">
        <div class="image-row" v-for="img in images" :key="img.id">
          <img :src="img.image_url" class="img-thumb" :alt="img.alt_text || ''" />
          <div class="image-meta">
            <div class="image-url" :title="img.image_url">{{ img.image_url }}</div>
            <div class="image-tags">
              <span v-if="img.role" class="tag">{{ img.role }}</span>
              <span class="tag">sort: {{ img.sort_order ?? 0 }}</span>
            </div>
          </div>
          <button
            class="btn-icon-del"
            @click="deleteImage(img)"
            :disabled="deleting === img.id"
            title="Remove image"
          >
            <v-icon size="16">mdi-close</v-icon>
          </button>
        </div>
      </div>
      <div v-else class="empty">No images added yet.</div>

      <!-- Add image form -->
      <div class="add-form">
        <h3 class="add-title">Add Image</h3>
        <div class="add-grid">
          <div class="field-label" style="grid-column: 1 / -1">
            Image *
            <ImageUploader v-model="newImg.image_url" :path-prefix="uploadPathPrefix" />
          </div>
          <label class="field-label">
            Alt Text
            <input
              v-model="newImg.alt_text"
              class="field-input"
              placeholder="e.g. Ring front view"
            />
          </label>
          <label class="field-label">
            Role
            <select v-model="newImg.role" class="field-input">
              <option value="">— none —</option>
              <option value="cover">cover</option>
              <option value="gallery">gallery</option>
              <option value="detail">detail</option>
            </select>
          </label>
          <label class="field-label">
            Sort Order
            <input
              v-model.number="newImg.sort_order"
              type="number"
              min="0"
              class="field-input"
              placeholder="0"
            />
          </label>
        </div>
        <div v-if="addError" class="add-error">{{ addError }}</div>
        <button class="btn-add" :disabled="!newImg.image_url || adding" @click="addImage">
          {{ adding ? 'Adding…' : '+ Add Image' }}
        </button>
      </div>

      <div class="panel-footer">
        <button class="btn-ghost" @click="$emit('update:modelValue', false)">Close</button>
      </div>
    </div>
  </v-dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useAdminStore } from '@/stores/admin'
import ImageUploader from '@/components/admin/ImageUploader.vue'

const props = defineProps({
  modelValue: Boolean,
  variant: { type: Object, default: null },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const admin = useAdminStore()

const uploadPathPrefix = computed(() =>
  props.variant?.id ? `variants/${props.variant.id}/gallery` : 'variants/gallery',
)

const images = computed(() =>
  props.variant
    ? [...(props.variant.variant_images ?? [])].sort(
        (a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0),
      )
    : [],
)

const defaultNew = () => ({ image_url: '', alt_text: '', role: '', sort_order: 0 })
const newImg = ref(defaultNew())
const adding = ref(false)
const addError = ref(null)
const deleting = ref(null)

watch(
  () => props.modelValue,
  (open) => {
    if (open) {
      newImg.value = defaultNew()
      addError.value = null
    }
  },
)

async function addImage() {
  if (!props.variant || !newImg.value.image_url) return
  adding.value = true
  addError.value = null
  try {
    await admin.addVariantImage({
      variant_id: props.variant.id,
      image_url: newImg.value.image_url,
      alt_text: newImg.value.alt_text || null,
      role: newImg.value.role || null,
      sort_order: newImg.value.sort_order ?? 0,
    })
    newImg.value = defaultNew()
    emit('saved')
  } catch (e) {
    addError.value = e.message
  } finally {
    adding.value = false
  }
}

async function deleteImage(img) {
  deleting.value = img.id
  try {
    await admin.deleteVariantImage(img.id)
    emit('saved')
  } catch {
    // silent — user can retry
  } finally {
    deleting.value = null
  }
}
</script>

<style scoped>
.panel-card {
  background: #fff;
  padding: 36px;
  font-family: 'Lora', 'Georgia', serif;
  max-height: 90vh;
  overflow-y: auto;
}

.panel-title {
  font-size: 20px;
  font-weight: 500;
  color: #1a1a1a;
  margin: 0 0 4px;
  letter-spacing: 0.04em;
}

.panel-sub {
  font-size: 12px;
  color: #9a9087;
  margin: 0 0 24px;
}

.images-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 28px;
}

.image-row {
  display: flex;
  align-items: center;
  gap: 12px;
  border: 1px solid #e8e2d8;
  padding: 8px;
  background: #faf9f7;
}

.img-thumb {
  width: 56px;
  height: 56px;
  object-fit: cover;
  flex-shrink: 0;
}

.image-meta {
  flex: 1;
  min-width: 0;
}

.image-url {
  font-size: 12px;
  color: #1a1a1a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.image-tags {
  margin-top: 4px;
  display: flex;
  gap: 6px;
}

.tag {
  font-size: 10px;
  letter-spacing: 0.08em;
  background: #f0ece6;
  color: #6b5b4a;
  padding: 2px 6px;
}

.btn-icon-del {
  background: none;
  border: none;
  color: #c0392b;
  cursor: pointer;
  padding: 4px;
  flex-shrink: 0;
}
.btn-icon-del:hover {
  background: #fdf0f0;
}
.btn-icon-del:disabled {
  opacity: 0.4;
  cursor: default;
}

.empty {
  padding: 24px;
  text-align: center;
  font-size: 13px;
  color: #9a9087;
  border: 1px solid #e8e2d8;
  margin-bottom: 28px;
}

.add-form {
  border-top: 1px solid #e8e2d8;
  padding-top: 24px;
  margin-bottom: 24px;
}

.add-title {
  font-size: 14px;
  font-weight: 500;
  color: #1a1a1a;
  letter-spacing: 0.06em;
  margin: 0 0 16px;
}

.add-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 14px;
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
  padding: 8px 12px;
  font-size: 13px;
  font-family: inherit;
  color: #1a1a1a;
  background: #faf9f7;
  outline: none;
}
.field-input:focus {
  border-color: #b8996a;
}

.add-error {
  font-size: 12px;
  color: #c0392b;
  margin-bottom: 10px;
}

.btn-add {
  background: #1a1a1a;
  color: #fff;
  border: none;
  padding: 9px 22px;
  font-size: 12px;
  letter-spacing: 0.1em;
  font-family: inherit;
  cursor: pointer;
}
.btn-add:hover:not(:disabled) {
  background: #b8996a;
}
.btn-add:disabled {
  opacity: 0.5;
  cursor: default;
}

.panel-footer {
  display: flex;
  justify-content: flex-end;
}

.btn-ghost {
  background: none;
  border: 1px solid #e8e2d8;
  color: #1a1a1a;
  padding: 9px 24px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
}
.btn-ghost:hover {
  border-color: #1a1a1a;
}
</style>
