<!-- =============================================================================
     登录页
     对接接口：POST /user/login（见 src/api/admin.js 的 login）
     流程：校验表单 → 调登录接口 → 存 token 和用户信息到 localStorage
          → 按 userType 跳转（2=管理员进后台，1=普通用户进用户端）
     ============================================================================= -->
<template>
    <div class="container">
        <div class="title">
            <div class="back-home">
                <el-icon>
                    <Back />
                </el-icon>
                <span>返回首页</span>
            </div>
            <div class="title-text">
                <h2>登录</h2>
                <p>登录以继续使用</p>
            </div>
        </div>
        <div class="form-container">
            <!-- el-form 的 rules 做前端校验，通过后才发请求；后端仍需再校验一次 -->
            <el-form
                ref="ruleFormRef"
                :model="formData"
                :rules="rules"
                label-width="120px"
                class="demo-form"
            >
                <el-form-item label="用户名" prop="username">
                    <el-input v-model="formData.username" placeholder="请输入用户名" />
                </el-form-item>


                <el-form-item label="密码" prop="password">
                    <el-input v-model="formData.password" type="password" placeholder="请输入密码" />
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" @click="submitForm(ruleFormRef)">登录</el-button>
                </el-form-item>
            </el-form>
            <div class="register">
                <p>还没有账号？<router-link to="/auth/register" type="primary">去注册</router-link></p>
            </div>
        </div>
    </div>
</template>


<script setup>
import { login } from '@/api/admin'
import { useMock } from '@/mock/knowledge'
import { useRouter } from 'vue-router'

import { ref } from 'vue'

// 表单实例，用来调用 validate() 触发校验
const ruleFormRef = ref()

// 表单数据（双向绑定到上面的 el-input）
const formData = ref({
    username: '',
    password: ''
})

// 校验规则
const rules = ref({
    username: [
        { required: true, message: '请输入用户名', trigger: 'blur' }
    ],
    password: [
        { required: true, message: '请输入密码', trigger: 'blur' }
    ]
})
const router = useRouter()

/**
 * 提交登录
 * @param formRef 表单实例（模板里通过 ref 传进来）
 */
const submitForm = async (formRef) => {
    if (!formRef) return
    await formRef.validate((valid) => {
        if (valid) {
            // mock 模式下的免后端登录：直接塞一个假 token 方便看页面效果。
            // useMock 已改为 false，所以正常都是走下面的真实接口。
            if (useMock && formData.value.username === 'admin' && formData.value.password === '123456') {
                localStorage.setItem('token', 'test-token')
                localStorage.setItem('userInfo', JSON.stringify({ username: 'admin', userType: 2 }))
                router.push('/back/dashboard')
                return
            }
            // 调用真实后端：POST /user/login
            // 后端返回 { code:200, data:{ token, userInfo } }，拦截器已剥掉外层，
            // 所以这里的 data 就是 { token, userInfo }
            login(formData.value).then(data => {
                if (!data.token) {
                    return console.error(data.msg || '登录失败')
                }
                // token 存起来，请求拦截器会自动加进请求头
                localStorage.setItem('token', data.token)
                localStorage.setItem('userInfo', JSON.stringify(data.userInfo))
                // 根据用户角色决定跳转的路径：2=管理员 → 后台；其它 → 用户端
                if (data.userInfo.userType === 2) {
                    router.push('/back/dashboard')
                } else {
                    router.push('/user')
                }
            })
        }
    })
}
</script>
