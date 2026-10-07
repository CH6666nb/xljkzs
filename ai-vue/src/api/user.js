// =============================================================================
// 用户端接口（面向普通用户的页面：AI 咨询、情绪日记、知识文章阅读）
//
// 与管理端接口的区别：
//   管理端的会话/日记接口是"看所有人的数据"，这里是"看自己的数据"，
//   后端一般从请求头 token 里解析出当前用户 id，所以前端不用传 userId。
// =============================================================================
import service from '@/utils/request'

// =============================================================================
// 一、账号
// =============================================================================

/**
 * 用户注册
 * 接口：POST /user/add
 * 请求体：
 *   username        用户名（唯一，用于登录）
 *   email           邮箱（唯一）
 *   nickname        昵称
 *   phone           手机号
 *   password        密码
 *   confirmPassword 确认密码（后端校验两次是否一致）
 *   gender          性别：1 男 2 女
 *   userType        用户类型：不传默认 1（普通用户），管理端建管理员账号时传 2
 */
export function register(data) {
    return service.post('/user/add', data)
}

// =============================================================================
// 二、咨询会话
// =============================================================================

/**
 * 分页查询"我的"咨询会话列表
 * 接口：GET /psychological-chat/sessions
 * 查询参数：pageNum 页码、pageSize 每页条数
 * 返回：{ records: [...], total }（也可以直接返回数组，页面两种都兼容）
 * 注意：这里的分页参数名是 pageNum/pageSize，管理端那个同名接口用的是 currentPage/size，
 *       写后端时如果想让一个接口同时兼容，就在方法参数里多收几个别名
 */
export function mySessions(params) {
    return service.get('/psychological-chat/sessions', { params })
}

/**
 * 查询某个会话的聊天记录
 * 接口：GET /psychological-chat/sessions/{sessionId}/messages
 * 返回：消息数组 [{ id, role, content, createTime }]
 * 说明：点左边会话列表切换时，用它把历史消息加载到聊天区
 */
export function sessionMessages(sessionId) {
    return service.get(`/psychological-chat/sessions/${sessionId}/messages`)
}

/**
 * 创建新会话（同时可以带上第一条消息）
 * 接口：POST /psychological-chat/session/start
 * 请求体：{ initialMessage 第一句话, sessionTitle 会话标题 }
 * 返回：新建的会话对象，含 sessionId
 * 注意：接口文档要求 createTime 返回毫秒时间戳，数据库存的是 DATETIME，后端记得转换
 */
export function startSession(data) {
    return service.post('/psychological-chat/session/start', data)
}

/**
 * 删除会话
 * 接口：DELETE /psychological-chat/sessions/{sessionId}
 * 说明：后端删除会话时要一并删掉该会话下的消息（数据库里配了级联删除）
 */
export function deleteSession(sessionId) {
    return service.delete(`/psychological-chat/sessions/${sessionId}`)
}

/**
 * 获取会话的情绪分析结果
 * 接口：GET /psychological-chat/session/{sessionId}/emotion
 * 返回：{ dominantEmotion 主要情绪, moodScore 心情分, positiveRatio 积极占比,
 *        negativeRatio 消极占比, neutralRatio 中性占比, summary 分析总结 }
 * 说明：用户端点"情绪分析"按钮时调用，用弹窗展示比例条
 */
export function sessionEmotion(sessionId) {
    return service.get(`/psychological-chat/session/${sessionId}/emotion`)
}

// =============================================================================
// 三、情绪日记
// =============================================================================

/**
 * 保存情绪日记（新增或更新二合一）
 * 接口：POST /emotion-diary
 * 请求体：
 *   diaryDate       日记日期（yyyy-MM-dd）
 *   moodScore       心情分 1-10
 *   dominantEmotion 主要情绪
 *   emotionTriggers 情绪诱因
 *   diaryContent    日记正文
 *   sleepQuality    睡眠质量
 *   stressLevel     压力水平
 * 说明：数据库里 emotion_diary 表对 (user_id, diary_date) 建了唯一索引，
 *       所以后端实现"同一天只能有一条"，重复提交用"先查后改"或 ON DUPLICATE KEY UPDATE
 */
export function saveDiary(data) {
    return service.post('/emotion-diary', data)
}

// =============================================================================
// 四、知识文章（只读）
// =============================================================================

/**
 * 分页查询文章列表（用户端"推荐阅读"）
 * 接口：GET /knowledge/article/page
 * 查询参数：sortField 排序字段（推荐用 readCount 按阅读量）、sortDirection 排序方向（desc）、
 *          currentPage 页码、size 每页条数
 * 返回：{ records: [...], total }
 * 说明：用户端只展示已发布的文章，后端记得过滤 status = 1
 */
export function articlePage(params) {
    return service.get('/knowledge/article/page', { params })
}

/**
 * 获取文章详情
 * 接口：GET /knowledge/article/{id}
 * 说明：打开文章详情页时调用，后端一般会顺便把阅读量 +1
 */
export function articleDetail(id) {
    return service.get(`/knowledge/article/${id}`)
}

// =============================================================================
// 五、AI 流式对话（SSE）★ 整个项目里最需要后端配合的接口
// =============================================================================

/**
 * 流式对话
 * 接口：POST /psychological-chat/stream
 * 请求体：{ sessionId, userMessage }
 * 返回：不是普通 JSON，而是 text/event-stream（SSE 流式响应）
 *
 * 为什么不能用 axios：axios 要等响应全部结束才把数据给你，
 * 打字机效果就没了。所以这里用浏览器原生 fetch 拿到可读流，边收边往页面拼。
 *
 * 后端返回的格式要求（两种都支持，前端已做兼容）：
 *   data: 你好            ← 纯文本分片
 *   data: {"content":"你好"}  ← JSON 分片
 *   每条消息之间用一个空行分隔；最后可以发一个 data: [DONE] 表示结束
 *
 * 对后端的技术提示：
 *   - Spring Boot 用 SseEmitter 或 WebFlux 的 Flux<ServerSentEvent> 都能实现
 *   - 需要设置响应头 Content-Type: text/event-stream，并关闭响应缓冲，否则会攒着一起发
 *
 * @param {string}   sessionId   会话 id
 * @param {string}   userMessage 用户这轮说的话
 * @param {Function} onMessage   每收到一个分片回调一次，参数是文本片段
 * @param {Function} onDone      流正常结束时回调
 * @param {Function} onError     出错时回调，参数是 Error 对象
 */
export async function streamChat({ sessionId, userMessage, onMessage, onDone, onError }) {
    const token = localStorage.getItem('token')
    try {
        // 注意：这里手写 /api 前缀，因为没走 axios 实例，拿不到 baseURL 配置
        const response = await fetch('/api/psychological-chat/stream', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'text/event-stream',
                'token': token || ''
            },
            body: JSON.stringify({ sessionId, userMessage })
        })

        // 后端返回非 2xx 或者没有响应体，直接当错误处理
        if (!response.ok || !response.body) {
            throw new Error(`流式请求失败，状态码：${response.status}`)
        }

        // 拿到流的读取器，逐块读取
        const reader = response.body.getReader()
        const decoder = new TextDecoder('utf-8')
        let buffer = ''

        while (true) {
            const { done, value } = await reader.read()
            if (done) break

            // 把二进制块解码成字符串。有个坑：一个中文字符可能被切成两个块，
            // 用 { stream: true } 可以让解码器把不完整的字节先留在内部，等下一块拼上
            buffer += decoder.decode(value, { stream: true })

            // SSE 规定每条消息以空行（\n\n）分隔，所以按空行切
            const events = buffer.split('\n\n')
            // 最后一段可能不完整（还没收到空行），留在 buffer 里等下次拼接
            buffer = events.pop() || ''

            events.forEach(event => {
                event.split('\n').forEach(line => {
                    if (!line.startsWith('data:')) return      // 只关心 data 行，忽略注释行/event 行
                    const payload = line.slice(5).trim()       // 去掉开头的 "data:"
                    if (!payload || payload === '[DONE]') return   // 结束标记，跳过
                    onMessage && onMessage(parseStreamPayload(payload))
                })
            })
        }
        onDone && onDone()
    } catch (error) {
        onError && onError(error)
    }
}

/**
 * 解析 SSE 每一条 data 的内容
 * 后端可能推纯文本，也可能推 JSON（{"content":"xx"}），这里统一成字符串返回，
 * 页面拿到什么都能直接往气泡里拼。
 */
function parseStreamPayload(payload) {
    try {
        const obj = JSON.parse(payload)
        if (typeof obj === 'string') return obj
        if (typeof obj?.content === 'string') return obj.content
        if (typeof obj?.data === 'string') return obj.data
        return payload
    } catch {
        // 不是合法 JSON，就当作纯文本（这是最常见的情况）
        return payload
    }
}
