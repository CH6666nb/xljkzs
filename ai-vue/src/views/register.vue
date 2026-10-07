<!-- =============================================================================
     注册页
     对接接口：POST /user/add（见 src/api/user.js 的 register）
     表单字段与数据库 user 表一一对应：
       username/email/password + nickname/phone/gender，
       其中 username 和 email 在数据库里是唯一索引，重复注册后端应返回错误提示
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
                <h2>注册</h2>
                <p>创建账号，开始使用心理健康AI助手</p>
            </div>
        </div>
        <div class="form-container">
            <el-form
                ref="ruleFormRef"
                :model="formData"
                :rules="rules"
                label-width="100px"
                class="demo-form"
            >
                <el-form-item label="用户名" prop="username">
                    <el-input v-model="formData.username" placeholder="请输入用户名" clearable />
                </el-form-item>
                <el-form-item label="邮箱" prop="email">
                    <el-input v-model="formData.email" placeholder="请输入邮箱" clearable />
                </el-form-item>
                <el-form-item label="昵称" prop="nickname">
                    <el-input v-model="formData.nickname" placeholder="请输入昵称（可选）" clearable />
                </el-form-item>
                <el-form-item label="手机号" prop="phone">
                    <el-input v-model="formData.phone" placeholder="请输入手机号（可选）" clearable />
                </el-form-item>
                <el-form-item label="密码" prop="password">
                    <el-input v-model="formData.password" type="password" placeholder="请输入密码" show-password />
                </el-form-item>
                <el-form-item label="确认密码" prop="confirmPassword">
                    <el-input v-model="formData.confirmPassword" type="password" placeholder="请再次输入密码" show-password />
                </el-form-item>
                <el-form-item label="性别" prop="gender">
                    <el-radio-group v-model="formData.gender">
                        <el-radio :value="1">男</el-radio>
                        <el-radio :value="2">女</el-radio>
                    </el-radio-group>
                </el-form-item>
                <el-form-item>
                    <el-button type="primary" :loading="submitting" @click="submitForm(ruleFormRef)">注册</el-button>
                    <el-button @click="resetForm(ruleFormRef)">重置</el-button>
                </el-form-item>
            </el-form>
            <div class="register">
                <p>已有账号？<router-link to="/auth/login">去登录</router-link></p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { register } from '@/api/user'

const router = useRouter()
const ruleFormRef = ref()
const submitting = ref(false)   // 提交中状态，用来给按钮加 loading 防止重复点击

// userType 固定传 1（普通用户），注册管理端账号需由后端/管理员处理
const formData = ref({
    username: '',
    email: '',
    nickname: '',
    phone: '',
    password: '',
    confirmPassword: '',
    gender: 1,
    userType: 1
})

// 前端校验规则（后端仍要再校验一次，前端校验只是提升体验）
const rules = ref({
    username: [
        { required: true, message: '请输入用户名', trigger: 'blur' },
        { min: 2, max: 20, message: '用户名长度为 2-20 个字符', trigger: 'blur' }
    ],
    email: [
        { required: true, message: '请输入邮箱', trigger: 'blur' },
        { type: 'email', message: '邮箱格式不正确', trigger: 'blur' }
    ],
    phone: [
        { pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }
    ],
    password: [
        { required: true, message: '请输入密码', trigger: 'blur' },
        { min: 6, max: 20, message: '密码长度为 6-20 个字符', trigger: 'blur' }
    ],
    confirmPassword: [
        { required: true, message: '请再次输入密码', trigger: 'blur' },
        {
            validator: (rule, value, callback) => {
                if (value !== formData.value.password) {
                    callback(new Error('两次输入的密码不一致'))
                } else {
                    callback()
                }
            },
            trigger: 'blur'
        }
    ],
    gender: [
        { required: true, message: '请选择性别', trigger: 'change' }
    ]
})

/**
 * 提交注册
 * 校验通过后调用 POST /user/add，成功后跳回登录页
 */
const submitForm = async (formRef) => {
    if (!formRef) return
    await formRef.validate(async (valid) => {
        if (!valid) return
        submitting.value = true
        try {
            await register(formData.value)
            ElMessage.success('注册成功，请登录')
            router.push('/auth/login')
        } catch (error) {
            // 具体错误信息已由响应拦截器统一弹出，这里只做日志
            console.error('注册失败：', error)
        } finally {
            submitting.value = false
        }
    })
}

// 重置表单（清空所有输入项）
const resetForm = (formRef) => {
    formRef?.resetFields()
}
</script>

<style scoped>
.container {
    width: 100%;
    max-width: 520px;
    padding: 20px;
}

.title {
    margin-bottom: 20px;
}

.back-home {
    display: flex;
    align-items: center;
    gap: 4px;
    color: #409eff;
    font-size: 14px;
    cursor: pointer;
    margin-bottom: 24px;
}

.title-text h2 {
    margin: 0 0 8px;
    color: #303133;
}

.title-text p {
    margin: 0;
    color: #909399;
    font-size: 14px;
}

.register {
    text-align: center;
    font-size: 14px;
    color: #909399;
}

.register a {
    color: #409eff;
    text-decoration: none;
}
</style>
