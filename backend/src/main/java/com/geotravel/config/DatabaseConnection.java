package com.geotravel.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {

    // En Docker, "db" es el nombre del servicio en docker-compose.
    // Si corrés sin Docker, cambialo a "localhost".
    private static final String HOST = System.getenv("DB_HOST") != null
            ? System.getenv("DB_HOST") : "db";
    private static final String PORT = System.getenv("DB_PORT") != null
            ? System.getenv("DB_PORT") : "5432";
    private static final String DB_NAME = "geotravel";
    private static final String USER = "postgres";
    private static final String PASSWORD = "postgres";

    private static final String URL = "jdbc:postgresql://" + HOST + ":" + PORT + "/" + DB_NAME;

    static {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("PostgreSQL driver not found", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
