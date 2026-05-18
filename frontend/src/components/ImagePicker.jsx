import React, { useState } from 'react';

/**
 * Componente para seleccionar imagen de una atracción turística.
 * Tres modos: búsqueda automática, pegar URL, o subir archivo.
 */
export default function ImagePicker({ value, onChange }) {
  const [mode, setMode] = useState('search');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [urlInput, setUrlInput] = useState(value || '');
  const [noResults, setNoResults] = useState(false);

  // Buscar imágenes en Wikimedia Commons (namespace=6 = archivos de imagen)
  const handleSearch = async () => {
    if (!searchQuery.trim()) return;
    setSearching(true);
    setNoResults(false);
    setSearchResults([]);

    try {
      // Búsqueda en Wikimedia Commons restringida a archivos (namespace 6)
      const query = encodeURIComponent(searchQuery);
      const url =
        `https://commons.wikimedia.org/w/api.php?action=query` +
        `&generator=search&gsrsearch=${query}&gsrnamespace=6&gsrlimit=9` +
        `&prop=imageinfo&iiprop=url&iiurlwidth=300` +
        `&format=json&origin=*`;

      const res = await fetch(url);
      const data = await res.json();
      const pages = data.query?.pages || {};

      const images = Object.values(pages)
        .filter(p => {
          const info = p.imageinfo?.[0];
          if (!info) return false;
          // Filtrar solo imágenes reales (no SVGs de íconos, no archivos muy chicos)
          const thumbUrl = info.thumburl || '';
          return thumbUrl && !thumbUrl.endsWith('.svg') && !thumbUrl.includes('Icon');
        })
        .map(p => ({
          thumb: p.imageinfo[0].thumburl,
          full: p.imageinfo[0].url,
          title: p.title?.replace('File:', '') || '',
        }))
        .slice(0, 6);

      if (images.length === 0) {
        setNoResults(true);
      }
      setSearchResults(images);
    } catch (err) {
      console.error('Error buscando imágenes:', err);
      setNoResults(true);
    }
    setSearching(false);
  };

  // Subir archivo local al backend
  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      alert('La imagen no puede superar 5MB');
      return;
    }
    const reader = new FileReader();
    reader.onload = async () => {
      try {
        const res = await fetch('/api/atracciones/upload', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ base64: reader.result, filename: file.name }),
        });
        const data = await res.json();
        if (data.url) {
          onChange(data.url);
        }
      } catch (err) {
        console.error('Error subiendo imagen:', err);
      }
    };
    reader.readAsDataURL(file);
  };

  const btnStyle = (active) => ({
    padding: '6px 12px',
    border: '1px solid ' + (active ? '#534AB7' : '#d3d1c7'),
    borderRadius: 6,
    background: active ? '#534AB7' : 'white',
    color: active ? 'white' : '#5f5e5a',
    cursor: 'pointer',
    fontSize: 11,
    fontWeight: 600,
  });

  return (
    <div style={{ marginBottom: 12 }}>
      {/* Preview de imagen seleccionada */}
      {value && (
        <div style={{ marginBottom: 8, position: 'relative' }}>
          <img
            src={value}
            alt="Preview"
            style={{ width: '100%', height: 140, objectFit: 'cover', borderRadius: 8, border: '1px solid #e5e3da' }}
            onError={(e) => { e.target.style.display = 'none'; }}
          />
          <button
            onClick={() => onChange('')}
            style={{
              position: 'absolute', top: 4, right: 4,
              background: 'rgba(0,0,0,0.6)', color: 'white', border: 'none',
              borderRadius: '50%', width: 24, height: 24, cursor: 'pointer', fontSize: 14,
            }}
          >✕</button>
        </div>
      )}

      {/* Tabs de modo */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 8 }}>
        <button type="button" onClick={() => setMode('search')} style={btnStyle(mode === 'search')}>🔍 Buscar</button>
        <button type="button" onClick={() => setMode('url')} style={btnStyle(mode === 'url')}>🔗 URL</button>
        <button type="button" onClick={() => setMode('upload')} style={btnStyle(mode === 'upload')}>📁 Subir</button>
      </div>

      {/* Modo búsqueda */}
      {mode === 'search' && (
        <div>
          <div style={{ display: 'flex', gap: 4 }}>
            <input
              type="text"
              placeholder="Ej: cafe, museum, beach, park..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleSearch(); } }}
              style={{
                flex: 1, padding: '6px 10px', border: '1px solid #d3d1c7',
                borderRadius: 6, fontSize: 12, outline: 'none',
              }}
            />
            <button
              type="button"
              onClick={handleSearch}
              disabled={searching}
              style={{
                padding: '6px 12px', background: '#534AB7', color: 'white',
                border: 'none', borderRadius: 6, cursor: 'pointer', fontSize: 12,
              }}
            >
              {searching ? '...' : 'Buscar'}
            </button>
          </div>
          <p style={{ fontSize: 10, color: '#999', margin: '4px 0 0' }}>
            Tip: buscá en inglés para más resultados (ej: "park", "theater", "beach")
          </p>
          {noResults && (
            <p style={{ fontSize: 11, color: '#e67e22', margin: '8px 0 0' }}>
              No se encontraron imágenes. Probá otro término o usá URL/Subir.
            </p>
          )}
          {searchResults.length > 0 && (
            <div style={{
              display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 4,
              marginTop: 8, maxHeight: 200, overflowY: 'auto',
            }}>
              {searchResults.map((img, i) => (
                <img
                  key={i}
                  src={img.thumb}
                  alt={img.title}
                  onClick={() => { onChange(img.thumb); setSearchResults([]); setNoResults(false); }}
                  style={{
                    width: '100%', height: 70, objectFit: 'cover', borderRadius: 6,
                    cursor: 'pointer', border: value === img.thumb ? '3px solid #534AB7' : '1px solid #e5e3da',
                  }}
                />
              ))}
            </div>
          )}
        </div>
      )}

      {/* Modo URL */}
      {mode === 'url' && (
        <div style={{ display: 'flex', gap: 4 }}>
          <input
            type="text"
            placeholder="https://ejemplo.com/imagen.jpg"
            value={urlInput}
            onChange={(e) => setUrlInput(e.target.value)}
            style={{
              flex: 1, padding: '6px 10px', border: '1px solid #d3d1c7',
              borderRadius: 6, fontSize: 12, outline: 'none',
            }}
          />
          <button
            type="button"
            onClick={() => onChange(urlInput)}
            style={{
              padding: '6px 12px', background: '#1D9E75', color: 'white',
              border: 'none', borderRadius: 6, cursor: 'pointer', fontSize: 12,
            }}
          >
            OK
          </button>
        </div>
      )}

      {/* Modo subir archivo */}
      {mode === 'upload' && (
        <input
          type="file"
          accept="image/*"
          onChange={handleFileUpload}
          style={{ fontSize: 12 }}
        />
      )}
    </div>
  );
}
