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
    foto_url text,
    tiempo_estimado integer DEFAULT 30
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

COPY public.atraccion_turistica (id, nombre, descripcion, clasificacion, geom, foto_url, tiempo_estimado) FROM stdin;
2	Plaza Independencia	Principal plaza de Montevideo con el Mausoleo de Artigas.	plaza	0101000020E61000008B6CE7FBA9194CC079E92631087441C0	\N	30
3	Puerta de la Ciudadela	Restos de la antigua muralla de Montevideo.	monumento	0101000020E610000060E5D022DB194CC0A301BC05127441C0	\N	30
4	Mercado del Puerto	Mercado gastronómico tradicional desde 1868.	gastronomia	0101000020E61000006DE7FBA9F11A4CC0787AA52C437441C0	\N	30
5	Museo Torres García	Museo dedicado al artista uruguayo Joaquín Torres García.	museo	0101000020E61000009A99999999194CC08716D9CEF77341C0	\N	30
1	Teatro Solís	Principal teatro de Uruguay, inaugurado en 1856.	teatro	0101000020E61000001904560E2D1A4CC05C8FC2F5287441C0	\N	30
11	Estadio Centenario	 Estadio histórico inaugurado en 1930 para el primer Mundial de Fútbol. Declarado Monumento Histórico Nacional y sede de los partidos más importantes del fútbol uruguayo.	monumento	0101000020E6100000D1764CDD95134CC05E13D21A837241C0	https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Estadio_Centenario_1930.jpg/330px-Estadio_Centenario_1930.jpg	30
13	Parque de la Amistad	El Parque de la Amistad es el primer espacio público totalmente inclusivo con accesibilidad universal en Montevideo. Ubicado en el predio de Villa Dolores, está diseñado para que niños, jóvenes y adultos disfruten sin barreras arquitectónicas ni sociales.	parque	0101000020E61000005DFC6D4F90124CC04CA59F70767341C0	https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Parque_de_la_Amistad_-_imf8935.jpg/330px-Parque_de_la_Amistad_-_imf8935.jpg	30
14	Planetario	Planetario de Montevideo, espacio dedicado a la divulgación de astronomía con proyecciones del cielo nocturno y exposiciones interactivas sobre el universo.	monumento	0101000020E610000087E0B88C9B124CC09E40D829567341C0	https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Planetario_2.jpg/330px-Planetario_2.jpg	30
16	Universo Pittamiglio - Castillo del Alquimista	Centro cultural ubicado en un castillo único del año 1911, con visitas guiadas y talleres espirituales.	monumento	0101000020E6100000E4F90CA837134CC02041F163CC7541C0	\N	30
15	Museo nacional de artes visuales	Información\nEl Museo Nacional de Artes Visuales es la institución que alberga la mayor colección pública de pintura y escultura de Uruguay, así como una destacada selección de arte extranjero. Se encuentra en el Parque Rodó de la ciudad de Montevideo	museo	0101000020E6100000564ACFF412154CC0D331E719FB7441C0	\N	30
\.


--
-- Data for Name: historico_estado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.historico_estado (id, recorrido_id, estado, fecha, observacion) FROM stdin;
7	4	pendiente	2026-03-01 10:00:00	Recorrido en planificación
10	4	disponible	2026-05-22 13:12:19.327681	\N
25	4	fuera_de_estacion	2026-05-22 20:08:11.547392	\N
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
11	4	1	1
12	4	5	2
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
17	Pocitos	Barrio costero residencial y comercial con una de las playas más populares de Montevideo, rambla animada y amplia oferta gastronómica.	2	Zona de gran actividad turística y recreativa sobre la rambla.	0103000020E610000001000000130000002E02637D03154CC08BC404357C7341C0B75D68AED3144CC004A9143B1A7541C0B9533A58FF134CC00307B474057541C0BBEF181EFB134CC0A565A4DE537541C0715985CD00134CC0938B31B08E7541C098A1F14410134CC0B4AF3C484F7541C098A1F14410134CC0FF25A94C317541C0718DCF64FF124CC00B7DB08C0D7541C0A7ECF483BA124CC01C06F357C87441C0C1ABE5CE4C124CC0FC170802647441C02123A0C211124CC0048E041A6C7441C0876EF607CA114CC0E4BA29E5B57441C0C6A52A6D71114CC0AC6F6072A37441C0D5CA845FEA114CC091477023657341C0AB24B20FB2124CC08C6665FB907341C05532005471134CC0C460FE0A997341C03160C9552C144CC0404E98309A7341C06CD102B4AD144CC00954FF20927341C02E02637D03154CC08BC404357C7341C0
20	Parque Rodo	Barrio cultural y recreativo que alberga el Parque Rodó, el Museo Nacional de Artes Visuales y la rambla. Punto de encuentro para familias y turistas.	2	Zona de esparcimiento con parque urbano, museos y acceso a la costa.	0103000020E61000000100000013000000C154336B29164CC01D3C139A247441C063D34A2190154CC015C616821C7441C0643BDF4F8D154CC04E621058397441C0055262D7F6144CC01E8D43FD2E7441C041B96DDFA3144CC001C3F2E7DB7641C0567E198C11154CC0DBA2CC06997641C0FDBB3E73D6154CC07FD93D79587641C027A089B0E1154CC0478E7406467641C053EC681CEA154CC04D11E0F42E7641C027A089B0E1154CC003D19332A97541C0B79BE09BA6154CC0A0336953757541C0B4CBB73EAC154CC07C6473D53C7541C0035C902DCB154CC088BB7A15197541C09E44847F11164CC08E8F16670C7541C09A40118B18164CC03CA3AD4A227541C0EDD45C6E30164CC03CA3AD4A227541C0E868554B3A164CC0FD321823127541C0990CC7F319164CC00307B474057541C0C154336B29164CC01D3C139A247441C0
21	Palermo	Barrio bohemio y gastronómico de Montevideo, conocido por su movida nocturna, bares, restaurantes y una vibrante escena cultural y artística.\n	3	Zona de referencia gastronómica y cultural, muy frecuentada por jóvenes y turistas.	0103000020E6100000010000000B000000CE88D2DEE0174CC094F77134477441C0AB7823F3C8174CC03D450E11377541C00EC0064488174CC0514CDE00337541C09983A0A355174CC05F454607247541C0EA76F69507174CC0A3E716BA127541C0297AE063B0164CC06CED7DAA0A7541C0AD307DAF21164CC0E8DA17D00B7541C0B134F0A31A164CC0B1E07EC0037541C0D714C8EC2C164CC0D12346CF2D7441C0FDF49F353F164CC0161747E5267441C0CE88D2DEE0174CC094F77134477441C0
22	Centro	Corazón comercial y administrativo de Montevideo. Concentra edificios históricos, teatros, el Palacio Legislativo y la principal arteria comercial de la ciudad, la Av. 18 de Julio.\n	2	Zona de alto tránsito peatonal con mezcla de comercio, cultura e historia.	0103000020E610000001000000180000008600E0D8B3174CC089618731E97341C048C49448A2174CC028F1B913EC7341C04CFC51D499174CC0D2C5A695427441C02D431CEBE2184CC003ECA353577441C00971E5EC9D194CC0C66E9F55667441C0F2B0506B9A194CC072A609DB4F7441C02C8194D8B5194CC0C9737D1F0E7441C02DB5DE6FB4194CC0CFF6E80DF77341C0CBD58F4DF2194CC01CD0D2156C7341C0F0E0270EA0194CC0FFB0A547537341C08EC8772975194CC0A4C343183F7341C0E38BF67821194CC012DC48D9227341C07E3B8908FF184CC03A1E3350197341C089B5F81400194CC01FF296AB1F7341C068AF3E1EFA184CC0B85CFDD8247341C038BD8BF7E3184CC0E814E467237341C04162BB7B80184CC02D08E57D1C7341C099F5622827184CC09B8E006E167341C0EE5A423EE8174CC003249A40117341C0B3EE1F0BD1174CC059DFC0E4467341C09E961FB8CA174CC0747973B8567341C0B456B439CE174CC0912A8A57597341C0A29A92ACC3174CC0462234828D7341C08600E0D8B3174CC089618731E97341C0
27	Punta Carretas	Barrio residencial y comercial de Montevideo, conocido por su rambla costera, el shopping Punta Carretas y el Faro, con vistas al Río de la Plata y una variada oferta gastronómica.	4	Zona con alta afluencia turística todo el año. Destaca por la rambla, el Faro de Punta Carretas y el shopping. Ideal para recorridos gastronómicos y culturales.	0103000020E610000001000000530000008BA9F413CE144CC043C879FF1F7541C043554CA59F144CC0B7EEE6A90E7741C0193DB7D095144CC06A85E97B0D7741C0F1F44A5986144CC0EEE87FB9167741C041B96DDFA3144CC0EF39B01C217741C04489963C9E144CC0AA46AF06287741C01BD9959691144CC0E814E467237741C0F1F44A5986144CC09CFC169D2C7741C0F1F44A5986144CC0DB6CACC43C7741C0F390291F82144CC097CADB114E7741C0F4F8BD4D7F144CC01409A69A597741C042EDB776A2144CC0FFEA71DF6A7741C06A696E85B0144CC08A22A46E677741C06631B1F9B8144CC00DE4D9E55B7741C08C118942CB144CC089D1730B5D7741C09015FC36C4144CC0C11C3D7E6F7741C08FE1B19FC5144CC07C293C68767741C0DFA5D425E3144CC0F816D68D777741C0055262D7F6144CC0888043A8527741C02DCE18E604154CC0D5E940D6537741C0055262D7F6144CC0B323D5777E7741C0DA39CD02ED144CC07D7A6CCB807741C092B1DAFCBF144CC07D7A6CCB807741C06B9DB81CAF144CC0A7CCCD37A27741C043554CA59F144CC0A7CCCD37A27741C043554CA59F144CC02B306475AB7741C018096D3997144CC0632AFD84B37741C018096D3997144CC09A249694BB7741C03F1D8F19A8144CC05C566133C07741C01BD9959691144CC05531957EC27741C0EE2422FC8B144CC05DA79196CA7741C0EF586C938A144CC042B5C189E87741C0EF586C938A144CC0F6ED2422FC7741C01AA54BFF92144CC0F78F85E8107841C0EE2422FC8B144CC0F06AB933137841C0F25CDF8783144CC03C8386FE097841C0CDE49B6D6E144CC02E39EE940E7841C0C9ACDEE176144CC094A12AA6D27741C0C878944A78144CC0D11E2FA4C37741C079E8BB5B59144CC0ECBFCE4D9B7741C07FBC57AD4C144CC007616EF7727741C07CB8E4B853144CC00DE4D9E55B7741C07A1C06F357144CC01ADD41EC4C7741C07A50508A56144CC0575A46EA3D7741C08124ECDB49144CC0DB6CACC43C7741C05470784144144CC0A2D0B2EE1F7741C052D4997B48144CC0F5BC1B0B0A7741C058A835CD3B144CC08577B988EF7641C08124ECDB49144CC00839EFFFE37641C056D80C7041144CC0C3F4BD86E07641C02FC4EA8F30144CC008E8BE9CD97641C02A8C2D0439144CC092CEC0C8CB7641C0DC63E94317144CC0D61F6118B07641C0B7B75B9203144CC09F76F86BB27641C0FAF202ECA3134CC07AA702EE797641C0D1764CDD95134CC0FC170802647641C07D7A6CCB80134CC03B376DC6697641C057CEDE196D134CC0043DD4B6617641C0365A0EF450134CC0FC170802647641C03526C45C52134CC04930D5CC5A7641C030BABC395C134CC0BDA772DA537641C02F52280B5F134CC0CBA0DAE0447641C03222516859134CC093A641D13C7641C05B069CA564134CC0D84812842B7641C0986DA7AD11134CC0DD7A4D0F0A7641C0BB7D569929134CC068B27F9E067641C09605137F14134CC0EA2285B2F07541C045D95BCAF9124CC0B3791C06F37541C0F67CCD72D9124CC0C0D02346CF7541C0D09CF529C7124CC07BDD2230D67541C08578245E9E124CC0FE9E58A7CA7541C03480B74082124CC08E59F624B07541C03318231285124CC048C49448A27541C059F8FA5A97124CC009A52F849C7541C0AC8C463EAF124CC04FE960FD9F7541C0D1048A58C4124CC04FE960FD9F7541C0F94CF6CFD3124CC0111B2C9CA47541C021C9ACDEE1124CC086E3F90CA87541C0718DCF64FF124CC01079CBD58F7541C0B9533A58FF134CC06FBC3B32567541C0B68311FB04144CC0CC5D4BC8077541C08D45D3D9C9144CC004A9143B1A7541C08BA9F413CE144CC043C879FF1F7541C0
28	Barrio sur	Barrio histórico de Montevideo, cuna del candombe y el carnaval uruguayo, con un rico patrimonio cultural afrouruguayo, conventillos emblemáticos y vida nocturna.	4	Zona de gran valor cultural e histórico. Epicentro del candombe y las Llamadas. Recomendable para recorridos culturales e históricos, especialmente en temporada de carnaval.\n\n	0103000020E61000000100000008000000070951BEA0194CC00BB3D0CE697441C0DD24068195194CC0AE11C138B87441C08FFCC1C073194CC02BA1BB24CE7441C0575BB1BFEC184CC0DF37BEF6CC7441C0E35295B6B8184CC0DF88EE59D77441C0C0046EDDCD174CC0BA32A836387541C0109546CCEC174CC009C03FA54A7441C0070951BEA0194CC00BB3D0CE697441C0
30	Parque Batlle	Parque Batlle es uno de los espacios verdes más importantes de Montevideo, conocido como el “pulmón” de la ciudad por sus más de 60 hectáreas de áreas verdes. Fue diseñado por el paisajista francés Carlos Thays y combina zonas arboladas, césped, monumentos históricos y espacios deportivos como el Estadio Centenario, el Velódromo y la pista de atletismo. Es un lugar muy usado para caminar, correr, andar en bici y actividades recreativas.	3	Muy buena conectividad con avenidas principales y otros barrios importantes.\nZona tranquila y residencial durante el día, con bastante movimiento deportivo y recreativo.	0103000020E61000000100000017000000D5CA845FEA114CC0986C3CD8627341C0268FA7E507124CC0B11A4B581B7341C074B7EBA529124CC064027E8D247341C0E8BF07AF5D124CC088653387A47241C0850662D9CC114CC0177E703E757241C010CAFB389A114CC0177E703E757241C035423F53AF114CC01D01DC2C5E7241C08A00A777F1104CC02DE8BD31047241C03A7AFCDEA6114CC0D40CA9A2787141C04837C2A222124CC0963E74417D7141C02331410DDF124CC000529B38B97141C0070ABC934F134CC079AF5A99F07141C05308E41247144CC028B682A6257241C052465C001A154CC0D3DB9F8B867241C02E02637D03154CC053CA6B25747341C017D522A298144CC04E4700378B7341C07FBC57AD4C144CC0CB85CABF967341C0672783A3E4134CC03FFD67CD8F7341C0834E081D74134CC03FFD67CD8F7341C06C21C84109134CC00954FF20927341C0A85489B2B7124CC04E4700378B7341C0E8BF07AF5D124CC0C2BE9D44847341C0D5CA845FEA114CC0986C3CD8627341C0
31	Cordon	Cordón es un distrito comercial céntrico con restaurantes de cadenas internacionales y tiendas populares, además de tiendas de artesanías que venden recipientes para yerba mate y accesorios de cuero uruguayos. La vida nocturna incluye bares de vino tradicionales y cervecerías modernas. El teatro Stella D’Italia, construido en 1895, tiene presentaciones de arte dramático y conciertos, mientras que en el gran Museo de Historia Natural, se exhiben minerales, fósiles y animales disecados.	3	Barrio muy céntrico y con excelente conectividad hacia gran parte de Montevideo.\nTiene mucho movimiento durante el día por la presencia de universidades, oficinas, comercios y servicios.	0103000020E610000001000000200000001EE0490B97174CC08C81751C3F7441C066A3737E8A154CC0A0FD4811197441C0670B08AD87154CC0D99942E7357441C0055262D7F6144CC0DF6DDE38297441C02C9ACE4E06154CC0990E9D9E777341C078F2E9B12D154CC053CA6B25747341C0884B8E3BA5154CC016FC36C4787341C0B3976DA7AD154CC0EA077591427341C02504ABEAE5154CC001C3F2E7DB7241C05184D4EDEC154CC0C7D5C8AEB47241C065A88AA9F4154CC062F4DC42577241C0C3BCC79926164CC0A8380EBC5A7241C0DC80CF0F23164CC0B70DA320787241C0739EB12FD9164CC0B03907CF847241C0739EB12FD9164CC0726BD26D897241C0AF0AD462F0164CC012FB04508C7241C0D61EF64201174CC0DA006C40847241C00C1F115322174CC0B900344A977241C0BEF6CC9200174CC0520DFB3DB17241C0271763601D174CC0A6D590B8C77241C0882F134548174CC001C3F2E7DB7241C0A9A3E36A64174CC08907944DB97241C0BB641C23D9174CC016BD5301F77241C00E2DB29DEF174CC010E9B7AF037341C0AA108FC4CB174CC0D5E940D6537341C06FD8B628B3174CC0363B527DE77341C0492C29779F174CC0D5CA845FEA7341C01DACFF7398174CC07104A9143B7441C04B5B5CE333174CC032E54350357441C089EC832C0B164CC001BF4692207441C0640795B88E154CC046B247A8197441C01EE0490B97174CC08C81751C3F7441C0
32	Buceo	Buceo es uno de los 62 barrios oficialmente reconocidos de Montevideo. Es una zona residencial costera, ubicada al sudeste de la ciudad, limítrofe con Malvín al este, Parque Batlle al noroeste, Pocitos suroeste, Villa Dolores al oeste, y Malvín Norte al noreste. 	1	Barrio costero con buena combinación entre zona residencial, comercial y oficinas.\nMuy valorado por su cercanía a la rambla y vistas al mar en algunos sectores.\nTiene áreas modernas y de gran desarrollo inmobiliario, especialmente cerca de Montevideo Shopping y World Trade Center.\nBuena conectividad y acceso a servicios, supermercados, gimnasios y restaurantes.\nAmbiente generalmente tranquilo y familiar en las zonas residenciales.	0103000020E6100000010000004C000000BC3FDEAB56124CC0D5CE30B5A57241C074EB353D28124CC0F65E7CD11E7341C0F9DA334B02124CC072FBE593157341C098BD6C3B6D114CC0F2B391EBA67441C04CFDBCA948114CC037A79201A07441C0B114C95702114CC0A73D25E7C47441C06420CF2EDF104CC0AE11C138B87441C0F17F4754A8104CC07DEBC37AA37441C0C4978922A4104CC0821DFF05827441C02EE7525C55104CC00B62A06B5F7441C029AF95D05D104CC0577A6D36567441C0C8CF46AE9B104CC088F19A57757441C0F17F4754A8104CC088A06AF46A7441C066BCADF4DA104CC012D89C83677441C063EC8497E0104CC0C6BFCFB8707441C08DD0CFD4EB104CC0C6BFCFB8707441C08ACC5CE0F2104CC0048E041A6C7441C0611C5C3AE6104CC08FC536A9687441C08C683BA6EE104CC08E7406465E7441C0B0AC342905114CC04930D5CC5A7441C0AE10566309114CC094F77134477441C086C8E9EBF9104CC094F77134477441C08A00A777F1104CC0E692AAED267441C0B4E4F1B4FC104CC0A0FD4811197441C08DD0CFD4EB104CC0AE47E17A147441C06420CF2EDF104CC06E861BF0F97341C063B83A00E2104CC0378C82E0F17341C0118C834BC7104CC073B8567BD87341C0EBABAB02B5104CC0740987DEE27341C0C63368E89F104CC06E35EB8CEF7341C09F1F46088F104CC0755AB741ED7341C07C43E1B375104CC0F2E9B12D037441C0043752B648104CC0F29881CAF87341C0DA1EBDE13E104CC076FC1708027441C0B6DAC35E28104CC0AC545051F57341C08A8EE4F21F104CC06E861BF0F97341C068B27F9E06104CC06E861BF0F97341C03F027FF8F90F4CC07C7F83F6EA7341C04206F2ECF20F4CC0F86C1D1CEC7341C0F1D93A38D80F4CC0740987DEE27341C0A01518B2BA0F4CC043E38920CE7341C0CDC98B4CC00F4CC03B6D8D08C67341C07765170CAE0F4CC0439259BDC37341C07901F6D1A90F4CC088855AD3BC7341C0A1496249B90F4CC088855AD3BC7341C07CD11E2FA40F4CC00B47904AB17341C0A3E5400FB50F4CC08D08C6C1A57341C079CDAB3AAB0F4CC017EFC7ED977341C0A01518B2BA0F4CC0D9CF6229927341C0C991CEC0C80F4CC01D210379767341C07CD11E2FA40F4CC066F50EB7437341C0B66801DA560F4CC033DC80CF0F7341C044FCC3961E0F4CC07FA31D37FC7241C0C91F0C3CF70E4CC0772D211FF47241C07D93A641D10E4CC0FB3F87F9F27241C05C1FD61BB50E4CC0FB3F87F9F27241C034D769A4A50E4CC0BDC282FB017341C00AF31E679A0E4CC0395FECBDF87241C005871744A40E4CC00F0D8B51D77241C0F2CF0CE2030F4CC0D0ED258DD17241C0CBBBEA01F30E4CC00D1AFA27B87241C06ADC9BDF300F4CC02426A8E15B7241C0CFBF5DF6EB0E4CC076C1E09A3B7241C0F86F5E9CF80E4CC0B43EE5982C7241C0CE8B135FED0E4CC037001B10217241C06ADC9BDF300F4CC008C89750C17141C0E31C75745C0F4CC08CDAFD2AC07141C0E2E82ADD5D0F4CC098E0D407927141C0C22FF5F3A6104CC0DC82A5BA807141C07C0F971C77104CC0D7506A2FA27141C0C7D9740470114CC00DFAD2DB9F7141C05FB4C70BE9104CC0F73E5585067241C03A7AFCDEA6114CC0EE7C3F355E7241C0E9818FC18A114CC0D9AF3BDD797241C087A2409FC8114CC0D9AF3BDD797241C0BC3FDEAB56124CC0D5CE30B5A57241C0
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

SELECT pg_catalog.setval('public.atraccion_turistica_id_seq', 16, true);


--
-- Name: historico_estado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.historico_estado_id_seq', 80, true);


--
-- Name: recorrido_atraccion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recorrido_atraccion_id_seq', 13, true);


--
-- Name: recorrido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recorrido_id_seq', 18, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_seq', 1, true);


--
-- Name: zona_turistica_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zona_turistica_id_seq', 32, true);


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

