--
-- PostgreSQL database dump
--

\restrict AHyecmmeJXyP4JAe1yIOnJ8ynINSGHOEAoNQ6NrnxA73rBDorUg45wbVVGYN5b3

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
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.platform_cookies OWNER TO wangxuyang;

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
cc0262d7-f5a2-42d0-80b0-657d92ecf3b6	xiaohongshu	694a4a1e000000001d038776	cursor太贵了，有什么平替	momo		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/cursor太贵了，有什么平替_694a4a1e000000001d038776	http://sns-webpic-qc.xhscdn.com/202512251840/6be5b346a11e51cfc21473fea68d4d30/1040g2sg31qe7nosr74kg5o7k4so08j5m5lg6lso!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694a4a1e000000001d038776?xsec_token=ABEU_34yv7jxXLA3D19ZuXajy_iUhH14K80g_kg2nBXHA=&xsec_source=	1	2025-12-25 18:40:58.353	\N	["http://sns-webpic-qc.xhscdn.com/202512251840/6be5b346a11e51cfc21473fea68d4d30/1040g2sg31qe7nosr74kg5o7k4so08j5m5lg6lso!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
ab15d3e5-7669-48a1-98b4-b39ef17e6fac	xiaohongshu	694dffea000000001e034c55	在厦门过圣诞🎄还可以穿裙子！！	小小猪🐷	不是很冷哈哈哈哈 俺可以坚持！\n#甜妹[话题]# #可甜可御可温柔[话题]# #厦门[话题]# #圣诞节日穿搭[话题]# #圣诞快乐[话题]# #厦门探店[话题]# #当个甜美女孩[话题]# #谁能拒绝甜妹[话题]# #御姐[话题]# #美女[话题]#	live_photo	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/在厦门过圣诞🎄还可以穿裙子！！_694dffea000000001e034c55	http://sns-webpic-qc.xhscdn.com/202512261656/f2f714704b9299090ac15fbab4a1e072/notes_pre_post/1040g3k831qhrlea6ga705nmbh7s081tuvbs7q70!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694dffea000000001e034c55?xsec_token=AB_yTc4-DAaR3t-JL6ZhYtDGHlxHdOQVN04mmMzCtX3_I=&xsec_source=pc_feed	1	2025-12-26 16:57:00.105	\N	["http://sns-webpic-qc.xhscdn.com/202512261656/f2f714704b9299090ac15fbab4a1e072/notes_pre_post/1040g3k831qhrlea6ga705nmbh7s081tuvbs7q70!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/999b494e7a72ec2bf8ba87dfda677f35/notes_pre_post/1040g3k831qhrlea6ga7g5nmbh7s081tu1on1ru8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/dda77cbd1f86b927bff7e95866b9d644/1040g2sg31qhrptqjg0705nmbh7s081tub1rvtjo!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/f8e596a243fb3a6af8c32889cdbcae7c/notes_pre_post/1040g3k831qhrlea6ga805nmbh7s081tue4drfl0!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261656/5bf3d2fe0a0d50ea22e69956d30974a9/notes_pre_post/1040g3k831qhrlea6ga8g5nmbh7s081tudueadio!nd_dft_wlteh_jpg_3"]	["http://sns-video-bd.xhscdn.com/stream/1/10/19/01e94dff9d1fb585010050039b58b25a59_19.mp4","http://sns-bak-v1.xhscdn.com/stream/1/10/19/01e94e00911d62b6010050039b58b261c7_19.mp4"]	0	5	2	\N	[]	0	0	f
b9b9511b-1676-4705-8f67-9112a2b7661a	xiaohongshu	6943cf25000000001e00216c	-	liU		image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/-_6943cf25000000001e00216c	http://sns-webpic-qc.xhscdn.com/202512261909/8a9a6dfd0691bcab5bb1ab9a34851f37/notes_pre_post/1040g3k831q7t8ml9gc7g5q7m60ndtvq0fkusfl8!nd_dft_wlteh_jpg_3	http://xhslink.com/o/1Xs0PFGLIYI	1	2025-12-26 19:09:41.534	\N	["http://sns-webpic-qc.xhscdn.com/202512261909/8a9a6dfd0691bcab5bb1ab9a34851f37/notes_pre_post/1040g3k831q7t8ml9gc7g5q7m60ndtvq0fkusfl8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261909/1dc9b93c61efb6fa4890e974b1e50b08/notes_pre_post/1040g3k831q7t8ml9gc705q7m60ndtvq0h8bvdj8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512261909/824b890b2f00cf63f296448ec3cff781/notes_pre_post/1040g3k831q7t8ml9gc805q7m60ndtvq02vu528o!nd_dft_wlteh_jpg_3"]	[]	0	8	0	\N	[]	0	0	f
7583a70c-1835-46b4-a489-39e8bdfee317	xiaohongshu	694e82c6000000001e02c901	你在就好了	CC-	#清纯[话题]#	image	/Users/wangxuyang/Downloads/01_GitHub/demo/videoAll/backend/media/xiaohongshu/你在就好了_694e82c6000000001e02c901	http://sns-webpic-qc.xhscdn.com/202512262051/670577764895bb802c1f9da4eac87054/notes_pre_post/1040g3k831qibl5ne7g405ouq7olpt81j3roprcg!nd_dft_wlteh_jpg_3	https://www.xiaohongshu.com/explore/694e82c6000000001e02c901?xsec_token=AB7MH_8h2mYcgfxpQlXwonGh5OoApYSFnSq_VhJQ-twbs=&xsec_source=pc_feed	1	2025-12-26 20:51:41.547	\N	["http://sns-webpic-qc.xhscdn.com/202512262051/670577764895bb802c1f9da4eac87054/notes_pre_post/1040g3k831qibl5ne7g405ouq7olpt81j3roprcg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262051/076cc08e5b697b4b704fa65400ed7e79/notes_pre_post/1040g3k831qibl5ne7g505ouq7olpt81j22ttdlg!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262051/7d445c9319d42042cbed09e0bd540781/notes_pre_post/1040g3k831qibl5ne7g4g5ouq7olpt81jlrl8hp8!nd_dft_wlteh_jpg_3","http://sns-webpic-qc.xhscdn.com/202512262051/849033df2a2569d058b6abce2c9e6fdc/notes_pre_post/1040g3k831qibl5ne7g5g5ouq7olpt81jd5n5p10!nd_dft_wlteh_jpg_3"]	[]	0	0	0	\N	[]	0	0	f
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
\.


--
-- Data for Name: crawl_tasks; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.crawl_tasks (id, name, platform, target_identifier, frequency, status, last_run_at, next_run_at, config, created_at) FROM stdin;
49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	https://www.xiaohongshu.com/user/profile/57146afe84edcd5ef0c7ef87?m_source=pwa	10min	1	2025-12-27 02:00:00.779	2025-12-27 02:10:00.779	{"cookie":null,"useDownloader":true}	2025-12-24 01:09:35.350335
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

COPY public.platform_cookies (id, platform, account_alias, cookies_encrypted, is_valid, last_checked_at, created_at) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: wangxuyang
--

COPY public.system_settings (id, storage_path, task_schedule_interval, hotsearch_fetch_interval, updated_at) FROM stdin;
0a4f0d0a-798a-4b90-9f54-11f78c7ab5fc	/test/path/	1800	1800	2025-12-23 20:09:28.33044
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
c2c95bc1-7bc9-41f1-a6bd-2698ff34f794	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:00:00.52	2025-12-26 21:00:03.997	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3478
5201a200-a995-42d7-8a32-a3c801cd3bfc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:30:00.98	2025-12-27 01:30:04.151	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3171
d37074c4-6bc4-4fd1-b6f2-b2c744fd9771	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:00:00.608	2025-12-25 16:00:03.811	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3204
30f5c9f9-15ae-41fd-8ec0-a4838321d032	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:10:00.683	2025-12-26 21:10:04.403	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3722
7a31a4b3-ae70-4526-b660-9d9ea9d3abf2	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:40:00.914	2025-12-27 01:40:04.164	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3250
17183c74-3843-4eaf-89f3-2b70e360f1db	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:10:00.271	2025-12-25 16:10:04.669	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4399
d8d532ea-869f-4be7-b548-b7a7804b0ad7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:20:00.507	2025-12-26 21:20:04.115	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3608
1910f4b6-da0f-421a-bd31-b6ad769be729	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:50:00.848	2025-12-27 01:50:04.058	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3211
30cf36e1-01ed-45f8-903e-d9941b4087c6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:20:00.9	2025-12-25 16:20:04.291	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3392
8bb2aa00-fc7b-48c9-b0ca-5e10382246fe	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:30:00.733	2025-12-26 21:30:04.887	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4154
0808b608-9963-40fa-b087-377fb07f35cf	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 02:00:00.742	\N	running	author	\N	\N	0	0	0	0
49224e74-60ea-4d09-a66e-364b167955f3	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:30:00.607	2025-12-25 16:30:04.348	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3743
8d950e33-b8af-4f6d-a006-114e403eceb6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:40:00.56	2025-12-26 21:40:03.86	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3301
fb790805-9e28-4ce7-afc2-5309f9da4567	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:40:00.254	2025-12-25 16:40:04.997	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4744
d7051fe7-6d71-4d00-b08b-3c2bc9ed0f71	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 21:50:00.733	2025-12-26 21:50:04.236	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3505
eb26eead-5fa1-4ab7-9687-656cdcd3ee39	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 16:50:00.825	2025-12-25 16:50:05.301	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4476
8fbfa14a-504e-45eb-88eb-023c269ff037	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:00:00.971	2025-12-26 22:00:03.867	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2897
b207fdaf-c3be-4717-a94c-d56884b33fc7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:00:00.481	2025-12-25 17:00:05.052	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4572
cc856216-87ad-4627-b5bc-49b39f8b2d00	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:10:00.052	2025-12-26 22:10:03.176	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3125
de763b1f-0319-4900-85e9-8ea3e88c0117	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:10:00.084	2025-12-25 17:10:05.094	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	5012
021645c3-3411-457b-9974-921d16723a92	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:20:00.831	2025-12-26 22:20:04.2	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3369
e2cc2f4c-c04e-457d-acca-564973c1dc05	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:20:00.676	2025-12-25 17:20:05.024	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4348
fab0141a-071a-44bb-b93b-b0a21bd5a8dc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 22:30:00.387	2025-12-26 22:30:04.157	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3772
465547ad-b4bd-42da-961d-f94d3e0d2dd5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:30:00.347	2025-12-25 17:30:05.172	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4826
d08e526d-4072-47c7-a199-cd2772c0e20a	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:00:00.606	2025-12-26 23:00:04.07	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3467
85036e3d-3e4d-4793-b3ef-f53ff1167ff4	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:40:00.944	2025-12-25 17:40:07.801	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	6857
37231e4c-460b-496d-8ed1-d0916f8f25e8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:10:00.513	2025-12-26 23:10:04.004	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3495
09d578bd-88bd-434d-90f8-40f31c580d34	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 17:50:00.657	2025-12-25 17:50:03.792	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3137
f2fd2ea2-54fb-4b43-ae70-c95d7425af04	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:20:00.438	2025-12-26 23:20:04.051	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3616
7e8fdb64-7d57-4cae-8745-8ff02592f705	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:00:00.448	2025-12-25 18:00:03.611	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3164
8f9b0ada-5e63-459f-bb2c-e036eda50a84	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:30:00.323	2025-12-26 23:30:03.74	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3420
b0ce66a9-5f3e-4e94-920e-fbb69f447b5c	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:10:00.104	2025-12-25 18:10:03.407	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3304
91dc75a6-6dfb-4806-be0c-d304c7a5640b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:40:00.184	2025-12-26 23:40:02.41	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	2227
4791a5ae-e2a5-4cbd-9aea-bdf83c7805cc	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:20:00.798	2025-12-25 18:20:04.238	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3440
d3bcf379-de65-4b1a-a1e0-4cea8a2eb9a8	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-26 23:50:00.129	2025-12-26 23:50:03.986	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3858
46ea4c0d-8fa7-436a-a16e-4776913c317b	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 18:40:00.462	2025-12-25 18:40:03.922	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3461
8ae7786d-c773-482d-a029-ab2569a6e892	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:00:00.457	2025-12-25 19:00:03.775	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3319
00db102e-54ab-410c-9953-b2e64c14cde0	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-27 01:10:00.694	2025-12-27 01:10:04.238	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3546
2436a598-63be-472f-94ff-886272152184	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:10:00.703	2025-12-25 19:10:04.273	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3570
e6c77508-ddf6-4eb3-8425-8ecca5e61538	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:20:00.804	2025-12-25 19:20:04.524	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3720
37a9f994-6746-47dd-9183-46c909db37a9	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:30:00.877	2025-12-25 19:30:05.295	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	4419
a40b329c-17f3-4730-9158-2eee0234f2f1	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:40:00.659	2025-12-25 19:40:04.179	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3520
b82f8af3-a731-4d2a-891c-47f1b168b8ed	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 19:50:00.73	2025-12-25 19:50:04.094	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3367
a2dd8470-70bb-474c-870f-6d37c8827be6	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:00:00.068	2025-12-25 20:00:03.427	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3359
09fe2aaf-779b-40f2-8edc-60b021db2dd7	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:10:00.273	2025-12-25 20:10:03.749	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3477
a1feae5c-f8fe-4e55-a70f-e467a11455e5	49132c8e-543f-44a0-bff5-426bbe820a64	123	xiaohongshu	2025-12-25 20:20:00.063	2025-12-25 20:20:03.394	failed	author	\N	ParseService.downloadMedia is not a function	0	0	0	3332
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
-- Name: users UQ_fe0bb3f6520ee0469504521e710; Type: CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_fe0bb3f6520ee0469504521e710" UNIQUE (username);


--
-- Name: IDX_CONTENT_PLATFORM_CONTENT_ID; Type: INDEX; Schema: public; Owner: wangxuyang
--

CREATE UNIQUE INDEX "IDX_CONTENT_PLATFORM_CONTENT_ID" ON public.contents USING btree (platform, content_id);


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
-- Name: task_logs FK_fdafd5e130ca3d2a7c12f957c5d; Type: FK CONSTRAINT; Schema: public; Owner: wangxuyang
--

ALTER TABLE ONLY public.task_logs
    ADD CONSTRAINT "FK_fdafd5e130ca3d2a7c12f957c5d" FOREIGN KEY (task_id) REFERENCES public.crawl_tasks(id);


--
-- PostgreSQL database dump complete
--

\unrestrict AHyecmmeJXyP4JAe1yIOnJ8ynINSGHOEAoNQ6NrnxA73rBDorUg45wbVVGYN5b3

