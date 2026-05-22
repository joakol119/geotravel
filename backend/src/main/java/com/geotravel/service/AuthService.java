package com.geotravel.service;

import com.geotravel.config.DatabaseConnection;
import com.geotravel.model.Usuario;
import java.sql.*;

public class AuthService {

    public Usuario login(String email, String password) throws SQLException {
        String sql = "SELECT id, email, password_hash, activo FROM usuario WHERE email = ? AND activo = true";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String storedHash = rs.getString("password_hash");
                if (storedHash.equals(password)) {
                    Usuario u = new Usuario();
                    u.setId(rs.getInt("id"));
                    u.setEmail(rs.getString("email"));
                    u.setActivo(rs.getBoolean("activo"));
                    return u;
                }
            }
            return null;
        }
    }
}
