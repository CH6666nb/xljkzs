<template>
    <div class="dashboard" v-loading="loading">
        <!-- 统计卡片：字段名以后端 overview 返回为准，pickNum 已做多字段名兼容 -->
        <el-row :gutter="20">
            <el-col :xs="12" :sm="6" v-for="card in statCards" :key="card.label">
                <div class="stat-card">
                    <div class="stat-icon" :style="{ backgroundColor: card.color }">
                        <el-icon :size="26"><component :is="card.icon" /></el-icon>
                    </div>
                    <div class="stat-info">
                        <p class="stat-value">{{ card.value }}</p>
                        <p class="stat-label">{{ card.label }}</p>
                    </div>
                </div>
            </el-col>
        </el-row>

        <el-row :gutter="20" class="chart-row">
            <!-- 情绪分布 -->
            <el-col :xs="24" :md="10">
                <div class="chart-card">
                    <h3>情绪分布</h3>
                    <div class="bar-list">
                        <div class="bar-item" v-for="item in emotionDistribution" :key="item.name">
                            <span class="bar-name">{{ item.name }}</span>
                            <div class="bar-track">
                                <div
                                    class="bar-fill"
                                    :style="{ width: barWidth(item.count, emotionMax), backgroundColor: emotionColor(item.name) }"
                                ></div>
                            </div>
                            <span class="bar-count">{{ item.count }}</span>
                        </div>
                    </div>
                    <el-empty v-if="!emotionDistribution.length" description="暂无数据" :image-size="60" />
                </div>
            </el-col>

            <!-- 近 7 日会话趋势 -->
            <el-col :xs="24" :md="14">
                <div class="chart-card">
                    <h3>近 7 日会话趋势</h3>
                    <div class="column-chart" v-if="trend.length">
                        <div class="column-item" v-for="item in trend" :key="item.date">
                            <span class="column-count">{{ item.count }}</span>
                            <div
                                class="column-fill"
                                :style="{ height: columnHeight(item.count) }"
                            ></div>
                            <span class="column-date">{{ item.date }}</span>
                        </div>
                    </div>
                    <el-empty v-else description="暂无数据" :image-size="60" />
                </div>
            </el-col>
        </el-row>

        <el-row class="chart-row">
            <el-col :span="24">
                <div class="chart-card tip-card">
                    <h3>说明</h3>
                    <p>
                        数据来自 <code>GET /data-analytics/overview</code> 综合数据分析接口。
                        后端返回字段名确定后，可在下方 <code>pickNum</code> / <code>normalize</code>
                        的字段候选列表中补充或调整，页面即可正常展示。
                    </p>
                </div>
            </el-col>
        </el-row>
    </div>
</template>

<script setup>
// =============================================================================
// 数据分析页（后台首页）
// 对接接口：GET /data-analytics/overview
//
// 这个接口返回的字段名接口文档没有写死，所以下面用了"候选字段名"的方式兼容：
//   例如用户数，后端叫 userCount / totalUsers / totalUser 都能认出来。
// 等你后端定了字段名，看到页面显示 0，就来下面这些候选列表里补上你的字段名即可。
//
// 参考的返回结构（mental_health_ai.sql 末尾附了对应的聚合 SQL）：
//   {
//     userCount, sessionCount, articleCount, diaryCount,
//     emotionDistribution: [{ name: '焦虑', count: 120 }, ...],
//     sessionTrend: [{ date: '09-17', count: 12 }, ...]
//   }
// =============================================================================
import { computed, onMounted, ref } from 'vue'
import { analyticsOverview } from '@/api/admin'
import { useMock, mockOverview } from '@/mock/index'

const loading = ref(false)
const overview = ref({})   // 接口返回的原始数据，下面所有图表都基于它计算

// 从对象中按候选字段名取第一个非空数值（兼容后端字段命名差异）
const pickNum = (keys) => {
    for (const key of keys) {
        const val = overview.value?.[key]
        if (val !== undefined && val !== null && val !== '') return Number(val) || 0
    }
    return 0
}

// 顶部四个统计卡片：label 是显示文案，value 取上面 pickNum 的结果
const statCards = computed(() => [
    { label: '用户总数', value: pickNum(['userCount', 'totalUsers', 'totalUser']), icon: 'User', color: '#409eff' },
    { label: '咨询会话总数', value: pickNum(['sessionCount', 'totalSessions', 'totalSession']), icon: 'ChatDotRound', color: '#67c23a' },
    { label: '知识文章总数', value: pickNum(['articleCount', 'totalArticles', 'totalArticle']), icon: 'Reading', color: '#e6a23c' },
    { label: '情绪日记总数', value: pickNum(['diaryCount', 'totalDiaries', 'totalDiary']), icon: 'Notebook', color: '#f56c6c' }
])

// 情绪分布：兼容 [{name/emotion/tagName, count/value/num}] 多种结构
const emotionDistribution = computed(() => {
    const list = overview.value?.emotionDistribution || overview.value?.emotions || []
    return list.map(item => ({
        name: item.name ?? item.emotion ?? item.tagName ?? '-',
        count: Number(item.count ?? item.value ?? item.num ?? 0)
    }))
})

// 会话趋势：兼容 [{date/day, count/value/num}] 多种结构
const trend = computed(() => {
    const list = overview.value?.sessionTrend || overview.value?.trend || []
    return list.map(item => ({
        date: item.date ?? item.day ?? '-',
        count: Number(item.count ?? item.value ?? item.num ?? 0)
    }))
})

const emotionMax = computed(() => Math.max(...emotionDistribution.value.map(i => i.count), 1))
const trendMax = computed(() => Math.max(...trend.value.map(i => i.count), 1))

const barWidth = (count, max) => `${Math.max((count / max) * 100, 2)}%`
const columnHeight = (count) => `${Math.max((count / trendMax.value) * 160, 4)}px`

// 常见情绪的展示色
const emotionColors = {
    '焦虑': '#e6a23c', '悲伤': '#409eff', '愤怒': '#f56c6c',
    '开心': '#67c23a', '平静': '#909399', '疲惫': '#9a6fe6'
}
const emotionColor = (name) => emotionColors[name] || '#409eff'

const loadOverview = async () => {
    loading.value = true
    try {
        // mock 模式：使用本地模拟数据
        overview.value = useMock ? mockOverview : await analyticsOverview()
    } catch (error) {
        console.error('获取综合数据分析失败：', error)
    } finally {
        loading.value = false
    }
}

onMounted(loadOverview)
</script>

<style lang="scss" scoped>
.stat-card {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 20px;
    border-radius: 8px;
    background-color: #fff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    margin-bottom: 20px;

    .stat-icon {
        width: 56px;
        height: 56px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #fff;
        flex-shrink: 0;
    }

    .stat-value {
        font-size: 26px;
        font-weight: 700;
        color: #303133;
        margin: 0;
        line-height: 1.2;
    }

    .stat-label {
        font-size: 13px;
        color: #909399;
        margin: 4px 0 0;
    }
}

.chart-row {
    margin-top: 4px;
}

.chart-card {
    background-color: #fff;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    padding: 20px;
    min-height: 280px;

    h3 {
        margin: 0 0 16px;
        font-size: 16px;
        color: #303133;
    }
}

// 横向条形图
.bar-item {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 14px;

    .bar-name {
        width: 48px;
        text-align: right;
        font-size: 13px;
        color: #606266;
        flex-shrink: 0;
    }

    .bar-track {
        flex: 1;
        height: 14px;
        background-color: #f0f2f5;
        border-radius: 7px;
        overflow: hidden;

        .bar-fill {
            height: 100%;
            border-radius: 7px;
            transition: width 0.5s ease;
        }
    }

    .bar-count {
        width: 40px;
        font-size: 13px;
        color: #606266;
        flex-shrink: 0;
    }
}

// 纵向柱状图
.column-chart {
    display: flex;
    align-items: flex-end;
    justify-content: space-around;
    height: 220px;
    padding-top: 10px;

    .column-item {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: flex-end;
        height: 100%;

        .column-count {
            font-size: 12px;
            color: #909399;
            margin-bottom: 4px;
        }

        .column-fill {
            width: 28px;
            border-radius: 4px 4px 0 0;
            background: linear-gradient(180deg, #79bbff, #409eff);
            transition: height 0.5s ease;
        }

        .column-date {
            font-size: 12px;
            color: #606266;
            margin-top: 6px;
        }
    }
}

.tip-card {
    min-height: auto;

    p {
        margin: 0;
        font-size: 13px;
        color: #909399;
        line-height: 1.8;
    }

    code {
        background-color: #f4f4f5;
        padding: 2px 6px;
        border-radius: 4px;
        color: #476582;
    }
}
</style>
