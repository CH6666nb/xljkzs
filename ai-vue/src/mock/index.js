// =============================================================================
// 全局 mock 开关
//   true  → 页面使用本文件（以及 knowledge.js）里的假数据，不需要后端也能点通
//   false → 全部走真实后端接口（需要你先把后端写起来）
// 注意：全项目只有这一个开关，knowledge.js 的 useMock 也是从这里转出去的
// 当前状态：已关闭 mock，连接你的本地后端
// =============================================================================
export const useMock = false

// ==================== 咨询会话 mock（管理端 + 用户端共用） ====================

export const mockSessions = [
    {
        sessionId: 'session_1001',
        userId: 11,
        sessionTitle: '最近工作压力有点大',
        emotionTag: '焦虑',
        status: 'ACTIVE',
        messageCount: 4,
        createTime: '2026-09-20 10:12:00'
    },
    {
        sessionId: 'session_1002',
        userId: 12,
        sessionTitle: '和好朋友闹矛盾了',
        emotionTag: '悲伤',
        status: 'ACTIVE',
        messageCount: 6,
        createTime: '2026-09-21 15:40:00'
    },
    {
        sessionId: 'session_1003',
        userId: 11,
        sessionTitle: '考前失眠怎么办',
        emotionTag: '焦虑',
        status: 'CLOSED',
        messageCount: 8,
        createTime: '2026-09-22 21:05:00'
    },
    {
        sessionId: 'session_1004',
        userId: 13,
        sessionTitle: '总是控制不住发脾气',
        emotionTag: '愤怒',
        status: 'ACTIVE',
        messageCount: 3,
        createTime: '2026-09-23 09:30:00'
    },
    {
        sessionId: 'session_1005',
        userId: 12,
        sessionTitle: '今天心情不错，记录一下',
        emotionTag: '开心',
        status: 'ACTIVE',
        messageCount: 2,
        createTime: '2026-09-23 18:20:00'
    }
]

// 各会话的消息记录（对应 sessionMessages 接口返回结构）
export const mockSessionMessages = {
    session_1001: [
        { id: 1, role: 'user', content: '最近工作压力好大，晚上总睡不着。', createTime: '2026-09-20 10:12:30' },
        { id: 2, role: 'assistant', content: '听到你说晚上睡不好，我很关心你。工作压力是从什么时候开始变大的呢？', createTime: '2026-09-20 10:12:40' },
        { id: 3, role: 'user', content: '大概一个月前，项目上线之后就一直加班。', createTime: '2026-09-20 10:13:20' },
        { id: 4, role: 'assistant', content: '持续加班一个月确实很消耗人。可以先从睡前的放松练习开始，比如 4-7-8 呼吸法，要不要我带你试一试？', createTime: '2026-09-20 10:13:35' }
    ],
    session_1002: [
        { id: 1, role: 'user', content: '和最好的朋友吵架了，心里很难受。', createTime: '2026-09-21 15:40:10' },
        { id: 2, role: 'assistant', content: '和亲近的人产生矛盾，往往最让人难过。愿意和我说说因为什么吵起来了吗？', createTime: '2026-09-21 15:40:22' }
    ],
    session_1003: [
        { id: 1, role: 'user', content: '马上要考试了，一躺下就开始胡思乱想。', createTime: '2026-09-22 21:05:00' },
        { id: 2, role: 'assistant', content: '考试前的紧张是很正常的反应。我们可以一起做一次渐进式肌肉放松，帮助你把注意力拉回身体。', createTime: '2026-09-22 21:05:15' }
    ],
    session_1004: [
        { id: 1, role: 'user', content: '我最近总是控制不住对家人发火。', createTime: '2026-09-23 09:30:00' },
        { id: 2, role: 'assistant', content: '能意识到这一点，已经是很好的开始了。通常在什么情境下，火气最容易上来？', createTime: '2026-09-23 09:30:12' }
    ],
    session_1005: [
        { id: 1, role: 'user', content: '今天散步的时候看到很美的晚霞，心情很好。', createTime: '2026-09-23 18:20:00' },
        { id: 2, role: 'assistant', content: '晚霞确实很治愈呀～把这些美好的瞬间记下来，难过的时候翻一翻，会很有力量。', createTime: '2026-09-23 18:20:10' }
    ]
}

// 会话情绪分析结果 mock（对应 sessionEmotion 接口返回结构）
export const mockEmotions = {
    session_1001: {
        dominantEmotion: '焦虑',
        moodScore: 4,
        positiveRatio: 25,
        negativeRatio: 60,
        neutralRatio: 15,
        summary: '用户近期因工作压力产生持续性焦虑，伴随睡眠问题，建议进行放松训练并规律作息。'
    },
    session_1002: {
        dominantEmotion: '悲伤',
        moodScore: 3,
        positiveRatio: 15,
        negativeRatio: 70,
        neutralRatio: 15,
        summary: '用户因人际关系冲突感到悲伤，存在自我否定倾向，建议引导表达情绪并给予情感支持。'
    }
}

// mock 流式回复：把一段固定文案按小块异步推送，模拟 SSE 效果
export async function mockStreamReply(userMessage, onMessage) {
    const reply = '谢谢你的信任，愿意把这些讲给我听。我听到了你的感受，这确实不容易。'
        + '我们可以先做一次深呼吸：慢慢吸气 4 秒，停留 2 秒，再用 6 秒缓缓呼出，重复三次。'
        + '如果愿意的话，也可以多和我说说最近发生的事情，我会一直在这里陪着你。'

    // 每 4 个字符一块，模拟后端逐块推送
    const chunks = reply.match(/.{1,4}/g) || []
    for (const chunk of chunks) {
        // eslint-disable-next-line no-await-in-loop
        await new Promise(resolve => setTimeout(resolve, 40))
        onMessage(chunk)
    }
}

// ==================== 情绪日记 mock（管理端） ====================

export const mockDiaries = [
    {
        id: 1,
        userId: 11,
        diaryDate: '2026-09-20',
        moodScore: 4,
        dominantEmotion: '焦虑',
        emotionTriggers: '加班、项目上线',
        diaryContent: '今天又忙到十点，躺在床上脑子停不下来。',
        sleepQuality: 3,
        stressLevel: 8,
        createTime: '2026-09-20 23:10:00'
    },
    {
        id: 2,
        userId: 12,
        diaryDate: '2026-09-21',
        moodScore: 3,
        dominantEmotion: '悲伤',
        emotionTriggers: '朋友争吵',
        diaryContent: '和最好的朋友吵架了，一整天都没什么精神。',
        sleepQuality: 5,
        stressLevel: 7,
        createTime: '2026-09-21 22:40:00'
    },
    {
        id: 3,
        userId: 11,
        diaryDate: '2026-09-22',
        moodScore: 5,
        dominantEmotion: '疲惫',
        emotionTriggers: '备考、失眠',
        diaryContent: '复习到很晚，睡前做了呼吸练习，好一些了。',
        sleepQuality: 4,
        stressLevel: 6,
        createTime: '2026-09-22 23:55:00'
    },
    {
        id: 4,
        userId: 13,
        diaryDate: '2026-09-23',
        moodScore: 6,
        dominantEmotion: '愤怒',
        emotionTriggers: '家庭沟通',
        diaryContent: '又对家人发了脾气，事后挺后悔的。',
        sleepQuality: 6,
        stressLevel: 7,
        createTime: '2026-09-23 21:30:00'
    },
    {
        id: 5,
        userId: 12,
        diaryDate: '2026-09-23',
        moodScore: 8,
        dominantEmotion: '开心',
        emotionTriggers: '散步、晚霞',
        diaryContent: '傍晚散步看到了很美的晚霞，记下来这一刻的好心情。',
        sleepQuality: 8,
        stressLevel: 3,
        createTime: '2026-09-23 19:00:00'
    }
]

// ==================== 综合数据分析 mock ====================

export const mockOverview = {
    userCount: 128,
    sessionCount: 356,
    articleCount: 42,
    diaryCount: 530,
    // 情绪分布
    emotionDistribution: [
        { name: '焦虑', count: 120 },
        { name: '悲伤', count: 86 },
        { name: '愤怒', count: 54 },
        { name: '开心', count: 62 },
        { name: '平静', count: 34 }
    ],
    // 近 7 日会话趋势
    sessionTrend: [
        { date: '09-17', count: 12 },
        { date: '09-18', count: 18 },
        { date: '09-19', count: 9 },
        { date: '09-20', count: 25 },
        { date: '09-21', count: 31 },
        { date: '09-22', count: 22 },
        { date: '09-23', count: 28 }
    ]
}
