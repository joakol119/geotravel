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
6	Playa Pocitos	Playa urbana más popular de Montevideo.	playa	0101000020E61000004E62105839144CC02FDD2406817541C0	\N
8	Museo Nacional de Artes Visuales	Principal museo de artes plásticas del Uruguay.	museo	0101000020E61000002FDD240681154CC077BE9F1A2F7541C0	\N
9	FacArq	Facultad arquitectura	monumento	0101000020E6100000DCA16131EA144CC04930D5CC5A7441C0	https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Facultad_de_Arquitectura%2C_Montevideo_38.jpg/330px-Facultad_de_Arquitectura%2C_Montevideo_38.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail
7	Faro de Punta Carretas	Faro histórico con vistas panorámicas.	monumento	0101000020E6100000DBF97E6ABC144CC0D9CEF753E37541C0	https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Facultad_de_Ingenier%C3%ADa_%28Uruguay%29.jpg/330px-Facultad_de_Ingenier%C3%ADa_%28Uruguay%29.jpg
10	Estadio Centenario	Estadio de la Selección Uruguaya	monumento	0101000020E6100000910BCEE0EF134CC0D3DB9F8B867241C0	https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Estadio_centenario_1.JPG/330px-Estadio_centenario_1.JPG
1	Teatro Solís	Principal teatro de Uruguay, inaugurado en 1856.	teatro	0101000020E61000001904560E2D1A4CC05C8FC2F5287441C0	\N
\.


--
-- Data for Name: historico_estado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.historico_estado (id, recorrido_id, estado, fecha, observacion) FROM stdin;
1	1	pendiente	2026-01-15 10:00:00	Recorrido creado
2	1	disponible	2026-02-01 09:00:00	Aprobado para temporada
3	2	pendiente	2026-01-20 11:00:00	Recorrido creado
4	2	disponible	2026-02-01 09:30:00	Aprobado - disponible todo el año
5	3	pendiente	2026-02-10 14:00:00	Recorrido creado
6	3	disponible	2026-03-01 08:00:00	Disponible para temporada de verano
7	4	pendiente	2026-03-01 10:00:00	Recorrido en planificación
8	6	disponible	2026-05-17 21:32:56.079443	\N
9	6	cancelado	2026-05-19 17:39:36.2831	\N
10	4	disponible	2026-05-22 13:12:19.327681	\N
11	3	cancelado	2026-05-22 19:39:56.465923	\N
12	2	fuera_de_estacion	2026-05-22 19:43:05.459003	\N
13	2	fuera_de_estacion	2026-05-22 19:43:08.391168	\N
14	2	fuera_de_estacion	2026-05-22 19:47:40.455519	\N
15	2	fuera_de_estacion	2026-05-22 19:48:35.084152	\N
16	2	fuera_de_estacion	2026-05-22 19:50:15.863233	\N
17	2	fuera_de_estacion	2026-05-22 19:59:22.472527	\N
18	2	fuera_de_estacion	2026-05-22 19:59:34.14361	\N
19	2	fuera_de_estacion	2026-05-22 19:59:43.133031	\N
20	2	fuera_de_estacion	2026-05-22 19:59:46.415167	\N
21	2	fuera_de_estacion	2026-05-22 20:05:30.285997	\N
22	2	fuera_de_estacion	2026-05-22 20:05:34.446204	\N
23	2	fuera_de_estacion	2026-05-22 20:07:10.622969	\N
24	2	cancelado	2026-05-22 20:07:59.370168	\N
25	4	fuera_de_estacion	2026-05-22 20:08:11.547392	\N
26	4	fuera_de_estacion	2026-05-22 20:08:15.618577	\N
27	1	fuera_de_estacion	2026-05-22 20:08:21.956004	\N
28	4	fuera_de_estacion	2026-05-22 20:08:25.049172	\N
29	4	fuera_de_estacion	2026-05-22 20:09:17.218535	\N
30	4	fuera_de_estacion	2026-05-22 20:10:14.682373	\N
31	4	fuera_de_estacion	2026-05-22 20:12:07.873576	\N
32	4	fuera_de_estacion	2026-05-22 20:12:52.541066	\N
33	1	fuera_de_estacion	2026-05-22 20:15:32.043399	\N
34	1	fuera_de_estacion	2026-05-22 20:15:38.297128	\N
35	1	fuera_de_estacion	2026-05-22 20:15:48.9628	\N
36	1	fuera_de_estacion	2026-05-22 20:17:01.676726	\N
37	1	fuera_de_estacion	2026-05-22 20:18:20.683181	\N
38	1	fuera_de_estacion	2026-05-22 22:52:28.47305	\N
39	1	fuera_de_estacion	2026-05-22 22:53:12.921344	\N
40	1	fuera_de_estacion	2026-05-22 22:57:23.579002	\N
41	1	fuera_de_estacion	2026-05-22 22:57:28.552649	\N
42	1	fuera_de_estacion	2026-05-22 22:57:46.054079	\N
43	4	fuera_de_estacion	2026-05-22 22:57:49.621025	\N
44	1	fuera_de_estacion	2026-05-22 22:58:04.57726	\N
45	1	fuera_de_estacion	2026-05-22 23:00:49.553652	\N
46	1	fuera_de_estacion	2026-05-22 23:02:34.660608	\N
47	1	fuera_de_estacion	2026-05-22 23:04:00.035059	\N
48	1	fuera_de_estacion	2026-05-22 23:06:34.792551	\N
49	1	fuera_de_estacion	2026-05-22 23:06:39.385047	\N
50	1	fuera_de_estacion	2026-05-22 23:08:40.880531	\N
51	1	fuera_de_estacion	2026-05-22 23:16:44.059891	\N
52	4	fuera_de_estacion	2026-05-22 23:16:57.838319	\N
53	1	fuera_de_estacion	2026-05-24 13:28:13.435162	\N
54	1	fuera_de_estacion	2026-05-24 13:28:51.327888	\N
55	4	fuera_de_estacion	2026-05-24 13:29:44.132296	\N
56	1	fuera_de_estacion	2026-05-24 13:32:55.958523	\N
57	4	fuera_de_estacion	2026-05-24 13:33:31.872086	\N
58	5	disponible	2026-05-24 13:33:36.760645	\N
59	5	fuera_de_estacion	2026-05-24 13:33:44.620012	\N
60	7	disponible	2026-05-24 13:33:58.507597	\N
61	1	fuera_de_estacion	2026-05-24 13:40:50.162792	\N
62	1	fuera_de_estacion	2026-05-24 13:40:54.80095	\N
63	8	disponible	2026-05-24 13:41:02.274718	\N
64	5	cancelado	2026-05-24 13:57:10.612164	\N
65	1	cancelado	2026-05-24 14:19:15.444066	\N
\.


--
-- Data for Name: recorrido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recorrido (id, nombre, descripcion, duracion_estimada, guia_responsable, tipo_experiencia, estado, estacion_inicio, estacion_fin, geom) FROM stdin;
5	prueba A	ola como ets 2\npruebas	5	Maria	cultural	cancelado	1	12	0102000020E6100000030000008C6A11514C1A4CC00473F4F8BD7341C070404B57B0174CC02F1686C8E97341C0DC476E4DBA154CC0E96514CB2D7341C0
1	Recorrido Histórico Ciudad Vieja	Paseo por los principales puntos históricos del casco antiguo.	3 horas	María González	historica	cancelado	3	12	0102000020E6100000040000001904560E2D1A4CC05C8FC2F5287441C060E5D022DB194CC0A301BC05127441C08B6CE7FBA9194CC079E92631087441C09A99999999194CC08716D9CEF77341C0
11	prueba pendiente	a	2	maria	cultural	pendiente	4	6	0102000020E610000002000000E0F42EDE8F194CC0556CCCEB887341C0B2A19BFD81164CC00ED76A0F7B7341C0
12	asd	asd	asd	asd	cultural	pendiente	3	12	0102000020E6100000020000005516855D14154CC0390EBC5AEE7241C0AD69DE718A164CC053CA6B25747341C0
13	rector	asd	3	maria	natural	pendiente	3	11	0102000020E610000003000000D5B14AE999164CC0DD7A4D0F0A7441C0DFA5D425E3144CC06DFFCA4A937441C0001AA54BFF144CC00AF65FE7A67341C0
14	asd	asd	4	Pedro	cultural	pendiente	3	10	0102000020E610000002000000EA04341136164CC0A321E3512A7341C024B4E55C8A174CC0A8380EBC5A7241C0
6	prueba B	\N	\N	\N	cultural	cancelado	1	3	0102000020E6100000020000002C0FD253E4184CC05BEF37DA717341C05EBD8A8C0E184CC023A46E675F7341C0
3	Paseo Costero Pocitos	Caminata por la rambla desde Parque Rodó hasta Playa Pocitos.	2.5 horas	Ana Martínez	natural	cancelado	11	3	0102000020E6100000030000002FDD240681154CC077BE9F1A2F7541C0DBF97E6ABC144CC0D9CEF753E37541C04E62105839144CC02FDD2406817541C0
2	Ruta Gastronómica del Puerto	Degustación y visita a los mejores puestos del Mercado del Puerto. PRUEBA	2 horas	Carlos Rodríguez	gastronomica	cancelado	1	12	0102000020E61000000300000060E5D022DB194CC0A301BC05127441C01904560E2D1A4CC05C8FC2F5287441C06DE7FBA9F11A4CC0787AA52C437441C0
4	Tour Cultural Completo	Visita a los principales museos y teatros de Montevideo.	5 horas	Pedro López	cultural	disponible	4	11	0102000020E6100000030000001904560E2D1A4CC05C8FC2F5287441C09A99999999194CC08716D9CEF77341C02FDD240681154CC077BE9F1A2F7541C0
7	parque rodo	paseo	\N	\N	cultural	disponible	1	12	0102000020E6100000020000009ED2C1FA3F154CC0E469F981AB7441C08EB27E3331154CC026C45C52B57541C0
9	asdfff	\N	\N	\N	cultural	pendiente	1	12	0102000020E610000002000000AF93FAB2B4154CC0410B09185D7641C0B891B245D2144CC007978E39CF7641C0
10	asddddd	asd	\N	\N	cultural	pendiente	1	12	0102000020E610000002000000F1F44A5986144CC04033880FEC7641C0AA622AFD84134CC0D99942E7357641C0
8	rambla	\N	\N	\N	cultural	disponible	1	12	0102000020E610000002000000164CFC51D4154CC0A22AA6D24F7641C01D5A643BDF154CC0B7EC10FFB07541C0
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
10	3	6	3
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
2	Rambla de Pocitos	Paseo costero con playas, parques y gastronomía.	2	Ideal para recorridos al aire libre.	0103000020E6100000010000000500000085EB51B81E154CC085EB51B81E7541C085EB51B81E154CC0BC749318047641C03333333333134CC0BC749318047641C03333333333134CC085EB51B81E7541C085EB51B81E154CC085EB51B81E7541C0
6	cba	prueba	3	a	0103000020E61000000100000006000000F8E3F6CB27194CC00B62A06B5F7441C070B20DDC81184CC04277499C157541C0386BF0BE2A174CC086ADD9CA4B7441C0098D60E3FA174CC03448C153C87341C0317BD976DA184CC066BFEE74E77341C0F8E3F6CB27194CC00B62A06B5F7441C0
7	Parque Batlle	\N	4	Parque Nacional de Uruguay	0103000020E6100000010000000B000000672C9ACE4E144CC0F25D4A5D327241C0B858518369144CC057EE0566857241C08E40BCAE5F144CC068588CBAD67241C0CAA7C7B60C144CC0B0C91AF5107341C0AB96749483134CC03AB01C21037341C034BE2F2E55134CC0EA77616BB67241C0338AE59656134CC086E7A562637241C069C36169E0134CC0CE1951DA1B7241C090A339B2F2134CC0D53E1D8F197241C0A12B11A8FE134CC059518369187241C0672C9ACE4E144CC0F25D4A5D327241C0
9	a	a	2	a	0103000020E61000000100000005000000BA30D28BDA174CC052280B5F5F7341C036035C902D174CC00322C495B37341C097E2AAB2EF164CC01B2E724F577341C0D0B7054B75174CC06C787AA52C7341C0BA30D28BDA174CC052280B5F5F7341C0
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

SELECT pg_catalog.setval('public.historico_estado_id_seq', 65, true);


--
-- Name: recorrido_atraccion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recorrido_atraccion_id_seq', 13, true);


--
-- Name: recorrido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recorrido_id_seq', 14, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_seq', 1, true);


--
-- Name: zona_turistica_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zona_turistica_id_seq', 9, true);


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

