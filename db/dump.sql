--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Debian 16.4-1.pgdg110+2)
-- Dumped by pg_dump version 16.4 (Debian 16.4-1.pgdg110+2)

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
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger;


ALTER SCHEMA tiger OWNER TO postgres;

--
-- Name: tiger_data; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiger_data;


ALTER SCHEMA tiger_data OWNER TO postgres;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: estado_recorrido; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_recorrido AS ENUM (
    'disponible',
    'fuera_de_estacion',
    'pendiente',
    'cancelado'
);


ALTER TYPE public.estado_recorrido OWNER TO postgres;

--
-- Name: tipo_experiencia; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_experiencia AS ENUM (
    'cultural',
    'gastronomica',
    'natural',
    'historica'
);


ALTER TYPE public.tipo_experiencia OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: atraccion_turistica; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atraccion_turistica (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    descripcion text,
    clasificacion character varying(100),
    geom public.geometry(Point,4326) NOT NULL,
    foto_url text
);


ALTER TABLE public.atraccion_turistica OWNER TO postgres;

--
-- Name: atraccion_turistica_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.atraccion_turistica_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.atraccion_turistica_id_seq OWNER TO postgres;

--
-- Name: atraccion_turistica_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.atraccion_turistica_id_seq OWNED BY public.atraccion_turistica.id;


--
-- Name: historico_estado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historico_estado (
    id integer NOT NULL,
    recorrido_id integer NOT NULL,
    estado public.estado_recorrido NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    observacion text
);


ALTER TABLE public.historico_estado OWNER TO postgres;

--
-- Name: historico_estado_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historico_estado_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.historico_estado_id_seq OWNER TO postgres;

--
-- Name: historico_estado_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historico_estado_id_seq OWNED BY public.historico_estado.id;


--
-- Name: recorrido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recorrido (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    descripcion text,
    duracion_estimada character varying(100),
    guia_responsable character varying(200),
    tipo_experiencia public.tipo_experiencia NOT NULL,
    estado public.estado_recorrido DEFAULT 'pendiente'::public.estado_recorrido NOT NULL,
    estacion_inicio integer NOT NULL,
    estacion_fin integer NOT NULL,
    geom public.geometry(LineString,4326) NOT NULL,
    CONSTRAINT recorrido_estacion_fin_check CHECK (((estacion_fin >= 1) AND (estacion_fin <= 12))),
    CONSTRAINT recorrido_estacion_inicio_check CHECK (((estacion_inicio >= 1) AND (estacion_inicio <= 12)))
);


ALTER TABLE public.recorrido OWNER TO postgres;

--
-- Name: recorrido_atraccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recorrido_atraccion (
    id integer NOT NULL,
    recorrido_id integer NOT NULL,
    atraccion_id integer NOT NULL,
    orden integer NOT NULL,
    CONSTRAINT recorrido_atraccion_orden_check CHECK ((orden > 0))
);


ALTER TABLE public.recorrido_atraccion OWNER TO postgres;

--
-- Name: recorrido_atraccion_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recorrido_atraccion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recorrido_atraccion_id_seq OWNER TO postgres;

--
-- Name: recorrido_atraccion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recorrido_atraccion_id_seq OWNED BY public.recorrido_atraccion.id;


--
-- Name: recorrido_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recorrido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recorrido_id_seq OWNER TO postgres;

--
-- Name: recorrido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recorrido_id_seq OWNED BY public.recorrido.id;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_seq OWNER TO postgres;

--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;


--
-- Name: zona_turistica; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zona_turistica (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    descripcion text,
    nivel_atractivo integer NOT NULL,
    observaciones text,
    geom public.geometry(Polygon,4326) NOT NULL,
    CONSTRAINT zona_turistica_nivel_atractivo_check CHECK (((nivel_atractivo >= 1) AND (nivel_atractivo <= 5)))
);


ALTER TABLE public.zona_turistica OWNER TO postgres;

--
-- Name: zona_turistica_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zona_turistica_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zona_turistica_id_seq OWNER TO postgres;

--
-- Name: zona_turistica_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zona_turistica_id_seq OWNED BY public.zona_turistica.id;


--
-- Name: atraccion_turistica id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atraccion_turistica ALTER COLUMN id SET DEFAULT nextval('public.atraccion_turistica_id_seq'::regclass);


--
-- Name: historico_estado id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_estado ALTER COLUMN id SET DEFAULT nextval('public.historico_estado_id_seq'::regclass);


--
-- Name: recorrido id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido ALTER COLUMN id SET DEFAULT nextval('public.recorrido_id_seq'::regclass);


--
-- Name: recorrido_atraccion id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido_atraccion ALTER COLUMN id SET DEFAULT nextval('public.recorrido_atraccion_id_seq'::regclass);


--
-- Name: usuario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- Name: zona_turistica id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zona_turistica ALTER COLUMN id SET DEFAULT nextval('public.zona_turistica_id_seq'::regclass);


--
-- Data for Name: atraccion_turistica; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.atraccion_turistica (id, nombre, descripcion, clasificacion, geom, foto_url) FROM stdin;
2	Plaza Independencia	Principal plaza de Montevideo con el Mausoleo de Artigas.	plaza	0101000020E61000008B6CE7FBA9194CC079E92631087441C0	\N
3	Puerta de la Ciudadela	Restos de la antigua muralla de Montevideo.	monumento	0101000020E610000060E5D022DB194CC0A301BC05127441C0	\N
4	Mercado del Puerto	Mercado gastronómico tradicional desde 1868.	gastronomia	0101000020E61000006DE7FBA9F11A4CC0787AA52C437441C0	\N
5	Museo Torres García	Museo dedicado al artista uruguayo Joaquín Torres García.	museo	0101000020E61000009A99999999194CC08716D9CEF77341C0	\N
8	Museo Nacional de Artes Visuales	Principal museo de artes plásticas del Uruguay.	museo	0101000020E61000002FDD240681154CC077BE9F1A2F7541C0	\N
7	Faro de Punta Carretas	Faro histórico con vistas panorámicas.	monumento	0101000020E6100000DBF97E6ABC144CC0D9CEF753E37541C0	https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Facultad_de_Ingenier%C3%ADa_%28Uruguay%29.jpg/330px-Facultad_de_Ingenier%C3%ADa_%28Uruguay%29.jpg
1	Teatro Solís	Principal teatro de Uruguay, inaugurado en 1856.	teatro	0101000020E61000001904560E2D1A4CC05C8FC2F5287441C0	\N
\.


--
-- Data for Name: historico_estado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.historico_estado (id, recorrido_id, estado, fecha, observacion) FROM stdin;
7	4	pendiente	2026-03-01 10:00:00	Recorrido en planificación
10	4	disponible	2026-05-22 13:12:19.327681	\N
25	4	fuera_de_estacion	2026-05-22 20:08:11.547392	\N
26	4	fuera_de_estacion	2026-05-22 20:08:15.618577	\N
28	4	fuera_de_estacion	2026-05-22 20:08:25.049172	\N
29	4	fuera_de_estacion	2026-05-22 20:09:17.218535	\N
30	4	fuera_de_estacion	2026-05-22 20:10:14.682373	\N
31	4	fuera_de_estacion	2026-05-22 20:12:07.873576	\N
32	4	fuera_de_estacion	2026-05-22 20:12:52.541066	\N
43	4	fuera_de_estacion	2026-05-22 22:57:49.621025	\N
52	4	fuera_de_estacion	2026-05-22 23:16:57.838319	\N
55	4	fuera_de_estacion	2026-05-24 13:29:44.132296	\N
57	4	fuera_de_estacion	2026-05-24 13:33:31.872086	\N
\.


--
-- Data for Name: recorrido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recorrido (id, nombre, descripcion, duracion_estimada, guia_responsable, tipo_experiencia, estado, estacion_inicio, estacion_fin, geom) FROM stdin;
1	Recorrido Histórico Ciudad Vieja	Paseo por los principales puntos históricos del casco antiguo.	3 horas	María González	historica	disponible	3	12	0102000020E6100000040000001904560E2D1A4CC05C8FC2F5287441C060E5D022DB194CC0A301BC05127441C08B6CE7FBA9194CC079E92631087441C09A99999999194CC08716D9CEF77341C0
2	Ruta Gastronómica del Puerto	Degustación y visita a los mejores puestos del Mercado del Puerto. PRUEBA	2 horas	Carlos Rodríguez	gastronomica	disponible	1	12	0102000020E61000000300000060E5D022DB194CC0A301BC05127441C01904560E2D1A4CC05C8FC2F5287441C06DE7FBA9F11A4CC0787AA52C437441C0
3	Paseo Costero Pocitos	Caminata por la rambla desde Parque Rodó hasta Playa Pocitos.	2.5 horas	Ana Martínez	natural	fuera_de_estacion	11	3	0102000020E6100000030000002FDD240681154CC077BE9F1A2F7541C0DBF97E6ABC144CC0D9CEF753E37541C04E62105839144CC02FDD2406817541C0
4	Tour Cultural Completo	Visita a los principales museos y teatros de Montevideo.	5 horas	Pedro López	cultural	disponible	4	11	0102000020E6100000030000001904560E2D1A4CC05C8FC2F5287441C09A99999999194CC08716D9CEF77341C02FDD240681154CC077BE9F1A2F7541C0
\.


--
-- Data for Name: recorrido_atraccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recorrido_atraccion (id, recorrido_id, atraccion_id, orden) FROM stdin;
1	1	1	1
2	1	3	2
3	1	2	3
4	1	5	4
5	2	3	1
6	2	1	2
7	2	4	3
8	3	8	1
9	3	7	2
11	4	1	1
12	4	5	2
13	4	8	3
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id, email, password_hash, activo, created_at) FROM stdin;
1	admin@geotravel.com	admin123	t	2026-05-21 23:15:08.654311
\.


--
-- Data for Name: zona_turistica; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zona_turistica (id, nombre, descripcion, nivel_atractivo, observaciones, geom) FROM stdin;
15	Ciudad Vieja	Barrio histórico de Montevideo, cuna de la ciudad. Concentra la mayor parte del patrimonio arquitectónico colonial, museos, teatros y la vida cultural de la capital.\n	1	Mayor concentración de atractivos culturales de Montevideo.	0103000020E6100000010000000D000000CBA145B6F3194CC098BD6C3B6D7341C00305DEC9A7194CC015C616821C7441C003D19332A9194CC0B91798158A7441C0EC1516DC0F1A4CC0821DFF05827441C017D4B7CCE91A4CC068CD8FBFB47441C02429E961681B4CC03CD9CD8C7E7441C022C154336B1B4CC05055A181587441C09F05A1BC8F1B4CC0EBC4E578057441C0C9AB730CC81A4CC0BE2EC37FBA7341C0D7F6764B721A4CC0C4B12E6EA37341C0B54E5C8E571A4CC00803CFBD877341C03FAA61BF271A4CC092E9D0E9797341C0CBA145B6F3194CC098BD6C3B6D7341C0
\.


--
-- Data for Name: geocode_settings; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.geocode_settings (name, setting, unit, category, short_desc) FROM stdin;
\.


--
-- Data for Name: pagc_gaz; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_gaz (id, seq, word, stdword, token, is_custom) FROM stdin;
\.


--
-- Data for Name: pagc_lex; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_lex (id, seq, word, stdword, token, is_custom) FROM stdin;
\.


--
-- Data for Name: pagc_rules; Type: TABLE DATA; Schema: tiger; Owner: postgres
--

COPY tiger.pagc_rules (id, rule, is_custom) FROM stdin;
\.


--
-- Data for Name: topology; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.topology (id, name, srid, "precision", hasz) FROM stdin;
\.


--
-- Data for Name: layer; Type: TABLE DATA; Schema: topology; Owner: postgres
--

COPY topology.layer (topology_id, layer_id, schema_name, table_name, feature_column, feature_type, level, child_id) FROM stdin;
\.


--
-- Name: atraccion_turistica_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.atraccion_turistica_id_seq', 10, true);


--
-- Name: historico_estado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.historico_estado_id_seq', 66, true);


--
-- Name: recorrido_atraccion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recorrido_atraccion_id_seq', 13, true);


--
-- Name: recorrido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recorrido_id_seq', 15, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_seq', 1, true);


--
-- Name: zona_turistica_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zona_turistica_id_seq', 16, true);


--
-- Name: topology_id_seq; Type: SEQUENCE SET; Schema: topology; Owner: postgres
--

SELECT pg_catalog.setval('topology.topology_id_seq', 1, false);


--
-- Name: atraccion_turistica atraccion_turistica_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atraccion_turistica
    ADD CONSTRAINT atraccion_turistica_pkey PRIMARY KEY (id);


--
-- Name: historico_estado historico_estado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_estado
    ADD CONSTRAINT historico_estado_pkey PRIMARY KEY (id);


--
-- Name: recorrido_atraccion recorrido_atraccion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido_atraccion
    ADD CONSTRAINT recorrido_atraccion_pkey PRIMARY KEY (id);


--
-- Name: recorrido_atraccion recorrido_atraccion_recorrido_id_atraccion_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido_atraccion
    ADD CONSTRAINT recorrido_atraccion_recorrido_id_atraccion_id_key UNIQUE (recorrido_id, atraccion_id);


--
-- Name: recorrido_atraccion recorrido_atraccion_recorrido_id_orden_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido_atraccion
    ADD CONSTRAINT recorrido_atraccion_recorrido_id_orden_key UNIQUE (recorrido_id, orden);


--
-- Name: recorrido recorrido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido
    ADD CONSTRAINT recorrido_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: zona_turistica zona_turistica_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zona_turistica
    ADD CONSTRAINT zona_turistica_pkey PRIMARY KEY (id);


--
-- Name: idx_atraccion_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_atraccion_geom ON public.atraccion_turistica USING gist (geom);


--
-- Name: idx_historico_recorrido; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_historico_recorrido ON public.historico_estado USING btree (recorrido_id);


--
-- Name: idx_recorrido_atraccion_atr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recorrido_atraccion_atr ON public.recorrido_atraccion USING btree (atraccion_id);


--
-- Name: idx_recorrido_atraccion_rec; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recorrido_atraccion_rec ON public.recorrido_atraccion USING btree (recorrido_id);


--
-- Name: idx_recorrido_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recorrido_estado ON public.recorrido USING btree (estado);


--
-- Name: idx_recorrido_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recorrido_geom ON public.recorrido USING gist (geom);


--
-- Name: idx_recorrido_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_recorrido_tipo ON public.recorrido USING btree (tipo_experiencia);


--
-- Name: idx_zona_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_zona_geom ON public.zona_turistica USING gist (geom);


--
-- Name: historico_estado historico_estado_recorrido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_estado
    ADD CONSTRAINT historico_estado_recorrido_id_fkey FOREIGN KEY (recorrido_id) REFERENCES public.recorrido(id) ON DELETE CASCADE;


--
-- Name: recorrido_atraccion recorrido_atraccion_atraccion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido_atraccion
    ADD CONSTRAINT recorrido_atraccion_atraccion_id_fkey FOREIGN KEY (atraccion_id) REFERENCES public.atraccion_turistica(id) ON DELETE CASCADE;


--
-- Name: recorrido_atraccion recorrido_atraccion_recorrido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recorrido_atraccion
    ADD CONSTRAINT recorrido_atraccion_recorrido_id_fkey FOREIGN KEY (recorrido_id) REFERENCES public.recorrido(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

