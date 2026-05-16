package com.geotravel.model;

public class Recorrido {

    private int id;
    private String nombre;
    private String descripcion;
    private String duracionEstimada;
    private String guiaResponsable;
    private String tipoExperiencia;
    private String estado;
    private int estacionInicio;
    private int estacionFin;
    private String geojson;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public String getDuracionEstimada() { return duracionEstimada; }
    public void setDuracionEstimada(String duracionEstimada) { this.duracionEstimada = duracionEstimada; }
    public String getGuiaResponsable() { return guiaResponsable; }
    public void setGuiaResponsable(String guiaResponsable) { this.guiaResponsable = guiaResponsable; }
    public String getTipoExperiencia() { return tipoExperiencia; }
    public void setTipoExperiencia(String tipoExperiencia) { this.tipoExperiencia = tipoExperiencia; }
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    public int getEstacionInicio() { return estacionInicio; }
    public void setEstacionInicio(int estacionInicio) { this.estacionInicio = estacionInicio; }
    public int getEstacionFin() { return estacionFin; }
    public void setEstacionFin(int estacionFin) { this.estacionFin = estacionFin; }
    public String getGeojson() { return geojson; }
    public void setGeojson(String geojson) { this.geojson = geojson; }
}
