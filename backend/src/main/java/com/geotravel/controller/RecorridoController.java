package com.geotravel.controller;

import com.geotravel.model.Recorrido;
import com.geotravel.service.RecorridoService;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.sql.SQLException;
import java.util.List;

@Path("/recorridos")
@Produces("application/json;charset=UTF-8")
@Consumes(MediaType.APPLICATION_JSON)
public class RecorridoController {

    private final RecorridoService service = new RecorridoService();

    @GET
    public Response getAll(@QueryParam("estado") String estado,
                           @QueryParam("tipo") String tipo,
                           @QueryParam("mes") Integer mes) {
        try {
            List<Recorrido> recorridos = service.getAll(estado, tipo, mes);
            return Response.ok(recorridos).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @GET @Path("/{id}")
    public Response getById(@PathParam("id") int id) {
        try {
            Recorrido r = service.getById(id);
            if (r == null) return Response.status(404).entity("{\"error\": \"No encontrado\"}").build();
            return Response.ok(r).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @POST
    public Response create(Recorrido recorrido) {
        try {
            Recorrido created = service.create(recorrido);
            return Response.status(201).entity(created).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @PUT @Path("/{id}")
    public Response update(@PathParam("id") int id, Recorrido recorrido) {
        try {
            Recorrido updated = service.update(id, recorrido);
            return Response.ok(updated).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @DELETE @Path("/{id}")
    public Response delete(@PathParam("id") int id) {
        try {
            if (service.delete(id)) return Response.noContent().build();
            return Response.status(404).entity("{\"error\": \"No encontrado\"}").build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    /** PUT /api/recorridos/{id}/avanzar — avanza al siguiente estado */
    @PUT @Path("/{id}/avanzar")
    public Response avanzarEstado(@PathParam("id") int id) {
        try {
            Recorrido r = service.avanzarEstado(id);
            if (r == null) return Response.status(404).entity("{\"error\": \"No encontrado\"}").build();
            return Response.ok(r).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @GET @Path("/zona/{zonaId}")
    public Response getByZona(@PathParam("zonaId") int zonaId) {
        try {
            return Response.ok(service.getByZona(zonaId)).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }

    @GET @Path("/cercano")
    public Response getMasCercano(@QueryParam("lng") double lng, @QueryParam("lat") double lat) {
        try {
            Recorrido r = service.getMasCercano(lng, lat);
            if (r == null) return Response.status(404).entity("{\"error\": \"Sin resultados\"}").build();
            return Response.ok(r).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }
    @GET @Path("/{id}/historico")
    public Response getHistorico(@PathParam("id") int id) {
        try {
            return Response.ok(service.getHistorico(id)).build();
        } catch (SQLException e) {
            return Response.serverError().entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }
}
