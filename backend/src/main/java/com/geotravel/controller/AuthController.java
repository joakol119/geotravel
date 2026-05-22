package com.geotravel.controller;

import com.geotravel.model.Usuario;
import com.geotravel.service.AuthService;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.sql.SQLException;
import java.util.Map;

@Path("/auth")
@Produces("application/json;charset=UTF-8")
@Consumes(MediaType.APPLICATION_JSON)
public class AuthController {

    private final AuthService service = new AuthService();

    @POST
    @Path("/login")
    public Response login(Map<String, String> body) {
        try {
            String email = body.get("email");
            String password = body.get("password");

            if (email == null || password == null) {
                return Response.status(400)
                    .entity("{\"error\": \"Email y password requeridos\"}")
                    .build();
            }

            Usuario u = service.login(email, password);
            if (u == null) {
                return Response.status(401)
                    .entity("{\"error\": \"Credenciales incorrectas\"}")
                    .build();
            }

            return Response.ok("{\"token\": \"admin-" + u.getId() + "\", \"email\": \"" + u.getEmail() + "\"}").build();

        } catch (SQLException e) {
            return Response.serverError()
                .entity("{\"error\": \"" + e.getMessage() + "\"}")
                .build();
        }
    }

    @POST
    @Path("/logout")
    public Response logout() {
        return Response.ok("{\"mensaje\": \"Sesión cerrada\"}").build();
    }
}
