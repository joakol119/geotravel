// Base URL de la API - en Docker, el proxy redirige a backend:8080
const API = '/api';

function authHeaders() {
  const token = localStorage.getItem('geotravel_token');
  return {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
  };
}

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
    method: 'POST', headers: authHeaders(),
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function updateRecorrido(id, data) {
  const res = await fetch(`${API}/recorridos/${id}`, {
    method: 'PUT', headers: authHeaders(),
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

export async function fetchAtraccionesPorRecorrido(recorridoId) {
  const res = await fetch(`${API}/recorridos/${recorridoId}/atracciones`);
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
    method: 'POST', headers: authHeaders(),
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function updateZona(id, data) {
  const res = await fetch(`${API}/zonas/${id}`, {
    method: 'PUT', headers: authHeaders(),
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
    method: 'POST', headers: authHeaders(),
    body: JSON.stringify(data),
  });
  return res.json();
}

export async function updateAtraccion(id, data) {
  const res = await fetch(`${API}/atracciones/${id}`, {
    method: 'PUT', headers: authHeaders(),
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
  // Detectar si es una intersección (contiene "y", "&", "esquina", ",")
  const separators = [' y ', ' & ', ' esquina ', ', '];
  let calles = null;
  for (const sep of separators) {
    if (query.toLowerCase().includes(sep)) {
      calles = query.toLowerCase().split(sep).map(c => c.trim());
      break;
    }
  }

  // Si es intersección, geocodificar ambas calles y buscar punto cercano
  if (calles && calles.length === 2) {
    const [resultados1, resultados2] = await Promise.all([
      geocodeSingle(calles[0] + ', Montevideo, Uruguay'),
      geocodeSingle(calles[1] + ', Montevideo, Uruguay'),
    ]);

    if (resultados1.length > 0 && resultados2.length > 0) {
      // Buscar el par de puntos más cercano entre ambas calles
      let minDist = Infinity;
      let best = null;
      for (const r1 of resultados1.slice(0, 3)) {
        for (const r2 of resultados2.slice(0, 3)) {
          const d = Math.sqrt(Math.pow(r1.lat - r2.lat, 2) + Math.pow(r1.lng - r2.lng, 2));
          if (d < minDist) {
            minDist = d;
            best = {
              name: calles[0] + ' y ' + calles[1] + ', Montevideo',
              lat: (r1.lat + r2.lat) / 2,
              lng: (r1.lng + r2.lng) / 2,
            };
          }
        }
      }
      if (best) return [best];
    }
  }

  // Búsqueda normal (no intersección)
  return geocodeSingle(query + ', Montevideo, Uruguay');
}

async function geocodeSingle(query) {
  const params = new URLSearchParams({
    q: query,
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

export async function fetchHistorico(recorridoId) {
  const res = await fetch(API + '/recorridos/' + recorridoId + '/historico');
  return res.json();
}

export async function checkSuperposicion(geojson, excludeId) {
  const params = new URLSearchParams({ geojson });
  if (excludeId) params.append('excludeId', excludeId);
  const res = await fetch(API + '/zonas/superpone?' + params);
  return res.json();
}

// ============================================================
// AUTH
// ============================================================
export async function login(email, password) {
  const res = await fetch(`${API}/auth/login`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) return null;
  return res.json();
}

export function getToken() {
  return localStorage.getItem('geotravel_token');
}

export function setToken(token) {
  localStorage.setItem('geotravel_token', token);
}

export function removeToken() {
  localStorage.removeItem('geotravel_token');
}

export function isAuthenticated() {
  return !!localStorage.getItem('geotravel_token');
}