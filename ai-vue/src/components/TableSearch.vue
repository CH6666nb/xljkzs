<!-- =============================================================================
     通用搜索栏组件
     用法：父组件传入 formItem 数组描述要渲染哪些搜索项，例如：
       [{ comp:'input',  prop:'title',    label:'标题' },
        { comp:'select', prop:'status',   label:'状态', options:[{label,value}, ...] }]
     用户点"查询"时，通过 @search 事件把表单值（一个对象）抛给父组件，
     父组件再拿这些值去调后端分页查询接口。
     ============================================================================= -->
<template>
    <el-form ref="ruleFormRef" :model="formData" :inline="true" class="demo-form-inline">
        <el-row>
            <el-form-item>
                <!-- 根据配置的 comp 字段动态渲染成 el-input 或 el-select -->
                <template v-for="item in formItemArray" :key="item.prop">
                    <el-col v-bind="item.col">
                        <component
                            :is="isComp(item.comp)"
                            v-model="formData[item.prop]"
                            :prop="item.prop"
                            :label="item.label"
                            :placeholder="item.placeholder">
                            <!-- 下拉框额外加一个"全部"选项（值为空字符串，表示不筛选） -->
                            <template v-if="item.comp === 'select'">
                                <el-option label="全部" value="" />
                                <el-option
                                v-for="opt in item.options"
                                :key="opt.value"
                                :label="opt.label"
                                :value="opt.value" />
                            </template>
                        </component>
                    </el-col>
                </template>
            </el-form-item>
        </el-row>

        <el-row>
            <el-button type="primary" @click="handleSearch(formData)">查询</el-button>
            <el-button type="primary" @click="handleReset(ruleFormRef)">重置</el-button>
        </el-row>
    </el-form>
</template>

<script setup>
import { ref, reactive, watch, computed } from 'vue'

const props = defineProps({
    // 搜索项配置数组，由父组件传入
    formItem: {
        type: Array,
        default: () => []
    }
})

// 向外抛事件：search 携带当前表单值
const emit = defineEmits(['search'])

const ruleFormRef = ref()

// 表单数据，键名 = 配置里的 prop
const formData = reactive({})

// 给每个搜索项加上响应式栅格宽度（大屏一行 4 个，小屏自动换行）
const formItemArray = computed(() => {
    return props.formItem.map(item => ({
        ...item,
        col: { xs: 24, sm: 12, md: 8, lg: 6, xl: 6 }
    }))
})

// 配置变化时，初始化每个搜索项的值为空字符串
watch(() => props.formItem, (items) => {
    items.forEach(item => {
        if (formData[item.prop] === undefined) {
            formData[item.prop] = ''
        }
    })
}, { immediate: true, deep: true })

// 组件名映射
const isComp = (comp) => {
    return {
        input: 'el-input',
        select: 'el-select'
    }[comp]
}

// 点"查询"：把表单值抛给父组件
const handleSearch = () => {
    console.log(formData)
    emit('search', formData)
}

// 点"重置"：清空所有搜索项并重新查询（注意条件是"全部"）
const handleReset = (fromEl) => {
    // 清空表单数据
    Object.keys(formData).forEach(key => {
        formData[key] = ''
    })
    // 重置表单校验状态
    if (fromEl) {
        fromEl.resetFields()
    }
    emit('search', formData)
}
</script>
