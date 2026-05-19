import React, { useState, useEffect, useCallback, useRef } from 'react';
import { MapContainer, TileLayer, WMSTileLayer, Polygon, Polyline, Marker, Tooltip, useMap, FeatureGroup } from 'react-leaflet';import { EditControl } from 'react-leaflet-draw';
import L from 'leaflet';
import ImagePicker from './components/ImagePicker';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';
import * as api from './data/api';
import 'leaflet.heat';

const ESTADO_COLORS = { disponible: '#1D9E75', fuera_de_estacion: '#BA7517', pendiente: '#378ADD', cancelado: '#E24B4A' };
const TIPO_ICONS = { cultural: '🏛️', gastronomica: '🍷', natural: '🌿', historica: '📜' };
const CLASIF_ICONS = { teatro: '🎭', plaza: '⛲', monumento: '🏛️', gastronomia: '🍖', museo: '🖼️', playa: '🏖️', parque: '🌳' };
const NEXT_ESTADO = { pendiente: 'disponible', disponible: 'fuera_de_estacion', fuera_de_estacion: 'cancelado' };

function FlyTo({ coords }) {
  const map = useMap();
  useEffect(() => {
    if (coords) {
      const target = Array.isArray(coords[0]) ? coords[Math.floor(coords.length / 2)] : coords;
      map.flyTo(target, 16, { duration: 0.8 });
    }
  }, [coords, map]);
  return null;
}

function createIcon(emoji) {
  return L.divIcon({
    html: '<div style="font-size:22px;text-align:center;filter:drop-shadow(0 1px 2px rgba(0,0,0,0.3))">' + emoji + '</div>',
    className: '', iconSize: [30, 30], iconAnchor: [15, 15],
  });
}

function FormModal({ title, fields, values, onChange, onSave, onCancel }) {
  return (
    <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,0.4)', zIndex:2000, display:'flex', alignItems:'center', justifyContent:'center' }}>
      <div style={{ background:'white', borderRadius:12, padding:24, width:380, maxHeight:'80vh', overflowY:'auto' }}>
        <h3 style={{ margin:'0 0 16px', fontSize:16 }}>{title}</h3>
        {fields.map(f => (
          <div key={f.key} style={{ marginBottom:12 }}>
            <label style={{ display:'block', fontSize:12, fontWeight:600, marginBottom:4, color:'#5f5e5a' }}>{f.label}</label>
            {f.type === 'select' ? (
              <select className="filter-select" style={{ width:'100%' }} value={values[f.key]||''} onChange={e => onChange(f.key, e.target.value)}>
                {f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
              ) : f.type === 'image' ? (
  <ImagePicker value={values[f.key] || ''} onChange={(url) => onChange(f.key, url)} />
            ) : f.type === 'textarea' ? (
              <textarea style={{ width:'100%', padding:8, border:'1px solid #d3d1c7', borderRadius:6, fontSize:13, resize:'vertical', minHeight:60, boxSizing:'border-box' }}
                value={values[f.key]||''} onChange={e => onChange(f.key, e.target.value)} />
            ) : (
              <input type={f.type||'text'} style={{ width:'100%', padding:8, border:'1px solid #d3d1c7', borderRadius:6, fontSize:13, boxSizing:'border-box' }}
                value={values[f.key]||''} onChange={e => onChange(f.key, e.target.value)} />
            )}
          </div>
        ))}
        <div style={{ display:'flex', gap:8, justifyContent:'flex-end', marginTop:16 }}>
          <button onClick={onCancel} style={{ padding:'8px 16px', border:'1px solid #d3d1c7', borderRadius:8, background:'white', cursor:'pointer' }}>Cancelar</button>
          <button onClick={onSave} style={{ padding:'8px 16px', border:'none', borderRadius:8, background:'#534AB7', color:'white', cursor:'pointer', fontWeight:600 }}>Guardar</button>
        </div>
      </div>
    </div>
  );
}

function HeatmapLayer({ points }) {
  const map = useMap();
  React.useEffect(() => {
    if (!points || points.length === 0) return;
    const heat = L.heatLayer(points, { radius: 25, blur: 15, maxZoom: 17, gradient: { 0.4: 'blue', 0.6: 'lime', 0.8: 'yellow', 1: 'red' } }).addTo(map);
    return () => map.removeLayer(heat);
  }, [map, points]);
  return null;
}

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [activeTab, setActiveTab] = useState('recorridos');
  const [filtroEstado, setFiltroEstado] = useState('todos');
  const [filtroTipo, setFiltroTipo] = useState('todos');
  const [filtroMes, setFiltroMes] = useState('todos');
  const [showZonas, setShowZonas] = useState(true);
  const [showAtracciones, setShowAtracciones] = useState(true);
  const [wmsRecorridos, setWmsRecorridos] = useState(false);
  const [wmsZonas, setWmsZonas] = useState(false);
  const [wmsAtracciones, setWmsAtracciones] = useState(false);
  const [selected, setSelected] = useState(null);
  const [flyTarget, setFlyTarget] = useState(null);
  const [recorridos, setRecorridos] = useState([]);
  const [zonas, setZonas] = useState([]);
  const [atracciones, setAtracciones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [drawMode, setDrawMode] = useState(null);
  const [drawnGeojson, setDrawnGeojson] = useState(null);
  const [showForm, setShowForm] = useState(null);
  const [formValues, setFormValues] = useState({});
  const [editingId, setEditingId] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searchMarker, setSearchMarker] = useState(null);
  const [reporte, setReporte] = useState(null);
  const featureGroupRef = useRef(null);
  const [historico, setHistorico] = useState(null);
  const [showHeatmap, setShowHeatmap] = useState(false);

  const loadData = useCallback(async () => {
    try {
      setError(null);
      const [r, z, a] = await Promise.all([
        api.fetchRecorridos(filtroEstado, filtroTipo, filtroMes),
        api.fetchZonas(),
        api.fetchAtracciones(),
      ]);
      setRecorridos(r);
      setZonas(z);
      setAtracciones(a);
    } catch (e) {
      setError('No se pudo conectar al backend. Asegurate que Docker este corriendo.');
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [filtroEstado, filtroTipo, filtroMes]);

  useEffect(() => { loadData(); }, [loadData]);

  const handleCreated = (e) => {
    const geojson = api.layerToGeojson(e.layer);
    setDrawnGeojson(geojson);
    setShowForm(drawMode);
    setFormValues({});
    setEditingId(null);
    if (featureGroupRef.current) featureGroupRef.current.clearLayers();
  };

  const startDraw = (mode) => {
    setDrawMode(mode);
    setSelected(null);
  };

  const handleSave = async () => {
    try {
      if (showForm === 'recorrido') {
        const data = {
          nombre: formValues.nombre, descripcion: formValues.descripcion,
          duracionEstimada: formValues.duracionEstimada, guiaResponsable: formValues.guiaResponsable,
          tipoExperiencia: formValues.tipoExperiencia || 'cultural',
          estado: formValues.estado || 'pendiente',
          estacionInicio: parseInt(formValues.estacionInicio) || 1,
          estacionFin: parseInt(formValues.estacionFin) || 12,
          geojson: drawnGeojson || formValues.geojson,
        };
        if (editingId) await api.updateRecorrido(editingId, data);
        else await api.createRecorrido(data);
      } else if (showForm === 'zona') {
        const data = {
          nombre: formValues.nombre, descripcion: formValues.descripcion,
          nivelAtractivo: parseInt(formValues.nivelAtractivo) || 3,
          observaciones: formValues.observaciones,
          geojson: drawnGeojson || formValues.geojson,
        };
        if (editingId) await api.updateZona(editingId, data);
        else await api.createZona(data);
      } else if (showForm === 'atraccion') {
        const data = {
          nombre: formValues.nombre, descripcion: formValues.descripcion,
          clasificacion: formValues.clasificacion || 'monumento',
          fotoUrl: formValues.fotoUrl || null,
          geojson: drawnGeojson || formValues.geojson,
        };
        if (editingId) await api.updateAtraccion(editingId, data);
        else await api.createAtraccion(data);
      }
      setShowForm(null); setDrawnGeojson(null); setDrawMode(null); setEditingId(null);
      await loadData();
    } catch (e) { alert('Error al guardar: ' + e.message); }
  };

  const handleDelete = async (type, id) => {
    if (!window.confirm('Estas seguro de eliminar?')) return;
    try {
      if (type === 'recorrido') await api.deleteRecorrido(id);
      else if (type === 'zona') await api.deleteZona(id);
      else await api.deleteAtraccion(id);
      setSelected(null);
      await loadData();
    } catch (e) { alert('Error al eliminar: ' + e.message); }
  };

  const handleAvanzar = async (id) => {
    try { await api.avanzarEstado(id); setSelected(null); await loadData(); }
    catch (e) { alert('Error al avanzar estado: ' + e.message); }
  };

  const handleEdit = (type, item) => {
    setEditingId(item.id);
    setDrawnGeojson(item.geojson);
    if (type === 'recorrido') {
      setFormValues({ nombre: item.nombre, descripcion: item.descripcion, duracionEstimada: item.duracionEstimada,
        guiaResponsable: item.guiaResponsable, tipoExperiencia: item.tipoExperiencia, estado: item.estado,
        estacionInicio: item.estacionInicio, estacionFin: item.estacionFin, geojson: item.geojson });
    } else if (type === 'zona') {
      setFormValues({ nombre: item.nombre, descripcion: item.descripcion,
        nivelAtractivo: item.nivelAtractivo, observaciones: item.observaciones, geojson: item.geojson });
    } else {
      setFormValues({ nombre: item.nombre, descripcion: item.descripcion,
        clasificacion: item.clasificacion, geojson: item.geojson });
    }
    setShowForm(type);
  };

  const handleSelect = useCallback((type, data, coords) => {
    setSelected({ type, data }); setHistorico(null); setFlyTarget(coords);
  }, []);

  const handleSearch = async () => {
    if (!searchQuery.trim()) return;
    try {
      const results = await api.geocode(searchQuery);
      setSearchResults(results);
      if (results.length > 0) {
        const r = results[0];
        setSearchMarker([r.lat, r.lng]);
        setFlyTarget([r.lat, r.lng]);
        // Buscar recorrido mas cercano y zona en ese punto
        const [cercano, zona] = await Promise.all([
          api.buscarRecorridoCercano(r.lng, r.lat).catch(() => null),
          api.buscarZonaPorPunto(r.lng, r.lat).catch(() => null),
        ]);
        setSelected({ type: 'busqueda', data: { direccion: r.name, cercano, zona } });
      }
    } catch (e) { console.error('Error en busqueda:', e); }
  };

  const handleReporte = async () => {
    try {
      const data = await api.fetchReporteZonas();
      setReporte(data);
    } catch (e) { alert('Error al cargar reporte: ' + e.message); }
  };

  const recorridoFields = [
    { key: 'nombre', label: 'Nombre' },
    { key: 'descripcion', label: 'Descripcion', type: 'textarea' },
    { key: 'duracionEstimada', label: 'Duracion estimada' },
    { key: 'guiaResponsable', label: 'Guia responsable' },
    { key: 'tipoExperiencia', label: 'Tipo de experiencia', type: 'select',
      options: [{value:'cultural',label:'Cultural'},{value:'gastronomica',label:'Gastronomica'},{value:'natural',label:'Natural'},{value:'historica',label:'Historica'}] },
    { key: 'estacionInicio', label: 'Mes inicio estacion (1-12)', type: 'number' },
    { key: 'estacionFin', label: 'Mes fin estacion (1-12)', type: 'number' },
  ];
  const zonaFields = [
    { key: 'nombre', label: 'Nombre' },
    { key: 'descripcion', label: 'Descripcion', type: 'textarea' },
    { key: 'nivelAtractivo', label: 'Nivel de atractivo (1-5)', type: 'number' },
    { key: 'observaciones', label: 'Observaciones', type: 'textarea' },
  ];
  const atraccionFields = [
    { key: 'nombre', label: 'Nombre' },
    { key: 'descripcion', label: 'Descripcion', type: 'textarea' },
    { key: 'fotoUrl', label: 'Foto', type: 'image' },
    { key: 'clasificacion', label: 'Clasificacion', type: 'select',
      options: [{value:'museo',label:'Museo'},{value:'teatro',label:'Teatro'},{value:'monumento',label:'Monumento'},
        {value:'plaza',label:'Plaza'},{value:'gastronomia',label:'Gastronomia'},{value:'playa',label:'Playa'},{value:'parque',label:'Parque'}] },
  ];

  const drawOptions = {
    polyline: drawMode === 'recorrido' ? { shapeOptions: { color: '#378ADD', weight: 4 } } : false,
    polygon: drawMode === 'zona' ? { shapeOptions: { color: '#534AB7', fillOpacity: 0.2 } } : false,
    marker: drawMode === 'atraccion' ? {} : false,
    circle: false, circlemarker: false, rectangle: false,
  };

  if (loading) return <div style={{ display:'flex', height:'100vh', alignItems:'center', justifyContent:'center', fontFamily:'system-ui' }}>Cargando datos...</div>;

  return (
    <div className="app">
      {showForm && (
        <FormModal
          title={editingId ? 'Editar ' + showForm : 'Nuevo ' + showForm}
          fields={showForm === 'recorrido' ? recorridoFields : showForm === 'zona' ? zonaFields : atraccionFields}
          values={formValues}
          onChange={(k, v) => setFormValues(p => ({...p, [k]: v}))}
          onSave={handleSave}
          onCancel={() => { setShowForm(null); setDrawMode(null); setDrawnGeojson(null); }}
        />
      )}

      <div className={`sidebar ${sidebarOpen ? '' : 'closed'}`}>
        <div className="sidebar-header">
          <div className="sidebar-logo">G</div>
          <div>
            <div style={{ fontWeight:700, fontSize:16, color:'#2C2C2A' }}>GeoTravel</div>
            <div style={{ fontSize:11, color:'#888780' }}>Sistema de gestion turistica</div>
          </div>
          <button onClick={() => setSidebarOpen(false)} style={{ marginLeft:'auto', background:'none', border:'none', cursor:'pointer', fontSize:20, color:'#888' }}>x</button>
        </div>

        <div className="tabs">
          {['recorridos','zonas','atracciones'].map(tab => (
            <button key={tab} className={'tab-btn ' + (activeTab === tab ? 'active' : '')} onClick={() => setActiveTab(tab)}>
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
          <button className={'tab-btn ' + (activeTab === 'reporte' ? 'active' : '')} onClick={() => { setActiveTab('reporte'); handleReporte(); }}>
            Reporte
          </button>
        </div>

        {/* Search bar */}
        <div style={{ padding:'8px 16px', borderBottom:'1px solid #f0efe8' }}>
          <div style={{ display:'flex', gap:6 }}>
            <input type="text" placeholder="Buscar direccion o interseccion..." value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSearch()}
              style={{ flex:1, padding:'8px 12px', border:'1px solid #d3d1c7', borderRadius:8, fontSize:13, outline:'none' }} />
            <button onClick={handleSearch} style={{ padding:'8px 12px', border:'none', borderRadius:8, background:'#534AB7', color:'white', cursor:'pointer', fontWeight:600, fontSize:13 }}>Buscar</button>
          </div>
          {searchResults.length > 1 && (
            <div style={{ marginTop:6, fontSize:11, color:'#888780' }}>
              {searchResults.slice(0, 3).map((r, i) => (
                <div key={i} style={{ padding:'4px 0', cursor:'pointer', borderBottom:'1px solid #f0efe8' }}
                  onClick={() => { setSearchMarker([r.lat, r.lng]); setFlyTarget([r.lat, r.lng]); }}>
                  {r.name.substring(0, 60)}...
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="filters">
          {activeTab === 'recorridos' && (
            <>
              <button className="toggle-chip active" onClick={() => startDraw('recorrido')} style={{ background:'#1D9E75', borderColor:'#1D9E75' }}>+ Nuevo</button>
              <select className="filter-select" value={filtroEstado} onChange={e => setFiltroEstado(e.target.value)}>
                <option value="todos">Todos los estados</option>
                <option value="disponible">Disponible</option>
                <option value="pendiente">Pendiente</option>
                <option value="fuera_de_estacion">Fuera de estacion</option>
                <option value="cancelado">Cancelado</option>
              </select>
              <select className="filter-select" value={filtroTipo} onChange={e => setFiltroTipo(e.target.value)}>
                <option value="todos">Todos los tipos</option>
                <option value="cultural">Cultural</option>
                <option value="gastronomica">Gastronomica</option>
                <option value="natural">Natural</option>
                <option value="historica">Historica</option>
              </select>
              <select className="filter-select" value={filtroMes} onChange={e => setFiltroMes(e.target.value)}>
                <option value="todos">Toda estacion</option>
                <option value="1">Enero</option><option value="2">Febrero</option>
                <option value="3">Marzo</option><option value="4">Abril</option>
                <option value="5">Mayo</option><option value="6">Junio</option>
                <option value="7">Julio</option><option value="8">Agosto</option>
                <option value="9">Septiembre</option><option value="10">Octubre</option>
                <option value="11">Noviembre</option><option value="12">Diciembre</option>
              </select>
            </>
          )}
          {activeTab === 'zonas' && (
            <button className="toggle-chip active" onClick={() => startDraw('zona')} style={{ background:'#534AB7', borderColor:'#534AB7' }}>+ Nueva zona</button>
          )}
          {activeTab === 'atracciones' && (
            <button className="toggle-chip active" onClick={() => startDraw('atraccion')} style={{ background:'#0F6E56', borderColor:'#0F6E56' }}>+ Nueva atraccion</button>
          )}
          <button className={'toggle-chip ' + (showZonas ? 'active' : '')} onClick={() => setShowZonas(!showZonas)}>Zonas</button>
          <button className={'toggle-chip ' + (showAtracciones ? 'active' : '')} onClick={() => setShowAtracciones(!showAtracciones)}>Atracciones</button>
          <button className={'toggle-chip ' + (wmsRecorridos ? 'active' : '')} onClick={() => setWmsRecorridos(!wmsRecorridos)}>WMS Recorridos</button>
          <button className={'toggle-chip ' + (wmsZonas ? 'active' : '')} onClick={() => setWmsZonas(!wmsZonas)}>WMS Zonas</button>
          <button className={'toggle-chip ' + (wmsAtracciones ? 'active' : '')} onClick={() => setWmsAtracciones(!wmsAtracciones)}>WMS Atracciones</button>
          <button className={'toggle-chip ' + (showHeatmap ? 'active' : '')} onClick={() => setShowHeatmap(!showHeatmap)}>🔥 Mapa de calor</button>
        </div>

        {error && <div style={{ padding:'12px 16px', background:'#FCEBEB', color:'#A32D2D', fontSize:12 }}>{error}</div>}

        <div className="list">
          {activeTab === 'recorridos' && recorridos.map(r => (
            <button key={r.id} className="list-item" onClick={() => handleSelect('recorrido', r, api.geojsonToLatLngs(r.geojson))}>
              <span style={{ fontSize:20 }}>{TIPO_ICONS[r.tipoExperiencia]||'📍'}</span>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ fontWeight:600, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{r.nombre}</div>
                <div style={{ display:'flex', gap:6, marginTop:3 }}>
                  <span className="tag" style={{ background: ESTADO_COLORS[r.estado]+'20', color: ESTADO_COLORS[r.estado] }}>{r.estado.replace('_',' ')}</span>
                  {r.duracionEstimada && <span className="tag" style={{ background:'#f0efe8', color:'#5f5e5a' }}>{r.duracionEstimada}</span>}
                </div>
              </div>
            </button>
          ))}
          {activeTab === 'zonas' && (
            <button className="toggle-chip" onClick={async () => {
              try {
                const reporte = await api.fetchReporteZonas();
                setSelected({ type: 'reporte', data: reporte });
              } catch(e) { console.error(e); }
            }} style={{ marginBottom:8, background:'#EEEDFE', color:'#534AB7', borderColor:'#534AB7', width:'100%' }}>📊 Reporte por zona</button>
          )}
          {activeTab === 'zonas' && zonas.map(z => (
            <button key={z.id} className="list-item" onClick={() => handleSelect('zona', z, api.geojsonToLatLngs(z.geojson))}>
              <div style={{ width:32, height:32, borderRadius:8, background:'#EEEDFE', display:'flex', alignItems:'center', justifyContent:'center', fontSize:14, fontWeight:700, color:'#534AB7' }}>{z.nivelAtractivo}</div>
              <div><div style={{ fontWeight:600 }}>{z.nombre}</div><div style={{ fontSize:11, color:'#888780' }}>Atractivo: {z.nivelAtractivo}/5</div></div>
            </button>
          ))}

          {activeTab === 'atracciones' && atracciones.map(a => (
            <button key={a.id} className="list-item" onClick={() => handleSelect('atraccion', a, api.geojsonToLatLngs(a.geojson))}>
              <span style={{ fontSize:20 }}>{CLASIF_ICONS[a.clasificacion]||'📍'}</span>
              <div><div style={{ fontWeight:600 }}>{a.nombre}</div><span className="tag" style={{ background:'#E1F5EE', color:'#0F6E56' }}>{a.clasificacion}</span></div>
            </button>
          ))}

          {activeTab === 'reporte' && reporte && (
            <div style={{ padding:'8px' }}>
              <div style={{ fontSize:13, fontWeight:600, marginBottom:8, color:'#2C2C2A' }}>Recorridos por zona turistica</div>
              {reporte.map(r => (
                <div key={r.id} style={{ padding:12, marginBottom:8, background:'#f9f9f6', borderRadius:8, fontSize:12 }}>
                  <div style={{ fontWeight:600, fontSize:14, marginBottom:6 }}>{r.nombre}</div>
                  <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:4 }}>
                    <span><span style={{ color:'#1D9E75', fontWeight:600 }}>{r.disponibles}</span> disponibles</span>
                    <span><span style={{ color:'#378ADD', fontWeight:600 }}>{r.pendientes}</span> pendientes</span>
                    <span><span style={{ color:'#BA7517', fontWeight:600 }}>{r.fueraEstacion}</span> fuera estacion</span>
                    <span><span style={{ color:'#E24B4A', fontWeight:600 }}>{r.cancelados}</span> cancelados</span>
                  </div>
                  <div style={{ marginTop:4, fontWeight:600 }}>Total: {r.total} recorridos</div>
                </div>
              ))}
              {reporte.length === 0 && <div style={{ color:'#888780', textAlign:'center', padding:20 }}>No hay datos</div>}
            </div>
          )}
          {activeTab === 'reporte' && !reporte && <div style={{ padding:20, textAlign:'center', color:'#888780', fontSize:13 }}>Cargando reporte...</div>}
        </div>

        <div className="legend">
          <div style={{ fontWeight:600, marginBottom:6 }}>Estado de recorridos</div>
          <div style={{ display:'flex', flexWrap:'wrap', gap:'4px 12px' }}>
            {Object.entries(ESTADO_COLORS).map(([k, c]) => (
              <div key={k} style={{ display:'flex', alignItems:'center', gap:4 }}>
                <div style={{ width:14, height:3, background:c, borderRadius:2 }}/><span>{k.replace('_',' ')}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="map-area">
        {!sidebarOpen && <button className="menu-btn" onClick={() => setSidebarOpen(true)}>&#9776;</button>}

        {drawMode && (
          <div style={{ position:'absolute', top:16, left:'50%', transform:'translateX(-50%)', zIndex:1000, background:'#534AB7', color:'white', padding:'8px 20px', borderRadius:20, fontSize:13, fontWeight:600, boxShadow:'0 2px 12px rgba(0,0,0,0.2)' }}>
            {drawMode === 'zona' ? 'Dibuja el poligono de la zona' : drawMode === 'recorrido' ? 'Dibuja la linea del recorrido' : 'Pon un marcador para la atraccion'}
            <button onClick={() => setDrawMode(null)} style={{ marginLeft:12, background:'rgba(255,255,255,0.3)', border:'none', color:'white', borderRadius:10, padding:'2px 8px', cursor:'pointer' }}>X</button>
          </div>
        )}
        <MapContainer center={[-34.91, -56.18]} zoom={13} className="map-container">
        <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" attribution="OSM CARTO" />
          {wmsRecorridos && <WMSTileLayer url="http://localhost:8081/geoserver/geotravel/wms" layers="geotravel:recorrido" format="image/png" transparent={true} />}
          {wmsZonas && <WMSTileLayer url="http://localhost:8081/geoserver/geotravel/wms" layers="geotravel:zona_turistica" format="image/png" transparent={true} />}
          {wmsAtracciones && <WMSTileLayer url="http://localhost:8081/geoserver/geotravel/wms" layers="geotravel:atraccion_turistica" format="image/png" transparent={true} />}
          {showHeatmap && <HeatmapLayer points={[
            ...atracciones.map(a => { const c = api.geojsonToLatLngs(a.geojson); return Array.isArray(c) && c.length === 2 && !Array.isArray(c[0]) ? [c[0], c[1], 1] : null; }).filter(Boolean),
            ...recorridos.flatMap(r => { const coords = api.geojsonToLatLngs(r.geojson); return Array.isArray(coords) ? coords.map(c => [c[0], c[1], 0.5]) : []; })
          ]} />}
          <FlyTo coords={flyTarget} />

          <FeatureGroup ref={featureGroupRef}>
            <EditControl position="topright" onCreated={handleCreated} draw={drawOptions} edit={{ edit: false, remove: false }} />
          </FeatureGroup>

          {showZonas && !wmsZonas && zonas.map(z => {
            const coords = api.geojsonToLatLngs(z.geojson);
            return coords.length > 0 ? (
              <Polygon key={'z-'+z.id} positions={coords} pathOptions={{ color:'#534AB7', weight:1.5, fillColor:'#AFA9EC', fillOpacity:0.2, dashArray:'5,5' }}
                eventHandlers={{ click: () => handleSelect('zona', z, coords) }}><Tooltip sticky>{z.nombre}</Tooltip></Polygon>
            ) : null;
          })}

          {!wmsRecorridos && recorridos.map(r => {
            const coords = api.geojsonToLatLngs(r.geojson);
            return coords.length > 0 ? (
              <Polyline key={'r-'+r.id} positions={coords} pathOptions={{ color: ESTADO_COLORS[r.estado]||'#888', weight:4, opacity:0.85 }}
                eventHandlers={{ click: () => handleSelect('recorrido', r, coords) }}><Tooltip sticky>{r.nombre}</Tooltip></Polyline>
            ) : null;
          })}

          {showAtracciones && !wmsAtracciones && atracciones.map(a => {
            const coords = api.geojsonToLatLngs(a.geojson);
            return Array.isArray(coords) && coords.length === 2 && !Array.isArray(coords[0]) ? (
              <Marker key={'a-'+a.id} position={coords} icon={createIcon(CLASIF_ICONS[a.clasificacion]||'📍')}
                eventHandlers={{ click: () => handleSelect('atraccion', a, coords) }}><Tooltip offset={[0,-12]}>{a.nombre}</Tooltip></Marker>
            ) : null;
          })}

          {searchMarker && (
            <Marker position={searchMarker} icon={createIcon('📍')}>
              <Tooltip permanent>Busqueda</Tooltip>
            </Marker>
          )}
        </MapContainer>

        {selected && (
          <div className="detail-card">
            <button className="close-btn" onClick={() => setSelected(null)}>x</button>
            {selected.type === 'recorrido' && (
              <>
                <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
                  <span style={{ fontSize:24 }}>{TIPO_ICONS[selected.data.tipoExperiencia]||'📍'}</span>
                  <div>
                    <div style={{ fontWeight:700, fontSize:15 }}>{selected.data.nombre}</div>
                    <span className="tag" style={{ background: ESTADO_COLORS[selected.data.estado]+'20', color: ESTADO_COLORS[selected.data.estado] }}>{selected.data.estado.replace('_',' ')}</span>
                  </div>
                </div>
                <div style={{ fontSize:12, color:'#5f5e5a', display:'grid', gridTemplateColumns:'1fr 1fr', gap:'6px 16px' }}>
                  <div><strong>Guia:</strong> {selected.data.guiaResponsable}</div>
                  <div><strong>Duracion:</strong> {selected.data.duracionEstimada}</div>
                  <div><strong>Tipo:</strong> {selected.data.tipoExperiencia}</div>
                  <div><strong>Estacion:</strong> mes {selected.data.estacionInicio} a {selected.data.estacionFin}</div>
                </div>
                <div style={{ display:'flex', gap:8, marginTop:12, flexWrap:'wrap' }}>
                  {NEXT_ESTADO[selected.data.estado] && (
                    <button onClick={() => handleAvanzar(selected.data.id)} style={{ padding:'6px 12px', border:'none', borderRadius:6, background:'#1D9E75', color:'white', cursor:'pointer', fontSize:12, fontWeight:600 }}>
                      Avanzar a {NEXT_ESTADO[selected.data.estado].replace('_',' ')}
                    </button>
                  )}
                  <button onClick={() => handleEdit('recorrido', selected.data)} style={{ padding:'6px 12px', border:'1px solid #d3d1c7', borderRadius:6, background:'white', cursor:'pointer', fontSize:12 }}>Editar</button>
                  <button onClick={() => handleDelete('recorrido', selected.data.id)} style={{ padding:'6px 12px', border:'1px solid #E24B4A', borderRadius:6, background:'white', color:'#E24B4A', cursor:'pointer', fontSize:12 }}>Eliminar</button>
                  <button onClick={async () => {
                    try {
                      const h = await api.fetchHistorico(selected.data.id);
                      setHistorico(h);
                    } catch(e) { console.error(e); }
                  }} style={{ padding:'6px 12px', border:'1px solid #534AB7', borderRadius:6, background:'white', color:'#534AB7', cursor:'pointer', fontSize:12 }}>📋 Histórico</button>
                </div>
                {historico && (
                  <div style={{ marginTop:12, padding:10, background:'#f9f9f6', borderRadius:8 }}>
                    <div style={{ fontWeight:700, fontSize:13, marginBottom:6 }}>Histórico de estados</div>
                    {historico.length === 0 && <div style={{ fontSize:12, color:'#888780' }}>Sin cambios registrados</div>}
                    {historico.map((h, i) => (
                      <div key={i} style={{ display:'flex', justifyContent:'space-between', alignItems:'center', padding:'4px 0', borderBottom:'1px solid #e5e3da', fontSize:12 }}>
                        <span className="tag" style={{ background: ESTADO_COLORS[h.estado]+'20', color: ESTADO_COLORS[h.estado] }}>{h.estado.replace('_',' ')}</span>
                        <span style={{ color:'#888780' }}>{new Date(h.fecha).toLocaleString('es-UY')}</span>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
            {selected.type === 'zona' && (
              <>
                <div style={{ fontWeight:700, fontSize:15, marginBottom:4 }}>{selected.data.nombre}</div>
                <div style={{ fontSize:12, color:'#5f5e5a', marginBottom:6 }}>{selected.data.descripcion}</div>
                <span className="tag" style={{ background:'#EEEDFE', color:'#534AB7' }}>Atractivo: {selected.data.nivelAtractivo}/5</span>
                <div style={{ display:'flex', gap:8, marginTop:12 }}>
                  <button onClick={() => handleEdit('zona', selected.data)} style={{ padding:'6px 12px', border:'1px solid #d3d1c7', borderRadius:6, background:'white', cursor:'pointer', fontSize:12 }}>Editar</button>
                  <button onClick={() => handleDelete('zona', selected.data.id)} style={{ padding:'6px 12px', border:'1px solid #E24B4A', borderRadius:6, background:'white', color:'#E24B4A', cursor:'pointer', fontSize:12 }}>Eliminar</button>
                </div>
              </>
            )}
           {selected.type === 'atraccion' && (
              <>
                <div style={{ display:'flex', alignItems:'center', gap:8 }}>
                  <span style={{ fontSize:24 }}>{CLASIF_ICONS[selected.data.clasificacion]||'📍'}</span>
                  <div>
                    <div style={{ fontWeight:700, fontSize:15 }}>{selected.data.nombre}</div>
                    <span className="tag" style={{ background:'#E1F5EE', color:'#0F6E56' }}>{selected.data.clasificacion}</span>
                  </div>
                </div>
                {selected.data.fotoUrl && (
                  <img src={selected.data.fotoUrl} alt={selected.data.nombre}
                    style={{ width:'100%', height:160, objectFit:'cover', borderRadius:8, marginTop:12 }} />
                )}
                {selected.data.descripcion && (
                  <p style={{ fontSize:13, color:'#5f5e5a', marginTop:8 }}>{selected.data.descripcion}</p>
                )}
                <div style={{ display:'flex', gap:8, marginTop:12 }}>
                  <button onClick={() => handleEdit('atraccion', selected.data)} style={{ padding:'6px 12px', border:'1px solid #d3d1c7', borderRadius:6, background:'white', cursor:'pointer', fontSize:12 }}>Editar</button>
                  <button onClick={() => handleDelete('atraccion', selected.data.id)} style={{ padding:'6px 12px', border:'1px solid #E24B4A', borderRadius:6, background:'white', color:'#E24B4A', cursor:'pointer', fontSize:12 }}>Eliminar</button>
                </div>
              </>
            )}
            {selected.type === 'busqueda' && (
              <>
                <div style={{ fontWeight:700, fontSize:14, marginBottom:8 }}>Resultado de busqueda</div>
                <div style={{ fontSize:12, color:'#5f5e5a', marginBottom:8 }}>{selected.data.direccion}</div>
                {selected.data.zona && selected.data.zona.nombre && (
                  <div style={{ marginBottom:6 }}>
                    <span className="tag" style={{ background:'#EEEDFE', color:'#534AB7' }}>Zona: {selected.data.zona.nombre}</span>
                  </div>
                )}
                {selected.data.zona && selected.data.zona.mensaje && (
                  <div style={{ fontSize:12, color:'#888780', marginBottom:6 }}>{selected.data.zona.mensaje}</div>
                )}
                {selected.data.cercano && selected.data.cercano.nombre && (
                  <div style={{ marginTop:6, padding:8, background:'#f0ffe8', borderRadius:6, fontSize:12 }}>
                    <strong>Recorrido mas cercano:</strong> {selected.data.cercano.nombre}
                    <span className="tag" style={{ marginLeft:6, background: ESTADO_COLORS[selected.data.cercano.estado]+'20', color: ESTADO_COLORS[selected.data.cercano.estado] }}>
                      {selected.data.cercano.estado.replace('_',' ')}
                    </span>
                  </div>
                )}
              </>
            )}
            {selected && selected.type === 'reporte' && (
              <div style={{ padding:16 }}>
                <h3 style={{ margin:'0 0 12px', fontSize:16 }}>📊 Recorridos por zona</h3>
                {selected.data.map((r, i) => (
                  <div key={i} style={{ padding:8, marginBottom:6, background:'#f9f9f6', borderRadius:8, fontSize:13 }}>
                    <div style={{ fontWeight:700 }}>{r.nombre}</div>
                    <div style={{ color:'#5f5e5a', marginTop:4 }}>
                      🟢 Disponibles: {r.disponibles} · 🟡 Pendientes: {r.pendientes} · 🔵 Fuera estación: {r.fueraEstacion} · 🔴 Cancelados: {r.cancelados}
                    </div>
                    <div style={{ fontWeight:600, marginTop:2 }}>Total: {r.total}</div>
                  </div>
                ))}
                <button onClick={() => setSelected(null)} style={{ marginTop:8, padding:'6px 12px', border:'1px solid #d3d1c7', borderRadius:6, background:'white', cursor:'pointer', fontSize:12 }}>Cerrar</button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
