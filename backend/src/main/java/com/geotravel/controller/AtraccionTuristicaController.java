package com.geotravel.controller;

import com.geotravel.model.AtraccionTuristica;
import com.geotravel.service.AtraccionTuristicaService;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.io.File;
import java.io.FileOutputStream;
import java.sql.SQLException;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

@Path("/atracciones")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AtraccionTuristicaController {

    private final AtraccionTuristicaService service = new AtraccionTuristicaService();

    // Directorio donde se guardan las imágenes subidas
    private static final String UPLOAD_DIR = "/opt/uploads";

    @GET
    public Response getAll() {
        try {
            return Response.ok(service.getAll()).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @GET @Path("/{id}")
    public Response getById(@PathParam("id") int id) {
        try {
            AtraccionTuristica a = service.getById(id);
            if (a == null) return Response.status(404).entity("{\"error\": \"No encontrada\"}").build();
            return Response.ok(a).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @POST
    public Response create(AtraccionTuristica atraccion) {
        try {
            AtraccionTuristica created = service.create(atraccion);
            return Response.status(201).entity(created).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @PUT @Path("/{id}")
    public Response update(@PathParam("id") int id, AtraccionTuristica atraccion) {
        try {
            AtraccionTuristica updated = service.update(id, atraccion);
            return Response.ok(updated).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @DELETE @Path("/{id}")
    public Response delete(@PathParam("id") int id) {
        try {
            if (service.delete(id)) return Response.noContent().build();
            return Response.status(404).entity("{\"error\": \"No encontrada\"}").build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @GET @Path("/populares")
    public Response getMasPopulares(@QueryParam("limit") @DefaultValue("10") int limit) {
        try {
            return Response.ok(service.getMasPopulares(limit)).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    /**
     * POST /api/atracciones/upload
     * Recibe una imagen en base64 y la guarda en disco.
     * Body: { "base64": "data:image/jpeg;base64,/9j/4AAQ...", "filename": "teatro.jpg" }
     * Retorna: { "url": "/uploads/abc123.jpg" }
     */
    @POST @Path("/upload")
    public Response uploadImage(Map<String, String> body) {
        try {
            String base64Data = body.get("base64");
            if (base64Data == null || base64Data.isEmpty()) {
                return Response.status(400).entity("{\"error\": \"No se envió imagen\"}").build();
            }

            // Separar el header "data:image/jpeg;base64," del contenido
            String imageData = base64Data;
            String extension = "jpg";
            if (base64Data.contains(",")) {
                String header = base64Data.substring(0, base64Data.indexOf(","));
                imageData = base64Data.substring(base64Data.indexOf(",") + 1);
                if (header.contains("png")) extension = "png";
                else if (header.contains("webp")) extension = "webp";
                else if (header.contains("gif")) extension = "gif";
            }

            // Generar nombre único
            String filename = UUID.randomUUID().toString().substring(0, 8) + "." + extension;

            // Crear directorio si no existe
            File dir = new File(UPLOAD_DIR);
            if (!dir.exists()) dir.mkdirs();

            // Decodificar y guardar
            byte[] bytes = Base64.getDecoder().decode(imageData);
            File file = new File(dir, filename);
            try (FileOutputStream fos = new FileOutputStream(file)) {
                fos.write(bytes);
            }

            // Retornar la URL relativa
            String url = "/uploads/" + filename;
            return Response.ok("{\"url\": \"" + url + "\"}").build();

        } catch (Exception e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }
}
