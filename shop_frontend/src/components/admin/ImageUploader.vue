<template>
  <div class="img-uploader">
    <!-- Preview -->
    <div v-if="modelValue" class="preview">
      <img :src="modelValue" class="preview-img" alt="Preview" />
      <button
        type="button"
        class="clear-btn"
        @click="$emit('update:modelValue', '')"
        title="Remove"
      >
        <v-icon size="14">mdi-close</v-icon>
      </button>
    </div>
    <div v-else class="preview preview--empty">
      <v-icon size="32" color="#c8bfb0">mdi-image-outline</v-icon>
    </div>

    <!-- Controls -->
    <div class="controls">
      <button type="button" class="btn-upload" :disabled="uploading" @click="fileInput?.click()">
        <v-icon size="14">mdi-upload</v-icon>
        {{ uploading ? 'Uploading…' : 'Upload file' }}
      </button>

      <span class="or-sep">or</span>

      <input
        :value="modelValue"
        @input="$emit('update:modelValue', $event.target.value)"
        class="url-input"
        placeholder="paste image URL…"
        type="url"
        :disabled="uploading"
      />
    </div>

    <div v-if="uploadProgress" class="upload-progress">
      <div class="progress-bar" :style="{ width: uploadProgress + '%' }" />
    </div>

    <div v-if="uploadError" class="upload-error">{{ uploadError }}</div>

    <input
      ref="fileInput"
      type="file"
      accept="image/jpeg,image/png,image/webp,image/gif"
      class="hidden-input"
      @change="onFileChange"
    />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAdminStore } from '@/stores/admin'

const props = defineProps({
  modelValue: { type: String, default: '' },
  pathPrefix: { type: String, default: 'products' },
})
const emit = defineEmits(['update:modelValue'])

const admin = useAdminStore()
const fileInput = ref(null)
const uploading = ref(false)
const uploadError = ref(null)
const uploadProgress = ref(0)

const MAX_FILE_SIZE = 5 * 1024 * 1024 // 5 MB

async function onFileChange(event) {
  const file = event.target.files?.[0]
  if (!file) return

  if (file.size > MAX_FILE_SIZE) {
    uploadError.value = 'File too large. Maximum size is 5 MB.'
    event.target.value = ''
    return
  }

  uploadError.value = null
  uploading.value = true
  uploadProgress.value = 10 // show immediate visual feedback

  let progressTimer
  try {
    // Simulate progress (Storage JS doesn't expose upload progress)
    progressTimer = setInterval(() => {
      if (uploadProgress.value < 80) uploadProgress.value += 15
    }, 200)

    const publicUrl = await admin.uploadImage(file, props.pathPrefix)

    uploadProgress.value = 100
    emit('update:modelValue', publicUrl)

    setTimeout(() => {
      uploadProgress.value = 0
    }, 600)
  } catch (e) {
    uploadError.value = e.message || 'Upload failed'
    uploadProgress.value = 0
  } finally {
    clearInterval(progressTimer)
    uploading.value = false
    // Reset so the same file can be re-selected if needed
    event.target.value = ''
  }
}
</script>

<style scoped>
.img-uploader {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.preview {
  position: relative;
  width: 100%;
  height: 120px;
  border: 1px solid #e8e2d8;
  background: #faf9f7;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.preview--empty {
  border-style: dashed;
}

.preview-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.clear-btn {
  position: absolute;
  top: 6px;
  right: 6px;
  background: rgba(255, 255, 255, 0.9);
  border: 1px solid #e8e2d8;
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  padding: 0;
  color: #1a1a1a;
}

.clear-btn:hover {
  background: #fff;
}

.controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-upload {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 7px 12px;
  font-size: 11px;
  letter-spacing: 0.08em;
  font-family: 'Lora', 'Georgia', serif;
  text-transform: uppercase;
  border: 1px solid #b8996a;
  color: #b8996a;
  background: transparent;
  cursor: pointer;
  white-space: nowrap;
  flex-shrink: 0;
}

.btn-upload:hover:not(:disabled) {
  background: #b8996a;
  color: #fff;
}

.btn-upload:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.or-sep {
  font-size: 11px;
  color: #9a9087;
  flex-shrink: 0;
}

.url-input {
  flex: 1;
  min-width: 0;
  border: 1px solid #e8e2d8;
  padding: 7px 10px;
  font-size: 12px;
  font-family: inherit;
  color: #1a1a1a;
  background: #faf9f7;
  outline: none;
}

.url-input:focus {
  border-color: #b8996a;
}

.url-input:disabled {
  opacity: 0.5;
}

.upload-progress {
  height: 2px;
  background: #e8e2d8;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: #b8996a;
  transition: width 0.2s ease;
}

.upload-error {
  font-size: 11px;
  color: #c0392b;
}

.hidden-input {
  display: none;
}
</style>
