// =============================================================================
// 路由配置
//
// 整个项目分成三块，对应三个布局组件：
//   /auth  → AuthLayout   登录、注册（不带侧边栏的居中卡片布局）
//   /back  → BackendLayout 管理端（左侧菜单 + 顶部栏，需要登录）
//   /user  → UserLayout   用户端（AI 咨询、情绪日记、知识文章，需要登录）
//
// meta 里的字段说明：
//   title       菜单/页面标题（侧边栏和顶部面包屑用它）
//   icon        Element Plus 图标名（侧边栏的图标）
//   requireAuth 是否要求登录（配合下面的全局守卫）
// =============================================================================
import { createRouter, createWebHistory } from 'vue-router'
import BackendLayout from '@/components/BackendLayout.vue'
import AuthLayout from '@/components/AuthLayout.vue'
import UserLayout from '@/components/UserLayout.vue'


//路由配置
const backendRouter = [
    {
        path: '/',
        redirect: '/auth/login'   // 打开网站默认跳到登录页
    },
    {
        path: '/back',
        redirect: '/back/dashboard',
        component: BackendLayout,
        children: [
            {
                path: 'dashboard',
                component: () => import('@/views/dashboard.vue'),
                meta:{
                    title:'数据分析',

                    icon:'PieChart',
                }
            },
            {
                path: 'knowledge',
                component: () => import('@/views/knowledge.vue'),
                meta:{
                    title:'知识管理',
                    icon:'Reading',
                }
            },
            {
                path: 'consultations',
                component: () => import('@/views/consultations.vue'),
                meta:{
                    title:'咨询管理',
                    icon:'ChatDotRound',
                }
            },
            {
                path: 'emotional',
                component: () => import('@/views/emotional.vue'),
                meta:{
                    title:'情感管理',
                    icon:'Sunny',
                }
            },
        ]
    },
    {
        path:'/auth',
        redirect: '/auth/login',
        component:AuthLayout,
        children:[
            {
                path:'login',
                component: () => import('@/views/login.vue'),
                meta:{
                    title:'登录',
                    icon:'Login',
                }
            },
            {
                path:'register',
                component: () => import('@/views/register.vue'),
                meta:{
                    title:'注册',
                    icon:'Register',
                }
            }
        ]
    },
    {
        // 用户端：AI 咨询 / 情绪日记 / 知识文章
        path: '/user',
        redirect: '/user/chat',
        component: UserLayout,
        children: [
            {
                path: 'chat',
                component: () => import('@/views/user/chat.vue'),
                meta: {
                    title: 'AI咨询',
                    icon: 'ChatDotRound',
                    requireAuth: true
                }
            },
            {
                path: 'diary',
                component: () => import('@/views/user/diary.vue'),
                meta: {
                    title: '情绪日记',
                    icon: 'Notebook',
                    requireAuth: true
                }
            },
            {
                path: 'articles',
                component: () => import('@/views/user/articles.vue'),
                meta: {
                    title: '知识文章',
                    icon: 'Reading',
                    requireAuth: true
                }
            },
            {
                path: 'articles/:id',
                component: () => import('@/views/user/articleDetail.vue'),
                meta: {
                    title: '文章详情',
                    requireAuth: true
                }
            }
        ]
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes: backendRouter
})

// 全局前置守卫：未登录时只能访问登录/注册页
const WHITE_LIST = ['/auth/login', '/auth/register']
router.beforeEach((to) => {
    const token = localStorage.getItem('token')
    if (!token && !WHITE_LIST.includes(to.path)) {
        return '/auth/login'
    }
})

export default router
