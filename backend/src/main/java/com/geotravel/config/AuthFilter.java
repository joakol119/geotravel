package com.geotravel.config;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;

@Provider
public class AuthFilter implements ContainerRequestFilter {

    @Override
    public void filter(ContainerRequestContext ctx) throws IOException {
        String method = ctx.getMethod();
        String path = ctx.getUriInfo().getPath();

        // Permitir OPTIONS (preflight CORS)
        if (method.equals("OPTIONS")) return;

        // Permitir GET sin token (invitado puede ver datos)
        if (method.equals("GET")) return;

        // Permitir login sin token
        if (path.startsWith("auth/")) return;

        // Para POST, PUT, DELETE verificar token
        String auth = ctx.getHeaderString("Authorization");
        if (auth == null || !auth.startsWith("Bearer admin-")) {
            ctx.abortWith(Response.status(401)
                .entity("{\"error\": \"No autorizado\"}")
                .type("application/json;charset=UTF-8")
                .build());
        }
    }
}
