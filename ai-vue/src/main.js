// =============================================================================
// 项目入口文件
// 作用：创建 Vue 应用，注册 Element Plus 组件库、路由、状态管理，最后挂载到页面
// =============================================================================
import { createApp } from 'vue'
import ElementPlus from 'element-plus'                          // Element Plus UI 组件库（表格、表单、弹窗等）
import 'element-plus/dist/index.css'                            // Element Plus 样式
import * as ElementPlusIconsVue from '@element-plus/icons-vue'  // Element Plus 图标库
import './style.css'                                            // 项目全局样式
import App from './App.vue'                                     // 根组件
import router from './router'                                   // 路由配置
import {createPinia} from 'pinia'                               // Pinia 状态管理

const pinia = createPinia()

const app = createApp(App)

// 把 Element Plus 的所有图标注册成全局组件，
// 这样模板里可以直接写 <el-icon><User /></el-icon>，不用每个页面单独 import
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// 依次挂载：UI 库 → 路由 → 状态管理
app.use(ElementPlus).use(router).use(pinia)
app.mount('#app')
