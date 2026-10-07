// =============================================================================
// 全局状态管理（Pinia）
// 目前只存放"后台侧边栏是否折叠"这一个 UI 状态
// 说明：登录信息（token、用户信息）没有放在这里，而是存在 localStorage 中，
//      因为后端接口要求每次请求在请求头里带 token，放 localStorage 读写更方便
// =============================================================================
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAdminStore = defineStore('admin', () => {
    // 侧边栏是否折叠（供 Navbar 的折叠按钮和 Sidebar 组件共用）
    const isCollapse = ref(false)

    // 切换折叠状态
    const toggleCollapse = () => {
        isCollapse.value = !isCollapse.value
    }

    return {
        isCollapse,
        toggleCollapse
    }
})
