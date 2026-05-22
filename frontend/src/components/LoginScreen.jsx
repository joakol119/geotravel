import React, { useState } from 'react';
import { login, setToken } from '../data/api';

export default function LoginScreen({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleLogin() {
    setError('');
    setLoading(true);
    const result = await login(email, password);
    setLoading(false);
    if (result && result.token) {
      setToken(result.token);
      onLogin();
    } else {
      setError('Email o contraseña incorrectos');
    }
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter') handleLogin();
  }

  return (
    <div style={{
      position: 'fixed', inset: 0,
      background: '#f1efe8',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 9999
    }}>
      <div style={{
        background: 'white', borderRadius: 16, padding: 40,
        width: 360, boxShadow: '0 4px 24px rgba(0,0,0,0.10)'
      }}>
        <h2 style={{ margin: '0 0 8px', fontSize: 22, fontWeight: 500, color: '#2c2c2a' }}>
          GeoTravel
        </h2>
        <p style={{ margin: '0 0 28px', fontSize: 14, color: '#888780' }}>
          Acceso para administradores
        </p>

        <label style={{ display: 'block', fontSize: 12, fontWeight: 600, marginBottom: 4, color: '#5f5e5a' }}>
          Email
        </label>
        <input
          type="email"
          value={email}
          onChange={e => setEmail(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="admin@geotravel.com"
          style={{
            width: '100%', padding: '10px 12px', marginBottom: 16,
            border: '1px solid #d3d1c7', borderRadius: 8, fontSize: 14,
            boxSizing: 'border-box', outline: 'none'
          }}
        />

        <label style={{ display: 'block', fontSize: 12, fontWeight: 600, marginBottom: 4, color: '#5f5e5a' }}>
          Contraseña
        </label>
        <input
          type="password"
          value={password}
          onChange={e => setPassword(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="••••••••"
          style={{
            width: '100%', padding: '10px 12px', marginBottom: 8,
            border: '1px solid #d3d1c7', borderRadius: 8, fontSize: 14,
            boxSizing: 'border-box', outline: 'none'
          }}
        />

        {error && (
          <p style={{ margin: '0 0 12px', fontSize: 13, color: '#E24B4A' }}>{error}</p>
        )}

        <button
          onClick={handleLogin}
          disabled={loading}
          style={{
            width: '100%', padding: '11px 0', marginTop: 8,
            background: '#534AB7', color: 'white', border: 'none',
            borderRadius: 8, fontSize: 15, fontWeight: 600,
            cursor: loading ? 'not-allowed' : 'pointer',
            opacity: loading ? 0.7 : 1
          }}
        >
          {loading ? 'Ingresando...' : 'Ingresar'}
        </button>

        <p style={{ margin: '20px 0 0', fontSize: 13, color: '#888780', textAlign: 'center' }}>
          ¿No sos admin?{' '}
          <span
            onClick={() => onLogin('invitado')}
            style={{ color: '#534AB7', cursor: 'pointer', fontWeight: 500 }}
          >
            Entrar como invitado
          </span>
        </p>
      </div>
    </div>
  );
}
