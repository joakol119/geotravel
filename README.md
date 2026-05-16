# GeoTravel - TSIG 2026 1er Semestre

Sistema de gestión de recorridos turísticos con información geográfica.

## Estructura del proyecto

```
geotravel/
├── docker-compose.yml          ← Levanta todo con un solo comando
├── README.md
├── db/
│   └── schema.sql              ← Se ejecuta automáticamente al crear el contenedor
├── backend/
│   ├── Dockerfile              ← Maven build + Tomcat 10.1
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/geotravel/
│       │   ├── config/         ← CorsFilter, DatabaseConnection
│       │   ├── model/          ← Recorrido (y demás entidades)
│       │   ├── service/        ← Lógica + consultas PostGIS
│       │   └── controller/     ← API REST (JAX-RS)
│       └── webapp/WEB-INF/web.xml
└── frontend/
    ├── Dockerfile              ← React dev server
    ├── package.json
    ├── public/index.html
    └── src/
        ├── App.jsx             ← Mapa Leaflet + sidebar
        ├── index.js
        ├── components/
        └── styles/index.css
```

## Levantar con Docker (recomendado)

```bash
# Desde la carpeta raíz del proyecto
docker compose up --build
```

Eso levanta 4 servicios:

| Servicio | Puerto | URL |
|----------|--------|-----|
| PostgreSQL + PostGIS | 5432 | `localhost:5432` (user: postgres, pass: postgres) |
| GeoServer | 8081 | http://localhost:8081/geoserver (admin / geoserver) |
| Backend (Tomcat) | 8080 | http://localhost:8080/api/recorridos |
| Frontend (React) | 3000 | http://localhost:3000 |

El `schema.sql` se ejecuta automáticamente la primera vez que levanta el contenedor de la base de datos (crea tablas, índices y datos de ejemplo).

### Comandos útiles

```bash
# Levantar en background
docker compose up -d --build

# Ver logs de un servicio
docker compose logs -f backend

# Parar todo
docker compose down

# Parar y borrar volúmenes (resetea la base de datos)
docker compose down -v

# Recompilar solo el backend después de cambios
docker compose up -d --build backend

# Conectarse a la base de datos
docker compose exec db psql -U postgres -d geotravel
```

## Levantar sin Docker

### 1. Base de datos
Instalar PostgreSQL + PostGIS, luego:
```bash
psql -U postgres -c "CREATE DATABASE geotravel;"
psql -U postgres -d geotravel -f db/schema.sql
```

### 2. Backend
Cambiar `DB_HOST` a `localhost` en DatabaseConnection.java, luego:
```bash
cd backend
mvn clean package
cp target/geotravel.war $CATALINA_HOME/webapps/
```

### 3. Frontend
```bash
cd frontend
npm install
npm start
```

## API REST

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/recorridos` | Listar (filtros: `?estado=disponible&tipo=cultural`) |
| GET | `/api/recorridos/{id}` | Obtener por ID |
| POST | `/api/recorridos` | Crear nuevo |
| GET | `/api/recorridos/zona/{zonaId}` | Recorridos dentro de una zona |
| GET | `/api/recorridos/cercano?lng=X&lat=Y` | Más cercano a un punto |

## Stack

| Capa | Tecnología |
|------|-----------|
| Base de datos | PostgreSQL 16 + PostGIS 3.4 |
| Servidor de mapas | GeoServer 2.25 |
| Backend | JEE (JAX-RS/Jersey) + Tomcat 10.1 |
| Frontend | React 18 + Leaflet 1.9 |
