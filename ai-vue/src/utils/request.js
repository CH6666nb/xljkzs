// =============================================================================
// axios 统一请求封装
// 所有接口调用都走这个文件导出的 service 实例，好处是：
//   1) 统一加请求头 token        —— 见"请求拦截器"
//   2) 统一处理返回结果和错误提示 —— 见"响应拦截器"
// =============================================================================
import axios from 'axios'
import { ElMessage } from 'element-plus'

const service = axios.create({
    baseURL: '/api',    // 所有请求自动加上 /api 前缀，再由 vite 代理转发到后端
    timeout: 10000,     // 超时时间 10 秒，超时会走到下面的错误处理
})

// -----------------------------------------------------------------------------
// 请求拦截器：每次请求发出前都会执行
// -----------------------------------------------------------------------------
service.interceptors.request.use(
    config => {
        // 接口文档要求：需要登录的接口在请求头 token 中携带令牌。
        // 注意这里不带 "Bearer " 前缀，直接放 token 原值。
        const token = localStorage.getItem('token')
        if (token) {
            config.headers['token'] = token
        }
        return config
    },
    error => {
        return Promise.reject(error)
    }
)


// -----------------------------------------------------------------------------
// 响应拦截器：后端返回后、业务代码拿到数据前执行
// 后端统一返回结构：{ code, msg(或 message), data }
//   code = 200  → 成功，这里直接 return data.data，
//                 所以业务代码里拿到的就是真正的数据，不用再 .data.data 层层剥
//   code = -1   → 登录失效/未登录，清除本地 token 并跳回登录页
//   其它 code   → 弹出后端返回的错误提示
// 为兼容后端可能返回字符串 "200"，这里统一转成数字再比较
// -----------------------------------------------------------------------------
service.interceptors.response.use(
    response => {
        const { data, config } = response
        const code = Number(data?.code)
        if (code === 200) {
            return data.data
        } else {
            if (code === -1) {
                // 登录接口本身返回 -1 时（账号密码错误），只提示不跳转
                if (!config.url?.includes('/user/login')) {
                    ElMessage.error('登录过期，请重新登录')
                    localStorage.removeItem('token')
                    localStorage.removeItem('userInfo')
                    window.location.href = '/auth/login'
                } else {
                    ElMessage.error(data.msg || '登录过期，请重新登录')
                    return Promise.reject('网络请求失败')
                }
            } else {
                ElMessage.error(data?.msg || data?.message || '请求失败')
            }
            return Promise.reject(data)
        }
    },
    error => {
        // 网络错误 / 请求超时 / 后端 5xx 等都会走到这里
        ElMessage.error(error?.message || '网络异常，请稍后重试')
        return Promise.reject(error)
    }
)

export default service
