// =============================================================================
// 管理端接口（后台管理页面用）
//
// 本文件把接口文档里的地址封装成一个个函数，页面里只 import 函数来用，
// 不在页面里直接写 axios，方便以后接口地址变动时只改这一个文件。
//
// 返回值的处理已经在 utils/request.js 的响应拦截器里做过了：
//   只要后端返回 { code:200, data:xxx }，这里拿到的就是 xxx 本身。
//
// 你在后端写 Controller 时，按下面每个函数上方的注释对照着写映射路径即可。
// =============================================================================
import service from '@/utils/request'

// =============================================================================
// 一、用户（管理端登录/退出）
// =============================================================================

/**
 * 管理员/用户登录
 * 接口：POST /user/login
 * 请求体：{ username, password }
 * 返回：{ token, userInfo }（userInfo 里含 id/username/nickname/userType 等）
 * 说明：登录成功后前端会把 token 和用户信息存进 localStorage
 */
export function login(data) {
    return service.post('/user/login', data)
}

/**
 * 退出登录
 * 接口：POST /user/logout
 * 说明：需要携带 token；后端做的是把服务端保存的登录状态清掉
 */
export function logout() {
    return service.post('/user/logout')
}

// =============================================================================
// 二、知识文章（知识管理页用）
// =============================================================================

/**
 * 获取知识分类树
 * 接口：GET /knowledge/category/tree
 * 返回：树形数组，每个节点形如 { id, categoryName, parentId, children: [...] }
 * 说明：后台文章表单的分类下拉框、列表的筛选条件都用这个接口的数据
 */
export function categoryTree() {
    return service.get('/knowledge/category/tree')
}

/**
 * 分页查询文章
 * 接口：GET /knowledge/article/page
 * 查询参数（注意是 query，不是 body）：
 *   title      文章标题，模糊查询
 *   categoryId 分类 id
 *   status     状态：0 草稿 / 1 已发布 / 2 已下线
 *   authorName 作者名
 *   currentPage 第几页（从 1 开始）
 *   size       每页条数
 * 返回：{ records: [...], total: 总条数 }
 *       —— Element Plus 的表格分页组件要的就是这两个字段
 */
export function articlePage(params) {
    return service.get('/knowledge/article/page', { params })
}

/**
 * 获取文章详情
 * 接口：GET /knowledge/article/{id}
 * 说明：编辑文章时要先查详情回填表单；用户端文章详情页也用它
 */
export function getArticleDetail(id) {
    return service.get(`/knowledge/article/${id}`)
}

/**
 * 新增文章
 * 接口：POST /knowledge/article
 * 请求体：{ title, categoryId, authorName, summary, coverImage, content, status }
 */
export function createArticle(data) {
    return service.post('/knowledge/article', data)
}

/**
 * 更新文章
 * 接口：PUT /knowledge/article/{id}
 * 说明：路径里带 id，请求体里也带一份 id（后端两种取法都能拿到，更省事）
 */
export function updateArticle(id, data) {
    return service.put(`/knowledge/article/${id}`, { ...data, id })
}

/**
 * 删除文章
 * 接口：DELETE /knowledge/article/{id}
 */
export function deleteArticle(id) {
    return service.delete(`/knowledge/article/${id}`)
}

/**
 * 发布 / 下线文章（只改状态，不改内容）
 * 接口：PUT /knowledge/article/{id}/status
 * 请求体：{ status }，取值：1 发布、2 下线
 * 说明：列表页点"发布/下线"按钮调它。0 草稿是新建时保存的状态，不通过这个接口改
 */
export function updateArticleStatus(id, status) {
    return service.put(`/knowledge/article/${id}/status`, { status })
}

// =============================================================================
// 三、咨询会话（咨询管理页用，只读不写）
// =============================================================================

/**
 * 分页查询所有用户的咨询会话
 * 接口：GET /psychological-chat/sessions
 * 查询参数：currentPage 页码、size 每页条数、emotionTag 情绪标签（可选筛选）
 * 返回：{ records: [...], total }
 *       每条记录含 sessionId / userId / sessionTitle / emotionTag / status / messageCount / createTime
 */
export function sessionPage(params) {
    return service.get('/psychological-chat/sessions', { params })
}

/**
 * 查询某个会话的聊天记录
 * 接口：GET /psychological-chat/sessions/{sessionId}/messages
 * 返回：消息数组，每条形如 { id, role('user'|'assistant'), content, createTime }
 * 说明：管理端点"查看消息"弹窗时调用
 */
export function sessionMessages(sessionId) {
    return service.get(`/psychological-chat/sessions/${sessionId}/messages`)
}

// =============================================================================
// 四、情绪日记（情感管理页用）
// =============================================================================

/**
 * 分页查询所有用户的情绪日记
 * 接口：GET /emotion-diary/admin/page
 * 查询参数：current 页码、size 每页条数、
 *          userId 用户 id、minMoodScore/maxMoodScore 心情分范围、dominantEmotion 主要情绪
 * 返回：{ records: [...], total }
 *       每条记录含 id / userId / diaryDate / moodScore / dominantEmotion /
 *       emotionTriggers / diaryContent / sleepQuality / stressLevel / createTime
 * 注意：这个接口的页码参数名是 current，和上面几个接口不一样，写后端时别写混
 */
export function diaryPage(params) {
    return service.get('/emotion-diary/admin/page', { params })
}

/**
 * 删除情绪日记
 * 接口：DELETE /emotion-diary/admin/{id}
 */
export function deleteDiary(id) {
    return service.delete(`/emotion-diary/admin/${id}`)
}

// =============================================================================
// 五、数据分析（首页仪表盘用）
// =============================================================================

/**
 * 获取综合数据分析数据
 * 接口：GET /data-analytics/overview
 * 返回：统计卡片数字 + 图表数据，前端做了多字段名兼容，详见 dashboard.vue
 *       参考返回结构：
 *       {
 *         userCount, sessionCount, articleCount, diaryCount,
 *         emotionDistribution: [{ name, count }],
 *         sessionTrend: [{ date, count }]
 *       }
 * 提示：SQL 脚本 mental_health_ai.sql 末尾附了可以直接用的聚合 SQL
 */
export function analyticsOverview() {
    return service.get('/data-analytics/overview')
}

// =============================================================================
// 六、文件上传（文章封面上传用）
// =============================================================================

/**
 * 文件上传
 * 接口：POST /file/upload
 * 提交方式：multipart/form-data，表单字段：
 *   file          文件本身
 *   businessType  业务类型，这里固定传 ARTICLE
 *   businessId    业务 id（新增文章时还没有 id，可传临时值，后端返回文件地址即可）
 *   businessField 业务字段名，比如 cover
 * 返回：文件信息，通常含 { id, filePath / url }
 */
export function uploadFile(file, businessInfo) {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('businessType', 'ARTICLE')
    formData.append('businessId', businessInfo.businessId)
    formData.append('businessField', businessInfo.businessField)

    return service.post('/file/upload', formData,
        {
            headers: {
                // 上传文件必须用这种 Content-Type，axios 会自动带上 boundary
                'Content-Type': 'multipart/form-data'
            }
        }
    )
}
