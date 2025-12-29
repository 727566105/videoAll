--
-- PostgreSQL database dump
--

\restrict vFSodJAAlutqLE05hs4eUYMeaLarZPakbztMsVRnJPwWoGPgqGiKei4XKtmgDtd

-- Dumped from database version 14.20 (Homebrew)
-- Dumped by pg_dump version 14.20 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_analysis_results; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.ai_analysis_results (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    content_id uuid NOT NULL,
    ai_config_id uuid,
    analysis_result json,
    generated_tags json,
    confidence_scores json,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    error_message text,
    execution_time integer,
    tokens_used integer,
    analysis_type character varying(50) DEFAULT 'tag_generation'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone,
    current_stage character varying(50)
);


ALTER TABLE public.ai_analysis_results OWNER TO wangxuyang;

--
-- Name: COLUMN ai_analysis_results.content_id; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.content_id IS '关联的内容ID';


--
-- Name: COLUMN ai_analysis_results.ai_config_id; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.ai_config_id IS '使用的AI配置ID';


--
-- Name: COLUMN ai_analysis_results.analysis_result; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.analysis_result IS 'AI分析原始结果';


--
-- Name: COLUMN ai_analysis_results.generated_tags; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.generated_tags IS 'AI生成的标签列表';


--
-- Name: COLUMN ai_analysis_results.confidence_scores; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.confidence_scores IS '各标签的置信度分数';


--
-- Name: COLUMN ai_analysis_results.status; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.status IS '分析状态：pending-等待中、processing-处理中、completed-完成、failed-失败';


--
-- Name: COLUMN ai_analysis_results.retry_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.retry_count IS '已重试次数';


--
-- Name: COLUMN ai_analysis_results.error_message; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.error_message IS '错误信息';


--
-- Name: COLUMN ai_analysis_results.execution_time; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.execution_time IS 'AI分析耗时（毫秒）';


--
-- Name: COLUMN ai_analysis_results.tokens_used; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.tokens_used IS '消耗的token数量';


--
-- Name: COLUMN ai_analysis_results.analysis_type; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.analysis_type IS '分析类型：tag_generation-标签生成、content_summary-内容摘要、sentiment_analysis-情感分析';


--
-- Name: COLUMN ai_analysis_results.completed_at; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.completed_at IS '分析完成时间';


--
-- Name: COLUMN ai_analysis_results.current_stage; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_analysis_results.current_stage IS '当前分析阶段：initializing-初始化、ocr-OCR提取、generating_tags-生成标签、generating_description-生成描述';


--
-- Name: ai_configs; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.ai_configs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    provider character varying(50) NOT NULL,
    api_endpoint character varying(500),
    api_key_encrypted text,
    model character varying(100),
    timeout integer DEFAULT 60000 NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    preferences json,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    last_test_at timestamp without time zone,
    imported_at timestamp without time zone,
    exported_at timestamp without time zone,
    last_rotation_at timestamp without time zone
);


ALTER TABLE public.ai_configs OWNER TO wangxuyang;

--
-- Name: COLUMN ai_configs.provider; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.provider IS 'AI服务提供商';


--
-- Name: COLUMN ai_configs.api_endpoint; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.api_endpoint IS 'API端点URL';


--
-- Name: COLUMN ai_configs.api_key_encrypted; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.api_key_encrypted IS '加密的API密钥';


--
-- Name: COLUMN ai_configs.model; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.model IS '模型名称，如 qwen2.5:7b、gpt-4o';


--
-- Name: COLUMN ai_configs.timeout; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.timeout IS 'API调用超时时间（毫秒）';


--
-- Name: COLUMN ai_configs.is_enabled; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.is_enabled IS '是否启用AI分析功能';


--
-- Name: COLUMN ai_configs.priority; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.priority IS '配置优先级，用于多配置场景';


--
-- Name: COLUMN ai_configs.preferences; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.preferences IS '其他偏好设置，包括温度、最大token数等';


--
-- Name: COLUMN ai_configs.status; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.status IS '配置状态：active-活跃、inactive-停用、testing-测试中';


--
-- Name: COLUMN ai_configs.last_test_at; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.last_test_at IS '最后测试连接时间';


--
-- Name: COLUMN ai_configs.imported_at; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.imported_at IS '配置导入时间';


--
-- Name: COLUMN ai_configs.exported_at; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.exported_at IS '配置最后导出时间';


--
-- Name: COLUMN ai_configs.last_rotation_at; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_configs.last_rotation_at IS 'API密钥最后轮换时间';


--
-- Name: ai_test_history; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.ai_test_history (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    ai_config_id uuid NOT NULL,
    test_result boolean NOT NULL,
    response_time integer,
    error_message text,
    details json,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ai_test_history OWNER TO wangxuyang;

--
-- Name: COLUMN ai_test_history.ai_config_id; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_test_history.ai_config_id IS '关联的AI配置ID';


--
-- Name: COLUMN ai_test_history.test_result; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_test_history.test_result IS '测试是否成功';


--
-- Name: COLUMN ai_test_history.response_time; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_test_history.response_time IS '响应时间（毫秒）';


--
-- Name: COLUMN ai_test_history.error_message; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_test_history.error_message IS '错误信息';


--
-- Name: COLUMN ai_test_history.details; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_test_history.details IS '详细信息（可用模型、token使用等）';


--
-- Name: COLUMN ai_test_history.created_at; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.ai_test_history.created_at IS '测试时间';


--
-- Name: content_tags; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.content_tags (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    content_id uuid NOT NULL,
    tag_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.content_tags OWNER TO wangxuyang;

--
-- Name: contents; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.contents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    platform character varying(20) NOT NULL,
    content_id character varying(100) NOT NULL,
    title character varying(500) NOT NULL,
    author character varying(100) NOT NULL,
    description text DEFAULT ''::text,
    media_type character varying(10) NOT NULL,
    file_path character varying(500) NOT NULL,
    cover_url character varying(500) NOT NULL,
    source_url character varying(500) NOT NULL,
    source_type integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    task_id uuid,
    all_images text,
    all_videos text,
    like_count integer DEFAULT 0,
    comment_count integer DEFAULT 0,
    share_count integer DEFAULT 0,
    publish_time timestamp without time zone,
    tags text,
    collect_count integer DEFAULT 0,
    view_count integer DEFAULT 0,
    is_missing boolean DEFAULT false
);


ALTER TABLE public.contents OWNER TO wangxuyang;

--
-- Name: COLUMN contents.all_images; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.all_images IS 'JSON array of all image URLs';


--
-- Name: COLUMN contents.all_videos; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.all_videos IS 'JSON array of all video URLs';


--
-- Name: COLUMN contents.like_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.like_count IS '点赞数量';


--
-- Name: COLUMN contents.comment_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.comment_count IS '评论数量';


--
-- Name: COLUMN contents.share_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.share_count IS '分享数量';


--
-- Name: COLUMN contents.publish_time; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.publish_time IS '发布时间';


--
-- Name: COLUMN contents.tags; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.tags IS 'JSON array of tags';


--
-- Name: COLUMN contents.collect_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.collect_count IS '收藏数量';


--
-- Name: COLUMN contents.view_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.view_count IS '浏览数量';


--
-- Name: COLUMN contents.is_missing; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.contents.is_missing IS '笔记是否已消失';


--
-- Name: crawl_tasks; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.crawl_tasks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    platform character varying(20) NOT NULL,
    target_identifier character varying(200) NOT NULL,
    frequency character varying(20) NOT NULL,
    status integer DEFAULT 1 NOT NULL,
    last_run_at timestamp without time zone,
    next_run_at timestamp without time zone,
    config json DEFAULT '{}'::json NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.crawl_tasks OWNER TO wangxuyang;

--
-- Name: hotsearch_snapshots; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.hotsearch_snapshots (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    platform character varying(20) NOT NULL,
    capture_date date NOT NULL,
    capture_time timestamp without time zone DEFAULT now() NOT NULL,
    snapshot_data json NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.hotsearch_snapshots OWNER TO wangxuyang;

--
-- Name: platform_accounts; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.platform_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    platform character varying(20) NOT NULL,
    account_alias character varying(50) NOT NULL,
    cookies_encrypted text NOT NULL,
    is_valid boolean DEFAULT true NOT NULL,
    last_checked_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.platform_accounts OWNER TO wangxuyang;

--
-- Name: platform_cookies; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.platform_cookies (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    platform character varying(50) NOT NULL,
    account_alias character varying(100) NOT NULL,
    cookies_encrypted text NOT NULL,
    is_valid boolean DEFAULT true NOT NULL,
    last_checked_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    preferences json
);


ALTER TABLE public.platform_cookies OWNER TO wangxuyang;

--
-- Name: COLUMN platform_cookies.preferences; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.platform_cookies.preferences IS '用户偏好设置（JSON格式）';


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.system_settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    storage_path character varying(500) DEFAULT '/data/media/'::character varying NOT NULL,
    task_schedule_interval integer DEFAULT 3600 NOT NULL,
    hotsearch_fetch_interval integer DEFAULT 3600 NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.system_settings OWNER TO wangxuyang;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.tags (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(50) NOT NULL,
    color character varying(7) DEFAULT '#1890ff'::character varying NOT NULL,
    description character varying(200),
    usage_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tags OWNER TO wangxuyang;

--
-- Name: COLUMN tags.color; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.tags.color IS '十六进制颜色代码';


--
-- Name: COLUMN tags.usage_count; Type: COMMENT; Schema: public; Owner: wangxuyang
--

COMMENT ON COLUMN public.tags.usage_count IS '使用次数统计';


--
-- Name: task_logs; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.task_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    task_id uuid,
    task_name character varying(100) NOT NULL,
    platform character varying(20) NOT NULL,
    start_time timestamp without time zone DEFAULT now() NOT NULL,
    end_time timestamp without time zone,
    status character varying(10) DEFAULT 'running'::character varying NOT NULL,
    type character varying(15) DEFAULT 'author'::character varying NOT NULL,
    result json,
    error text,
    crawled_count integer DEFAULT 0 NOT NULL,
    new_count integer DEFAULT 0 NOT NULL,
    updated_count integer DEFAULT 0 NOT NULL,
    execution_time integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.task_logs OWNER TO wangxuyang;

--
-- Name: users; Type: TABLE; Schema: public; Owner: wangxuyang
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    deleted_at timestamp without time zone,
    role character varying(20) DEFAULT 'operator'::character varying NOT NULL
);


ALTER TABLE public.users OWNER TO wangxuyang;

--
-- Data for Name: ai_analysis_results; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.ai_analysis_results (id, content_id, ai_config_id, analysis_result, generated_tags, confidence_scores, status, retry_count, error_message, execution_time, tokens_used, analysis_type, created_at, updated_at, completed_at, current_stage) FROM stdin;
\.


--
-- Data for Name: ai_configs; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.ai_configs (id, provider, api_endpoint, api_key_encrypted, model, timeout, is_enabled, priority, preferences, status, created_at, updated_at, last_test_at, imported_at, exported_at, last_rotation_at) FROM stdin;
f9192a66-d9ed-4f46-9a28-a92b35800abb	deepseek	https://api.deepseek.com/v1	fa61fb523885f4a2eb92161f57e77dc9:f13c8470b4ebc08de993e9ffb38d1ea1b0c0793ee85925a0fb0dea0ad32795cd43be74af73786a7837f0a7f0306432aa	deepseek-chat	60000	t	0	\N	active	2025-12-28 01:54:51.592963	2025-12-28 09:41:51.260385	2025-12-28 09:54:19.762	\N	\N	\N
d26acb69-d7b7-4007-ab10-58b0d2135a8d	deepseek	https://api.deepseek.com/v1	\N	deepseek-chat	60000	f	1	\N	inactive	2025-12-28 09:54:30.130869	2025-12-28 09:54:30.130869	\N	\N	\N	\N
\.


--
-- Data for Name: ai_test_history; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.ai_test_history (id, ai_config_id, test_result, response_time, error_message, details, created_at) FROM stdin;
\.


--
-- Data for Name: content_tags; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.content_tags (id, content_id, tag_id, created_at) FROM stdin;
042cd347-4693-4f0a-89b4-239151c33df9	fdc342d5-e6cc-4c39-aca7-d383b4c1924c	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 21:12:02.011773
8c026451-4421-4f9c-84eb-8852b859f1c1	25b464fb-82d6-43d0-9875-7188fe613e62	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 21:29:59.847361
8317a54a-f8d8-4d03-8d05-62565f9922ac	b64577bb-bc62-408e-b935-729ceffd7aa7	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 21:30:07.760191
1bd35f91-bb22-4456-839c-8611e4530309	f184278c-e5ee-496b-a033-b4fe9525bc1a	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 21:30:18.175108
63d23e22-5472-44b4-8727-2976659bc25e	e5ae618f-727c-4c05-afda-7e1654ee74ff	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 21:30:18.182231
37a5e65c-3675-4561-adf4-2c37ed0e744d	8f4098d8-08a8-4de1-8e99-8ce8a296ae65	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 21:30:18.190947
08c95aae-32b5-439a-a42f-f5c100cf919d	d5649369-da0b-4c53-87d3-819ddb1a3500	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-27 22:14:53.589795
9d8b0d1c-727b-4670-85e4-8f3289260fd0	497a26a3-c17e-4023-b01f-3975070d2e34	deacecf9-a0c5-48b0-b6ca-d529b0fb2aaa	2025-12-28 01:04:10.240943
3911f251-7029-4f79-a17a-08b003b63bb2	f4935144-ccee-4551-a222-ed9885dee8b2	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.780966
4eb1e929-7441-4695-9061-a4bbc7d95f32	f1213ea5-8bd0-433a-b0c7-881f1c5b9c6a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.784331
e81eb895-dfd7-4609-82a0-3837770714c9	8c3da8ef-14f9-4ed2-addd-84d75788b231	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.786091
1620e314-9551-4b6b-8527-b646b0a686b0	371b7ea9-e591-4746-96c1-04201e653097	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.788176
4b889a77-ebc2-4502-b4f7-dafdb13da30e	8820efe7-64be-4821-bd35-f13d5abf65ef	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.790172
701f2b16-0fdc-4f78-9dc1-dcb8e653e524	1f3be079-e132-4b71-86ae-c705fee8c0ea	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.791995
c1ee3b50-780c-44cd-a72e-28a8700e3232	24256734-34b1-48c9-bd36-242688c1bd74	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.795071
8dda34a4-d17d-49ab-9952-494f4bb85227	d49d98bf-ed5b-4051-9321-4836ce63bcbd	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:23.798268
0c7a7897-0e2a-4dc1-9fbe-d305f6e919dd	58e238c5-c4cd-483d-857b-2b58869a1197	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:36.954267
f98ac459-af6d-4ca2-ab1e-22247bc21f13	ca895d0a-60be-480c-a659-bd697406b24f	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:36.961464
6d9e8d3b-2a51-4ae0-8ebb-bed9d40fe6fb	d2922b6e-1e94-4eac-88dc-86a8ee72ec91	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:36.964125
761a63fd-6d0e-4187-9648-a2d8307488e2	acf5ff23-82bb-4587-a2a0-8add23a09f3a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:36.965881
f636c157-fa5b-476d-b121-9221e3e3db6f	44ceed34-c97e-472d-b76c-68057c547327	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:36.967369
0da7dac7-9e17-46b3-9ccf-9393ab1d0f8d	d2149f0a-390d-4895-8e45-9c0c107b1baf	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:36.968504
99beaa67-a737-497f-aa64-7c0abfc4d96e	dd72a941-95a8-4249-806c-40d7d14f8e96	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:58.371727
5aa4d433-79d4-46c1-a07e-793062ad17ab	c00b7216-286d-45c3-9d6f-b93215260df4	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:58.379038
101713c5-427b-4afd-b459-5fa72d4ba46f	6641a335-00a2-4406-9d08-4d3ee0525452	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:58.382093
786c010d-551e-4cd1-a70f-51cdc8deb354	a9b2b770-eddb-453d-a110-eb62e73cd33c	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:58.383782
7a45e2a1-4447-4f79-8397-aa175f27ad89	999a17ac-058e-4fb3-a806-7ea77eedad55	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:58.38579
1d6bbeb9-66dd-4759-a815-5de4e41632d1	991c6c25-94d6-4d47-8108-89926d66669a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:32:58.388
bff9ec75-e1c2-4354-baf8-ab84fe8af6f4	751ee457-d282-477c-b1a7-b548bc3ff1df	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.309608
1e3b39d8-7a1e-4fc1-982d-caf18a4830f3	30a86ef6-7756-4647-930f-9ec0d7a96166	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.322795
cf4420a9-d25a-4753-996a-e316843d380a	e46340e0-e693-43e1-889e-ec0214f62dc7	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.324451
01c45b97-40af-41df-baca-6841b1c69015	5d23d24d-138f-4314-a9d3-7356f9402918	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.326494
124fdca5-9ba0-40d9-93bc-6824c403d196	250e37a6-66fd-481e-90f2-dd983f67208a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.332019
ea400004-e0d1-49b7-b92a-0f892c08616d	59b4a550-9590-43c3-9b41-eb0b10b1bcaf	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.333713
5742ff37-18be-4b36-98bc-4905e76ef2da	b6a56f53-162b-4a82-bdd7-d5c0b9d2b827	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.335274
00271f48-9dff-4a8b-a525-a7e301994de5	6075ca2b-470e-4498-89c2-3a080d05f145	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.337769
6af4b178-cb39-4597-b14d-1901220a58d5	38ce1c59-14d2-42a8-9485-db152fbc9e59	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.339126
3a092002-b014-45a5-8db4-184714a179b3	8c449b55-d684-4dd5-a29e-6a01d4f2d8d6	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:06.340316
9ec306db-daa9-4e2d-87f4-37b6e8e81bb4	7583a70c-1835-46b4-a489-39e8bdfee317	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.674093
959d1e4a-3530-4e1d-afd2-170e4e4c1615	bbcc400e-657b-41f3-b7c9-c29377c67f2b	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.679778
1701d842-e38a-43e9-b7ff-e4b4a6ecbd6e	443c68f5-411d-434c-80c9-64d5ccfade8b	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.701284
c25773c4-756e-4110-ad46-17f22186fc7e	1296cfe2-614a-413c-abda-fe5c3eb6dd66	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.704125
781e34b8-d2d4-4ff2-9849-274657879d8d	6013b4d1-645f-4215-8cfc-fa63ca06cdfa	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.705902
81fdeb18-b459-4fa1-927b-592aab2929ba	6f1d0a17-e3e7-4d8f-9523-7eb1093219e4	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.711993
12d6e5b0-3cb7-4cdf-b4ce-d4e7ba3d36f1	f4869e31-792b-464e-bc81-139687e32459	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.71409
b32d234d-69eb-4ea6-a84f-352653403f72	9f749f66-cca0-45ca-8130-3c07ee42fe26	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.715647
84d04c00-5f6d-4657-8dea-38c18d4bdd63	ea422f78-f302-4c53-af1e-1557edd557d9	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.71694
c91ae21f-05d3-457c-8a8a-5995d0498acb	37850121-3b8f-454b-b16c-c036b5480538	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:13.718189
86442516-19f6-4dab-8292-b4dbd05121a2	090d8ede-8c13-48d1-9b07-5f216f4f3430	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.20253
7eb4e0bb-4cb0-4308-8beb-2eeceeabb4fe	b9b9511b-1676-4705-8f67-9112a2b7661a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.206183
d2ba96ab-9da8-4663-b86d-123f2a065107	45884b5d-e2ac-404a-bb36-2ddfd92b9753	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.208007
5db6eb65-5549-4f33-9a61-92e39a991ce0	267685c5-a3ac-4edb-8686-03504a4f31e0	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.211627
8b9e7dd2-8eee-41aa-bf1b-c3d7c4bdfec8	02d41e9d-b99a-4aa3-9b56-3e2e6ca8255a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.214501
3ec8e56e-8ca3-4350-92c4-778dc1ed9b9f	702f878e-56b1-4d6c-a308-a21c1f18dd2a	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.216064
8234279e-375b-4726-9335-8500a21fc284	75987a49-21d5-44a6-9318-2720a8620156	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.217754
ab4b0ca9-af9f-41e4-a77d-734c065c7b2d	ab15d3e5-7669-48a1-98b4-b39ef17e6fac	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.218987
f163ba60-14ad-42b5-8e08-2ecba8f03d14	0b7a8212-1518-4cda-bcd4-365d226622a9	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 01:33:22.22031
3d7a95bb-13b2-47e7-9b00-baa6a9bce9de	1d0a2f72-bf30-44ea-9b5e-3e3f7dacbccc	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-28 01:33:37.239605
9a52a1d4-d839-4862-8a03-da465789359f	63925858-45d3-43ad-9102-b641e5a18566	854a955c-7fbd-41cc-afe0-f60b6a1fd055	2025-12-28 11:32:06.120299
67bce759-a9e9-43e8-80be-aae246a87068	63925858-45d3-43ad-9102-b641e5a18566	44f34509-8e99-47a5-9ba2-2cdad0db2b32	2025-12-28 11:32:06.129516
70305474-e92e-4d8b-96de-4f944031afa9	63925858-45d3-43ad-9102-b641e5a18566	780afa94-974b-4460-8647-b0e060905bb5	2025-12-28 11:32:06.14335
7c2d6a1f-465e-4deb-8b09-0bcc1774644a	63925858-45d3-43ad-9102-b641e5a18566	99607ff5-b6cd-4ba1-965f-c2e50831103b	2025-12-28 11:32:06.153035
4dd192cb-7cc8-4c33-a5e1-b06bd8a5a70d	c7931ba4-be64-49e1-ae2a-b00ffd1f7076	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-28 11:33:05.303566
1e75f05f-8a97-4df3-b5b6-0435251f6825	d58c643c-f89b-4e00-9eed-0a327aa31d89	e1633aad-1323-4839-8297-a7ef62e04423	2025-12-28 11:34:10.20309
d4a436b4-16c9-4d18-a6c8-02635dfc14eb	d58c643c-f89b-4e00-9eed-0a327aa31d89	a056b708-5498-4958-ac30-cfc8934f28c0	2025-12-28 11:34:10.209417
320e9ecd-8d90-4a85-9a65-039beeaf9229	d58c643c-f89b-4e00-9eed-0a327aa31d89	8ebc3049-dbe8-4035-a9e0-989d17388e29	2025-12-28 11:34:10.215047
126784af-71cb-46da-88a2-d3235ae46dbb	d58c643c-f89b-4e00-9eed-0a327aa31d89	c1d358de-6bdd-4d63-87f4-823f3340f74f	2025-12-28 11:34:10.218756
dff2586a-b74e-4e17-a8e5-3e62c77e0872	7c3df960-fa05-40f4-9f76-40c204336f11	a3087408-e5fd-42e8-beb2-b60c007fb547	2025-12-28 11:39:57.915886
c87c610b-9392-4c06-8da2-c1aa3a2671dd	3a9eb180-ee42-4af2-aa44-1716b43a4250	9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	2025-12-28 11:42:41.038748
cca89888-55c5-4629-a1ed-ebc75eaec4eb	3a9eb180-ee42-4af2-aa44-1716b43a4250	3a781eba-9ef8-4acb-bbe0-5dcd0168c022	2025-12-28 11:42:41.04777
99bf840d-0358-43c6-aecc-3f101cbf3401	3a9eb180-ee42-4af2-aa44-1716b43a4250	84dba2e1-306c-40ad-b9f5-c9270c36aba9	2025-12-28 11:42:41.055653
304ba675-8433-4560-b571-2158625caac0	3a9eb180-ee42-4af2-aa44-1716b43a4250	f9b1742b-4dad-4184-a8dc-79b13294f16f	2025-12-28 11:42:41.063657
69284ca2-cc02-4049-ac79-1eff3afe729f	309cd4ac-00bf-4f39-b4ab-7da2738925b8	b51c8d18-dbb1-4e0b-8222-273426920b45	2025-12-28 11:43:32.71748
1249bf6a-3f1f-4826-ad1e-1278cf4775c4	309cd4ac-00bf-4f39-b4ab-7da2738925b8	8a225ddf-ffc3-4017-b409-064b6d3c5fb9	2025-12-28 11:43:32.730053
79e35a53-1d4b-416a-ba0f-378cb90aef13	309cd4ac-00bf-4f39-b4ab-7da2738925b8	8ebc3049-dbe8-4035-a9e0-989d17388e29	2025-12-28 11:43:32.749204
e29c8197-3f91-479b-9cd0-bd8e2299d76d	309cd4ac-00bf-4f39-b4ab-7da2738925b8	95b086c8-b0af-4138-9c70-f2aa1d55d27b	2025-12-28 11:43:32.759748
9a450188-011b-4dbe-9f41-d7aa322a1c16	038d7cf3-3009-4e65-a5f5-ccf16937fa9d	9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	2025-12-28 11:45:53.24791
be458a22-8060-4204-a969-d2a5ede88ca2	038d7cf3-3009-4e65-a5f5-ccf16937fa9d	3a781eba-9ef8-4acb-bbe0-5dcd0168c022	2025-12-28 11:45:53.253962
ea8275dd-a8ed-42ce-a82e-75527963e06a	038d7cf3-3009-4e65-a5f5-ccf16937fa9d	bffa8fe8-abde-4b29-b4af-961217d582f9	2025-12-28 11:45:53.26868
1c5e463c-1209-4f6a-a3f2-0d1757916943	038d7cf3-3009-4e65-a5f5-ccf16937fa9d	278c9a3d-e1a8-4c7b-86ea-3540610316fb	2025-12-28 11:45:53.274194
5ddb5cc7-f4a9-496a-9d46-6fbf2a4dadd3	af90e8fb-7392-4d6e-83a0-1ca407fe3950	9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	2025-12-28 11:48:08.976121
5356b682-d9f2-4472-9d5b-2059fb147d50	af90e8fb-7392-4d6e-83a0-1ca407fe3950	4d8719de-cc0b-46dc-b011-8ec392facf3e	2025-12-28 11:48:08.987382
b9f01d35-90bb-4030-8f4a-a737b698cd3f	af90e8fb-7392-4d6e-83a0-1ca407fe3950	3a781eba-9ef8-4acb-bbe0-5dcd0168c022	2025-12-28 11:48:08.999807
772a8a02-a076-49f0-a525-3c86d1234ec7	af90e8fb-7392-4d6e-83a0-1ca407fe3950	73ab7354-6a7f-4703-9cbf-786ec035ced0	2025-12-28 11:48:09.005856
ae915b64-6762-4074-9e08-afb3c46fa817	aaace7be-4f4e-4d49-83a0-f594ea84a4a7	9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	2025-12-28 11:49:04.650836
f9c246fa-88c2-4cfb-817e-b5ec2e311291	aaace7be-4f4e-4d49-83a0-f594ea84a4a7	4d8719de-cc0b-46dc-b011-8ec392facf3e	2025-12-28 11:49:04.65993
9121d9c7-8260-4fdf-8f6f-685acf88f1f4	aaace7be-4f4e-4d49-83a0-f594ea84a4a7	a4937ea8-1d93-4261-8289-bca21fdeea44	2025-12-28 11:49:04.665262
b178f706-cda2-48ab-b2bd-7f8ff4c8c808	aaace7be-4f4e-4d49-83a0-f594ea84a4a7	61c07533-f42f-4dd2-850e-a68df807a039	2025-12-28 11:49:04.673402
679893ff-d07e-49a3-81d6-6dca58765caf	c2a361b4-cbd9-4eb1-9391-f44b9ac1df79	9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	2025-12-28 11:55:53.853437
f208e43f-685c-4839-8675-f352c000c9ef	c2a361b4-cbd9-4eb1-9391-f44b9ac1df79	3a781eba-9ef8-4acb-bbe0-5dcd0168c022	2025-12-28 11:55:53.861504
845d234d-745c-4370-b17e-9f57932aa2d5	5ca5e0ad-5ded-4660-bf0f-3c173aa1dc4a	8ebc3049-dbe8-4035-a9e0-989d17388e29	2025-12-28 11:58:19.839347
2f61f39e-a9e9-468b-90bc-93a04827122d	5ca5e0ad-5ded-4660-bf0f-3c173aa1dc4a	4d8719de-cc0b-46dc-b011-8ec392facf3e	2025-12-28 11:58:19.8487
00282e9e-3d75-44a5-aa31-53a13a24457c	bf6a6098-7d9b-440b-b3a1-6e04fd08b623	b1a68c08-6c6d-4da4-819e-0285bd4a4e3c	2025-12-28 12:06:43.1596
d0e82520-3fe6-46e1-b55f-92e8ff66914d	bf6a6098-7d9b-440b-b3a1-6e04fd08b623	9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	2025-12-28 12:06:43.17141
de5fe81a-192b-4863-8b59-df9f1763d7c8	bf6a6098-7d9b-440b-b3a1-6e04fd08b623	3a781eba-9ef8-4acb-bbe0-5dcd0168c022	2025-12-28 12:06:43.178371
fa66a1b1-6b24-4fe7-aea7-bb961a5785f8	bf6a6098-7d9b-440b-b3a1-6e04fd08b623	8ebc3049-dbe8-4035-a9e0-989d17388e29	2025-12-28 12:06:43.190289
f139aac9-1c6e-455f-bb37-22e4640c701c	54e5493d-939f-4500-87dc-e68f71e97285	a5d9db23-c34d-46ca-be16-c78cbed8f800	2025-12-28 17:18:05.937027
039d53ff-8033-4a1b-81bf-d1c1d58114bc	54e5493d-939f-4500-87dc-e68f71e97285	bd1853f2-64bd-44d2-afce-e2c705328eb0	2025-12-28 17:18:05.944248
0d59077c-96e4-41f8-9aff-31066dc7183d	54e5493d-939f-4500-87dc-e68f71e97285	780afa94-974b-4460-8647-b0e060905bb5	2025-12-28 17:18:05.951802
7d447e77-0c82-4237-a00b-921b7c213434	54e5493d-939f-4500-87dc-e68f71e97285	99607ff5-b6cd-4ba1-965f-c2e50831103b	2025-12-28 17:18:05.958279
83901dd8-9c19-443a-8cdb-9065edd26aa5	e576c722-bc7b-4cdf-80ae-a7ac967359cf	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-28 17:32:58.76426
e3cf47c4-b813-4256-960c-ee2bb8efa1cb	e576c722-bc7b-4cdf-80ae-a7ac967359cf	39700ae7-4cae-482f-9243-1de20147c866	2025-12-28 17:36:30.754625
43913423-1527-4982-8e47-c83fff37bda0	6cb13ee3-9042-441d-945d-f89119e9221e	39700ae7-4cae-482f-9243-1de20147c866	2025-12-28 17:50:13.4412
1372cc6d-2b2c-454e-9864-f28ace48e593	6cb13ee3-9042-441d-945d-f89119e9221e	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-28 17:50:36.780476
82ea8bb5-5170-4890-a887-f700bb238a8c	fa3fa0a6-82d6-4732-a4a1-7bd2f8f7f67b	b50027b3-72b4-4642-bbe7-8b908c463bea	2025-12-28 17:58:24.272746
5eae449a-da0b-4e10-aafa-a9ceb59462a0	fa3fa0a6-82d6-4732-a4a1-7bd2f8f7f67b	854a955c-7fbd-41cc-afe0-f60b6a1fd055	2025-12-28 17:58:34.895044
88e65f12-d8da-40fb-a442-028294aaea33	fa3fa0a6-82d6-4732-a4a1-7bd2f8f7f67b	e1f5aef3-aa95-47bf-9393-34231874f665	2025-12-28 17:58:34.905436
d0da8166-43b0-405f-af6a-88c42907b5db	fa3fa0a6-82d6-4732-a4a1-7bd2f8f7f67b	b9ddfc70-cb7e-4c9d-a168-0f9cbad9b2a3	2025-12-28 17:58:34.93165
0f607bc6-4c58-4cbd-a3b7-7c99083fa1a6	fa3fa0a6-82d6-4732-a4a1-7bd2f8f7f67b	780afa94-974b-4460-8647-b0e060905bb5	2025-12-28 17:58:34.939382
2bbb18e4-f690-4650-83ab-ac22859ef94c	fa3fa0a6-82d6-4732-a4a1-7bd2f8f7f67b	8d2a8438-5766-42cc-9c06-48d9cc8f0c9e	2025-12-28 17:58:34.954734
306acfe7-c3a0-4154-8884-6740db7e446f	8a701e68-0278-41f9-90cd-fe9432aee03c	854a955c-7fbd-41cc-afe0-f60b6a1fd055	2025-12-28 18:01:18.805118
9b3eb269-7f3c-405a-9169-e5df8983025b	8a701e68-0278-41f9-90cd-fe9432aee03c	95679738-613f-4064-a939-8f823636bc01	2025-12-28 18:01:18.815503
e36877d4-d4b5-4979-8f6a-89421dbeb203	8a701e68-0278-41f9-90cd-fe9432aee03c	44f34509-8e99-47a5-9ba2-2cdad0db2b32	2025-12-28 18:01:18.820736
482d2581-f4c7-424b-a3a4-d3d285a972ce	8a701e68-0278-41f9-90cd-fe9432aee03c	780afa94-974b-4460-8647-b0e060905bb5	2025-12-28 18:01:18.825424
abe51b90-28ac-4c24-b070-76c1e73b26e6	c3517da2-98e6-410d-a1f0-7d8ec139266e	e1f5aef3-aa95-47bf-9393-34231874f665	2025-12-28 18:20:02.867487
30a6eb6e-53fb-4c54-ba82-11234237a5ba	c3517da2-98e6-410d-a1f0-7d8ec139266e	8ebc3049-dbe8-4035-a9e0-989d17388e29	2025-12-28 18:20:02.894353
\.


--
-- Data for Name: contents; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.contents (id, platform, content_id, title, author, description, media_type, file_path, cover_url, source_url, source_type, created_at, task_id, all_images, all_videos, like_count, comment_count, share_count, publish_time, tags, collect_count, view_count, is_missing) FROM stdin;
371801f9-df39-4eec-8177-3106f349123e	bilibili	BV1sqvCBSEBH	看得出她是\\公主/	Huhu安	-	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/看得出她是_公主__BV1sqvCBSEBH	http://i1.hdslb.com/bfs/archive/5749094cfb83566146e31244fbb3de2973f6226b.jpg	https://www.bilibili.com/video/BV1sqvCBSEBH/?-Arouter=story&buvid=XU1385511FED24B6C37D7F7040D8AA0BEFB89&from_spmid=tm.recommend.0.0&is_story_h5=true&mid=rMzHDsgn2jUxDg5x4vHDtw%3D%3D&p=1&plat_id=163&share_from=ugc&share_medium=android&share_plat=android&share_session_id=6cb6d65b-cb1f-4ce2-bae3-fcd7d7d8d684&share_source=COPY&share_tag=s_i&spmid=main.ugc-video-detail-vertical.0.0&timestamp=1766920746&unique_k=JWuXrcD&up_id=284194350	1	2025-12-28 19:25:48.976	\N	[]	["https://b-3a941ad4guqmkj1a5gwi64a8q9h7l5fw95c.edge.mountaintoys.cn:4483/upgcxcode/41/85/35036268541/35036268541-1-192.mp4?e=ig8euxZM2rNcNbRghWdVhwdlhWN1hwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&gen=playurlv3&og=cos&oi=3707349438&deadline=1766928348&platform=pc&trid=0000e9404ae5639c4c32b5f2b87cacbc7c4u&mid=0&os=mcdn&nbs=1&uipk=5&upsig=8d8905dcd8849eec9a5fd011d0ef0bab&uparams=e,gen,og,oi,deadline,platform,trid,mid,os,nbs,uipk&mcdnid=50045820&bvc=vod&nettype=0&bw=1016524&lrs=54&dl=0&f=u_0_0&qn_dyeid=e3c6e27a949c9e07009bd2c7695113bc&agrr=0&buvid=&build=0&orderid=0,3"]	374	33	14	2025-12-28 18:46:41	[]	150	3301	f
52f9f492-f3da-48a8-ad8e-531cbe4799d7	xiaohongshu	694fd004000000001e0247d4	在一个雪天怀念中央公园的春樱🌸	又又YnG	4月最晚追樱花的旧照片 #盛开的樱花林下[话题]# #交换春天[话题]# #纽约[话题]# #纽约樱花[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/在一个雪天怀念中央公园的春樱🌸_694fd004000000001e0247d4	http://sns-webpic-qc.xhscdn.com/202512282047/1d41d3fd59d598307dc6fc69afb16660/1040g00831qjkbqvtg0fg5n4bojnkif5al37mje0!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/694fd004000000001e0247d4?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VDK_psdUjY2rQp342rerqaI=&xsec_source=pc_feed	1	2025-12-28 20:47:25.736	\N	["http://sns-webpic-qc.xhscdn.com/202512282047/1d41d3fd59d598307dc6fc69afb16660/1040g00831qjkbqvtg0fg5n4bojnkif5al37mje0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/ff91ffa1da36f04fd7a8ab4cf78e0479/1040g00831qjkbqvtg0eg5n4bojnkif5a3oktd8g!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/bed9e5c646990d72cc7aff87a7578d87/1040g00831qjkbqvtg0g05n4bojnkif5a5e1hdd0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/81f921f1e9794f37edd76f94bd48d0aa/1040g00831qjkbqvtg0f05n4bojnkif5ar8o08u0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/6ecd3e7e0b7e940273193f47cb4fc9bf/1040g00831qjkbqvtg0e05n4bojnkif5an7k32oo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/eaccb90ed487de3dc93aa2a35ed89c41/1040g00831qjkbqvtg0gg5n4bojnkif5arfum41o!nd_dft_wlteh_webp_3"]	[]	0	0	0	\N	[]	0	0	f
7137ffe8-4a9b-407e-8570-bfccd9c6dbd4	xiaohongshu	6950891c000000001f005c48	Hou er	小圈总	谁知道跳下来还有这么长楼梯要爬啊🥹\n#猴儿天坑[话题]##人间绿宝石[话题]# #山山水水美如画[话题]# #总有些惊奇的际遇[话题]# #开始收藏世界[话题]# #贵州[话题]##这世界的一切都在吸引我[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/Hou_er_6950891c000000001f005c48	http://sns-webpic-qc.xhscdn.com/202512282047/c473d95855f625d12660828dc90211de/notes_pre_post/1040g3k031qkara4n00s05pskenkjjomp9hqqth0!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/6950891c000000001f005c48?xsec_token=ABP7EzTBDBwTZOA7ev6HtZWBqYPCoTNxm_txckhCai5sU=&xsec_source=pc_feed	1	2025-12-28 20:47:36.025	\N	["http://sns-webpic-qc.xhscdn.com/202512282047/c473d95855f625d12660828dc90211de/notes_pre_post/1040g3k031qkara4n00s05pskenkjjomp9hqqth0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/009a2a2f9874e7ef2d2809fef9e45125/notes_pre_post/1040g3k031qkara4n00sg5pskenkjjomp4832eo0!nd_dft_wgth_webp_3"]	[]	0	0	5	\N	[]	0	0	f
4c252ee3-5743-4d4b-bdbf-2414f9d59fe6	xiaohongshu	6950e3b40000000022039704	Cursor 的一年，证明设计师可以直接造产品	药药	#小红书科技AMA[话题]# #科技薯[话题]# #cursor[话题]# #设计师未来[话题]# #用户体验设计[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/Cursor_的一年，证明设计师可以直接造产品_6950e3b40000000022039704	http://sns-webpic-qc.xhscdn.com/202512282047/ff4407f0a1b0380a9d062e74c2808a13/spectrum/1040g0k031qklu6ks0m005n66nd1kds0gt113gt0!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/6950e3b40000000022039704?xsec_token=ABP7EzTBDBwTZOA7ev6HtZWCOevRT5I6PamJ9q-5M5xwQ=&xsec_source=pc_feed	1	2025-12-28 20:47:51.79	\N	["http://sns-webpic-qc.xhscdn.com/202512282047/ff4407f0a1b0380a9d062e74c2808a13/spectrum/1040g0k031qklu6ks0m005n66nd1kds0gt113gt0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/8052650407dc37fb31759012e179c4f2/spectrum/1040g0k031qklu6ks0m0g5n66nd1kds0gn9k4270!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/32354ee37f40e420c7ade5b2d95cd8e7/spectrum/1040g0k031qklu6ks0m105n66nd1kds0gqptf7to!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/e76771d20d9286db60cbefbb76daa108/spectrum/1040g0k031qklu6ks0m1g5n66nd1kds0g1h2c3io!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/da9a738dd50f73114bc1d6f2d3fbb5e8/spectrum/1040g0k031qklu6ks0m205n66nd1kds0gthv54ko!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/31d85ebe1aaf93d327f3d9bce44f0523/spectrum/1040g0k031qklu6ks0m2g5n66nd1kds0g5fodh38!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/3d23cc14be2cfb64edb68fb4c4116e18/spectrum/1040g0k031qklu6ks0m305n66nd1kds0ggu2k020!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/fd254a8324003c57f3cdb1aa6d5f5b77/spectrum/1040g0k031qklu6ks0m3g5n66nd1kds0gkqges78!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/1540f28e6d6cc7f4032ac32d43a43497/spectrum/1040g0k031qklu6ks0m405n66nd1kds0gfdavr0g!nd_dft_wlteh_webp_3"]	[]	0	0	0	\N	[]	0	0	f
63914d30-f4aa-4751-a7c9-56107667508c	xiaohongshu	694d48e1000000001e004420	paranoidpuppy	🐑 ྀི	甜妹必备的波点蝴蝶结耳环跟项链～设计感超足 强推强推～～冲冲冲 #paranoidpuppy饰品[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/paranoidpuppy_694d48e1000000001e004420	http://sns-webpic-qc.xhscdn.com/202512282047/9e3219b04db9fcb43783d67c41daf368/notes_pre_post/1040g3k831qh59q50mu2g5ng1t2sg8lsg88qhr2o!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/694d48e1000000001e004420?xsec_token=AB_yTc4-DAaR3t-JL6ZhYtDEaq_9oMKHk6EAXP8qAqX-g=&xsec_source=pc_feed	1	2025-12-28 20:47:56.997	\N	["http://sns-webpic-qc.xhscdn.com/202512282047/9e3219b04db9fcb43783d67c41daf368/notes_pre_post/1040g3k831qh59q50mu2g5ng1t2sg8lsg88qhr2o!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/cd4a64e1cf92269df66ebcc6cd11538b/notes_pre_post/1040g3k031qh5aa9e70005ng1t2sg8lsgqttb080!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/4d84d3dc3da75c4cf40689745f73f635/notes_pre_post/1040g3k031qh5aa9e700g5ng1t2sg8lsgdr5cvk8!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/3b3dd5356b2a613f7b576630809a10ce/notes_pre_post/1040g3k031qh5aa9e70105ng1t2sg8lsgdk7227o!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282047/de1360668c042289944505aee40d2454/notes_pre_post/1040g3k031qh5aa9e701g5ng1t2sg8lsgr99g3rg!nd_dft_wlteh_webp_3"]	[]	0	9	6	\N	[]	0	0	f
f2637b90-4e9c-439b-901c-dccbef562004	xiaohongshu	6950ee01000000002103c64c	在杭州运河边，挖到烟火气超市与诗意展览	翻斗花园小酱	周末沿运河散步，从拱宸桥拐进世纪联华运河店，瞬间被满屋的生活气包裹💓更惊喜的是，店里竟藏着一个名为 “让生活为了生活” 的治愈系展览✨	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/在杭州运河边，挖到烟火气超市与诗意展览_6950ee01000000002103c64c	http://sns-webpic-qc.xhscdn.com/202512282048/578c0f78f64416d122dcb9352e162840/notes_pre_post/1040g3k831qkn825n0a705nf34pkg8t2mfvs4ib8!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/6950ee01000000002103c64c?xsec_token=ABP7EzTBDBwTZOA7ev6HtZWPFJNR1p5HsGN3vc8obDmb4=&xsec_source=pc_feed	1	2025-12-28 20:48:11.747	\N	["http://sns-webpic-qc.xhscdn.com/202512282048/578c0f78f64416d122dcb9352e162840/notes_pre_post/1040g3k831qkn825n0a705nf34pkg8t2mfvs4ib8!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/e12a2150ff6efa96702bc9ae7f5c2f99/notes_pre_post/1040g3k831qkn825n0a7g5nf34pkg8t2mrn73nlg!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/ed85880296b376be0717928581146fe6/notes_pre_post/1040g3k831qkn825n0a805nf34pkg8t2mjbiofb8!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/5bb54c63203d139355349f4845515aac/notes_pre_post/1040g3k831qkn825n0a8g5nf34pkg8t2m7j8frl0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/e44b3d50ae07f4f66a57180924c9b81e/notes_pre_post/1040g3k831qkn825n0a905nf34pkg8t2m4s9hkbg!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/bf5c9af05db657efcb0699d0d7e34add/notes_pre_post/1040g3k831qkn825n0a9g5nf34pkg8t2mb505ap8!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/6a7d8997720b231403bef1da08c9d19f/notes_pre_post/1040g3k831qkn825n0aa05nf34pkg8t2m5vhgprg!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/d48f1449d2f0ce239ec5aa28d46698e2/notes_pre_post/1040g3k831qkn825n0aag5nf34pkg8t2mpaud9no!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/ffe4e8261eae3ef448585266755c06d5/notes_pre_post/1040g3k831qkn825n0ab05nf34pkg8t2m11uksj8!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/6f4b2fd6bfa87386a5a8295d9b658d13/notes_pre_post/1040g3k831qkn825n0abg5nf34pkg8t2mlm3lgho!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/f1618c08367ae0d61c5a1c052ae7f5cb/notes_pre_post/1040g3k831qkn825n0ac05nf34pkg8t2mfs4h4co!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/0eb117e4956482a8d4e0c61638e239da/notes_pre_post/1040g3k831qkn825n0acg5nf34pkg8t2mnef1628!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/69debf1865778ec07dc27f78a943f1d8/notes_pre_post/1040g3k831qkn825n0ad05nf34pkg8t2mp26db80!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/a6cf6966b2d8fc4f5e62eeecb002b446/notes_pre_post/1040g3k831qkn825n0adg5nf34pkg8t2mnkal6uo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/75ef5505c078baf079853ccd4ac304dc/notes_pre_post/1040g3k031qkn97pmno005nf34pkg8t2mhekp13o!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/cf6b1b489a7bd9ce4b52a58341d5b169/notes_pre_post/1040g3k031qkn97pmno0g5nf34pkg8t2mv44g05g!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/a21944af8c3b03a33d6d0857fc73ce92/notes_pre_post/1040g3k031qkn97pmno105nf34pkg8t2m8qj5ijo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282048/9247bc059c73862a24ae0ad7894373c9/notes_pre_post/1040g3k031qkn97pmno1g5nf34pkg8t2mgvhcbl8!nd_dft_wlteh_webp_3"]	[]	0	0	2	\N	[]	0	0	f
a146302e-6c55-4d27-a21f-0a1132900428	xiaohongshu	6950e830000000002103e36b	旧手机里前女友的照片	水星小狐狸	不知道她最近过的好不好\n#今日分享[话题]# #ootd[话题]# #想回到过去[话题]# #旧照片[话题]# #iPhone5s拍照[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/旧手机里前女友的照片_6950e830000000002103e36b	http://sns-webpic-qc.xhscdn.com/202512282049/6f71394964cd4942f03b4bb644535a77/notes_pre_post/1040g3k831qkmdq3snoe04a6u0o8daj8gs6llrlo!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/6950e830000000002103e36b?xsec_token=ABP7EzTBDBwTZOA7ev6HtZWC4WimNeFyKnlrOaamHdXtQ=&xsec_source=pc_feed	1	2025-12-28 20:49:19.24	\N	["http://sns-webpic-qc.xhscdn.com/202512282049/6f71394964cd4942f03b4bb644535a77/notes_pre_post/1040g3k831qkmdq3snoe04a6u0o8daj8gs6llrlo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/e16a9c44ea7f199913b000ff70f627e9/notes_pre_post/1040g3k831qkmdq3snoeg4a6u0o8daj8ggionf9o!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/e1c8f8a7c530899d8cb2762f33579ea4/notes_pre_post/1040g3k831qkmdq3snof04a6u0o8daj8gqaemoa0!nd_dft_wlteh_webp_3"]	[]	0	0	0	\N	[]	0	0	f
c4a422f2-90a6-46f6-8d31-f970bc74c9fa	xiaohongshu	69509947000000001e0275b5	毛绒绒穿搭🧶	茜茜cici	#短发女孩[话题]# #氛围感对镜拍[话题]# #居家拍照[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/毛绒绒穿搭🧶_69509947000000001e0275b5	http://sns-webpic-qc.xhscdn.com/202512282049/bb216fc770284c156070d030fb4fd03e/notes_uhdr/1040g3qo31qkbfj11009049r482180ja4v0106l0!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/69509947000000001e0275b5?xsec_token=ABP7EzTBDBwTZOA7ev6HtZWHyfTVz43XlLgNgEDBB_uzo=&xsec_source=pc_feed	1	2025-12-28 20:49:33.274	\N	["http://sns-webpic-qc.xhscdn.com/202512282049/bb216fc770284c156070d030fb4fd03e/notes_uhdr/1040g3qo31qkbfj11009049r482180ja4v0106l0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/5e1ce9be12d6b0176bbef8390ea484a9/notes_uhdr/1040g3qo31qkbfj11009g49r482180ja4586gee8!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/99d42f3f34442d2f1629326cb0a94f89/1040g00831qkbaqck002049r482180ja4k2g8cjo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/e6f89bfb10f2056d54d5f737bf31a1fc/1040g00831qkbaqck002g49r482180ja4lo1tpro!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/34f2906c99c9a3dfa1cb9a54f79ed630/1040g00831qkbaqck003g49r482180ja4j9ot568!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282049/7cb1f859b795128a425f2baa76037598/1040g00831qkbaqck003049r482180ja45ecsbbg!nd_dft_wlteh_webp_3"]	[]	0	0	0	\N	[]	0	0	f
1f286c3f-d383-45e0-bf82-bf140c6674f2	xiaohongshu	695138b90000000022008005	我的年度📷🌟	Fanny巴黎蜜桃（在港）	#fyp[话题]# #年度报告[话题]# #小红书年度报告[话题]# #年度关键帧[话题]# #美女[话题]# #万能的小红书[话题]# #微胖穿搭[话题]# #来拍照了[话题]# #旅游编辑部[话题]# #回顾这一年[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/我的年度📷🌟_695138b90000000022008005	http://sns-webpic-qc.xhscdn.com/202512282329/c2e1f5863ad2b26f44d65eb23b53ade7/notes_pre_post/1040g3k031ql07n5s7u005p4753jk80901qf6hj0!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/695138b90000000022008005?xsec_token=ABYq2IFxLjVZY2lIL2zdYiPHDoopc9wCRmPzfPzIqZCC0=&xsec_source=pc_feed	1	2025-12-28 23:29:50.785	\N	["http://sns-webpic-qc.xhscdn.com/202512282329/c2e1f5863ad2b26f44d65eb23b53ade7/notes_pre_post/1040g3k031ql07n5s7u005p4753jk80901qf6hj0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/61512e492cc4bb403a988cc5482b8391/notes_pre_post/1040g3k031ql07n5s7u205p4753jk8090vidbjco!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/61d73f4f35e7e65527beca0f968f05ae/notes_pre_post/1040g3k031ql07n5s7u0g5p4753jk80909poaqko!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/71a8039185d292774fd9fe257880bee9/notes_pre_post/1040g3k031ql07n5s7u105p4753jk8090s0crtco!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/a69f75cac6e6c0f252633c8fe0de00e6/notes_pre_post/1040g3k031ql07n5s7u1g5p4753jk8090ms30gjo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/ae1723d21a11a3332bf2bd486dfe9ea7/notes_pre_post/1040g3k031ql07n5s7u2g5p4753jk8090j18imeo!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/7d7316f5d53c5a8d0b554327421703d8/notes_pre_post/1040g3k031ql07n5s7u3g5p4753jk8090pvsuet0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/26b1050e021d5f923be576f28a137cbe/notes_pre_post/1040g3k031ql07n5s7u305p4753jk80904ehr460!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/33a3927fc896af476bc95f6334ce6819/notes_pre_post/1040g3k031ql07n5s7u405p4753jk8090gc8b4l0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/471c7bd52079d31444d78f347d0ee9d5/notes_pre_post/1040g3k031ql07n5s7u505p4753jk8090uik0u90!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/d107a5693ad74dc015b87d09a720ec28/notes_pre_post/1040g3k031ql07n5s7u4g5p4753jk8090su0vldg!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/7af291749408a9447b5fb719c11dd7ed/notes_pre_post/1040g3k031ql07n5s7u5g5p4753jk80907fh9bno!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/e727febe86816b8e56af887b4461530e/notes_pre_post/1040g3k031ql07n5s7u605p4753jk8090sb1aqug!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/a5a81dc07154f23357f848eb89d0fd3a/notes_pre_post/1040g3k031ql09sknnolg5p4753jk8090sjc4b20!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/fe1deb858d9149a53f3d2d62538365c5/notes_pre_post/1040g3k031ql09sknnol05p4753jk8090m900d40!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512282329/e3353e5e02d8ad4b00aeaa657e5f2cd0/notes_pre_post/1040g3k031ql07n5s7u6g5p4753jk8090bj4c8s8!nd_dft_wlteh_webp_3"]	[]	0	7	6	\N	[]	0	0	f
b01748a9-9273-4d0f-8789-55c12083ee1d	xiaohongshu	69510823000000001f009846	天老爷哇，太显瘦了吧耶～焊在身上	苡沫	#一穿一个不吱声[话题]# #怎么穿都不腻[话题]# #一穿就变美[话题]# #显高显廋显腿长[话题]# #把喜欢的感觉穿在身上[话题]# #简单舒适不挑人[话题]# #穿起来非常的好看[话题]# #穿出小蛮腰[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/天老爷哇，太显瘦了吧耶～焊在身上_69510823000000001f009846	http://sns-webpic-qc.xhscdn.com/202512282332/d352142ad9ad838855bc7ec5b000061d/1040g00831qkqbikdga005obnrcs0jbpt0n9mdlg!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/69510823000000001f009846?xsec_token=ABYq2IFxLjVZY2lIL2zdYiPEdIczmxOuNmGV5b3jnJH2g=&xsec_source=pc_feed	1	2025-12-28 23:32:12.314	\N	["http://sns-webpic-qc.xhscdn.com/202512282332/d352142ad9ad838855bc7ec5b000061d/1040g00831qkqbikdga005obnrcs0jbpt0n9mdlg!nd_dft_wlteh_webp_3"]	["http://sns-video-hs.xhscdn.com/stream/1/110/258/01e95108221d5eaf010370019b648805c7_258.mp4"]	0	0	3	\N	[]	0	0	f
\.


--
-- Data for Name: crawl_tasks; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.crawl_tasks (id, name, platform, target_identifier, frequency, status, last_run_at, next_run_at, config, created_at) FROM stdin;
49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87?m_source=pwa	10min	1	2025-12-29 02:00:00.279	2025-12-29 02:10:00.279	{"cookie":null,"useDownloader":true}	2025-12-24 01:09:35.350335
\.


--
-- Data for Name: hotsearch_snapshots; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.hotsearch_snapshots (id, platform, capture_date, capture_time, snapshot_data, created_at) FROM stdin;
\.


--
-- Data for Name: platform_accounts; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.platform_accounts (id, platform, account_alias, cookies_encrypted, is_valid, last_checked_at, created_at) FROM stdin;
\.


--
-- Data for Name: platform_cookies; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.platform_cookies (id, platform, account_alias, cookies_encrypted, is_valid, last_checked_at, created_at, preferences) FROM stdin;
1216e570-fe8a-4ab2-83ec-7ca2cca34eb5	xiaohongshu	小红书	6b091691120c1181798df807d1b33f29:454e4329ccb5ef10a4810cd351567b1908ab3061a95781ccc66a2f2bb4754b3e0668f87addc777b16282926e953565a0f60145eeb15c690a6ee78d296e9c2883feae191db839ff113fd9b9362ff41079c390bd6a66ccf0387671b6253b06c4b057a39a4c625f7fa54d1a929a2f69ca33cea3a054e9f9c63e8b88ebcdc41462c897c5afba43a32be5b973628dc027d429abfc53906cd95e14ecefc5a8f668bfe82b9607e056277da5d136f44d4f48baee876ab286c3c60a5a715ca208cac2dc9db958837dec8a778561dbc2e37fb98d131e3f1f08d9811218fc4a506a1cabf7546229b48aa88bbbe53e50044671fd5b3a2c4dc5cbca1dc7ebb88ca13ac780c785440aada1c324a3adffa41d29236e976ab8ec3ecce5b9526d8cc45daca59822956b527a4e4aac669f0d681c07356175f256133479cc124cfe998795a43e0bc23a5c6ed5183dc5b51f9f941f729fa579d137341a27da1519bf3a2553bc916b343c2d00e5de5151135c50c8d7c73568b160ee58485fcbaaf551b1715e1dcc94d59a4fc07ed784516254d9c1ca4476df6ce248eff713a6085aac5987322f10734feda72988cccee1d2fa6f43edd699647e2edc632f52642ec4d8d42185b45b057337776aa93351fa9b80b84d6a5a0594a5184e4ad9a3e394252f20ebd9ed4f99719b020d992004c827aa816d1d0396dbe6b7f7fa49d146b07133006d6495dda6d0a8557684ac02916131e9956ed10d68336ccb8d9ad5be070a9f601d9fe5743c3e1504ecce05081e2442dd3aa9c5055478f68281435a103a0dff862e05373eaaccdb63e5ead470d6b98072a826074e0cbb331110ff9cc19d97852543814b4f0ab874c3db73a3ca5310542e6ee7516c7d6534e47977b63c76d0ea34014bf6c6beb519a1723e5bfe7630a75dc8e5efef53cfb4acea388a183e7796fe612a3a388860520a38df0ba42e10f0d27a3a891f0054ebe440ae6c8ba459f19ac0ebbf64a124d8d30584b8da520835272074bf4a9e7da013f4d7c2ea5d67d7d345ad9f81e9ec86b216f4a6905c98d1ab39eaf6062c2b441776664c96ee46f41db090990ad5ec79919a587dbf37125057a8f475fc2c1aeb606967aa81ab85f5936eae2c6e2b1e80f3e0b1287d52c94ab7026d887b88d52d614e3cbe6600a7642f2d9f6b32861681212dd7afb3f198b7434e7d8e1be97178268bcc22a09470ffef597cd2961411378075ecddedee6b16c9467fa06a2defe764411c7cb5f1c6f555e2265564716e14	f	2025-12-28 00:43:35.338	2025-12-28 00:26:41.599	\N
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.system_settings (id, storage_path, task_schedule_interval, hotsearch_fetch_interval, updated_at) FROM stdin;
0a4f0d0a-798a-4b90-9f54-11f78c7ab5fc	/test/path/	1800	1800	2025-12-23 20:09:28.33044
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.tags (id, name, color, description, usage_count, created_at, updated_at) FROM stdin;
deacecf9-a0c5-48b0-b6ca-d529b0fb2aaa	睡眠	#faad14	\N	1	2025-12-28 00:58:50.317456	2025-12-28 00:58:50.317456
e1633aad-1323-4839-8297-a7ef62e04423	校园活动	green	AI自动生成 (主题标签, 置信度: 95%)	0	2025-12-28 11:34:10.193243	2025-12-28 11:34:10.193243
a056b708-5498-4958-ac30-cfc8934f28c0	音乐表演	magenta	AI自动生成 (主题标签, 置信度: 90%)	0	2025-12-28 11:34:10.205926	2025-12-28 11:34:10.205926
c1d358de-6bdd-4d63-87f4-823f3340f74f	女高	volcano	AI自动生成 (细节标签, 置信度: 80%)	0	2025-12-28 11:34:10.217135	2025-12-28 11:34:10.217135
a3087408-e5fd-42e8-beb2-b60c007fb547	美女	#eb2f96	\N	50	2025-12-28 01:32:02.674012	2025-12-28 01:32:02.674012
84dba2e1-306c-40ad-b9f5-c9270c36aba9	平价	green	AI自动生成 (细节标签, 置信度: 99%)	0	2025-12-28 11:42:41.052863	2025-12-28 11:42:41.052863
f9b1742b-4dad-4184-a8dc-79b13294f16f	震惊	purple	AI自动生成 (情感标签, 置信度: 90%)	0	2025-12-28 11:42:41.059018	2025-12-28 11:42:41.059018
b51c8d18-dbb1-4e0b-8222-273426920b45	旅游	volcano	AI自动生成 (主题标签, 置信度: 95%)	0	2025-12-28 11:43:32.710085	2025-12-28 11:43:32.710085
8a225ddf-ffc3-4017-b409-064b6d3c5fb9	摄影	orange	AI自动生成 (主题标签, 置信度: 90%)	0	2025-12-28 11:43:32.725394	2025-12-28 11:43:32.725394
95b086c8-b0af-4138-9c70-f2aa1d55d27b	氛围感	cyan	AI自动生成 (细节标签, 置信度: 80%)	0	2025-12-28 11:43:32.755807	2025-12-28 11:43:32.755807
bffa8fe8-abde-4b29-b4af-961217d582f9	白色	blue	AI自动生成 (细节标签, 置信度: 95%)	0	2025-12-28 11:45:53.2588	2025-12-28 11:45:53.2588
278c9a3d-e1a8-4c7b-86ea-3540610316fb	治愈	orange	AI自动生成 (情感标签, 置信度: 80%)	0	2025-12-28 11:45:53.271929	2025-12-28 11:45:53.271929
73ab7354-6a7f-4703-9cbf-786ec035ced0	清冷感	cyan	AI自动生成 (细节标签, 置信度: 80%)	0	2025-12-28 11:48:09.003344	2025-12-28 11:48:09.003344
a4937ea8-1d93-4261-8289-bca21fdeea44	日常	magenta	AI自动生成 (风格标签, 置信度: 90%)	0	2025-12-28 11:49:04.662217	2025-12-28 11:49:04.662217
61c07533-f42f-4dd2-850e-a68df807a039	自拍	lime	AI自动生成 (风格标签, 置信度: 80%)	0	2025-12-28 11:49:04.670059	2025-12-28 11:49:04.670059
4d8719de-cc0b-46dc-b011-8ec392facf3e	健身	orange	AI自动生成 (主题标签, 置信度: 85%)	2	2025-12-28 11:48:08.98365	2025-12-28 11:48:08.98365
b1a68c08-6c6d-4da4-819e-0285bd4a4e3c	滑雪	volcano	AI自动生成 (主题标签, 置信度: 95%)	0	2025-12-28 12:06:43.15285	2025-12-28 12:06:43.15285
9c23cbf1-dcdc-436b-9f91-d7e4f901c46e	穿搭	blue	AI自动生成 (主题标签, 置信度: 98%)	5	2025-12-28 11:42:41.033462	2025-12-28 11:42:41.033462
3a781eba-9ef8-4acb-bbe0-5dcd0168c022	种草	red	AI自动生成 (风格标签, 置信度: 95%)	4	2025-12-28 11:42:41.044269	2025-12-28 11:42:41.044269
a5d9db23-c34d-46ca-be16-c78cbed8f800	理财规划	gold	AI自动生成 (主题标签, 置信度: 95%)	0	2025-12-28 17:18:05.928575	2025-12-28 17:18:05.928575
bd1853f2-64bd-44d2-afce-e2c705328eb0	APP推荐	purple	AI自动生成 (风格标签, 置信度: 90%)	0	2025-12-28 17:18:05.941762	2025-12-28 17:18:05.941762
99607ff5-b6cd-4ba1-965f-c2e50831103b	原创	cyan	AI自动生成 (细节标签, 置信度: 80%)	1	2025-12-28 11:32:06.14677	2025-12-28 11:32:06.14677
39700ae7-4cae-482f-9243-1de20147c866	微调大模型	#52c41a	\N	2	2025-12-28 17:33:09.644566	2025-12-28 17:33:09.644566
b50027b3-72b4-4642-bbe7-8b908c463bea	AI学习	#9254de	\N	13	2025-12-27 21:11:45.505105	2025-12-27 21:29:46.698
b9ddfc70-cb7e-4c9d-a168-0f9cbad9b2a3	分析	gold	AI自动生成 (风格标签, 置信度: 92%)	0	2025-12-28 17:58:34.917968	2025-12-28 17:58:34.917968
8d2a8438-5766-42cc-9c06-48d9cc8f0c9e	深度	lime	AI自动生成 (细节标签, 置信度: 85%)	0	2025-12-28 17:58:34.947673	2025-12-28 17:58:34.947673
854a955c-7fbd-41cc-afe0-f60b6a1fd055	科技	gold	AI自动生成 (主题标签, 置信度: 95%)	2	2025-12-28 11:32:06.116131	2025-12-28 11:32:06.116131
95679738-613f-4064-a939-8f823636bc01	测评	cyan	AI自动生成 (风格标签, 置信度: 90%)	0	2025-12-28 18:01:18.810951	2025-12-28 18:01:18.810951
44f34509-8e99-47a5-9ba2-2cdad0db2b32	教程	magenta	AI自动生成 (风格标签, 置信度: 90%)	1	2025-12-28 11:32:06.126799	2025-12-28 11:32:06.126799
780afa94-974b-4460-8647-b0e060905bb5	干货	magenta	AI自动生成 (风格标签, 置信度: 85%)	3	2025-12-28 11:32:06.139889	2025-12-28 11:32:06.139889
e1f5aef3-aa95-47bf-9393-34231874f665	产品	green	AI自动生成 (主题标签, 置信度: 90%)	1	2025-12-28 17:58:34.901273	2025-12-28 17:58:34.901273
8ebc3049-dbe8-4035-a9e0-989d17388e29	生活记录	gold	AI自动生成 (风格标签, 置信度: 85%)	4	2025-12-28 11:34:10.211477	2025-12-28 11:34:10.211477
\.


--
-- Data for Name: task_logs; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.task_logs (id, task_id, task_name, platform, start_time, end_time, status, type, result, error, crawled_count, new_count, updated_count, execution_time) FROM stdin;
84b92f0b-869b-4770-8e76-9fae7c31d293	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 20:50:00.96	\N	running	author	\N	\N	0	0	0	0
3a7e8275-3c09-45b8-8bab-16941197d693	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 01:14:10.473	2025-12-24 01:14:16.25	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5777
3507d655-6826-458f-a660-d2c4a5bd3f68	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 01:20:00.945	2025-12-24 01:20:04.158	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3213
4462ddce-7837-4d9a-8b44-bda6f6cd8505	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 01:30:00.931	2025-12-24 01:30:04.28	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3350
2b074c36-6878-4439-a6c1-98c18985822d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 01:40:00.865	2025-12-24 01:40:04.256	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3392
c0cf57cb-a894-4482-96ce-d3bcdda6d722	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 01:50:00.792	2025-12-24 01:50:03.944	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3153
fea8c34f-993d-4e55-80b8-bf9d3c5779da	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 02:00:00.743	2025-12-24 02:00:03.931	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3188
ffb26ead-b321-4fdb-8838-cfbded38030f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 02:10:00.672	2025-12-24 02:10:04.005	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3334
deb39077-0b64-486e-a709-4e705b88965c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 02:20:00.626	2025-12-24 02:20:03.088	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2463
a34b3c5b-0214-47b8-9876-a1592f74e9d2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 02:30:00.564	2025-12-24 02:30:06.066	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5503
f8ee2f89-e448-4fd1-84a7-9dc36eca61f4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 02:40:00.524	2025-12-24 02:40:06.355	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5831
5e1cdd67-7676-485d-8fdc-d48085550684	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 02:50:00.451	2025-12-24 02:50:02.444	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	1994
3bbd6f57-c0be-4be2-9d98-60638d72ffa0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 03:00:00.371	2025-12-24 03:00:06.265	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5894
09d295bd-9d5f-4c76-a61e-286c5503f752	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 03:10:00.318	2025-12-24 03:10:05.676	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5358
18ac57bc-4f92-4322-968e-a6941853297b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 03:20:00.277	2025-12-24 03:20:05.898	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5621
3a84501a-75c6-416a-863d-7e16eeb3cd63	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 03:30:00.164	2025-12-24 03:30:05.763	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5600
d37576b4-e377-4de2-a6b1-395f47eca32c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 03:40:00.069	2025-12-24 03:40:05.687	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5618
e3b8a3dc-8e53-416a-9829-60e68e1987da	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 03:50:00.012	2025-12-24 03:50:05.642	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5630
123ad03e-9b8f-40e0-bfee-0b07541dcbb8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 04:00:00.997	2025-12-24 04:00:06.569	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5573
74f395a3-0713-4342-9d84-797f2ea74ff9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 04:10:00.971	2025-12-24 04:10:06.546	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5576
b6dd6cf9-da20-4710-ad06-c5d60e14fd85	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 04:20:00.92	2025-12-24 04:20:06.589	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5670
363ed4fb-1f40-45e1-b1c5-f511790df20c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 04:30:00.823	2025-12-24 04:30:06.474	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5651
19600762-0233-4fe0-a21c-9f216422bbc4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 04:40:00.762	2025-12-24 04:40:03.031	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2269
8d6ef9ba-81ba-45a9-9a29-8270341c050f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 04:50:00.659	2025-12-24 04:50:06.318	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5659
91052961-4aab-4846-a7c2-6b43d1d5b980	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 05:00:00.61	2025-12-24 05:00:06.165	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5555
751c839c-551a-4153-a3a8-c789f4836a7b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 05:10:00.511	2025-12-24 05:10:06.183	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5672
a8e65f25-8e7d-49ff-ae2c-cb9c1c986f14	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 05:20:00.485	2025-12-24 05:20:06.377	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5892
12b00670-f6d4-4079-892a-673f007fcc02	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 05:30:00.468	2025-12-24 05:30:06.072	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5604
02142ce6-93f1-4e1c-bd2f-45f8729f48c6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 05:40:00.403	2025-12-24 05:40:06.056	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5653
540622e3-693e-40e9-bf83-49f6a1671264	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 05:50:00.263	2025-12-24 05:50:05.977	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5714
3a29bdb4-1432-4ac4-a243-f6cce85e5a91	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 06:00:00.225	2025-12-24 06:00:05.79	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5565
677e4baf-4062-4e7e-9244-238fb6350fff	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 06:10:00.19	2025-12-24 06:10:06.196	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6006
368501fe-a376-420a-ae67-090650327a24	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 06:20:00.133	2025-12-24 06:20:05.834	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5702
d2a71749-f314-46ed-94bb-bfa9e6c0ffd4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 06:30:00.081	2025-12-24 06:30:05.825	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5745
a1a3dfd2-8983-4193-ab3b-2be48c93103d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 06:40:00.017	2025-12-24 06:40:02.229	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2212
7f365766-6388-48f4-82d2-e8365bb9efcd	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 06:50:00.983	2025-12-24 06:50:06.506	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5523
1174d229-0e85-4684-a1eb-2d71574043be	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 07:00:00.937	2025-12-24 07:00:06.653	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5717
a4a5041a-80c6-4981-8f71-527e12a2c083	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 07:10:00.863	2025-12-24 07:10:06.465	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5602
fde7b08e-bb80-4460-ad68-fb79312b075f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 07:20:00.792	2025-12-24 07:20:06.373	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5582
9b64f2a2-4ce9-4208-81ff-e48425ded2f4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 07:30:00.735	2025-12-24 07:30:02.986	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2251
cc361fbb-62b5-4790-a7d6-6dba8750ec99	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 07:40:00.678	2025-12-24 07:40:06.209	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5531
6e287f42-96c9-46f0-a4b3-36f1a7db53bc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 07:50:00.64	2025-12-24 07:50:02.881	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2241
776ac0a6-934c-432a-95d7-627c5d025239	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 08:00:00.448	2025-12-24 08:00:00.79	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	342
b1b7b427-ae4b-42e5-b50d-6ed992515f1c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 08:30:00.466	2025-12-24 08:30:00.781	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	315
a7fc0794-c2e5-4381-8988-ff979e06f817	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 08:50:00.827	2025-12-24 08:50:04.033	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3207
493c841d-49f6-47ff-9f82-3a26d312db62	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 13:00:00.195	2025-12-24 13:00:30.729	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30534
cab9f820-111b-4dd8-aed7-008e99deac91	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 09:00:00.244	2025-12-24 09:00:03.451	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3207
74694b0a-2747-474b-836d-9587671da2a1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 13:10:00.093	2025-12-24 13:10:30.655	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30564
f467d492-ee27-4f22-8c81-47fa459112aa	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 09:10:00.752	2025-12-24 09:10:03.844	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3092
18b4cd2d-2b13-46d5-bfec-baa033c8459e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 13:20:00.718	2025-12-24 13:20:31.334	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30616
66c5aee3-8d48-4496-924e-f65e593dd272	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 09:30:00.535	2025-12-24 09:30:03.641	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3107
82e51c33-4b7b-420b-91c0-7fed7e247fe0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 13:30:00.564	2025-12-24 13:30:31.329	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30766
88a632d2-89ac-40b2-9045-a4ed8ce32704	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 09:40:00.428	2025-12-24 09:40:03.889	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3461
aecd7cdc-2126-42d1-9f2c-3711f4333d8f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 13:40:00.013	2025-12-24 13:40:30.388	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30377
4b3b9b9a-8bad-4e0e-a64c-3cf610c5fa70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 09:50:00.051	2025-12-24 09:50:03.269	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3218
e8703200-6848-475f-9ef7-2b8b0b810c35	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 13:50:00.303	2025-12-24 13:50:30.72	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30417
1dab16d4-97da-41ba-9d20-b7e1ea9ef45f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 10:00:00.823	2025-12-24 10:00:04.04	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3217
5d757944-5ebe-4e6e-9cf6-e96d26c38f8d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 14:00:00.947	2025-12-24 14:00:13.001	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	12054
1544fdca-5e46-4f22-a8ac-909ddc437e4f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 10:10:00.56	2025-12-24 10:10:03.759	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3200
d2839cd7-c094-462f-b271-64f810b072c7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 14:10:00.29	2025-12-24 14:10:30.922	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30632
7229f9f4-2553-4af1-9e8c-a083a49913d6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 10:30:00.567	2025-12-24 10:30:03.776	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3209
0b4936f4-eead-4192-9881-3317fada4d27	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 14:20:00.107	2025-12-24 14:20:10.095	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	9988
aa1d005d-9a0d-40d5-ac5a-15309a558a91	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 10:40:00.837	2025-12-24 10:40:04.027	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3190
65fda21c-eb40-4606-8bf3-6d3df6d0a29f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 14:30:00.036	2025-12-24 14:30:30.466	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30430
528829b2-f134-4f4f-bef5-e04287d3ebd7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 10:50:00.13	2025-12-24 10:50:03.599	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3469
0c955110-7ce8-40be-a7e0-d1f38a838aeb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 14:40:00.182	2025-12-24 14:40:30.544	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30363
3c42bfde-94be-45be-8376-ebbd8382dda1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 11:00:00.578	2025-12-24 11:00:03.918	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3341
4efd7d46-a144-4090-a9ae-a57dc9b63acf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 14:50:00.121	2025-12-24 14:50:30.507	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30386
c3caf512-e87b-4e5d-958b-6eb893823f76	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 11:10:00.967	2025-12-24 11:10:05.29	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4323
bfa84703-7942-46a5-ad98-d13c817390df	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 15:00:00.108	2025-12-24 15:00:30.552	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30444
78e18702-5e28-4ce7-8868-f5f74d3616c7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 11:20:00.866	2025-12-24 11:20:04.266	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3400
f6e3b970-af18-4639-acc3-3db63ffd68cc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 15:10:00.08	2025-12-24 15:10:30.47	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30390
60e9bc13-4497-4fb8-a454-1ca7ffda4dd4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 11:30:00.191	2025-12-24 11:30:03.659	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3468
6dc92750-ad79-4d79-a10d-2cd981ffa163	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 15:20:00.056	2025-12-24 15:20:30.43	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30374
2b5ac513-17de-49c9-8d65-0887cc9d167d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 12:40:00.988	2025-12-24 12:40:15.282	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	14296
240a4fcc-15a9-45d4-9e32-931e656e3746	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 15:30:00.026	2025-12-24 15:30:30.46	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30434
a85ee971-7ffe-4867-98cf-bbc1c7eb79b6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 12:50:00.066	2025-12-24 12:50:36.923	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	36858
bd5fca9b-1fe7-4bd5-81f4-135b4e3d35d8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 15:40:00.035	2025-12-24 15:40:30.4	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30365
05c01fcd-7bb0-4b72-a302-1ad08c04dea8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 20:30:00.42	2025-12-24 20:30:00.708	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	288
43bffb6e-e341-4d36-ab8c-bb9dcf0bf53a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 22:00:00.001	2025-12-24 22:00:07.877	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	7876
4077018f-3501-45fe-9adf-9eb8fffd56a5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 22:10:00.563	2025-12-24 22:10:07.837	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	7274
e93f460b-aec1-4e3e-b840-8c596190ae11	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-24 22:30:00.46	2025-12-24 22:30:07.306	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6846
b6745c4c-76ac-4e51-b28a-b7216b6e2d2a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 08:00:00.594	2025-12-25 08:00:31.196	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30603
9ab51c52-4cc9-4f41-b137-2ef6d0db8415	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 09:00:00.108	2025-12-25 09:00:00.441	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	333
df598a81-5102-4eb1-b2d7-55562adeb277	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 09:20:00.779	2025-12-25 09:20:13.356	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	12577
909a14d4-ada8-4452-987b-d992b46936a8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 10:30:00.432	2025-12-25 10:30:01.065	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	633
b9087505-c6a8-493c-a1d7-1be2f385e05d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 15:20:00.908	2025-12-25 15:20:06.625	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5718
dace4b43-1160-44c1-bcbf-6a50dc3be9d6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 15:30:00.61	2025-12-25 15:30:04.031	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3422
5e7b5db3-5cbd-46cf-b1dd-5e6598437b43	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 15:40:00.265	2025-12-25 15:40:09.552	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	9288
0f4a61f1-6fe7-4139-9c9e-7dbec43e16c0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 15:50:00.973	2025-12-25 15:50:04.269	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3297
cf054352-c6f9-46d1-b92c-e583a5a3fb3e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:40:00.604	2025-12-27 22:40:03.084	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2480
c2c95bc1-7bc9-41f1-a6bd-2698ff34f794	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:00:00.52	2025-12-26 21:00:03.997	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3478
5201a200-a995-42d7-8a32-a3c801cd3bfc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:30:00.98	2025-12-27 01:30:04.151	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3171
6f3b8ac5-2532-4f91-a853-9ffc167bc1a1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 19:00:00.604	2025-12-28 19:00:03.973	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3369
6ca12da3-300b-4daf-b0df-ce119a8da187	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:30:00.893	2025-12-27 10:30:04.564	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3673
6e43ef03-060f-4ed2-a933-cb39da0602e2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:40:00.737	2025-12-28 01:40:04.194	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3457
b4fc72c9-c7e0-43db-a6d0-b2602e3668a8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:10:00.512	2025-12-27 15:10:03.776	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3264
a5206fa4-6db3-4e3a-84eb-1e62181940d3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:00:00.927	2025-12-27 18:00:04.732	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3806
0082d6db-8dc0-4d9b-9f24-527b11ed555f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 04:30:00.78	2025-12-28 04:30:02.924	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2144
409d90cd-74ed-4332-a84d-64ad18ccdbff	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:50:00.51	2025-12-27 20:50:04.674	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4164
f0108404-b843-46d3-8e30-50ef87b925db	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 21:40:00.645	2025-12-28 21:40:04.004	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3361
d2793f4a-361f-427b-b2c0-1a7b637a64ed	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 07:20:00.033	2025-12-28 07:20:03.746	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3713
5936d93d-1d44-4d60-be38-933092187a66	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 10:10:00.036	2025-12-28 10:10:03.174	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3139
e95952ba-54c3-4ea4-ac1e-fc53aaf8a8d9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 00:30:00.673	2025-12-29 00:30:03.387	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2715
b20c8f85-9f39-431a-a517-6c069cd3c629	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 13:40:00.324	2025-12-28 13:40:04.829	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4506
fde46846-9f8c-43be-8056-13fad94d47f4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 16:30:00.842	2025-12-28 16:30:04.489	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3647
d37074c4-6bc4-4fd1-b6f2-b2c744fd9771	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:00:00.608	2025-12-25 16:00:03.811	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3204
30f5c9f9-15ae-41fd-8ec0-a4838321d032	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:10:00.683	2025-12-26 21:10:04.403	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3722
e91c51b7-c66b-484e-8096-98c4d677793d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:50:00.571	2025-12-27 22:50:03.164	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2593
7a31a4b3-ae70-4526-b660-9d9ea9d3abf2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:40:00.914	2025-12-27 01:40:04.164	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3250
881cac2b-c5d1-4734-a315-5c7d01049947	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 19:10:00.306	2025-12-28 19:10:03.165	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2859
0b549efb-3e01-4db9-a0d9-ddbfd629ca67	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:40:00.842	2025-12-27 10:40:03.953	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3112
3b179ec6-4bff-49b6-b463-22c09c11678b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:50:00.453	2025-12-28 01:50:03.67	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3218
1f28807f-10f5-46d3-a0f4-4604698fe11a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:20:00.166	2025-12-27 15:20:03.462	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3297
a6c40ac4-987b-4bcb-b228-f87473835df0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:10:00.64	2025-12-27 18:10:06.06	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5420
03f6500a-19dc-4795-b549-f70e2c9c9ec6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 04:40:00.78	2025-12-28 04:40:04.261	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3482
cfe611f3-4aa8-4131-ac43-926eca2faad8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:00:00.291	2025-12-27 21:00:04.421	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4131
de499f95-2ec0-4407-9f0c-956d172f0a0a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 21:50:00.541	2025-12-28 21:50:04.312	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3772
5136d59a-1e3a-49e4-b9b8-a40b9afb2e11	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 07:30:00.021	2025-12-28 07:30:03.357	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3336
061158b3-c9b0-44e7-99ea-6832570e493f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 10:20:00.79	2025-12-28 10:20:04.777	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3987
7b0ea123-2c59-4e7c-9ac0-3e812457d95d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 00:40:00.425	2025-12-29 00:40:07.576	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	7152
b46e40e6-c994-44c7-af38-f116672ed969	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 13:50:00.383	2025-12-28 13:50:03.793	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3410
66d7efbf-c8ce-40a9-b0bf-5b46eaeb2ea0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 16:40:00.653	2025-12-28 16:40:03.84	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3187
17183c74-3843-4eaf-89f3-2b70e360f1db	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:10:00.271	2025-12-25 16:10:04.669	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4399
d8d532ea-869f-4be7-b548-b7a7804b0ad7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:20:00.507	2025-12-26 21:20:04.115	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3608
f985fae8-e14f-408b-a739-df010f75b94e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:00:00.651	2025-12-27 23:00:04.399	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3748
1910f4b6-da0f-421a-bd31-b6ad769be729	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:50:00.848	2025-12-27 01:50:04.058	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3211
a8886cb6-3a26-4af2-8b17-781e2de5aee0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 19:20:00.15	2025-12-28 19:20:03.756	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3607
993bd118-4c10-43cc-8ee0-76e7562d87ca	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:20:00.853	2025-12-27 11:20:04.687	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3835
50a69929-783e-42ac-a8bf-9af78a06ea70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:00:00.597	2025-12-28 02:00:03.801	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3204
76e07e8d-f02b-4313-97f1-65e7d96f9c1a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:30:00.863	2025-12-27 15:30:04.089	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3227
0347cb5c-038c-42ba-b2af-8288aed4ae76	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:20:00.763	2025-12-27 18:20:04.424	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3662
e0a55c29-8e82-4012-8867-685ac262a998	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 04:50:00.884	2025-12-28 04:50:05.063	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4179
f525da68-85a2-448d-8402-46c7f0285c7a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:10:00.003	2025-12-27 21:10:03.89	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3887
d8ffffe8-ab17-43b6-9e06-ae69703393d2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 22:00:00.342	2025-12-28 22:00:04.166	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3825
bf4260e1-67e5-4d23-a070-167caa3ff1a1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 07:50:00.99	2025-12-28 07:50:04.462	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3472
86d539ba-74ba-4ceb-9032-98f57e2730d0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 10:30:00.451	2025-12-28 10:30:03.891	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3440
f41cc06f-63e3-40a7-bc67-2dbbbc82f262	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 00:50:00.169	2025-12-29 00:50:03.42	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3254
ca9c690d-1085-4335-b90a-91e79a6fba84	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 14:00:00.394	2025-12-28 14:00:03.938	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3544
510d1d58-57ff-4c0b-8736-373a7735ab1f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 16:50:00.546	2025-12-28 16:50:03.722	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3177
30cf36e1-01ed-45f8-903e-d9941b4087c6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:20:00.9	2025-12-25 16:20:04.291	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3392
8bb2aa00-fc7b-48c9-b0ca-5e10382246fe	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:30:00.733	2025-12-26 21:30:04.887	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4154
a9936ab7-688e-4be1-9a1c-03511a8adddb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:10:00.39	2025-12-27 23:10:03.879	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3489
0808b608-9963-40fa-b087-377fb07f35cf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:00:00.742	2025-12-27 02:00:04.373	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3632
c449f711-e628-4669-9e0e-9d90aab6d609	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 19:30:00.385	2025-12-28 19:30:04.446	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4061
62dd5f19-4cc7-4c1a-bdb7-3f96cf35d8b9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:30:00.728	2025-12-27 11:30:04.308	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3581
57e64c30-79a3-44d5-b68a-9f16b49a7177	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:10:00.814	2025-12-28 02:10:04.139	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3326
6d266c84-f59b-432f-8f28-5609752d6fe3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:40:00.512	2025-12-27 15:40:04.115	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3604
948c26cc-df42-4488-a53b-b1bde7b46b86	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:30:00.628	2025-12-27 18:30:03.82	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3193
a6453502-bcc8-460e-bc54-84f1dc6b9075	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 05:00:00.893	2025-12-28 05:00:04.428	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3536
a97a2d70-c4c1-4694-893f-aa44b43ca706	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:20:00.804	2025-12-27 21:20:04.347	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3544
2cc53d92-02a1-4469-a83f-d7bfd54b3f08	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 22:10:00.999	2025-12-28 22:10:04.464	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3472
3123ae6b-dcb2-4076-b316-1935b24b247e	\N	每日热搜抓取	all	2025-12-28 08:00:00.026	2025-12-28 08:00:00.061	success	hotsearch	[{"platform":"douyin","success":true,"data":[{"rank":1,"keyword":"抖音热点1","heat":1015786,"trend":"下降","url":"https://douyin.com/search/"},{"rank":2,"keyword":"抖音热点2","heat":705652,"trend":"上升","url":"https://douyin.com/search/"},{"rank":3,"keyword":"抖音热点3","heat":1073489,"trend":"下降","url":"https://douyin.com/search/"},{"rank":4,"keyword":"抖音热点4","heat":302705,"trend":"上升","url":"https://douyin.com/search/"},{"rank":5,"keyword":"抖音热点5","heat":623142,"trend":"下降","url":"https://douyin.com/search/"},{"rank":6,"keyword":"抖音热点6","heat":580722,"trend":"下降","url":"https://douyin.com/search/"},{"rank":7,"keyword":"抖音热点7","heat":239916,"trend":"下降","url":"https://douyin.com/search/"},{"rank":8,"keyword":"抖音热点8","heat":429694,"trend":"下降","url":"https://douyin.com/search/"},{"rank":9,"keyword":"抖音热点9","heat":1073095,"trend":"上升","url":"https://douyin.com/search/"},{"rank":10,"keyword":"抖音热点10","heat":602124,"trend":"上升","url":"https://douyin.com/search/"},{"rank":11,"keyword":"抖音热点11","heat":474147,"trend":"下降","url":"https://douyin.com/search/"},{"rank":12,"keyword":"抖音热点12","heat":551042,"trend":"上升","url":"https://douyin.com/search/"},{"rank":13,"keyword":"抖音热点13","heat":839444,"trend":"下降","url":"https://douyin.com/search/"},{"rank":14,"keyword":"抖音热点14","heat":1063595,"trend":"上升","url":"https://douyin.com/search/"},{"rank":15,"keyword":"抖音热点15","heat":183312,"trend":"上升","url":"https://douyin.com/search/"},{"rank":16,"keyword":"抖音热点16","heat":1026579,"trend":"上升","url":"https://douyin.com/search/"},{"rank":17,"keyword":"抖音热点17","heat":276803,"trend":"上升","url":"https://douyin.com/search/"},{"rank":18,"keyword":"抖音热点18","heat":385245,"trend":"下降","url":"https://douyin.com/search/"},{"rank":19,"keyword":"抖音热点19","heat":802973,"trend":"上升","url":"https://douyin.com/search/"},{"rank":20,"keyword":"抖音热点20","heat":623165,"trend":"上升","url":"https://douyin.com/search/"}]},{"platform":"xiaohongshu","success":true,"data":[{"rank":1,"keyword":"小红书热点1","heat":135358,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":2,"keyword":"小红书热点2","heat":559231,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":3,"keyword":"小红书热点3","heat":935270,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":4,"keyword":"小红书热点4","heat":678307,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":5,"keyword":"小红书热点5","heat":381032,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":6,"keyword":"小红书热点6","heat":123572,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":7,"keyword":"小红书热点7","heat":651398,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":8,"keyword":"小红书热点8","heat":929361,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":9,"keyword":"小红书热点9","heat":195383,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":10,"keyword":"小红书热点10","heat":362581,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":11,"keyword":"小红书热点11","heat":371061,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":12,"keyword":"小红书热点12","heat":604327,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":13,"keyword":"小红书热点13","heat":823469,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":14,"keyword":"小红书热点14","heat":274787,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":15,"keyword":"小红书热点15","heat":643133,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":16,"keyword":"小红书热点16","heat":741062,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":17,"keyword":"小红书热点17","heat":380891,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":18,"keyword":"小红书热点18","heat":252692,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":19,"keyword":"小红书热点19","heat":650088,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":20,"keyword":"小红书热点20","heat":654867,"trend":"下降","url":"https://xiaohongshu.com/search_result/"}]},{"platform":"weibo","success":true,"data":[{"rank":1,"keyword":"微博热点1","heat":1436712,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":2,"keyword":"微博热点2","heat":757374,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":3,"keyword":"微博热点3","heat":2250266,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":4,"keyword":"微博热点4","heat":2073911,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":5,"keyword":"微博热点5","heat":1710112,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":6,"keyword":"微博热点6","heat":568681,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":7,"keyword":"微博热点7","heat":2257707,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":8,"keyword":"微博热点8","heat":901258,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":9,"keyword":"微博热点9","heat":1117364,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":10,"keyword":"微博热点10","heat":1975569,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":11,"keyword":"微博热点11","heat":2279488,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":12,"keyword":"微博热点12","heat":2065144,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":13,"keyword":"微博热点13","heat":1569114,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":14,"keyword":"微博热点14","heat":508105,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":15,"keyword":"微博热点15","heat":766515,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":16,"keyword":"微博热点16","heat":1072101,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":17,"keyword":"微博热点17","heat":1894703,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":18,"keyword":"微博热点18","heat":979435,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":19,"keyword":"微博热点19","heat":1289321,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":20,"keyword":"微博热点20","heat":2023505,"trend":"上升","url":"https://s.weibo.com/top/summary"}]},{"platform":"kuaishou","success":true,"data":[{"rank":1,"keyword":"快手热点1","heat":216150,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":2,"keyword":"快手热点2","heat":236554,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":3,"keyword":"快手热点3","heat":140344,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":4,"keyword":"快手热点4","heat":162205,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":5,"keyword":"快手热点5","heat":587772,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":6,"keyword":"快手热点6","heat":783666,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":7,"keyword":"快手热点7","heat":588073,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":8,"keyword":"快手热点8","heat":184888,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":9,"keyword":"快手热点9","heat":480345,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":10,"keyword":"快手热点10","heat":598371,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":11,"keyword":"快手热点11","heat":578889,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":12,"keyword":"快手热点12","heat":398808,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":13,"keyword":"快手热点13","heat":721749,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":14,"keyword":"快手热点14","heat":244646,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":15,"keyword":"快手热点15","heat":668467,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":16,"keyword":"快手热点16","heat":832606,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":17,"keyword":"快手热点17","heat":108900,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":18,"keyword":"快手热点18","heat":294217,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":19,"keyword":"快手热点19","heat":290903,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":20,"keyword":"快手热点20","heat":563275,"trend":"上升","url":"https://www.kuaishou.com/search/"}]},{"platform":"bilibili","success":true,"data":[{"rank":1,"keyword":"B站热点1","heat":663019,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":2,"keyword":"B站热点2","heat":856206,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":3,"keyword":"B站热点3","heat":1239020,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":4,"keyword":"B站热点4","heat":1523877,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":5,"keyword":"B站热点5","heat":741401,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":6,"keyword":"B站热点6","heat":571897,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":7,"keyword":"B站热点7","heat":1091140,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":8,"keyword":"B站热点8","heat":251427,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":9,"keyword":"B站热点9","heat":1149140,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":10,"keyword":"B站热点10","heat":282369,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":11,"keyword":"B站热点11","heat":1589768,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":12,"keyword":"B站热点12","heat":1299978,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":13,"keyword":"B站热点13","heat":629945,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":14,"keyword":"B站热点14","heat":1522533,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":15,"keyword":"B站热点15","heat":1285422,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":16,"keyword":"B站热点16","heat":1640925,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":17,"keyword":"B站热点17","heat":529875,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":18,"keyword":"B站热点18","heat":1604078,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":19,"keyword":"B站热点19","heat":223623,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":20,"keyword":"B站热点20","heat":1540531,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"}]}]	\N	5	0	0	35
bfe8cac3-7471-4ea7-8fa1-a387a7f1f728	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 10:40:00.216	2025-12-28 10:40:03.422	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3206
6d34e628-cf9c-45d3-953d-4ad792b86af2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 01:00:00.853	2025-12-29 01:00:04.041	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3191
a1edbb46-64f6-438f-b85f-4e71d0a56e16	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 14:10:00.415	2025-12-28 14:10:04.015	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3600
077fe348-01b5-4c5d-aa18-69c53bec6aa9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 17:00:00.215	2025-12-28 17:00:03.543	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3328
49224e74-60ea-4d09-a66e-364b167955f3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:30:00.607	2025-12-25 16:30:04.348	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3743
8d950e33-b8af-4f6d-a006-114e403eceb6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:40:00.56	2025-12-26 21:40:03.86	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3301
402d9861-55a0-4d18-ac0b-1f08390d79a2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:20:00.154	2025-12-27 23:20:03.509	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3355
ec4b2ac2-ca87-4f18-baf5-3a865d988473	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:10:00.636	2025-12-27 02:10:03.965	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3332
5eb790cc-5d7a-4a0d-ade6-ae0a5272eafb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 19:40:00.271	2025-12-28 19:40:03.42	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3150
25888a88-fb51-4c2e-882e-75dc3c4da065	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:40:00.556	2025-12-27 11:40:04.168	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3614
bd901bb7-ad89-43bc-a3a9-c6a51c19d0cb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:20:00.512	2025-12-28 02:20:03.937	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3426
2a476388-1968-4637-ada5-3e5ea07175f4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:50:00.471	2025-12-27 15:50:03.614	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3144
0097d881-0f91-4188-909b-acb75c29ca65	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:40:00.582	2025-12-27 18:40:03.272	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2690
70a59c4a-db0d-45c8-a47f-b7c3bea59ddb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 05:10:00.905	2025-12-28 05:10:04.318	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3413
7b6d7c7a-8b8a-4ac0-9c22-3095b42e37d6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:30:00.972	2025-12-27 21:30:04.42	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3448
6f7af63a-dacf-473c-a050-619a95abcdb1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 22:20:00.801	2025-12-28 22:20:04.638	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3839
26ad44c7-656f-4197-9e7f-e78e4725782c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 08:00:00.025	2025-12-28 08:00:03.242	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3217
0fc9edc1-4325-4f97-ae07-ba204f5cef4d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 10:50:00.244	2025-12-28 10:50:05.477	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5235
d962d45c-69de-4572-a2e3-001d57e6e9e9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 01:10:00.59	2025-12-29 01:10:03.761	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3175
e995de5a-fe37-4fdc-a221-4ecfcbdae62d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 14:20:00.388	2025-12-28 14:20:04.299	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3911
f5b038d8-2a4f-4e97-8846-ed44f636e6b6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 17:10:00.681	2025-12-28 17:10:03.959	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3278
fb790805-9e28-4ce7-afc2-5309f9da4567	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:40:00.254	2025-12-25 16:40:04.997	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4744
d7051fe7-6d71-4d00-b08b-3c2bc9ed0f71	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:50:00.733	2025-12-26 21:50:04.236	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3505
aebe79fc-2053-42f5-a46a-eefc385ff91c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:30:00.007	2025-12-27 23:30:03.611	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3604
d24e6c3c-07d4-4859-adb4-8e555a651931	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:20:00.546	2025-12-27 02:20:03.926	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3380
44f9e973-f8c1-4cad-a6f9-1cf6fde2a5b8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 19:50:00.15	2025-12-28 19:50:03.436	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3286
b1a48dd8-12a1-431f-b963-d521973b5681	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:50:00.432	2025-12-27 11:50:27.605	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	27175
6254f071-2045-428b-9b7b-8f67ce957322	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:30:00.261	2025-12-28 02:30:03.469	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3208
3a2d7a85-4feb-45ed-b7e5-2827b75ce6ac	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:00:00.52	2025-12-27 16:00:03.691	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3172
ec9be0b8-88f4-44cb-a749-4908d723959b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:50:00.808	2025-12-27 18:50:06.158	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5350
e1933040-b402-4a68-aeb6-eec9a39e4f56	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 05:20:00.912	2025-12-28 05:20:04.198	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3287
a642c1b0-60f5-4cde-8ccd-098155c7eb9c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:00:00.342	2025-12-27 22:00:05.207	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4865
e39bf0f0-ccdc-4fe6-a51f-de81e7500575	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 22:30:00.546	2025-12-28 22:30:04.308	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3763
469271d5-37a8-4290-b0f3-f9d7f5f804e0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 08:10:00.054	2025-12-28 08:10:03.544	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3490
a311382c-b12e-4db4-9053-1524d4b94086	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 11:00:00.703	2025-12-28 11:00:03.868	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3165
eb3febff-70d3-4bf7-8bb6-1c126a68fabd	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 01:20:00.29	2025-12-29 01:20:03.494	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3205
ad4c418a-51de-4a08-8693-3555a1f823c5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 14:30:00.402	2025-12-28 14:30:03.783	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3381
779f42fb-1b7c-4af7-bedc-47d929634ee9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 17:20:00.4	2025-12-28 17:20:02.955	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2555
eb26eead-5fa1-4ab7-9687-656cdcd3ee39	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:50:00.825	2025-12-25 16:50:05.301	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4476
8fbfa14a-504e-45eb-88eb-023c269ff037	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:00:00.971	2025-12-26 22:00:03.867	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2897
a2750183-faca-486e-a551-977e2df72783	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:40:00.79	2025-12-27 23:40:04.397	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3607
786d8c73-b74b-49cb-b294-e3be89e59c27	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 04:40:00.571	2025-12-27 04:40:04.154	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3585
fc9c2156-8995-4edc-9a84-df9da4488d73	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 20:00:00.295	2025-12-28 20:00:05.541	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5246
3b1b00e6-4888-4da6-bdd5-8fcde5a78a82	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 12:00:00.32	2025-12-27 12:00:03.655	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3336
eba4a1cb-115f-4561-a4a8-b30573ee4179	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:40:00.598	2025-12-28 02:40:04.038	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3440
fdf65ae9-adc9-4b21-8324-7ad3d6273e6a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:10:00.256	2025-12-27 16:10:04.266	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4011
9126e1f3-097f-46c6-b936-45c1c017b302	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:00:00.883	2025-12-27 19:00:04.241	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3359
442b1c7d-edba-466c-a910-5e92460495a9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 05:30:00.916	2025-12-28 05:30:04.109	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3193
bc5db996-ae99-4abd-8b64-4b89b846039b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:10:00.302	2025-12-27 22:10:03.674	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3373
bcb650ad-e07e-4cd8-86db-e393c73f0abb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 22:40:00.331	2025-12-28 22:40:04.16	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3829
69587a97-47da-433e-8e98-b36ab3af865f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 08:20:00.097	2025-12-28 08:20:03.408	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3311
be5392e0-d473-450e-9141-410aa1b7878f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 11:10:00.051	2025-12-28 11:10:03.63	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3579
40f4ac66-0195-4bc4-81aa-7c261a3c0429	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 01:30:00.041	2025-12-29 01:30:03.2	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3162
a41fecee-f9a4-4d3c-a5f7-ae20b7560905	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 14:40:00.371	2025-12-28 14:40:03.896	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3526
c67405ac-2ec1-40c0-bf21-ebdfd8e74c6c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 17:30:00.102	2025-12-28 17:30:03.288	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3186
b207fdaf-c3be-4717-a94c-d56884b33fc7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:00:00.481	2025-12-25 17:00:05.052	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4572
cc856216-87ad-4627-b5bc-49b39f8b2d00	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:10:00.052	2025-12-26 22:10:03.176	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3125
c867f782-aa74-4702-ba9c-68093702abc4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:50:00.733	2025-12-27 23:50:04.398	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3665
0d6735ed-3afb-4a7a-882a-263c46270a8e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 04:50:00.464	2025-12-27 04:50:03.98	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3517
046a2915-b846-4fce-b05e-624c8decb489	\N	每日热搜抓取	all	2025-12-28 20:00:00.298	2025-12-28 20:06:20.554	success	hotsearch	[{"platform":"douyin","success":true,"data":[]},{"platform":"xiaohongshu","success":true,"data":[]},{"platform":"weibo","success":true,"data":[{"rank":1,"keyword":"兔子警官回应作秀质疑","heat":1094439,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E5%85%94%E5%AD%90%E8%AD%A6%E5%AE%98%E5%9B%9E%E5%BA%94%E4%BD%9C%E7%A7%80%E8%B4%A8%E7%96%91","category":"综合"},{"rank":2,"keyword":"奶奶喜丧女子因朋友少求助网友","heat":504048,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E5%A5%B6%E5%A5%B6%E5%96%9C%E4%B8%A7%E5%A5%B3%E5%AD%90%E5%9B%A0%E6%9C%8B%E5%8F%8B%E5%B0%91%E6%B1%82%E5%8A%A9%E7%BD%91%E5%8F%8B","category":"综合"},{"rank":3,"keyword":"故事里的2025","heat":372514,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E6%95%85%E4%BA%8B%E9%87%8C%E7%9A%842025","category":"综合"},{"rank":4,"keyword":"京东超级明星","heat":372063,"trend":"推广","url":"https://s.weibo.com/weibo?q=%E4%BA%AC%E4%B8%9C%E8%B6%85%E7%BA%A7%E6%98%8E%E6%98%9F","category":"综合"},{"rank":5,"keyword":"苏新皓杨博文双人舞台","heat":371412,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E8%8B%8F%E6%96%B0%E7%9A%93%E6%9D%A8%E5%8D%9A%E6%96%87%E5%8F%8C%E4%BA%BA%E8%88%9E%E5%8F%B0","category":"综合"},{"rank":6,"keyword":"Karsa宣布退役","heat":369354,"trend":"新晋","url":"https://s.weibo.com/weibo?q=Karsa%E5%AE%A3%E5%B8%83%E9%80%80%E5%BD%B9","category":"综合"},{"rank":7,"keyword":"双轨婚礼呢","heat":354245,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E5%8F%8C%E8%BD%A8%E5%A9%9A%E7%A4%BC%E5%91%A2","category":"综合"},{"rank":8,"keyword":"成都警方通报燃爆事件致1死4伤","heat":324235,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E6%88%90%E9%83%BD%E8%AD%A6%E6%96%B9%E9%80%9A%E6%8A%A5%E7%87%83%E7%88%86%E4%BA%8B%E4%BB%B6%E8%87%B41%E6%AD%BB4%E4%BC%A4","category":"综合"},{"rank":9,"keyword":"商场展车被小孩误触撞入手机店","heat":300164,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E5%95%86%E5%9C%BA%E5%B1%95%E8%BD%A6%E8%A2%AB%E5%B0%8F%E5%AD%A9%E8%AF%AF%E8%A7%A6%E6%92%9E%E5%85%A5%E6%89%8B%E6%9C%BA%E5%BA%97","category":"综合"},{"rank":10,"keyword":"骄阳似我","heat":286111,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E9%AA%84%E9%98%B3%E4%BC%BC%E6%88%91","category":"综合"},{"rank":11,"keyword":"何与 靳朝是最接近自己的","heat":283666,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E4%BD%95%E4%B8%8E%20%E9%9D%B3%E6%9C%9D%E6%98%AF%E6%9C%80%E6%8E%A5%E8%BF%91%E8%87%AA%E5%B7%B1%E7%9A%84","category":"综合"},{"rank":12,"keyword":"点外卖备注只要一点点饭时","heat":282437,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E7%82%B9%E5%A4%96%E5%8D%96%E5%A4%87%E6%B3%A8%E5%8F%AA%E8%A6%81%E4%B8%80%E7%82%B9%E7%82%B9%E9%A5%AD%E6%97%B6","category":"综合"},{"rank":13,"keyword":"虞书欣特别感谢小石榴们","heat":280001,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E8%99%9E%E4%B9%A6%E6%AC%A3%E7%89%B9%E5%88%AB%E6%84%9F%E8%B0%A2%E5%B0%8F%E7%9F%B3%E6%A6%B4%E4%BB%AC","category":"综合"},{"rank":14,"keyword":"王梓莼称没有霸凌任何人","heat":277809,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E7%8E%8B%E6%A2%93%E8%8E%BC%E7%A7%B0%E6%B2%A1%E6%9C%89%E9%9C%B8%E5%87%8C%E4%BB%BB%E4%BD%95%E4%BA%BA","category":"综合"},{"rank":15,"keyword":"中学通报学生跑操后昏迷几天后离世","heat":275041,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E4%B8%AD%E5%AD%A6%E9%80%9A%E6%8A%A5%E5%AD%A6%E7%94%9F%E8%B7%91%E6%93%8D%E5%90%8E%E6%98%8F%E8%BF%B7%E5%87%A0%E5%A4%A9%E5%90%8E%E7%A6%BB%E4%B8%96","category":"综合"},{"rank":16,"keyword":"王橹杰羽毛眼链","heat":272429,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E7%8E%8B%E6%A9%B9%E6%9D%B0%E7%BE%BD%E6%AF%9B%E7%9C%BC%E9%93%BE","category":"综合"},{"rank":17,"keyword":"严浩翔 马丁","heat":264865,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E4%B8%A5%E6%B5%A9%E7%BF%94%20%E9%A9%AC%E4%B8%81","category":"综合"},{"rank":18,"keyword":"江西省博确认米芾展品为原件","heat":253547,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E6%B1%9F%E8%A5%BF%E7%9C%81%E5%8D%9A%E7%A1%AE%E8%AE%A4%E7%B1%B3%E8%8A%BE%E5%B1%95%E5%93%81%E4%B8%BA%E5%8E%9F%E4%BB%B6","category":"综合"},{"rank":19,"keyword":"男子内裤裆部藏70.8克毒品进境","heat":250232,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E7%94%B7%E5%AD%90%E5%86%85%E8%A3%A4%E8%A3%86%E9%83%A8%E8%97%8F70.8%E5%85%8B%E6%AF%92%E5%93%81%E8%BF%9B%E5%A2%83","category":"综合"},{"rank":20,"keyword":"中国摄影地图上的郑州坐标","heat":243538,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E4%B8%AD%E5%9B%BD%E6%91%84%E5%BD%B1%E5%9C%B0%E5%9B%BE%E4%B8%8A%E7%9A%84%E9%83%91%E5%B7%9E%E5%9D%90%E6%A0%87","category":"综合"},{"rank":21,"keyword":"骄阳似我这集演到真假千金","heat":240103,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E9%AA%84%E9%98%B3%E4%BC%BC%E6%88%91%E8%BF%99%E9%9B%86%E6%BC%94%E5%88%B0%E7%9C%9F%E5%81%87%E5%8D%83%E9%87%91","category":"综合"},{"rank":22,"keyword":"美国斩杀线击碎美国梦","heat":237960,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E7%BE%8E%E5%9B%BD%E6%96%A9%E6%9D%80%E7%BA%BF%E5%87%BB%E7%A2%8E%E7%BE%8E%E5%9B%BD%E6%A2%A6","category":"综合"},{"rank":23,"keyword":"黄子韬因脑淤血手术缝了43针","heat":231441,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E9%BB%84%E5%AD%90%E9%9F%AC%E5%9B%A0%E8%84%91%E6%B7%A4%E8%A1%80%E6%89%8B%E6%9C%AF%E7%BC%9D%E4%BA%8643%E9%92%88","category":"综合"},{"rank":24,"keyword":"张杰谢娜 同台","heat":225117,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E5%BC%A0%E6%9D%B0%E8%B0%A2%E5%A8%9C%20%E5%90%8C%E5%8F%B0","category":"综合"},{"rank":25,"keyword":"微博之夜","heat":216206,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E5%BE%AE%E5%8D%9A%E4%B9%8B%E5%A4%9C","category":"综合"},{"rank":26,"keyword":"半个娱乐圈都来董璇评论区团建了","heat":208584,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E5%8D%8A%E4%B8%AA%E5%A8%B1%E4%B9%90%E5%9C%88%E9%83%BD%E6%9D%A5%E8%91%A3%E7%92%87%E8%AF%84%E8%AE%BA%E5%8C%BA%E5%9B%A2%E5%BB%BA%E4%BA%86","category":"综合"},{"rank":27,"keyword":"仙逆","heat":206247,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E4%BB%99%E9%80%86","category":"综合"},{"rank":28,"keyword":"王楚钦vs向鹏","heat":201430,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E7%8E%8B%E6%A5%9A%E9%92%A6vs%E5%90%91%E9%B9%8F","category":"综合"},{"rank":29,"keyword":"日本老年人称已经没希望了","heat":189013,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E6%97%A5%E6%9C%AC%E8%80%81%E5%B9%B4%E4%BA%BA%E7%A7%B0%E5%B7%B2%E7%BB%8F%E6%B2%A1%E5%B8%8C%E6%9C%9B%E4%BA%86","category":"综合"},{"rank":30,"keyword":"宋亚轩免检生图","heat":179860,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E5%AE%8B%E4%BA%9A%E8%BD%A9%E5%85%8D%E6%A3%80%E7%94%9F%E5%9B%BE","category":"综合"},{"rank":31,"keyword":"艾克里里不愧是杨紫的嫡长闺","heat":172790,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E8%89%BE%E5%85%8B%E9%87%8C%E9%87%8C%E4%B8%8D%E6%84%A7%E6%98%AF%E6%9D%A8%E7%B4%AB%E7%9A%84%E5%AB%A1%E9%95%BF%E9%97%BA","category":"综合"},{"rank":32,"keyword":"马嘉祺 吸血鬼伯爵","heat":160736,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E9%A9%AC%E5%98%89%E7%A5%BA%20%E5%90%B8%E8%A1%80%E9%AC%BC%E4%BC%AF%E7%88%B5","category":"综合"},{"rank":33,"keyword":"王俊凯出发澳门跨年","heat":160658,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E7%8E%8B%E4%BF%8A%E5%87%AF%E5%87%BA%E5%8F%91%E6%BE%B3%E9%97%A8%E8%B7%A8%E5%B9%B4","category":"综合"},{"rank":34,"keyword":"2026春晚分会场发布","heat":160251,"trend":"普通","url":"https://s.weibo.com/weibo?q=2026%E6%98%A5%E6%99%9A%E5%88%86%E4%BC%9A%E5%9C%BA%E5%8F%91%E5%B8%83","category":"综合"},{"rank":35,"keyword":"骄阳似我 单更","heat":157521,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E9%AA%84%E9%98%B3%E4%BC%BC%E6%88%91%20%E5%8D%95%E6%9B%B4","category":"综合"},{"rank":36,"keyword":"王安宇告别现在就出发","heat":156667,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E7%8E%8B%E5%AE%89%E5%AE%87%E5%91%8A%E5%88%AB%E7%8E%B0%E5%9C%A8%E5%B0%B1%E5%87%BA%E5%8F%91","category":"综合"},{"rank":37,"keyword":"杨博文贝斯手男神","heat":151921,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E6%9D%A8%E5%8D%9A%E6%96%87%E8%B4%9D%E6%96%AF%E6%89%8B%E7%94%B7%E7%A5%9E","category":"综合"},{"rank":38,"keyword":"罗大美遇害两年后下葬","heat":151884,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E7%BD%97%E5%A4%A7%E7%BE%8E%E9%81%87%E5%AE%B3%E4%B8%A4%E5%B9%B4%E5%90%8E%E4%B8%8B%E8%91%AC","category":"综合"},{"rank":39,"keyword":"多款游戏女性角色陷擦边卖肉争议","heat":151867,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E5%A4%9A%E6%AC%BE%E6%B8%B8%E6%88%8F%E5%A5%B3%E6%80%A7%E8%A7%92%E8%89%B2%E9%99%B7%E6%93%A6%E8%BE%B9%E5%8D%96%E8%82%89%E4%BA%89%E8%AE%AE","category":"综合"},{"rank":40,"keyword":"古天乐又讨宣萱打了","heat":151810,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E5%8F%A4%E5%A4%A9%E4%B9%90%E5%8F%88%E8%AE%A8%E5%AE%A3%E8%90%B1%E6%89%93%E4%BA%86","category":"综合"},{"rank":41,"keyword":"高超高越心有不灵犀","heat":151774,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E9%AB%98%E8%B6%85%E9%AB%98%E8%B6%8A%E5%BF%83%E6%9C%89%E4%B8%8D%E7%81%B5%E7%8A%80","category":"综合"},{"rank":42,"keyword":"丁程鑫站姐神图火力全开","heat":151743,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E4%B8%81%E7%A8%8B%E9%91%AB%E7%AB%99%E5%A7%90%E7%A5%9E%E5%9B%BE%E7%81%AB%E5%8A%9B%E5%85%A8%E5%BC%80","category":"综合"},{"rank":43,"keyword":"演员碧姬芭铎去世","heat":147431,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E6%BC%94%E5%91%98%E7%A2%A7%E5%A7%AC%E8%8A%AD%E9%93%8E%E5%8E%BB%E4%B8%96","category":"综合"},{"rank":44,"keyword":"AG吃鸡拒绝下班","heat":145050,"trend":"新晋","url":"https://s.weibo.com/weibo?q=AG%E5%90%83%E9%B8%A1%E6%8B%92%E7%BB%9D%E4%B8%8B%E7%8F%AD","category":"综合"},{"rank":45,"keyword":"刘耀文 撕漫男","heat":144080,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E5%88%98%E8%80%80%E6%96%87%20%E6%92%95%E6%BC%AB%E7%94%B7","category":"综合"},{"rank":46,"keyword":"苹果煮水喝好处太多了","heat":138180,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E8%8B%B9%E6%9E%9C%E7%85%AE%E6%B0%B4%E5%96%9D%E5%A5%BD%E5%A4%84%E5%A4%AA%E5%A4%9A%E4%BA%86","category":"综合"},{"rank":47,"keyword":"新音节目单","heat":137606,"trend":"普通","url":"https://s.weibo.com/weibo?q=%E6%96%B0%E9%9F%B3%E8%8A%82%E7%9B%AE%E5%8D%95","category":"综合"},{"rank":48,"keyword":"杨枝甘露白开水猫眼美甲","heat":134558,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E6%9D%A8%E6%9E%9D%E7%94%98%E9%9C%B2%E7%99%BD%E5%BC%80%E6%B0%B4%E7%8C%AB%E7%9C%BC%E7%BE%8E%E7%94%B2","category":"综合"},{"rank":49,"keyword":"田曦薇演戏归来三年农龄","heat":131268,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E7%94%B0%E6%9B%A6%E8%96%87%E6%BC%94%E6%88%8F%E5%BD%92%E6%9D%A5%E4%B8%89%E5%B9%B4%E5%86%9C%E9%BE%84","category":"综合"},{"rank":50,"keyword":"外科医生拿手术刀折千纸鹤","heat":129070,"trend":"新晋","url":"https://s.weibo.com/weibo?q=%E5%A4%96%E7%A7%91%E5%8C%BB%E7%94%9F%E6%8B%BF%E6%89%8B%E6%9C%AF%E5%88%80%E6%8A%98%E5%8D%83%E7%BA%B8%E9%B9%A4","category":"综合"}]},{"platform":"bilibili","success":true,"data":[]}]	\N	4	0	0	380256
aaba408d-dd7c-4996-87b1-842c78763680	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 12:10:00.177	2025-12-27 12:10:02.554	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2377
f19eb193-fca9-4aaf-9450-15eabd939f00	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:50:00.623	2025-12-28 02:50:31.321	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	30699
81d25fcd-3d8f-4bb8-93ab-4523f697f385	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:20:00.255	2025-12-27 16:20:03.938	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3685
b110ff8c-495f-49db-b49a-a16861e8bf70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:10:00.46	2025-12-27 19:10:03.867	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3409
67d54abe-a00f-486c-a5d1-bc4805679577	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 05:40:00.921	2025-12-28 05:40:04.004	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3083
241172bd-e204-4211-97d3-5e7e1ef77d15	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:20:00.775	2025-12-27 22:20:05.397	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4622
0606db46-c215-4a1d-937f-7f085945e9d3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 22:50:00.146	2025-12-28 22:50:03.707	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3561
4c84c5f0-714d-4f67-a456-e2864d980da4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 08:30:00.118	2025-12-28 08:30:02.316	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2198
7c6dcb96-428a-41e0-a683-7eae8383bf05	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 11:20:00.432	2025-12-28 11:20:04.055	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3623
17c2172d-58b7-44dc-be2d-e5807c0e9288	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 01:40:00.785	2025-12-29 01:40:04.161	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3380
7dc048ee-d251-4874-a8f1-91472df859bf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 14:50:00.336	2025-12-28 14:50:02.557	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2221
0b5abe74-19ad-4854-8062-369184c9a75b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 17:40:00.342	2025-12-28 17:40:03.567	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3225
de763b1f-0319-4900-85e9-8ea3e88c0117	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:10:00.084	2025-12-25 17:10:05.094	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5012
021645c3-3411-457b-9974-921d16723a92	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:20:00.831	2025-12-26 22:20:04.2	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3369
6bd02609-cc8d-4f11-b562-ddd4b52c7ce5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:10:00.594	2025-12-28 00:10:05.241	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4648
350d87b6-c1cf-4ba5-987f-530591e8de01	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:00:00.352	2025-12-27 05:00:03.613	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3264
2ab7e35d-5076-44ae-9a45-7ded84c94efd	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 20:10:00.406	2025-12-28 20:10:03.612	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3207
3b79aa09-ca1d-4355-9ae7-564578e65c4e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 13:30:00.669	2025-12-27 13:30:04.155	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3488
2d853538-3b0b-411a-b47b-92c92d9cec06	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 03:00:00.61	2025-12-28 03:00:04.423	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3813
e4b0b9a6-7f07-458f-a190-59581211805a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:30:00.267	2025-12-27 16:30:02.567	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2302
5671b3ba-d755-4d21-a4fa-c5cc754ff55e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:20:00.208	2025-12-27 19:20:03.578	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3370
920c8d90-eab4-4804-a666-7caf18577695	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 05:50:00.898	2025-12-28 05:50:04.429	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3532
18ed64b1-7f6c-4fd0-ade7-ef2f0fb2c8d3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:30:00.617	2025-12-27 22:30:04.512	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3895
5ea304ee-60f4-48d7-ab82-d7a850db0011	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 23:00:00.839	2025-12-28 23:00:04.15	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3312
87d64b04-f134-42eb-81c9-2045bd5d71bd	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 08:40:00.117	2025-12-28 08:40:03.649	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3532
896266a5-6a38-403c-95d5-2f961088112c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 11:30:00.469	2025-12-28 11:30:04.288	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3819
41e3db5b-c284-49c1-a0df-9d63fc64e8af	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 01:50:00.131	2025-12-29 01:50:03.879	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3753
d48bb332-a61d-430f-991d-a4dd600c7069	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 15:00:00.316	2025-12-28 15:00:03.599	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3283
c14f1f90-c9e9-4c37-897e-1630db2fa7d3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 17:50:00.304	2025-12-28 17:50:03.971	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3667
e2cc2f4c-c04e-457d-acca-564973c1dc05	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:20:00.676	2025-12-25 17:20:05.024	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4348
fab0141a-071a-44bb-b93b-b0a21bd5a8dc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:30:00.387	2025-12-26 22:30:04.157	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3772
cc5fbc91-0586-49d1-b67f-687533c8d300	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:20:00.42	2025-12-28 00:20:04.105	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3686
d2cf257c-dccb-43f6-beeb-81ca0e70b4c8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:10:00.241	2025-12-27 05:10:04.129	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3889
b3663b91-b4ce-440a-a992-d5b11d95edb2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 20:20:00.517	2025-12-28 20:20:03.792	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3276
1dd11280-a324-4da7-a421-fabb687f35fb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 13:40:00.602	2025-12-27 13:40:03.835	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3235
45116431-d791-4361-8795-a085f2808408	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 03:10:00.619	2025-12-28 03:10:03.706	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3087
7d40b727-91d1-4dc4-b09f-9855856ae97c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:40:00.358	2025-12-27 16:40:03.7	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3345
fa207805-8002-4285-a585-729f10d72091	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:30:00.606	\N	running	author	\N	\N	0	0	0	0
d7a325a2-416c-41bd-b81c-e3ade58d703a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 06:00:00.906	2025-12-28 06:00:04.259	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3353
c76b1c35-d639-486f-b953-d0eeb483af45	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 23:10:00.494	2025-12-28 23:10:03.604	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3111
02722bda-3b90-45fc-b794-a25699e4f104	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 08:50:00.142	2025-12-28 08:50:03.59	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3449
14d39f5e-ad38-46ec-9d78-4c222e9d23ac	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 02:00:00.209	\N	running	author	\N	\N	0	0	0	0
269aec41-26ca-40b5-90c1-3717a344bc8c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 11:40:00.731	2025-12-28 11:40:04.052	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3321
39790a3d-4a9b-4aaf-a9b4-1d405b897015	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 15:10:00.296	2025-12-28 15:10:03.809	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3514
2ff39262-b346-4dc2-911f-9a7107987c3d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 18:00:00.249	2025-12-28 18:00:03.766	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3517
465547ad-b4bd-42da-961d-f94d3e0d2dd5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:30:00.347	2025-12-25 17:30:05.172	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4826
d08e526d-4072-47c7-a199-cd2772c0e20a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:00:00.606	2025-12-26 23:00:04.07	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3467
182309a2-f8b1-4b65-b301-58796bde4746	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:30:00.126	2025-12-28 00:30:04.657	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4531
23fbff8d-d12e-4974-a52e-1f7b23a7bb02	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:20:00.132	2025-12-27 05:20:03.597	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3467
33c2266e-5cf5-4002-989c-440ee2deedbb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 20:30:00.727	2025-12-28 20:30:03.846	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3119
1c62ee06-6768-467c-ac3b-981f6ca21967	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 13:50:00.548	2025-12-27 13:50:04.074	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3530
63786311-4f20-4d9c-91b3-24cd62514376	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 03:20:00.657	2025-12-28 03:20:04.04	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3384
ce19edea-f926-4873-879b-d0f89c165115	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:50:00.521	2025-12-27 16:50:04.167	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3648
42b43108-0188-4448-9c12-84adce795233	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:40:00.578	2025-12-27 19:40:03.88	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3302
78075762-c773-4603-8d91-45015be8d5e5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 06:10:00.917	2025-12-28 06:10:04.012	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3095
4652c574-8801-40f1-97aa-66817bfe4f65	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 23:20:00.22	2025-12-28 23:20:04.074	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3855
3223a64c-5beb-48ac-880a-34b54aac7e0a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 09:00:00.16	2025-12-28 09:00:03.271	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3111
8d9d7ddf-389e-4757-a663-e823c8c1a5c6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 11:50:00.456	2025-12-28 11:50:03.492	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3036
756766c3-65dc-4921-9e69-d13c69a9efed	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 15:20:00.269	2025-12-28 15:20:03.461	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3193
ed02cd29-baf8-43a9-89a8-e12e829eff84	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 18:20:00.687	2025-12-28 18:20:03.595	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2908
85036e3d-3e4d-4793-b3ef-f53ff1167ff4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:40:00.944	2025-12-25 17:40:07.801	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6857
37231e4c-460b-496d-8ed1-d0916f8f25e8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:10:00.513	2025-12-26 23:10:04.004	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3495
105604b9-dc31-4538-a99a-a0207c354844	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:40:00.74	2025-12-28 00:40:05.345	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4605
012a6b83-bd9f-44fa-bdbb-799710427ecb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:30:00.038	2025-12-27 05:30:03.167	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3131
7a3afb9f-c975-46aa-b846-190f5ef3140b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 20:40:00.427	2025-12-28 20:40:03.745	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3319
888da43c-ab25-4726-ba9b-ce4a48730394	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:00:00.461	2025-12-27 14:00:04.124	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3664
a37d9a59-83ce-4e3f-85ab-52e7e4c1d2ac	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 03:30:00.654	2025-12-28 03:30:03.917	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3263
69a0c064-39eb-4985-a3b5-28de4a426eee	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:00:00.641	2025-12-27 17:00:04.077	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3438
dce479fd-d0ea-4ae5-93de-4ba314a72e5c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:50:00.798	2025-12-27 19:50:03.92	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3122
0e1abd81-3fcd-4cdb-a0bb-b8b8016d3102	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 06:20:00.926	2025-12-28 06:20:04.398	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3473
142b46bb-8475-4aa8-9393-dcf31f3b9e5d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 23:30:00.656	2025-12-28 23:30:03.987	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3331
1d443f9a-2bb3-461b-bdfa-74dad141e6b1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 09:10:00.194	2025-12-28 09:10:03.824	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3630
d275a78a-3ea1-4181-ba72-9c480ae9f8bb	\N	每日热搜抓取	all	2025-12-28 12:00:00.535	2025-12-28 12:00:00.555	success	hotsearch	[{"platform":"douyin","success":true,"data":[{"rank":1,"keyword":"抖音热点1","heat":846607,"trend":"上升","url":"https://douyin.com/search/"},{"rank":2,"keyword":"抖音热点2","heat":338172,"trend":"下降","url":"https://douyin.com/search/"},{"rank":3,"keyword":"抖音热点3","heat":849431,"trend":"上升","url":"https://douyin.com/search/"},{"rank":4,"keyword":"抖音热点4","heat":944425,"trend":"上升","url":"https://douyin.com/search/"},{"rank":5,"keyword":"抖音热点5","heat":629505,"trend":"上升","url":"https://douyin.com/search/"},{"rank":6,"keyword":"抖音热点6","heat":795574,"trend":"下降","url":"https://douyin.com/search/"},{"rank":7,"keyword":"抖音热点7","heat":1030716,"trend":"下降","url":"https://douyin.com/search/"},{"rank":8,"keyword":"抖音热点8","heat":407353,"trend":"下降","url":"https://douyin.com/search/"},{"rank":9,"keyword":"抖音热点9","heat":600186,"trend":"下降","url":"https://douyin.com/search/"},{"rank":10,"keyword":"抖音热点10","heat":360141,"trend":"下降","url":"https://douyin.com/search/"},{"rank":11,"keyword":"抖音热点11","heat":815142,"trend":"上升","url":"https://douyin.com/search/"},{"rank":12,"keyword":"抖音热点12","heat":499689,"trend":"下降","url":"https://douyin.com/search/"},{"rank":13,"keyword":"抖音热点13","heat":153034,"trend":"上升","url":"https://douyin.com/search/"},{"rank":14,"keyword":"抖音热点14","heat":385740,"trend":"上升","url":"https://douyin.com/search/"},{"rank":15,"keyword":"抖音热点15","heat":612187,"trend":"下降","url":"https://douyin.com/search/"},{"rank":16,"keyword":"抖音热点16","heat":311467,"trend":"下降","url":"https://douyin.com/search/"},{"rank":17,"keyword":"抖音热点17","heat":920209,"trend":"下降","url":"https://douyin.com/search/"},{"rank":18,"keyword":"抖音热点18","heat":439447,"trend":"下降","url":"https://douyin.com/search/"},{"rank":19,"keyword":"抖音热点19","heat":1020798,"trend":"上升","url":"https://douyin.com/search/"},{"rank":20,"keyword":"抖音热点20","heat":587947,"trend":"下降","url":"https://douyin.com/search/"}]},{"platform":"xiaohongshu","success":true,"data":[{"rank":1,"keyword":"小红书热点1","heat":772305,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":2,"keyword":"小红书热点2","heat":501534,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":3,"keyword":"小红书热点3","heat":974223,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":4,"keyword":"小红书热点4","heat":931129,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":5,"keyword":"小红书热点5","heat":744843,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":6,"keyword":"小红书热点6","heat":445097,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":7,"keyword":"小红书热点7","heat":691925,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":8,"keyword":"小红书热点8","heat":196551,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":9,"keyword":"小红书热点9","heat":1080903,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":10,"keyword":"小红书热点10","heat":934419,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":11,"keyword":"小红书热点11","heat":785600,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":12,"keyword":"小红书热点12","heat":435981,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":13,"keyword":"小红书热点13","heat":754661,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":14,"keyword":"小红书热点14","heat":1027481,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":15,"keyword":"小红书热点15","heat":849940,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":16,"keyword":"小红书热点16","heat":1088558,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":17,"keyword":"小红书热点17","heat":119712,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":18,"keyword":"小红书热点18","heat":788501,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":19,"keyword":"小红书热点19","heat":286482,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":20,"keyword":"小红书热点20","heat":514263,"trend":"下降","url":"https://xiaohongshu.com/search_result/"}]},{"platform":"weibo","success":true,"data":[{"rank":1,"keyword":"微博热点1","heat":2127211,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":2,"keyword":"微博热点2","heat":2391971,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":3,"keyword":"微博热点3","heat":1285837,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":4,"keyword":"微博热点4","heat":1919944,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":5,"keyword":"微博热点5","heat":870472,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":6,"keyword":"微博热点6","heat":641646,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":7,"keyword":"微博热点7","heat":1488959,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":8,"keyword":"微博热点8","heat":1441553,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":9,"keyword":"微博热点9","heat":677341,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":10,"keyword":"微博热点10","heat":2252117,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":11,"keyword":"微博热点11","heat":600373,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":12,"keyword":"微博热点12","heat":1943371,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":13,"keyword":"微博热点13","heat":2043926,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":14,"keyword":"微博热点14","heat":1226264,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":15,"keyword":"微博热点15","heat":1113019,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":16,"keyword":"微博热点16","heat":1901347,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":17,"keyword":"微博热点17","heat":620072,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":18,"keyword":"微博热点18","heat":1309066,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":19,"keyword":"微博热点19","heat":919629,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":20,"keyword":"微博热点20","heat":1059637,"trend":"上升","url":"https://s.weibo.com/top/summary"}]},{"platform":"kuaishou","success":true,"data":[{"rank":1,"keyword":"快手热点1","heat":292801,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":2,"keyword":"快手热点2","heat":706594,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":3,"keyword":"快手热点3","heat":425306,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":4,"keyword":"快手热点4","heat":851108,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":5,"keyword":"快手热点5","heat":484524,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":6,"keyword":"快手热点6","heat":659116,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":7,"keyword":"快手热点7","heat":862710,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":8,"keyword":"快手热点8","heat":363934,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":9,"keyword":"快手热点9","heat":773486,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":10,"keyword":"快手热点10","heat":651212,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":11,"keyword":"快手热点11","heat":646667,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":12,"keyword":"快手热点12","heat":604851,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":13,"keyword":"快手热点13","heat":261476,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":14,"keyword":"快手热点14","heat":594089,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":15,"keyword":"快手热点15","heat":323250,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":16,"keyword":"快手热点16","heat":873593,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":17,"keyword":"快手热点17","heat":614014,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":18,"keyword":"快手热点18","heat":219065,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":19,"keyword":"快手热点19","heat":284755,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":20,"keyword":"快手热点20","heat":106837,"trend":"下降","url":"https://www.kuaishou.com/search/"}]},{"platform":"bilibili","success":true,"data":[{"rank":1,"keyword":"B站热点1","heat":1239013,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":2,"keyword":"B站热点2","heat":1125161,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":3,"keyword":"B站热点3","heat":742402,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":4,"keyword":"B站热点4","heat":1378627,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":5,"keyword":"B站热点5","heat":1028307,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":6,"keyword":"B站热点6","heat":1326742,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":7,"keyword":"B站热点7","heat":450221,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":8,"keyword":"B站热点8","heat":223250,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":9,"keyword":"B站热点9","heat":778274,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":10,"keyword":"B站热点10","heat":414073,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":11,"keyword":"B站热点11","heat":532834,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":12,"keyword":"B站热点12","heat":1153135,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":13,"keyword":"B站热点13","heat":300816,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":14,"keyword":"B站热点14","heat":1154125,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":15,"keyword":"B站热点15","heat":1303172,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":16,"keyword":"B站热点16","heat":913517,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":17,"keyword":"B站热点17","heat":568524,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":18,"keyword":"B站热点18","heat":1414710,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":19,"keyword":"B站热点19","heat":1248374,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":20,"keyword":"B站热点20","heat":430254,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"}]}]	\N	5	0	0	20
a4ff6e9c-804e-47ce-9850-714d0e66b028	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 15:30:00.237	2025-12-28 15:30:03.628	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3391
86f775a3-1dad-4e31-988b-63df1a83e9d6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 18:40:00.874	2025-12-28 18:40:05.974	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5100
09d578bd-88bd-434d-90f8-40f31c580d34	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:50:00.657	2025-12-25 17:50:03.792	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3137
f2fd2ea2-54fb-4b43-ae70-c95d7425af04	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:20:00.438	2025-12-26 23:20:04.051	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3616
c12393b7-20b6-43f6-9f5b-fba868176b6c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:50:00.676	2025-12-28 00:50:04.992	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4316
bfafa799-bc7c-4bee-ba2d-61a837369f70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 07:20:00.23	2025-12-27 07:20:04.124	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3896
678c061f-4e0b-4a57-95d8-c05de9e139e7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 20:50:00.51	2025-12-28 20:50:03.935	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3426
c3425d83-670d-4964-b529-af9dc62fa250	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:20:00.664	2025-12-27 14:20:03.961	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3298
d024462a-baa4-4908-ae59-48ef313e710b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 03:40:00.678	2025-12-28 03:40:03.888	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3210
da6f893a-ad19-4e54-80da-8b7b922906c7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:10:00.771	2025-12-27 17:10:04.131	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3361
e2191058-54cf-4dac-8643-12766b9fe0df	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:00:00.74	2025-12-27 20:00:03.797	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3058
430c83bf-7e6c-420f-a557-edff2c1c5e21	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 06:30:00.924	2025-12-28 06:30:04.695	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3771
d87c267e-afcc-448d-8ff4-97b7227ee460	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 23:40:00.845	2025-12-28 23:40:04.156	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3313
1ae8e094-5eac-4bb1-a872-91ce967e52a2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 09:20:00.233	2025-12-28 09:20:03.934	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3701
9c178b3f-4210-48aa-a380-3173af5e9199	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 12:00:00.534	2025-12-28 12:00:04.937	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4403
aee15e88-e841-4343-b9d3-cbde276a2556	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 15:40:00.202	2025-12-28 15:40:04.007	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3805
237d358c-3488-4ea7-9e9e-ac5fb9c0b64a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 18:50:00.959	2025-12-28 18:50:04.605	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3646
7e8fdb64-7d57-4cae-8745-8ff02592f705	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:00:00.448	2025-12-25 18:00:03.611	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3164
8f9b0ada-5e63-459f-bb2c-e036eda50a84	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:30:00.323	2025-12-26 23:30:03.74	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3420
41c7f32d-32a8-4c32-80d7-d9436c9d26de	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:00:00.534	2025-12-28 01:00:02.702	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2168
7296a567-0a85-48f6-8483-d17deee4d163	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 09:20:00.687	2025-12-27 09:20:05.26	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4574
2d66b3aa-7a58-4222-8393-50709c9ea9cc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 21:00:00.374	2025-12-28 21:00:04.177	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3803
c737e91b-0500-41f7-bae6-1299f680a251	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:30:00.287	2025-12-27 14:30:03.438	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3152
bd3ff014-9a8b-4fcc-9724-7ddaca364fa2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 03:50:00.721	2025-12-28 03:50:04.55	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3829
e454adea-23f2-425b-a1d0-a74bf995cc52	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:20:00.891	2025-12-27 17:20:04.494	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3605
05f95db3-67b4-424b-b10a-8d579db9e28a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:10:00.162	2025-12-27 20:10:03.429	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3267
a2318e50-5fbd-4934-98cb-78e71116b7a1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 06:40:00.939	2025-12-28 06:40:04.126	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3187
b274d550-be88-459c-aee4-ea90ce5286ab	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 23:50:00.636	2025-12-28 23:50:04.058	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3423
6da5fc61-7d86-45c3-8ff6-8b598ea3db82	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 09:30:00.775	2025-12-28 09:30:04.418	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3643
eaf5b643-af29-4be1-b34d-beb7fcd92532	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 12:10:00.314	2025-12-28 12:10:03.75	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3436
a993cc4e-7ebe-4a4a-94e0-851c5205e21f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 15:50:00.162	2025-12-28 15:50:03.646	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3484
b0ce66a9-5f3e-4e94-920e-fbb69f447b5c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:10:00.104	2025-12-25 18:10:03.407	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3304
91dc75a6-6dfb-4806-be0c-d304c7a5640b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:40:00.184	2025-12-26 23:40:02.41	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2227
c06b58b2-8546-479b-b983-f65be5143c4f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:10:00.142	2025-12-28 01:10:03.402	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3260
7562c32e-c6a0-40b1-ad88-fe9f8ee99e3d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 09:50:00.252	2025-12-27 09:50:04.053	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3802
9054feb6-8862-4048-bcd0-46b4f8f6c171	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 21:10:00.822	2025-12-28 21:10:04.709	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3888
3f327094-b506-4b90-a5da-513e316534cf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:40:00.951	2025-12-27 14:40:03.2	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2249
f46d0344-1f9e-4012-9069-215932500817	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 04:00:00.706	2025-12-28 04:00:02.882	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2176
8492dc7d-3dff-4fac-b595-2bc5d84e8dbb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:30:00.984	2025-12-27 17:30:04.279	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3297
b5dcd5df-a1d1-4d60-ac36-fc2e42b75643	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:20:00.823	2025-12-27 20:20:03.337	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2514
15cbbe8a-9fab-4a99-b5f9-015c5149af65	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 06:50:00.955	2025-12-28 06:50:04.675	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3720
813feec4-a9f6-4f40-a66f-107472e18902	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 00:00:00.386	2025-12-29 00:00:03.485	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3100
440f43cf-f82c-4d86-97ec-cb8dd569eb85	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 09:40:00.558	2025-12-28 09:40:03.904	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3346
03fea1b2-10e0-4182-bb6a-cf07f4ae5a37	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 12:20:00.221	2025-12-28 12:20:05.77	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5551
eefad77e-aefc-4a0d-87bf-8c1531c9f6ab	\N	每日热搜抓取	all	2025-12-28 16:00:00.137	2025-12-28 16:00:00.169	success	hotsearch	[{"platform":"douyin","success":true,"data":[{"rank":1,"keyword":"抖音热点1","heat":853545,"trend":"上升","url":"https://douyin.com/search/"},{"rank":2,"keyword":"抖音热点2","heat":502267,"trend":"下降","url":"https://douyin.com/search/"},{"rank":3,"keyword":"抖音热点3","heat":714727,"trend":"上升","url":"https://douyin.com/search/"},{"rank":4,"keyword":"抖音热点4","heat":1027958,"trend":"下降","url":"https://douyin.com/search/"},{"rank":5,"keyword":"抖音热点5","heat":513353,"trend":"上升","url":"https://douyin.com/search/"},{"rank":6,"keyword":"抖音热点6","heat":610553,"trend":"下降","url":"https://douyin.com/search/"},{"rank":7,"keyword":"抖音热点7","heat":971399,"trend":"上升","url":"https://douyin.com/search/"},{"rank":8,"keyword":"抖音热点8","heat":316168,"trend":"下降","url":"https://douyin.com/search/"},{"rank":9,"keyword":"抖音热点9","heat":820783,"trend":"上升","url":"https://douyin.com/search/"},{"rank":10,"keyword":"抖音热点10","heat":995240,"trend":"下降","url":"https://douyin.com/search/"},{"rank":11,"keyword":"抖音热点11","heat":264221,"trend":"上升","url":"https://douyin.com/search/"},{"rank":12,"keyword":"抖音热点12","heat":967156,"trend":"下降","url":"https://douyin.com/search/"},{"rank":13,"keyword":"抖音热点13","heat":939640,"trend":"上升","url":"https://douyin.com/search/"},{"rank":14,"keyword":"抖音热点14","heat":282870,"trend":"下降","url":"https://douyin.com/search/"},{"rank":15,"keyword":"抖音热点15","heat":367383,"trend":"下降","url":"https://douyin.com/search/"},{"rank":16,"keyword":"抖音热点16","heat":720187,"trend":"下降","url":"https://douyin.com/search/"},{"rank":17,"keyword":"抖音热点17","heat":533639,"trend":"上升","url":"https://douyin.com/search/"},{"rank":18,"keyword":"抖音热点18","heat":115633,"trend":"下降","url":"https://douyin.com/search/"},{"rank":19,"keyword":"抖音热点19","heat":592831,"trend":"下降","url":"https://douyin.com/search/"},{"rank":20,"keyword":"抖音热点20","heat":922531,"trend":"上升","url":"https://douyin.com/search/"}]},{"platform":"xiaohongshu","success":true,"data":[{"rank":1,"keyword":"小红书热点1","heat":944028,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":2,"keyword":"小红书热点2","heat":709538,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":3,"keyword":"小红书热点3","heat":725984,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":4,"keyword":"小红书热点4","heat":856538,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":5,"keyword":"小红书热点5","heat":964659,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":6,"keyword":"小红书热点6","heat":321270,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":7,"keyword":"小红书热点7","heat":706321,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":8,"keyword":"小红书热点8","heat":144584,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":9,"keyword":"小红书热点9","heat":867816,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":10,"keyword":"小红书热点10","heat":725521,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":11,"keyword":"小红书热点11","heat":252232,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":12,"keyword":"小红书热点12","heat":380076,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":13,"keyword":"小红书热点13","heat":653732,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":14,"keyword":"小红书热点14","heat":611192,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":15,"keyword":"小红书热点15","heat":906253,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":16,"keyword":"小红书热点16","heat":913696,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":17,"keyword":"小红书热点17","heat":984348,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":18,"keyword":"小红书热点18","heat":777683,"trend":"上升","url":"https://xiaohongshu.com/search_result/"},{"rank":19,"keyword":"小红书热点19","heat":281291,"trend":"下降","url":"https://xiaohongshu.com/search_result/"},{"rank":20,"keyword":"小红书热点20","heat":1089012,"trend":"上升","url":"https://xiaohongshu.com/search_result/"}]},{"platform":"weibo","success":true,"data":[{"rank":1,"keyword":"微博热点1","heat":626646,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":2,"keyword":"微博热点2","heat":1381159,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":3,"keyword":"微博热点3","heat":1559589,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":4,"keyword":"微博热点4","heat":2168768,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":5,"keyword":"微博热点5","heat":1779544,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":6,"keyword":"微博热点6","heat":1941704,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":7,"keyword":"微博热点7","heat":1152070,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":8,"keyword":"微博热点8","heat":2458219,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":9,"keyword":"微博热点9","heat":603243,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":10,"keyword":"微博热点10","heat":602968,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":11,"keyword":"微博热点11","heat":1001347,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":12,"keyword":"微博热点12","heat":2041474,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":13,"keyword":"微博热点13","heat":2229576,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":14,"keyword":"微博热点14","heat":1195157,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":15,"keyword":"微博热点15","heat":2096094,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":16,"keyword":"微博热点16","heat":2480561,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":17,"keyword":"微博热点17","heat":1884655,"trend":"下降","url":"https://s.weibo.com/top/summary"},{"rank":18,"keyword":"微博热点18","heat":1583858,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":19,"keyword":"微博热点19","heat":910845,"trend":"上升","url":"https://s.weibo.com/top/summary"},{"rank":20,"keyword":"微博热点20","heat":826008,"trend":"下降","url":"https://s.weibo.com/top/summary"}]},{"platform":"kuaishou","success":true,"data":[{"rank":1,"keyword":"快手热点1","heat":473990,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":2,"keyword":"快手热点2","heat":666823,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":3,"keyword":"快手热点3","heat":535551,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":4,"keyword":"快手热点4","heat":200178,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":5,"keyword":"快手热点5","heat":342925,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":6,"keyword":"快手热点6","heat":562524,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":7,"keyword":"快手热点7","heat":799302,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":8,"keyword":"快手热点8","heat":149915,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":9,"keyword":"快手热点9","heat":383016,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":10,"keyword":"快手热点10","heat":724186,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":11,"keyword":"快手热点11","heat":580993,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":12,"keyword":"快手热点12","heat":546668,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":13,"keyword":"快手热点13","heat":803206,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":14,"keyword":"快手热点14","heat":448133,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":15,"keyword":"快手热点15","heat":465304,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":16,"keyword":"快手热点16","heat":820980,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":17,"keyword":"快手热点17","heat":219281,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":18,"keyword":"快手热点18","heat":685713,"trend":"上升","url":"https://www.kuaishou.com/search/"},{"rank":19,"keyword":"快手热点19","heat":90603,"trend":"下降","url":"https://www.kuaishou.com/search/"},{"rank":20,"keyword":"快手热点20","heat":460817,"trend":"上升","url":"https://www.kuaishou.com/search/"}]},{"platform":"bilibili","success":true,"data":[{"rank":1,"keyword":"B站热点1","heat":660168,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":2,"keyword":"B站热点2","heat":844324,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":3,"keyword":"B站热点3","heat":1218451,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":4,"keyword":"B站热点4","heat":757079,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":5,"keyword":"B站热点5","heat":709714,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":6,"keyword":"B站热点6","heat":1677277,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":7,"keyword":"B站热点7","heat":406824,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":8,"keyword":"B站热点8","heat":588841,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":9,"keyword":"B站热点9","heat":1152888,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":10,"keyword":"B站热点10","heat":1266769,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":11,"keyword":"B站热点11","heat":639884,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":12,"keyword":"B站热点12","heat":1625965,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":13,"keyword":"B站热点13","heat":813073,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":14,"keyword":"B站热点14","heat":247799,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":15,"keyword":"B站热点15","heat":1698956,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":16,"keyword":"B站热点16","heat":260187,"trend":"上升","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":17,"keyword":"B站热点17","heat":1485796,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":18,"keyword":"B站热点18","heat":1115849,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":19,"keyword":"B站热点19","heat":922142,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"},{"rank":20,"keyword":"B站热点20","heat":1294135,"trend":"下降","url":"https://www.bilibili.com/v/popular/rank/all"}]}]	\N	5	0	0	32
1a85ae2f-e92b-4c63-9d3a-dc7b5d4d7f0e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 16:00:00.134	2025-12-28 16:00:02.42	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2287
4791a5ae-e2a5-4cbd-9aea-bdf83c7805cc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:20:00.798	2025-12-25 18:20:04.238	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3440
d3bcf379-de65-4b1a-a1e0-4cea8a2eb9a8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:50:00.129	2025-12-26 23:50:03.986	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3858
065aa039-9078-47dc-ba1e-246644bd2cd0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:20:00.202	2025-12-28 01:20:03.873	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3671
3078914a-8146-4512-aca8-ce491d59e218	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:00:00.157	2025-12-27 10:00:03.737	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3581
301cd7d8-e5b9-4342-a2f5-a31fd1daadb2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 21:20:00.656	2025-12-28 21:20:04.052	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3400
682114a8-815b-4f4e-9850-29c8081d6950	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:50:00.615	2025-12-27 14:50:04.093	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3480
af2ef4b4-7d98-4821-b8e3-9834f77971a1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 04:10:00.723	2025-12-28 04:10:03.929	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3206
b2cf60c0-d1d0-4e6b-91a5-cff797726476	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:40:00.104	2025-12-27 17:40:02.279	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2177
dbf0f303-a4a4-4853-8d7a-c5fe83a35baf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:30:00.979	2025-12-27 20:30:04.388	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3409
99824ba1-1eb6-4dfb-8f55-c38b8bf90159	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 07:00:00.985	2025-12-28 07:00:04.302	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3318
d5ce8265-732e-4302-8d8e-e49d0d0f3ee2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 00:10:00.161	2025-12-29 00:10:03.457	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3297
186891f2-a422-4488-872b-cc3af29df64f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 09:50:00.405	2025-12-28 09:50:03.889	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3484
e7895f00-d2b8-4890-8751-26bcf67dc216	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 12:30:00.288	2025-12-28 12:30:02.499	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2213
7117c974-fbb2-44f8-860b-90e141562426	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 16:10:00.085	2025-12-28 16:10:03.515	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3430
46ea4c0d-8fa7-436a-a16e-4776913c317b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:40:00.462	2025-12-25 18:40:03.922	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3461
8ae7786d-c773-482d-a029-ab2569a6e892	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:00:00.457	2025-12-25 19:00:03.775	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3319
00db102e-54ab-410c-9953-b2e64c14cde0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:10:00.694	2025-12-27 01:10:04.238	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3546
2436a598-63be-472f-94ff-886272152184	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:10:00.703	2025-12-25 19:10:04.273	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3570
86f609d4-c3a0-45bc-92e9-e4201e06f75c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:30:00.217	2025-12-28 01:30:02.846	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2630
e6c77508-ddf6-4eb3-8425-8ecca5e61538	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:20:00.804	2025-12-25 19:20:04.524	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3720
8dca3ac9-3713-4dce-ba13-ae002b417d47	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:10:00.094	2025-12-27 10:10:03.33	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3236
37a9f994-6746-47dd-9183-46c909db37a9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:30:00.877	2025-12-25 19:30:05.295	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4419
39921227-3301-415e-8493-6a634afa04e6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 21:30:00.501	2025-12-28 21:30:06.052	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5553
a40b329c-17f3-4730-9158-2eee0234f2f1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:40:00.659	2025-12-25 19:40:04.179	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3520
6f9238ac-59ed-4dd7-a7e4-5304e6cca1a2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:00:00.831	2025-12-27 15:00:04.05	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3220
b82f8af3-a731-4d2a-891c-47f1b168b8ed	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:50:00.73	2025-12-25 19:50:04.094	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3367
a743b11f-2ac4-4720-9d15-4ba7f39f3338	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 04:20:00.758	2025-12-28 04:20:04.707	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3949
a2dd8470-70bb-474c-870f-6d37c8827be6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:00:00.068	2025-12-25 20:00:03.427	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3359
093f34c8-b382-416e-9831-0b7a940798f5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:50:00.439	2025-12-27 17:50:04.063	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3626
09fe2aaf-779b-40f2-8edc-60b021db2dd7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:10:00.273	2025-12-25 20:10:03.749	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3477
a1feae5c-f8fe-4e55-a70f-e467a11455e5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:20:00.063	2025-12-25 20:20:03.394	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3332
253f4813-7b6a-4fdd-98ef-d1357f1ce884	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:40:00.611	2025-12-27 20:40:03.963	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3352
5e043b1b-356c-4dee-913e-1afefebbb0be	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:30:00.542	2025-12-25 20:30:03.879	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3338
3ec2d179-6e82-4ad6-a1d5-c0f11ef1ff5c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 07:10:00.993	2025-12-28 07:10:03.295	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2302
1cc9335b-b6ad-459b-8663-0ece0dcec898	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:40:00.565	2025-12-25 20:40:03.985	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3421
29a35028-96a0-44b8-8775-401f663b99c4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-29 00:20:00.917	2025-12-29 00:20:04.354	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3440
a4a7534c-bc49-44dc-94e9-72432525e650	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:50:00.384	2025-12-25 20:50:03.794	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3411
c6b3b3cc-5c05-4b98-bea4-85f0643a6c02	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 10:00:00.698	2025-12-28 10:00:04.252	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3555
3ef6b414-3f34-4aba-a37e-2f161f83bfd9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 15:50:00.106	2025-12-26 15:50:06.127	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6021
98184ae2-fd58-4fa4-8972-f7c8e48b7253	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:00:00.94	2025-12-26 16:00:05.454	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4514
4ce49b9b-d476-4941-8bc3-db0fed277e1f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 12:40:00.32	2025-12-28 12:40:03.956	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3637
3ce322ad-7ddd-48b4-892d-2f7573064dc2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:10:00.718	2025-12-26 16:10:05.582	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4865
1ce4211a-d614-40ac-973a-5abed3543cde	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:20:00.037	2025-12-26 16:20:04.877	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4840
6a8073c5-d96f-422d-b36a-e46c777c137a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 16:20:00.019	2025-12-28 16:20:03.3	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3281
d5667f64-0886-4562-a41c-02debfd03558	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:40:00.25	2025-12-26 16:40:05.053	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4803
a5ddb50d-388b-449d-969b-3716210f9c6b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:50:00.834	2025-12-26 16:50:05.663	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4829
7e62b4b3-8a3c-4154-9e1d-cef64c31e77f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 17:00:00.514	2025-12-26 17:00:06.814	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6301
c80ca0c2-3774-4d78-b21e-e33430a5524f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 17:20:00.691	2025-12-26 17:20:06.421	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5731
8210dbd2-9539-49b6-b167-cc72d9eda147	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 17:30:00.518	2025-12-26 17:30:03.976	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3459
3fad5238-0923-403e-8017-5039308b15c9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 17:40:00.336	2025-12-26 17:40:03.663	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3327
16a6caf9-5b09-46a8-ae86-1e827f1921e4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 18:30:00.888	2025-12-26 18:30:05.763	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4875
d386c32d-5f2c-48fd-bbb2-89acd4283b99	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 18:40:00.028	2025-12-26 18:40:03.365	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3337
8a51ad93-0e50-4038-8b67-ade2c4a9a776	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 19:00:00.712	2025-12-26 19:00:03.889	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3177
1dcb6c52-2f86-46b3-af30-f5927002bd13	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 19:10:00.722	2025-12-26 19:10:04.067	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3345
5f696217-1f3e-4e89-83ad-a87be8afb64d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 19:20:00.548	2025-12-26 19:20:03.719	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3174
8dceacc5-38a8-4c6d-b106-8c76c4c04ca9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 20:40:00.985	2025-12-26 20:40:05.254	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4270
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.users (id, username, password_hash, is_active, created_at, updated_at, deleted_at, role) FROM stdin;
c0dec882-dc26-4cf2-9a1d-091182232641	testuser	$2a$10$guqfXFXheb2Zd45XLeTnM.9dYtlanNvAtTG7SsGAETjBF2D7OnR42	f	2025-12-23 20:00:47.582063	2025-12-23 20:00:47.608	2025-12-23 20:00:47.608	operator
f940ea3b-246b-429f-9c51-40fe412a7475	testuser123_updated	$2a$10$e/0qTwjyiEqNrsbhD.aIG.gcaGqzmBHR4Jilet0ed8NMF/hmnOvX6	f	2025-12-23 20:10:55.533082	2025-12-23 20:10:55.554	2025-12-23 20:10:55.554	operator
46ca104f-0232-4b98-bc10-0f1c3f9f3214	finaltest_updated	$2a$10$lMtc1V7Pbd5b2qp44tUr1uuOXxpgyUjsAZEs9S1zXtp1XI3UqYV5i	f	2025-12-23 20:19:40.739539	2025-12-23 20:19:40.759	2025-12-23 20:19:40.759	operator
bb093eac-41e9-4cf9-b2b7-f25591c0db45	updateduser	$2a$10$mWRIJOXnNJnNzzcxOwGnseoUZspO7753XsxaiBXgfCSxteDq1i3ki	t	2025-12-23 15:50:12.702327	2025-12-23 15:50:59.815	2025-12-23 15:50:59.815	admin
16f72858-f20a-459f-9456-9fc2ee56c947	yangzai	$2a$10$G4JXUK1OqiK.Fz2arzsn5O/ve6oqWHTqLiS1c2YtusgucU0QWj5OG	t	2025-12-23 15:53:32.482755	2025-12-23 15:54:11.549	\N	admin
8a897d56-88e3-4bd4-9c9f-80a57114c5eb	admin	$2a$10$biJOi8Tb/EJv3qdQ32Vt/OccG7xGET1uKR9odi.YQjcW8vsxNGtXW	t	2025-12-23 15:37:24.570237	2025-12-24 09:07:17.949	\N	admin
fb9f5a5f-a8cc-4c99-a756-274c2f56f39e	123	$2a$10$7I8vJJqSUIp91WwJ4gFaB.kOHbWLInLkBs.CdkEsfypg6s3PmnyLC	t	2025-12-24 09:16:11.995203	2025-12-24 09:16:11.995203	\N	operator
\.


--
-- Name: platform_accounts PK_3ee99dfeb0ac9a79b966cc296f9; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.platform_accounts
    ADD CONSTRAINT "PK_3ee99dfeb0ac9a79b966cc296f9" PRIMARY KEY (id);


--
-- Name: platform_cookies PK_43033d6d9f22511611edb4c0953; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.platform_cookies
    ADD CONSTRAINT "PK_43033d6d9f22511611edb4c0953" PRIMARY KEY (id);


--
-- Name: content_tags PK_6a24e5245d735b48bfe9ca5c1cc; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.content_tags
    ADD CONSTRAINT "PK_6a24e5245d735b48bfe9ca5c1cc" PRIMARY KEY (id);


--
-- Name: crawl_tasks PK_78b96ed0a35c6b1768bb496edce; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.crawl_tasks
    ADD CONSTRAINT "PK_78b96ed0a35c6b1768bb496edce" PRIMARY KEY (id);


--
-- Name: system_settings PK_82521f08790d248b2a80cc85d40; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT "PK_82521f08790d248b2a80cc85d40" PRIMARY KEY (id);


--
-- Name: ai_test_history PK_85aef1bccfae0c40786851cdf46; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.ai_test_history
    ADD CONSTRAINT "PK_85aef1bccfae0c40786851cdf46" PRIMARY KEY (id);


--
-- Name: task_logs PK_9754457a29b4ffbb772e8a3039c; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.task_logs
    ADD CONSTRAINT "PK_9754457a29b4ffbb772e8a3039c" PRIMARY KEY (id);


--
-- Name: users PK_a3ffb1c0c8416b9fc6f907b7433; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY (id);


--
-- Name: ai_analysis_results PK_a628d27356f4fb92c423529e0e9; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.ai_analysis_results
    ADD CONSTRAINT "PK_a628d27356f4fb92c423529e0e9" PRIMARY KEY (id);


--
-- Name: contents PK_b7c504072e537532d7080c54fac; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT "PK_b7c504072e537532d7080c54fac" PRIMARY KEY (id);


--
-- Name: hotsearch_snapshots PK_c30a21ff21cb0ce086cca82ffdf; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.hotsearch_snapshots
    ADD CONSTRAINT "PK_c30a21ff21cb0ce086cca82ffdf" PRIMARY KEY (id);


--
-- Name: ai_configs PK_e062638208222edc23b70e8c31b; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.ai_configs
    ADD CONSTRAINT "PK_e062638208222edc23b70e8c31b" PRIMARY KEY (id);


--
-- Name: tags PK_e7dc17249a1148a1970748eda99; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT "PK_e7dc17249a1148a1970748eda99" PRIMARY KEY (id);


--
-- Name: tags UQ_d90243459a697eadb8ad56e9092; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT "UQ_d90243459a697eadb8ad56e9092" UNIQUE (name);


--
-- Name: users UQ_fe0bb3f6520ee0469504521e710; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_fe0bb3f6520ee0469504521e710" UNIQUE (username);


--
-- Name: IDX_AI_CONFIG_ENABLED; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_CONFIG_ENABLED" ON public.ai_configs USING btree (is_enabled);


--
-- Name: IDX_AI_CONFIG_PRIORITY; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_CONFIG_PRIORITY" ON public.ai_configs USING btree (priority);


--
-- Name: IDX_AI_CONFIG_PROVIDER; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_CONFIG_PROVIDER" ON public.ai_configs USING btree (provider);


--
-- Name: IDX_AI_CONFIG_STATUS; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_CONFIG_STATUS" ON public.ai_configs USING btree (status);


--
-- Name: IDX_AI_RESULT_CONFIG; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_RESULT_CONFIG" ON public.ai_analysis_results USING btree (ai_config_id);


--
-- Name: IDX_AI_RESULT_CONTENT; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_RESULT_CONTENT" ON public.ai_analysis_results USING btree (content_id);


--
-- Name: IDX_AI_RESULT_CONTENT_STATUS; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_RESULT_CONTENT_STATUS" ON public.ai_analysis_results USING btree (content_id, status);


--
-- Name: IDX_AI_RESULT_CREATED; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_RESULT_CREATED" ON public.ai_analysis_results USING btree (created_at);


--
-- Name: IDX_AI_RESULT_STATUS; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_RESULT_STATUS" ON public.ai_analysis_results USING btree (status);


--
-- Name: IDX_AI_TEST_CONFIG; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_TEST_CONFIG" ON public.ai_test_history USING btree (ai_config_id);


--
-- Name: IDX_AI_TEST_CREATED; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_AI_TEST_CREATED" ON public.ai_test_history USING btree (created_at);


--
-- Name: IDX_CONTENT_PLATFORM_CONTENT_ID; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE UNIQUE INDEX "IDX_CONTENT_PLATFORM_CONTENT_ID" ON public.contents USING btree (platform, content_id);


--
-- Name: IDX_CONTENT_TAG_CONTENT; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_CONTENT_TAG_CONTENT" ON public.content_tags USING btree (content_id);


--
-- Name: IDX_CONTENT_TAG_TAG; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_CONTENT_TAG_TAG" ON public.content_tags USING btree (tag_id);


--
-- Name: IDX_CONTENT_TAG_UNIQUE; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE UNIQUE INDEX "IDX_CONTENT_TAG_UNIQUE" ON public.content_tags USING btree (content_id, tag_id);


--
-- Name: IDX_CRAWL_TASK_NEXT_RUN; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_CRAWL_TASK_NEXT_RUN" ON public.crawl_tasks USING btree (next_run_at);


--
-- Name: IDX_CRAWL_TASK_PLATFORM; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_CRAWL_TASK_PLATFORM" ON public.crawl_tasks USING btree (platform);


--
-- Name: IDX_CRAWL_TASK_STATUS; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_CRAWL_TASK_STATUS" ON public.crawl_tasks USING btree (status);


--
-- Name: IDX_HOTSEARCH_PLATFORM_DATE; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE UNIQUE INDEX "IDX_HOTSEARCH_PLATFORM_DATE" ON public.hotsearch_snapshots USING btree (platform, capture_date);


--
-- Name: IDX_PLATFORM_ACCOUNT_PLATFORM; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_PLATFORM_ACCOUNT_PLATFORM" ON public.platform_accounts USING btree (platform);


--
-- Name: IDX_PLATFORM_ACCOUNT_VALID; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_PLATFORM_ACCOUNT_VALID" ON public.platform_accounts USING btree (is_valid);


--
-- Name: IDX_PLATFORM_COOKIE_PLATFORM; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_PLATFORM_COOKIE_PLATFORM" ON public.platform_cookies USING btree (platform);


--
-- Name: IDX_PLATFORM_COOKIE_VALID; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_PLATFORM_COOKIE_VALID" ON public.platform_cookies USING btree (is_valid);


--
-- Name: IDX_TAG_NAME; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE UNIQUE INDEX "IDX_TAG_NAME" ON public.tags USING btree (name);


--
-- Name: IDX_TAG_USAGE_COUNT; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_TAG_USAGE_COUNT" ON public.tags USING btree (usage_count);


--
-- Name: IDX_TASK_LOG_START_TIME; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_TASK_LOG_START_TIME" ON public.task_logs USING btree (start_time, status);


--
-- Name: IDX_TASK_LOG_TASK_ID; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_TASK_LOG_TASK_ID" ON public.task_logs USING btree (task_id);


--
-- Name: IDX_USER_ACTIVE; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_USER_ACTIVE" ON public.users USING btree (is_active);


--
-- Name: IDX_USER_ROLE; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE INDEX "IDX_USER_ROLE" ON public.users USING btree (role);


--
-- Name: IDX_USER_USERNAME; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE UNIQUE INDEX "IDX_USER_USERNAME" ON public.users USING btree (username);


--
-- Name: contents FK_22519c1551f45c21639d529b7f9; Type: FK CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT "FK_22519c1551f45c21639d529b7f9" FOREIGN KEY (task_id) REFERENCES public.crawl_tasks(id);


--
-- Name: ai_analysis_results FK_4ef204a604fb5197fe3cb9befde; Type: FK CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.ai_analysis_results
    ADD CONSTRAINT "FK_4ef204a604fb5197fe3cb9befde" FOREIGN KEY (content_id) REFERENCES public.contents(id) ON DELETE CASCADE;


--
-- Name: ai_test_history FK_8765046462a7ed17b4e78662433; Type: FK CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.ai_test_history
    ADD CONSTRAINT "FK_8765046462a7ed17b4e78662433" FOREIGN KEY (ai_config_id) REFERENCES public.ai_configs(id) ON DELETE CASCADE;


--
-- Name: ai_analysis_results FK_f9fbbb123c88b1d43271b37432f; Type: FK CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.ai_analysis_results
    ADD CONSTRAINT "FK_f9fbbb123c88b1d43271b37432f" FOREIGN KEY (ai_config_id) REFERENCES public.ai_configs(id) ON DELETE SET NULL;


--
-- Name: task_logs FK_fdafd5e130ca3d2a7c12f957c5d; Type: FK CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.task_logs
    ADD CONSTRAINT "FK_fdafd5e130ca3d2a7c12f957c5d" FOREIGN KEY (task_id) REFERENCES public.crawl_tasks(id);


--
-- PostgreSQL database dump complete
--

\unrestrict vFSodJAAlutqLE05hs4eUYMeaLarZPakbztMsVRnJPwWoGPgqGiKei4XKtmgDtd

