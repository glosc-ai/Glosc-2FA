import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import DownloadView from '../views/DownloadView.vue'
import SupportView from '../views/SupportView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/download',
      name: 'download',
      component: DownloadView,
    },
    {
      path: '/support',
      name: 'support',
      component: SupportView,
    },
  ],
})

export default router
