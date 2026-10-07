<!-- =============================================================================
     管理端整体布局
     结构：左侧 Sidebar（菜单） + 右侧（顶部 Navbar  + 中间 router-view 内容区）
     路由 /back 下的所有页面都用这个布局
     ============================================================================= -->
<template>
    <el-container class="backend-layout">
        <Sidebar />
        <el-container class="main-container">
            <el-header class="navbar-header">
                <Navbar />
            </el-header>
            <el-main class="main-content">
                <!-- 子路由（数据分析/知识管理/咨询管理/情感管理）渲染在这里 -->
                <router-view />
            </el-main>
        </el-container>
    </el-container>
</template>

<script setup>
import Sidebar from './Sidebar.vue'
import Navbar from './Navbar.vue'
</script>

<style lang="scss" scoped>
.backend-layout {
    height: 100vh;
}

.main-container {
    height: 100%;
    overflow: hidden;
}

.navbar-header {
    height: 60px;
    padding: 0;
    border-bottom: 1px solid #e5e4e7;
    background-color: #fff;
}

.main-content {
    padding: 20px;
    background-color: white;
    min-height: calc(100% - 100px);
}
</style>
