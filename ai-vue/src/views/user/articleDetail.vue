<!-- =============================================================================
     知识文章详情页（用户端）
     对接接口：GET /knowledge/article/{id}（id 从路由参数取，见 /user/articles/:id）
     内容说明：article.content 是富文本 HTML（管理端编辑器产出），用 v-html 渲染
     ============================================================================= -->
<template>
    <div class="detail-page" v-loading="loading">
        <el-empty v-if="!loading && !article" description="文章不存在或已下线">
            <el-button type="primary" @click="goBack">返回列表</el-button>
        </el-empty>

        <template v-if="article">
            <div class="detail-card">
                <div class="detail-head">
                    <h1 class="detail-title">{{ article.title }}</h1>
                    <div class="detail-meta">
                        <span v-if="article.authorName"><el-icon><User /></el-icon>{{ article.authorName }}</span>
                        <span v-if="article.createTime"><el-icon><Clock /></el-icon>{{ article.createTime }}</span>
                        <span><el-icon><View /></el-icon>{{ article.readCount ?? 0 }} 阅读</span>
                    </div>
                    <div class="detail-tags" v-if="article.tags">
                        <el-tag v-for="tag in article.tags.split(',')" :key="tag" size="small" effect="plain">
                            {{ tag }}
                        </el-tag>
                    </div>
                </div>

                <el-divider />

                <!-- 文章内容为富文本 HTML，由管理端 wangEditor 编辑产出 -->
                <div class="detail-content" v-html="article.content"></div>

                <el-divider />
                <el-button @click="goBack">
                    <el-icon><Back /></el-icon>
                    返回文章列表
                </el-button>
            </div>
        </template>
    </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { articleDetail } from '@/api/user'
import { useMock, mockArticles } from '@/mock/knowledge'

const route = useRoute()      // 用来取路由参数 id
const router = useRouter()

const loading = ref(false)
const article = ref(null)

// 加载文章详情；后端一般会顺便把阅读量 +1
const loadArticle = async () => {
    loading.value = true
    try {
        if (useMock) {
            article.value = mockArticles.find(item => String(item.id) === String(route.params.id)) || null
            return
        }
        article.value = await articleDetail(route.params.id)
    } catch (error) {
        console.error('获取文章详情失败：', error)
    } finally {
        loading.value = false
    }
}

// 返回文章列表页
const goBack = () => {
    router.push('/user/articles')
}

onMounted(loadArticle)
</script>

<style lang="scss" scoped>
.detail-page {
    display: flex;
    justify-content: center;
}

.detail-card {
    width: 100%;
    max-width: 860px;
    background-color: #fff;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    padding: 32px 40px;

    .detail-head {
        .detail-title {
            margin: 0 0 14px;
            font-size: 26px;
            color: #303133;
            line-height: 1.4;
        }

        .detail-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 18px;
            font-size: 13px;
            color: #909399;

            span {
                display: inline-flex;
                align-items: center;
                gap: 4px;
            }
        }

        .detail-tags {
            margin-top: 12px;
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }
    }

    // 富文本内容基础排版
    .detail-content {
        font-size: 15px;
        color: #303133;
        line-height: 1.9;

        :deep(img) {
            max-width: 100%;
            border-radius: 8px;
        }

        :deep(p) {
            margin: 0 0 14px;
        }

        :deep(h1), :deep(h2), :deep(h3) {
            margin: 20px 0 12px;
        }

        :deep(blockquote) {
            margin: 14px 0;
            padding: 8px 16px;
            background-color: #f5f7fa;
            border-left: 4px solid #409eff;
            color: #606266;
        }
    }
}
</style>
