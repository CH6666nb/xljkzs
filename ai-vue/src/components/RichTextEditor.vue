<!-- =============================================================================
     富文本编辑器（基于 wangEditor）
     用途：管理端编辑文章正文，产出 HTML 字符串存进数据库 knowledge_article.content，
          用户端文章详情页用 v-html 渲染同一个 HTML
     用法：<RichTextEditor v-model="formData.content" />
     ============================================================================= -->
<template>
    <div class="rich-text-editor" :style="{ border: '1px solid #d9d9d9', borderRadius: '4px', zIndex: 100 }">
        <!-- 工具栏 -->
        <Toolbar
            :editor="editorRef"
            :defaultConfig="toolbarConfig"
            :mode="mode"
            style="border-bottom: 1px solid #d9d9d9"
        />
        <!-- 编辑区域 -->
        <Editor
            v-model="valueHtml"
            :defaultConfig="editorConfig"
            :mode="mode"
            @onCreated="handleCreated"
            @onChange="handleChange"
            style="height: 400px; overflow-y: hidden"
        />
    </div>
</template>

<script setup>
import '@wangeditor/editor/dist/css/style.css'
import { onBeforeUnmount, ref, shallowRef, watch } from 'vue'
import { Editor, Toolbar } from '@wangeditor/editor-for-vue'

const props = defineProps({
    modelValue: {
        type: String,
        default: ''
    },
    mode: {
        type: String,
        default: 'default' // 可选 'simple' 简洁模式
    },
    placeholder: {
        type: String,
        default: '请输入文章内容...'
    },
    readOnly: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits(['update:modelValue'])

// 编辑器实例必须用 shallowRef，深度响应式会导致编辑器异常
const editorRef = shallowRef()

// 编辑器内容 HTML
const valueHtml = ref(props.modelValue)

// 监听外部传入的值变化（如编辑文章时回显）
watch(() => props.modelValue, (val) => {
    if (val !== valueHtml.value) {
        valueHtml.value = val
    }
})

const toolbarConfig = {
    // 排除不需要的菜单，可按需调整
    excludeKeys: []
}

const editorConfig = {
    placeholder: props.placeholder,
    readOnly: props.readOnly
}

const handleCreated = (editor) => {
    editorRef.value = editor
}

// 内容变化时通知父组件
const handleChange = (editor) => {
    emit('update:modelValue', editor.getHtml())
}

// 组件销毁时，及时销毁编辑器，避免内存泄漏
onBeforeUnmount(() => {
    const editor = editorRef.value
    if (editor) {
        editor.destroy()
    }
})
</script>
