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
      meta: { title: 'Opusio' },
    },
    {
      path: '/product/:id',
      name: 'product',
      component: ProductView,
      props: true,
      // title set dynamically by ProductView once product loads
    },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import('../views/AboutView.vue'),
      meta: { title: 'About — Opusio' },
    },
    {
      path: '/cart',
      name: 'cart',
      component: () => import('../views/CartView.vue'),
      meta: { title: 'Shopping Bag — Opusio' },
    },
    {
      path: '/wishlist',
      name: 'wishlist',
      component: () => import('../views/WishlistView.vue'),
      meta: { title: 'Wishlist — Opusio' },
    },
    {
      path: '/auth',
      name: 'auth',
      component: AuthView,
      meta: { title: 'Sign In — Opusio' },
    },
    {
      path: '/auth/callback',
      name: 'auth-callback',
      component: () => import('@/views/AuthCallbackView.vue'),
      meta: { title: 'Opusio' },
    },
    {
      path: '/profile',
      name: 'profile',
      component: () => import('@/views/ProfileView.vue'),
      meta: { requiresAuth: true, title: 'My Account — Opusio' },
    },
    {
      path: '/checkout',
      name: 'checkout',
      component: () => import('@/views/CheckoutView.vue'),
      meta: { requiresAuth: true, title: 'Checkout — Opusio' },
    },
    {
      path: '/order/:id',
      name: 'order-confirm',
      component: () => import('@/views/OrderConfirmView.vue'),
      meta: { requiresAuth: true, title: 'Order Confirmed — Opusio' },
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('@/views/NotFoundView.vue'),
      meta: { title: 'Page Not Found — Opusio' },
    },
    {
      path: '/contact',
      name: 'contact',
      component: () => import('@/views/ContactView.vue'),
      meta: { title: 'Contact — Opusio' },
    },
    {
      path: '/admin',
      component: () => import('@/views/admin/AdminLayout.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
      children: [
        {
          path: '',
          name: 'admin-dashboard',
          component: () => import('@/views/admin/AdminDashboardView.vue'),
          meta: { title: 'Dashboard — Admin' },
        },
        {
          path: 'products',
          name: 'admin-products',
          component: () => import('@/views/admin/AdminProductsView.vue'),
          meta: { title: 'Products — Admin' },
        },
        {
          path: 'products/:id',
          name: 'admin-product-detail',
          component: () => import('@/views/admin/AdminProductDetailView.vue'),
          meta: { title: 'Product — Admin' },
          props: true,
        },
        {
          path: 'orders',
          name: 'admin-orders',
          component: () => import('@/views/admin/AdminOrdersView.vue'),
          meta: { title: 'Orders — Admin' },
        },
      ],
    },
    {
      path: '/forbidden',
      name: 'forbidden',
      component: () => import('@/views/AdminForbiddenView.vue'),
      meta: { title: 'Access Denied — Opusio' },
    },
  ],
})

// Simple navigation guard example for routes that require auth
router.beforeEach(async (to) => {
  const auth = useAuthStore()
  // Always wait for init to complete — it is idempotent after the first call.
  // The old condition (!auth.user && !auth.loading) skipped init when the user
  // was already set but the profile had not loaded yet, causing isAdmin to be
  // false and incorrectly redirecting admins to /forbidden.
  if (!auth.initialized) {
    try {
      await auth.init()
    } catch {
      // ignore — guard proceeds with whatever state is available
    }
  }

  if (to.meta?.requiresAuth && !auth.isAuthenticated) {
    return { name: 'auth', query: { redirect: to.fullPath } }
  }

  if (to.meta?.requiresAdmin && !auth.isAdmin) {
    return { name: 'forbidden' }
  }
})

router.afterEach((to) => {
  if (to.meta?.title) {
    document.title = to.meta.title
  }
})

export default router
