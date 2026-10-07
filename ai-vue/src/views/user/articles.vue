<!-- =============================================================================
     知识文章列表页（用户端）
     对接接口：GET /knowledge/article/page
     排序参数：sortField=readCount & sortDirection=desc（按阅读量倒序 = "推荐阅读"）
     注意：
       1) 用户端只应展示已发布文章，后端请过滤 status = 1
       2) 封面图若是相对路径，需要拼上 fileBaseUrl 才能显示（见 :src 那行）
     ============================================================================= -->
<template>
    <div>
        <PageHead title="知识文章">
            <template #buttons>
                <el-radio-group v-model="onlyPublished" @change="handleFilterChange">
                    <el-radio-button :value="true">已发布</el-radio-button>
                    <el-radio-button :value="false">全部</el-radio-button>
                </el-radio-group>
            </template>
        </PageHead>

        <!-- 推荐阅读：按阅读量倒序 -->
        <div class="article-list" v-loading="loading">
            <el-empty v-if="!loading && !articles.length" description="暂无文章" />
            <el-card
                v-for="item in articles"
                :key="item.id"
                class="article-card"
                shadow="hover"
                @click="goDetail(item)"
            >
                <div class="article-card-body">
                    <el-image
                        v-if="item.coverImage"
                        :src="fileBaseUrl + item.coverImage"
                        class="article-cover"
                        fit="cover"
                    >
                        <template #error>
                            <div class="cover-fallback">📖</div>
                        </template>
                    </el-image>
                    <div class="article-cover cover-fallback" v-else>📖</div>
                    <div class="article-info">
                        <h3 class="article-title">{{ item.title }}</h3>
                        <p class="article-summary">{{ item.summary }}</p>
                        <div class="article-meta">
                            <span v-if="item.authorName"><el-icon><User /></el-icon>{{ item.authorName }}</span>
                            <span><el-icon><View /></el-icon>{{ item.readCount ?? 0 }} 阅读</span>
                            <span v-if="item.createTime"><el-icon><Clock /></el-icon>{{ item.createTime }}</span>
                            <span class="article-tags" v-if="item.tags">
                                <el-tag
                                    v-for="tag in item.tags.split(',')"
                                    :key="tag"
                                    size="small"
                                    effect="plain"
                                >
                                    {{ tag }}
                                </el-tag>
                            </span>
                        </div>
                    </div>
                </div>
            </el-card>
        </div>

        <el-pagination
            style="margin-top: 20px; justify-content: center;"
            layout="prev, pager, next"
            v-model:current-page="pagination.currentPage"
            :page-size="pagination.pageSize"
            :total="pagination.total"
            @change="handleChange"
        />
    </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import PageHead from '@/components/PageHead.vue'
import { articlePage } from '@/api/user'
import { fileBaseUrl } from '@/config/index'
import { useMock, mockArticles } from '@/mock/knowledge'

const router = useRouter()
const loading = ref(false)
const articles = ref([])
const onlyPublished = ref(true)   // 是否只看已发布（默认是）

// 本接口分页参数名：currentPage / size
const pagination = reactive({
    currentPage: 1,
    pageSize: 5,
    total: 0
})

/**
 * 加载文章列表
 * 后端需返回 { records: [...], total }
 * 每条记录建议字段：id / title / summary / coverImage / authorName / readCount / createTime / tags / status
 */
const loadArticles = async () => {
    loading.value = true
    try {
        if (useMock) {
            // mock 模式：本地过滤 + 按阅读量倒序 + 分页
            let list = [...mockArticles]
            if (onlyPublished.value) {
                list = list.filter(item => item.status === 1)
            }
            list.sort((a, b) => (b.readCount || 0) - (a.readCount || 0))
            pagination.total = list.length
            const start = (pagination.currentPage - 1) * pagination.pageSize
            articles.value = list.slice(start, start + pagination.pageSize)
            return
        }

        // 用户端推荐阅读：sortField=readCount, sortDirection=desc
        const params = {
            sortField: 'readCount',
            sortDirection: 'desc',
            currentPage: pagination.currentPage,
            size: pagination.pageSize
        }
        const { records, total } = await articlePage(params)
        articles.value = records || []
        pagination.total = total || 0
    } catch (error) {
        console.error('查询文章列表失败：', error)
    } finally {
        loading.value = false
    }
}

// 切页
const handleChange = (page) => {
    pagination.currentPage = page
    loadArticles()
}

// 切换"已发布/全部"筛选，回到第一页重新查
const handleFilterChange = () => {
    pagination.currentPage = 1
    loadArticles()
}

// 点击卡片进入文章详情（路由 /user/articles/:id）
const goDetail = (item) => {
    router.push(`/user/articles/${item.id}`)
}

onMounted(loadArticles)
</script>

<style lang="scss" scoped>
.article-list {
    min-height: 200px;
    display: flex;
    flex-direction: column;
    gap: 16px;

    .article-card {
        cursor: pointer;
        border-radius: 10px;

        .article-card-body {
            display: flex;
            gap: 18px;
        }

        .article-cover {
            width: 160px;
            height: 100px;
            border-radius: 8px;
            flex-shrink: 0;
        }

        .cover-fallback {
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #ecf5ff;
            font-size: 32px;
        }

        .article-info {
            flex: 1;
            min-width: 0;

            .article-title {
                margin: 0 0 8px;
                font-size: 17px;
                color: #303133;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            }

            .article-summary {
                margin: 0 0 12px;
                font-size: 13px;
                color: #909399;
                line-height: 1.7;
                display: -webkit-box;
                -webkit-line-clamp: 2;
                -webkit-box-orient: vertical;
                overflow: hidden;
            }

            .article-meta {
                display: flex;
                align-items: center;
                flex-wrap: wrap;
                gap: 16px;
                font-size: 12px;
                color: #909399;

                span {
                    display: inline-flex;
                    align-items: center;
                    gap: 4px;
                }

                .article-tags {
                    gap: 6px;
                }
            }
        }
    }
}
</style>
