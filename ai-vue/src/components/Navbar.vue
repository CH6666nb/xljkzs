<!-- =============================================================================
     管理端顶部栏
     左侧：折叠菜单按钮；右侧：用户下拉菜单（退出登录）
     退出登录会调用 POST /user/logout，并清掉本地 token
     ============================================================================= -->
<template>
    <div class="navbar">
        <div class="flex-box">
            <el-button @click="handleCollapse">
                <el-icon><Expand /></el-icon>
            </el-button>
            <p class="brand-title">导航栏</p>
        </div>
        <div class="flex-box">
            <el-dropdown @command="handleCommand">
                <el-button>
                    <div class="flex-box">
                        <el-avatar src="https://pic1.zhimg.com/v2-4ce8619dbace99c1804d578c3b312334_r.jpg?source=1940ef5c"></el-avatar>
                        <p>用户中心</p>
                        <el-icon><ArrowDown/></el-icon>
                    </div>
                </el-button>
                <template #dropdown>
                    <el-dropdown-menu>
                        <el-dropdown-item command="logout">
                            退出登录
                        </el-dropdown-item>
                    </el-dropdown-menu>
                </template>
            </el-dropdown>
        </div>
    </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { logout } from '@/api/admin'
import { useMock } from '@/mock/knowledge'
import { useAdminStore } from '@/stores/admin'

const router = useRouter()

const handleCollapse = () => {
    useAdminStore().toggleCollapse()
}

// 退出登录：优先调用后端登出接口，无论成功与否都清理本地登录态并回到登录页
const handleCommand = async (command) => {
    if (command !== 'logout') return
    try {
        if (!useMock) {
            await logout()
        }
    } catch (error) {
        // 接口失败也继续退出，避免卡在后台
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
.flex-box {
    display: flex;
    align-items: center;
    justify-content: center;
}
.navbar {
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 20px;
    background-color: #f5f7fa;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
.brand-title {
    margin-left: 20px;
    font-size: 20px;
    font-weight: bold;
    color: #303133;
}

</style>
