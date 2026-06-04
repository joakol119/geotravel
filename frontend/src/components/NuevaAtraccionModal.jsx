import React, { useState, useEffect } from 'react';

const CLASIFICACIONES = [
  { value: 'museo', label: '🖼️ Museo' },
  { value: 'teatro', label: '🎭 Teatro' },
  { value: 'monumento', label: '🏛️ Monumento' },
  { value: 'plaza', label: '⛲ Plaza' },
  { value: 'gastronomia', label: '🍖 Gastronomía' },
  { value: 'playa', label: '🏖️ Playa' },
  { value: 'parque', label: '🌿 Parque' },
];

export default function NuevaAtraccionModal({ onUbicarEnMapa, onGuardar, onCancel, editando }) {
  const [step, setStep] = useState(1);
  const [modoUbicacion, setModoUbicacion] = useState(null);
  const [cargando, setCargando] = useState(false);
  const [busqueda, setBusqueda] = useState('');
  const [resultados, setResultados] = useState([]);
  const [form, setForm] = useState({
    nombre: editando?.nombre || '',
    descripcion: editando?.descripcion || '',
    clasificacion: editando?.clasificacion || 'monumento',
    fotoUrl: editando?.fotoUrl || '',
  });
  const [coordsSeleccionadas, setCoordsSeleccionadas] = useState(
    editando?.geojson ? JSON.parse(editando.geojson).coordinates : null
  );

  if (cargando) return null;

  const handleForm = (k, v) => setForm(p => ({ ...p, [k]: v }));

  const buscarDireccion = async () => {
    if (!busqueda.trim()) return;
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(busqueda)}&limit=5&countrycodes=uy`);
      const data = await res.json();
      setResultados(data);
    } catch(e) {
      alert('Error buscando dirección');
    }
  };

  const seleccionarResultado = (r) => {
    setCoordsSeleccionadas([parseFloat(r.lon), parseFloat(r.lat)]);
    setResultados([]);
    setBusqueda(r.display_name.split(',').slice(0,2).join(','));
    setStep(3);
  };

  const handleGuardar = () => {
    if (!coordsSeleccionadas) { alert('Seleccioná una ubicación'); return; }
    const geojson = JSON.stringify({ type: 'Point', coordinates: coordsSeleccionadas });
    onGuardar({ ...form, geojson });
  };

  const formValido = form.nombre && form.clasificacion;

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)', zIndex: 3000,
      display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16,
    }}>
      <div style={{
        background: 'white', borderRadius: 20, width: '100%', maxWidth: 500,
        maxHeight: '90vh', overflowY: 'auto',
        boxShadow: '0 24px 80px rgba(0,0,0,0.18)',
      }}>

        {/* Header */}
        <div style={{ padding: '24px 24px 0' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
            <h2 style={{ margin: 0, fontSize: 20, fontWeight: 600, color: '#2c2c2a' }}>
              {editando ? 'Editar atracción' : 'Nueva atracción'}
            </h2>
            <button onClick={onCancel} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 22, color: '#888780', padding: 4 }}>×</button>
          </div>
          <p style={{ margin: '4px 0 20px', fontSize: 13, color: '#888780' }}>
            {step === 1 ? 'Elegí cómo ubicar la atracción' : step === 2 ? 'Buscá la dirección' : 'Completá los datos'}
          </p>

          {/* Steps */}
          <div style={{ display: 'flex', gap: 6, marginBottom: 24 }}>
            {['Ubicación', 'Buscar', 'Datos'].map((label, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{
                  width: 24, height: 24, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 11, fontWeight: 600,
                  background: step > i ? '#1D9E75' : step === i + 1 ? '#0F6E56' : '#f0efe8',
                  color: step >= i + 1 ? 'white' : '#9c9b95',
                }}>
                  {step > i ? '✓' : i + 1}
                </div>
                <span style={{ fontSize: 11, color: step === i + 1 ? '#0F6E56' : '#9c9b95', fontWeight: step === i + 1 ? 500 : 400 }}>{label}</span>
                {i < 2 && <div style={{ width: 20, height: 1, background: '#e5e4df' }} />}
              </div>
            ))}
          </div>
        </div>

        <div style={{ padding: '0 24px 24px' }}>

          {/* PASO 1: Elegir modo de ubicación */}
          {step === 1 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <button onClick={() => { setModoUbicacion('buscar'); setStep(2); }} style={{
                padding: 20, border: `2px solid ${modoUbicacion === 'buscar' ? '#0F6E56' : '#e5e4df'}`,
                borderRadius: 14, background: modoUbicacion === 'buscar' ? '#E1F5EE' : 'white',
                cursor: 'pointer', textAlign: 'left', transition: 'all 0.15s',
              }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>🔍</div>
                <div style={{ fontWeight: 600, fontSize: 14, color: '#2c2c2a', marginBottom: 4 }}>Buscar dirección</div>
                <div style={{ fontSize: 12, color: '#888780' }}>Escribí el nombre o dirección y el sistema la geocodifica automáticamente.</div>
              </button>
              <button onClick={() => { setModoUbicacion('mapa'); onUbicarEnMapa(form); }} style={{
                padding: 20, border: `2px solid ${modoUbicacion === 'mapa' ? '#0F6E56' : '#e5e4df'}`,
                borderRadius: 14, background: modoUbicacion === 'mapa' ? '#E1F5EE' : 'white',
                cursor: 'pointer', textAlign: 'left', transition: 'all 0.15s',
              }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>📍</div>
                <div style={{ fontWeight: 600, fontSize: 14, color: '#2c2c2a', marginBottom: 4 }}>Marcar en el mapa</div>
                <div style={{ fontSize: 12, color: '#888780' }}>Hacé click directamente sobre el mapa para colocar la atracción.</div>
              </button>
              {editando && coordsSeleccionadas && (
                <button onClick={() => setStep(3)} style={{
                  padding: 20, border: '2px solid #e5e4df',
                  borderRadius: 14, background: 'white',
                  cursor: 'pointer', textAlign: 'left',
                }}>
                  <div style={{ fontSize: 28, marginBottom: 8 }}>✅</div>
                  <div style={{ fontWeight: 600, fontSize: 14, color: '#2c2c2a', marginBottom: 4 }}>Mantener ubicación actual</div>
                  <div style={{ fontSize: 12, color: '#888780' }}>Conservar las coordenadas actuales y solo editar los datos.</div>
                </button>
              )}
            </div>
          )}

          {/* PASO 2: Buscar dirección */}
          {step === 2 && modoUbicacion === 'buscar' && (
            <div>
              <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
                <input
                  type="text"
                  value={busqueda}
                  onChange={e => setBusqueda(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && buscarDireccion()}
                  placeholder="Ej: Teatro Solís, Montevideo"
                  style={{ flex: 1, padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, outline: 'none' }}
                />
                <button onClick={buscarDireccion} style={{
                  padding: '9px 16px', border: 'none', borderRadius: 8,
                  background: '#0F6E56', color: 'white', cursor: 'pointer', fontSize: 13, fontWeight: 600,
                }}>
                  Buscar
                </button>
              </div>
              {resultados.length > 0 && (
                <div style={{ border: '1px solid #e5e4df', borderRadius: 10, overflow: 'hidden', marginBottom: 12 }}>
                  {resultados.map((r, i) => (
                    <div key={i} onClick={() => seleccionarResultado(r)} style={{
                      padding: '10px 14px', cursor: 'pointer', borderBottom: i < resultados.length-1 ? '1px solid #f0efe8' : 'none',
                      fontSize: 12, color: '#2c2c2a',
                    }}
                    onMouseEnter={e => e.currentTarget.style.background = '#f9f8f5'}
                    onMouseLeave={e => e.currentTarget.style.background = 'white'}
                    >
                      📍 {r.display_name.substring(0, 80)}...
                    </div>
                  ))}
                </div>
              )}
              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={() => setStep(1)} style={{ flex: 1, padding: '10px', border: '1px solid #e5e4df', borderRadius: 10, background: 'white', cursor: 'pointer', fontSize: 13, color: '#5f5e5a' }}>Atrás</button>
              </div>
            </div>
          )}

          {/* PASO 3: Formulario de datos */}
          {step === 3 && (
            <div>
              {coordsSeleccionadas && (
                <div style={{ padding: '10px 14px', background: '#E1F5EE', borderRadius: 10, marginBottom: 16, fontSize: 12, color: '#0F6E56' }}>
                  ✅ Ubicación: {coordsSeleccionadas[1].toFixed(5)}, {coordsSeleccionadas[0].toFixed(5)}
                  <button onClick={() => setStep(1)} style={{ marginLeft: 8, background: 'none', border: 'none', cursor: 'pointer', color: '#0F6E56', fontSize: 11, textDecoration: 'underline' }}>cambiar</button>
                </div>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Nombre</label>
                  <input type="text" value={form.nombre} onChange={e => handleForm('nombre', e.target.value)}
                    placeholder="Ej: Teatro Solís"
                    style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Clasificación</label>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
                    {CLASIFICACIONES.map(c => (
                      <button key={c.value} onClick={() => handleForm('clasificacion', c.value)} style={{
                        padding: '8px 4px', border: `1.5px solid ${form.clasificacion === c.value ? '#0F6E56' : '#e5e4df'}`,
                        borderRadius: 8, background: form.clasificacion === c.value ? '#E1F5EE' : 'white',
                        cursor: 'pointer', fontSize: 11, color: form.clasificacion === c.value ? '#0F6E56' : '#5f5e5a',
                        fontWeight: form.clasificacion === c.value ? 600 : 400, textAlign: 'center',
                      }}>
                        {c.label}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Descripción</label>
                  <textarea value={form.descripcion} onChange={e => handleForm('descripcion', e.target.value)}
                    placeholder="Descripción de la atracción..."
                    rows={3}
                    style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none', resize: 'vertical' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Foto (URL opcional)</label>
                  <input type="text" value={form.fotoUrl} onChange={e => handleForm('fotoUrl', e.target.value)}
                    placeholder="https://..."
                    style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none' }} />
                </div>
              </div>

              <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
                <button onClick={() => setStep(1)} style={{ flex: 1, padding: '10px', border: '1px solid #e5e4df', borderRadius: 10, background: 'white', cursor: 'pointer', fontSize: 13, color: '#5f5e5a' }}>Atrás</button>
                <button
                  onClick={() => formValido && handleGuardar()}
                  disabled={!formValido}
                  style={{ flex: 2, padding: '10px', border: 'none', borderRadius: 10, background: formValido ? '#0F6E56' : '#e5e4df', color: formValido ? 'white' : '#9c9b95', cursor: formValido ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600 }}
                >
                  {editando ? 'Guardar cambios' : 'Crear atracción'}
                </button>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
