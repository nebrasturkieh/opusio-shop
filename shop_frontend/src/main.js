// import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import 'vuetify/styles'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(vuetify)
console.log('Vuetify plugin:', vuetify)

app.mount('#app')
