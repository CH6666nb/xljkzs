<!-- =============================================================================
     情绪日记页（用户端）
     对接接口：POST /emotion-diary（新增或更新二合一，见 src/api/user.js 的 saveDiary）
     7 个字段：diaryDate 日期 / moodScore 情绪分(1-10) / dominantEmotion 主要情绪 /
              emotionTriggers 触发因素 / diaryContent 正文 / sleepQuality 睡眠质量 / stressLevel 压力水平
     注意：数据库 emotion_diary 表有 (user_id, diary_date) 唯一索引 → 同一天只能有一条，
          所以后端保存时要用"先查后改"或 ON DUPLICATE KEY UPDATE，不要直接 insert
     ============================================================================= -->
<template>
    <div class="diary-page">
        <div class="diary-card">
            <div class="diary-head">
                <h2>今日情绪日记</h2>
                <p>每天记录一点心情，看见自己的情绪变化。同一天再次提交会更新当天的日记。</p>
            </div>

            <el-form
                ref="ruleFormRef"
                :model="formData"
                :rules="rules"
                label-width="110px"
                class="diary-form"
            >
                <el-form-item label="记录日期" prop="diaryDate">
                    <el-date-picker
                        v-model="formData.diaryDate"
                        type="date"
                        placeholder="选择日期"
                        value-format="YYYY-MM-DD"
                        :disabled-date="disableFuture"
                        style="width: 100%"
                    />
                </el-form-item>

                <el-form-item label="情绪评分" prop="moodScore">
                    <div class="slider-wrap">
                        <el-slider
                            v-model="formData.moodScore"
                            :min="1"
                            :max="10"
                            :marks="{ 1: '1', 5: '5', 10: '10' }"
                            show-stops
                        />
                        <span class="slider-score">{{ formData.moodScore }} 分</span>
                    </div>
                </el-form-item>

                <el-form-item label="主要情绪" prop="dominantEmotion">
                    <el-select v-model="formData.dominantEmotion" placeholder="选择今天最主要的情绪">
                        <el-option
                            v-for="emotion in emotionOptions"
                            :key="emotion"
                            :label="emotion"
                            :value="emotion"
                        />
                    </el-select>
                </el-form-item>

                <el-form-item label="情绪触发因素" prop="emotionTriggers">
                    <el-input
                        v-model="formData.emotionTriggers"
                        placeholder="是什么引发了这种情绪？如：工作、考试、家人朋友……"
                        maxlength="200"
                        show-word-limit
                    />
                </el-form-item>

                <el-form-item label="今日感想" prop="diaryContent">
                    <el-input
                        v-model="formData.diaryContent"
                        type="textarea"
                        :rows="5"
                        placeholder="今天过得怎么样？写下想说的话……"
                        maxlength="1000"
                        show-word-limit
                    />
                </el-form-item>

                <el-form-item label="睡眠质量" prop="sleepQuality">
                    <div class="slider-wrap">
                        <el-slider v-model="formData.sleepQuality" :min="1" :max="10" show-stops />
                        <span class="slider-score">{{ formData.sleepQuality }} 分</span>
                    </div>
                </el-form-item>

                <el-form-item label="压力水平" prop="stressLevel">
                    <div class="slider-wrap">
                        <el-slider v-model="formData.stressLevel" :min="1" :max="10" show-stops />
                        <span class="slider-score">{{ formData.stressLevel }} 分</span>
                    </div>
                </el-form-item>

                <el-form-item>
                    <el-button type="primary" :loading="submitting" @click="submitForm(ruleFormRef)">
                        保存日记
                    </el-button>
                    <el-button @click="resetForm(ruleFormRef)">重置</el-button>
                </el-form-item>
            </el-form>
        </div>
    </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { saveDiary } from '@/api/user'
import { useMock } from '@/mock/knowledge'

const ruleFormRef = ref()
const submitting = ref(false)

// 取今天的日期，格式 yyyy-MM-dd（作为日期选择框的默认值）
const today = () => {
    const d = new Date()
    const pad = n => String(n).padStart(2, '0')
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

// 表单数据，字段名与后端接收参数、数据库列一一对应
const formData = reactive({
    diaryDate: today(),
    moodScore: 5,          // 情绪分，1-10
    dominantEmotion: '',
    emotionTriggers: '',
    diaryContent: '',
    sleepQuality: 5,
    stressLevel: 5
})

// 情绪可选项（下拉框）
const emotionOptions = ['开心', '平静', '焦虑', '悲伤', '愤怒', '疲惫', '孤独', '期待']

// 校验规则：本页所有字段都必填
const rules = {
    diaryDate: [{ required: true, message: '请选择记录日期', trigger: 'change' }],
    moodScore: [{ required: true, message: '请设置情绪评分', trigger: 'change' }],
    dominantEmotion: [{ required: true, message: '请选择主要情绪', trigger: 'change' }],
    emotionTriggers: [{ required: true, message: '请填写情绪触发因素', trigger: 'blur' }],
    diaryContent: [{ required: true, message: '请填写今日感想', trigger: 'blur' }],
    sleepQuality: [{ required: true, message: '请设置睡眠质量', trigger: 'change' }],
    stressLevel: [{ required: true, message: '请设置压力水平', trigger: 'change' }]
}

// 不允许选择未来日期
const disableFuture = (date) => date.getTime() > Date.now()

/**
 * 保存日记
 * 校验通过后 POST /emotion-diary
 * 后端设计要求：同一个用户同一天只保留一条记录，重复提交视为更新
 */
const submitForm = async (formRef) => {
    if (!formRef) return
    await formRef.validate(async (valid) => {
        if (!valid) return
        submitting.value = true
        try {
            if (useMock) {
                // mock 模式：仅模拟保存延迟
                await new Promise(resolve => setTimeout(resolve, 500))
            } else {
                await saveDiary(formData)
            }
            ElMessage.success('日记已保存')
        } catch (error) {
            console.error('保存日记失败：', error)
        } finally {
            submitting.value = false
        }
    })
}

// 重置表单为初始值
const resetForm = (formRef) => {
    formRef?.resetFields()
}
</script>

<style lang="scss" scoped>
.diary-page {
    display: flex;
    justify-content: center;
}

.diary-card {
    width: 100%;
    max-width: 720px;
    background-color: #fff;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    padding: 28px 32px;

    .diary-head {
        margin-bottom: 24px;

        h2 {
            margin: 0 0 8px;
            font-size: 20px;
            color: #303133;
        }

        p {
            margin: 0;
            font-size: 13px;
            color: #909399;
        }
    }

    .slider-wrap {
        display: flex;
        align-items: center;
        gap: 16px;
        width: 100%;

        .el-slider {
            flex: 1;
        }

        .slider-score {
            font-size: 14px;
            color: #409eff;
            font-weight: 600;
            width: 44px;
            text-align: right;
            flex-shrink: 0;
        }
    }
}
</style>
