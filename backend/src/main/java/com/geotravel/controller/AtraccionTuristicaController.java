package com.geotravel.controller;

import com.geotravel.model.AtraccionTuristica;
import com.geotravel.service.AtraccionTuristicaService;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.sql.SQLException;

@Path("/atracciones")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AtraccionTuristicaController {

    private final AtraccionTuristicaService service = new AtraccionTuristicaService();

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
}
