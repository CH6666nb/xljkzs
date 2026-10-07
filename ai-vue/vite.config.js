import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// =============================================================================
// 后端服务地址（开发环境代理目标）
//   你写后端时，只要把这里改成自己后端的地址即可。
//   Spring Boot 默认端口是 8080，所以下面默认指向本机 8080。
//   如果你的后端端口不是 8080，改下面这一行就行。
// =============================================================================
const BACKEND_URL = 'http://localhost:8080'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      // @ 指向 src 目录，代码里可以写 import xxx from '@/api/user'
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    proxy: {
      // 前端所有以 /api 开头的请求，都会被转发到后端
      // 例如前端请求 /api/user/login  ->  实际请求 http://localhost:8080/user/login
      // （rewrite 的作用就是把开头的 /api 去掉，因为后端接口路径里没有 /api）
      '/api': {
        target: BACKEND_URL,
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  }
})
