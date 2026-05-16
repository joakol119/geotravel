// Base URL de la API - en Docker, el proxy redirige a backend:8080
const API = '/api';

// ============================================================
// RECORRIDOS
// ============================================================
export async function fetchRecorridos(estado, tipo, mes) {
  const params = new URLSearchParams();
  if (estado && estado !== 'todos') params.append('estado', estado);
  if (tipo && tipo !== 'todos') params.append('tipo', tipo);
  if (mes && mes !== 'todos') params.append('mes', mes);
  const res = await fetch(`${API}/recorridos?${params}`);
  return res.json();
}

export async function createRecorrido(data) {
  const res = await fetch(`${API}/recorridos`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function updateRecorrido(id, data) {
  const res = await fetch(`${API}/recorridos/${id}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function deleteRecorrido(id) {
  return fetch(`${API}/recorridos/${id}`, { method: 'DELETE' });
}

export async function avanzarEstado(id) {
  const res = await fetch(`${API}/recorridos/${id}/avanzar`, { method: 'PUT' });
  return res.json();
}

// ============================================================
// ZONAS
// ============================================================
export async function fetchZonas() {
  const res = await fetch(`${API}/zonas`);
  return res.json();
}

export async function createZona(data) {
  const res = await fetch(`${API}/zonas`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function updateZona(id, data) {
  const res = await fetch(`${API}/zonas/${id}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function deleteZona(id) {
  return fetch(`${API}/zonas/${id}`, { method: 'DELETE' });
}

// ============================================================
// ATRACCIONES
// ============================================================
export async function fetchAtracciones() {
  const res = await fetch(`${API}/atracciones`);
  return res.json();
}

export async function createAtraccion(data) {
  const res = await fetch(`${API}/atracciones`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function updateAtraccion(id, data) {
  const res = await fetch(`${API}/atracciones/${id}`, {
    method: 'PUT', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function deleteAtraccion(id) {
  return fetch(`${API}/atracciones/${id}`, { method: 'DELETE' });
}

// ============================================================
// HELPERS
// ============================================================

/** Convierte GeoJSON geometry string a array de coordenadas para Leaflet */
export function geojsonToLatLngs(geojsonStr) {
  if (!geojsonStr) return [];
  const geo = typeof geojsonStr === 'string' ? JSON.parse(geojsonStr) : geojsonStr;
  if (geo.type === 'Point') {
    return [geo.coordinates[1], geo.coordinates[0]];
  }
  if (geo.type === 'LineString') {
    return geo.coordinates.map(c => [c[1], c[0]]);
  }
  if (geo.type === 'Polygon') {
    return geo.coordinates[0].map(c => [c[1], c[0]]);
  }
  return [];
}

/** Convierte Leaflet layer a GeoJSON string */
export function layerToGeojson(layer) {
  const geo = layer.toGeoJSON();
  return JSON.stringify(geo.geometry);
}

// ============================================================
// GEOCODING (Nominatim / OpenStreetMap - gratuito)
// ============================================================
export async function geocode(query) {
  const params = new URLSearchParams({
    q: query + ', Montevideo, Uruguay',
    format: 'json',
    limit: '5',
    addressdetails: '1',
  });
  const res = await fetch('https://nominatim.openstreetmap.org/search?' + params, {
    headers: { 'Accept-Language': 'es' }
  });
  const data = await res.json();
  return data.map(r => ({
    name: r.display_name,
    lat: parseFloat(r.lat),
    lng: parseFloat(r.lon),
  }));
}

// ============================================================
// CONSULTAS GEOGRÁFICAS
// ============================================================
export async function fetchReporteZonas() {
  const res = await fetch(API + '/zonas/reporte');
  return res.json();
}

export async function buscarZonaPorPunto(lng, lat) {
  const res = await fetch(API + '/zonas/buscar?lng=' + lng + '&lat=' + lat);
  return res.json();
}

export async function buscarRecorridoCercano(lng, lat) {
  const res = await fetch(API + '/recorridos/cercano?lng=' + lng + '&lat=' + lat);
  return res.json();
}

export async function fetchRecorridosPorZona(zonaId) {
  const res = await fetch(API + '/recorridos/zona/' + zonaId);
  return res.json();
}
