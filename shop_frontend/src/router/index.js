import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import ProductView from '@/views/ProductView.vue'
import AuthView from '@/views/AuthView.vue'
import { useAuthStore } from '@/stores/auth'
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(to, from, savedPosition) {
    // If the user navigates to the home page with #catalog, jump straight to catalog
    if (to.hash === '#catalog') {
      return { el: to.hash, behavior: 'auto' }
    }

    // Preserve browser back/forward scroll position
    if (savedPosition) return savedPosition

    // Default behavior: scroll to top
    return { top: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/product/:id',
      name: 'product',
      component: ProductView,
      props: true,
    },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import('../views/AboutView.vue'),
    },
    {
      path: '/cart',
      name: 'cart',
      component: () => import('../views/CartView.vue'),
    },
    {
      path: '/wishlist',
      name: 'wishlist',
      component: () => import('../views/WishlistView.vue'),
    },
    {
      path: '/auth',
      name: 'auth',
      component: AuthView,
    },
  ],
})

// Simple navigation guard example for routes that require auth
router.beforeEach(async (to) => {
  // lazy-init auth store when navigation happens
  const auth = useAuthStore()
  // ensure auth initialized (no-op after first call)
  if (!auth.user && !auth.loading) {
    try {
      await auth.init()
    } catch (e) {
      // ignore
    }
  }

  if (to.meta && to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'auth', query: { redirect: to.fullPath } }
  }
})

export default router
