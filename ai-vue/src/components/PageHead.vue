<!-- =============================================================================
     页面标题栏通用组件
     用法：<PageHead title="知识管理">
             <template #buttons><el-button>新增</el-button></template>
           </PageHead>
     左边显示 title，右边插槽放操作按钮
     ============================================================================= -->
<template>
    <div class="page-head">
        <div class="page-title">
            {{ props.title }}
        </div>
        <div class="action-btn">
            <slot name="buttons"></slot>
        </div>
    </div>
</template>

<script setup>
const props = defineProps({
    title: {
        type: String,
        default: ''
    }
})
</script>

<style lang="scss" scoped>

.page-head{
    display: flex;
    align-items: center;
    justify-content: space-between;
    .page-title{
        font-size: 24px;
        color: black;
    }

}



</style>