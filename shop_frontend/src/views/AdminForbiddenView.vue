<template>
  <div class="forbidden">
    <div class="forbidden-inner">
      <div class="forbidden-code">403</div>
      <h1 class="forbidden-title">ACCESS DENIED</h1>
      <p class="forbidden-sub">You do not have permission to view this page.</p>
      <router-link to="/" class="forbidden-btn">GO HOME</router-link>
    </div>
  </div>
</template>

<script setup></script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.forbidden {
  min-height: 100vh;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Lora', 'Georgia', serif;
}

.forbidden-inner {
  text-align: center;
  padding: 48px 24px;
}

.forbidden-code {
  font-size: 96px;
  font-weight: 300;
  color: #e0d6c8;
  line-height: 1;
  letter-spacing: -4px;
  margin-bottom: 24px;
}

.forbidden-title {
  font-size: 22px;
  font-weight: 500;
  letter-spacing: 0.18em;
  color: #1a1a1a;
  margin: 0 0 12px;
}

.forbidden-sub {
  font-size: 14px;
  color: #6b5b4a;
  margin: 0 0 36px;
}

.forbidden-btn {
  display: inline-block;
  padding: 12px 36px;
  background: #1a1a1a;
  color: #fff;
  font-size: 11px;
  letter-spacing: 0.15em;
  text-decoration: none;
  font-family: inherit;
}

.forbidden-btn:hover {
  background: #b8996a;
}
</style>
