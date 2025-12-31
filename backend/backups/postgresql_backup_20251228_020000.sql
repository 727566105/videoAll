--
-- PostgreSQL database dump
--

\restrict lJ8d5bas1ZKGBA7fE5vCaX8rHuLUtlHgW1cM4oaRL8XvbwDEZ1FJXs8oS8Ergf6

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
    completed_at timestamp without time zone
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

COPY public.ai_analysis_results (id, content_id, ai_config_id, analysis_result, generated_tags, confidence_scores, status, retry_count, error_message, execution_time, tokens_used, analysis_type, created_at, updated_at, completed_at) FROM stdin;
716f1940-a2e4-4a95-9eda-d50580632636	f4935144-ccee-4551-a222-ed9885dee8b2	f9192a66-d9ed-4f46-9a28-a92b35800abb	\N	[]	{}	failed	0	不支持的AI提供商: deepseek	36	\N	tag_generation	2025-12-28 01:58:09.378186	2025-12-28 01:58:09.378186	\N
3becb95e-ccda-4e81-9d62-f3e2ea0f1328	f4935144-ccee-4551-a222-ed9885dee8b2	f9192a66-d9ed-4f46-9a28-a92b35800abb	\N	[]	{}	failed	0	不支持的AI提供商: deepseek	1	\N	tag_generation	2025-12-28 01:58:11.471445	2025-12-28 01:58:11.471445	\N
f2ae9566-d9cd-4729-9340-60ed5252e38b	f4935144-ccee-4551-a222-ed9885dee8b2	f9192a66-d9ed-4f46-9a28-a92b35800abb	\N	[]	{}	failed	0	不支持的AI提供商: deepseek	2	\N	tag_generation	2025-12-28 01:58:15.485152	2025-12-28 01:58:15.485152	\N
f65b1772-9fdd-42ea-b894-d5d7a0f2afdf	f4935144-ccee-4551-a222-ed9885dee8b2	f9192a66-d9ed-4f46-9a28-a92b35800abb	\N	[]	{}	failed	0	不支持的AI提供商: deepseek	1	\N	tag_generation	2025-12-28 01:58:29.419287	2025-12-28 01:58:29.419287	\N
b092260d-477c-4e87-90d3-40795a2a9e93	f4935144-ccee-4551-a222-ed9885dee8b2	f9192a66-d9ed-4f46-9a28-a92b35800abb	\N	[]	{}	failed	0	不支持的AI提供商: deepseek	2	\N	tag_generation	2025-12-28 01:58:31.439826	2025-12-28 01:58:31.439826	\N
c6fe3031-9115-48fa-88f3-5d260ff07294	f4935144-ccee-4551-a222-ed9885dee8b2	f9192a66-d9ed-4f46-9a28-a92b35800abb	\N	[]	{}	failed	0	不支持的AI提供商: deepseek	2	\N	tag_generation	2025-12-28 01:58:35.46011	2025-12-28 01:58:35.46011	\N
\.


--
-- Data for Name: ai_configs; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.ai_configs (id, provider, api_endpoint, api_key_encrypted, model, timeout, is_enabled, priority, preferences, status, created_at, updated_at, last_test_at, imported_at, exported_at, last_rotation_at) FROM stdin;
f9192a66-d9ed-4f46-9a28-a92b35800abb	deepseek	https://api.deepseek.com/v1/chat/completions	fa61fb523885f4a2eb92161f57e77dc9:f13c8470b4ebc08de993e9ffb38d1ea1b0c0793ee85925a0fb0dea0ad32795cd43be74af73786a7837f0a7f0306432aa	DeepSeek Chat	60000	t	0	\N	active	2025-12-28 01:54:51.592963	2025-12-28 01:54:51.592963	2025-12-28 01:58:01.936	\N	\N	\N
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
\.


--
-- Data for Name: contents; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.contents (id, platform, content_id, title, author, description, media_type, file_path, cover_url, source_url, source_type, created_at, task_id, all_images, all_videos, like_count, comment_count, share_count, publish_time, tags, collect_count, view_count, is_missing) FROM stdin;
ea422f78-f302-4c53-af1e-1557edd557d9	xiaohongshu	694ab5e6000000001f004f4e	阳光很好	叽里呱啦		live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/阳光很好_694ab5e6000000001f004f4e	http://sns-webpic-qc.xhscdn.com/202512262049/5588dcf407118b19f89d4c0af1ea51e4/notes_pre_post/1040g3k031qekt7167o205n21vv1hrjcdaecrhq8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/694ab5e6000000001f004f4e?xsec_token=ABdx3d5ixiq1hq9c6AX9JrcT3VclEJ1X4AcnT7mELDRR4=&xsec_source=pc_like	1	2025-12-26 20:49:52.249	\N	["http://sns-webpic-qc.xhscdn.com/202512262049/5588dcf407118b19f89d4c0af1ea51e4/notes_pre_post/1040g3k031qekt7167o205n21vv1hrjcdaecrhq8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/e4bb3306ee6671696f0b576a4c4711a8/notes_pre_post/1040g3k031qekt7167o2g5n21vv1hrjcdvt86dio!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/7733259dd3763d8baa9e9c1270dd912d/notes_pre_post/1040g3k031qekt7167o305n21vv1hrjcd6uop5l8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/42938bbe2c19a02e96c02bba1db49607/notes_pre_post/1040g3k031qekt7167o3g5n21vv1hrjcd6hgt9b0!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94ab5d51d6b87010050039b4bd6cb20_19.mp4"]	0	0	4	\N	[]	0	0	f
1296cfe2-614a-413c-abda-fe5c3eb6dd66	xiaohongshu	6942c31c000000001d03de9c	🌺	燕燕u点笨	#来拍照了[话题]##纯欲风[话题]# #惠州西湖[话题]##live图[话题]##三角梅的浪漫[话题]##开心至上[话题]##好天气[话题]##喜欢就发喽[话题]# #存在于每一个当下[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/🌺_6942c31c000000001d03de9c	http://sns-webpic-qc.xhscdn.com/202512262050/c870d8b156abded38f790ac18b5557d1/1040g00831q6rtc1mn20049iqug88vd6ia57pncg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/6942c31c000000001d03de9c?xsec_token=ABgChbnCrgAgY6UmNQTc1gu5_uhR2Xy6LOCsRYy4_vrkQ=&xsec_source=pc_like	1	2025-12-26 20:50:17.885	\N	["http://sns-webpic-qc.xhscdn.com/202512262050/c870d8b156abded38f790ac18b5557d1/1040g00831q6rtc1mn20049iqug88vd6ia57pncg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/3005ede1b5b8e8c602d924a68dbd40da/1040g00831q6rtc1mn20g49iqug88vd6iiq3sb60!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/88d9d62b45b893955b7fdd27ddc01541/1040g00831q6rtc1mn21049iqug88vd6ib86i1c0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/95661d6f25d1daf53aa3fa6a6f37a59a/1040g00831q6rtc1mn21g49iqug88vd6if7nrin0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/e91444ee6df38737f6bcda3c3f65ddd5/1040g00831q6rtc1mn22g49iqug88vd6i35g7no8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/2cfacfd4554611238c56d33bd899cd67/1040g00831q6rtc1mn22049iqug88vd6iq9omgsg!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e942c30363ac4d010050039b2cf7da47_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e942c306640966010050039b2cf7d84e_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e942c309640de9010050039b2cf7d98c_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e942c30c6412d1010050039b2cf7e7c7_19.mp4","http://sns-bak-v1.xhscdn.com/stream/1/10/19/01e942c30e274cdc010050039b2cf7d336_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e942c311641a3d010050039b2cf7d89a_19.mp4"]	0	0	8	\N	[]	0	0	f
59b4a550-9590-43c3-9b41-eb0b10b1bcaf	xiaohongshu	694a2555000000000d038f83	本命年内衣！红得超正，聚拢效果更是一绝	多情猫	到底谁还没挖到这件红内衣？\n聚拢不压胸，新年穿它，好运 + 事业线双丰收\n#多情猫内衣[话题]# #聚拢内衣[话题]# #本命年红色套装[话题]# #新年红[话题]# #红色内衣[话题]# #红色氛围感[话题]# #多情猫[话题]# #聚拢内衣就穿多情猫[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/本命年内衣！红得超正，聚拢效果更是一绝_694a2555000000000d038f83	http://sns-webpic-qc.xhscdn.com/202512262123/200654d346ca4ac0a6d0f8ca9b85a003/spectrum/1040g34o31qe377n4gm105nv4aa809dof2p4865g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694a2555000000000d038f83?xsec_token=ABEU_34yv7jxXLA3D19ZuXamMgWHaiW8Edgx5WNz8iadw=&xsec_source=pc_feed	1	2025-12-26 21:23:55.964	\N	["http://sns-webpic-qc.xhscdn.com/202512262123/200654d346ca4ac0a6d0f8ca9b85a003/spectrum/1040g34o31qe377n4gm105nv4aa809dof2p4865g!nd_dft_wlteh_jpg_3"]	["http://sns-video-qc.xhscdn.com/stream/1/110/258/01e94a2555dd6e7f010370019b49a2196a_258.mp4?sign=5287afbc91f4f434e4ee8650be6bad01&t=695329ab"]	0	1	0	\N	[]	0	0	f
48e7650d-e9ed-4530-91f3-7c367a3598e9	xiaohongshu	694ca75e000000001f0088f4	专家：或许是气候变化导致	四川观察		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/专家：或许是气候变化导致_694ca75e000000001f0088f4	http://sns-webpic-qc.xhscdn.com/202512251914/243e77531c3a1d6850ed6b1a47086099/spectrum/1040g0k031qghl3c3n4005nth5veg89inb9n2jq8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694ca75e000000001f0088f4?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNYWH7S2XNs17BdMneTBH9VY=&xsec_source=pc_feed	1	2025-12-25 19:14:01.481	\N	["http://sns-webpic-qc.xhscdn.com/202512251914/243e77531c3a1d6850ed6b1a47086099/spectrum/1040g0k031qghl3c3n4005nth5veg89inb9n2jq8!nd_dft_wlteh_jpg_3"]	["http://sns-video-hs.xhscdn.com/stream/79/110/258/01e94ca73c615b4d4f0370019b536defe1_258.mp4","http://sns-bak-v1.xhscdn.com/stream/79/110/258/01e94ca73c615b4d4f0370019b536defe1_258.mp4"]	0	0	0	\N	[]	0	0	f
02d41e9d-b99a-4aa3-9b56-3e2e6ca8255a	xiaohongshu	694e549e000000001e0266c1	162｜115斤 总在冬天怀念夏天	66小宝	在冬天遇到很适合海边的碎花裙\n#开始期待夏天啦[话题]# #在冬天想念夏天[话题]# #穿搭[话题]# #162穿搭[话题]# #115斤[话题]# #美女穿搭[话题]# #碎花裙[话题]# #海边穿搭[话题]# #海边[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/162｜115斤_总在冬天怀念夏天_694e549e000000001e0266c1	http://sns-webpic-qc.xhscdn.com/202512261903/8f92284eed55a128e638f792f4ba008b/1040g00831qi5vimp0ae05q7kt0htt7funvbodvg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e549e000000001e0266c1?xsec_token=AB7MH_8h2mYcgfxpQlXwonGoeEyPIZVIpxAE9Il4UfxQY=&xsec_source=pc_feed	1	2025-12-26 19:03:53.004	\N	["http://sns-webpic-qc.xhscdn.com/202512261903/8f92284eed55a128e638f792f4ba008b/1040g00831qi5vimp0ae05q7kt0htt7funvbodvg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261903/59e30bfe905b25201ad753401fcdca72/1040g00831qi5vimp0aeg5q7kt0htt7furfbgip8!nd_dft_wlteh_jpg_3"]	[]	0	2	0	\N	[]	0	0	f
6641a335-00a2-4406-9d08-4d3ee0525452	xiaohongshu	694800f9000000001e0167fb	这视角真的太好拍啦📷	snkrs	#上海citywalk[话题]# #这里拍照很出片[话题]# #沙美大楼[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/这视角真的太好拍啦📷_694800f9000000001e0167fb	http://sns-webpic-qc.xhscdn.com/202512262124/574924b54b0a2968159a9ac9092e90ee/1040g2sg31qc09h21mui05pf1ukb19nfa1j9v9f0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694800f9000000001e0167fb?xsec_token=ABMgrfZDNkghfZFaXgfEExOLmrDSINKNlorfTjZ_9Y23U=&xsec_source=pc_feed	1	2025-12-26 21:24:59.575	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/574924b54b0a2968159a9ac9092e90ee/1040g2sg31qc09h21mui05pf1ukb19nfa1j9v9f0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/02cf0279131dc684aa8c3c5c056ddf3d/1040g2sg31qc09h21muj05pf1ukb19nfam9hbhpo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/24f7a8db78ef115e1ab590b2c9e25e03/1040g2sg31qc09h21muh05pf1ukb19nfa8q06jb8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/0ce40e85cc90eaea71e3ae1b236c4e81/1040g2sg31qc09h21muhg5pf1ukb19nfa0m8rvfo!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
443c68f5-411d-434c-80c9-64d5ccfade8b	xiaohongshu	69435ada000000001e0043ab	🎄🧑‍🎄	小肥猪babe	#微胖[话题]# #不过圣诞节[话题]# #出门吃出圣诞氛围感[话题]# #微胖穿搭[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/🎄🧑‍🎄_69435ada000000001e0043ab	http://sns-webpic-qc.xhscdn.com/202512262050/45d4c69bc3922c79fc3747d15cc20e4b/notes_pre_post/1040g3k831q7f1es4gc7040n7kcm5j44ibf1n46o!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/69435ada000000001e0043ab?xsec_token=ABIpReBHB-C3bJ8DQc_9mG5ex731KeufXHxwf6szngxX4=&xsec_source=pc_like	1	2025-12-26 20:50:22.111	\N	["http://sns-webpic-qc.xhscdn.com/202512262050/45d4c69bc3922c79fc3747d15cc20e4b/notes_pre_post/1040g3k831q7f1es4gc7040n7kcm5j44ibf1n46o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/73b8884d019c8db70d9e67cfde8d9c08/notes_pre_post/1040g3k831q7f1es4gc7g40n7kcm5j44i42k4pig!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/9cf5cc0fdc9c59d14ae28e5c2c96f942/notes_pre_post/1040g3k831q7f1es4gc8040n7kcm5j44i4u3ttp8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/b6be9552ba069eefa4a2a2bef78b8f5e/notes_pre_post/1040g3k831q7f1es4gc8g40n7kcm5j44iiovao4o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/e904a923fcfeab3c7256f7f2110cefa4/notes_pre_post/1040g3k831q7f1es4gc9040n7kcm5j44iljos238!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/344fa2bd445c73431583039fc6fd1940/notes_pre_post/1040g3k831q7f1es4gc9g40n7kcm5j44itlvna2g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/e3abc3bb8246945e245703329dba1986/notes_pre_post/1040g3k831q7f1es4gca040n7kcm5j44ih6gmk8o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/037abf71fb63232be35aba8db450441b/notes_pre_post/1040g3k831q7f1es4gcag40n7kcm5j44infob940!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/31bc630aac18cd6dcf2d21460156b7e5/notes_pre_post/1040g3k831q7f1es4gcb040n7kcm5j44id8rv14o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/ec1254a680e3758baa17dce8866a3185/notes_pre_post/1040g3k831q7f1es4gcbg40n7kcm5j44i07pq210!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/ad674138b0cab43e618454170870162d/notes_pre_post/1040g3k831q7f1es4gcc040n7kcm5j44i3lk994o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/1e8d55ef4ce9a9211251fa383890d975/notes_pre_post/1040g3k831q7f1es4gccg40n7kcm5j44iks4vc1g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/6efe8e193cb67e03015ea2ca6c36272f/notes_pre_post/1040g3k831q7f1es4gcd040n7kcm5j44iipflok8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/4a8ebdb6d3caa79ab7fbef442fea89ad/notes_pre_post/1040g3k831q7f1es4gcdg40n7kcm5j44iqls00io!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/aec9587f82078f544231a51dd61af48d/notes_pre_post/1040g3k831q7f2i65727g40n7kcm5j44igfkve00!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/63aaf8a3ea8ad8b57a6aa00b.jpg"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9435ac3642d97010050039b348f7b51_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9435ac5643078010050039b348f8562_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9435ac6643233010050039b348f805f_19.mp4","http://sns-bak-v1.xhscdn.com/stream/1/10/19/01e9435ac86382a4010050039b348f89b2_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9435ace638ab8010050039b348f8690_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9435ad0638cb8010050039b348f8064_19.mp4"]	0	0	0	\N	[]	0	0	f
38ce1c59-14d2-42a8-9485-db152fbc9e59	xiaohongshu	694e715d000000001e008739	🎄又一年圣诞了🥂	nonomaddy	圣诞和朋友聚聚，隐藏在武定路的氛围感bar，环境真的很chill，能在这儿拍照聊天抽水烟呆一整天～\n他们家是只做黑料但是对入门的朋友也特别友好，如果是初学者也会帮你调整做的很顺！\n小吃菜单比大部分bar多，烧鸟也是特色！还会再来～\n#fyp[话题]# #位置隐匿的小众酒吧[话题]# #氛围酒吧微醺时刻[话题]# #圣诞快乐[话题]##Shisha[话题]##Hookah[话题]##上海水烟吧[话题]##圣诞的氛围感[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/🎄又一年圣诞了🥂_694e715d000000001e008739	http://sns-webpic-qc.xhscdn.com/202512262052/cc2fd8ea2ca0e556b35985bc9c48d84e/notes_pre_post/1040g3k031qi9dp5tn22g418hl1kbd474t9b9jug!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e715d000000001e008739?xsec_token=AB7MH_8h2mYcgfxpQlXwonGnmNn7p7jolU3-HjZvO6dIE=&xsec_source=pc_feed	1	2025-12-26 20:52:32.685	\N	["http://sns-webpic-qc.xhscdn.com/202512262052/cc2fd8ea2ca0e556b35985bc9c48d84e/notes_pre_post/1040g3k031qi9dp5tn22g418hl1kbd474t9b9jug!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/5a866c50799373fc222c27a3ab84b73e/notes_pre_post/1040g3k031qi9dp5tn230418hl1kbd474rdeibq8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/f33d053d52a4467882eae64d262c82fa/notes_pre_post/1040g3k031qi9dp5tn23g418hl1kbd474g55n338!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/eeb442a506b46cdc76cec6d57c652712/notes_pre_post/1040g3k031qi9dp5tn240418hl1kbd474qv5276g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/45cf35cf8e0612990abf72d2461790f2/notes_pre_post/1040g3k031qi9dp5tn24g418hl1kbd4741oo2eg8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/70395b55d2d276705d834a07eb8107f1/notes_pre_post/1040g3k031qi9dp5tn250418hl1kbd4741q2qe38!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/115d7185f82b0e503f5469963f886597/notes_pre_post/1040g3k031qi9dp5tn25g418hl1kbd474gg9hap0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/b3f3a740b33c0289518f32295845bb7b/note_pre_post_uhdr/1040g3r831qi8nnlun2cg418hl1kbd4746u8sjo8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/89e851af480c38da88b1e38f32fb63af/note_pre_post_uhdr/1040g3r831qi8nnlun2d0418hl1kbd47473e0gro!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/a4337c2a33d0d3310154e9734ae142ce/notes_pre_post/1040g3k031qi9dp5tn260418hl1kbd474nt94mmg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262052/4a4b8414c897019006abb990becb1cd0/note_pre_post_uhdr/1040g3r831qi8nnlun2dg418hl1kbd474dgioa1g!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e7145216fab010050039b5a6afe20_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e714661960f010050039b5a6af928_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e71486069b0010050039b5a6b0156_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e714921086a010050039b5a6af9b4_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e714b2171f9010050039b5a6af846_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e714d619803010050039b5a6afc34_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e7150606c6b010050039b5a6af4ec_19.mp4"]	0	9	0	\N	[]	0	0	f
0e1fbde3-4c47-4250-8875-53595eed8428	xiaohongshu	694ce877000000001d03baf7	圣诞收到不一样的平安果，春节还能用	漳州优美饰纸业有限公司		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/圣诞收到不一样的平安果，春节还能用_694ce877000000001d03baf7	http://sns-webpic-qc.xhscdn.com/202512251924/33bbf0a898fed2c1d4245d54a57145a8/spectrum/1040g34o31qgph957n4105njgcmvg915ukubvpjo!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694ce877000000001d03baf7?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNU3gA2TRKp2sZMoCK5hWcvs=&xsec_source=pc_feed	1	2025-12-25 19:24:02.857	\N	["http://sns-webpic-qc.xhscdn.com/202512251924/33bbf0a898fed2c1d4245d54a57145a8/spectrum/1040g34o31qgph957n4105njgcmvg915ukubvpjo!nd_dft_wlteh_jpg_3"]	["http://sns-video-hs.xhscdn.com/stream/1/110/258/01e94ce73c1d5de3010370019b546c3462_258.mp4","http://sns-bak-v1.xhscdn.com/stream/1/110/258/01e94ce73c1d5de3010370019b546c3462_258.mp4"]	0	0	0	\N	[]	0	0	f
267685c5-a3ac-4edb-8686-03504a4f31e0	xiaohongshu	694e1302000000001e009e9c	圣诞快乐哦🎄：）	被你踩过的蚂蚁		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/圣诞快乐哦🎄：）_694e1302000000001e009e9c	http://sns-webpic-qc.xhscdn.com/202512261904/bde23839f4163c4d21a8d3a9c2797f3f/1040g2sg31qhtunls707g4b4padlroorgkhqtlp0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e1302000000001e009e9c?xsec_token=AB7MH_8h2mYcgfxpQlXwonGuIvBqPw-tYhLSMK5VVz0Uo=&xsec_source=pc_feed	1	2025-12-26 19:04:16.315	\N	["http://sns-webpic-qc.xhscdn.com/202512261904/bde23839f4163c4d21a8d3a9c2797f3f/1040g2sg31qhtunls707g4b4padlroorgkhqtlp0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261904/4a225807bf70541d93456cb2eb7805d4/1040g2sg31qhtunls70904b4padlroorgvd122eo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261904/344cd43053b54c490e1c0535bb286558/1040g2sg31qhtunls70804b4padlroorg4fc01fo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261904/000ab678a2d8c515ab947018ad04bc3c/1040g2sg31qhtunls70704b4padlroorg5s0tft0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261904/3a1d8be6db3e1736a7e9217bed0e6b74/1040g2sg31qhtunls708g4b4padlroorg7u6ikq8!nd_dft_wgth_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/62978f875173dc9214e1c3e2.jpg"]	[]	0	0	0	\N	[]	0	0	f
9f749f66-cca0-45ca-8130-3c07ee42fe26	xiaohongshu	6949f344000000000d035548	House of cb裙子	谢啦啦	Pick一个最爱\n还是第一个，露肤度没那么高\n#度假裙[话题]# #连衣裙分享[话题]# #连身裙[话题]# #法式吊带裙[话题]# #好看的小裙子[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/House_of_cb裙子_6949f344000000000d035548	http://sns-webpic-qc.xhscdn.com/202512262049/f20f80ed1a971280173442cafa1470db/notes_pre_post/1040g3k831qdsvhee7g9048ptimp823tdiav3ta8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/6949f344000000000d035548?xsec_token=AB7ibZaMW_irzv5axoWFD2zTzrfYMThteZ-wMNfxVaGgc=&xsec_source=pc_like	1	2025-12-26 20:49:56.008	\N	["http://sns-webpic-qc.xhscdn.com/202512262049/f20f80ed1a971280173442cafa1470db/notes_pre_post/1040g3k831qdsvhee7g9048ptimp823tdiav3ta8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/2f2b21aaa44551568ac7b589050b3eba/notes_pre_post/1040g3k831qdsvhee7g9g48ptimp823tdd5tn6to!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/5159544b9dc5cb5cc48d99806cf0597e/notes_pre_post/1040g3k831qdsvhee7ga048ptimp823td334hl50!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/0b6304025ac8d146ebe7d3b564b86097/notes_pre_post/1040g3k831qdsvhee7gag48ptimp823td60a7iig!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e949f31d1a8c02010050039b48de6f1d_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e949f3201f8502010050039b48de7a75_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e949f3231f88d2010050039b48de75ff_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e949f3271d7d06010050039b48de75c6_19.mp4"]	0	0	0	\N	[]	0	0	f
45884b5d-e2ac-404a-bb36-2ddfd92b9753	xiaohongshu	694e62a0000000001e02f7d3	好美！程潇气质太超前了	一粒小沙子	#女爱豆[话题]# #女明星[话题]# #气质女明星[话题]# #又美又飒[话题]# #每个她都闪闪发光[话题]# #气质女神[话题]# #程潇[话题]# #kpop[话题]# #女明星日常[话题]# #女神[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/好美！程潇气质太超前了_694e62a0000000001e02f7d3	http://sns-webpic-qc.xhscdn.com/202512261908/1d593eeb607dbabc2ee0cbab7698f16e/notes_pre_post/1040g3k031qi7k975g0005pkanrj3uth9ha03830!nd_dft_wlteh_jpg_3	http://xhslink.com/o/2TnKgljF6MO	1	2025-12-26 19:08:54.645	\N	["http://sns-webpic-qc.xhscdn.com/202512261908/1d593eeb607dbabc2ee0cbab7698f16e/notes_pre_post/1040g3k031qi7k975g0005pkanrj3uth9ha03830!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261908/c598b4f8e97d3635c5c78f5110a17084/notes_pre_post/1040g3k031qi7k975g00g5pkanrj3uth9175lotg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261908/ee8cb1de88236e73b58572523a5e6eb4/notes_pre_post/1040g3k031qi7k975g0105pkanrj3uth9odbmsc8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261908/076fbb49ba98a3959720daa857ad06b7/notes_pre_post/1040g3k031qi7k975g01g5pkanrj3uth9hsi923o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261908/89d75fd45c18fb245dd7c4a69d6708ee/notes_pre_post/1040g3k031qi7k975g0205pkanrj3uth969pbt8g!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
f4869e31-792b-464e-bc81-139687e32459	xiaohongshu	69462130000000000d03d907	周白子裙子yyds	财宝	在大连穿还好 估计再北点就太冷穿不了了\n#超好看的神仙裙子[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/周白子裙子yyds_69462130000000000d03d907	http://sns-webpic-qc.xhscdn.com/202512262050/9c99b80d94933647a61982edddbf0996/notes_pre_post/1040g3k031qa5kbm97o004a3is1ub9qkf3pgotk8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/69462130000000000d03d907?xsec_token=ABgfKvyw1P60vAveIZGkid4gHRrRcWZHIWqRU31564VDk=&xsec_source=pc_like	1	2025-12-26 20:50:01.162	\N	["http://sns-webpic-qc.xhscdn.com/202512262050/9c99b80d94933647a61982edddbf0996/notes_pre_post/1040g3k031qa5kbm97o004a3is1ub9qkf3pgotk8!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9462016275557010050039b39f1c82d_19.mp4"]	0	0	0	\N	[]	0	0	f
e131b0c0-389f-4f1d-b59c-653073a3183e	xiaohongshu	694bc8a5000000001e003ba1	未知标题	是雨萱丫		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/未知标题_694bc8a5000000001e003ba1	http://sns-webpic-qc.xhscdn.com/202512251931/8ed50c42f378a6ffb7523851999ad6c1/1040g2sg31qfme48e745g5q84m51sje66iinej38!nd_dft_wgth_jpg_3	https://www.xiaohongshu.com/explore/694bc8a5000000001e003ba1?xsec_token=ABxsq7Xz1iUVyVGKtiYw9uFklW6t_Crx7AQv58s_0OTeE=&xsec_source=pc_feed	1	2025-12-25 19:31:46.818	\N	["http://sns-webpic-qc.xhscdn.com/202512251931/8ed50c42f378a6ffb7523851999ad6c1/1040g2sg31qfme48e745g5q84m51sje66iinej38!nd_dft_wgth_jpg_3"]	["http://sns-video-hs.xhscdn.com/stream/1/110/258/01e94bc8a51d4280010370019b500811e7_258.mp4"]	0	0	0	\N	[]	0	0	f
0b7a8212-1518-4cda-bcd4-365d226622a9	xiaohongshu	694a5d8a000000001e0271a4	好久没出来旅游了	Vivi	好久没去那么远的地方了，要多拍几张美美的照片，好歹也是半年前刚填的熊，现在穿什么都格外的带了点属性，穿不下的感觉，难道是衣服又小了吗，可复查的时候说小了一点点的呀，就保留了八九层不过不用担心了，后面就稳定了不会再变动了\n#脂肪填胸[话题]##分享[话题]##旅游[话题]##霓珀美学咨询[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/好久没出来旅游了_694a5d8a000000001e0271a4	http://sns-webpic-qc.xhscdn.com/202512261652/1339943c1188d29991e11e4290da8a06/1040g00831qea55g9ng0g5pjo76gjcp2cic4jdn8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694a5d8a000000001e0271a4?xsec_token=ABEU_34yv7jxXLA3D19ZuXalXmt3YDdnbFKjM-MOKrDMQ=&xsec_source=pc_feed	1	2025-12-26 16:52:50.411	\N	["http://sns-webpic-qc.xhscdn.com/202512261652/1339943c1188d29991e11e4290da8a06/1040g00831qea55g9ng0g5pjo76gjcp2cic4jdn8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261652/0136c9dddf743fa25c6e54a69bc18ac1/1040g00831qea55g9ng105pjo76gjcp2cmr8dvk8!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
bbcc400e-657b-41f3-b7c9-c29377c67f2b	xiaohongshu	69367333000000001e039fbc	从烦恼到舒展，我的身形与心态都变了	智惠	谁懂那种失去形态支撑的烦恼？穿什么都显得臃肿没精神，整个人状态都不对劲……\n但现在的我，真的完全不同了！这半年多来，整个人从内到外都舒展了。\n之前，在建议下我选择了motiva。整个过程比想象中顺利，恢复后最让我惊喜的是获得了理想的支撑感和挺拔感。现在无论动态静态，形态都非常自然流畅，那种平躺时依然柔和的线条，真的让我特别满意。\n改变后最有趣的是，身边亲近的闺蜜并没发现“具体哪里变了”，只是好奇我怎么突然穿衣服更好看，人也更精致了。\n如今大半年过去，状态依然维持得很好。这次改变带给我的，远不止是外在的调整，更是由内而外接纳自己、喜欢自己的底气和自信。\n#motiva[话题]## #变美日记[话题]##身材管理[话题]##日常[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/从烦恼到舒展，我的身形与心态都变了_69367333000000001e039fbc	http://sns-webpic-qc.xhscdn.com/202512262050/e46bfdd99119b89d6fceab093ceea41a/notes_pre_post/1040g3k031pqrl4lgl2005p2oe7o452mkdfrslfg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/69367333000000001e039fbc?xsec_token=ABgH10mXoroKYlnVx65TY4shCPIfSxaWFJ4ALlEkJzEV0=&xsec_source=pc_like	1	2025-12-26 20:50:27.71	\N	["http://sns-webpic-qc.xhscdn.com/202512262050/e46bfdd99119b89d6fceab093ceea41a/notes_pre_post/1040g3k031pqrl4lgl2005p2oe7o452mkdfrslfg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/704adc5f376b9fcbe5c827f3b004d4b4/1040g00831q553d1mno1g5p2oe7o452mk49ufu4g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/ddad59ca3264cdfef11cd854c2292f02/1040g00831q553d1mno105p2oe7o452mk2vff6i0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/2c17f36ccb341908d7447835c84ab4f1/notes_pre_post/1040g3k031pqrl4lgl20g5p2oe7o452mk96rl0uo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/71f591ded75340294cdbdaf5a7ce1e04/notes_pre_post/1040g3k031pqrl4lgl2105p2oe7o452mke77k790!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/1ae2dc56121155d8ecea146414e7197d/1040g00831q553d1mno005p2oe7o452mkbrotn6o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/4523f0634749f03390cdc365c2ce7023/1040g00831q553d1mno0g5p2oe7o452mkrp26d0g!nd_dft_wlteh_jpg_3","https://picasso-static.xiaohongshu.com/fe-platfrom/bc740cc162107169b504c4c1e5ee35f92eaa8456.png"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e93672e921fd49010050039b25de191a_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e940fd632219cd010050039b25de1e35_19.mp4"]	0	0	0	\N	[]	0	0	f
6075ca2b-470e-4498-89c2-3a080d05f145	xiaohongshu	694d5a3e0000000021031a19	未知标题	snow	🎄	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/未知标题_694d5a3e0000000021031a19	http://sns-webpic-qc.xhscdn.com/202512262123/ebee3abfb07434b9dad0e05693000ac8/notes_pre_post/1040g3k031qh7ef380a004a7ag6ug3eoocnjuhu0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694d5a3e0000000021031a19?xsec_token=AB_yTc4-DAaR3t-JL6ZhYtDFBR4Tbaqu4QWQJ9Sds2NJ4=&xsec_source=pc_feed	1	2025-12-26 21:23:31.981	\N	["http://sns-webpic-qc.xhscdn.com/202512262123/ebee3abfb07434b9dad0e05693000ac8/notes_pre_post/1040g3k031qh7ef380a004a7ag6ug3eoocnjuhu0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/18d9e1102be92ca047ad0e5274c242be/notes_pre_post/1040g3k031qh7ef380a0g4a7ag6ug3eoo883svk8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/ef2bec95e7fee8e50c3248002fa6ea52/notes_pre_post/1040g3k031qh7ef380a104a7ag6ug3eoo4h8kfq8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/4e06c0ea62ef2ac72b5d6988b9306667/notes_pre_post/1040g3k031qh7ef380a1g4a7ag6ug3eoooomgjbo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/81bfb0a9bdc682e498f75892343a3b98/notes_pre_post/1040g3k031qh7ef380a204a7ag6ug3eoojod8ps8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/4c91d8dcbde6834f94dc4ca6218a30e0/notes_pre_post/1040g3k031qh7ef380a2g4a7ag6ug3eoo6n3fc6g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/fdd5c56d21281042f66aea3b9294b1b5/notes_pre_post/1040g3k031qh7ef380a304a7ag6ug3eoo0r78osg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/d477755137d874697892a68d29878f58/notes_pre_post/1040g3k031qh7ef380a3g4a7ag6ug3eookt405t8!nd_dft_wlteh_jpg_3"]	[]	0	9	8	\N	[]	0	0	f
b6a56f53-162b-4a82-bdd7-d5c0b9d2b827	xiaohongshu	694e30ff000000001f0096a4	红	lele酱		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/红_694e30ff000000001f0096a4	http://sns-webpic-qc.xhscdn.com/202512262123/489ee40f5a80dee7d25c51e628596bf2/1040g00831qi1m7vdno1g5p9kgl3h1c49kseac10!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e30ff000000001f0096a4?xsec_token=AB7MH_8h2mYcgfxpQlXwonGkKNnMlKh24uzZl2-byaDsc=&xsec_source=pc_feed	1	2025-12-26 21:23:46.292	\N	["http://sns-webpic-qc.xhscdn.com/202512262123/489ee40f5a80dee7d25c51e628596bf2/1040g00831qi1m7vdno1g5p9kgl3h1c49kseac10!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/7fcbc722fa7f2e3d958265b4475449bf/1040g00831qi1m7vdno105p9kgl3h1c49ltoj06g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/a119163a96481ad1bf41acf7c1ed16e2/1040g00831qi1m7vdno205p9kgl3h1c49vnr6s1g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/62b0b9dece2a6f087f541d0df39511be/1040g00831qi1m7vdno005p9kgl3h1c499spoi20!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262123/2bddf1f745fe546c414b6f49c5f5caf3/1040g00831qi1m7vdno0g5p9kgl3h1c49qjsmifo!nd_dft_wlteh_jpg_3"]	[]	0	9	0	\N	[]	0	0	f
e46340e0-e693-43e1-889e-ec0214f62dc7	xiaohongshu	694cb0b2000000001e03a3f1	圣诞 快乐	Monica魔女		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/圣诞_快乐_694cb0b2000000001e03a3f1	http://sns-webpic-qc.xhscdn.com/202512262124/68424494e666100706e5fd061f806c01/notes_pre_post/1040g3k831qgipnnqng704a1622tfar55g2ttei8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694cb0b2000000001e03a3f1?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNclFwM9tcVXgVym8W65Osjs=&xsec_source=pc_feed	1	2025-12-26 21:24:13.717	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/68424494e666100706e5fd061f806c01/notes_pre_post/1040g3k831qgipnnqng704a1622tfar55g2ttei8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/b7676780a3937c14133a6f035a8e3ee0/notes_pre_post/1040g3k831qgipnnqng7g4a1622tfar55u39ota0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/62b6076169b61f6fa17abcf13d5897cd/notes_pre_post/1040g3k831qgipnnqng804a1622tfar55sges8c8!nd_dft_wlteh_jpg_3"]	[]	0	4	7	\N	[]	0	0	f
ab15d3e5-7669-48a1-98b4-b39ef17e6fac	xiaohongshu	694dffea000000001e034c55	在厦门过圣诞🎄还可以穿裙子！！	小小猪🐷	不是很冷哈哈哈哈 俺可以坚持！\n#甜妹[话题]# #可甜可御可温柔[话题]# #厦门[话题]# #圣诞节日穿搭[话题]# #圣诞快乐[话题]# #厦门探店[话题]# #当个甜美女孩[话题]# #谁能拒绝甜妹[话题]# #御姐[话题]# #美女[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/在厦门过圣诞🎄还可以穿裙子！！_694dffea000000001e034c55	http://sns-webpic-qc.xhscdn.com/202512261656/f2f714704b9299090ac15fbab4a1e072/notes_pre_post/1040g3k831qhrlea6ga705nmbh7s081tuvbs7q70!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694dffea000000001e034c55?xsec_token=AB_yTc4-DAaR3t-JL6ZhYtDGHlxHdOQVN04mmMzCtX3_I=&xsec_source=pc_feed	1	2025-12-26 16:57:00.105	\N	["http://sns-webpic-qc.xhscdn.com/202512261656/f2f714704b9299090ac15fbab4a1e072/notes_pre_post/1040g3k831qhrlea6ga705nmbh7s081tuvbs7q70!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/999b494e7a72ec2bf8ba87dfda677f35/notes_pre_post/1040g3k831qhrlea6ga7g5nmbh7s081tu1on1ru8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/dda77cbd1f86b927bff7e95866b9d644/1040g2sg31qhrptqjg0705nmbh7s081tub1rvtjo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/f8e596a243fb3a6af8c32889cdbcae7c/notes_pre_post/1040g3k831qhrlea6ga805nmbh7s081tue4drfl0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/5bf3d2fe0a0d50ea22e69956d30974a9/notes_pre_post/1040g3k831qhrlea6ga8g5nmbh7s081tudueadio!nd_dft_wlteh_jpg_3"]	["http://sns-video-bd.xhscdn.com/stream/1/10/19/01e94dff9d1fb585010050039b58b25a59_19.mp4","http://sns-bak-v1.xhscdn.com/stream/1/10/19/01e94e00911d62b6010050039b58b261c7_19.mp4"]	0	5	2	\N	[]	0	0	f
b9b9511b-1676-4705-8f67-9112a2b7661a	xiaohongshu	6943cf25000000001e00216c	-	liU		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/-_6943cf25000000001e00216c	http://sns-webpic-qc.xhscdn.com/202512261909/8a9a6dfd0691bcab5bb1ab9a34851f37/notes_pre_post/1040g3k831q7t8ml9gc7g5q7m60ndtvq0fkusfl8!nd_dft_wlteh_jpg_3	http://xhslink.com/o/1Xs0PFGLIYI	1	2025-12-26 19:09:41.534	\N	["http://sns-webpic-qc.xhscdn.com/202512261909/8a9a6dfd0691bcab5bb1ab9a34851f37/notes_pre_post/1040g3k831q7t8ml9gc7g5q7m60ndtvq0fkusfl8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261909/1dc9b93c61efb6fa4890e974b1e50b08/notes_pre_post/1040g3k831q7t8ml9gc705q7m60ndtvq0h8bvdj8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261909/824b890b2f00cf63f296448ec3cff781/notes_pre_post/1040g3k831q7t8ml9gc805q7m60ndtvq02vu528o!nd_dft_wlteh_jpg_3"]	[]	0	8	0	\N	[]	0	0	f
7583a70c-1835-46b4-a489-39e8bdfee317	xiaohongshu	694e82c6000000001e02c901	你在就好了	CC-	#清纯[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/你在就好了_694e82c6000000001e02c901	http://sns-webpic-qc.xhscdn.com/202512262051/670577764895bb802c1f9da4eac87054/notes_pre_post/1040g3k831qibl5ne7g405ouq7olpt81j3roprcg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e82c6000000001e02c901?xsec_token=AB7MH_8h2mYcgfxpQlXwonGh5OoApYSFnSq_VhJQ-twbs=&xsec_source=pc_feed	1	2025-12-26 20:51:41.547	\N	["http://sns-webpic-qc.xhscdn.com/202512262051/670577764895bb802c1f9da4eac87054/notes_pre_post/1040g3k831qibl5ne7g405ouq7olpt81j3roprcg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262051/076cc08e5b697b4b704fa65400ed7e79/notes_pre_post/1040g3k831qibl5ne7g505ouq7olpt81j22ttdlg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262051/7d445c9319d42042cbed09e0bd540781/notes_pre_post/1040g3k831qibl5ne7g4g5ouq7olpt81jlrl8hp8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262051/849033df2a2569d058b6abce2c9e6fdc/notes_pre_post/1040g3k831qibl5ne7g5g5ouq7olpt81jd5n5p10!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
ca895d0a-60be-480c-a659-bd697406b24f	xiaohongshu	694f5af0000000001f00b134	素颜也很纯	爱哭鬼阿悦🌙.	#微胖[话题]# #甜妹[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/素颜也很纯_694f5af0000000001f00b134	http://sns-webpic-qc.xhscdn.com/202512271926/65c48498723f72f351066ad0b9844ca2/notes_pre_post/1040g3k031qj62jbhnu005p367m5aa9qdhi99gf8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694f5af0000000001f00b134?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VMCJ34t1YLHYp5ic1olY6b8=&xsec_source=pc_feed	1	2025-12-27 19:26:42.306	\N	["http://sns-webpic-qc.xhscdn.com/202512271926/65c48498723f72f351066ad0b9844ca2/notes_pre_post/1040g3k031qj62jbhnu005p367m5aa9qdhi99gf8!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
8820efe7-64be-4821-bd35-f13d5abf65ef	xiaohongshu	694f46b70000000022023e9e	看得出她是公主👑	Huhu安（虎虎）	#公主裙[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/看得出她是公主👑_694f46b70000000022023e9e	http://sns-webpic-qc.xhscdn.com/202512272347/d0a36ed71c5a9a803226712e5cc012f4/1040g2sg31qj3g52agae05nm6b7o08menb4kprt8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694f46b70000000022023e9e?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VBnx6yeymzNjKyqvwFDWeeE=&xsec_source=pc_feed	1	2025-12-27 23:47:28.015	\N	["http://sns-webpic-qc.xhscdn.com/202512272347/d0a36ed71c5a9a803226712e5cc012f4/1040g2sg31qj3g52agae05nm6b7o08menb4kprt8!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/79/110/258/01e94f46b460a1214f0370019b5daca88c_258.mp4"]	0	0	0	\N	[]	0	0	f
090d8ede-8c13-48d1-9b07-5f216f4f3430	xiaohongshu	694e5124000000001e02f647	𐂂𝓜𝓮𝓻𝓻𝔂  𝓒𝓱𝓻𝓲𝓼𝓽𝓶𝓪𝓼˚♬🎄	口子	#不是今天拍的[话题]# #妆个新人设[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/𐂂𝓜𝓮𝓻𝓻𝔂_𝓒𝓱𝓻𝓲𝓼𝓽𝓶𝓪𝓼˚♬🎄_694e5124000000001e02f647	http://sns-webpic-qc.xhscdn.com/202512262049/9cd23fb7907570b378e3a36255945258/notes_pre_post/1040g3k831qi449fsg0b05o1ghe70bv6i3rbgb38!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e5124000000001e02f647?xsec_token=AB7MH_8h2mYcgfxpQlXwonGlHzE2Mzfbdv2daenyNFQqc=&xsec_source=pc_feed	1	2025-12-26 20:49:27.446	\N	["http://sns-webpic-qc.xhscdn.com/202512262049/9cd23fb7907570b378e3a36255945258/notes_pre_post/1040g3k831qi449fsg0b05o1ghe70bv6i3rbgb38!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/7b12f9b80da4dbe268d807ccfce55306/notes_pre_post/1040g3k831qi449fsg0bg5o1ghe70bv6i7grrnno!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/d74ec696e9bf08232992729dc2ee22bd/notes_pre_post/1040g3k831qi449fsg0c05o1ghe70bv6iotfqmn0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/eeee91d576fef47b1254f23b4222cc01/notes_pre_post/1040g3k831qi449fsg0cg5o1ghe70bv6imrr120g!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e94e50d11a8ad7010050039b59f116e3_19.mp4"]	0	0	0	\N	[]	0	0	f
b6beb249-e4d4-45d9-a842-40869fddb602	xiaohongshu	694d1297000000001f004982	仓山地铁洋房，79平，原175万，现99万‼️	婷你说房🍀		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/仓山地铁洋房，79平，原175万，现99万‼️_694d1297000000001f004982	http://sns-webpic-qc.xhscdn.com/202512251852/76dd8994c0b5611f86387a1e2827c804/notes_pre_post/1040g3k831qgpb1377o805pappha0ms0p17cnhq8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694d1297000000001f004982?xsec_token=AB_yTc4-DAaR3t-JL6ZhYtDIJr2AvS-7Y2A8pHFMgLWPw=&xsec_source=pc_feed	1	2025-12-25 18:52:27.775	\N	["http://sns-webpic-qc.xhscdn.com/202512251852/76dd8994c0b5611f86387a1e2827c804/notes_pre_post/1040g3k831qgpb1377o805pappha0ms0p17cnhq8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512251852/3d276d6da382fc6eab177b14a648d219/notes_pre_post/1040g3k831qgpb1377ocg5pappha0ms0p39d9mfg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512251852/79ee38e7e1608d78b542474633e82da1/notes_pre_post/1040g3k831qgpb1377o705pappha0ms0p83ojl90!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512251852/5805d87c49b7483a096f71a3053239ce/notes_pre_post/1040g3k831qgpb1377o7g5pappha0ms0p46doud0!nd_dft_wlteh_jpg_3"]	[]	1	0	1	\N	[]	0	0	f
1d0a2f72-bf30-44ea-9b5e-3e3f7dacbccc	xiaohongshu	694b4589000000001e01373e	MiniMax M2.1 国产最强 Coding 模型	星纬智联Stellarlink		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/MiniMax_M2.1_国产最强_Coding_模型_694b4589000000001e01373e	http://sns-webpic-qc.xhscdn.com/202512252002/0c076c9e1012377da4c9216c40d1ae77/spectrum/1040g34o31qf6esld0m705p240tk3ovng1ugva88!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694b4589000000001e01373e?xsec_token=ABxsq7Xz1iUVyVGKtiYw9uFh9Iyu21__OqdvhFPciDBho=&xsec_source=pc_feed	1	2025-12-25 20:02:37.466	\N	["http://sns-webpic-qc.xhscdn.com/202512252002/0c076c9e1012377da4c9216c40d1ae77/spectrum/1040g34o31qf6esld0m705p240tk3ovng1ugva88!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/32ae9ed72f8432dfc75565c83a7b6b2b/spectrum/1040g34o31qf6esld0m7g5p240tk3ovngso3f0ag!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/485fc6c670c1a87ca8def44130748b62/spectrum/1040g34o31qf6esld0m805p240tk3ovngm6u8u7g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/90802cc1abec813bad8e4d7a829a1e89/spectrum/1040g34o31qf6esld0m8g5p240tk3ovngtn3bpb8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/6b53f9f8e22e06f2d1be4f52b1b3671e/spectrum/1040g34o31qf6esld0m905p240tk3ovngi6qkqsg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/a46babe42146d045541ca105579fbfff/spectrum/1040g34o31qf6esld0m9g5p240tk3ovngd41ov0o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/e3385659cd8684a6ada01c3cf89de2ed/spectrum/1040g34o31qf6esld0ma05p240tk3ovngsdn72u0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/2597e261cb4ed06a764a8172b4adb7ba/spectrum/1040g34o31qf6esld0mag5p240tk3ovng4klvh5g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/dfde8a51ceaf58fd12d0f7ec6e51f1dc/spectrum/1040g34o31qf6esld0mb05p240tk3ovnghhcvrbo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/0d6432618a25215774539b0f549b2279/spectrum/1040g34o31qf6esld0mbg5p240tk3ovngr61gev8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/02e24d2971adbdc88a35b9ba54bc9481/spectrum/1040g34o31qf6esld0mc05p240tk3ovngrog5jto!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/97bf7f89ff76788269ad3603f9d14e95/spectrum/1040g34o31qf6esld0mcg5p240tk3ovngid10kuo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/33f818533e99cc54fd05708f7fac7ef3/spectrum/1040g34o31qf6esld0md05p240tk3ovngn9eq2ng!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/b05e64d45f58c6c49da5f9f1b06ca4f1/spectrum/1040g34o31qf6esld0mdg5p240tk3ovngh9ctogg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512252002/b4884b69846136949d4a302677d44d38/spectrum/1040g0k031qf6eso8n00g5p240tk3ovnga3gelto!nd_dft_wlteh_jpg_3"]	[]	0	0	2	\N	[]	0	0	f
75987a49-21d5-44a6-9318-2720a8620156	xiaohongshu	694ce11a000000001e030afc	🏝️☀️🐋	Mzzza.	这两天去海南过夏天啦 真的好喜欢海南的天气[大笑R]\n#氛围感[话题]# #每日穿搭[话题]# #ootd[话题]# #来拍照了[话题]# #海边度假[话题]# #度假裙[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/🏝️☀️🐋_694ce11a000000001e030afc	http://sns-webpic-qc.xhscdn.com/202512261659/dfdd23abcf0cb6404da94d5f07632f2b/notes_pre_post/1040g3k831qgol2t4nuag5p47tii46vckri6i7k8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694ce11a000000001e030afc?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNXc56o3EZzpJCvI7c5GRUxs=&xsec_source=pc_feed	1	2025-12-26 16:59:43.956	\N	["http://sns-webpic-qc.xhscdn.com/202512261659/dfdd23abcf0cb6404da94d5f07632f2b/notes_pre_post/1040g3k831qgol2t4nuag5p47tii46vckri6i7k8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/b2b4ac5d9b6ae78423b2d80e3d8ac139/notes_pre_post/1040g3k831qgol2t4nub05p47tii46vckqh567ro!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/86118875574a0678c0bdbd6af6ae26fa/notes_pre_post/1040g3k031qgomjnnno805p47tii46vck1f7oie8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/9a4b42075da5f5eda609d9f54c872e7a/notes_pre_post/1040g3k831qgol2t4nudg5p47tii46vckgaujmcg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/afc0488a5a0618ecff8fbaf0dda094b7/notes_pre_post/1040g3k031qgomjnnno8g5p47tii46vckdgg14j8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/59e184aa2da1508bd0c36cf06cbd1996/notes_pre_post/1040g3k831qgol2t4nubg5p47tii46vckq2l8fso!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/50c9dd1c47293ba7230b65e075e02898/notes_pre_post/1040g3k831qgol2t4nud05p47tii46vck5mafo90!nd_dft_wgth_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/2902758fe882e6c9b69c553e2c5ed315/notes_pre_post/1040g3k031qgomjnnno705p47tii46vckhc4a7bo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/172e2aad24d6242c27626c49d2741314/notes_pre_post/1040g3k031qgomjnnno7g5p47tii46vckhhh90do!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/57cd8ce885016396e9872fae2c94cb96/notes_pre_post/1040g3k031qgomjnnno905p47tii46vckmmg1ps8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261659/9b1a8e2d10a7dbd3f22d26e461572623/notes_pre_post/1040g3k831qgol2t4nucg5p47tii46vcks4choao!nd_dft_wgth_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/675f8ca377a3f0252732aadd.jpg"]	[]	0	0	0	\N	[]	0	0	f
6f1d0a17-e3e7-4d8f-9523-7eb1093219e4	xiaohongshu	69481cc8000000001e03a65d	第二张图怎么…	屁屁要瘦💨	#微胖穿搭[话题]# #微胖女孩[话题]# #脸和身高各长各的[话题]# #分享图片[话题]# #随便发发你随便看看[话题]# #算了你肯定觉得[话题]# #拍了就要发[话题]# #反正也没人看[话题]# #这辈子拍不出第二张[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/第二张图怎么…_69481cc8000000001e03a65d	http://sns-webpic-qc.xhscdn.com/202512262050/a8bb4c152c711a393cfd550d976203db/notes_pre_post/1040g3k831qc3knriga705neioim08sb9luhsaq0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/69481cc8000000001e03a65d?xsec_token=AB2Oz2pAI8Yd-TTNeNjR5CkljrUQBYEgdbi3zSbShCRSk=&xsec_source=pc_like	1	2025-12-26 20:50:06.033	\N	["http://sns-webpic-qc.xhscdn.com/202512262050/a8bb4c152c711a393cfd550d976203db/notes_pre_post/1040g3k831qc3knriga705neioim08sb9luhsaq0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/12eb17e11e1939a04efa099e2d280d1a/notes_pre_post/1040g3k831qc3knriga7g5neioim08sb9sgb6480!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/52400281dc50a8a8044100dd3764065e/notes_pre_post/1040g3k831qc3knriga805neioim08sb9t4rd7lo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/5bf78f1ab27f088818476abcc03b8ea4/notes_pre_post/1040g3k831qc3knriga8g5neioim08sb910itrfg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/23236d6a4e136b059f5e2f79441fc436/notes_pre_post/1040g3k831qc3knriga905neioim08sb96nsede0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/d9c9bbccb65a91829549f9ccb341cd59/notes_pre_post/1040g3k831qc3knriga9g5neioim08sb9o2c0dqg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/7641630ed40ae57b36ad49fa0c93e5a2/notes_pre_post/1040g3k831qc3knrigaa05neioim08sb93oi0ldo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/d1435cb139d9c197239b74a56bdf3c23/notes_pre_post/1040g3k831qc3knrigaag5neioim08sb9orv95bo!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e9481c936064bb010050039b41b0a365_19.mp4"]	0	0	4	\N	[]	0	0	f
fd9f7c67-2d73-4b6a-81ef-31ec3076f84c	xiaohongshu	694a15d2000000000d0382d9	把自己平时用的app给上线啦！！	someone		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/把自己平时用的app给上线啦！！_694a15d2000000000d0382d9	http://sns-webpic-qc.xhscdn.com/202512252013/c19f8d4f558b06a0038e4bc5b9ec6d1b/notes_pre_post/1040g3k831qe17ap9ga705nppn3igbvn5drb4ado!nd_dft_wgth_jpg_3	https://www.xiaohongshu.com/explore/694a15d2000000000d0382d9?xsec_token=ABEU_34yv7jxXLA3D19ZuXalWr6zLqHTCLLkaWTBj00_8=&xsec_source=pc_feed	1	2025-12-25 20:13:03.249	\N	["http://sns-webpic-qc.xhscdn.com/202512252013/c19f8d4f558b06a0038e4bc5b9ec6d1b/notes_pre_post/1040g3k831qe17ap9ga705nppn3igbvn5drb4ado!nd_dft_wgth_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/63b0dd24daa810d35a52e5d5.jpg"]	[]	0	0	5	\N	[]	0	0	f
702f878e-56b1-4d6c-a308-a21c1f18dd2a	xiaohongshu	694e465e000000001f00cf8e	迟来的圣诞🎄快乐	Bella💦	要我说，周五才是真正的圣诞🧑‍🎄[吐舌头H]\n\t\n#圣诞快乐[话题]# #不一样的圣诞[话题]# #圣诞节给自己的仪式感[话题]# #圣诞写真[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/迟来的圣诞🎄快乐_694e465e000000001f00cf8e	http://sns-webpic-qc.xhscdn.com/202512261704/005b780c3be5d1737cec54676b0513ec/notes_pre_post/1040g3k831qi48vio00f05okv76r8cmij6hj57lg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e465e000000001f00cf8e?xsec_token=AB7MH_8h2mYcgfxpQlXwonGmCeb_fhwvHbWPiMJBcNS7U=&xsec_source=pc_feed	1	2025-12-26 17:04:31.541	\N	["http://sns-webpic-qc.xhscdn.com/202512261704/005b780c3be5d1737cec54676b0513ec/notes_pre_post/1040g3k831qi48vio00f05okv76r8cmij6hj57lg!nd_dft_wlteh_jpg_3"]	[]	0	3	0	\N	[]	0	0	f
37850121-3b8f-454b-b16c-c036b5480538	xiaohongshu	694baa2e000000001e008383	河边就餐	芸儿	在河边聚会，多烂漫，好久没这样出来，这氛围绝了吧会不会，刚填的熊，前面一段时间都没这样打扮，因为感觉太早了，万一还没过恢复期又吸收了就麻烦了，现在稳下来了就好多了，怎么穿都可以，就是凉凉的，还得买大一点衣服\n#脂肪填胸[话题]##分享[话题]##霓珀美学咨询[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/河边就餐_694baa2e000000001e008383	http://sns-webpic-qc.xhscdn.com/202512262049/e2257c8a01780eee85866cd347412a50/notes_pre_post/1040g3k831qfiocfcn0b05pr5cc456e80s0b9g1g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/694baa2e000000001e008383?xsec_token=AB1WwqbTRYdpIUvMfsKVwfj-VPlaP2_oEj3wa9ZBwEQdw=&xsec_source=pc_like	1	2025-12-26 20:49:41.443	\N	["http://sns-webpic-qc.xhscdn.com/202512262049/e2257c8a01780eee85866cd347412a50/notes_pre_post/1040g3k831qfiocfcn0b05pr5cc456e80s0b9g1g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/fa019f1f289ca8b1686534b076864534/notes_pre_post/1040g3k031qfiocgin46g5pr5cc456e8035ba7fg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262049/d20f322c99ec4abdc9956108c92f98f1/notes_pre_post/1040g3k031qfiocgin4605pr5cc456e80g4m4d70!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
c45dfb0e-c32a-4572-9775-d2e8915d6bfc	xiaohongshu	694cd56c000000002200bb2d	南博镇馆之宝金兽被指脱皮掉色	深圳Plus		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/南博镇馆之宝金兽被指脱皮掉色_694cd56c000000002200bb2d	http://sns-webpic-qc.xhscdn.com/202512251908/52b81e3a5c20e0ae22b16b44060b464e/spectrum/1040g0k031qgn7iuj70005oh8gnqk0iugkdlvrsg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694cd56c000000002200bb2d?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNTtHAVr2j8ZNN-BmHZCJeKc=&xsec_source=pc_feed	1	2025-12-25 19:08:43.764	\N	["http://sns-webpic-qc.xhscdn.com/202512251908/52b81e3a5c20e0ae22b16b44060b464e/spectrum/1040g0k031qgn7iuj70005oh8gnqk0iugkdlvrsg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512251908/78fc55e60e82a64ae48a2a0537ffa844/spectrum/1040g0k031qgn7iuj700g5oh8gnqk0iugq796kao!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/63b7bfd77a9edea0a76c8416.jpg"]	[]	0	0	0	\N	[]	0	0	f
6013b4d1-645f-4215-8cfc-fa63ca06cdfa	xiaohongshu	68ad7acf000000001b01d486	库存-1	Water	#扶梯拍照[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/库存-1_68ad7acf000000001b01d486	http://sns-webpic-qc.xhscdn.com/202512262050/2136739d75998f81b91d08005a907c37/1040g00831nj9pvmi5i1048i3ps271es99rh7g88!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87/68ad7acf000000001b01d486?xsec_token=ABI32xtGMjs2GE7rsZ7Iab1UTOcUhR1GjTC4iiUUTRTzQ=&xsec_source=pc_like	1	2025-12-26 20:50:10.438	\N	["http://sns-webpic-qc.xhscdn.com/202512262050/2136739d75998f81b91d08005a907c37/1040g00831nj9pvmi5i1048i3ps271es99rh7g88!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/08446261123a222b5d68d6a99b57ea74/1040g00831ll3c1luli0048i3ps271es9pp0169g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/85924d14bf37aa36e85a8914ffdb13bd/1040g00831ll3c1luli2g48i3ps271es9ubvmglg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/25a6cebb38e06a9e4151a74a9fe95b95/1040g00831nj9pvmi5i2048i3ps271es9n61lttg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/e8b5d68a14d2a58da651b4385db088f5/1040g00831nj9pvmi5i1g48i3ps271es9l2a0ab0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/4307443d9a6e302204b2305b74e50a4c/1040g00831nj9pvmi5i0g48i3ps271es97qig48g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262050/c16c719d0c4281082b268348dd32ab92/1040g00831nj9pvmi5i0048i3ps271es9uig11m8!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/62db698cb56982e02fad5f9c.jpg"]	["http://sns-video-hw.xhscdn.com/stream/1/10/19/01e8ed2bcb7fc2d40100500399de735419_19.mp4","http://sns-bak-v1.xhscdn.com/stream/1/10/19/01e8ad7ac7bd12930100500399de7362be_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e8ad7ac5bca1440100500399de735fa5_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e8ed2bcd3452980100500399de736398_19.mp4","http://sns-bak-v1.xhscdn.com/stream/1/10/19/01e8ed2bce7f8fed0100500399de735b8a_19.mp4","http://sns-video-hw.xhscdn.com/stream/1/10/19/01e8ed2bd07f90150100500399de73625c_19.mp4"]	0	0	0	\N	[]	0	0	f
8c449b55-d684-4dd5-a29e-6a01d4f2d8d6	xiaohongshu	694baafa000000001b020fcd	🎄Christmas eve 🎀🎄想你的圣诞节🔔	桃栗圆	空无一人的宝藏圣诞树哈哈哈超级出片！\n#圣诞树[话题]# #圣诞[话题]# #杭州约拍[话题]# #杭州陪拍[话题]# #杭州短视频拍摄[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/🎄Christmas_eve_🎀🎄想你的圣诞节🔔_694baafa000000001b020fcd	http://sns-webpic-qc.xhscdn.com/202512262052/46c70684e093cbb6de2a3a2fec9fe612/1040g2sg31qfiiems0a204a30l4ngcfnn4n3cm08!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694baafa000000001b020fcd?xsec_token=ABxsq7Xz1iUVyVGKtiYw9uFmiaOkNbDlp6AgLwPvf6VH4=&xsec_source=pc_feed	1	2025-12-26 20:52:12.582	\N	["http://sns-webpic-qc.xhscdn.com/202512262052/46c70684e093cbb6de2a3a2fec9fe612/1040g2sg31qfiiems0a204a30l4ngcfnn4n3cm08!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/79/110/258/01e94beed260657e4f0370019b509d183b_258.mp4"]	0	3	8	\N	[]	0	0	f
a9b2b770-eddb-453d-a110-eb62e73cd33c	xiaohongshu	6943ebb6000000001e014fd5	未知标题	tutu	爱是柔软地注视	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/未知标题_6943ebb6000000001e014fd5	http://sns-webpic-qc.xhscdn.com/202512262124/7dec73b74d34111a135df3938cf9fb8a/notes_pre_post/1040g3k031q80oalb6u105nit2eh08dkvue0n8bg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/6943ebb6000000001e014fd5?xsec_token=ABqoPeUjQbrahoSkA2uGwbIHLn_mOV7qqK5J4IHzQ9254=&xsec_source=pc_feed	1	2025-12-26 21:24:54.25	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/7dec73b74d34111a135df3938cf9fb8a/notes_pre_post/1040g3k031q80oalb6u105nit2eh08dkvue0n8bg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/8eff0a7b03a0913875781c29eb18b77a/notes_pre_post/1040g3k031q80oalb6u1g5nit2eh08dkvceobh5g!nd_dft_wlteh_jpg_3"]	[]	0	0	3	\N	[]	0	0	f
250e37a6-66fd-481e-90f2-dd983f67208a	xiaohongshu	6942a0de000000000d00f88d	拍完直接跳水撤了	玛卡巴卡没有推车	#我的调色是魔法[话题]# #氛围感[话题]# #ootdinspo[话题]# #泳池拍照[话题]# #拍照姿势不重样[话题]# #闪光灯拍照[话题]# #姿势越怪越可爱[话题]# #拍照姿势[话题]# #泳衣拍照[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/拍完直接跳水撤了_6942a0de000000000d00f88d	http://sns-webpic-qc.xhscdn.com/202512262124/8003effcecb4de3498cbc2b54c6cbae9/notes_pre_post/1040g3k031q6o1g9nno705n3demi44u7qfgee338!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/6942a0de000000000d00f88d?xsec_token=ABmtuIbum4_89AOM3VFJ6HYGiBJ637l7d2HZ3p7iTqJf0=&xsec_source=pc_feed	1	2025-12-26 21:24:02.589	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/8003effcecb4de3498cbc2b54c6cbae9/notes_pre_post/1040g3k031q6o1g9nno705n3demi44u7qfgee338!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/9107be5e7cc30f128104fb5959117fc0/notes_pre_post/1040g3k031q6o1g9nno7g5n3demi44u7qocpagto!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/396306f3d2d9539ddfccce830d899817/notes_pre_post/1040g3k031q6o1g9nno805n3demi44u7q6ngivng!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/c67a866940d21ec5b4f5ae06cce86f24/notes_pre_post/1040g3k031q6o1g9nno8g5n3demi44u7qgnjmfr0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/1ddb909eabff44469caa7e8e792d53fb/notes_pre_post/1040g3k031q6o1g9nno905n3demi44u7qtpsh3vo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/c09285e6e3944b1924bdb918b62b61e6/notes_pre_post/1040g3k031q6o1g9nno9g5n3demi44u7q288kphg!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
5d23d24d-138f-4314-a9d3-7356f9402918	xiaohongshu	694def24000000001f00ffbc	海边散步🚶	白白桔	#吹海边的风[话题]# #海边吹吹风[话题]# 素颜就是最好的状态	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/海边散步🚶_694def24000000001f00ffbc	http://sns-webpic-qc.xhscdn.com/202512262124/b8277012be8744fbb46c32ee58301de6/1040g2sg31qhpj3v9gae05oo25sskg5grdq42gg8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694def24000000001f00ffbc?xsec_token=AB_yTc4-DAaR3t-JL6ZhYtDOH6bur48u6ymeaSaK0N1EM=&xsec_source=pc_feed	1	2025-12-26 21:24:08.106	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/b8277012be8744fbb46c32ee58301de6/1040g2sg31qhpj3v9gae05oo25sskg5grdq42gg8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/740eccf9fe09d2b98f7e76e9bac80932/1040g2sg31qhpj3v9gaf05oo25sskg5gr6cc2kc8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/fe37c22eeb37bb53f1e7fccc8558b60b/1040g2sg31qhpj3v9gaeg5oo25sskg5gr1mhcf7g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/84b79254a8e377ca0f24d47519df0e35/1040g2sg31qhpj3v9gafg5oo25sskg5grfvpt03o!nd_dft_wlteh_jpg_3"]	["http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94deee361bcd7010050039b586e575e_19.mp4?sign=997294f456ae3590bb8f684269c84f45&t=695329b7","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94deeed6155b2010050039b586e5d3b_19.mp4?sign=7d3a13487d9d9349d8cee058a144b098&t=695329b7","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94deef9222224010050039b586e59b2_19.mp4?sign=4920407843b5bca320ec632b28423340&t=695329b7","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94def0521dffa010050039b586e583d_19.mp4?sign=4c433bb338f2e514bbeefda9f9dd99d0&t=695329b7"]	0	0	0	\N	[]	0	0	f
30a86ef6-7756-4647-930f-9ec0d7a96166	xiaohongshu	694e012b000000001e035418	实况live 我需要这样的好天气	肉肉	#live图[话题]# #氛围感[话题]# #动漫感[话题]# #实况[话题]# #jk[话题]# #日系[话题]# #ootd[话题]# #种草姬[话题]# #jk穿搭[话题]# #海[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/实况live_我需要这样的好天气_694e012b000000001e035418	http://sns-webpic-qc.xhscdn.com/202512262124/f918ef4ea19e0bcd891312fa10152e47/1040g00831qhb60v7nu205n21q90h9f8kjctpo4g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e012b000000001e035418?xsec_token=AB7MH_8h2mYcgfxpQlXwonGgWT4ym7GvGJKrFr1Fc6U3A=&xsec_source=pc_feed	1	2025-12-26 21:24:21.658	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/f918ef4ea19e0bcd891312fa10152e47/1040g00831qhb60v7nu205n21q90h9f8kjctpo4g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/a0e22b60714d536cd2c8094cff2820b4/1040g00831qhb60v7nu005n21q90h9f8kun8lp00!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/88182c0a1ca7e82f12ed979143209e31/1040g00831qhb60v7nu0g5n21q90h9f8kl6vn2fo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/fac5928154cb7403b1771f38f84d0568/1040g00831qhb60v7nu2g5n21q90h9f8ka2m46ag!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/a35cc40e4e7b6ae16b51b823eeae4f3e/1040g00831qhb60v7nu105n21q90h9f8kk15l5bg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/746eccf051594700533d537399f95abe/1040g00831qhb60v7nu1g5n21q90h9f8k8k76fp0!nd_dft_wlteh_jpg_3"]	["http://sns-bak-v6.xhscdn.com/stream/1/10/19/01e94e012b194600010050039b58b4d6e0_19.mp4","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94e012bed3e9c010050039b58b4d3e8_19.mp4?sign=b1711b8ef0a4e4ed3e6d80db0d2728fa&t=695329c5","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94e012bed3e9d010050039b58b4d2b7_19.mp4?sign=d58548f2bd4c03e41d95f37fdb03db7a&t=695329c5","http://sns-bak-v6.xhscdn.com/stream/1/10/19/01e94e012b2b672c010050039b58b4cc4b_19.mp4","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94e012b194601010050039b58b4f112_19.mp4?sign=1d299767fed0cf0bf919cc8fdedf33d5&t=695329c5","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94e012bed3e9b010050039b58b4e494_19.mp4?sign=03da4ef12a099fa593e1b9c7824fcfe9&t=695329c5"]	0	0	0	\N	[]	0	0	f
751ee457-d282-477c-b1a7-b548bc3ff1df	xiaohongshu	694cf0ba0000000021030fa2	圣诞海南，香港打工人已经晒上海岛太阳了🏖️	狮狮晒太阳	冬天的海岛太阳晒着可真舒服🥰暖洋洋的，人都舒畅了\n#治愈系海岛生活[话题]# #海岛游[话题]# #海边度假[话题]##海南[话题]# #海南万宁[话题]# #海南旅游[话题]# #逃离冬天过夏天[话题]# #阳光与海滩[话题]# #旅游[话题]# #圣诞[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/圣诞海南，香港打工人已经晒上海岛太阳了🏖️_694cf0ba0000000021030fa2	http://sns-webpic-qc.xhscdn.com/202512262124/ff2d2c1b9ced9887968c5d766f2d68e4/1040g00831qgev94u000g4a3tur49knepothq8ko!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694cf0ba0000000021030fa2?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNXVju-4KoVwZ44Pd8VO0ZO8=&xsec_source=pc_feed	1	2025-12-26 21:24:25.753	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/ff2d2c1b9ced9887968c5d766f2d68e4/1040g00831qgev94u000g4a3tur49knepothq8ko!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/4c911f2bd7cf2e7f45009385b50c7563/notes_uhdr/1040g3qg31qgqgc3j7o0g4a3tur49knepr83p7tg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/9f6b84ba3e9c41756f864ab9fa1aa6b2/notes_uhdr/1040g3qg31qgqgc3j7o004a3tur49knephdu7b68!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/63e60652d33732db82452da2.jpg"]	["http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94cf00461854d010050039b548c73d0_19.mp4?sign=e6120767c43c31b574d024b2416a066f&t=695329c9","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94cf02721dde9010050039b548c8a53_19.mp4?sign=419bc6da85f62c3a1bd22dcd9309685b&t=695329c9","http://sns-video-qc.xhscdn.com/stream/1/10/19/01e94cf0b6615510010050039b548c829e_19.mp4?sign=adbbc88dba68f4ef16297c3717878c31&t=695329c9"]	0	0	6	\N	[]	0	0	f
991c6c25-94d6-4d47-8108-89926d66669a	xiaohongshu	694b5a56000000001e020e48	在山里泡个汤♨️	金珠岚	这季节泡温泉好舒服\n浅浅恢复正常作息的一天～\n#去山里泡温泉[话题]# #冬日泡汤时间到[话题]# #一起去泡温泉[话题]#\n#温泉拍照[话题]# #温泉酒店[话题]# #泡汤[话题]# #温泉[话题]# #纯天然温泉[话题]#\n#AtlanticBeach[话题]# #ATLB[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/在山里泡个汤♨️_694b5a56000000001e020e48	http://sns-webpic-qc.xhscdn.com/202512262124/3d06af93392edc2883d02cf44da885a9/1040g2sg31qf90fkcg07048mjuspfrdah9c4n8vo!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694b5a56000000001e020e48?xsec_token=ABxsq7Xz1iUVyVGKtiYw9uFoKag_qaulKSfdd-oRudAMs=&xsec_source=pc_feed	1	2025-12-26 21:24:33.527	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/3d06af93392edc2883d02cf44da885a9/1040g2sg31qf90fkcg07048mjuspfrdah9c4n8vo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/11441e783c025d82222993b7cf7369bb/1040g2sg31qf90fkcg08048mjuspfrdah3mv5tvg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/d6531b241ba79024e70d9b7db0c6b009/1040g2sg31qf90fkcg07g48mjuspfrdah1daom6g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/d816db7f6cc25a4f0c348f2cee75851f/1040g2sg31qf90fkcg09g48mjuspfrdahaicjg28!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/3a98689793d7e1c9cb7007813fc0ff06/1040g2sg31qf90fkcg0a048mjuspfrdah1hb6jvg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/effd18c8e57925ee746d89f1e59c531a/1040g2sg31qf90fkcg08g48mjuspfrdahrkokhs0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/6885d82112d4d84e1366e82c20716e23/1040g2sg31qf90fkcg0ag48mjuspfrdahh40ofr0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/48e195ad8d215bdafb838fe935bc9473/1040g2sg31qf90fkcg09048mjuspfrdahukdsabg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/9200c63558b421d0a0f222ca0ca0f3ac/1040g2sg31qf90fkcg0b048mjuspfrdahgnnvprg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/42e198da1508072e9804f969fa0d71e6/1040g2sg31qf90fkcg0bg48mjuspfrdahutvv1hg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/63ef147e4fe4281bd5f34511cf2a1f25/1040g2sg31qf90fkcg0c048mjuspfrdah1ngbst0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/610242d54a735a929e879ac3b10b7fe9/1040g2sg31qf90fkcg0d048mjuspfrdahqbhp718!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/26a9b1352b84d59690a1ae4573f15350/1040g2sg31qf90fkcg0cg48mjuspfrdahdalq87o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/111f1a12c795d90566460cf885874e8d/1040g2sg31qf90fkcg0dg48mjuspfrdah7k8dc20!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/c736e208f0507b0b27a61a17543d1476/1040g00831qf90mca0a0048mjuspfrdah4b8abag!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/7584235007b11d23ca3e4a7fc8e10744/1040g00831qf90mca0a0g48mjuspfrdah0s3ou18!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/efcbd7d6d745e8a7bb0eabb63f649e06/1040g00831qf90mca0a1048mjuspfrdah2ipfptg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/c4004e68c896370e6c4bdd9c43bdf415/1040g00831qf90mca0a1g48mjuspfrdahk9ssn0g!nd_dft_wlteh_jpg_3"]	[]	0	9	0	\N	[]	0	0	f
999a17ac-058e-4fb3-a806-7ea77eedad55	xiaohongshu	694e8158000000001e00a3e0	三亚大东海🌴	aqrirene		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/三亚大东海🌴_694e8158000000001e00a3e0	http://sns-webpic-qc.xhscdn.com/202512262124/fceb16e6c1e18c9f56380ced3e532530/notes_pre_post/1040g3k031qibgmge74l049uj5nju2lf5b34pb20!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e8158000000001e00a3e0?xsec_token=AB7MH_8h2mYcgfxpQlXwonGnxlMO2yh3Nc9wnrwkVntHc=&xsec_source=pc_feed	1	2025-12-26 21:24:49.505	\N	["http://sns-webpic-qc.xhscdn.com/202512262124/fceb16e6c1e18c9f56380ced3e532530/notes_pre_post/1040g3k031qibgmge74l049uj5nju2lf5b34pb20!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/477c143115709815a0e35582aa036ffb/notes_pre_post/1040g3k031qibgmge74lg49uj5nju2lf5amj5a10!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/49ff6ecac54e1a2acde6cdf37c8a4f4a/notes_pre_post/1040g3k031qibgmge74m049uj5nju2lf5tgaksa0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/5e766cf86c65e6b4ba8569df23b7a579/notes_pre_post/1040g3k031qibgmge74mg49uj5nju2lf52cqllc8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/57b385a0a4591a2858c7013f7805b206/notes_pre_post/1040g3k031qibgmge74n049uj5nju2lf5mdrthjg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/bbdc2e73af575c88eff6d93a6befd98e/notes_pre_post/1040g3k031qibgmge74ng49uj5nju2lf5uurobhg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262124/4caf8093658e90ee0ec5f2b22e271a1f/notes_pre_post/1040g3k031qibgmge74o049uj5nju2lf520qiqf8!nd_dft_wlteh_jpg_3"]	[]	0	1	2	\N	[]	0	0	f
c00b7216-286d-45c3-9d6f-b93215260df4	xiaohongshu	694eaf580000000022022350	未知标题	汉堡王子é	#古路村爬山[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/未知标题_694eaf580000000022022350	http://sns-webpic-qc.xhscdn.com/202512271759/0116313a68b2ccfc6c09c7d1016b8734/1040g00831qih3ubr7g005os9u81nqsnrhsog1m8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694eaf580000000022022350?xsec_token=AB7MH_8h2mYcgfxpQlXwonGj8cdp7xw5MzMXUdUT-WZ3A=&xsec_source=pc_feed	1	2025-12-27 17:59:54.912	\N	["http://sns-webpic-qc.xhscdn.com/202512271759/0116313a68b2ccfc6c09c7d1016b8734/1040g00831qih3ubr7g005os9u81nqsnrhsog1m8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271759/8f47a4b2bb07f3aee9e3927f8d4fa5f1/1040g00831qih3ubr7g0g5os9u81nqsnr4tfi5ao!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271759/394acecc01c164de4467a98a154c846c/1040g00831qih3ubr7g105os9u81nqsnruf8da3o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271759/fe6b570731ab1152bb1c30da891ae076/1040g00831qih3ubr7g1g5os9u81nqsnrvlte34o!nd_dft_wlteh_jpg_3"]	[]	0	0	6	\N	[]	0	0	f
fdc342d5-e6cc-4c39-aca7-d383b4c1924c	xiaohongshu	6944113b000000001e0338d3	Google AI工具一览:这是普通人易吃到的红利	商业分析家Suri	截止到2025年12月，Google的 AI产品矩阵已经非常庞大，涵盖了从底层模型、开发者工具到消费者应用的各个方面。\n\t\n初学者会看到各种各样的词汇，比如Gemini、AI Studio、NotebookLM、NanoBanana Pro、Flow、Veo 3、Google Labs、Mixboard、Workspace、Antigravity、CLI等，往往被搞得云里雾里，不知道哪些工具适合自己。\n\t\n为了更好地了解它们，我们把Google的AI家族比作一个影视制作公司：\n\t\nGemini是大管家，什么事都能找他协调。\nNanoBanana Pro是美术设计，负责画海报、P图。\nGoogle Flow 是剪辑导演，指挥怎么运镜，并把片子剪好。\nMixboard是创意总监，负责在白板上贴贴画画找感觉。\nNotebookLM是资料研究员，负责读剧本、查历史资料，确保不穿帮。\nGoogle Antigravity是搭建片场的工程师，负责用代码构建基础设施。\nGemini CLI是片场的电工，在后台敲敲打打维持系统运行。\nGoogle AI Studio是试镜间，用来测试新演员（模型）行不行。\nGoogle Labs是概念设计部，专门搞一些疯狂的、还没决定要不要拍的想法。\nGemini for Workspace是行政部门，负责发邮件、写通告、做表格。\n#商业分析[话题]# #AI人工智能[话题]# #google[话题]# #gemini[话题]# #nanobanana[话题]# #veo[话题]# #notebooklm[话题]# #ai工具[话题]# #ai产品[话题]# #数据分析[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/Google_AI工具一览_这是普通人易吃到的红利_6944113b000000001e0338d3	http://sns-webpic-qc.xhscdn.com/202512272045/32640c017284ddbfb605247e128b86ca/spectrum/1040g34o31q84m64h701g5o6934i08108fco0hqg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/6944113b000000001e0338d3?xsec_token=AB2jspeFadEuEOUanWHF6qpNGXbxWoDNql0oamflh7F3Q=&xsec_source=pc_feed	1	2025-12-27 20:45:04.126	\N	["http://sns-webpic-qc.xhscdn.com/202512272045/32640c017284ddbfb605247e128b86ca/spectrum/1040g34o31q84m64h701g5o6934i08108fco0hqg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272045/21a2239118d4f00b092c91e933dfab76/spectrum/1040g34o31q84m64h70205o6934i081081bn15h8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272045/93c783ae03efd974b5227bcbc9a38e3f/spectrum/1040g34o31q84m64h702g5o6934i08108arkgdso!nd_dft_wlteh_jpg_3"]	[]	0	7	0	\N	[]	0	0	f
8c3da8ef-14f9-4ed2-addd-84d75788b231	xiaohongshu	6947b15b000000001e00026c	好温柔的姐姐吧	小葡挞挞🍇	#虞书欣[话题]# #双轨姜暮[话题]# #灿如繁星林晚星[话题]# #云初令[话题]# #中餐厅[话题]# #小红书热门[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/好温柔的姐姐吧_6947b15b000000001e00026c	http://sns-webpic-qc.xhscdn.com/202512272350/5a640d48839e4ea5d281cc50a4ae4a8f/1040g00831qbmji3ln2005q8j5o3dtcee1qqebh0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/6947b15b000000001e00026c?xsec_token=ABnSe2gs9TQq8zZXCCO0X57wAbsDvR1EzJRSg2zfocXuA=&xsec_source=pc_feed	1	2025-12-27 23:50:26.365	\N	["http://sns-webpic-qc.xhscdn.com/202512272350/5a640d48839e4ea5d281cc50a4ae4a8f/1040g00831qbmji3ln2005q8j5o3dtcee1qqebh0!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/110/258/01e947b15b1ab6bb010370019b400de544_258.mp4"]	0	0	0	\N	[]	0	0	f
8f4098d8-08a8-4de1-8e99-8ce8a296ae65	bilibili	BV1YPYXzTE9w	Claude Code 用了 30 天，我再也回不去从零手写代码了 | 编程正式从「胶卷时代」正式迈入「数码时代」| Vibe Coding	海拉鲁编程客	视频简介：\nClaude Code火了，但大部分人却在吐槽它的"黑框界面"。作为一个用Claude Code写了7万行代码的程序员，我想分享一些不一样的观点。\n本期视频，我会带你深入了解：\n\n- 为什么2025年最强的AI编程工具偏偏选择了"土掉渣"的终端界面\n- 我总结的"谋定动"三字诀，如何让AI编程效率真正翻倍\n- 那些隐藏的提示词技巧（比如"think harder"的魔法咒语）\n- Claude Code每天烧掉100-200美元Token的真实体验\n- 从"代码搬运工"到"AI驾驶员"的身份转变\n- AI编程的真实边界：大模型、工程、人的三要素框架\n\n如果你正在观望Claude Code，或者想提升AI编程效率，这个视频会给你最真实的参考。从编程的"胶卷时代"到"数码时代"，让我们一起探讨这场正在发生的革命。\n\n时间戳：\n\n00:00 开场：Claude Code的争议与真相\n00:20 我的实战成果 - 三个项目，7万行代码\n00:59 第一部分：编辑器进化史\n01:46 2015-2018：从手敲代码到智能补全\n02:19 2022-2023：ChatGPT时代的"代码搬运工"\n02:40 2024-2025：AI编程工具的神仙打架\n03:29 为什么Claude Code选择了黑框？- 深度解析\n04:05 终端的三大优势 - 自由度、认知负担、工具融合\n04:33 界面vs效率的真相 - Token额度的秘密\n04:58 第二部分：Claude Code实战技巧\n05:08 "谋定动"三字诀详解 - 自动驾驶式编程\n05:32 谋：需求聊透的艺术 - 对话式需求文档\n06:16 定：任务拆解的智慧 - 渐进式TODO\n06:55 动：狂飙模式的把控 - ESC与clear技巧\n07:46 实用小技巧合集 - init、commit、自定义命令\n09:06 第三部分：提示词技巧揭秘\n09:32 简单就是最好 - 不需要复杂框架\n09:50 "你给我好好想想"的科学原理\n10:09 魔法咒语：think harder与ultrathink\n10:15 链式思考：避免超时的秘诀\n10:33 正面表达vs负面限制 - 引导AI的艺术\n11:01 生产级代码标准 - 避免AI投机取巧\n11:23 长文本优化技巧 - 内容在前，指令在后\n11:47 第四部分：AI编程的边界\n11:54 大模型：天花板的决定因素\n12:32 工程：让能力落地的壳\n13:14 人：定义者、把关者、创新者\n13:37 AI编程现状：超级助手，而非替代品\n13:37 第五部分：从胶卷到数码的感悟\n13:39 Claude Code宕机那天的震撼\n14:07 编程习惯的根本改变\n14:16 胶卷时代vs数码时代的完美类比\n14:45 程序员角色的深刻转变\n15:10 结语：时代变了，我们不必回去\n\n👉 如果这个视频对你有帮助，记得点赞支持！\n💬 你对AI编程工具有什么看法？欢迎在评论区分享你的经历\n🔔 订阅频道，获取更多AI相关的内容	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/Claude_Code_用了_30_天，我再也回不去从零手写代码了___编程正式从「胶卷时代」正式迈入「数码时代」__Vibe_Coding_BV1YPYXzTE9w	http://i2.hdslb.com/bfs/archive/5b0f63f68f4f1e0dea3f4881ed3c7047e53c8d79.jpg	https://www.bilibili.com/video/BV1YPYXzTE9w/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 18:43:42.412	\N	[]	["https://upos-sz-estgoss.bilivideo.com/upgcxcode/48/57/31844925748/31844925748-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&uipk=5&mid=0&deadline=1766839418&gen=playurlv3&os=estgoss&og=hw&platform=pc&oi=3707349438&trid=88c3745a66e64a50924233e2a32e42au&nbs=1&upsig=4087d3661c36b4ff1161a452c7a29c3d&uparams=e,uipk,mid,deadline,gen,os,og,platform,oi,trid,nbs&bvc=vod&nettype=0&bw=343495&dl=0&f=u_0_0&qn_dyeid=03f02f61e47194d000f4b3fd694fb85a&agrr=1&buvid=&build=0&orderid=0,3"]	1443	274	317	2025-08-21 16:10:31	[]	2532	68012	f
e5ae618f-727c-4c05-afda-7e1654ee74ff	bilibili	BV1G1qVBSExe	Claude CodeCodeX+Skills入门教程（1）	通往AGI之路	💻编程党省力气神器来啦！Claude Code/CodeX+Skills入门教程直接把“环境配置难”“工具不会用”的门槛踹飞——WaytoAGI编程区版主Ben+Vibecoding爱好者木里组队，手把手教你装工具、用AI辅助写代码，新手也能无痛上车！\n\n视频里全是“入门级”干货：\n1. 🛠️保姆级安装配置：从Claude Code/CodeX的下载到Skills插件的适配，每一步都标清操作细节，避开“环境冲突”“插件装不上”的坑，现场演示5分钟搞定基础配置；\n2. 🚀新手友好实操：写简单脚本、让AI帮查bug、用Skills插件提速编码，不用啃复杂文档，跟着操作就能让AI当你的编程小助手；\n3. ❌避坑急救包：安装失败、工具闪退、指令没用对的常见问题，嘉宾直接给“一键解决”方案，省得你查半天教程；\n\n评论区聊聊你用AI编程时最头疼的是啥？	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/Claude_CodeCodeX+Skills入门教程（1）_BV1G1qVBSExe	http://i1.hdslb.com/bfs/archive/77b1c0ed59f4b10b45527779e49c29fa12664c00.jpg	https://www.bilibili.com/video/BV1G1qVBSExe/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 18:48:20.379	\N	[]	["https://upos-sz-mirrorbd.bilivideo.com/upgcxcode/51/76/34800797651/34800797651-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&nbs=1&trid=5fe5e29c1ab44b97ac88b6405e8d2aeu&og=hw&deadline=1766839698&uipk=5&oi=3707349438&platform=pc&mid=0&gen=playurlv3&os=bdbv&upsig=09e57e3d42c6ce4b09ba9a0141e7b689&uparams=e,nbs,trid,og,deadline,uipk,oi,platform,mid,gen,os&bvc=vod&nettype=0&bw=252402&agrr=1&buvid=&build=0&dl=0&f=u_0_0&qn_dyeid=1c5dd9df12e2ef16002f9bf0694fb972&orderid=0,3"]	31	1	10	2025-12-17 20:44:12	[]	116	1099	f
f184278c-e5ee-496b-a033-b4fe9525bc1a	bilibili	BV1ueyjBgEZx	三周深度实测：Claude Skills 真的强到离谱，它不是 Prompt 收藏夹！ | 回到 Axton	回到Axton	Claude Skills 发布三周后，我确信它是当前最值得关注的 Agent 技术。\n\n 很多人误以为 Skills 只是"保存 Prompt 的地方"，但它真正的能力是：把你的判断逻辑和处理流程封装成可复用的模块，将 4-5\n 小时的人工工作压缩到 5 分钟。\n\n 本期视频用两个真实案例带你理解：\n ✅ 能力包型 Skills：封装复杂判断逻辑（笔记整理案例）\n ✅ 软编排型 Skills：协调多个 sub-agents 协作（字幕处理案例）\n\n 无需写代码，看完即可上手。视频最后提供完整的 5 步操作指南。\n\n 🎯 适合人群：\n • Claude 付费用户（想深度使用 Skills 功能）\n • 需要处理重复性知识工作的人（整理笔记、处理文档等）\n • 对 AI 自动化、Agent 技术感兴趣的探索者\n\n ⏱️ 章节目录：\n 0:00 开场：为什么 Skills 能改变 Agent 格局\n 1:35 什么是 Claude Skills？\n 3:39 Prompt vs Skill 的本质区别\n 5:55 案例1：能力包型 Skills（笔记整理自动化）\n 12:05 案例2：软编排型 Skills（字幕转文章工作流）\n 16:17 使用限制与注意事项\n 19:35 快速上手：5步创建你的第一个 Skill\n\n以下是2 个 Skills 资源网站，供大家参考。 但是注意，由于 Skill 需要代码执行权限，因此对于第三方的 Skills 大家要谨慎使用：\n\nhttps://github.com/anthropics/skills\n这是 Anthropic 的官方 Skills，既可以用来学习，还可以用来把他们放到 Claude Code 里用。\nhttps://github.com/BehiSecc/awesome-claude-skills\nAwesome 系列，这是 Skills\n\n---\n\n『我的核心课程与社群』\n\n🔥「MAPS™ AI 系统化训练营」| 从“工具使用者”到“系统构建者”\n从零开始，手把手带你掌握可迁移的系统化思维，独立设计、部署并迭代多场景的AI自动化工作流，用AI重塑你的核心竞争力。\n👉 https://www.axtonliu.ai/aiagent\n\n⚡「AI 精英圈」社群 | 你的AI私人智囊团\n加入社群，解锁精英周刊、社区深度互动、专属工具资源与每月直播答疑等多项会员特权。\n👉 https://www.axtonliu.ai/ai-elite\n\n▶︎ 其他实战课程\n-「AI 实战派」Prompt Engineering 提示工程课: https://axtonliu.ai/ai \n-「AI 自动化」ChatGPT + Make 高效工作流: https://axtonliu.ai/autoai \n\n\n ---\n\n✨『我使用的生产力工具』\n（免责声明：以下部分链接为推荐链接，您通过此链接购买，我可能会获得少量佣金，但不会影响您的购买价格。）\n\n• Make: 我首选的无代码自动化平台 → https://www.make.com/en/register?pc=axton\n• TubeBuddy: YouTube频道主必备的增长与管理工具 → https://www.tubebuddy.com/axton\n• Envato Elements: 高性价比的无限图片视频素材库 → https://1.envato.market/axton\n\n---\n\n#ClaudeSkills #AI自动化 #AIAgent #MAPS #AxtonLiu\n\n🤝【联系与关注】\n\n官网首页：https://axtonliu.ai\nTwitter: https://twitter.com/AxtonLiu\n我的博客&Newsletter: https://www.axtonliu.ai/newsletters/ai-2\n\n免责声明：\n视频仅供娱乐和教育之用。所有信息都是基于互联网的公开资料，请进行独立研究并做出明智决策。	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/三周深度实测：Claude_Skills_真的强到离谱，它不是_Prompt_收藏夹！___回到_Axton_BV1ueyjBgEZx	http://i2.hdslb.com/bfs/archive/110552c69ac1f50127bd50a259b17ec09b896b81.jpg	https://www.bilibili.com/video/BV1ueyjBgEZx/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 18:56:41.578	\N	[]	["https://upos-sz-estgcos.bilivideo.com/upgcxcode/68/52/34102185268/34102185268-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&nbs=1&trid=097f6f8d301544ca86a14e7d2ffa074u&uipk=5&mid=0&os=estgcos&oi=3707349438&platform=pc&deadline=1766840200&gen=playurlv3&og=cos&upsig=8f1da1550e09e70e649d280f14bfa051&uparams=e,nbs,trid,uipk,mid,os,oi,platform,deadline,gen,og&bvc=vod&nettype=0&bw=351859&qn_dyeid=9f147c97b71ef7c1000c214d694fbb68&agrr=1&buvid=&build=0&dl=0&f=u_0_0&orderid=0,3"]	903	140	339	2025-11-19 21:00:00	[]	2217	35794	f
dd72a941-95a8-4249-806c-40d7d14f8e96	xiaohongshu	694f4df1000000001e02e48a	咖啡day~☕️	杨_	#04[话题]# #今天不一样[话题]# #短发[话题]# #一起喝杯咖啡吧[话题]# #喝杯咖啡再说[话题]# #喝一杯咖啡[话题]# #喝咖啡拍照[话题]# #有空一起喝咖啡[话题]# #coffee[话题]# #喜欢喝咖啡[话题]# 超级开心的最近	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/咖啡day~☕️_694f4df1000000001e02e48a	http://sns-webpic-qc.xhscdn.com/202512271912/f373ada66dde603e121e095ff6429866/1040g00831qj4fchunue05oltnbpmsluqe1svi1g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694f4df1000000001e02e48a?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VKrFMxqZ9hz5pVZL27hAhtU=&xsec_source=pc_feed	1	2025-12-27 19:12:51.626	\N	["http://sns-webpic-qc.xhscdn.com/202512271912/f373ada66dde603e121e095ff6429866/1040g00831qj4fchunue05oltnbpmsluqe1svi1g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271912/90ee159964734405dcae04337fca778e/1040g00831qj4fchunueg5oltnbpmsluqa33c6qg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271912/8fdd9bcbb19a9307bc24755e10e85dbd/1040g00831qj4fchunuf05oltnbpmsluqp17juio!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271912/55bf99e818730bee7974e30c6d6dec05/1040g00831qj4fchunufg5oltnbpmsluq38u1uuo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271912/76e4f35b1a03f7f5e454d84a419f11d8/notes_uhdr/1040g3qo31qj4g90m0a005oltnbpmsluq42ce0gg!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/63d28157cfead81aea1a9406.jpg"]	["http://sns-video-hs.xhscdn.com/stream/1/10/19/01e94f4def1faa55010050039b5dc8a78d_19.mp4"]	0	7	9	\N	[]	0	0	f
b64577bb-bc62-408e-b935-729ceffd7aa7	bilibili	BV1agBWB7EAv	【Claude Code】从安装到使用全流程讲解，手把手教你Claude Code企业级实战案例，存下吧，让你少走99%的弯路！	居然说AI	喜欢UP主发的视频记得一键3连支持一波噢，你的支持，是我最大的动力！	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/【Claude_Code】从安装到使用全流程讲解，手把手教你Claude_Code企业级实战案例，存下吧，让你少走99%的弯路！_BV1agBWB7EAv	http://i1.hdslb.com/bfs/archive/f753d506d6218a945445b7497f62f4815ae87a12.jpg	https://www.bilibili.com/video/BV1agBWB7EAv/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 19:13:55.605	\N	[]	["https://cn-hncs-cu-01-04.bilivideo.com/upgcxcode/09/86/34900148609/34900148609-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&os=bcache&og=hw&deadline=1766841211&nbs=1&oi=3707349438&platform=pc&gen=playurlv3&uipk=5&trid=00004f35e5d3fc03449e80f32d2536ee654u&mid=0&upsig=a88aa7bf27bb226daaa09bf48fa512b3&uparams=e,os,og,deadline,nbs,oi,platform,gen,uipk,trid,mid&cdnid=3293&bvc=vod&nettype=0&bw=189084&lrs=42&buvid=&build=0&dl=0&f=u_0_0&qn_dyeid=c6625e80153ecbe300b02bf0694fbf5b&agrr=0&orderid=0,3"]	154	18	37	2025-12-22 14:47:20	[]	223	4766	f
f1213ea5-8bd0-433a-b0c7-881f1c5b9c6a	xiaohongshu	694fcffa000000001f00ac70	未知标题	小鱼丸	来啦	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/未知标题_694fcffa000000001f00ac70	http://sns-webpic-qc.xhscdn.com/202512272350/133757126442905f89a9541897d73d3b/1040g2sg31qjkbt4700005n95nod5jshcpc96vr0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694fcffa000000001f00ac70?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VEk4efHbZ3lbeDDu_OiFPB8=&xsec_source=pc_feed	1	2025-12-27 23:50:33.066	\N	["http://sns-webpic-qc.xhscdn.com/202512272350/133757126442905f89a9541897d73d3b/1040g2sg31qjkbt4700005n95nod5jshcpc96vr0!nd_dft_wlteh_jpg_3"]	["http://sns-video-hw.xhscdn.com/stream/1/110/258/01e94fcfe81fb69e010370019b5fc492ec_258.mp4"]	0	0	0	\N	[]	0	0	f
58e238c5-c4cd-483d-857b-2b58869a1197	xiaohongshu	694faa0f000000002200894f	未知标题	王亿涵小朋友^_^	圣诞快乐	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/未知标题_694faa0f000000002200894f	http://sns-webpic-qc.xhscdn.com/202512271924/5aa0cb690c97614b348c78330cee216a/1040g00831qjfm4b0ga0g5n2vilrnanca0o505pg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694faa0f000000002200894f?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VNeWQGmpI7af1wJ4xbpvq_M=&xsec_source=pc_feed	1	2025-12-27 19:24:21.988	\N	["http://sns-webpic-qc.xhscdn.com/202512271924/5aa0cb690c97614b348c78330cee216a/1040g00831qjfm4b0ga0g5n2vilrnanca0o505pg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271924/e8750ef76666bb2155788cf0d5d0a9ff/1040g00831qjfm4b0ga005n2vilrnancaiqqeef8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271924/2f95e3a63cfa7b055b25018b3254d356/1040g00831qjfm4b0ga1g5n2vilrnancaputhqag!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271924/9c463fa5166bc49bd13d9dfa3036ba4e/notes_uhdr/1040g3qo31qjfo1qc7g705n2vilrnancald14l80!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271924/df419c028d2ac8fa98ae96b48d277669/notes_uhdr/1040g3qo31qjfo1qc7g7g5n2vilrnancaaaobqhg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271924/e62a0516f67af7226d7367f010b10004/1040g00831qjfm4b0ga205n2vilrnanca2a3gtio!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271924/6aa9d42bda869f6757695eea31d0df35/1040g00831qjfm4b0ga105n2vilrnanca0lcto0g!nd_dft_wlteh_jpg_3"]	["http://sns-video-hs.xhscdn.com/stream/1/10/19/01e94faa091f9021010050039b5f307a26_19.mp4"]	0	0	0	\N	[]	0	0	f
d2922b6e-1e94-4eac-88dc-86a8ee72ec91	xiaohongshu	694fba98000000001f0074d2	irene	杨宛宁ywn	ins:auddk_77#美女姐姐[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/irene_694fba98000000001f0074d2	http://sns-webpic-qc.xhscdn.com/202512271927/f28157d524cbafe663e68c8c5764140b/notes_pre_post/1040g3k031qjhktl2ng005o3l1e4g8ngafo0qd38!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694fba98000000001f0074d2?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VNrvd9-qL9MaPhakW2IPTPQ=&xsec_source=pc_feed	1	2025-12-27 19:27:46.451	\N	["http://sns-webpic-qc.xhscdn.com/202512271927/f28157d524cbafe663e68c8c5764140b/notes_pre_post/1040g3k031qjhktl2ng005o3l1e4g8ngafo0qd38!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271927/10804200cb6936cb4d9706dc818c3bb1/notes_pre_post/1040g3k031qjhktl2ng0g5o3l1e4g8ngai44er78!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271927/fc2208d0035875d61c841f60cc18f4ea/notes_pre_post/1040g3k031qjhktl2ng105o3l1e4g8ngaf114f7g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271927/de8d6f31e897579b21846da6ee91d1cd/notes_pre_post/1040g3k031qjhktl2ng1g5o3l1e4g8nga9p69gno!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271927/5eea1a80504d00b0d1dcb28fdab07ff1/notes_pre_post/1040g3k031qjhktl2ng205o3l1e4g8ngan44e940!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271927/b51912302162d13af83c6b7254a74d57/notes_pre_post/1040g3k031qjhktl2ng2g5o3l1e4g8nga2qcm5fg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271927/1fc1688f81d94859f0bfc74b663897db/notes_pre_post/1040g3k031qjhktl2ng305o3l1e4g8nga65meang!nd_dft_wlteh_jpg_3"]	[]	0	0	1	\N	[]	0	0	f
25b464fb-82d6-43d0-9875-7188fe613e62	xiaohongshu	694cf7170000000022020e4d	APP常见的4种盈模式！	数途科技APP定制开发	APP盈利模式包括广告收入、应用内购买、订阅制度和数据销售。广告通过展示或点击获利；应用内购买提供增值功能；订阅制度为用户提供专属内容；数据销售变现用户数据。选择模式需结合APP类型和用户需求，注重用户体验和隐私保护。#app开发公司[话题]# #软件开发[话题]# #小程序开发[话题]# #app开发[话题]# #APP开发公司[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/APP常见的4种盈模式！_694cf7170000000022020e4d	http://sns-webpic-qc.xhscdn.com/202512271929/6c0d4eae97f41feb4c2a13a868cf55e7/1040g00831qgrbl767u6g5q63sdsmc384m01r88o!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694cf7170000000022020e4d?xsec_token=AB_nPcx_GLvpB2GJZ06YDBNXPQYjmDc2MkDLTEmgbxFPo=&xsec_source=pc_feed	1	2025-12-27 19:29:35.51	\N	["http://sns-webpic-qc.xhscdn.com/202512271929/6c0d4eae97f41feb4c2a13a868cf55e7/1040g00831qgrbl767u6g5q63sdsmc384m01r88o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271929/c8313d5882124f6cdd3ce3894db654c6/1040g00831qgrbl767u605q63sdsmc384l9jvqc0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271929/26f8853ff106fa00d4a581aaf2e974af/1040g00831qgrbl767u5g5q63sdsmc384ttgafsg!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/68f061baccd3360001262490.jpg"]	[]	1	1	0	\N	[]	0	0	f
acf5ff23-82bb-4587-a2a0-8add23a09f3a	xiaohongshu	694f6a4b0000000022020b5a	🇦🇺圣诞摇铃 许愿永远和你在一起	Avery	盼星星盼月亮终于把璇璇盼到我身边了\n非常lukcy的随机定到了圣诞节的sushi sho晚市位\n迟到了40分钟所以上菜有一点快\n前菜都觉得一般般\n海苔手握真的太美味了\n我和璇一致评价是 好丰富的口感\n很愉快的体验\n因为生日还特地给我留了最好的位置\n📍Sushi sho\n💰：加完圣诞surcharge之后330🔪pp\n#墨尔本漂亮饭[话题]##墨尔本[话题]##圣诞[话题]##墨尔本拍照[话题]##生日拍照片[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/🇦🇺圣诞摇铃_许愿永远和你在一起_694f6a4b0000000022020b5a	http://sns-webpic-qc.xhscdn.com/202512271945/b91aa477eb4396aca4b2587ba75c99f1/notes_pre_post/1040g3k031qj7trsa7u005pe001t3bnuhf9gro5g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694f6a4b0000000022020b5a?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VJ68GRgSyA2s8f2QWeWceNE=&xsec_source=pc_feed	1	2025-12-27 19:45:24.38	\N	["http://sns-webpic-qc.xhscdn.com/202512271945/b91aa477eb4396aca4b2587ba75c99f1/notes_pre_post/1040g3k031qj7trsa7u005pe001t3bnuhf9gro5g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/673096d2d2b2d8103473f6710b750cf6/notes_pre_post/1040g3k031qj7trsa7u0g5pe001t3bnuhl2oui40!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/db8b0af0f6af703ca7b72ce5876e9d0e/note_pre_post_uhdr/1040g3r831qj7ttj17g705pe001t3bnuhdju733g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/f42851e1c54b76e8d9feb94fdc16c77a/note_pre_post_uhdr/1040g3r831qj7ttj17g7g5pe001t3bnuhe9s0bag!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/d121c8669a397e49bb0364bd52f42886/note_pre_post_uhdr/1040g3r831qj7ttj17g805pe001t3bnuhg9m7c4o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/50a7b8a93b6118bcad1f49a6137fb5a6/note_pre_post_uhdr/1040g3r831qj7ttj17g8g5pe001t3bnuhidjt1d0!nd_dft_wlteh_jpg_3"]	["http://sns-video-hs.xhscdn.com/stream/1/10/19/01e94f6a051f99c2010050039b5e44da69_19.mp4","http://sns-video-hs.xhscdn.com/stream/1/10/19/01e94f6a091d7b92010050039b5e44e53b_19.mp4","http://sns-video-hs.xhscdn.com/stream/1/10/19/01e94f6a0c1d4172010050039b5e44e2bf_19.mp4"]	0	0	0	\N	[]	0	0	f
d2149f0a-390d-4895-8e45-9c0c107b1baf	xiaohongshu	6947d337000000001e036510	下次见	Curry	#日常[话题]# #旅游是最好的医美[话题]# #ootd每日穿搭[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/下次见_6947d337000000001e036510	http://sns-webpic-qc.xhscdn.com/202512272129/bc206869eb23d75c4d69491bb59d765d/1040g00831qbqo9do00005oi5h32k13rfof9ogj8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/6947d337000000001e036510?xsec_token=ABnSe2gs9TQq8zZXCCO0X576LuuXQYh_CbPKvz2tZ7YXM=&xsec_source=pc_feed	1	2025-12-27 21:29:06.472	\N	["http://sns-webpic-qc.xhscdn.com/202512272129/bc206869eb23d75c4d69491bb59d765d/1040g00831qbqo9do00005oi5h32k13rfof9ogj8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272129/677dbb989c1c9abc14848fa460e40d34/1040g00831qbqo9do000g5oi5h32k13rf2smc2a0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272129/742737c0ddf55ce17f330c2c2b2ca821/1040g00831qbqo9do00105oi5h32k13rfvj6ohmo!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
08acb71d-9e94-4ac6-95c3-16b5834ef2fd	xiaohongshu	69436bcd000000001e03a16f	吴恩达|现在最流行4种Agent设计模式及原理	AI大模型知识官	#大模型[话题]# #LLM[话题]# #AI大模型[话题]# #agent[话题]# #大模型微调[话题]# #大模型学习[话题]# #RAG[话题]# #智能体[话题]# #ai产品经理[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/吴恩达_现在最流行4种Agent设计模式及原理_69436bcd000000001e03a16f	http://sns-webpic-qc.xhscdn.com/202512271945/94b7dffce691044070c19f0d845f1153/spectrum/1040g34o31q7h1ocd74105pes7mm3cv91khrle68!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/69436bcd000000001e03a16f?xsec_token=ABqoPeUjQbrahoSkA2uGwbICrFL9SKrWSod3wExhUkItU=&xsec_source=pc_feed	1	2025-12-27 19:45:57.186	\N	["http://sns-webpic-qc.xhscdn.com/202512271945/94b7dffce691044070c19f0d845f1153/spectrum/1040g34o31q7h1ocd74105pes7mm3cv91khrle68!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/b896e9af631d1d28313fb8250ad35751/spectrum/1040g0k031q7h239gn23g5pes7mm3cv9178vn708!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/84a546a3c6efa3059d1df291b1964a33/spectrum/1040g0k031q7h239gn2305pes7mm3cv91obva79g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/a5fbeea03454da26d06959a1f28773f2/spectrum/1040g0k031q7h239gn22g5pes7mm3cv91sm5ftrg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/c31e85d3f8c6b8d635a71552d685b6da/spectrum/1040g0k031q7h239gn2205pes7mm3cv91vhn9o7o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/f7cf1d4ad1d9db491ff43b208c7d9963/spectrum/1040g0k031q7h239gn21g5pes7mm3cv9170qeif8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/eb5640f56da7da5c30d638a1d619d771/spectrum/1040g0k031q7h239gn2105pes7mm3cv91ljvjfbo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/c9eb3998b84ba2f31f8f1a1ae492b0cf/spectrum/1040g0k031q7h239gn20g5pes7mm3cv91ptv41uo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271945/f5a359209167b17c6d6f7273f170afc2/spectrum/1040g0k031q7h239gn2005pes7mm3cv91f8gnri0!nd_dft_wlteh_jpg_3"]	[]	0	0	5	\N	[]	0	0	f
44ceed34-c97e-472d-b76c-68057c547327	xiaohongshu	694f1e14000000001e0271f6	和城市里的海拍了一组胶片🎞️	抚琴大人	#ootd[话题]# #胶片写真[话题]# #胶片的意义在于定格生命力[话题]# #假装在海边[话题]# #完美身材[话题]# #带着胶片去旅行[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/和城市里的海拍了一组胶片🎞️_694f1e14000000001e0271f6	http://sns-webpic-qc.xhscdn.com/202512271956/b002f2ca7be68e792711a456d41c20dc/1040g00831qiufudiga005oihoe6jebh6jp4gf9g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694f1e14000000001e0271f6?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VFs3QrGiJFMQIe5HuZm27S0=&xsec_source=pc_feed	1	2025-12-27 19:56:27.5	\N	["http://sns-webpic-qc.xhscdn.com/202512271956/b002f2ca7be68e792711a456d41c20dc/1040g00831qiufudiga005oihoe6jebh6jp4gf9g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512271956/892a3320a7c41147c360e9ed44735ee2/1040g00831qiufudiga0g5oihoe6jebh6rmho7u0!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
d5649369-da0b-4c53-87d3-819ddb1a3500	bilibili	BV1h2CTBjEdQ	30分钟用TRAE SOLO做了个iOS App，从Web到原生	AI进化论-花生	我用 TRAE SOLO 把 Web 版的图像处理功能重构成了 iOS 原生 App。整个过程体验了 SOLO Coder 的核心功能:Plan模式先规划再执行、多任务并行同时开发多个模块、Sub Agent 智能协作自动调用专业智能体、Diff View集中查看所有代码变更。开发过程中遇到编译错误,用 Plan 模式分析并快速修复。\n最终 1:1 复刻了 Web 版功能。TRAE SOLO 特别适合专业开发者处理复杂项目:需求迭代、代码重构、Bug修复、技术迁移等场景。现在还在限时免费,可以试试。\n\n⏱️ 时间戳\n00:00:00 - 项目背景与需求\n00:00:25 - TRAE SOLO & SOLO Coder 介绍\n00:02:23 - Plan 模式制定开发计划 ⭐\n00:03:22 - To-Do List 实时进度追踪\n00:04:54 - 多任务并行开发 ⭐\n00:06:10 - Sub Agent 智能协作\n00:07:03 - Diff View 查看代码变更\n00:08:25 - 开发成果及小结	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/30分钟用TRAE_SOLO做了个iOS_App，从Web到原生_BV1h2CTBjEdQ	http://i0.hdslb.com/bfs/archive/14830dfcb8121aca05fc79d4735de724e54a8785.jpg	https://www.bilibili.com/video/BV1h2CTBjEdQ/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 22:14:35.196	\N	[]	["https://upos-sz-estgcos.bilivideo.com/upgcxcode/13/26/33996672613/33996672613-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&oi=3707349438&platform=pc&os=estgcos&nbs=1&uipk=5&gen=playurlv3&og=cos&trid=28a04d37f6e440d798d69c15069d192u&mid=0&deadline=1766852073&upsig=004bc3e403f1e5c242a404bf09167443&uparams=e,oi,platform,os,nbs,uipk,gen,og,trid,mid,deadline&bvc=vod&nettype=0&bw=604177&build=0&dl=0&f=u_0_0&qn_dyeid=dd0a375c19d88b0a00c27032694fe9c9&agrr=0&buvid=&orderid=0,3"]	1617	47	89	2025-11-14 16:01:47	[]	2053	41321	f
8a701e68-0278-41f9-90cd-fe9432aee03c	bilibili	BV1hQm1BwEb8	Minimax m2使用一个月，用了30亿Token，11万行代码，和Kimi K2对比如何？可以评一评了	小天fotos	Minimax的Coding Plan订阅刚好满一个月，同时也订阅了Kimi k2。\n\n用这两个模型尝试不读一行代码的黑盒式开发。\n\n用了一个月，产出11万行代码，也跑通了流程。\n\n这期先聊一下这两个模型的能力对比。\n\n下期详细分享这个项目的黑盒式开发的经验。	video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/Minimax_m2使用一个月，用了30亿Token，11万行代码，和Kimi_K2对比如何？可以评一评了_BV1hQm1BwEb8	http://i1.hdslb.com/bfs/archive/5f8f24265fed3992d2c6aaa0323df0f16e3cb9f2.jpg	https://www.bilibili.com/video/BV1hQm1BwEb8/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 22:58:29.958	\N	[]	["https://upos-sz-mirror08h.bilivideo.com/upgcxcode/26/90/34750989026/34750989026-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&nbs=1&gen=playurlv3&os=08hbv&trid=b0efeeeff2994909b209c4458e23688u&mid=0&oi=3707349438&deadline=1766854690&og=hw&uipk=5&platform=pc&upsig=2bd78ab84dafd0c670c9c67841f1cfa3&uparams=e,nbs,gen,os,trid,mid,oi,deadline,og,uipk,platform&bvc=vod&nettype=0&bw=182608&qn_dyeid=91736d114b7973e30065a426694ff402&agrr=0&buvid=&build=0&dl=0&f=u_0_0&orderid=0,3"]	311	207	34	2025-12-15 19:00:00	[]	306	16921	f
497a26a3-c17e-4023-b01f-3975070d2e34	bilibili	BV162qWBfEut	【酥酥学姐一百部】(6/100)温柔舔耳口腔音，入睡必听系列专治免疫~	asmr听爽了		video	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/bilibili/【酥酥学姐一百部】(6_100)温柔舔耳口腔音，入睡必听系列专治免疫~_BV162qWBfEut	http://i2.hdslb.com/bfs/archive/a58ec3adfccd2bc9f532917cc48b15e173c9dcb6.jpg	https://www.bilibili.com/video/BV162qWBfEut/?spm_id_from=333.1387.favlist.content.click&vd_source=0444c7e4e9701a2bebef78ff53c23a20	1	2025-12-27 23:04:16.22	\N	[]	["https://upos-sz-estgcos.bilivideo.com/upgcxcode/16/50/34760755016/34760755016-1-192.mp4?e=ig8euxZM2rNcNbRVhwdVhwdlhWdVhwdVhoNvNC8BqJIzNbfqXBvEqxTEto8BTrNvN0GvT90W5JZMkX_YN0MvXg8gNEV4NC8xNEV4N03eN0B5tZlqNxTEto8BTrNvNeZVuJ10Kj_g2UB02J0mN0B5tZlqNCNEto8BTrNvNC7MTX502C8f2jmMQJ6mqF2fka1mqx6gqj0eN0B599M=&deadline=1766855055&oi=3707349438&mid=0&os=estgcos&trid=f6a1370ff8104b58bf71f442b251194u&gen=playurlv3&og=hw&nbs=1&uipk=5&platform=pc&upsig=a6c6d19e91f417075efadbe80e554f49&uparams=e,deadline,oi,mid,os,trid,gen,og,nbs,uipk,platform&bvc=vod&nettype=0&bw=528150&dl=0&f=u_0_0&qn_dyeid=80297848b9f30214001757ff694ff56f&agrr=0&buvid=&build=0&orderid=0,3"]	180	5	6	2025-12-15 23:50:49	[]	898	12332	f
d49d98bf-ed5b-4051-9321-4836ce63bcbd	xiaohongshu	694e55bf000000001e0050bf	家里宅	覃美莹doggyqin	#美甲分享[话题]#\n#日常[话题]#\n#拍照[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/家里宅_694e55bf000000001e0050bf	http://sns-webpic-qc.xhscdn.com/202512272314/dea1f73b56666c50f25464baf055e1ed/1040g00831qh17o8v7g4g5ogf07gocpemj10c2v0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e55bf000000001e0050bf?xsec_token=AB7MH_8h2mYcgfxpQlXwonGq5ctPuiUwhqQbdVkKXVwGE=&xsec_source=pc_feed	1	2025-12-27 23:14:30.014	\N	["http://sns-webpic-qc.xhscdn.com/202512272314/dea1f73b56666c50f25464baf055e1ed/1040g00831qh17o8v7g4g5ogf07gocpemj10c2v0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/6bbeb047c8cffffcdef7ac133a7d1b34/1040g00831qh17o8v7g505ogf07gocpemhv9475o!nd_dft_wgth_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/4551f70ee636010b2fcb954e45992ba7/1040g00831qh17o8v7g605ogf07gocpem025gdhg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/5ad02c5aeb700167cb66f20e7b1ef92d/1040g00831qh17o8v7g5g5ogf07gocpemh870duo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/d97fcb078c79907a7116814f18c61051/1040g2sg31qi6ck1hmu705p6ch7n2oq9b4amq6co!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/658941f1ea2dd4427df98377.jpg"]	[]	0	0	0	\N	[]	0	0	f
24256734-34b1-48c9-bd36-242688c1bd74	xiaohongshu	694e9937000000001d03f819	王玉雯高清写真，	欢乐马	王玉雯，1997年出生，毕业于北京舞蹈学院，中国内地女演员。\n\t\n2015年，主演青春言情微电影《数字恋爱》从而正式进入演艺圈。2016年，主演青春校园超能力网络剧《超星星学园》；同年，参演青春偶像剧《夏至未至》。2017年，参演三国题材古装剧《三国机密》。2018年3月27日，参演的三国题材古装剧《三国机密之潜龙在渊》在腾讯视频上线，在剧中饰演曹操之女曹节。2019年，与吴希泽搭档主演古代青春校园喜剧《长安少年行》。2019年6月9日，参演的电视剧《少年派》在湖南卫视播出，在剧中饰演邓小琪​。	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/王玉雯高清写真，_694e9937000000001d03f819	http://sns-webpic-qc.xhscdn.com/202512272314/a612c4f6eb96c967e3e9c7f7622db835/notes_pre_post/1040g3k031qiedqrpn46g5oi798e41pfc78t4tj8!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e9937000000001d03f819?xsec_token=AB7MH_8h2mYcgfxpQlXwonGk02Qx5_riwfef_eHv4Wj9M=&xsec_source=pc_feed	1	2025-12-27 23:14:57.161	\N	["http://sns-webpic-qc.xhscdn.com/202512272314/a612c4f6eb96c967e3e9c7f7622db835/notes_pre_post/1040g3k031qiedqrpn46g5oi798e41pfc78t4tj8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/e9d4338645a9d7ca91a8de62b14b2419/notes_pre_post/1040g3k031qiedqt0n2605oi798e41pfcou9rqt0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/644e01f7fc23c6a41760281518ef8e29/notes_pre_post/1040g3k831qiedro6n0cg5oi798e41pfcipo8re0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/0d7e810a0a33d820ef98c5fc8526a4c2/notes_pre_post/1040g3k831qiedro6n0d05oi798e41pfciqhv608!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/682c3798febfb74368a8104088617b64/notes_pre_post/1040g3k031qiedrnhn46g5oi798e41pfcar6tt20!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/e35ef30ae4d6a7330d3f89a66b50491f/notes_pre_post/1040g3k031qiedqt0n2005oi798e41pfcmqovcgo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/1d53d43a91934e64b50a9398f4cf50f8/notes_pre_post/1040g3k031qiedqt0n2505oi798e41pfcd60ot7o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/47d78cfc11cca77aa9dc4a36a32ea6c6/notes_pre_post/1040g3k031qiedqt0n26g5oi798e41pfc2niub3o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/5003ac7faa56cd74e64a701a5528199e/notes_pre_post/1040g3k031qiedqt0n21g5oi798e41pfcs2eofq0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/581352ede355d59fd0fa2cb383579683/notes_pre_post/1040g3k031qiedqt0n2105oi798e41pfcdsfqmno!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/6b834094bf03c2cc6c4d7a90b3549e6f/notes_pre_post/1040g3k031qiedqt0n20g5oi798e41pfcf3s3ouo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/bb77484f89764d59c617aecb10bddd56/notes_pre_post/1040g3k031qiedqt0n22g5oi798e41pfc2n0jcmg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/3cdce8663e566decbc4c38fd5ae8f4c8/notes_pre_post/1040g3k031qiedqt0n2205oi798e41pfc8hj9cgo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/a73ffe97679426adc0b0407f769f716f/notes_pre_post/1040g3k031qiedqt0n2305oi798e41pfcd1m2ib0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/015e5b4fdf48ec646d8cd81707e069f5/notes_pre_post/1040g3k031qiedqt0n23g5oi798e41pfc992nbtg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/7ed8a26d8e0e0657990d0711df7a261a/notes_pre_post/1040g3k031qiedqt0n24g5oi798e41pfcvg2lba0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/28830a6593da452075320b387835f7c4/notes_pre_post/1040g3k031qiedqt0n2405oi798e41pfcbrpij70!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272314/d36b5b20ae00ad43b8c3adaf6e5550d0/notes_pre_post/1040g3k031qiedqt0n25g5oi798e41pfclmj8ino!nd_dft_wlteh_jpg_3","https://sns-avatar-qc.xhscdn.com/avatar/62474a1c000000001000e5ec.jpg"]	[]	0	0	0	\N	[]	0	0	f
1f3be079-e132-4b71-86ae-c705fee8c0ea	xiaohongshu	694eec13000000001f00e079	Melt into the night	Pluto23	融入夜色\n\t\n#氛围感穿搭[话题]# #御姐范[话题]# #姐感穿搭[话题]# #大姐姐穿搭[话题]# #ootd每日穿搭[话题]# #深圳打卡点[话题]# #万象天地[话题]# #秋冬穿搭[话题]# #女神范[话题]##战袍御姐风[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/Melt_into_the_night_694eec13000000001f00e079	http://sns-webpic-qc.xhscdn.com/202512272341/1c5fef957221a605752c497a63b0e72e/notes_pre_post/1040g3k831qio42ebngb05q2m8p37hejia4csq0g!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694eec13000000001f00e079?xsec_token=AB7MH_8h2mYcgfxpQlXwonGuM8LCNdUIHOiaKZglbJSuk=&xsec_source=pc_feed	1	2025-12-27 23:41:40.761	\N	["http://sns-webpic-qc.xhscdn.com/202512272341/1c5fef957221a605752c497a63b0e72e/notes_pre_post/1040g3k831qio42ebngb05q2m8p37hejia4csq0g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272341/8c39f90da99116073bb3f046c6a7b757/notes_pre_post/1040g3k831qio42ebng905q2m8p37hejifredml8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272341/bb9bf0b01dbb4b345afc03d413785c34/notes_pre_post/1040g3k031qiof4l1no505q2m8p37heji08mcb2g!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272341/74427dca3eded0094c090970f2957969/notes_pre_post/1040g3k031qiof4l1no6g5q2m8p37hejin7dpf4o!nd_dft_wlteh_jpg_3"]	[]	0	2	1	\N	[]	0	0	f
371b7ea9-e591-4746-96c1-04201e653097	xiaohongshu	694fdbff000000001e00956c	想念夏日	Nicole 妮蔻		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/想念夏日_694fdbff000000001e00956c	http://sns-webpic-qc.xhscdn.com/202512272350/e93f7080480b05fd215f059217c70fc5/notes_pre_post/1040g3k831qjlo6gp74004a6u60jfdrjf71ed8m0!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694fdbff000000001e00956c?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VFlobr7sqXN8pdX7GcXb3WE=&xsec_source=pc_feed	1	2025-12-27 23:50:15.681	\N	["http://sns-webpic-qc.xhscdn.com/202512272350/e93f7080480b05fd215f059217c70fc5/notes_pre_post/1040g3k831qjlo6gp74004a6u60jfdrjf71ed8m0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272350/47265967a28d6c70f762b662b52a2401/notes_pre_post/1040g3k831qjlo6gp74204a6u60jfdrjfgo8fu78!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272350/b2b06dd6d4d879cfb1393003b6b3b882/notes_pre_post/1040g3k831qjlo6gp741g4a6u60jfdrjfsjd8mn8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272350/ab71d020918ecc27d8d5f781977cfb24/notes_pre_post/1040g3k831qjlo6gp742g4a6u60jfdrjfd8mjt0o!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272350/aecd2976117d259939ae4340cf76d450/notes_pre_post/1040g3k831qjlo6gp74104a6u60jfdrjflunmfao!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512272350/c32c75fc0ca241bd7bc116fd08923b2b/notes_pre_post/1040g3k831qjlo6gp740g4a6u60jfdrjfucdebv0!nd_dft_wgth_jpg_3"]	[]	0	0	1	\N	[]	0	0	f
f4935144-ccee-4551-a222-ed9885dee8b2	xiaohongshu	694fbf22000000001e02587e	舒舒服服的	Miaaa	#拍照[话题]# #我的日常[话题]# #舒适度至上[话题]# #自带松弛感[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/舒舒服服的_694fbf22000000001e02587e	http://sns-webpic-qc.xhscdn.com/202512280020/60153c66a01a22bc85b4eb34705edd0f/1040g00831qjiachonu2g4a3a84qnvev7pn2ek6g!nd_dft_wlteh_webp_3	https://www.xiaohongshu.com/explore/694fbf22000000001e02587e?xsec_token=ABUCqzf1U2EfO0JzrdF8k-VGUnvJu0bg2xczxltpIcWKs=&xsec_source=pc_feed	1	2025-12-28 00:20:32.095	\N	["http://sns-webpic-qc.xhscdn.com/202512280020/60153c66a01a22bc85b4eb34705edd0f/1040g00831qjiachonu2g4a3a84qnvev7pn2ek6g!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512280020/5fb869687c7e743bad00942ae90645db/1040g00831qjiachonu0g4a3a84qnvev7hamg0r0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512280020/8742738b0a017c22ee3df8ddfb1d72eb/1040g00831qjiachonu204a3a84qnvev7bumtc5g!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512280020/28e6591ef802ccb98f6d1c579a4d6ddf/1040g00831qjiachonu1g4a3a84qnvev7a2i5je0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512280020/685c65be1e8d2e9cf9bdc3344565fdcd/1040g00831qjiachonu104a3a84qnvev79tnh8b0!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512280020/f944a602a930a4e1812f5331bfda66ca/1040g00831qjiachonu004a3a84qnvev772l7778!nd_dft_wlteh_webp_3","http://sns-webpic-qc.xhscdn.com/202512280020/ebe7ccb61cbdde7a00a1e73a3ccc3e09/1040g00831qjiachonu304a3a84qnvev71n53umo!nd_dft_wlteh_webp_3","https://sns-avatar-qc.xhscdn.com/avatar/6382d461565747ca2c720b04.jpg"]	[]	0	0	0	\N	[]	0	0	f
\.


--
-- Data for Name: crawl_tasks; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.crawl_tasks (id, name, platform, target_identifier, frequency, status, last_run_at, next_run_at, config, created_at) FROM stdin;
49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87?m_source=pwa	10min	1	2025-12-28 02:00:00.627	2025-12-28 02:10:00.627	{"cookie":null,"useDownloader":true}	2025-12-24 01:09:35.350335
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
b1055593-c10c-474f-95d5-b845c64d3264	教程	#faad14	教程类内容	0	2025-12-27 20:19:57.000317	2025-12-27 20:19:57.000317
deacecf9-a0c5-48b0-b6ca-d529b0fb2aaa	睡眠	#faad14	\N	1	2025-12-28 00:58:50.317456	2025-12-28 00:58:50.317456
a3087408-e5fd-42e8-beb2-b60c007fb547	美女	#eb2f96	\N	49	2025-12-28 01:32:02.674012	2025-12-28 01:32:02.674012
b50027b3-72b4-4642-bbe7-8b908c463bea	AI学习	#9254de	\N	8	2025-12-27 21:11:45.505105	2025-12-27 21:29:46.698
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
6ca12da3-300b-4daf-b0df-ce119a8da187	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:30:00.893	2025-12-27 10:30:04.564	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3673
6e43ef03-060f-4ed2-a933-cb39da0602e2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:40:00.737	2025-12-28 01:40:04.194	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3457
b4fc72c9-c7e0-43db-a6d0-b2602e3668a8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:10:00.512	2025-12-27 15:10:03.776	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3264
a5206fa4-6db3-4e3a-84eb-1e62181940d3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:00:00.927	2025-12-27 18:00:04.732	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3806
409d90cd-74ed-4332-a84d-64ad18ccdbff	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:50:00.51	2025-12-27 20:50:04.674	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4164
d37074c4-6bc4-4fd1-b6f2-b2c744fd9771	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:00:00.608	2025-12-25 16:00:03.811	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3204
30f5c9f9-15ae-41fd-8ec0-a4838321d032	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:10:00.683	2025-12-26 21:10:04.403	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3722
e91c51b7-c66b-484e-8096-98c4d677793d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:50:00.571	2025-12-27 22:50:03.164	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2593
7a31a4b3-ae70-4526-b660-9d9ea9d3abf2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:40:00.914	2025-12-27 01:40:04.164	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3250
0b549efb-3e01-4db9-a0d9-ddbfd629ca67	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:40:00.842	2025-12-27 10:40:03.953	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3112
3b179ec6-4bff-49b6-b463-22c09c11678b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:50:00.453	2025-12-28 01:50:03.67	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3218
1f28807f-10f5-46d3-a0f4-4604698fe11a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:20:00.166	2025-12-27 15:20:03.462	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3297
a6c40ac4-987b-4bcb-b228-f87473835df0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:10:00.64	2025-12-27 18:10:06.06	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5420
cfe611f3-4aa8-4131-ac43-926eca2faad8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:00:00.291	2025-12-27 21:00:04.421	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4131
17183c74-3843-4eaf-89f3-2b70e360f1db	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:10:00.271	2025-12-25 16:10:04.669	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4399
d8d532ea-869f-4be7-b548-b7a7804b0ad7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:20:00.507	2025-12-26 21:20:04.115	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3608
f985fae8-e14f-408b-a739-df010f75b94e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:00:00.651	2025-12-27 23:00:04.399	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3748
1910f4b6-da0f-421a-bd31-b6ad769be729	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:50:00.848	2025-12-27 01:50:04.058	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3211
50a69929-783e-42ac-a8bf-9af78a06ea70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 02:00:00.597	\N	running	author	\N	\N	0	0	0	0
993bd118-4c10-43cc-8ee0-76e7562d87ca	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:20:00.853	2025-12-27 11:20:04.687	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3835
76e07e8d-f02b-4313-97f1-65e7d96f9c1a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:30:00.863	2025-12-27 15:30:04.089	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3227
0347cb5c-038c-42ba-b2af-8288aed4ae76	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:20:00.763	2025-12-27 18:20:04.424	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3662
f525da68-85a2-448d-8402-46c7f0285c7a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:10:00.003	2025-12-27 21:10:03.89	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3887
30cf36e1-01ed-45f8-903e-d9941b4087c6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:20:00.9	2025-12-25 16:20:04.291	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3392
8bb2aa00-fc7b-48c9-b0ca-5e10382246fe	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:30:00.733	2025-12-26 21:30:04.887	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4154
a9936ab7-688e-4be1-9a1c-03511a8adddb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:10:00.39	2025-12-27 23:10:03.879	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3489
0808b608-9963-40fa-b087-377fb07f35cf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:00:00.742	2025-12-27 02:00:04.373	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3632
62dd5f19-4cc7-4c1a-bdb7-3f96cf35d8b9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:30:00.728	2025-12-27 11:30:04.308	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3581
6d266c84-f59b-432f-8f28-5609752d6fe3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:40:00.512	2025-12-27 15:40:04.115	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3604
948c26cc-df42-4488-a53b-b1bde7b46b86	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:30:00.628	2025-12-27 18:30:03.82	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3193
a97a2d70-c4c1-4694-893f-aa44b43ca706	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:20:00.804	2025-12-27 21:20:04.347	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3544
49224e74-60ea-4d09-a66e-364b167955f3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:30:00.607	2025-12-25 16:30:04.348	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3743
8d950e33-b8af-4f6d-a006-114e403eceb6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:40:00.56	2025-12-26 21:40:03.86	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3301
402d9861-55a0-4d18-ac0b-1f08390d79a2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:20:00.154	2025-12-27 23:20:03.509	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3355
ec4b2ac2-ca87-4f18-baf5-3a865d988473	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:10:00.636	2025-12-27 02:10:03.965	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3332
25888a88-fb51-4c2e-882e-75dc3c4da065	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:40:00.556	2025-12-27 11:40:04.168	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3614
2a476388-1968-4637-ada5-3e5ea07175f4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:50:00.471	2025-12-27 15:50:03.614	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3144
0097d881-0f91-4188-909b-acb75c29ca65	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:40:00.582	2025-12-27 18:40:03.272	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2690
7b6d7c7a-8b8a-4ac0-9c22-3095b42e37d6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 21:30:00.972	2025-12-27 21:30:04.42	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3448
fb790805-9e28-4ce7-afc2-5309f9da4567	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:40:00.254	2025-12-25 16:40:04.997	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4744
d7051fe7-6d71-4d00-b08b-3c2bc9ed0f71	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:50:00.733	2025-12-26 21:50:04.236	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3505
aebe79fc-2053-42f5-a46a-eefc385ff91c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:30:00.007	2025-12-27 23:30:03.611	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3604
d24e6c3c-07d4-4859-adb4-8e555a651931	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:20:00.546	2025-12-27 02:20:03.926	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3380
b1a48dd8-12a1-431f-b963-d521973b5681	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 11:50:00.432	2025-12-27 11:50:27.605	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	27175
3a2d7a85-4feb-45ed-b7e5-2827b75ce6ac	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:00:00.52	2025-12-27 16:00:03.691	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3172
ec9be0b8-88f4-44cb-a749-4908d723959b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 18:50:00.808	2025-12-27 18:50:06.158	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5350
a642c1b0-60f5-4cde-8ccd-098155c7eb9c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:00:00.342	2025-12-27 22:00:05.207	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4865
eb26eead-5fa1-4ab7-9687-656cdcd3ee39	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:50:00.825	2025-12-25 16:50:05.301	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4476
8fbfa14a-504e-45eb-88eb-023c269ff037	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:00:00.971	2025-12-26 22:00:03.867	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2897
a2750183-faca-486e-a551-977e2df72783	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:40:00.79	2025-12-27 23:40:04.397	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3607
786d8c73-b74b-49cb-b294-e3be89e59c27	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 04:40:00.571	2025-12-27 04:40:04.154	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3585
3b1b00e6-4888-4da6-bdd5-8fcde5a78a82	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 12:00:00.32	2025-12-27 12:00:03.655	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3336
fdf65ae9-adc9-4b21-8324-7ad3d6273e6a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:10:00.256	2025-12-27 16:10:04.266	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4011
9126e1f3-097f-46c6-b936-45c1c017b302	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:00:00.883	2025-12-27 19:00:04.241	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3359
bc5db996-ae99-4abd-8b64-4b89b846039b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:10:00.302	2025-12-27 22:10:03.674	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3373
b207fdaf-c3be-4717-a94c-d56884b33fc7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:00:00.481	2025-12-25 17:00:05.052	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4572
cc856216-87ad-4627-b5bc-49b39f8b2d00	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:10:00.052	2025-12-26 22:10:03.176	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3125
c867f782-aa74-4702-ba9c-68093702abc4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 23:50:00.733	2025-12-27 23:50:04.398	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3665
0d6735ed-3afb-4a7a-882a-263c46270a8e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 04:50:00.464	2025-12-27 04:50:03.98	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3517
aaba408d-dd7c-4996-87b1-842c78763680	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 12:10:00.177	2025-12-27 12:10:02.554	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2377
81d25fcd-3d8f-4bb8-93ab-4523f697f385	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:20:00.255	2025-12-27 16:20:03.938	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3685
b110ff8c-495f-49db-b49a-a16861e8bf70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:10:00.46	2025-12-27 19:10:03.867	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3409
241172bd-e204-4211-97d3-5e7e1ef77d15	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:20:00.775	2025-12-27 22:20:05.397	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4622
de763b1f-0319-4900-85e9-8ea3e88c0117	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:10:00.084	2025-12-25 17:10:05.094	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5012
021645c3-3411-457b-9974-921d16723a92	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:20:00.831	2025-12-26 22:20:04.2	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3369
6bd02609-cc8d-4f11-b562-ddd4b52c7ce5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:10:00.594	2025-12-28 00:10:05.241	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4648
350d87b6-c1cf-4ba5-987f-530591e8de01	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:00:00.352	2025-12-27 05:00:03.613	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3264
3b79aa09-ca1d-4355-9ae7-564578e65c4e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 13:30:00.669	2025-12-27 13:30:04.155	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3488
e4b0b9a6-7f07-458f-a190-59581211805a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:30:00.267	2025-12-27 16:30:02.567	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2302
5671b3ba-d755-4d21-a4fa-c5cc754ff55e	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:20:00.208	2025-12-27 19:20:03.578	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3370
18ed64b1-7f6c-4fd0-ade7-ef2f0fb2c8d3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 22:30:00.617	2025-12-27 22:30:04.512	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3895
e2cc2f4c-c04e-457d-acca-564973c1dc05	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:20:00.676	2025-12-25 17:20:05.024	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4348
fab0141a-071a-44bb-b93b-b0a21bd5a8dc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:30:00.387	2025-12-26 22:30:04.157	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3772
cc5fbc91-0586-49d1-b67f-687533c8d300	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:20:00.42	2025-12-28 00:20:04.105	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3686
d2cf257c-dccb-43f6-beeb-81ca0e70b4c8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:10:00.241	2025-12-27 05:10:04.129	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3889
1dd11280-a324-4da7-a421-fabb687f35fb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 13:40:00.602	2025-12-27 13:40:03.835	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3235
7d40b727-91d1-4dc4-b09f-9855856ae97c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:40:00.358	2025-12-27 16:40:03.7	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3345
fa207805-8002-4285-a585-729f10d72091	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:30:00.606	\N	running	author	\N	\N	0	0	0	0
465547ad-b4bd-42da-961d-f94d3e0d2dd5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:30:00.347	2025-12-25 17:30:05.172	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4826
d08e526d-4072-47c7-a199-cd2772c0e20a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:00:00.606	2025-12-26 23:00:04.07	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3467
182309a2-f8b1-4b65-b301-58796bde4746	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:30:00.126	2025-12-28 00:30:04.657	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4531
23fbff8d-d12e-4974-a52e-1f7b23a7bb02	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:20:00.132	2025-12-27 05:20:03.597	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3467
1c62ee06-6768-467c-ac3b-981f6ca21967	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 13:50:00.548	2025-12-27 13:50:04.074	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3530
ce19edea-f926-4873-879b-d0f89c165115	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 16:50:00.521	2025-12-27 16:50:04.167	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3648
42b43108-0188-4448-9c12-84adce795233	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:40:00.578	2025-12-27 19:40:03.88	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3302
85036e3d-3e4d-4793-b3ef-f53ff1167ff4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:40:00.944	2025-12-25 17:40:07.801	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6857
37231e4c-460b-496d-8ed1-d0916f8f25e8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:10:00.513	2025-12-26 23:10:04.004	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3495
105604b9-dc31-4538-a99a-a0207c354844	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:40:00.74	2025-12-28 00:40:05.345	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4605
012a6b83-bd9f-44fa-bdbb-799710427ecb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 05:30:00.038	2025-12-27 05:30:03.167	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3131
888da43c-ab25-4726-ba9b-ce4a48730394	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:00:00.461	2025-12-27 14:00:04.124	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3664
69a0c064-39eb-4985-a3b5-28de4a426eee	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:00:00.641	2025-12-27 17:00:04.077	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3438
dce479fd-d0ea-4ae5-93de-4ba314a72e5c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 19:50:00.798	2025-12-27 19:50:03.92	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3122
09d578bd-88bd-434d-90f8-40f31c580d34	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:50:00.657	2025-12-25 17:50:03.792	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3137
f2fd2ea2-54fb-4b43-ae70-c95d7425af04	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:20:00.438	2025-12-26 23:20:04.051	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3616
c12393b7-20b6-43f6-9f5b-fba868176b6c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 00:50:00.676	2025-12-28 00:50:04.992	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4316
bfafa799-bc7c-4bee-ba2d-61a837369f70	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 07:20:00.23	2025-12-27 07:20:04.124	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3896
c3425d83-670d-4964-b529-af9dc62fa250	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:20:00.664	2025-12-27 14:20:03.961	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3298
da6f893a-ad19-4e54-80da-8b7b922906c7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:10:00.771	2025-12-27 17:10:04.131	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3361
e2191058-54cf-4dac-8643-12766b9fe0df	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:00:00.74	2025-12-27 20:00:03.797	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3058
7e8fdb64-7d57-4cae-8745-8ff02592f705	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:00:00.448	2025-12-25 18:00:03.611	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3164
8f9b0ada-5e63-459f-bb2c-e036eda50a84	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:30:00.323	2025-12-26 23:30:03.74	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3420
41c7f32d-32a8-4c32-80d7-d9436c9d26de	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:00:00.534	2025-12-28 01:00:02.702	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2168
7296a567-0a85-48f6-8483-d17deee4d163	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 09:20:00.687	2025-12-27 09:20:05.26	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4574
c737e91b-0500-41f7-bae6-1299f680a251	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:30:00.287	2025-12-27 14:30:03.438	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3152
e454adea-23f2-425b-a1d0-a74bf995cc52	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:20:00.891	2025-12-27 17:20:04.494	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3605
05f95db3-67b4-424b-b10a-8d579db9e28a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:10:00.162	2025-12-27 20:10:03.429	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3267
b0ce66a9-5f3e-4e94-920e-fbb69f447b5c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:10:00.104	2025-12-25 18:10:03.407	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3304
91dc75a6-6dfb-4806-be0c-d304c7a5640b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:40:00.184	2025-12-26 23:40:02.41	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2227
c06b58b2-8546-479b-b983-f65be5143c4f	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:10:00.142	2025-12-28 01:10:03.402	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3260
7562c32e-c6a0-40b1-ad88-fe9f8ee99e3d	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 09:50:00.252	2025-12-27 09:50:04.053	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3802
3f327094-b506-4b90-a5da-513e316534cf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:40:00.951	2025-12-27 14:40:03.2	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2249
8492dc7d-3dff-4fac-b595-2bc5d84e8dbb	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:30:00.984	2025-12-27 17:30:04.279	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3297
b5dcd5df-a1d1-4d60-ac36-fc2e42b75643	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:20:00.823	2025-12-27 20:20:03.337	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2514
4791a5ae-e2a5-4cbd-9aea-bdf83c7805cc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:20:00.798	2025-12-25 18:20:04.238	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3440
d3bcf379-de65-4b1a-a1e0-4cea8a2eb9a8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:50:00.129	2025-12-26 23:50:03.986	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3858
065aa039-9078-47dc-ba1e-246644bd2cd0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:20:00.202	2025-12-28 01:20:03.873	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3671
3078914a-8146-4512-aca8-ce491d59e218	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:00:00.157	2025-12-27 10:00:03.737	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3581
682114a8-815b-4f4e-9850-29c8081d6950	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 14:50:00.615	2025-12-27 14:50:04.093	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3480
b2cf60c0-d1d0-4e6b-91a5-cff797726476	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:40:00.104	2025-12-27 17:40:02.279	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2177
dbf0f303-a4a4-4853-8d7a-c5fe83a35baf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:30:00.979	2025-12-27 20:30:04.388	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3409
46ea4c0d-8fa7-436a-a16e-4776913c317b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:40:00.462	2025-12-25 18:40:03.922	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3461
8ae7786d-c773-482d-a029-ab2569a6e892	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:00:00.457	2025-12-25 19:00:03.775	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3319
00db102e-54ab-410c-9953-b2e64c14cde0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:10:00.694	2025-12-27 01:10:04.238	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3546
2436a598-63be-472f-94ff-886272152184	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:10:00.703	2025-12-25 19:10:04.273	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3570
86f609d4-c3a0-45bc-92e9-e4201e06f75c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-28 01:30:00.217	2025-12-28 01:30:02.846	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2630
e6c77508-ddf6-4eb3-8425-8ecca5e61538	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:20:00.804	2025-12-25 19:20:04.524	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3720
8dca3ac9-3713-4dce-ba13-ae002b417d47	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 10:10:00.094	2025-12-27 10:10:03.33	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3236
37a9f994-6746-47dd-9183-46c909db37a9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:30:00.877	2025-12-25 19:30:05.295	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4419
a40b329c-17f3-4730-9158-2eee0234f2f1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:40:00.659	2025-12-25 19:40:04.179	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3520
6f9238ac-59ed-4dd7-a7e4-5304e6cca1a2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 15:00:00.831	2025-12-27 15:00:04.05	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3220
b82f8af3-a731-4d2a-891c-47f1b168b8ed	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:50:00.73	2025-12-25 19:50:04.094	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3367
a2dd8470-70bb-474c-870f-6d37c8827be6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:00:00.068	2025-12-25 20:00:03.427	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3359
093f34c8-b382-416e-9831-0b7a940798f5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 17:50:00.439	2025-12-27 17:50:04.063	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3626
09fe2aaf-779b-40f2-8edc-60b021db2dd7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:10:00.273	2025-12-25 20:10:03.749	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3477
a1feae5c-f8fe-4e55-a70f-e467a11455e5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:20:00.063	2025-12-25 20:20:03.394	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3332
253f4813-7b6a-4fdd-98ef-d1357f1ce884	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 20:40:00.611	2025-12-27 20:40:03.963	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3352
5e043b1b-356c-4dee-913e-1afefebbb0be	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:30:00.542	2025-12-25 20:30:03.879	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3338
1cc9335b-b6ad-459b-8663-0ece0dcec898	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:40:00.565	2025-12-25 20:40:03.985	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3421
a4a7534c-bc49-44dc-94e9-72432525e650	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:50:00.384	2025-12-25 20:50:03.794	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3411
3ef6b414-3f34-4aba-a37e-2f161f83bfd9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 15:50:00.106	2025-12-26 15:50:06.127	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6021
98184ae2-fd58-4fa4-8972-f7c8e48b7253	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:00:00.94	2025-12-26 16:00:05.454	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4514
3ce322ad-7ddd-48b4-892d-2f7573064dc2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:10:00.718	2025-12-26 16:10:05.582	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4865
1ce4211a-d614-40ac-973a-5abed3543cde	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 16:20:00.037	2025-12-26 16:20:04.877	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4840
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

\unrestrict lJ8d5bas1ZKGBA7fE5vCaX8rHuLUtlHgW1cM4oaRL8XvbwDEZ1FJXs8oS8Ergf6

