<template>
  <div class="notfound-page">
    <div class="notfound-wrap">
      <div class="notfound-num">404</div>
      <h1 class="notfound-title">Page Not Found</h1>
      <p class="notfound-sub">
        The page you are looking for has moved, been removed, or does not exist.
      </p>
      <div class="notfound-actions">
        <router-link to="/" class="notfound-btn">GO HOME</router-link>
        <router-link to="/#catalog" class="notfound-btn notfound-btn--ghost"
          >SHOP COLLECTION</router-link
        >
      </div>
    </div>
  </div>
</template>

<script setup></script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.notfound-page {
  background: #fff;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
}

.notfound-wrap {
  text-align: center;
  max-width: 520px;
}

.notfound-num {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 96px;
  font-weight: 400;
  color: rgba(0, 0, 0, 0.06);
  line-height: 1;
  letter-spacing: 0.1em;
  margin-bottom: 24px;
  user-select: none;
}

.notfound-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 18px;
  font-weight: 400;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0 0 16px;
}

.notfound-sub {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  color: #6b5b4a;
  line-height: 1.8;
  margin: 0 0 40px;
}

.notfound-actions {
  display: flex;
  gap: 14px;
  justify-content: center;
  flex-wrap: wrap;
}

.notfound-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 44px;
  padding: 0 32px;
  background: #1a1a1a;
  color: #fff;
  border: 1px solid #1a1a1a;
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  text-decoration: none;
  cursor: pointer;
  transition: background 0.15s;
  border-radius: 0;
}

.notfound-btn:hover {
  background: #2a2a2a;
  border-color: #2a2a2a;
}

.notfound-btn--ghost {
  background: transparent;
  color: #1a1a1a;
}

.notfound-btn--ghost:hover {
  background: rgba(0, 0, 0, 0.04);
}
</style>
