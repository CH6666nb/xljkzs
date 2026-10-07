<!-- =============================================================================
     登录/注册页的布局：左右分栏
     左边是宣传区（渐变背景 + 机器人图），右边是 router-view（登录或注册表单）
     ============================================================================= -->
<template>
    <div class="auth-layout">
        <div class="left-section">
            <div class="left-content">
                <h1 class="title">ai情感管理系统</h1>
                <p class="text">基于vue3 + springboot 实现的情感管理系统</p>
                <div class="robot">
                    <el-image style="width: 100px; height: 100px;" :src="robotUrl" alt="robot"/>
                </div>
            </div>
        </div>


        <div class="right-section">
            <router-view></router-view>
        </div>


    </div>
</template>

<script setup>
import robotUrl from '@/assets/images/机器人.png'
</script>

<style scoped>
.auth-layout {
    display: flex;
    width: 100%;
    height: 100vh;
}

.left-section {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%);
}

.left-content {
    text-align: center;
}

.title {
    font-size: 32px;
    color: #303133;
    margin-bottom: 12px;
}

.text {
    font-size: 16px;
    color: #606266;
    margin-bottom: 24px;
}

.right-section {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f5f7fa;
}
</style>