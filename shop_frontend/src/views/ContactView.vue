<template>
  <div class="contact-page">
    <div class="contact-wrap">
      <header class="contact-header">
        <div class="contact-eyebrow">Client Services</div>
        <h1 class="contact-title">HOW TO CONTACT US</h1>
        <div class="contact-rule"></div>
        <p class="contact-subtitle">Choose your preferred method of contact and connect with us</p>
      </header>

      <div class="contact-grid">
        <!-- Phone -->
        <div class="contact-card">
          <div class="card-icon-wrap">
            <svg
              class="card-icon"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M6.1 3H3.5C3.2 3 3 3.2 3 3.5C3 11.5 9.5 17 17.5 17C17.8 17 18 16.8 18 16.5V14C18 13.7 17.8 13.5 17.5 13.4L14.5 12.4C14.2 12.3 13.9 12.4 13.8 12.6L12.6 13.8C11 13 9 11 8.2 9.4L9.4 8.2C9.6 8.1 9.7 7.8 9.6 7.5L8.6 4.5C8.5 4.2 8.3 4 8 4H6.1Z"
                stroke="#b8996a"
                stroke-width="1.2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </div>
          <h2 class="card-title">PHONE</h2>
          <p class="card-hours">Monday – Friday &nbsp;·&nbsp; 9 AM to 6 PM (CET)</p>
          <a href="tel:+4930123456789" class="card-link">Call Us</a>
        </div>

        <!-- Email -->
        <div class="contact-card">
          <div class="card-icon-wrap">
            <svg
              class="card-icon"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <rect
                x="2.5"
                y="5"
                width="15"
                height="10"
                rx="1"
                stroke="#b8996a"
                stroke-width="1.2"
              />
              <path d="M2.5 6L10 11.5L17.5 6" stroke="#b8996a" stroke-width="1.2" />
            </svg>
          </div>
          <h2 class="card-title">EMAIL</h2>
          <p class="card-hours">
            Your inquiry will receive a response from a dedicated Client Advisor
          </p>
          <button class="card-link" type="button" @click="openPanel('email')">Write Us</button>
        </div>

        <!-- WhatsApp -->
        <div class="contact-card">
          <div class="card-icon-wrap">
            <svg
              class="card-icon"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M10 2C5.58 2 2 5.58 2 10C2 11.48 2.41 12.86 3.12 14.04L2 18L6.06 16.9C7.21 17.56 8.56 17.94 10 17.94C14.42 17.94 18 14.36 18 9.94C18 5.58 14.42 2 10 2Z"
                stroke="#b8996a"
                stroke-width="1.2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <path
                d="M7.5 9.5C7.5 9.5 8 11 9.5 12.5C11 14 12.5 14.5 12.5 14.5L13.5 13.5C13.5 13.5 13.8 13.2 14.1 13.3L15.8 14C16 14.1 16 14.3 16 14.5V15.5C16 15.8 15.8 16 15.5 16C11.5 16 4 9.5 4 5.5C4 5.2 4.2 5 4.5 5H5.5C5.7 5 5.9 5.1 5.9 5.3L6.7 7C6.8 7.3 6.5 7.5 6.5 7.5L7.5 9.5Z"
                stroke="#b8996a"
                stroke-width="1.2"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </div>
          <h2 class="card-title">WHATSAPP</h2>
          <p class="card-hours">Monday – Friday &nbsp;·&nbsp; 9 AM to 6 PM (CET)</p>
          <button class="card-link" type="button" @click="openPanel('whatsapp')">
            Chat With Us
          </button>
        </div>
      </div>
    </div>

    <!-- Side panel overlay -->
    <transition name="panel-fade">
      <div v-if="activePanel" class="panel-overlay" @click.self="closePanel">
        <!-- EMAIL PANEL -->
        <aside v-if="activePanel === 'email'" class="side-panel">
          <button class="panel-close" type="button" aria-label="Close" @click="closePanel">
            ✕
          </button>
          <h2 class="panel-title">EMAIL US</h2>

          <form class="panel-form" novalidate @submit.prevent="submitEmail">
            <div class="form-group">
              <label class="form-label">First Name*</label>
              <input
                v-model="emailForm.firstName"
                class="form-input"
                type="text"
                autocomplete="given-name"
                required
              />
              <span v-if="emailErrors.firstName" class="field-error">{{
                emailErrors.firstName
              }}</span>
            </div>

            <div class="form-group">
              <label class="form-label">Last Name*</label>
              <input
                v-model="emailForm.lastName"
                class="form-input"
                type="text"
                autocomplete="family-name"
                required
              />
              <span v-if="emailErrors.lastName" class="field-error">{{
                emailErrors.lastName
              }}</span>
            </div>

            <div class="form-group">
              <label class="form-label">Email address*</label>
              <input
                v-model="emailForm.email"
                class="form-input"
                type="email"
                autocomplete="email"
                required
              />
              <span v-if="emailErrors.email" class="field-error">{{ emailErrors.email }}</span>
            </div>

            <div class="form-group">
              <label class="form-label">Phone number</label>
              <input v-model="emailForm.phone" class="form-input" type="tel" autocomplete="tel" />
            </div>

            <div class="form-group">
              <label class="form-label">Subject*</label>
              <select v-model="emailForm.subject" class="form-input form-select" required>
                <option value="" disabled>Select a subject</option>
                <option>Order inquiry</option>
                <option>Product information</option>
                <option>Return or exchange</option>
                <option>Other</option>
              </select>
              <span v-if="emailErrors.subject" class="field-error">{{ emailErrors.subject }}</span>
            </div>

            <div class="form-group">
              <label class="form-label">Your inquiry or comment*</label>
              <textarea
                v-model="emailForm.message"
                class="form-input form-textarea"
                rows="4"
                required
              ></textarea>
              <span v-if="emailErrors.message" class="field-error">{{ emailErrors.message }}</span>
            </div>

            <p v-if="emailSent" class="send-success">
              Your message has been sent. We will reply within 2 business days.
            </p>

            <button class="panel-submit-btn" type="submit" :disabled="emailSending">
              {{ emailSending ? 'SENDING…' : 'SEND EMAIL' }}
            </button>
          </form>
        </aside>

        <!-- WHATSAPP PANEL -->
        <aside v-else-if="activePanel === 'whatsapp'" class="side-panel">
          <button class="panel-close" type="button" aria-label="Close" @click="closePanel">
            ✕
          </button>
          <h2 class="panel-title">CONNECT TO WHATSAPP</h2>
          <p class="panel-desc">
            Scan the QR code with your smartphone to connect with our Client Service, or click the
            link below to open WhatsApp Web.
          </p>

          <div class="qr-wrap">
            <!-- SVG placeholder QR — replace src with a real QR image -->
            <img
              src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=https://wa.me/4930123456789"
              alt="WhatsApp QR code"
              class="qr-img"
              width="180"
              height="180"
            />
          </div>

          <a
            href="https://wa.me/4930123456789"
            target="_blank"
            rel="noopener noreferrer"
            class="wa-web-link"
          >
            Click here to open WhatsApp Web
          </a>
        </aside>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'

const activePanel = ref(null)

function openPanel(type) {
  activePanel.value = type
  document.body.style.overflow = 'hidden'
}

function closePanel() {
  activePanel.value = null
  document.body.style.overflow = ''
  emailSent.value = false
  emailSending.value = false
  Object.keys(emailErrors).forEach((k) => delete emailErrors[k])
}

// Email form
const emailForm = reactive({
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  subject: '',
  message: '',
})
const emailErrors = reactive({})
const emailSending = ref(false)
const emailSent = ref(false)

function validateEmail() {
  Object.keys(emailErrors).forEach((k) => delete emailErrors[k])
  let ok = true
  if (!emailForm.firstName.trim()) {
    emailErrors.firstName = 'Required'
    ok = false
  }
  if (!emailForm.lastName.trim()) {
    emailErrors.lastName = 'Required'
    ok = false
  }
  if (!emailForm.email.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailForm.email)) {
    emailErrors.email = 'Valid email required'
    ok = false
  }
  if (!emailForm.subject) {
    emailErrors.subject = 'Please select a subject'
    ok = false
  }
  if (!emailForm.message.trim()) {
    emailErrors.message = 'Required'
    ok = false
  }
  return ok
}

async function submitEmail() {
  if (!validateEmail()) return
  emailSending.value = true
  // Simulate sending (replace with real API call / Supabase edge function)
  await new Promise((r) => setTimeout(r, 1000))
  emailSending.value = false
  emailSent.value = true
  Object.assign(emailForm, {
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    subject: '',
    message: '',
  })
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.contact-page {
  background: #fff;
  min-height: 100vh;
  padding: 80px 0 120px;
}

.contact-wrap {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 24px;
}

/* ── header ── */
.contact-header {
  text-align: center;
  margin-bottom: 80px;
}

.contact-eyebrow {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.26em;
  text-transform: uppercase;
  color: #b8996a;
  margin-bottom: 20px;
}

.contact-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 28px;
  font-weight: 400;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 auto 28px;
  max-width: 680px;
  line-height: 1.25;
}

.contact-rule {
  width: 40px;
  height: 1px;
  background: #b8996a;
  margin: 0 auto 24px;
}

.contact-subtitle {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  font-weight: 400;
  letter-spacing: 0.02em;
  color: #6b5b4a;
  margin: 0;
  font-style: italic;
}

/* ── strips — stacked vertically, centered content ── */
.contact-grid {
  display: flex;
  flex-direction: column;
  border-top: 1px solid rgba(0, 0, 0, 0.08);
}

.contact-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 64px 40px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.card-icon-wrap {
  width: 52px;
  height: 52px;
  border: 1px solid rgba(184, 153, 106, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-bottom: 28px;
}

.card-icon {
  width: 22px;
  height: 22px;
}

.card-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 14px;
}

.card-hours {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #6b5b4a;
  line-height: 1.75;
  margin: 0 0 32px;
  font-style: italic;
  max-width: 420px;
}

.card-link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #1a1a1a;
  text-decoration: none;
  background: transparent;
  border: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.3);
  padding-bottom: 4px;
  cursor: pointer;
  transition:
    color 0.18s,
    border-color 0.18s;
}
.card-link:hover {
  color: #b8996a;
  border-bottom-color: #b8996a;
}

/* ── panel overlay ── */
.panel-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.36);
  z-index: 3500;
  display: flex;
  justify-content: flex-end;
}

.side-panel {
  width: 420px;
  max-width: 100vw;
  background: #fff;
  height: 100%;
  overflow-y: auto;
  padding: 32px 36px 60px;
  position: relative;
  box-shadow: -4px 0 32px rgba(0, 0, 0, 0.12);
}

.panel-close {
  position: absolute;
  top: 20px;
  right: 20px;
  background: transparent;
  border: none;
  font-size: 18px;
  cursor: pointer;
  color: #1a1a1a;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background 0.15s;
}
.panel-close:hover {
  background: rgba(0, 0, 0, 0.06);
}

.panel-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 32px;
}

.panel-desc {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
  line-height: 1.8;
  margin: 0 0 32px;
}

/* ── email form ── */
.panel-form {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.form-group {
  display: flex;
  flex-direction: column;
  margin-bottom: 24px;
}

.form-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #888;
  margin-bottom: 10px;
}

.form-input {
  width: 100%;
  border: none;
  border-bottom: 1px solid rgba(0, 0, 0, 0.2);
  padding: 10px 0;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 14px;
  color: #1a1a1a;
  background: transparent;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
  border-radius: 0;
  appearance: none;
  -webkit-appearance: none;
}
.form-input:focus {
  border-bottom-color: #000;
}

.form-select {
  cursor: pointer;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' stroke='%231a1a1a' stroke-width='1.2' fill='none' stroke-linecap='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 4px center;
  padding-right: 24px;
}

.form-textarea {
  resize: vertical;
  min-height: 90px;
  line-height: 1.6;
}

.field-error {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  color: #8e2134;
  margin-top: 6px;
}

.send-success {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 12px;
  color: #2c6e49;
  background: rgba(44, 110, 73, 0.06);
  border: 1px solid rgba(44, 110, 73, 0.2);
  padding: 12px 14px;
  margin-bottom: 16px;
  line-height: 1.6;
}

.panel-submit-btn {
  width: 100%;
  height: 46px;
  background: #1a1a1a;
  color: #fff;
  border: none;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  cursor: pointer;
  transition: background 0.15s;
  border-radius: 0;
  margin-top: 8px;
}
.panel-submit-btn:hover:not(:disabled) {
  background: #2a2a2a;
}
.panel-submit-btn:disabled {
  background: #b8b2ab;
  color: #f5f2ee;
  cursor: not-allowed;
}

/* ── WhatsApp panel ── */
.qr-wrap {
  margin: 0 0 28px;
}

.qr-img {
  display: block;
  width: 180px;
  height: 180px;
  border: 1px solid rgba(0, 0, 0, 0.08);
}

.wa-web-link {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #1a1a1a;
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 1px;
  transition: color 0.15s;
}
.wa-web-link:hover {
  color: #b8996a;
}

/* ── transition ── */
.panel-fade-enter-active {
  transition: opacity 0.2s ease;
}
.panel-fade-leave-active {
  transition: opacity 0.22s ease;
}
.panel-fade-enter-from,
.panel-fade-leave-to {
  opacity: 0;
}
.panel-fade-enter-active .side-panel {
  transition: transform 0.28s cubic-bezier(0.22, 1, 0.36, 1);
}
.panel-fade-leave-active .side-panel {
  transition: transform 0.22s cubic-bezier(0.22, 1, 0.36, 1);
}
.panel-fade-enter-from .side-panel {
  transform: translateX(100%);
}
.panel-fade-leave-to .side-panel {
  transform: translateX(100%);
}

/* ── responsive ── */
@media (max-width: 640px) {
  .contact-card {
    padding: 48px 16px;
  }

  .contact-title {
    font-size: 20px;
  }

  .side-panel {
    width: 100vw;
    padding: 32px 24px 60px;
  }
}
</style>
