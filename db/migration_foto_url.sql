-- Migración: cambiar columna foto BYTEA a foto_url TEXT
-- Ejecutar una sola vez en la base de datos geotravel

ALTER TABLE atraccion_turistica DROP COLUMN IF EXISTS foto;
ALTER TABLE atraccion_turistica ADD COLUMN IF NOT EXISTS foto_url TEXT;
