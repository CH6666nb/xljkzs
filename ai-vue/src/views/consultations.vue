<!-- =============================================================================
     咨询管理页（管理端）
     对接接口：
       GET /psychological-chat/sessions                     分页查询所有用户的咨询会话
       GET /psychological-chat/sessions/{sessionId}/messages 查询某会话的聊天记录
     只读页面：管理员可以查看用户和 AI 的对话过程，不能修改
     ============================================================================= -->
<template>
    <div>
        <PageHead title="咨询管理" />
        <TableSearch :formItem="formItem" @search="handleSearch" />
        <el-table :data="tableData" style="width: 100%; margin-top: 20px" v-loading="loading">
            <el-table-column prop="sessionId" label="会话ID" width="150" fixed="left" />
            <el-table-column prop="userId" label="用户ID" width="100" />
            <el-table-column prop="sessionTitle" label="会话标题" min-width="180" show-overflow-tooltip />
            <el-table-column prop="emotionTag" label="情绪标签" width="110">
                <template #default="scope">
                    <el-tag v-if="scope.row.emotionTag" :type="emotionTagType(scope.row.emotionTag)">
                        {{ scope.row.emotionTag }}
                    </el-tag>
                    <span v-else>-</span>
                </template>
            </el-table-column>
            <el-table-column prop="messageCount" label="消息数" width="90" />
            <el-table-column prop="status" label="状态" width="100">
                <template #default="scope">
                    <el-tag :type="scope.row.status === 'ACTIVE' ? 'success' : 'info'" effect="plain">
                        {{ statusText(scope.row.status) }}
                    </el-tag>
                </template>
            </el-table-column>
            <el-table-column prop="createTime" label="开始时间" width="170" />
            <el-table-column label="操作" width="120" fixed="right">
                <template #default="scope">
                    <el-button text type="primary" @click="handleViewMessages(scope.row)">查看消息</el-button>
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

        <!-- 会话消息记录 -->
        <el-dialog
            v-model="messageDialogVisible"
            :title="`消息记录 - ${currentSession?.sessionTitle || currentSession?.sessionId || ''}`"
            width="640px"
        >
            <div v-loading="messageLoading" class="message-list">
                <el-empty v-if="!messageLoading && !messages.length" description="暂无消息" />
                <div
                    v-for="msg in messages"
                    :key="msg.id ?? msg.createTime"
                    class="message-item"
                    :class="msg.role === 'user' ? 'message-user' : 'message-assistant'"
                >
                    <el-tag :type="msg.role === 'user' ? 'primary' : 'success'" size="small" effect="plain">
                        {{ msg.role === 'user' ? '用户' : 'AI助手' }}
                    </el-tag>
                    <div class="message-content">{{ msg.content }}</div>
                    <span class="message-time">{{ msg.createTime }}</span>
                </div>
            </div>
        </el-dialog>
    </div>
</template>

<script setup>
// 详见文件顶部注释：本页是只读的会话监控页
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import PageHead from '@/components/PageHead.vue'
import TableSearch from '@/components/TableSearch.vue'
import { sessionPage, sessionMessages } from '@/api/admin'
import { useMock, mockSessions, mockSessionMessages } from '@/mock/index'

const formItem = [
    // 接口文档要求 emotionTag 为必传参数
    { comp: 'input', prop: 'emotionTag', label: '情绪标签', placeholder: '如：焦虑 / 悲伤 / 愤怒' }
]

const loading = ref(false)
const tableData = ref([])

// 本接口分页参数名：currentPage / size
const pagination = reactive({
    currentPage: 1,
    pageSize: 10,
    total: 0
})

/**
 * 查询会话列表
 * @param formData 搜索栏的值，本页只有 emotionTag
 * 后端需返回 { records: [...], total }
 * 每条记录字段：sessionId / userId / sessionTitle / emotionTag / status / messageCount / createTime
 * status 取值：ACTIVE 进行中、CLOSED 已结束
 */
const handleSearch = async (formData) => {
    loading.value = true
    try {
        if (useMock) {
            // mock 模式：本地过滤 + 分页
            let list = [...mockSessions]
            if (formData?.emotionTag) {
                list = list.filter(item => item.emotionTag?.includes(formData.emotionTag))
            }
            pagination.total = list.length
            const start = (pagination.currentPage - 1) * pagination.pageSize
            tableData.value = list.slice(start, start + pagination.pageSize)
            return
        }

        // 真实接口：分页参数为 currentPage / size
        const params = {
            emotionTag: formData?.emotionTag || '',
            currentPage: pagination.currentPage,
            size: pagination.pageSize
        }
        const { records, total } = await sessionPage(params)
        tableData.value = records || []
        pagination.total = total || 0
    } catch (error) {
        console.error('查询咨询会话失败：', error)
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
    '平静': 'info'
}
const emotionTagType = (tag) => emotionTagMap[tag] || 'info'
const statusText = (status) => (status === 'ACTIVE' ? '进行中' : status === 'CLOSED' ? '已结束' : status || '-')

// ==================== 查看消息 ====================
const messageDialogVisible = ref(false)
const messageLoading = ref(false)
const messages = ref([])
const currentSession = ref(null)

const handleViewMessages = async (row) => {
    currentSession.value = row
    messageDialogVisible.value = true
    messageLoading.value = true
    messages.value = []
    try {
        if (useMock) {
            // mock 模式：直接取本地消息数据
            messages.value = mockSessionMessages[row.sessionId] || []
            return
        }
        const data = await sessionMessages(row.sessionId)
        // 兼容直接返回数组或 { records: [] } 两种结构
        messages.value = Array.isArray(data) ? data : (data?.records || [])
    } catch (error) {
        console.error('获取会话消息失败：', error)
        ElMessage.error('获取会话消息失败')
    } finally {
        messageLoading.value = false
    }
}

onMounted(() => {
    handleSearch({})
})
</script>

<style lang="scss" scoped>
.message-list {
    max-height: 480px;
    overflow-y: auto;

    .message-item {
        margin-bottom: 16px;

        .message-content {
            margin: 6px 0 4px;
            padding: 10px 12px;
            border-radius: 8px;
            background-color: #f5f7fa;
            font-size: 14px;
            color: #303133;
            line-height: 1.7;
            white-space: pre-wrap;
            word-break: break-word;
        }

        .message-time {
            font-size: 12px;
            color: #c0c4cc;
        }
    }

    .message-user .message-content {
        background-color: #ecf5ff;
    }
}
</style>
