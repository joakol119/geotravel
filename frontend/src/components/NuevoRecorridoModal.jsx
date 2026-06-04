import React, { useState, useEffect } from 'react';

const MESES = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

const TIPO_OPTIONS = [
  { value: 'cultural', label: '🏛️ Cultural' },
  { value: 'gastronomica', label: '🍷 Gastronómica' },
  { value: 'natural', label: '🌿 Natural' },
  { value: 'historica', label: '📜 Histórica' },
];

export default function NuevoRecorridoModal({ zonas, atracciones, onDibujar, onCrearDesdePuntos, onCancel, editando }) {  const [modo, setModo] = useState(null);
  const [form, setForm] = useState({
    nombre: editando?.nombre || '',
    descripcion: editando?.descripcion || '',
    duracionEstimada: editando?.duracionEstimada || '',
    guiaResponsable: editando?.guiaResponsable || '',
    tipoExperiencia: editando?.tipoExperiencia || 'cultural',
    estacionInicio: editando?.estacionInicio || 1,
    estacionFin: editando?.estacionFin || 12,
  });
  const [puntos, setPuntos] = useState([
    { tipo: 'atraccion', id: '' },
    { tipo: 'atraccion', id: '' }
  ]);
  const [step, setStep] = useState(1);
  const [optimizado, setOptimizado] = useState(false);
  const [cargando, setCargando] = useState(!!editando);

  useEffect(() => {
    if (editando) {
      fetch(`/api/recorridos/${editando.id}/atracciones`)
        .then(r => r.json())
        .then(atracs => {
          if (atracs.length > 0) {
            setPuntos(atracs.map(a => ({ tipo: 'atraccion', id: String(a.id) })));
            setModo('puntos');
            setStep(2);
          }
          setCargando(false);
        })
        .catch(() => setCargando(false));
    }
  }, [editando]);

  const handleForm = (k, v) => setForm(p => ({ ...p, [k]: v }));
  const addPunto = () => setPuntos(p => [...p.slice(0, -1), { tipo: 'atraccion', id: '' }, p[p.length - 1]]);
  const removePunto = (i) => setPuntos(p => p.filter((_, idx) => idx !== i));
  const updatePunto = (i, k, v) => setPuntos(p => p.map((pt, idx) => idx === i ? { ...pt, [k]: v } : pt));

  const getOpcionesPunto = (tipo) => {
    if (tipo === 'zona') return zonas.map(z => ({ value: z.id, label: z.nombre }));
    return atracciones.map(a => ({ value: a.id, label: a.nombre }));
  };

  const getPuntoCoords = (punto) => {
    if (punto.tipo === 'zona') {
      const z = zonas.find(z => z.id === parseInt(punto.id));
      if (!z || !z.geojson) return null;
      const geo = JSON.parse(z.geojson);
      if (geo.type === 'Polygon') return geo.coordinates[0][0];
      if (geo.type === 'MultiPolygon') return geo.coordinates[0][0][0];
      return null;
    } else {
      const a = atracciones.find(a => a.id === parseInt(punto.id));
      if (!a || !a.geojson) return null;
      const geo = JSON.parse(a.geojson);
      return geo.coordinates;
    }
  };

  const ORS_KEY = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6Ijc5OTM0MTAwODJmYzRlMzY4MGIzYjAwMmViNTQ3YTI1IiwiaCI6Im11cm11cjY0In0=';

const optimizarOrden = async () => {
  const coords = puntos.map(getPuntoCoords).filter(Boolean);
  if (coords.length < 3) return; // con 2 puntos no hay nada que optimizar
  
  // Fijamos origen y destino, optimizamos solo las paradas intermedias
  const inicio = puntos[0];
  const fin = puntos[puntos.length - 1];
  const intermedios = puntos.slice(1, -1);
  
  if (intermedios.length === 0) return;

  // Calculamos distancias en línea recta entre todos los puntos intermedios
  const calcDist = (a, b) => {
    const ca = getPuntoCoords(a);
    const cb = getPuntoCoords(b);
    if (!ca || !cb) return Infinity;
    return Math.sqrt(Math.pow(ca[0]-cb[0],2) + Math.pow(ca[1]-cb[1],2));
  };
  setOptimizado(true);

  // Greedy: ordenamos intermedios por distancia al punto anterior
  let ordenados = [];
  let restantes = [...intermedios];
  let actual = inicio;
  
  while (restantes.length > 0) {
    let minDist = Infinity;
    let minIdx = 0;
    restantes.forEach((p, i) => {
      const d = calcDist(actual, p);
      if (d < minDist) { minDist = d; minIdx = i; }
    });
    ordenados.push(restantes[minIdx]);
    actual = restantes[minIdx];
    restantes.splice(minIdx, 1);
  }

  setPuntos([inicio, ...ordenados, fin]);
};

const handleCrear = async () => {
  if (modo === 'dibujar') {
    onDibujar(form);
    return;
  }
  const coords = puntos.map(getPuntoCoords).filter(Boolean);
  if (coords.length < 2) { alert('Seleccioná al menos 2 puntos'); return; }
  
  try {
    let rutaCoords = [];
    for (let i = 0; i < coords.length - 1; i++) {
      const start = `${coords[i][0]},${coords[i][1]}`;
      const end = `${coords[i+1][0]},${coords[i+1][1]}`;
      const res = await fetch(`https://api.openrouteservice.org/v2/directions/driving-car?api_key=${ORS_KEY}&start=${start}&end=${end}`);
      if (!res.ok) {
        rutaCoords = [...rutaCoords, coords[i], coords[i+1]];
        continue;
      }
      const data = await res.json();
      if (data.features && data.features[0]) {
        const segmento = data.features[0].geometry.coordinates;
        rutaCoords = [...rutaCoords, ...segmento];
      } else {
        rutaCoords = [...rutaCoords, coords[i], coords[i+1]];
      }
    }
    const geojson = JSON.stringify({ type: 'LineString', coordinates: rutaCoords });
    onCrearDesdePuntos({ ...form, geojson, puntos });
  } catch(e) {
    alert('Error calculando ruta. Se usará línea recta.');
    const geojson = JSON.stringify({ type: 'LineString', coordinates: coords });
    onCrearDesdePuntos({ ...form, geojson, puntos });
  }
};

  const puntosCompletos = puntos.every(p => p.id);
  const formValido = form.nombre && form.guiaResponsable;

  if (cargando) return null;
  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)', zIndex: 3000,
      display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16,
    }}>
      <div style={{
        background: 'white', borderRadius: 20, width: '100%', maxWidth: 520,
        maxHeight: '90vh', overflowY: 'auto',
        boxShadow: '0 24px 80px rgba(0,0,0,0.18)',
      }}>

        {/* Header */}
        <div style={{ padding: '24px 24px 0' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
            <h2 style={{ margin: 0, fontSize: 20, fontWeight: 600, color: '#2c2c2a' }}>Nuevo recorrido</h2>
            <button onClick={onCancel} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 22, color: '#888780', padding: 4 }}>×</button>
          </div>
          <p style={{ margin: '4px 0 20px', fontSize: 13, color: '#888780' }}>
            {step === 1 ? 'Elegí cómo querés crear el recorrido' : modo === 'puntos' ? 'Seleccioná los puntos del recorrido' : 'Completá los datos del recorrido'}
          </p>

          {/* Paso indicator */}
          <div style={{ display: 'flex', gap: 6, marginBottom: 24 }}>
            {['Modo', modo === 'puntos' ? 'Puntos' : 'Ruta', 'Datos'].map((label, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{
                  width: 24, height: 24, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 11, fontWeight: 600,
                  background: step > i ? '#1D9E75' : step === i + 1 ? '#534AB7' : '#f0efe8',
                  color: step >= i + 1 ? 'white' : '#9c9b95',
                }}>
                  {step > i ? '✓' : i + 1}
                </div>
                <span style={{ fontSize: 11, color: step === i + 1 ? '#534AB7' : '#9c9b95', fontWeight: step === i + 1 ? 500 : 400 }}>{label}</span>
                {i < 2 && <div style={{ width: 20, height: 1, background: '#e5e4df' }} />}
              </div>
            ))}
          </div>
        </div>

        <div style={{ padding: '0 24px 24px' }}>
          {/* PASO 1: Elegir modo */}
          {step === 1 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <button onClick={() => { setModo('puntos'); setStep(2); }} style={{
                padding: 20, border: `2px solid ${modo === 'puntos' ? '#534AB7' : '#e5e4df'}`,
                borderRadius: 14, background: modo === 'puntos' ? '#EEEDFE' : 'white',
                cursor: 'pointer', textAlign: 'left', transition: 'all 0.15s',
              }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>📍</div>
                <div style={{ fontWeight: 600, fontSize: 14, color: '#2c2c2a', marginBottom: 4 }}>Seleccionar puntos</div>
                <div style={{ fontSize: 12, color: '#888780' }}>Elegí atracciones o zonas como paradas. El sistema conecta los puntos automáticamente.</div>
              </button>
              <button onClick={() => { setModo('dibujar'); setStep(2); }} style={{
                padding: 20, border: `2px solid ${modo === 'dibujar' ? '#1D9E75' : '#e5e4df'}`,
                borderRadius: 14, background: modo === 'dibujar' ? '#E1F5EE' : 'white',
                cursor: 'pointer', textAlign: 'left', transition: 'all 0.15s',
              }}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>✏️</div>
                <div style={{ fontWeight: 600, fontSize: 14, color: '#2c2c2a', marginBottom: 4 }}>Dibujar en el mapa</div>
                <div style={{ fontSize: 12, color: '#888780' }}>Trazá la ruta directamente sobre el mapa con total libertad.</div>
              </button>
            </div>
          )}

          {/* PASO 2: Puntos */}
          {step === 2 && modo === 'puntos' && (
            <div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
                {puntos.map((p, i) => (
                  <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                    <div style={{
                      width: 28, height: 28, borderRadius: '50%', flexShrink: 0,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 12, fontWeight: 700,
                      background: i === 0 ? '#E1F5EE' : i === puntos.length - 1 ? '#FCEBEB' : '#EEEDFE',
                      color: i === 0 ? '#0F6E56' : i === puntos.length - 1 ? '#A32D2D' : '#3C3489',
                    }}>
                      {i === 0 ? 'O' : i === puntos.length - 1 ? 'D' : i}
                    </div>
                    <select
                      value={p.tipo}
                      onChange={e => updatePunto(i, 'tipo', e.target.value)}
                      style={{ padding: '7px 10px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 12, background: 'white', color: '#5f5e5a' }}
                    >
                      <option value="atraccion">Atracción</option>
                      <option value="zona">Zona</option>
                    </select>
                    <select
                      value={p.id}
                      onChange={e => updatePunto(i, 'id', e.target.value)}
                      style={{ flex: 1, padding: '7px 10px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 12, background: 'white', color: p.id ? '#2c2c2a' : '#9c9b95' }}
                    >
                      <option value="">Seleccionar...</option>
                      {getOpcionesPunto(p.tipo).map(op => (
                        <option key={op.value} value={op.value}>{op.label}</option>
                      ))}
                    </select>
                    {i !== 0 && i !== puntos.length - 1 && (
                      <button onClick={() => removePunto(i)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#E24B4A', fontSize: 18, padding: 4 }}>×</button>
                    )}
                  </div>  
                ))}
              </div>
              {puntos.length > 2 && (
                <button onClick={() => optimizado ? setOptimizado(false) : optimizarOrden()} style={{
                  width: '100%', padding: '10px', border: '1.5px solid #534AB7',
                  borderRadius: 10, background: optimizado ? '#534AB7' : '#EEEDFE', cursor: 'pointer',
                  fontSize: 13, color: optimizado ? 'white' : '#534AB7', fontWeight: 600, marginBottom: 8,
                }}>
                  {optimizado ? '✅ Orden optimizado' : '✨ Optimizar orden'}
                </button>
              )}
              <button onClick={addPunto} style={{
                width: '100%', padding: '10px', border: '1.5px dashed #d3d1c7',
                borderRadius: 10, background: 'none', cursor: 'pointer',
                fontSize: 13, color: '#888780', marginBottom: 16,
              }}>
                + Agregar parada intermedia
              </button>
              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={() => setStep(1)} style={{ flex: 1, padding: '10px', border: '1px solid #e5e4df', borderRadius: 10, background: 'white', cursor: 'pointer', fontSize: 13, color: '#5f5e5a' }}>Atrás</button>
                <button
                  onClick={() => puntosCompletos && setStep(3)}
                  disabled={!puntosCompletos}
                  style={{ flex: 2, padding: '10px', border: 'none', borderRadius: 10, background: puntosCompletos ? '#534AB7' : '#e5e4df', color: puntosCompletos ? 'white' : '#9c9b95', cursor: puntosCompletos ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600 }}
                >
                  Continuar →
                </button>
              </div>
            </div>
          )}

          {/* PASO 2: Dibujar (solo formulario, el dibujo se hace en mapa) */}
          {step === 2 && modo === 'dibujar' && (
            <div>
              <div style={{ padding: 16, background: '#E1F5EE', borderRadius: 10, marginBottom: 16, fontSize: 13, color: '#0F6E56' }}>
                ✏️ Completá los datos y hacé click en <strong>Continuar</strong> para dibujar la ruta en el mapa.
              </div>
              <FormRecorrido form={form} onChange={handleForm} />
              <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
                <button onClick={() => setStep(1)} style={{ flex: 1, padding: '10px', border: '1px solid #e5e4df', borderRadius: 10, background: 'white', cursor: 'pointer', fontSize: 13, color: '#5f5e5a' }}>Atrás</button>
                <button
                  onClick={() => formValido && handleCrear()}
                  disabled={!formValido}
                  style={{ flex: 2, padding: '10px', border: 'none', borderRadius: 10, background: formValido ? '#1D9E75' : '#e5e4df', color: formValido ? 'white' : '#9c9b95', cursor: formValido ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600 }}
                >
                  ✏️ Ir a dibujar
                </button>
              </div>
            </div>
          )}

          {/* PASO 3: Formulario (solo para modo puntos) */}
          {step === 3 && modo === 'puntos' && (
            <div>
              <div style={{ padding: 16, background: '#EEEDFE', borderRadius: 10, marginBottom: 16, fontSize: 13, color: '#3C3489' }}>
                📍 <strong>{puntos.length} puntos</strong> seleccionados. La ruta se generará automáticamente.
              </div>
              <FormRecorrido form={form} onChange={handleForm} />
              <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
                <button onClick={() => setStep(2)} style={{ flex: 1, padding: '10px', border: '1px solid #e5e4df', borderRadius: 10, background: 'white', cursor: 'pointer', fontSize: 13, color: '#5f5e5a' }}>Atrás</button>
                <button
                  onClick={() => formValido && handleCrear()}
                  disabled={!formValido}
                  style={{ flex: 2, padding: '10px', border: 'none', borderRadius: 10, background: formValido ? '#534AB7' : '#e5e4df', color: formValido ? 'white' : '#9c9b95', cursor: formValido ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600 }}
                >
                  Crear recorrido
     </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function FormRecorrido({ form, onChange }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {[
        { key: 'nombre', label: 'Nombre del recorrido', placeholder: 'Ej: Tour Histórico Ciudad Vieja' },
        { key: 'guiaResponsable', label: 'Guía responsable', placeholder: 'Nombre del guía' },
        { key: 'duracionEstimada', label: 'Duración estimada', placeholder: 'Ej: 3 horas' },
      ].map(f => (
        <div key={f.key}>
          <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>{f.label}</label>
          <input
            type="text"
            value={form[f.key] || ''}
            onChange={e => onChange(f.key, e.target.value)}
            placeholder={f.placeholder}
            style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none', color: '#2c2c2a' }}
          />
        </div>
      ))}
      <div>
        <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Descripción</label>
        <textarea
          value={form.descripcion || ''}
          onChange={e => onChange('descripcion', e.target.value)}
          placeholder="Descripción del recorrido..."
          rows={3}
          style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none', resize: 'vertical', color: '#2c2c2a' }}
        />
      </div>
      <div>
        <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Tipo de experiencia</label>
        <select
          value={form.tipoExperiencia}
          onChange={e => onChange('tipoExperiencia', e.target.value)}
          style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, background: 'white', color: '#2c2c2a' }}
        >
          <option value="cultural">🏛️ Cultural</option>
          <option value="gastronomica">🍷 Gastronómica</option>
          <option value="natural">🌿 Natural</option>
          <option value="historica">📜 Histórica</option>
        </select>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <div>
          <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Mes inicio</label>
          <select
            value={form.estacionInicio}
            onChange={e => onChange('estacionInicio', parseInt(e.target.value))}
            style={{ width: '100%', padding: '9px 10px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 12, background: 'white', color: '#2c2c2a' }}
          >
            {['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'].map((m, i) => (
              <option key={i} value={i + 1}>{m}</option>
            ))}
          </select>
        </div>
        <div>
          <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Mes fin</label>
          <select
            value={form.estacionFin}
            onChange={e => onChange('estacionFin', parseInt(e.target.value))}
            style={{ width: '100%', padding: '9px 10px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 12, background: 'white', color: '#2c2c2a' }}
          >
            {['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'].map((m, i) => (
              <option key={i} value={i + 1}>{m}</option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
}
