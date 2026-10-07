<!-- =============================================================================
     AI 咨询对话页（用户端）
     页面结构：左边会话列表 + 右边对话区（气泡 + 输入框）
     对接接口（全部定义在 src/api/user.js）：
       GET    /psychological-chat/sessions                      查询"我的"会话列表
       GET    /psychological-chat/sessions/{sessionId}/messages 查询某会话的历史消息
       POST   /psychological-chat/session/start                 新建会话
       POST   /psychological-chat/stream                        流式对话（SSE，★重点）
       GET    /psychological-chat/session/{sessionId}/emotion   会话情绪分析
       DELETE /psychological-chat/sessions/{sessionId}          删除会话
     ============================================================================= -->
<template>
    <div class="chat-page">
        <!-- 左侧：会话列表 -->
        <aside class="session-panel">
            <div class="session-panel-head">
                <span>我的咨询会话</span>
                <el-button type="primary" size="small" @click="openCreateDialog">
                    <el-icon><Plus /></el-icon>
                    <span>新会话</span>
                </el-button>
            </div>
            <div class="session-list" v-loading="sessionLoading">
                <el-empty v-if="!sessionLoading && !sessions.length" description="暂无会话" :image-size="60" />
                <div
                    v-for="item in sessions"
                    :key="item.sessionId"
                    class="session-item"
                    :class="{ active: currentSessionId === item.sessionId }"
                    @click="handleSelectSession(item)"
                >
                    <div class="session-item-title">
                        <el-icon class="session-item-icon"><ChatDotRound /></el-icon>
                        <span class="session-name">{{ item.sessionTitle || item.sessionId }}</span>
                    </div>
                    <div class="session-item-meta">
                        <span>{{ item.createTime || '' }}</span>
                        <el-tag v-if="item.emotionTag" size="small" effect="plain">{{ item.emotionTag }}</el-tag>
                    </div>
                    <div class="session-item-actions" @click.stop>
                        <el-button
                            text
                            type="primary"
                            size="small"
                            title="情绪分析"
                            @click="handleEmotion(item)"
                        >
                            <el-icon><DataAnalysis /></el-icon>
                        </el-button>
                        <el-button
                            text
                            type="danger"
                            size="small"
                            title="删除会话"
                            @click="handleDeleteSession(item)"
                        >
                            <el-icon><Delete /></el-icon>
                        </el-button>
                    </div>
                </div>
            </div>
        </aside>

        <!-- 右侧：对话区 -->
        <section class="chat-panel">
            <template v-if="currentSessionId">
                <div class="chat-panel-head">
                    <span class="chat-title">{{ currentSession?.sessionTitle || currentSessionId }}</span>
                    <el-tag v-if="currentSession?.emotionTag" size="small" effect="plain">
                        {{ currentSession.emotionTag }}
                    </el-tag>
                </div>

                <div class="message-area" ref="messageAreaRef">
                    <div
                        v-for="(msg, index) in messages"
                        :key="index"
                        class="message-row"
                        :class="msg.role === 'user' ? 'row-user' : 'row-assistant'"
                    >
                        <el-avatar v-if="msg.role === 'user'" :size="32" class="avatar-user">我</el-avatar>
                        <div class="bubble" :class="msg.role === 'user' ? 'bubble-user' : 'bubble-assistant'">
                            <span class="bubble-content">{{ msg.content }}<span v-if="msg.streaming" class="cursor">▍</span></span>
                            <span v-if="msg.createTime && !msg.streaming" class="bubble-time">{{ msg.createTime }}</span>
                        </div>
                        <el-avatar v-if="msg.role !== 'user'" :size="32" class="avatar-ai">AI</el-avatar>
                    </div>
                </div>

                <!-- 输入区 -->
                <div class="input-area">
                    <el-input
                        v-model="inputText"
                        type="textarea"
                        :rows="3"
                        resize="none"
                        placeholder="写下你此刻的感受，AI 助手会陪着你……（Enter 发送，Shift+Enter 换行）"
                        :disabled="streaming"
                        @keydown.enter.exact.prevent="handleSend"
                    />
                    <div class="input-actions">
                        <el-button
                            type="primary"
                            :loading="streaming"
                            :disabled="!inputText.trim()"
                            @click="handleSend"
                        >
                            {{ streaming ? '回复中…' : '发送' }}
                        </el-button>
                    </div>
                </div>
            </template>

            <div v-else class="chat-empty">
                <el-empty description="选择一个会话开始对话，或点击左上角「新会话」">
                    <el-button type="primary" @click="openCreateDialog">创建新会话</el-button>
                </el-empty>
            </div>
        </section>

        <!-- 新建会话弹窗 -->
        <el-dialog v-model="createDialogVisible" title="开始新的咨询会话" width="520px">
            <el-form ref="createFormRef" :model="createForm" :rules="createRules" label-width="90px">
                <el-form-item label="会话标题" prop="sessionTitle">
                    <el-input v-model="createForm.sessionTitle" placeholder="给这次对话起个名字" maxlength="50" />
                </el-form-item>
                <el-form-item label="开场白" prop="initialMessage">
                    <el-input
                        v-model="createForm.initialMessage"
                        type="textarea"
                        :rows="4"
                        placeholder="说说你最近的心情，比如：最近工作压力有点大……"
                        maxlength="500"
                        show-word-limit
                    />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="createDialogVisible = false">取消</el-button>
                <el-button type="primary" :loading="creating" @click="handleCreateSession">开始对话</el-button>
            </template>
        </el-dialog>

        <!-- 情绪分析结果弹窗 -->
        <el-dialog v-model="emotionDialogVisible" title="会话情绪分析" width="560px">
            <div v-loading="emotionLoading">
                <template v-if="emotionResult">
                    <!-- 常见字段结构化展示 -->
                    <div class="emotion-cards">
                        <div class="emotion-card">
                            <p class="emotion-label">主要情绪</p>
                            <p class="emotion-value">{{ emotionResult.dominantEmotion || '-' }}</p>
                        </div>
                        <div class="emotion-card">
                            <p class="emotion-label">情绪评分</p>
                            <p class="emotion-value">{{ emotionResult.moodScore ?? '-' }}/10</p>
                        </div>
                        <div class="emotion-card">
                            <p class="emotion-label">积极占比</p>
                            <p class="emotion-value">{{ emotionResult.positiveRatio ?? '-' }}%</p>
                        </div>
                        <div class="emotion-card">
                            <p class="emotion-label">消极占比</p>
                            <p class="emotion-value">{{ emotionResult.negativeRatio ?? '-' }}%</p>
                        </div>
                    </div>
                    <p v-if="emotionResult.summary" class="emotion-summary">{{ emotionResult.summary }}</p>
                    <el-collapse class="emotion-raw">
                        <el-collapse-item title="查看完整原始数据">
                            <pre>{{ JSON.stringify(emotionResult, null, 2) }}</pre>
                        </el-collapse-item>
                    </el-collapse>
                </template>
                <el-empty v-else-if="!emotionLoading" description="暂无分析结果" :image-size="60" />
            </div>
        </el-dialog>
    </div>
</template>

<script setup>
import { nextTick, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { mySessions, sessionMessages, startSession, deleteSession, sessionEmotion, streamChat } from '@/api/user'
import { useMock, mockSessions, mockSessionMessages, mockEmotions, mockStreamReply } from '@/mock/index'

// ==================== 会话列表 ====================
const sessionLoading = ref(false)
const sessions = ref([])      // 左侧列表数据
const pagination = reactive({ pageNum: 1, pageSize: 20 })   // 本接口分页参数名：pageNum / pageSize

const currentSessionId = ref('')    // 当前选中的会话 id（控制右边是否显示对话区）
const currentSession = ref(null)    // 当前选中的会话对象

/**
 * 加载"我的"会话列表
 * 后端可返回数组，也可返回 { records: [...], total }，两种都兼容
 */
const loadSessions = async () => {
    sessionLoading.value = true
    try {
        if (useMock) {
            sessions.value = [...mockSessions].reverse()
            return
        }
        const data = await mySessions({ pageNum: pagination.pageNum, pageSize: pagination.pageSize })
        // 兼容 { records: [] } 与直接返回数组两种结构
        sessions.value = Array.isArray(data) ? data : (data?.records || [])
    } catch (error) {
        console.error('查询会话列表失败：', error)
    } finally {
        sessionLoading.value = false
    }
}

// 点击左侧某个会话 → 切换到它并加载历史消息
const handleSelectSession = async (item) => {
    currentSessionId.value = item.sessionId
    currentSession.value = item
    await loadMessages(item.sessionId)
}

// ==================== 消息 ====================
const messages = ref([])         // 当前会话的消息数组
const messageAreaRef = ref()     // 消息区域的 DOM 引用，用来滚到底部

/**
 * 加载某个会话的历史消息
 * 后端 role 字段可能是 'user'/'assistant' 或 'USER'/'ASSISTANT'，这里统一转成小写判断
 */
const loadMessages = async (sessionId) => {
    messages.value = []
    try {
        let list
        if (useMock) {
            list = mockSessionMessages[sessionId] || []
        } else {
            const data = await sessionMessages(sessionId)
            list = Array.isArray(data) ? data : (data?.records || [])
        }
        // 兼容 role: 'user'/'assistant' 或 'USER'/'ASSISTANT' 两种取值
        messages.value = list.map(m => ({
            role: String(m.role || '').toLowerCase() === 'user' ? 'user' : 'assistant',
            content: m.content,
            createTime: m.createTime || m.sendTime || ''
        }))
        scrollToBottom()
    } catch (error) {
        console.error('获取消息列表失败：', error)
    }
}

// 消息区域滚到最底部（新消息进来时调用）
const scrollToBottom = () => {
    nextTick(() => {
        const el = messageAreaRef.value
        if (el) el.scrollTop = el.scrollHeight
    })
}

// ==================== 发送消息（流式对话★） ====================
const inputText = ref('')
const streaming = ref(false)   // 是否正在接收 AI 回复（期间禁用输入框和发送按钮）

/**
 * 发送一条消息
 * 核心思路：
 *   1) 用户消息立刻上屏
 *   2) 先插入一个空的 AI 气泡并标记 streaming，
 *   3) 通过 onMessage 回调，每收到一小段文本就拼到气泡里（打字机效果）
 *   4) onDone / onError 时把 streaming 去掉，光标停止闪烁
 */
const handleSend = async () => {
    const text = inputText.value.trim()
    if (!text || streaming.value) return
    // 没有选中会话时，引导用户先创建
    if (!currentSessionId.value) {
        openCreateDialog(text)
        return
    }

    // 先把用户消息上屏
    messages.value.push({ role: 'user', content: text, createTime: '' })
    inputText.value = ''
    scrollToBottom()

    // 创建 AI 回复占位消息，流式分片逐步拼接
    const aiMessage = reactive({ role: 'assistant', content: '', createTime: '', streaming: true })
    messages.value.push(aiMessage)
    streaming.value = true
    scrollToBottom()

    // 每收到一个分片就追加到气泡内容里
    const appendChunk = (chunk) => {
        aiMessage.content += chunk
        scrollToBottom()
    }

    if (useMock) {
        // mock 模式：用本地模拟流式回复
        await mockStreamReply(text, appendChunk)
        finishAiMessage(aiMessage)
        return
    }

    // 真实接口：SSE 流式对话 POST /psychological-chat/stream
    // 具体实现见 api/user.js，用 fetch 逐块读取 text/event-stream
    await streamChat({
        sessionId: currentSessionId.value,
        userMessage: text,
        onMessage: appendChunk,
        onDone: () => finishAiMessage(aiMessage),
        onError: (error) => {
            console.error('流式对话失败：', error)
            if (!aiMessage.content) {
                aiMessage.content = '抱歉，回复出了点问题，请稍后重试。'
            }
            finishAiMessage(aiMessage)
        }
    })
}

// 结束一次 AI 回复：去掉光标、补上时间、解除输入禁用
const finishAiMessage = (aiMessage) => {
    aiMessage.streaming = false
    aiMessage.createTime = new Date().toLocaleString('zh-CN', { hour12: false })
    streaming.value = false
    // 消息数 +1（本地同步，下次刷新以后端为准）
    if (currentSession.value) {
        currentSession.value.messageCount = (currentSession.value.messageCount || 0) + 2
    }
}

// ==================== 创建会话 ====================
const createDialogVisible = ref(false)
const creating = ref(false)
const createFormRef = ref()

// 默认会话标题：带上当前时间，免得一堆会话重名分不清
const defaultTitle = () => `宁渡AI助手 - ${new Date().toLocaleString('zh-CN', { hour12: false })}`

const createForm = reactive({
    sessionTitle: '',
    initialMessage: ''
})

const createRules = {
    sessionTitle: [{ required: true, message: '请输入会话标题', trigger: 'blur' }],
    initialMessage: [{ required: true, message: '请输入开场白', trigger: 'blur' }]
}

// 打开新建会话弹窗；prefillMessage 用于用户直接输入内容但还没选会话的情况
const openCreateDialog = (prefillMessage) => {
    createForm.sessionTitle = defaultTitle()
    createForm.initialMessage = prefillMessage || ''
    createDialogVisible.value = true
}

/**
 * 提交新建会话
 * 接口：POST /psychological-chat/session/start
 * 请求体：{ sessionTitle, initialMessage }
 * 返回：新建的会话对象（必须含 sessionId，前端要拿它去加载消息）
 */
const handleCreateSession = async () => {
    try {
        await createFormRef.value.validate()
    } catch {
        return
    }
    creating.value = true
    try {
        let newSession
        if (useMock) {
            // mock 模式：本地生成一个会话对象
            newSession = {
                sessionId: `session_${Date.now()}`,
                sessionTitle: createForm.sessionTitle,
                initialMessage: createForm.initialMessage,
                status: 'ACTIVE',
                messageCount: 1,
                createTime: new Date().toLocaleString('zh-CN', { hour12: false })
            }
            mockSessions.unshift(newSession)
            mockSessionMessages[newSession.sessionId] = [
                { id: 1, role: 'user', content: createForm.initialMessage, createTime: newSession.createTime }
            ]
        } else {
            // 真实接口：POST /psychological-chat/session/start
            newSession = await startSession({
                sessionTitle: createForm.sessionTitle,
                initialMessage: createForm.initialMessage
            })
        }

        createDialogVisible.value = false
        await loadSessions()
        // 选中新建的会话并回显开场白
        currentSessionId.value = newSession.sessionId
        currentSession.value = sessions.value.find(s => s.sessionId === newSession.sessionId) || newSession
        await loadMessages(newSession.sessionId)
        // 开场白还没有 AI 回复，直接进入流式对话让 AI 响应
        inputText.value = ''
    } catch (error) {
        console.error('创建会话失败：', error)
    } finally {
        creating.value = false
    }
}

// ==================== 删除会话 ====================
// 接口：DELETE /psychological-chat/sessions/{sessionId}
// 后端删除会话时要连带删掉该会话下的所有消息（保证数据不残留）
const handleDeleteSession = async (item) => {
    try {
        await ElMessageBox.confirm(
            `确定删除会话「${item.sessionTitle || item.sessionId}」吗？删除后不可恢复。`,
            '删除确认',
            { type: 'warning', confirmButtonText: '确定删除', cancelButtonText: '取消' }
        )
    } catch {
        return
    }
    try {
        if (useMock) {
            const index = mockSessions.findIndex(s => s.sessionId === item.sessionId)
            if (index > -1) mockSessions.splice(index, 1)
            delete mockSessionMessages[item.sessionId]
        } else {
            await deleteSession(item.sessionId)
        }
        ElMessage.success('删除成功')
        // 删除的是当前打开的会话时，清空对话区
        if (currentSessionId.value === item.sessionId) {
            currentSessionId.value = ''
            currentSession.value = null
            messages.value = []
        }
        await loadSessions()
    } catch (error) {
        console.error('删除会话失败：', error)
        ElMessage.error('删除失败，请重试')
    }
}

// ==================== 情绪分析 ====================
// 接口：GET /psychological-chat/session/{sessionId}/emotion
// 返回字段参考：dominantEmotion / moodScore / positiveRatio / negativeRatio / neutralRatio / summary
const emotionDialogVisible = ref(false)
const emotionLoading = ref(false)
const emotionResult = ref(null)

const handleEmotion = async (item) => {
    emotionDialogVisible.value = true
    emotionLoading.value = true
    emotionResult.value = null
    try {
        if (useMock) {
            emotionResult.value = mockEmotions[item.sessionId] || null
            return
        }
        emotionResult.value = await sessionEmotion(item.sessionId)
    } catch (error) {
        console.error('获取情绪分析失败：', error)
        ElMessage.error('获取情绪分析失败')
    } finally {
        emotionLoading.value = false
    }
}

onMounted(() => {
    loadSessions()
})
</script>

<style lang="scss" scoped>
.chat-page {
    display: flex;
    gap: 16px;
    height: calc(100vh - 100px);
    min-height: 520px;
}

// 左侧会话列表
.session-panel {
    width: 300px;
    flex-shrink: 0;
    background-color: #fff;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    display: flex;
    flex-direction: column;
    overflow: hidden;

    .session-panel-head {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 14px 16px;
        font-size: 15px;
        font-weight: 600;
        color: #303133;
        border-bottom: 1px solid #f0f2f5;
    }

    .session-list {
        flex: 1;
        overflow-y: auto;
        padding: 8px;
    }

    .session-item {
        padding: 10px 12px;
        border-radius: 8px;
        cursor: pointer;
        margin-bottom: 4px;
        transition: background-color 0.2s;

        &:hover {
            background-color: #f5f7fa;
        }

        &.active {
            background-color: #ecf5ff;
        }

        .session-item-title {
            display: flex;
            align-items: center;
            gap: 6px;

            .session-item-icon {
                color: #409eff;
                flex-shrink: 0;
            }

            .session-name {
                font-size: 14px;
                color: #303133;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            }
        }

        .session-item-meta {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 6px;
            font-size: 12px;
            color: #909399;
        }

        .session-item-actions {
            display: flex;
            gap: 2px;
            margin-top: 4px;
            opacity: 0;
            transition: opacity 0.2s;
        }

        &:hover .session-item-actions {
            opacity: 1;
        }
    }
}

// 右侧对话区
.chat-panel {
    flex: 1;
    background-color: #fff;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    display: flex;
    flex-direction: column;
    overflow: hidden;

    .chat-panel-head {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 14px 20px;
        border-bottom: 1px solid #f0f2f5;

        .chat-title {
            font-size: 15px;
            font-weight: 600;
            color: #303133;
        }
    }

    .message-area {
        flex: 1;
        overflow-y: auto;
        padding: 20px;
        background-color: #fafbfc;
    }

    .message-row {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        margin-bottom: 18px;

        &.row-user {
            justify-content: flex-end;

            .bubble {
                background-color: #409eff;
                color: #fff;
                border-radius: 12px 2px 12px 12px;

                .bubble-time {
                    color: rgba(255, 255, 255, 0.7);
                }
            }
        }

        &.row-assistant {
            justify-content: flex-start;

            .bubble {
                background-color: #fff;
                color: #303133;
                border: 1px solid #e4e7ed;
                border-radius: 2px 12px 12px 12px;

                .bubble-time {
                    color: #c0c4cc;
                }
            }
        }
    }

    .avatar-user {
        background-color: #67c23a;
        color: #fff;
        font-size: 12px;
        flex-shrink: 0;
    }

    .avatar-ai {
        background-color: #409eff;
        color: #fff;
        font-size: 12px;
        flex-shrink: 0;
    }

    .bubble {
        max-width: 68%;
        padding: 10px 14px;

        .bubble-content {
            font-size: 14px;
            line-height: 1.7;
            white-space: pre-wrap;
            word-break: break-word;
        }

        .bubble-time {
            display: block;
            font-size: 11px;
            margin-top: 4px;
        }

        // 流式回复中的光标闪烁
        .cursor {
            animation: blink 1s infinite;
        }
    }

    .input-area {
        border-top: 1px solid #f0f2f5;
        padding: 14px 20px;

        .input-actions {
            display: flex;
            justify-content: flex-end;
            margin-top: 10px;
        }
    }

    .chat-empty {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
    }
}

@keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0; }
}

// 情绪分析弹窗
.emotion-cards {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;

    .emotion-card {
        background-color: #f5f7fa;
        border-radius: 8px;
        padding: 12px;
        text-align: center;

        .emotion-label {
            margin: 0 0 6px;
            font-size: 12px;
            color: #909399;
        }

        .emotion-value {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
            color: #303133;
        }
    }
}

.emotion-summary {
    margin: 16px 0 0;
    padding: 12px 14px;
    background-color: #ecf5ff;
    border-radius: 8px;
    font-size: 14px;
    color: #303133;
    line-height: 1.8;
}

.emotion-raw {
    margin-top: 12px;

    pre {
        margin: 0;
        font-size: 12px;
        color: #606266;
        white-space: pre-wrap;
        word-break: break-word;
    }
}
</style>
