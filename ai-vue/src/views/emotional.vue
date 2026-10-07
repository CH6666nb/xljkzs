<!-- =============================================================================
     情感管理页（管理端）
     对接接口：
       GET    /emotion-diary/admin/page  分页查询所有用户的情绪日记
       DELETE /emotion-diary/admin/{id}  删除某条日记
     页面展示用户每天的心情分（1-10）、主要情绪、睡眠质量、压力水平等
     ============================================================================= -->
<template>
    <div>
        <PageHead title="情感管理" />
        <TableSearch :formItem="formItem" @search="handleSearch" />
        <el-table :data="tableData" style="width: 100%; margin-top: 20px" v-loading="loading">
            <el-table-column prop="id" label="ID" width="70" fixed="left" />
            <el-table-column prop="userId" label="用户ID" width="90" />
            <el-table-column prop="diaryDate" label="记录日期" width="120" />
            <el-table-column prop="moodScore" label="情绪评分" width="180">
                <template #default="scope">
                    <el-rate
                        :model-value="Number(scope.row.moodScore) / 2"
                        disabled
                        allow-half
                        :max="5"
                    />
                    <span class="score-text">{{ scope.row.moodScore }}/10</span>
                </template>
            </el-table-column>
            <el-table-column prop="dominantEmotion" label="主要情绪" width="100">
                <template #default="scope">
                    <el-tag :type="emotionTagType(scope.row.dominantEmotion)">
                        {{ scope.row.dominantEmotion || '-' }}
                    </el-tag>
                </template>
            </el-table-column>
            <el-table-column prop="sleepQuality" label="睡眠质量" width="100">
                <template #default="scope">{{ scope.row.sleepQuality }}/10</template>
            </el-table-column>
            <el-table-column prop="stressLevel" label="压力水平" width="100">
                <template #default="scope">{{ scope.row.stressLevel }}/10</template>
            </el-table-column>
            <el-table-column prop="emotionTriggers" label="情绪触发因素" min-width="140" show-overflow-tooltip />
            <el-table-column prop="diaryContent" label="今日感想" min-width="180" show-overflow-tooltip />
            <el-table-column prop="createTime" label="创建时间" width="170" />
            <el-table-column label="操作" width="100" fixed="right">
                <template #default="scope">
                    <el-button text type="danger" @click="handleDelete(scope.row)">删除</el-button>
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
    </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import PageHead from '@/components/PageHead.vue'
import TableSearch from '@/components/TableSearch.vue'
import { diaryPage, deleteDiary } from '@/api/admin'
import { useMock, mockDiaries } from '@/mock/index'

// 搜索栏配置，字段名与后端查询参数一一对应
const formItem = [
    { comp: 'input', prop: 'userId', label: '用户ID', placeholder: '请输入用户ID' },
    { comp: 'input', prop: 'dominantEmotion', label: '主要情绪', placeholder: '如：焦虑 / 悲伤' },
    { comp: 'input', prop: 'minMoodScore', label: '情绪分下限', placeholder: '1-10' },
    { comp: 'input', prop: 'maxMoodScore', label: '情绪分上限', placeholder: '1-10' }
]

const loading = ref(false)
const tableData = ref([])

// 注意：情绪日记接口的分页参数名是 current（不是 currentPage），写后端时别搞混
const pagination = reactive({
    currentPage: 1,
    pageSize: 10,
    total: 0
})

/**
 * 查询情绪日记列表
 * @param formData 搜索栏的值
 * 后端需返回 { records: [...], total }
 * 每条记录字段：id / userId / diaryDate / moodScore / dominantEmotion /
 *              emotionTriggers / diaryContent / sleepQuality / stressLevel / createTime
 */
const handleSearch = async (formData) => {
    loading.value = true
    try {
        if (useMock) {
            // mock 模式：本地过滤 + 分页
            let list = [...mockDiaries]
            if (formData?.userId) {
                list = list.filter(item => String(item.userId) === String(formData.userId))
            }
            if (formData?.dominantEmotion) {
                list = list.filter(item => item.dominantEmotion?.includes(formData.dominantEmotion))
            }
            if (formData?.minMoodScore) {
                list = list.filter(item => Number(item.moodScore) >= Number(formData.minMoodScore))
            }
            if (formData?.maxMoodScore) {
                list = list.filter(item => Number(item.moodScore) <= Number(formData.maxMoodScore))
            }
            pagination.total = list.length
            const start = (pagination.currentPage - 1) * pagination.pageSize
            tableData.value = list.slice(start, start + pagination.pageSize)
            return
        }

        const params = {
            userId: formData?.userId || undefined,
            dominantEmotion: formData?.dominantEmotion || undefined,
            minMoodScore: formData?.minMoodScore || undefined,
            maxMoodScore: formData?.maxMoodScore || undefined,
            current: pagination.currentPage,
            size: pagination.pageSize
        }
        const { records, total } = await diaryPage(params)
        tableData.value = records || []
        pagination.total = total || 0
    } catch (error) {
        console.error('查询情绪日记失败：', error)
    } finally {
        loading.value = false
    }
}

const handleChange = (page) => {
    pagination.currentPage = page
    handleSearch({})
}

const emotionTagMap = {
    '焦虑': 'warning',
    '悲伤': 'primary',
    '愤怒': 'danger',
    '开心': 'success',
    '平静': 'info',
    '疲惫': 'warning'
}
const emotionTagType = (tag) => emotionTagMap[tag] || 'info'

const handleDelete = async (row) => {
    try {
        await ElMessageBox.confirm(
            `确定删除用户 ${row.userId} 在 ${row.diaryDate} 的情绪日记吗？删除后不可恢复。`,
            '删除确认',
            { type: 'warning', confirmButtonText: '确定删除', cancelButtonText: '取消' }
        )
    } catch {
        return // 用户取消
    }

    try {
        if (useMock) {
            const index = mockDiaries.findIndex(d => d.id === row.id)
            if (index > -1) mockDiaries.splice(index, 1)
        } else {
            await deleteDiary(row.id)
        }
        ElMessage.success('删除成功')
        // 删除的是当前页最后一条时，回退一页避免空页
        if (tableData.value.length === 1 && pagination.currentPage > 1) {
            pagination.currentPage--
        }
        handleSearch({})
    } catch (error) {
        console.error('删除情绪日记失败：', error)
        ElMessage.error('删除失败，请重试')
    }
}

onMounted(() => {
    handleSearch({})
})
</script>

<style scoped>
.score-text {
    margin-left: 8px;
    font-size: 12px;
    color: #909399;
}
</style>
