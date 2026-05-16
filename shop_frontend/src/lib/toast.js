import { reactive } from 'vue'

export const toastState = reactive({ items: [] })

let _id = 0

/**
 * Show a toast. Callable from anywhere — components, stores, composables.
 * @param {string} message
 * @param {'success'|'error'|'info'} type
 * @param {number} duration ms before auto-dismiss
 */
export function showToast(message, type = 'success', duration = 2600) {
  const id = ++_id
  toastState.items.push({ id, message, type })
  setTimeout(() => {
    const idx = toastState.items.findIndex((t) => t.id === id)
    if (idx !== -1) toastState.items.splice(idx, 1)
  }, duration)
}
