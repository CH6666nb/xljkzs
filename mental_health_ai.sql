-- =============================================================================
-- 心理健康AI助手 · 数据库脚本（MySQL 8.0）
-- 库名：mental_health_ai
-- 内容：① 9 张表的建表语句  ② 与前端 mock 完全对得上的测试数据
-- 说明：
--   1) 表字段用下划线命名（数据库习惯），接口返回用驼峰（Java/MyBatis 自动映射）
--   2) 脚本可重复执行：会先 DROP 再 CREATE，已有测试数据会被清空
--   3) 测试账号：admin / 123456（管理员，user_type=2）；其余普通用户密码同为 123456
--      ⚠ 密码目前是明文，仅用于学习联调；正式项目请改成 BCrypt 加密后再存
-- 执行方式：mysql -uroot -p < mental_health_ai.sql
--           或在 DataGrip 中打开本文件 → 选择 mental_health_ai 数据源 → 全选执行
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `mental_health_ai`
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `mental_health_ai`;


-- =============================================================================
-- 1. user 用户表
--    对应接口：POST /user/add（注册）、POST /user/login（登录）、POST /user/logout
-- =============================================================================
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`
(
    `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `username`        VARCHAR(50)  NOT NULL COMMENT '用户名（登录账号）',
    `password`        VARCHAR(100) NOT NULL COMMENT '密码（建议存 BCrypt 加密结果）',
    `email`           VARCHAR(100) NOT NULL COMMENT '邮箱',
    `nickname`        VARCHAR(50)  DEFAULT NULL COMMENT '昵称',
    `phone`           VARCHAR(20)  DEFAULT NULL COMMENT '手机号',
    `gender`          TINYINT      DEFAULT NULL COMMENT '性别：1 男 2 女',
    `avatar`          VARCHAR(500) DEFAULT NULL COMMENT '头像地址',
    `user_type`       TINYINT      NOT NULL DEFAULT 1 COMMENT '权限：1 普通用户 2 管理员',
    `status`          TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1 正常 0 禁用',
    `last_login_time` DATETIME     DEFAULT NULL COMMENT '最后登录时间',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_email` (`email`),
    KEY `idx_phone` (`phone`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='用户表';


-- =============================================================================
-- 2. knowledge_category 知识分类表（树形结构，parent_id = 0 表示一级分类）
--    对应接口：GET /knowledge/category/tree（获取分类）
-- =============================================================================
DROP TABLE IF EXISTS `knowledge_category`;
CREATE TABLE `knowledge_category`
(
    `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `parent_id`     BIGINT       NOT NULL DEFAULT 0 COMMENT '父分类ID：0 表示一级分类',
    `category_name` VARCHAR(50)  NOT NULL COMMENT '分类名称',
    `description`   VARCHAR(255) DEFAULT NULL COMMENT '分类描述',
    `icon`          VARCHAR(255) DEFAULT NULL COMMENT '分类图标',
    `sort`          INT          NOT NULL DEFAULT 0 COMMENT '排序号，越小越靠前',
    `status`        TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1 启用 0 禁用',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`       TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='知识分类表';


-- =============================================================================
-- 3. knowledge_article 知识文章表
--    对应接口：GET /knowledge/article/page（列表，管理端/用户端共用）
--             GET /knowledge/article/{id}（详情）
--             POST /knowledge/article（新增）
--             PUT /knowledge/article/{id}（更新）
--             PUT /knowledge/article/{id}/status（发布/下线）
--             DELETE /knowledge/article/{id}（删除）
-- =============================================================================
DROP TABLE IF EXISTS `knowledge_article`;
CREATE TABLE `knowledge_article`
(
    `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `title`         VARCHAR(100) NOT NULL COMMENT '文章标题',
    `summary`       VARCHAR(500) DEFAULT NULL COMMENT '文章摘要',
    `content`       LONGTEXT     COMMENT '文章内容（富文本 HTML）',
    `cover_image`   VARCHAR(500) DEFAULT NULL COMMENT '封面图片地址（相对路径，前端拼接 fileBaseUrl）',
    `category_id`   BIGINT       DEFAULT NULL COMMENT '所属分类ID',
    `tags`          VARCHAR(255) DEFAULT NULL COMMENT '标签，多个用英文逗号分隔',
    `author_id`     BIGINT       DEFAULT NULL COMMENT '作者用户ID',
    `author_name`   VARCHAR(50)  DEFAULT NULL COMMENT '作者名称（冗余字段，方便列表直接展示）',
    `read_count`    INT          NOT NULL DEFAULT 0 COMMENT '阅读量（用户端推荐阅读按此倒序）',
    `favorite_count` INT         NOT NULL DEFAULT 0 COMMENT '收藏数',
    `status`        TINYINT      NOT NULL DEFAULT 0 COMMENT '状态：0 草稿 1 已发布 2 已下线',
    `publish_time`  DATETIME     DEFAULT NULL COMMENT '发布时间',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`       TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_status` (`status`),
    KEY `idx_read_count` (`read_count`),
    KEY `idx_title` (`title`),
    CONSTRAINT `fk_article_category` FOREIGN KEY (`category_id`) REFERENCES `knowledge_category` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='知识文章表';


-- =============================================================================
-- 4. consultation_session 咨询会话表
--    对应接口：GET  /psychological-chat/sessions（分页查询会话）
--             POST /psychological-chat/session/start（创建会话）
--             DELETE /psychological-chat/sessions/{sessionId}（删除会话）
--    注意：session_id 是业务主键（如 session_1001），接口里的 sessionId 都用它
--          start_time / expiry_time 接口返回的是毫秒时间戳，库里存 DATETIME，
--          返回时可用 DATE_FORMAT 格式化，或在 Java 里转成 getTime()
-- =============================================================================
DROP TABLE IF EXISTS `consultation_session`;
CREATE TABLE `consultation_session`
(
    `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `session_id`      VARCHAR(64)  NOT NULL COMMENT '会话业务ID，如 session_1001',
    `user_id`         BIGINT       NOT NULL COMMENT '所属用户ID',
    `session_title`   VARCHAR(200) DEFAULT NULL COMMENT '会话标题',
    `initial_message` VARCHAR(1000) DEFAULT NULL COMMENT '开场白（创建会话时的第一句话）',
    `emotion_tag`     VARCHAR(20)  DEFAULT NULL COMMENT '情绪标签：焦虑/悲伤/愤怒/开心/平静等',
    `status`          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE 进行中 / CLOSED 已结束 / EXPIRED 已过期',
    `message_count`   INT          NOT NULL DEFAULT 0 COMMENT '消息数量',
    `start_time`      DATETIME     DEFAULT NULL COMMENT '会话开始时间',
    `expiry_time`     DATETIME     DEFAULT NULL COMMENT '会话过期时间',
    `end_time`        DATETIME     DEFAULT NULL COMMENT '会话结束时间',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_session_id` (`session_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_emotion_tag` (`emotion_tag`),
    KEY `idx_create_time` (`create_time`),
    CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='咨询会话表';


-- =============================================================================
-- 5. consultation_message 咨询消息表
--    对应接口：GET  /psychological-chat/sessions/{sessionId}/messages（消息列表）
--             POST /psychological-chat/stream（流式对话，AI 回复完整后落库）
--    注意：role = user 是用户发言，assistant 是 AI 回复
--          接口里的消息字段用 role / content / createTime
-- =============================================================================
DROP TABLE IF EXISTS `consultation_message`;
CREATE TABLE `consultation_message`
(
    `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `session_id`    VARCHAR(64)  NOT NULL COMMENT '所属会话ID（对应 consultation_session.session_id）',
    `user_id`       BIGINT       DEFAULT NULL COMMENT '发言用户ID（AI 回复时可为空）',
    `role`          VARCHAR(20)  NOT NULL COMMENT '角色：user 用户 / assistant AI助手 / system 系统',
    `content`       TEXT         NOT NULL COMMENT '消息内容',
    `emotion_tag`   VARCHAR(20)  DEFAULT NULL COMMENT '该条消息识别出的情绪（可选）',
    `input_tokens`  INT          DEFAULT NULL COMMENT '输入 token 数（调用大模型时记录，可选）',
    `output_tokens` INT          DEFAULT NULL COMMENT '输出 token 数（可选）',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    `deleted`       TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    KEY `idx_session_id` (`session_id`),
    KEY `idx_create_time` (`create_time`),
    CONSTRAINT `fk_message_session` FOREIGN KEY (`session_id`) REFERENCES `consultation_session` (`session_id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='咨询消息表';


-- =============================================================================
-- 6. emotion_diary 情绪日记表
--    对应接口：POST /emotion-diary（创建或更新：同一天重复提交 → 更新）
--             GET  /emotion-diary/admin/page（管理端分页查询）
--             DELETE /emotion-diary/admin/{id}（管理端删除）
--    注意：唯一索引 uk_user_date 保证「一个用户一天一条日记」，
--          后端用 INSERT ... ON DUPLICATE KEY UPDATE 或先查后改即可实现"创建或更新"
-- =============================================================================
DROP TABLE IF EXISTS `emotion_diary`;
CREATE TABLE `emotion_diary`
(
    `id`               BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id`          BIGINT       NOT NULL COMMENT '用户ID',
    `diary_date`       DATE         NOT NULL COMMENT '记录日期',
    `mood_score`       TINYINT      NOT NULL COMMENT '情绪评分 1-10，越高越积极',
    `dominant_emotion` VARCHAR(20)  NOT NULL COMMENT '主要情绪：开心/平静/焦虑/悲伤/愤怒/疲惫等',
    `emotion_triggers` VARCHAR(255) NOT NULL COMMENT '情绪触发因素',
    `diary_content`    TEXT         NOT NULL COMMENT '今日感想',
    `sleep_quality`    TINYINT      NOT NULL COMMENT '睡眠质量 1-10',
    `stress_level`     TINYINT      NOT NULL COMMENT '压力水平 1-10',
    `create_time`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`          TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_date` (`user_id`, `diary_date`),
    KEY `idx_mood_score` (`mood_score`),
    KEY `idx_dominant_emotion` (`dominant_emotion`),
    CONSTRAINT `fk_diary_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='情绪日记表';


-- =============================================================================
-- 7. ai_analysis_task AI 分析任务表
--    对应接口：GET /psychological-chat/session/{sessionId}/emotion（会话情绪分析结果）
--    作用：记录每一次大模型分析任务（会话情绪分析、日记分析等）的状态与结果
--    result_json 里存完整的原始分析结果，接口直接把常用字段平铺返回即可
-- =============================================================================
DROP TABLE IF EXISTS `ai_analysis_task`;
CREATE TABLE `ai_analysis_task`
(
    `id`               BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `task_id`          VARCHAR(64)  NOT NULL COMMENT '任务编号，如 task_1001',
    `user_id`          BIGINT       DEFAULT NULL COMMENT '关联用户ID',
    `session_id`       VARCHAR(64)  DEFAULT NULL COMMENT '关联会话ID（会话分析时有值）',
    `diary_id`         BIGINT       DEFAULT NULL COMMENT '关联日记ID（日记分析时有值）',
    `analysis_type`    VARCHAR(20)  NOT NULL DEFAULT 'EMOTION' COMMENT '分析类型：EMOTION 情绪分析 / SUMMARY 摘要 / RISK 风险识别',
    `status`           VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT '任务状态：PENDING 待处理 / PROCESSING 处理中 / SUCCESS 成功 / FAILED 失败',
    `dominant_emotion` VARCHAR(20)  DEFAULT NULL COMMENT '分析出的主要情绪',
    `mood_score`       TINYINT      DEFAULT NULL COMMENT '分析出的情绪评分 1-10',
    `positive_ratio`   TINYINT      DEFAULT NULL COMMENT '积极情绪占比 %',
    `negative_ratio`   TINYINT      DEFAULT NULL COMMENT '消极情绪占比 %',
    `neutral_ratio`    TINYINT      DEFAULT NULL COMMENT '中性情绪占比 %',
    `summary`          VARCHAR(500) DEFAULT NULL COMMENT '分析结论摘要',
    `result_json`      JSON         DEFAULT NULL COMMENT '原始分析结果（完整 JSON）',
    `model_name`       VARCHAR(50)  DEFAULT NULL COMMENT '使用的模型名称',
    `cost_time`        INT          DEFAULT NULL COMMENT '耗时（毫秒）',
    `error_msg`        VARCHAR(500) DEFAULT NULL COMMENT '失败原因',
    `create_time`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `finish_time`      DATETIME     DEFAULT NULL COMMENT '完成时间',
    `deleted`          TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_task_id` (`task_id`),
    KEY `idx_session_id` (`session_id`),
    KEY `idx_diary_id` (`diary_id`),
    KEY `idx_status` (`status`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='AI分析任务表';


-- =============================================================================
-- 8. sys_file_info 文件信息表
--    对应接口：POST /file/upload（文件上传）
--    注意：businessType = ARTICLE / DIARY，businessField = cover / content
--          file_path 存相对路径（如 /upload/article/2026/09/cover_1.jpg），
--          接口返回给前端的 coverImage 就是它，前端会拼上 fileBaseUrl 显示
-- =============================================================================
DROP TABLE IF EXISTS `sys_file_info`;
CREATE TABLE `sys_file_info`
(
    `id`             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `file_name`      VARCHAR(200) NOT NULL COMMENT '存储文件名（一般为 UUID）',
    `original_name`  VARCHAR(200) DEFAULT NULL COMMENT '原始文件名',
    `file_path`      VARCHAR(500) NOT NULL COMMENT '文件相对路径',
    `file_url`       VARCHAR(500) DEFAULT NULL COMMENT '完整访问地址（可选，CDN/OSS 时使用）',
    `file_suffix`    VARCHAR(20)  DEFAULT NULL COMMENT '文件后缀，如 jpg/png',
    `mime_type`      VARCHAR(100) DEFAULT NULL COMMENT 'MIME 类型，如 image/jpeg',
    `file_size`      BIGINT       DEFAULT 0 COMMENT '文件大小（字节）',
    `business_type`  VARCHAR(20)  DEFAULT NULL COMMENT '业务类型：ARTICLE 文章 / DIARY 日记',
    `business_id`    VARCHAR(64)  DEFAULT NULL COMMENT '业务ID（文章ID、日记ID等）',
    `business_field` VARCHAR(50)  DEFAULT NULL COMMENT '业务字段：cover 封面 / content 正文图片',
    `storage_type`   VARCHAR(20)  NOT NULL DEFAULT 'LOCAL' COMMENT '存储方式：LOCAL 本地 / OSS 对象存储',
    `uploader_id`    BIGINT       DEFAULT NULL COMMENT '上传人ID',
    `status`         TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1 有效 0 已删除',
    `create_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `deleted`        TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    KEY `idx_business` (`business_type`, `business_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='文件信息表';


-- =============================================================================
-- 9. user_favorite 用户收藏表
--    用户端收藏知识文章（文章详情页"收藏"按钮），唯一索引防止重复收藏
-- =============================================================================
DROP TABLE IF EXISTS `user_favorite`;
CREATE TABLE `user_favorite`
(
    `id`          BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id`     BIGINT   NOT NULL COMMENT '用户ID',
    `article_id`  BIGINT   NOT NULL COMMENT '文章ID',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
    `deleted`     TINYINT  NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 未删除 1 已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_article` (`user_id`, `article_id`),
    KEY `idx_article_id` (`article_id`),
    CONSTRAINT `fk_favorite_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_favorite_article` FOREIGN KEY (`article_id`) REFERENCES `knowledge_article` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='用户收藏表';


-- =============================================================================
--                               测试数据
-- 数据与前端 mock（src/mock/index.js、src/mock/knowledge.js）保持一致，
-- 把前端的 useMock 改成 false 后，页面上的数据就是下面这些
-- =============================================================================

-- ---------- 用户（id=1 管理员，id=11/12/13 是 mock 里会话与日记用到的用户） ----------
INSERT INTO `user` (`id`, `username`, `password`, `email`, `nickname`, `phone`, `gender`, `user_type`, `status`, `last_login_time`, `create_time`) VALUES
(1,  'admin',      '123456', 'admin@mental-health.com',   '管理员',   '13800000001', 1, 2, 1, '2026-09-24 09:00:00', '2026-08-01 09:00:00'),
(2,  'user02',     '123456', 'user02@example.com',        '安然',     '13800000002', 2, 1, 1, '2026-09-23 21:10:00', '2026-08-05 10:12:00'),
(3,  'user03',     '123456', 'user03@example.com',        '小鹿',     '13800000003', 2, 1, 1, '2026-09-22 19:30:00', '2026-08-08 14:05:00'),
(4,  'user04',     '123456', 'user04@example.com',        '阿哲',     '13800000004', 1, 1, 1, '2026-09-21 08:40:00', '2026-08-11 08:40:00'),
(5,  'user05',     '123456', 'user05@example.com',        '橙子',     '13800000005', 2, 1, 1, NULL,                  '2026-08-15 16:20:00'),
(6,  'user06',     '123456', 'user06@example.com',        '木木',     '13800000006', 1, 1, 1, '2026-09-18 22:05:00', '2026-08-19 20:30:00'),
(7,  'user07',     '123456', 'user07@example.com',        '晚风',     '13800000007', 2, 1, 1, NULL,                  '2026-08-22 11:15:00'),
(8,  'user08',     '123456', 'user08@example.com',        '小舟',     '13800000008', 1, 1, 1, '2026-09-20 07:50:00', '2026-08-26 09:45:00'),
(9,  'user09',     '123456', 'user09@example.com',        '星野',     '13800000009', 2, 1, 1, NULL,                  '2026-08-29 15:35:00'),
(10, 'user10',     '123456', 'user10@example.com',        '清和',     '13800000010', 1, 1, 1, '2026-09-24 08:20:00', '2026-09-01 13:00:00'),
(11, 'zhangsan',   '123456', 'zhangsan@example.com',      '小张',     '13800000011', 1, 1, 1, '2026-09-24 10:12:00', '2026-09-02 10:00:00'),
(12, 'lisi',       '123456', 'lisi@example.com',          '阿四',     '13800000012', 2, 1, 1, '2026-09-23 18:25:00', '2026-09-03 11:30:00'),
(13, 'wangwu',     '123456', 'wangwu@example.com',        '五五',     '13800000013', 1, 1, 1, '2026-09-23 09:32:00', '2026-09-04 09:10:00'),
(14, 'lilaoshi',   '123456', 'lilaoshi@example.com',      '李老师',   '13800000014', 2, 1, 1, NULL,                  '2026-09-05 09:00:00'),
(15, 'wangyisheng','123456', 'wangyisheng@example.com',   '王医生',   '13800000015', 1, 1, 1, NULL,                  '2026-09-05 09:10:00');


-- ---------- 知识分类（一级分类，parent_id = 0） ----------
INSERT INTO `knowledge_category` (`id`, `parent_id`, `category_name`, `description`, `sort`, `status`, `create_time`) VALUES
(1, 0, '心理健康基础', '心理健康的定义、常见误区与基础概念', 1, 1, '2026-08-01 09:10:00'),
(2, 0, '情绪管理',     '认识情绪、识别情绪、与情绪共处',     2, 1, '2026-08-01 09:11:00'),
(3, 0, '压力缓解',     '压力来源分析与实用的减压方法',       3, 1, '2026-08-01 09:12:00'),
(4, 0, '人际关系',     '亲密关系、社交焦虑与边界感',         4, 1, '2026-08-01 09:13:00'),
(5, 0, '自我成长',     '自我认知、自我接纳与心理韧性',       5, 1, '2026-08-01 09:14:00'),
(6, 0, '睡眠健康',     '失眠调理、作息与睡眠卫生',           6, 1, '2026-08-01 09:15:00');

-- 二级分类示例（需要分类树展示时再放开；注意前端下拉目前只渲染一级分类）
-- INSERT INTO `knowledge_category` (`id`, `parent_id`, `category_name`, `sort`, `status`, `create_time`) VALUES
-- (11, 2, '焦虑情绪', 1, 1, '2026-08-01 09:20:00'),
-- (12, 2, '抑郁情绪', 2, 1, '2026-08-01 09:21:00'),
-- (13, 4, '亲密关系', 1, 1, '2026-08-01 09:22:00'),
-- (14, 4, '社交焦虑', 2, 1, '2026-08-01 09:23:00');


-- ---------- 知识文章（与前端 mock 一致：id 1-6，状态 0 草稿 / 1 已发布 / 2 已下线） ----------
INSERT INTO `knowledge_article` (`id`, `title`, `summary`, `content`, `cover_image`, `category_id`, `tags`, `author_id`, `author_name`, `read_count`, `favorite_count`, `status`, `publish_time`, `create_time`, `update_time`) VALUES
(1, '认识情绪：情绪没有好坏之分',
 '情绪本身并无正负之分，真正影响我们的是应对情绪的方式。本文带你重新认识愤怒、焦虑、悲伤等常见情绪。',
 '<p>很多人习惯把情绪分成"好"和"坏"：开心是好的，愤怒和悲伤是坏的。但从心理学角度看，<strong>情绪本身没有好坏</strong>，它们只是身体对内外变化做出的反应。</p><h3>情绪的三个功能</h3><ul><li>传递信息：焦虑常常在提醒我们"有事情需要面对"；</li><li>驱动行动：愤怒有时能帮我们守住自己的边界；</li><li>连接他人：把难过说出来，别人才能靠近你。</li></ul><p>真正影响我们的，不是情绪出现，而是我们如何应对它。压抑情绪会让它在别处爆发，而承认并命名情绪——"我现在感到焦虑"——本身就是一种调节。</p><p>试着在接下来的一周里，每天记录一次自己的情绪：它是什么？强度几分？想告诉你什么？这份观察，是与情绪和解的第一步。</p>',
 '', 2, '情绪管理,情感分析', 1, 'admin', 1286, 12, 1, '2026-09-10 09:30:00', '2026-09-10 09:30:00', '2026-09-10 09:30:00'),
(2, '缓解焦虑的 5 个呼吸练习方法',
 '当焦虑来袭时，有意识地调节呼吸可以快速安抚神经系统。本文介绍 5 种简单有效的呼吸练习。',
 '<p>焦虑时呼吸会不自觉地变浅变快，而呼吸反过来又能影响神经系统——<strong>这是我们可以主动使用的一个"开关"</strong>。</p><h3>1. 4-7-8 呼吸法</h3><p>吸气 4 秒，屏息 7 秒，呼气 8 秒，重复 4 轮，睡前练习效果尤其好。</p><h3>2. 方形呼吸</h3><p>吸气 4 秒、停顿 4 秒、呼气 4 秒、停顿 4 秒，像画一个正方形。</p><h3>3. 腹式呼吸</h3><p>一只手放在腹部，感受吸气时肚子鼓起、呼气时落下，每次 5 分钟。</p><h3>4. 生理性叹气</h3><p>鼻吸气两次（第二次短促补气），再长长呼出，重复 3 次。</p><h3>5. 数呼吸</h3><p>只关注呼吸，从 1 数到 10 再重来，走神了就温柔地拉回来。</p><p>练习贵在每天都做上三五分钟，而不是等焦虑到极点才想起来。</p>',
 '', 3, '压力管理,放松', 1, 'admin', 2341, 26, 1, '2026-09-12 14:20:00', '2026-09-12 14:20:00', '2026-09-12 14:20:00'),
(3, '什么是心理健康？一文读懂基础概念',
 '心理健康并不等于"没有心理疾病"，它是一种能够认识自我、应对压力、发挥潜能的良好状态。',
 '<p>世界卫生组织对心理健康的定义是：一种良好的状态，在这种状态中，<strong>个人能够认识自己的能力、应对正常的生活压力、有效地工作，并为自己所在的社区做出贡献</strong>。</p><h3>常见误区</h3><ul><li>误区一：心理健康 = 没有心理疾病；</li><li>误区二：心理问题扛一扛就过去了；</li><li>误区三：看心理咨询就是"有病"。</li></ul><p>心理健康更像是一条波动的曲线，而不是一个固定标签。遇到重大变故时状态下滑是正常反应，重要的是让自己有能力回到平衡。</p>',
 '', 1, '情感识别,学习', 14, '李老师', 876, 8, 0, NULL, '2026-09-15 10:05:00', '2026-09-15 10:05:00'),
(4, '如何建立健康的人际边界感',
 '清晰的人际边界是健康关系的基础。学会拒绝、表达需求，既尊重他人也保护自己。',
 '<p>边界感不是冷漠，而是关系中的相互尊重。它回答的是一个问题：<strong>哪些事是我的责任，哪些不是</strong>。</p><h3>三个可以练习的动作</h3><ul><li>学会说"我考虑一下"，而不是立刻答应所有请求；</li><li>用"我"开头的表达："我现在需要一点独处时间"；</li><li>接受别人因你的边界而产生的失望——那是对方需要消化的情绪。</li></ul><p>边界建立初期往往会让人不安，但长期看，它能让关系更真实、更持久。</p>',
 '', 4, '生活,放松', 15, '王医生', 1502, 19, 1, '2026-09-18 16:45:00', '2026-09-18 16:45:00', '2026-09-18 16:45:00'),
(5, '自我接纳：停止内耗的第一步',
 '很多精神内耗来源于对真实自我的不接纳。本文从心理学角度探讨如何与不完美的自己和解。',
 '<p>自我接纳意味着承认并拥抱自己的全部，包括那些你不满意的部分。<strong>它不等于放弃改变，而是先停止与自己为敌</strong>。</p><h3>为什么内耗这么累</h3><p>内耗往往来自两股力量的拉扯：一边想改变，一边在自我批判。批判消耗掉的能量，本可以用来真正推动改变。</p><h3>可以试试的三件事</h3><ul><li>把"我应该"换成"我希望"；</li><li>像对待好朋友一样和自己说话；</li><li>每天写下三件自己做得还不错的小事。</li></ul>',
 '', 5, '情感分析,学习,生活', 1, 'admin', 3209, 41, 2, '2026-09-20 20:10:00', '2026-09-20 20:10:00', '2026-09-22 09:15:00'),
(6, '职场压力大到失眠？试试这几招',
 '长期职场压力会影响睡眠与身体健康。通过时间管理、运动和认知调整，可以有效减轻压力反应。',
 '<p>职场压力已成为现代人最主要的压力来源之一，长期累积会以失眠、易怒、注意力下降的形式表现出来。</p><h3>四步减压法</h3><ul><li>把压力源写下来，区分"能改变的"和"暂时改变不了的"；</li><li>给工作设一个结束时间，睡前 1 小时不看工作消息；</li><li>每周 3 次、每次 30 分钟的中等强度运动；</li><li>睡前做 4-7-8 呼吸，或写 5 分钟"待办清单"把念头安放下来。</li></ul><p>如果失眠持续超过一个月并影响白天状态，建议寻求专业帮助。</p>',
 '', 3, '压力管理', 14, '李老师', 654, 5, 0, NULL, '2026-09-22 08:50:00', '2026-09-22 08:50:00');


-- ---------- 咨询会话（与前端 mock 一致：session_1001 ~ session_1005） ----------
INSERT INTO `consultation_session` (`id`, `session_id`, `user_id`, `session_title`, `initial_message`, `emotion_tag`, `status`, `message_count`, `start_time`, `expiry_time`, `end_time`, `create_time`, `update_time`) VALUES
(1, 'session_1001', 11, '最近工作压力有点大', '最近工作压力好大，晚上总睡不着。', '焦虑', 'ACTIVE', 5, '2026-09-20 10:12:00', '2026-09-21 10:12:00', NULL, '2026-09-20 10:12:00', '2026-09-20 10:15:00'),
(2, 'session_1002', 12, '和好朋友闹矛盾了',   '和最好的朋友吵架了，心里很难受。',   '悲伤', 'ACTIVE', 4, '2026-09-21 15:40:00', '2026-09-22 15:40:00', NULL, '2026-09-21 15:40:00', '2026-09-21 15:44:00'),
(3, 'session_1003', 11, '考前失眠怎么办',     '马上要考试了，一躺下就开始胡思乱想。', '焦虑', 'CLOSED', 4, '2026-09-22 21:05:00', '2026-09-23 21:05:00', '2026-09-22 21:40:00', '2026-09-22 21:05:00', '2026-09-22 21:40:00'),
(4, 'session_1004', 13, '总是控制不住发脾气', '我最近总是控制不住对家人发火。',     '愤怒', 'ACTIVE', 3, '2026-09-23 09:30:00', '2026-09-24 09:30:00', NULL, '2026-09-23 09:30:00', '2026-09-23 09:33:00'),
(5, 'session_1005', 12, '今天心情不错，记录一下', '今天散步的时候看到很美的晚霞，心情很好。', '开心', 'ACTIVE', 3, '2026-09-23 18:20:00', '2026-09-24 18:20:00', NULL, '2026-09-23 18:20:00', '2026-09-23 18:22:00');


-- ---------- 咨询消息 ----------
INSERT INTO `consultation_message` (`session_id`, `user_id`, `role`, `content`, `emotion_tag`, `create_time`) VALUES
-- session_1001
('session_1001', 11,   'user',      '最近工作压力好大，晚上总睡不着。', '焦虑', '2026-09-20 10:12:30'),
('session_1001', NULL, 'assistant', '听到你说晚上睡不好，我很关心你。工作压力是从什么时候开始变大的呢？', NULL, '2026-09-20 10:12:40'),
('session_1001', 11,   'user',      '大概一个月前，项目上线之后就一直加班。', '焦虑', '2026-09-20 10:13:20'),
('session_1001', NULL, 'assistant', '持续加班一个月确实很消耗人。可以先从睡前的放松练习开始，比如 4-7-8 呼吸法：吸气 4 秒、屏息 7 秒、呼气 8 秒，循环 4 轮。要不要我带你试一试？', NULL, '2026-09-20 10:13:35'),
('session_1001', 11,   'user',      '好，我今晚试试。感觉说出来轻松一点了。', '平静', '2026-09-20 10:15:00'),
-- session_1002
('session_1002', 12,   'user',      '和最好的朋友吵架了，心里很难受。', '悲伤', '2026-09-21 15:40:10'),
('session_1002', NULL, 'assistant', '和亲近的人产生矛盾，往往最让人难过。愿意和我说说因为什么吵起来了吗？', NULL, '2026-09-21 15:40:22'),
('session_1002', 12,   'user',      '她觉得我最近总不回她消息，其实我只是太累了。', '委屈', '2026-09-21 15:41:05'),
('session_1002', NULL, 'assistant', '你在疲惫的时候没能及时回应，她感到被忽略，两个人都在用自己的方式表达需要。也许可以找时间告诉她你最近的状态，同时听听她的感受。', NULL, '2026-09-21 15:41:20'),
-- session_1003
('session_1003', 11,   'user',      '马上要考试了，一躺下就开始胡思乱想。', '焦虑', '2026-09-22 21:05:00'),
('session_1003', NULL, 'assistant', '考试前的紧张是很正常的反应。我们可以一起做一次渐进式肌肉放松，帮助你把注意力拉回身体。', NULL, '2026-09-22 21:05:15'),
('session_1003', 11,   'user',      '做完之后确实放松了一些，谢谢你。', '平静', '2026-09-22 21:38:00'),
('session_1003', NULL, 'assistant', '很高兴听到这个反馈。考前这几天保持规律作息，把复习任务拆小，会更有掌控感。', NULL, '2026-09-22 21:39:30'),
-- session_1004
('session_1004', 13,   'user',      '我最近总是控制不住对家人发火。', '愤怒', '2026-09-23 09:30:00'),
('session_1004', NULL, 'assistant', '能意识到这一点，已经是很好的开始了。通常在什么情境下，火气最容易上来？', NULL, '2026-09-23 09:30:12'),
('session_1004', 13,   'user',      '下班回家以后，一点小事就会爆发。', '疲惫', '2026-09-23 09:32:30'),
-- session_1005
('session_1005', 12,   'user',      '今天散步的时候看到很美的晚霞，心情很好。', '开心', '2026-09-23 18:20:00'),
('session_1005', NULL, 'assistant', '晚霞确实很治愈呀～把这些美好的瞬间记下来，难过的时候翻一翻，会很有力量。', NULL, '2026-09-23 18:20:10'),
('session_1005', 12,   'user',      '嗯，我打算写进情绪日记里。', '开心', '2026-09-23 18:22:00');


-- ---------- 情绪日记（uk_user_date 保证一人一天一条） ----------
INSERT INTO `emotion_diary` (`id`, `user_id`, `diary_date`, `mood_score`, `dominant_emotion`, `emotion_triggers`, `diary_content`, `sleep_quality`, `stress_level`, `create_time`, `update_time`) VALUES
(1,  11, '2026-09-20', 4,  '焦虑', '加班、项目上线', '今天又忙到十点，躺在床上脑子停不下来。',                       3, 8, '2026-09-20 23:10:00', '2026-09-20 23:10:00'),
(2,  12, '2026-09-21', 3,  '悲伤', '朋友争吵',       '和最好的朋友吵架了，一整天都没什么精神。',                     5, 7, '2026-09-21 22:40:00', '2026-09-21 22:40:00'),
(3,  11, '2026-09-22', 5,  '疲惫', '备考、失眠',     '复习到很晚，睡前做了呼吸练习，好一些了。',                     4, 6, '2026-09-22 23:55:00', '2026-09-22 23:55:00'),
(4,  13, '2026-09-23', 6,  '愤怒', '家庭沟通',       '又对家人发了脾气，事后挺后悔的。',                             6, 7, '2026-09-23 21:30:00', '2026-09-23 21:30:00'),
(5,  12, '2026-09-23', 8,  '开心', '散步、晚霞',     '傍晚散步看到了很美的晚霞，记下来这一刻的好心情。',             8, 3, '2026-09-23 19:00:00', '2026-09-23 19:00:00'),
(6,  2,  '2026-09-17', 7,  '平静', '规律作息',       '早睡早起的一天，工作效率意外地高。',                           8, 3, '2026-09-17 22:20:00', '2026-09-17 22:20:00'),
(7,  3,  '2026-09-18', 5,  '焦虑', '工作汇报',       '明天要做汇报，反复修改 PPT，心跳有点快。',                     5, 7, '2026-09-18 23:05:00', '2026-09-18 23:05:00'),
(8,  4,  '2026-09-19', 6,  '平静', '和朋友聚餐',     '和朋友吃了顿火锅，聊了很多，心情舒展。',                       7, 4, '2026-09-19 22:50:00', '2026-09-19 22:50:00'),
(9,  5,  '2026-09-20', 4,  '孤独', '独处周末',       '周末一个人在家，突然有点空落落的。',                           6, 5, '2026-09-20 21:40:00', '2026-09-20 21:40:00'),
(10, 6,  '2026-09-21', 7,  '开心', '运动',           '跑了五公里，出了一身汗，整个人轻松很多。',                     8, 3, '2026-09-21 20:15:00', '2026-09-21 20:15:00'),
(11, 2,  '2026-09-22', 5,  '疲惫', '加班',           '连续加了三天班，回家只想躺着。',                               4, 8, '2026-09-22 23:30:00', '2026-09-22 23:30:00'),
(12, 7,  '2026-09-23', 6,  '平静', '阅读',           '读完了一本一直想看的书，心里很安静。',                         7, 4, '2026-09-23 22:10:00', '2026-09-23 22:10:00'),
(13, 8,  '2026-09-24', 7,  '开心', '被认可',         '方案通过了，同事还夸了我一句，挺开心的。',                     7, 4, '2026-09-24 21:00:00', '2026-09-24 21:00:00');


-- ---------- AI 分析任务（会话情绪分析结果 / 日记分析） ----------
INSERT INTO `ai_analysis_task` (`id`, `task_id`, `user_id`, `session_id`, `diary_id`, `analysis_type`, `status`, `dominant_emotion`, `mood_score`, `positive_ratio`, `negative_ratio`, `neutral_ratio`, `summary`, `result_json`, `model_name`, `cost_time`, `error_msg`, `create_time`, `finish_time`) VALUES
(1, 'task_1001', 11, 'session_1001', NULL, 'EMOTION', 'SUCCESS',
 '焦虑', 4, 25, 60, 15,
 '用户近期因工作压力产生持续性焦虑，伴随睡眠问题，建议进行放松训练并规律作息。',
 JSON_OBJECT('dominantEmotion', '焦虑', 'moodScore', 4, 'positiveRatio', 25, 'negativeRatio', 60, 'neutralRatio', 15,
             'emotions', JSON_ARRAY(JSON_OBJECT('name', '焦虑', 'ratio', 50), JSON_OBJECT('name', '疲惫', 'ratio', 25), JSON_OBJECT('name', '平静', 'ratio', 25)),
             'summary', '用户近期因工作压力产生持续性焦虑，伴随睡眠问题，建议进行放松训练并规律作息。'),
 'qwen-plus', 1280, NULL, '2026-09-20 10:16:00', '2026-09-20 10:16:02'),
(2, 'task_1002', 12, 'session_1002', NULL, 'EMOTION', 'SUCCESS',
 '悲伤', 3, 15, 70, 15,
 '用户因人际关系冲突感到悲伤，存在自我否定倾向，建议引导表达情绪并给予情感支持。',
 JSON_OBJECT('dominantEmotion', '悲伤', 'moodScore', 3, 'positiveRatio', 15, 'negativeRatio', 70, 'neutralRatio', 15,
             'emotions', JSON_ARRAY(JSON_OBJECT('name', '悲伤', 'ratio', 45), JSON_OBJECT('name', '委屈', 'ratio', 35), JSON_OBJECT('name', '平静', 'ratio', 20)),
             'summary', '用户因人际关系冲突感到悲伤，存在自我否定倾向，建议引导表达情绪并给予情感支持。'),
 'qwen-plus', 1150, NULL, '2026-09-21 15:45:00', '2026-09-21 15:45:01'),
(3, 'task_1003', 11, NULL, 1, 'EMOTION', 'SUCCESS',
 '焦虑', 4, 20, 65, 15,
 '日记显示用户处于高压力低睡眠状态，建议关注睡眠卫生并继续每日情绪记录。',
 JSON_OBJECT('dominantEmotion', '焦虑', 'moodScore', 4, 'positiveRatio', 20, 'negativeRatio', 65, 'neutralRatio', 15,
             'summary', '日记显示用户处于高压力低睡眠状态，建议关注睡眠卫生并继续每日情绪记录。'),
 'qwen-plus', 980, NULL, '2026-09-20 23:11:00', '2026-09-20 23:11:01'),
(4, 'task_1004', 13, 'session_1004', NULL, 'EMOTION', 'PENDING',
 NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'qwen-plus', NULL, NULL, '2026-09-23 09:33:00', NULL);


-- ---------- 文件信息（文章封面，business_field = cover） ----------
INSERT INTO `sys_file_info` (`id`, `file_name`, `original_name`, `file_path`, `file_url`, `file_suffix`, `mime_type`, `file_size`, `business_type`, `business_id`, `business_field`, `storage_type`, `uploader_id`, `status`, `create_time`) VALUES
(1, 'a1f3c9e2-6b41-4d8a-9c77-1f0b2e5d7101.jpg', 'emotion-cover.jpg',  '/upload/article/2026/09/a1f3c9e2-6b41-4d8a-9c77-1f0b2e5d7101.jpg', NULL, 'jpg', 'image/jpeg', 184320, 'ARTICLE', '1', 'cover', 'LOCAL', 1, 1, '2026-09-10 09:28:00'),
(2, 'b2c4d0f3-7c52-4e9b-8d88-2f1c3a6e8202.jpg', 'breath-cover.jpg',   '/upload/article/2026/09/b2c4d0f3-7c52-4e9b-8d88-2f1c3a6e8202.jpg', NULL, 'jpg', 'image/jpeg', 226510, 'ARTICLE', '2', 'cover', 'LOCAL', 1, 1, '2026-09-12 14:18:00'),
(3, 'c3d5e1a4-8d63-4f0c-9e99-3a2d4b7f9303.jpg', 'boundary-cover.jpg', '/upload/article/2026/09/c3d5e1a4-8d63-4f0c-9e99-3a2d4b7f9303.jpg', NULL, 'jpg', 'image/jpeg', 198744, 'ARTICLE', '4', 'cover', 'LOCAL', 15, 1, '2026-09-18 16:40:00');


-- ---------- 用户收藏 ----------
INSERT INTO `user_favorite` (`id`, `user_id`, `article_id`, `create_time`) VALUES
(1, 11, 1, '2026-09-20 10:20:00'),
(2, 11, 2, '2026-09-20 10:21:00'),
(3, 12, 4, '2026-09-21 16:00:00'),
(4, 13, 2, '2026-09-23 09:40:00'),
(5, 2,  5, '2026-09-22 22:05:00');


SET FOREIGN_KEY_CHECKS = 1;


-- =============================================================================
-- 附：数据分析接口（GET /data-analytics/overview）可以直接用下面这些聚合查询
--     记得带上 deleted = 0 条件（MyBatis-Plus 逻辑删除会自动加）
-- =============================================================================
-- 用户总数
-- SELECT COUNT(*) AS userCount FROM `user` WHERE deleted = 0;
--
-- 咨询会话总数 / 消息总数
-- SELECT COUNT(*) AS sessionCount FROM consultation_session WHERE deleted = 0;
-- SELECT COUNT(*) AS messageCount FROM consultation_message WHERE deleted = 0;
--
-- 知识文章总数、情绪日记总数
-- SELECT COUNT(*) AS articleCount FROM knowledge_article WHERE deleted = 0;
-- SELECT COUNT(*) AS diaryCount   FROM emotion_diary    WHERE deleted = 0;
--
-- 情绪分布（对应前端"情绪分布"柱状图）
-- SELECT dominant_emotion AS name, COUNT(*) AS count
-- FROM emotion_diary WHERE deleted = 0
-- GROUP BY dominant_emotion ORDER BY count DESC;
--
-- 近 7 日会话趋势（对应前端"近 7 日会话趋势"折线/柱状图）
-- SELECT DATE_FORMAT(create_time, '%m-%d') AS date, COUNT(*) AS count
-- FROM consultation_session
-- WHERE deleted = 0 AND create_time >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
-- GROUP BY DATE_FORMAT(create_time, '%m-%d') ORDER BY date;
--
-- 平均情绪评分（可用于数据分析页的补充指标）
-- SELECT ROUND(AVG(mood_score), 1) AS avgMoodScore FROM emotion_diary WHERE deleted = 0;
