package com.geotravel.model;

public class ZonaTuristica {
    private int id;
    private String nombre;
    private String descripcion;
    private int nivelAtractivo;
    private String observaciones;
    private String geojson;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public int getNivelAtractivo() { return nivelAtractivo; }
    public void setNivelAtractivo(int nivelAtractivo) { this.nivelAtractivo = nivelAtractivo; }
    public String getObservaciones() { return observaciones; }
    public void setObservaciones(String observaciones) { this.observaciones = observaciones; }
    public String getGeojson() { return geojson; }
    public void setGeojson(String geojson) { this.geojson = geojson; }
}
