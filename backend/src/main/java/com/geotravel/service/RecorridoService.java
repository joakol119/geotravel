package com.geotravel.service;

import com.geotravel.config.DatabaseConnection;
import com.geotravel.model.Recorrido;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RecorridoService {

    public List<Recorrido> getAll(String estado, String tipo, Integer mes) throws SQLException {
        StringBuilder sql = new StringBuilder(
            "SELECT id, nombre, descripcion, duracion_estimada, guia_responsable, " +
            "tipo_experiencia, estado, estacion_inicio, estacion_fin, " +
            "ST_AsGeoJSON(geom) AS geojson FROM recorrido WHERE 1=1"
        );
        List<Object> params = new ArrayList<>();
        if (estado != null && !estado.isEmpty()) {
            sql.append(" AND estado = ?::estado_recorrido");
            params.add(estado);
        }
        if (tipo != null && !tipo.isEmpty()) {
            sql.append(" AND tipo_experiencia = ?::tipo_experiencia");
            params.add(tipo);
        }
        if (mes != null && mes >= 1 && mes <= 12) {
            // Maneja estaciones que cruzan fin de año (ej: nov a marzo = 11 a 3)
            sql.append(" AND (CASE WHEN estacion_inicio <= estacion_fin " +
                       "THEN ? BETWEEN estacion_inicio AND estacion_fin " +
                       "ELSE ? >= estacion_inicio OR ? <= estacion_fin END)");
        }
        sql.append(" ORDER BY nombre");
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            for (Object p : params) {
                ps.setString(idx++, (String) p);
            }
            if (mes != null && mes >= 1 && mes <= 12) {
                ps.setInt(idx++, mes);
                ps.setInt(idx++, mes);
                ps.setInt(idx++, mes);
            }
            ResultSet rs = ps.executeQuery();
            List<Recorrido> result = new ArrayList<>();
            while (rs.next()) { result.add(mapRow(rs)); }
            return result;
        }
    }

    public Recorrido getById(int id) throws SQLException {
        String sql = "SELECT id, nombre, descripcion, duracion_estimada, guia_responsable, " +
                     "tipo_experiencia, estado, estacion_inicio, estacion_fin, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM recorrido WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        }
    }

    public Recorrido create(Recorrido r) throws SQLException {
        String sql = "INSERT INTO recorrido (nombre, descripcion, duracion_estimada, " +
                     "guia_responsable, tipo_experiencia, estado, estacion_inicio, estacion_fin, geom) " +
                     "VALUES (?, ?, ?, ?, ?::tipo_experiencia, ?::estado_recorrido, ?, ?, " +
                     "ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)) RETURNING id";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, r.getNombre());
            ps.setString(2, r.getDescripcion());
            ps.setString(3, r.getDuracionEstimada());
            ps.setString(4, r.getGuiaResponsable());
            ps.setString(5, r.getTipoExperiencia());
            ps.setString(6, r.getEstado());
            ps.setInt(7, r.getEstacionInicio());
            ps.setInt(8, r.getEstacionFin());
            ps.setString(9, r.getGeojson());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) { r.setId(rs.getInt(1)); }
            return r;
        }
    }

    public List<Recorrido> getByZona(int zonaId) throws SQLException {
        String sql = "SELECT r.id, r.nombre, r.descripcion, r.duracion_estimada, " +
                     "r.guia_responsable, r.tipo_experiencia, r.estado, " +
                     "r.estacion_inicio, r.estacion_fin, ST_AsGeoJSON(r.geom) AS geojson " +
                     "FROM recorrido r, zona_turistica z " +
                     "WHERE z.id = ? AND ST_Intersects(r.geom, z.geom)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, zonaId);
            ResultSet rs = ps.executeQuery();
            List<Recorrido> result = new ArrayList<>();
            while (rs.next()) { result.add(mapRow(rs)); }
            return result;
        }
    }

    public Recorrido getMasCercano(double lng, double lat) throws SQLException {
        String sql = "SELECT id, nombre, descripcion, duracion_estimada, guia_responsable, " +
                     "tipo_experiencia, estado, estacion_inicio, estacion_fin, " +
                     "ST_AsGeoJSON(geom) AS geojson FROM recorrido " +
                     "WHERE estado = 'disponible' " +
                     "ORDER BY geom::geography <-> ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, lng);
            ps.setDouble(2, lat);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        }
    }

    public Recorrido update(int id, Recorrido r) throws SQLException {
        String sql = "UPDATE recorrido SET nombre=?, descripcion=?, duracion_estimada=?, " +
                     "guia_responsable=?, tipo_experiencia=?::tipo_experiencia, " +
                     "estacion_inicio=?, estacion_fin=?, " +
                     "geom=ST_SetSRID(ST_GeomFromGeoJSON(?), 4326) WHERE id=?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, r.getNombre());
            ps.setString(2, r.getDescripcion());
            ps.setString(3, r.getDuracionEstimada());
            ps.setString(4, r.getGuiaResponsable());
            ps.setString(5, r.getTipoExperiencia());
            ps.setInt(6, r.getEstacionInicio());
            ps.setInt(7, r.getEstacionFin());
            ps.setString(8, r.getGeojson());
            ps.setInt(9, id);
            ps.executeUpdate();
            r.setId(id);
            return r;
        }
    }

    public boolean delete(int id) throws SQLException {
        String sql = "DELETE FROM recorrido WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Avanzar estado respetando la secuencia:
     * pendiente -> disponible -> fuera_de_estacion -> cancelado
     */
    public Recorrido avanzarEstado(int id) throws SQLException {
        Recorrido r = getById(id);
        if (r == null) return null;

        String nuevoEstado;
        switch (r.getEstado()) {
            case "pendiente": nuevoEstado = "disponible"; break;
            case "disponible": nuevoEstado = "fuera_de_estacion"; break;
            case "fuera_de_estacion": nuevoEstado = "cancelado"; break;
            default: throw new SQLException("No se puede avanzar desde el estado: " + r.getEstado());
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Actualizar estado
            PreparedStatement ps1 = conn.prepareStatement(
                "UPDATE recorrido SET estado = ?::estado_recorrido WHERE id = ?");
            ps1.setString(1, nuevoEstado);
            ps1.setInt(2, id);
            ps1.executeUpdate();

            // Registrar en histórico
            PreparedStatement ps2 = conn.prepareStatement(
                "INSERT INTO historico_estado (recorrido_id, estado, fecha) VALUES (?, ?::estado_recorrido, NOW())");
            ps2.setInt(1, id);
            ps2.setString(2, nuevoEstado);
            ps2.executeUpdate();
        }

        return getById(id);
    }

    private Recorrido mapRow(ResultSet rs) throws SQLException {
        Recorrido r = new Recorrido();
        r.setId(rs.getInt("id"));
        r.setNombre(rs.getString("nombre"));
        r.setDescripcion(rs.getString("descripcion"));
        r.setDuracionEstimada(rs.getString("duracion_estimada"));
        r.setGuiaResponsable(rs.getString("guia_responsable"));
        r.setTipoExperiencia(rs.getString("tipo_experiencia"));
        r.setEstado(rs.getString("estado"));
        r.setEstacionInicio(rs.getInt("estacion_inicio"));
        r.setEstacionFin(rs.getInt("estacion_fin"));
        r.setGeojson(rs.getString("geojson"));
        return r;
    }
}
