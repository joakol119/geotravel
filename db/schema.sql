-- ============================================================
-- GeoTravel - Schema para PostgreSQL + PostGIS
-- TSIG 2026 - 1er Semestre
-- ============================================================

-- 1. Crear la base de datos (ejecutar como superusuario)
-- CREATE DATABASE geotravel;
-- \c geotravel
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- TIPOS ENUMERADOS
-- ============================================================

CREATE TYPE estado_recorrido AS ENUM (
    'disponible',
    'fuera_de_estacion',
    'pendiente',
    'cancelado'
);

CREATE TYPE tipo_experiencia AS ENUM (
    'cultural',
    'gastronomica',
    'natural',
    'historica'
);

-- ============================================================
-- TABLAS
-- ============================================================

-- Zonas turísticas (polígonos)
CREATE TABLE zona_turistica (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    descripcion     TEXT,
    nivel_atractivo INTEGER NOT NULL CHECK (nivel_atractivo BETWEEN 1 AND 5),
    observaciones   TEXT,
    geom            GEOMETRY(POLYGON, 4326) NOT NULL
);

-- Recorridos turísticos (líneas)
CREATE TABLE recorrido (
    id                 SERIAL PRIMARY KEY,
    nombre             VARCHAR(200) NOT NULL,
    descripcion        TEXT,
    duracion_estimada  VARCHAR(100),       -- ej: "3 horas", "medio día"
    guia_responsable   VARCHAR(200),
    tipo_experiencia   tipo_experiencia NOT NULL,
    estado             estado_recorrido NOT NULL DEFAULT 'pendiente',
    estacion_inicio    INTEGER NOT NULL CHECK (estacion_inicio BETWEEN 1 AND 12),
    estacion_fin       INTEGER NOT NULL CHECK (estacion_fin BETWEEN 1 AND 12),
    geom               GEOMETRY(LINESTRING, 4326) NOT NULL
);

-- Atracciones turísticas (puntos)
CREATE TABLE atraccion_turistica (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(200) NOT NULL,
    descripcion     TEXT,
    clasificacion   VARCHAR(100),           -- ej: "museo", "parque", "monumento"
    foto            BYTEA,                  -- imagen opcional
    geom            GEOMETRY(POINT, 4326) NOT NULL
);

-- Relación recorrido <-> atracción (con orden de visita)
CREATE TABLE recorrido_atraccion (
    id              SERIAL PRIMARY KEY,
    recorrido_id    INTEGER NOT NULL REFERENCES recorrido(id) ON DELETE CASCADE,
    atraccion_id    INTEGER NOT NULL REFERENCES atraccion_turistica(id) ON DELETE CASCADE,
    orden           INTEGER NOT NULL CHECK (orden > 0),
    UNIQUE (recorrido_id, atraccion_id),
    UNIQUE (recorrido_id, orden)
);

-- Histórico de estados de recorridos
CREATE TABLE historico_estado (
    id              SERIAL PRIMARY KEY,
    recorrido_id    INTEGER NOT NULL REFERENCES recorrido(id) ON DELETE CASCADE,
    estado          estado_recorrido NOT NULL,
    fecha           TIMESTAMP NOT NULL DEFAULT NOW(),
    observacion     TEXT
);

-- ============================================================
-- ÍNDICES ESPACIALES (GiST) - Fundamentales para rendimiento
-- ============================================================

CREATE INDEX idx_zona_geom       ON zona_turistica    USING GIST (geom);
CREATE INDEX idx_recorrido_geom  ON recorrido         USING GIST (geom);
CREATE INDEX idx_atraccion_geom  ON atraccion_turistica USING GIST (geom);

-- Índices adicionales para consultas frecuentes
CREATE INDEX idx_recorrido_estado     ON recorrido (estado);
CREATE INDEX idx_recorrido_tipo       ON recorrido (tipo_experiencia);
CREATE INDEX idx_historico_recorrido  ON historico_estado (recorrido_id);
CREATE INDEX idx_recorrido_atraccion_rec ON recorrido_atraccion (recorrido_id);
CREATE INDEX idx_recorrido_atraccion_atr ON recorrido_atraccion (atraccion_id);

-- ============================================================
-- DATOS DE EJEMPLO - Zonas turísticas en Montevideo
-- ============================================================

INSERT INTO zona_turistica (nombre, descripcion, nivel_atractivo, observaciones, geom) VALUES
(
    'Ciudad Vieja',
    'Centro histórico de Montevideo con arquitectura colonial, museos y vida nocturna.',
    1,
    'Zona con mayor concentración de atractivos culturales.',
    ST_GeomFromText('POLYGON((-56.2120 -34.9060, -56.2120 -34.9110, -56.2020 -34.9110, -56.2020 -34.9060, -56.2120 -34.9060))', 4326)
),
(
    'Rambla de Pocitos',
    'Paseo costero con playas, parques y gastronomía.',
    2,
    'Ideal para recorridos al aire libre.',
    ST_GeomFromText('POLYGON((-56.1650 -34.9150, -56.1650 -34.9220, -56.1500 -34.9220, -56.1500 -34.9150, -56.1650 -34.9150))', 4326)
),
(
    'Mercado del Puerto',
    'Zona gastronómica icónica de Montevideo.',
    1,
    'Mercado histórico con parrillas y productos artesanales.',
    ST_GeomFromText('POLYGON((-56.2115 -34.9075, -56.2115 -34.9090, -56.2095 -34.9090, -56.2095 -34.9075, -56.2115 -34.9075))', 4326)
),
(
    'Parque Rodó',
    'Parque urbano con lago, feria de artesanos y espacios culturales.',
    2,
    'Conecta con la rambla y la zona de teatros.',
    ST_GeomFromText('POLYGON((-56.1720 -34.9130, -56.1720 -34.9190, -56.1640 -34.9190, -56.1640 -34.9130, -56.1720 -34.9130))', 4326)
);

-- ============================================================
-- DATOS DE EJEMPLO - Atracciones turísticas
-- ============================================================

INSERT INTO atraccion_turistica (nombre, descripcion, clasificacion, geom) VALUES
(
    'Teatro Solís',
    'Principal teatro de Uruguay, inaugurado en 1856.',
    'teatro',
    ST_GeomFromText('POINT(-56.2045 -34.9075)', 4326)
),
(
    'Plaza Independencia',
    'Principal plaza de Montevideo con el Mausoleo de Artigas.',
    'plaza',
    ST_GeomFromText('POINT(-56.2005 -34.9065)', 4326)
),
(
    'Puerta de la Ciudadela',
    'Restos de la antigua muralla de Montevideo.',
    'monumento',
    ST_GeomFromText('POINT(-56.2020 -34.9068)', 4326)
),
(
    'Mercado del Puerto',
    'Mercado gastronómico tradicional desde 1868.',
    'gastronomia',
    ST_GeomFromText('POINT(-56.2105 -34.9083)', 4326)
),
(
    'Museo Torres García',
    'Museo dedicado al artista uruguayo Joaquín Torres García.',
    'museo',
    ST_GeomFromText('POINT(-56.2000 -34.9060)', 4326)
),
(
    'Playa Pocitos',
    'Playa urbana más popular de Montevideo.',
    'playa',
    ST_GeomFromText('POINT(-56.1580 -34.9180)', 4326)
),
(
    'Faro de Punta Carretas',
    'Faro histórico con vistas panorámicas.',
    'monumento',
    ST_GeomFromText('POINT(-56.1620 -34.9210)', 4326)
),
(
    'Museo Nacional de Artes Visuales',
    'Principal museo de artes plásticas del Uruguay.',
    'museo',
    ST_GeomFromText('POINT(-56.1680 -34.9155)', 4326)
);

-- ============================================================
-- DATOS DE EJEMPLO - Recorridos turísticos
-- ============================================================

INSERT INTO recorrido (nombre, descripcion, duracion_estimada, guia_responsable, tipo_experiencia, estado, estacion_inicio, estacion_fin, geom) VALUES
(
    'Recorrido Histórico Ciudad Vieja',
    'Paseo por los principales puntos históricos del casco antiguo.',
    '3 horas',
    'María González',
    'historica',
    'disponible',
    3, 12,
    ST_GeomFromText('LINESTRING(-56.2045 -34.9075, -56.2020 -34.9068, -56.2005 -34.9065, -56.2000 -34.9060)', 4326)
),
(
    'Ruta Gastronómica del Puerto',
    'Degustación y visita a los mejores puestos del Mercado del Puerto.',
    '2 horas',
    'Carlos Rodríguez',
    'gastronomica',
    'disponible',
    1, 12,
    ST_GeomFromText('LINESTRING(-56.2020 -34.9068, -56.2045 -34.9075, -56.2105 -34.9083)', 4326)
),
(
    'Paseo Costero Pocitos',
    'Caminata por la rambla desde Parque Rodó hasta Playa Pocitos.',
    '2.5 horas',
    'Ana Martínez',
    'natural',
    'disponible',
    11, 3,
    ST_GeomFromText('LINESTRING(-56.1680 -34.9155, -56.1620 -34.9210, -56.1580 -34.9180)', 4326)
),
(
    'Tour Cultural Completo',
    'Visita a los principales museos y teatros de Montevideo.',
    '5 horas',
    'Pedro López',
    'cultural',
    'pendiente',
    4, 11,
    ST_GeomFromText('LINESTRING(-56.2045 -34.9075, -56.2000 -34.9060, -56.1680 -34.9155)', 4326)
);

-- ============================================================
-- DATOS DE EJEMPLO - Asociaciones recorrido <-> atracción
-- ============================================================

-- Recorrido Histórico: Teatro Solís -> Puerta Ciudadela -> Plaza Independencia -> Museo Torres García
INSERT INTO recorrido_atraccion (recorrido_id, atraccion_id, orden) VALUES
(1, 1, 1),  -- Teatro Solís
(1, 3, 2),  -- Puerta de la Ciudadela
(1, 2, 3),  -- Plaza Independencia
(1, 5, 4);  -- Museo Torres García

-- Ruta Gastronómica: Puerta Ciudadela -> Teatro Solís -> Mercado del Puerto
INSERT INTO recorrido_atraccion (recorrido_id, atraccion_id, orden) VALUES
(2, 3, 1),  -- Puerta de la Ciudadela
(2, 1, 2),  -- Teatro Solís
(2, 4, 3);  -- Mercado del Puerto

-- Paseo Costero: MNAV -> Faro Punta Carretas -> Playa Pocitos
INSERT INTO recorrido_atraccion (recorrido_id, atraccion_id, orden) VALUES
(3, 8, 1),  -- Museo Nacional de Artes Visuales
(3, 7, 2),  -- Faro de Punta Carretas
(3, 6, 3);  -- Playa Pocitos

-- Tour Cultural: Teatro Solís -> Museo Torres García -> MNAV
INSERT INTO recorrido_atraccion (recorrido_id, atraccion_id, orden) VALUES
(4, 1, 1),  -- Teatro Solís
(4, 5, 2),  -- Museo Torres García
(4, 8, 3);  -- MNAV

-- ============================================================
-- DATOS DE EJEMPLO - Histórico de estados
-- ============================================================

INSERT INTO historico_estado (recorrido_id, estado, fecha, observacion) VALUES
(1, 'pendiente',   '2026-01-15 10:00:00', 'Recorrido creado'),
(1, 'disponible',  '2026-02-01 09:00:00', 'Aprobado para temporada'),
(2, 'pendiente',   '2026-01-20 11:00:00', 'Recorrido creado'),
(2, 'disponible',  '2026-02-01 09:30:00', 'Aprobado - disponible todo el año'),
(3, 'pendiente',   '2026-02-10 14:00:00', 'Recorrido creado'),
(3, 'disponible',  '2026-03-01 08:00:00', 'Disponible para temporada de verano'),
(4, 'pendiente',   '2026-03-01 10:00:00', 'Recorrido en planificación');

-- ============================================================
-- CONSULTAS GEOGRÁFICAS DE EJEMPLO
-- (Estas son las que vas a necesitar en el backend)
-- ============================================================

-- 1. Recorridos dentro de una zona seleccionada
-- SELECT r.* FROM recorrido r, zona_turistica z
-- WHERE z.id = 1 AND ST_Intersects(r.geom, z.geom);

-- 2. Zonas con más recorridos activos (disponibles)
-- SELECT z.nombre, COUNT(r.id) AS total_recorridos
-- FROM zona_turistica z
-- JOIN recorrido r ON ST_Intersects(r.geom, z.geom)
-- WHERE r.estado = 'disponible'
-- GROUP BY z.id, z.nombre
-- ORDER BY total_recorridos DESC;

-- 3. Recorrido más cercano a una intersección de calles (dado un punto)
-- SELECT r.nombre, ST_Distance(r.geom::geography, ST_SetSRID(ST_MakePoint(-56.1900, -34.9100), 4326)::geography) AS distancia_metros
-- FROM recorrido r
-- WHERE r.estado = 'disponible'
-- ORDER BY distancia_metros
-- LIMIT 1;

-- 4. Zona correspondiente a una dirección (dado un punto)
-- SELECT z.* FROM zona_turistica z
-- WHERE ST_Contains(z.geom, ST_SetSRID(ST_MakePoint(-56.2050, -34.9080), 4326));

-- 5. Puntos de interés dentro de una zona
-- SELECT a.* FROM atraccion_turistica a, zona_turistica z
-- WHERE z.id = 1 AND ST_Contains(z.geom, a.geom);

-- 6. Puntos más populares (incluidos en más recorridos)
-- SELECT a.nombre, COUNT(ra.recorrido_id) AS total_recorridos
-- FROM atraccion_turistica a
-- JOIN recorrido_atraccion ra ON a.id = ra.atraccion_id
-- GROUP BY a.id, a.nombre
-- ORDER BY total_recorridos DESC;

-- 7. Verificar que no se superponen las zonas (para validación)
-- SELECT z1.nombre, z2.nombre
-- FROM zona_turistica z1, zona_turistica z2
-- WHERE z1.id < z2.id AND ST_Overlaps(z1.geom, z2.geom);

CREATE TABLE IF NOT EXISTS usuario (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO usuario (email, password_hash) 
VALUES ('admin@geotravel.com', 'admin123')
ON CONFLICT (email) DO NOTHING;