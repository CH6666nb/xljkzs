// =============================================================================
// 知识管理模块的假数据（仅供 useMock = true 时使用）
// 开关统一放在 mock/index.js —— 现在已经是 false，即走真实后端，
// 所以本文件里的数据不会影响页面显示，保留是为了方便随时切回来看效果。
// =============================================================================
export { useMock } from './index'

// 文章分类（对应后端 categoryTree 接口结构）
export const mockCategories = [
    { id: 1, categoryName: '心理健康基础' },
    { id: 2, categoryName: '情绪管理' },
    { id: 3, categoryName: '压力缓解' },
    { id: 4, categoryName: '人际关系' },
    { id: 5, categoryName: '自我成长' }
]

// 文章列表（对应后端 articlePage 接口 records 结构）
export const mockArticles = [
    {
        id: 1,
        title: '认识情绪：情绪没有好坏之分',
        categoryId: 2,
        authorName: 'admin',
        readCount: 1286,
        createTime: '2026-09-10 09:30:00',
        status: 1,
        summary: '情绪本身并无正负之分，真正影响我们的是应对情绪的方式。本文带你重新认识愤怒、焦虑、悲伤等常见情绪。',
        tags: '情绪管理,情感分析',
        content: '<p>情绪是人类面对环境变化时的自然反应……</p>',
        coverImage: ''
    },
    {
        id: 2,
        title: '缓解焦虑的 5 个呼吸练习方法',
        categoryId: 3,
        authorName: 'admin',
        readCount: 2341,
        createTime: '2026-09-12 14:20:00',
        status: 1,
        summary: '当焦虑来袭时，有意识地调节呼吸可以快速安抚神经系统。本文介绍 5 种简单有效的呼吸练习。',
        tags: '压力管理,放松',
        content: '<p>深呼吸是最简单有效的放松方式之一……</p>',
        coverImage: ''
    },
    {
        id: 3,
        title: '什么是心理健康？一文读懂基础概念',
        categoryId: 1,
        authorName: '李老师',
        readCount: 876,
        createTime: '2026-09-15 10:05:00',
        status: 0,
        summary: '心理健康并不等于“没有心理疾病”，它是一种能够认识自我、应对压力、发挥潜能的良好状态。',
        tags: '情感识别,学习',
        content: '<p>世界卫生组织对心理健康的定义是……</p>',
        coverImage: ''
    },
    {
        id: 4,
        title: '如何建立健康的人际边界感',
        categoryId: 4,
        authorName: '王医生',
        readCount: 1502,
        createTime: '2026-09-18 16:45:00',
        status: 1,
        summary: '清晰的人际边界是健康关系的基础。学会拒绝、表达需求，既尊重他人也保护自己。',
        tags: '生活,放松',
        content: '<p>边界感不是冷漠，而是关系中的相互尊重……</p>',
        coverImage: ''
    },
    {
        id: 5,
        title: '自我接纳：停止内耗的第一步',
        categoryId: 5,
        authorName: 'admin',
        readCount: 3209,
        createTime: '2026-09-20 20:10:00',
        status: 2,
        summary: '很多精神内耗来源于对真实自我的不接纳。本文从心理学角度探讨如何与不完美的自己和解。',
        tags: '情感分析,学习,生活',
        content: '<p>自我接纳意味着承认并拥抱自己的全部……</p>',
        coverImage: ''
    },
    {
        id: 6,
        title: '职场压力大到失眠？试试这几招',
        categoryId: 3,
        authorName: '李老师',
        readCount: 654,
        createTime: '2026-09-22 08:50:00',
        status: 0,
        summary: '长期职场压力会影响睡眠与身体健康。通过时间管理、运动和认知调整，可以有效减轻压力反应。',
        tags: '压力管理',
        content: '<p>职场压力已成为现代人最主要的压力来源……</p>',
        coverImage: ''
    }
]
