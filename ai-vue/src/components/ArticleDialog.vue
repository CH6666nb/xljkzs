<!-- =============================================================================
     新增/编辑文章弹窗（知识管理页的子组件）
     对接接口：
       POST /file/upload              上传封面图片
       POST /knowledge/article        新增文章
       PUT  /knowledge/article/{id}   更新文章
     用法：父组件通过 v-model 控制显隐，:article 传要编辑的文章（null 表示新增），
          新增/修改成功后触发 @success 让父组件刷新列表
     ============================================================================= -->
<template>
    <el-dialog
        :title="formData.id ? '编辑文章' : '新增文章'"
        v-model="dialogVisible"
        width="60%"
        destroy-on-close
        @close="handleClose"
    >
        <el-form :model="formData" :rules="rules" ref="formRef" label-width="120px">
            <el-form-item label="文章标题" prop="title">
                <el-input v-model="formData.title" placeholder="请输入文章标题" maxlength="100" show-word-limit clearable></el-input>
            </el-form-item>
            <el-form-item label="文章分类" prop="categoryId">
                <el-select v-model="formData.categoryId" placeholder="请选择文章分类" clearable>
                    <el-option v-for="item in props.categoryOptions" :key="item.value" :label="item.label" :value="item.value"></el-option>
                </el-select>
            </el-form-item>
            <el-form-item label="文章摘要" prop="summary">
                <el-input v-model="formData.summary" placeholder="请输入文章摘要" maxlength="500" show-word-limit :rows="4"></el-input>
            </el-form-item>
            <el-form-item label="文章标签" prop="tags">
                <el-select v-model="formData.tagArray" placeholder="请选择文章标签" multiple filterable allow-create style="width: 100%">
                    <el-option v-for="tag in commonTags" :key="tag" :label="tag" :value="tag"></el-option>
                </el-select>
            </el-form-item>
            <el-form-item label="封面图片" prop="coverImage">
                <el-upload
                    class="avatar-uploader"
                    action="#"
                    :show-file-list="false"
                    :before-upload="beforeAvatarUpload"
                    :http-request="handleUploadRequest"
                    accept="image/*">
                    <div v-if="!imgUrl" v-loading="uploading" class="cover-placeholder">
                        <el-icon v-if="!uploading" class="avatar-uploader-icon"><Plus /></el-icon>
                        <p>{{ uploading ? '上传中...' : '点击上传封面图片' }}</p>
                    </div>
                    <img v-else :src="imgUrl" class="avatar" alt="封面图片" />
                </el-upload>
                <el-button v-if="imgUrl && !uploading" type="danger" size="small" @click="handleRemove">删除封面</el-button>
            </el-form-item>
            <el-form-item label="文章内容" prop="content">
                <RichTextEditor v-model="formData.content" />
            </el-form-item>
        </el-form>
        <template #footer>
            <el-button @click="handleClose">取消</el-button>
            <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
        </template>
    </el-dialog>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { uploadFile, createArticle, updateArticle } from '@/api/admin'
import {fileBaseUrl} from '@/config/index'
import RichTextEditor from '@/components/RichTextEditor.vue'
import { useMock, mockArticles } from '@/mock/knowledge'

const props = defineProps({
    modelValue: {
        type: Boolean,
        default: false
    },
    categoryOptions: {
        type: Array,
        default: () => []
    },
    // 编辑时传入的文章数据，新增时为 null
    article: {
        type: Object,
        default: null
    }
})

const emit = defineEmits(['update:modelValue', 'success'])

const formRef = ref()
const submitting = ref(false)

const dialogVisible = computed({
    get: () => props.modelValue,
    set: (val) => emit('update:modelValue', val)
})

// 表单初始值，用于重置
const getInitialFormData = () => ({
    title: '',
    content: '',
    coverImage: '',
    categoryId: 1,
    summary: '',
    tags: '',
    tagArray: [],
    id: ''
})

const formData = reactive(getInitialFormData())

const handleClose = () => {
    emit('update:modelValue', false)
}

// 提交文章：校验 → 标签数组转字符串 → 调接口 → 通知父组件刷新
const handleSubmit = async () => {
    if (!formRef.value) return
    try {
        await formRef.value.validate()
    } catch {
        return // 校验未通过，不提交
    }

    submitting.value = true
    try {
        // tagArray 多选数组按逗号拼接为 tags 字符串
        formData.tags = formData.tagArray.join(',')

        const isEdit = !!formData.id
        if (useMock) {
            if (isEdit) {
                // mock 模式编辑：基于原数据覆盖表单字段
                const index = mockArticles.findIndex(item => item.id === formData.id)
                if (index > -1) {
                    mockArticles[index] = { ...mockArticles[index], ...formData }
                }
            } else {
                // mock 模式新增：直接写入本地测试数据
                mockArticles.unshift({
                    ...formData,
                    id: Date.now(),
                    authorName: 'admin',
                    readCount: 0,
                    createTime: new Date().toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-'),
                    status: 0
                })
            }
        } else {
            isEdit ? await updateArticle(formData.id, formData) : await createArticle(formData)
        }

        ElMessage.success(isEdit ? '文章更新成功' : '文章发布成功')
        emit('success')
        handleClose()
    } catch (error) {
        console.error('文章提交失败：', error)
        ElMessage.error('文章提交失败，请重试')
    } finally {
        submitting.value = false
    }
}

// 弹窗打开时回填编辑数据，关闭后重置表单、封面
watch(dialogVisible, (visible) => {
    if (visible && props.article) {
        // 编辑模式：回填表单，tags 字符串拆成多选数组
        Object.assign(formData, getInitialFormData(), props.article, {
            tagArray: props.article.tags ? props.article.tags.split(',') : []
        })
        imgUrl.value = props.article.coverImage ? fileBaseUrl + props.article.coverImage : ''
    }
    if (!visible) {
        Object.assign(formData, getInitialFormData())
        imgUrl.value = ''
        formRef.value?.clearValidate()
    }
})

const rules = reactive({
    title: [
        { required: true, message: '请输入文章标题', trigger: 'blur' },
        { max: 100, message: '文章标题最多100个字符', trigger: 'blur' }
    ],
    categoryId: [
        { required: true, message: '请选择文章分类', trigger: 'change' }
    ],
    summary: [
        { required: true, message: '请输入文章摘要', trigger: 'blur' },
        { max: 500, message: '文章摘要最多500个字符', trigger: 'blur' }
    ],
    content: [
        {
            validator: (rule, value, callback) => {
                // 富文本空内容为 <p><br></p>，去掉标签后判断
                const text = (value || '').replace(/<[^>]+>/g, '').trim()
                if (!text) {
                    callback(new Error('请输入文章内容'))
                } else {
                    callback()
                }
            },
            trigger: 'blur'
        }
    ]
})

// 常用标签候选（可自定义输入，见模板里的 allow-create）
const commonTags = [
    '情绪管理','情感分析','情感识别','压力管理','放松','学习','生活'
]

// 封面预览地址（完整的 http 地址，用于 <img> 显示）
const imgUrl = ref('')

// 上传前校验：只允许 JPG/PNG，且不超过 5MB
const beforeAvatarUpload = (file) => {
    const isJPG = file.type === 'image/jpeg'
    const isPNG = file.type === 'image/png'
    const isLt5M = file.size / 1024 / 1024 < 5
    if (!isJPG && !isPNG) {
        ElMessage.error('上传图片只能是 JPG/PNG 格式!')
        return false
    }
    if (!isLt5M) {
        ElMessage.error('上传图片大小不能超过 5MB!')
        return false
    }
    return true
}

// 删除封面
const handleRemove = () => {
    imgUrl.value = ''
    formData.coverImage = ''
}

const uploading = ref(false)

/**
 * 自定义上传（覆盖 el-upload 默认行为）
 * 走自己的后端接口 POST /file/upload，成功后拿到 filePath 存进表单
 * businessId 这里用随机串，因为新增文章时还没有文章 id
 */
const handleUploadRequest = async ({ file }) => {
    // crypto.randomUUID 在部分非安全上下文环境不可用，做兜底
    const businessId = (crypto?.randomUUID?.()) || `${Date.now()}-${Math.random().toString(36).slice(2)}`
    console.log(businessId, 'businessId')

    uploading.value = true
    try {
        const fileRes = await uploadFile(file, { businessId, businessField: 'cover' })
        console.log(fileRes)

        // 后端返回相对路径 → 拼上 fileBaseUrl 才能显示；表单里存相对路径
        imgUrl.value = fileBaseUrl + fileRes.filePath
        formData.coverImage = fileRes.filePath
        ElMessage.success('封面上传成功')
    } catch (error) {
        console.error('封面上传失败：', error)
        ElMessage.error('封面上传失败，请重试')
    } finally {
        uploading.value = false
    }
}
</script>

<style scoped>
.avatar-uploader .cover-placeholder {
    width: 120px;
    height: 120px;
    border: 1px dashed #d9d9d9;
    border-radius: 6px;
    cursor: pointer;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: #8c939d;
}

.avatar-uploader .cover-placeholder:hover {
    border-color: #409eff;
}

.avatar-uploader-icon {
    font-size: 28px;
    margin-bottom: 8px;
}

.avatar {
    width: 120px;
    height: 120px;
    object-fit: cover;
    border-radius: 6px;
    display: block;
}
</style>
