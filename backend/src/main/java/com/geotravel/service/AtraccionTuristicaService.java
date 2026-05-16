package com.geotravel.service;

import com.geotravel.config.DatabaseConnection;
import com.geotravel.model.AtraccionTuristica;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AtraccionTuristicaService {

    public List<AtraccionTuristica> getAll() throws SQLException {
        String sql = "SELECT id, nombre, descripcion, clasificacion, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM atraccion_turistica ORDER BY nombre";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            List<AtraccionTuristica> result = new ArrayList<>();
            while (rs.next()) { result.add(mapRow(rs)); }
            return result;
        }
    }

    public AtraccionTuristica getById(int id) throws SQLException {
        String sql = "SELECT id, nombre, descripcion, clasificacion, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM atraccion_turistica WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        }
    }

    public AtraccionTuristica create(AtraccionTuristica a) throws SQLException {
        String sql = "INSERT INTO atraccion_turistica (nombre, descripcion, clasificacion, geom) " +
                     "VALUES (?, ?, ?, ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)) RETURNING id";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, a.getNombre());
            ps.setString(2, a.getDescripcion());
            ps.setString(3, a.getClasificacion());
            ps.setString(4, a.getGeojson());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) a.setId(rs.getInt(1));
            return a;
        }
    }

    public AtraccionTuristica update(int id, AtraccionTuristica a) throws SQLException {
        String sql = "UPDATE atraccion_turistica SET nombre=?, descripcion=?, clasificacion=?, " +
                     "geom=ST_SetSRID(ST_GeomFromGeoJSON(?), 4326) WHERE id=?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, a.getNombre());
            ps.setString(2, a.getDescripcion());
            ps.setString(3, a.getClasificacion());
            ps.setString(4, a.getGeojson());
            ps.setInt(5, id);
            ps.executeUpdate();
            a.setId(id);
            return a;
        }
    }

    public boolean delete(int id) throws SQLException {
        String sql = "DELETE FROM atraccion_turistica WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    /** Atracciones más populares (en más recorridos) */
    public List<AtraccionTuristica> getMasPopulares(int limit) throws SQLException {
        String sql = "SELECT a.id, a.nombre, a.descripcion, a.clasificacion, " +
                     "ST_AsGeoJSON(a.geom) AS geojson, COUNT(ra.recorrido_id) AS total " +
                     "FROM atraccion_turistica a " +
                     "JOIN recorrido_atraccion ra ON a.id = ra.atraccion_id " +
                     "GROUP BY a.id ORDER BY total DESC LIMIT ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ResultSet rs = ps.executeQuery();
            List<AtraccionTuristica> result = new ArrayList<>();
            while (rs.next()) { result.add(mapRow(rs)); }
            return result;
        }
    }

    private AtraccionTuristica mapRow(ResultSet rs) throws SQLException {
        AtraccionTuristica a = new AtraccionTuristica();
        a.setId(rs.getInt("id"));
        a.setNombre(rs.getString("nombre"));
        a.setDescripcion(rs.getString("descripcion"));
        a.setClasificacion(rs.getString("clasificacion"));
        a.setGeojson(rs.getString("geojson"));
        return a;
    }
}
