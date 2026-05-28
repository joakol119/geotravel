package com.geotravel.service;

import com.geotravel.config.DatabaseConnection;
import com.geotravel.model.Recorrido;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class RecorridoService {

    private static final Map<String, String> NEXT_ESTADO = Map.of(
        "pendiente", "disponible",
        "disponible", "cancelado",
        "cancelado", "pendiente"
    );

    // ============================================================
    // ESTACIONALIDAD AUTOMÁTICA
    // ============================================================

    private void actualizarEstacionalidad() throws SQLException {
        String sqlFuera =
            "UPDATE recorrido SET estado = 'fuera_de_estacion'::estado_recorrido " +
            "WHERE estado NOT IN ('cancelado', 'fuera_de_estacion') " +
            "AND CASE " +
            "  WHEN estacion_inicio <= estacion_fin " +
            "    THEN EXTRACT(MONTH FROM CURRENT_DATE) NOT BETWEEN estacion_inicio AND estacion_fin " +
            "  ELSE " +
            "    EXTRACT(MONTH FROM CURRENT_DATE) < estacion_inicio " +
            "    AND EXTRACT(MONTH FROM CURRENT_DATE) > estacion_fin " +
            "END";

        String sqlActivar =
            "UPDATE recorrido SET estado = 'disponible'::estado_recorrido " +
            "WHERE estado = 'fuera_de_estacion'::estado_recorrido " +
            "AND CASE " +
            "  WHEN estacion_inicio <= estacion_fin " +
            "    THEN EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN estacion_inicio AND estacion_fin " +
            "  ELSE " +
            "    EXTRACT(MONTH FROM CURRENT_DATE) >= estacion_inicio " +
            "    OR EXTRACT(MONTH FROM CURRENT_DATE) <= estacion_fin " +
            "END";

        try (Connection conn = DatabaseConnection.getConnection();
             Statement st = conn.createStatement()) {
            st.executeUpdate(sqlFuera);
            st.executeUpdate(sqlActivar);
        }
    }

    // ============================================================
    // CONSULTAS
    // ============================================================

    public List<Recorrido> getAll(String estado, String tipo, Integer mes) throws SQLException {
    actualizarEstacionalidad();

    StringBuilder sql = new StringBuilder(
        "SELECT id, nombre, descripcion, duracion_estimada, guia_responsable, " +
        "tipo_experiencia, " +
        "CASE " +
        "  WHEN estado IN ('cancelado', 'pendiente') THEN estado::text " +
        "  WHEN ? IS NOT NULL AND CASE WHEN estacion_inicio <= estacion_fin " +
        "    THEN ? BETWEEN estacion_inicio AND estacion_fin " +
        "    ELSE ? >= estacion_inicio OR ? <= estacion_fin END THEN 'disponible' " +
        "  WHEN ? IS NOT NULL THEN 'fuera_de_estacion' " +
        "  ELSE estado::text END AS estado_calculado, " +
        "estado, estacion_inicio, estacion_fin, " +
        "ST_AsGeoJSON(geom) AS geojson FROM recorrido WHERE 1=1"
    );
    List<Object> params = new ArrayList<>();
    Integer mesParam = mes;
    params.add(mesParam); params.add(mesParam); params.add(mesParam); params.add(mesParam); params.add(mesParam);

    if (estado != null && !estado.isEmpty()) {
        sql.append(" AND estado = ?::estado_recorrido");
        params.add(estado);
    }
    if (tipo != null && !tipo.isEmpty()) {
        sql.append(" AND tipo_experiencia = ?::tipo_experiencia");
        params.add(tipo);
    }
    if (mes != null && mes >= 1 && mes <= 12) {
        sql.append(" AND estado NOT IN ('cancelado'::estado_recorrido, 'pendiente'::estado_recorrido)");
    }

    sql.append(" ORDER BY nombre");

    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql.toString())) {
        for (int i = 0; i < params.size(); i++) {
            Object p = params.get(i);
            if (p instanceof Integer) ps.setInt(i + 1, (Integer) p);
            else if (p == null) ps.setNull(i + 1, java.sql.Types.INTEGER);
            else ps.setString(i + 1, (String) p);
        }
        ResultSet rs = ps.executeQuery();
        List<Recorrido> result = new ArrayList<>();
        while (rs.next()) {
            Recorrido r = mapRow(rs);
            if (mes != null) r.setEstado(rs.getString("estado_calculado"));
            result.add(r);
        }
        return result;
    }
}

    public List<Recorrido> getAll(String estado, String tipo) throws SQLException {
        return getAll(estado, tipo, null);
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

    // ============================================================
    // CRUD
    // ============================================================

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
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM recorrido_atraccion WHERE recorrido_id = ?")) {
                    ps.setInt(1, id); ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM historico_estado WHERE recorrido_id = ?")) {
                    ps.setInt(1, id); ps.executeUpdate();
                }
                boolean deleted;
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM recorrido WHERE id = ?")) {
                    ps.setInt(1, id); deleted = ps.executeUpdate() > 0;
                }
                conn.commit();
                return deleted;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        }
    }

    // ============================================================
    // AVANZAR ESTADO (manual)
    // ============================================================

    public Recorrido avanzarEstado(int id) throws SQLException {
    Recorrido r = getById(id);
    if (r == null) return null;

    String nuevoEstado = NEXT_ESTADO.get(r.getEstado());
    if (nuevoEstado == null) return r;

    try (Connection conn = DatabaseConnection.getConnection()) {
        conn.setAutoCommit(false);
        try {
            PreparedStatement ps1 = conn.prepareStatement(
                "UPDATE recorrido SET estado = ?::estado_recorrido WHERE id = ?");
            ps1.setString(1, nuevoEstado);
            ps1.setInt(2, id);
            ps1.executeUpdate();

            PreparedStatement ps2 = conn.prepareStatement(
                "INSERT INTO historico_estado (recorrido_id, estado, fecha) VALUES (?, ?::estado_recorrido, NOW())");
            ps2.setInt(1, id);
            ps2.setString(2, nuevoEstado);
            ps2.executeUpdate();
            conn.commit();
        } catch (SQLException e) {
            conn.rollback();
            throw e;
        }
    }

    return getById(id);
}

    // ============================================================
    // CONSULTAS GEOGRÁFICAS
    // ============================================================

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
                     "ORDER BY geom::geography <-> ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography " +
                     "LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, lng);
            ps.setDouble(2, lat);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        }
    }

    // ============================================================
    // MAPPER
    // ============================================================

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
    public List<Map<String, Object>> getHistorico(int recorridoId) throws SQLException {
        String sql = "SELECT estado, fecha FROM historico_estado WHERE recorrido_id = ? ORDER BY fecha DESC";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recorridoId);
            ResultSet rs = ps.executeQuery();
            List<Map<String, Object>> result = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> row = new java.util.LinkedHashMap<>();
                row.put("estado", rs.getString("estado"));
                row.put("fecha", rs.getTimestamp("fecha").toString());
                result.add(row);
            }
            return result;
        }
    }
    public void deleteHistorico(int recorridoId) throws SQLException {
        String sql = "DELETE FROM historico_estado WHERE recorrido_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, recorridoId);
            ps.executeUpdate();
        }
    }
    public List<Map<String, Object>> getAtraccionesByRecorrido(int recorridoId) throws SQLException {
    String sql = "SELECT a.id, a.nombre, a.clasificacion, a.descripcion, " +
                 "ST_AsGeoJSON(a.geom) AS geojson, ra.orden " +
                 "FROM atraccion_turistica a " +
                 "JOIN recorrido_atraccion ra ON ra.atraccion_id = a.id " +
                 "WHERE ra.recorrido_id = ? ORDER BY ra.orden";
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setInt(1, recorridoId);
        ResultSet rs = ps.executeQuery();
        List<Map<String, Object>> result = new ArrayList<>();
        while (rs.next()) {
            Map<String, Object> m = new java.util.LinkedHashMap<>();
            m.put("id", rs.getInt("id"));
            m.put("nombre", rs.getString("nombre"));
            m.put("clasificacion", rs.getString("clasificacion"));
            m.put("descripcion", rs.getString("descripcion"));
            m.put("geojson", rs.getString("geojson"));
            m.put("orden", rs.getInt("orden"));
            result.add(m);
        }
        return result;
    }
    }
}
