package com.geotravel.controller;

import com.geotravel.model.ZonaTuristica;
import com.geotravel.service.ZonaTuristicaService;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.sql.SQLException;

@Path("/zonas")
@Produces("application/json;charset=UTF-8")
@Consumes(MediaType.APPLICATION_JSON)
public class ZonaTuristicaController {

    private final ZonaTuristicaService service = new ZonaTuristicaService();

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
            ZonaTuristica z = service.getById(id);
            if (z == null) return Response.status(404).entity("{\"error\": \"No encontrada\"}").build();
            return Response.ok(z).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @POST
    public Response create(ZonaTuristica zona) {
        try {
            ZonaTuristica created = service.create(zona);
            return Response.status(201).entity(created).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @PUT @Path("/{id}")
    public Response update(@PathParam("id") int id, ZonaTuristica zona) {
        try {
            ZonaTuristica updated = service.update(id, zona);
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

    /** GET /api/zonas/superpone?geojson={...} */
    @GET @Path("/superpone")
    public Response checkSuperposicion(@QueryParam("geojson") String geojson,
                                        @QueryParam("excludeId") Integer excludeId) {
        try {
            boolean superpone = service.seSuperponeCon(geojson, excludeId);
            return Response.ok("{\"superpone\": " + superpone + "}").build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    /** GET /api/zonas/reporte — recorridos agrupados por zona */
    @GET @Path("/reporte")
    public Response getReporte() {
        try {
            String json = service.getReporteRecorridosPorZona();
            return Response.ok(json).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    /** GET /api/zonas/buscar?lng=X&lat=Y — zona que contiene un punto */
    @GET @Path("/buscar")
    public Response getZonaPorPunto(@QueryParam("lng") double lng, @QueryParam("lat") double lat) {
        try {
            ZonaTuristica z = service.getZonaPorPunto(lng, lat);
            if (z == null) return Response.ok("{\"mensaje\": \"No hay zona en esa ubicacion\"}").build();
            return Response.ok(z).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }
}
