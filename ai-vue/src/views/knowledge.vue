<!-- =============================================================================
     知识管理页（管理端）
     对接接口：
       GET    /knowledge/category/tree          查询分类树 → 表格"文章分类"列 + 搜索下拉
       GET    /knowledge/article/page           分页查询文章列表
       PUT    /knowledge/article/{id}/status    发布 / 下线
       DELETE /knowledge/article/{id}           删除文章
     （新增、编辑走子组件 ArticleDialog.vue）
     ============================================================================= -->
<template>
    <div>
        <PageHead title="知识管理">
            <template  #buttons>
                <el-button @click="handleAdd" type="primary" size="small">
                    新增
                </el-button>
            </template>
        </PageHead>
        <!-- 搜索栏：表单项由 script 里的 formItem 配置生成 -->
        <TableSearch :formItem="formItem" @search="handleSearch"/>
        <el-table :data="tableData" style="width: 100%; margin-top: 20px">
            <el-table-column prop="title" label="文章标题" width="200" fixed="left">
                <template #default="scope">
                    <span>{{ scope.row.title }}</span>
                </template>
            </el-table-column>
            <!-- 后端存的是 categoryId，这里通过 categoryMap 翻译成分类名显示 -->
            <el-table-column prop="categoryId" label="文章分类" width="150" >
                <template #default="scope">
                    {{categoryMap[scope.row.categoryId]}}
                </template>
            </el-table-column>
            <el-table-column prop="authorName" label="作者" width="150" />
            <el-table-column prop="readCount" label="阅读量" width="150" />
            <el-table-column prop="createTime" label="创建时间" width="150" />
            <el-table-column label="操作" width="240" fixed="right">
                <template #default="scope">
                    <el-button text type="primary" @click="handleEdit(scope.row)">编辑</el-button>
                    <!-- 状态口径：0 草稿 / 1 已发布 / 2 已下线 -->
                    <el-button v-if="scope.row.status === 0 || scope.row.status === 2" type="success" @click="handleToggleStatus(scope.row)">发布</el-button>
                    <el-button v-if="scope.row.status === 1" type="warning" @click="handleToggleStatus(scope.row)">下线</el-button>
                    <el-button text type="danger" size="small" @click="handleDelete(scope.row)">删除</el-button>
                </template>
            </el-table-column>


        </el-table>

        <el-pagination
            style="margin-top: 20px;"
            layout="total, sizes, prev, pager, next, jumper"
            v-model:current-page="pagination.currentPage"
            v-model:page-size="pagination.pageSize"
            :total="pagination.total"
            @change="handleChange"
        />
        <!-- 新增 / 编辑文章弹窗：currentArticle 为 null 时是新增，否则是编辑 -->
        <ArticleDialog v-model="dialogVisible" :categoryOptions="categoryOptions" :article="currentArticle" @success="handleDialogSuccess" />
    </div>
</template>

<script setup>
import { onMounted, reactive, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import PageHead from '@/components/PageHead.vue'
import TableSearch from '@/components/TableSearch.vue'
import { categoryTree, articlePage, deleteArticle, updateArticleStatus } from '@/api/admin'
import ArticleDialog from '@/components/ArticleDialog.vue'
import { useMock, mockCategories, mockArticles } from '@/mock/knowledge'

// 搜索栏配置（TableSearch 组件按这个数组渲染表单）
// 注意 categoryId 的 options 在 onMounted 里查完分类树后才填进去（因为要动态获取）
const formItem = [
    {comp:'input',prop:'title',label:'文章标题',placeholder:'请输入文章标题'},
    {comp:'select',prop:'categoryId',label:'文章分类',placeholder:'请选择文章分类',options:[

]},
{comp:'select',prop:'status',label:'状态',placeholder:'请选择状态',options:[
    {label:'草稿',value:0},
    {label:'已发布',value:1},
    {label:'已下线',value:2},
]}

]

//分页参数
const pagination = reactive({
    currentPage:1,
    pageSize:10,
    total:0,
})

/**
 * 查询文章列表（搜索、切页、增删改后都调它刷新）
 * @param formData 搜索栏的表单值，如 { title, categoryId, status }
 */
const handleSearch = async (formData) => {
    console.log(formData,'查询参数')

    // mock 模式：本地过滤 + 分页
    if (useMock) {
        let list = [...mockArticles]
        if (formData?.title) {
            list = list.filter(item => item.title.includes(formData.title))
        }
        if (formData?.categoryId) {
            list = list.filter(item => item.categoryId === Number(formData.categoryId))
        }
        if (formData?.status !== undefined && formData?.status !== '' && formData?.status !== null) {
            list = list.filter(item => item.status === Number(formData.status))
        }
        pagination.total = list.length
        const start = (pagination.currentPage - 1) * pagination.pageSize
        tableData.value = list.slice(start, start + pagination.pageSize)
        return
    }

    // 接口文档口径：本接口分页参数为 currentPage / size
    // 后端需要返回 { records: 当前页数据数组, total: 总条数 }
    const params = {
        ...formData,
        currentPage: pagination.currentPage,
        size: pagination.pageSize,
    }

    const {records, total} = await articlePage(params)

    tableData.value = records
    pagination.total = total
}

// 新增/编辑文章成功后的回调，重新拉一次列表让数据最新
const handleDialogSuccess = () => {
    handleSearch({})
}

//分页参数变化（切页 / 改每页条数）
const handleChange = (page) => {
    pagination.currentPage = page
    handleSearch({})
}



// id → 分类名 的映射表，用于表格里显示分类名称
const categoryMap = reactive({})

// 分类下拉选项 [{ label, value }]
const categoryOptions = ref([])

// 表格数据
const tableData = ref([])

// 弹窗显示控制
const dialogVisible = ref(false)

// 当前编辑的文章，null 表示新增模式
const currentArticle = ref(null)

// 点"新增"
const handleAdd = () => {
    currentArticle.value = null
    dialogVisible.value = true
}

// 点"编辑"，把行数据传给弹窗做回填
const handleEdit = (row) => {
    currentArticle.value = row
    dialogVisible.value = true
}

// 发布/下线：已发布(1)→下线(2)，草稿(0)/已下线(2)→发布(1)
const handleToggleStatus = async (row) => {
    const isOfflineAction = row.status === 1
    const targetStatus = isOfflineAction ? 2 : 1
    const actionText = isOfflineAction ? '下线' : '发布'
    try {
        await ElMessageBox.confirm(
            `确定${actionText}文章「${row.title}」吗？`,
            '提示',
            { type: 'warning', confirmButtonText: '确定', cancelButtonText: '取消' }
        )
    } catch {
        return // 用户取消
    }

    try {
        if (useMock) {
            const item = mockArticles.find(a => a.id === row.id)
            if (item) item.status = targetStatus
        } else {
            // 真实接口：PUT /knowledge/article/{id}/status
            await updateArticleStatus(row.id, targetStatus)
        }
        ElMessage.success(`${actionText}成功`)
        handleSearch({})
    } catch (error) {
        console.error(`${actionText}失败：`, error)
        ElMessage.error(`${actionText}失败，请重试`)
    }
}

// 删除文章（带二次确认）
const handleDelete = async (row) => {
    try {
        await ElMessageBox.confirm(
            `确定删除文章「${row.title}」吗？删除后不可恢复。`,
            '删除确认',
            { type: 'warning', confirmButtonText: '确定删除', cancelButtonText: '取消' }
        )
    } catch {
        return // 用户取消
    }

    try {
        if (useMock) {
            const index = mockArticles.findIndex(a => a.id === row.id)
            if (index > -1) mockArticles.splice(index, 1)
        } else {
            // 真实接口：DELETE /knowledge/article/{id}
            await deleteArticle(row.id)
        }
        ElMessage.success('删除成功')
        // 删除的是当前页最后一条时，回退一页避免空页
        if (tableData.value.length === 1 && pagination.currentPage > 1) {
            pagination.currentPage--
        }
        handleSearch({})
    } catch (error) {
        console.error('删除失败：', error)
        ElMessage.error('删除失败，请重试')
    }
}

// 弹窗关闭后清空编辑对象，保证下次点“新增”不会带着旧数据
watch(dialogVisible, (visible) => {
    if (!visible) currentArticle.value = null
})

// 页面加载：先拉分类树填充下拉框，再拉文章列表
onMounted(async () => {
    try {
        // mock 模式：使用本地分类数据
        const data = useMock ? mockCategories : await categoryTree()

        // 分类数据同时用于：① 表格里 id→名称 的翻译（categoryMap）② 搜索下拉的选项
        categoryOptions.value = data.map(item => {
            categoryMap[item.id] = item.categoryName
            return {
                label:item.categoryName,
                value:item.id
            }
        })
        formItem[1].options = categoryOptions.value

        //获取列表
        handleSearch({})
    } catch (error) {
        console.error('获取分类数据失败：', error)
    }
})
</script>
