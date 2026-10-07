<!-- =============================================================================
     管理端左侧菜单
     菜单项不是写死的，而是从路由配置里读 /back 的子路由自动生成，
     所以以后加页面只要在 router/index.js 里加一条路由，菜单会自动出现
     ============================================================================= -->
<template>
    <el-aside :width="isCollapse ? '64px' : '220px'" class="aside-wrapper">
        <el-menu
            :collapse="isCollapse"
            :default-active="route.path"
            router
            class="menu-style"
        >
            <div class="brand">
                <el-image :src="iconUrl" alt="logo" class="brand-logo" />
                <div class="info-card">
                    <h2 class="brand-title">心理健康AI助手</h2>
                    <p class="brand-desc">后台管理</p>
                </div>
            </div>

            <el-menu-item
                v-for="item in menuItems"
                :key="item.fullPath"
                :index="item.fullPath"
            >
                <el-icon><component :is="item.meta.icon" /></el-icon>
                <span>{{ item.meta.title }}</span>
            </el-menu-item>
        </el-menu>
    </el-aside>
</template>


<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import iconUrl from '@/assets/images/机器人.png'
import { useAdminStore } from '@/stores/admin'

const route = useRoute()
const router = useRouter()
const adminStore = useAdminStore()
const isCollapse = computed(() => adminStore.isCollapse)

// 取 /back 的子路由作为菜单项，拼接出完整路径供 el-menu 跳转
const menuItems = computed(() => {
    const backRoute = router.options.routes.find(r => r.path === '/back')
    if (!backRoute?.children) return []
    return backRoute.children.map(c => ({
        ...c,
        fullPath: c.path.startsWith('/') ? c.path : `${backRoute.path}/${c.path}`
    }))
})
</script>


<style lang="scss" scoped>
.aside-wrapper {
    background-color: #304156;
    height: 100vh;
    overflow-y: auto;
}

.menu-style {
    height: 100%;
    background-color: #304156;
    border-right: none;
}

.brand {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.brand-logo {
    width: 40px;
    height: 40px;
    flex-shrink: 0;
}

.info-card {
    display: flex;
    flex-direction: column;
}

.brand-title {
    font-size: 15px;
    font-weight: 600;
    color: #fff;
    margin: 0;
    line-height: 1.3;
}

.brand-desc {
    font-size: 12px;
    color: rgba(255, 255, 255, 0.6);
    margin: 2px 0 0;
    line-height: 1.3;
}

:deep(.el-menu-item) {
    color: #bfcbd9;

    &:hover,
    &.is-active {
        background-color: #263445;
        color: #fff;
    }
}
</style>
