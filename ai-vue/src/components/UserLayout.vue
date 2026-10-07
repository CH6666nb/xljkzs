<!-- =============================================================================
     用户端整体布局：顶部横向导航 + 内容区
     导航项：AI咨询 / 情绪日记 / 知识文章
     ============================================================================= -->
<template>
    <div class="user-layout">
        <!-- 顶部导航 -->
        <header class="user-header">
            <div class="header-left">
                <el-image :src="iconUrl" alt="logo" class="header-logo" />
                <span class="header-title">心理健康AI助手</span>
            </div>

            <el-menu
                mode="horizontal"
                :default-active="activeMenu"
                router
                class="header-menu"
                :ellipsis="false"
            >
                <el-menu-item
                    v-for="item in menuItems"
                    :key="item.path"
                    :index="item.path"
                >
                    <el-icon><component :is="item.icon" /></el-icon>
                    <span>{{ item.title }}</span>
                </el-menu-item>
            </el-menu>

            <div class="header-right">
                <el-dropdown @command="handleCommand">
                    <div class="user-info">
                        <el-avatar :size="32" class="user-avatar">
                            {{ nickname.slice(0, 1) }}
                        </el-avatar>
                        <span class="user-name">{{ nickname }}</span>
                        <el-icon><ArrowDown /></el-icon>
                    </div>
                    <template #dropdown>
                        <el-dropdown-menu>
                            <el-dropdown-item command="logout">退出登录</el-dropdown-item>
                        </el-dropdown-menu>
                    </template>
                </el-dropdown>
            </div>
        </header>

        <!-- 页面内容 -->
        <main class="user-main">
            <router-view />
        </main>
    </div>
</template>

<script setup>
// 用户端整体布局：顶部导航 + 内容区
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import iconUrl from '@/assets/images/机器人.png'
import { logout } from '@/api/admin'
import { useMock } from '@/mock/knowledge'

const route = useRoute()
const router = useRouter()

// 用户端菜单
const menuItems = [
    { path: '/user/chat', title: 'AI咨询', icon: 'ChatDotRound' },
    { path: '/user/diary', title: '情绪日记', icon: 'Notebook' },
    { path: '/user/articles', title: '知识文章', icon: 'Reading' }
]

// 文章详情页高亮“知识文章”菜单
const activeMenu = computed(() => {
    if (route.path.startsWith('/user/articles')) return '/user/articles'
    return route.path
})

const nickname = computed(() => {
    try {
        const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
        return userInfo.nickname || userInfo.username || '用户'
    } catch {
        return '用户'
    }
})

// 退出登录：优先调用后端登出接口，无论成功与否都清理本地登录态并回到登录页
const handleCommand = async (command) => {
    if (command !== 'logout') return
    try {
        if (!useMock) {
            await logout()
        }
    } catch (error) {
        console.error('退出登录接口失败：', error)
    } finally {
        localStorage.removeItem('token')
        localStorage.removeItem('userInfo')
        ElMessage.success('已退出登录')
        router.push('/auth/login')
    }
}
</script>

<style lang="scss" scoped>
.user-layout {
    min-height: 100vh;
    background-color: #f5f7fa;
    display: flex;
    flex-direction: column;
}

.user-header {
    display: flex;
    align-items: center;
    gap: 32px;
    height: 60px;
    padding: 0 24px;
    background-color: #fff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    position: sticky;
    top: 0;
    z-index: 10;

    .header-left {
        display: flex;
        align-items: center;
        gap: 10px;

        .header-logo {
            width: 36px;
            height: 36px;
        }

        .header-title {
            font-size: 17px;
            font-weight: 700;
            color: #303133;
            white-space: nowrap;
        }
    }

    .header-menu {
        flex: 1;
        border-bottom: none;

        :deep(.el-menu-item) {
            height: 60px;
        }
    }

    .header-right {
        .user-info {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;

            .user-avatar {
                background-color: #409eff;
                color: #fff;
                font-size: 14px;
            }

            .user-name {
                font-size: 14px;
                color: #606266;
                max-width: 120px;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            }
        }
    }
}

.user-main {
    flex: 1;
    padding: 20px;
    max-width: 1200px;
    width: 100%;
    margin: 0 auto;
    box-sizing: border-box;
}
</style>
