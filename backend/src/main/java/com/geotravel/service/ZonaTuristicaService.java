package com.geotravel.service;

import com.geotravel.config.DatabaseConnection;
import com.geotravel.model.ZonaTuristica;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ZonaTuristicaService {

    public List<ZonaTuristica> getAll() throws SQLException {
        String sql = "SELECT id, nombre, descripcion, nivel_atractivo, observaciones, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM zona_turistica ORDER BY nivel_atractivo";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            List<ZonaTuristica> result = new ArrayList<>();
            while (rs.next()) { result.add(mapRow(rs)); }
            return result;
        }
    }

    public ZonaTuristica getById(int id) throws SQLException {
        String sql = "SELECT id, nombre, descripcion, nivel_atractivo, observaciones, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM zona_turistica WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        }
    }

    public ZonaTuristica create(ZonaTuristica z) throws SQLException {
        String sql = "INSERT INTO zona_turistica (nombre, descripcion, nivel_atractivo, observaciones, geom) " +
                     "VALUES (?, ?, ?, ?, ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)) RETURNING id";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, z.getNombre());
            ps.setString(2, z.getDescripcion());
            ps.setInt(3, z.getNivelAtractivo());
            ps.setString(4, z.getObservaciones());
            ps.setString(5, z.getGeojson());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) z.setId(rs.getInt(1));
            return z;
        }
    }

    public ZonaTuristica update(int id, ZonaTuristica z) throws SQLException {
        String sql = "UPDATE zona_turistica SET nombre=?, descripcion=?, nivel_atractivo=?, " +
                     "observaciones=?, geom=ST_SetSRID(ST_GeomFromGeoJSON(?), 4326) WHERE id=?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, z.getNombre());
            ps.setString(2, z.getDescripcion());
            ps.setInt(3, z.getNivelAtractivo());
            ps.setString(4, z.getObservaciones());
            ps.setString(5, z.getGeojson());
            ps.setInt(6, id);
            ps.executeUpdate();
            z.setId(id);
            return z;
        }
    }

    public boolean delete(int id) throws SQLException {
        String sql = "DELETE FROM zona_turistica WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Verificar superposición con otras zonas (requerimiento opcional)
     */
    public boolean seSuperponeCon(String geojson, Integer excludeId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM zona_turistica " +
                     "WHERE ST_Overlaps(geom, ST_SetSRID(ST_GeomFromGeoJSON(?), 4326))";
        if (excludeId != null) sql += " AND id != " + excludeId;
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, geojson);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt(1) > 0;
        }
    }

    /**
     * Reporte: zonas con cantidad de recorridos activos (ST_Intersects)
     * Devuelve JSON string directamente para simplicidad
     */
    public String getReporteRecorridosPorZona() throws SQLException {
        String sql = "SELECT z.id, z.nombre, z.nivel_atractivo, " +
                     "COUNT(CASE WHEN r.estado = 'disponible' THEN 1 END) AS disponibles, " +
                     "COUNT(CASE WHEN r.estado = 'pendiente' THEN 1 END) AS pendientes, " +
                     "COUNT(CASE WHEN r.estado = 'fuera_de_estacion' THEN 1 END) AS fuera_estacion, " +
                     "COUNT(CASE WHEN r.estado = 'cancelado' THEN 1 END) AS cancelados, " +
                     "COUNT(r.id) AS total " +
                     "FROM zona_turistica z " +
                     "LEFT JOIN recorrido r ON ST_Intersects(r.geom, z.geom) " +
                     "GROUP BY z.id, z.nombre, z.nivel_atractivo " +
                     "ORDER BY total DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                json.append("{\"id\":").append(rs.getInt("id"))
                    .append(",\"nombre\":\"").append(rs.getString("nombre")).append("\"")
                    .append(",\"nivelAtractivo\":").append(rs.getInt("nivel_atractivo"))
                    .append(",\"disponibles\":").append(rs.getInt("disponibles"))
                    .append(",\"pendientes\":").append(rs.getInt("pendientes"))
                    .append(",\"fueraEstacion\":").append(rs.getInt("fuera_estacion"))
                    .append(",\"cancelados\":").append(rs.getInt("cancelados"))
                    .append(",\"total\":").append(rs.getInt("total"))
                    .append("}");
                first = false;
            }
            json.append("]");
            return json.toString();
        }
    }

    /** Zona que contiene un punto dado (búsqueda por dirección) */
    public ZonaTuristica getZonaPorPunto(double lng, double lat) throws SQLException {
        String sql = "SELECT id, nombre, descripcion, nivel_atractivo, observaciones, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM zona_turistica " +
                     "WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(?, ?), 4326)) LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, lng);
            ps.setDouble(2, lat);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        }
    }

    private ZonaTuristica mapRow(ResultSet rs) throws SQLException {
        ZonaTuristica z = new ZonaTuristica();
        z.setId(rs.getInt("id"));
        z.setNombre(rs.getString("nombre"));
        z.setDescripcion(rs.getString("descripcion"));
        z.setNivelAtractivo(rs.getInt("nivel_atractivo"));
        z.setObservaciones(rs.getString("observaciones"));
        z.setGeojson(rs.getString("geojson"));
        return z;
    }
}
