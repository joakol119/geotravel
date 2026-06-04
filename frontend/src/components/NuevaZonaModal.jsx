import React, { useState } from 'react';

const NIVELES = [
  { value: 1, label: '⭐⭐⭐⭐⭐', desc: 'Máximo atractivo' },
  { value: 2, label: '⭐⭐⭐⭐', desc: 'Alto atractivo' },
  { value: 3, label: '⭐⭐⭐', desc: 'Atractivo medio' },
  { value: 4, label: '⭐⭐', desc: 'Atractivo bajo' },
  { value: 5, label: '⭐', desc: 'Atractivo mínimo' },
];

export default function NuevaZonaModal({ onDibujar, onCancel, editando }) {
  const [form, setForm] = useState({
    nombre: editando?.nombre || '',
    descripcion: editando?.descripcion || '',
    nivelAtractivo: editando?.nivelAtractivo || 1,
    observaciones: editando?.observaciones || '',
  });

  const handleForm = (k, v) => setForm(p => ({ ...p, [k]: v }));
  const formValido = form.nombre && form.nivelAtractivo;

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
              {editando ? 'Editar zona' : 'Nueva zona turística'}
            </h2>
            <button onClick={onCancel} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 22, color: '#888780', padding: 4 }}>×</button>
          </div>
          <p style={{ margin: '4px 0 20px', fontSize: 13, color: '#888780' }}>
            {editando ? 'Editá los datos de la zona o redibujá su geometría' : 'Completá los datos y dibujá el área en el mapa'}
          </p>
        </div>

        <div style={{ padding: '0 24px 24px' }}>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>

            {/* Nombre */}
            <div>
              <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Nombre de la zona</label>
              <input type="text" value={form.nombre} onChange={e => handleForm('nombre', e.target.value)}
                placeholder="Ej: Ciudad Vieja, Pocitos..."
                style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none', color: '#2c2c2a' }} />
            </div>

            {/* Nivel de atractivo */}
            <div>
              <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Nivel de atractivo</label>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {NIVELES.map(n => (
                  <button key={n.value} onClick={() => handleForm('nivelAtractivo', n.value)} style={{
                    padding: '10px 14px', border: `1.5px solid ${form.nivelAtractivo === n.value ? '#534AB7' : '#e5e4df'}`,
                    borderRadius: 10, background: form.nivelAtractivo === n.value ? '#EEEDFE' : 'white',
                    cursor: 'pointer', textAlign: 'left', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                    transition: 'all 0.15s',
                  }}>
                    <span style={{ fontSize: 12, color: form.nivelAtractivo === n.value ? '#3C3489' : '#5f5e5a', fontWeight: form.nivelAtractivo === n.value ? 600 : 400 }}>
                      Nivel {n.value} — {n.desc}
                    </span>
                    <span style={{ fontSize: 13 }}>{n.label}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Descripción */}
            <div>
              <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Descripción</label>
              <textarea value={form.descripcion} onChange={e => handleForm('descripcion', e.target.value)}
                placeholder="Descripción de la zona turística..."
                rows={3}
                style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none', resize: 'vertical', color: '#2c2c2a' }} />
            </div>

            {/* Observaciones */}
            <div>
              <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#5f5e5a', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.4px' }}>Observaciones</label>
              <textarea value={form.observaciones} onChange={e => handleForm('observaciones', e.target.value)}
                placeholder="Notas adicionales..."
                rows={2}
                style={{ width: '100%', padding: '9px 12px', border: '1px solid #e5e4df', borderRadius: 8, fontSize: 13, boxSizing: 'border-box', outline: 'none', resize: 'vertical', color: '#2c2c2a' }} />
            </div>

          </div>

          {/* Botones */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 20 }}>
            <button
              onClick={() => formValido && onDibujar(form)}
              disabled={!formValido}
              style={{ width: '100%', padding: '12px', border: 'none', borderRadius: 10, background: formValido ? '#534AB7' : '#e5e4df', color: formValido ? 'white' : '#9c9b95', cursor: formValido ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600 }}
            >
              ✏️ {editando ? 'Redibujar en el mapa' : 'Dibujar zona en el mapa'}
            </button>
            <button onClick={onCancel} style={{ width: '100%', padding: '10px', border: '1px solid #e5e4df', borderRadius: 10, background: 'white', cursor: 'pointer', fontSize: 13, color: '#5f5e5a' }}>
              Cancelar
            </button>
          </div>

        </div>
      </div>
    </div>
  );
}
