# Planify Mobile

Aplicación Flutter de Planify.

## Ejecutar en desarrollo

Desde esta carpeta:

```powershell
flutter pub get
flutter run --dart-define=PLANIFY_API_BASE_URL=http://192.168.137.1:8000
```

Inicia el backend desde `C:\planify` con `npm run start:dev`. El backend debe
tener su conexión MySQL configurada en su propio `.env`; no copies ese archivo
ni sus credenciales a la aplicación. El teléfono y el equipo deben estar en la
misma red y el firewall debe permitir el puerto `8000`.

La IP `192.168.137.1` corresponde a la conexión local usada durante esta
configuración. Si cambia la red, reemplázala por la IPv4 del equipo. Para el
emulador Android usa `http://10.0.2.2:8000`.

El registro envía `identificacion`, `nombres`, `apellidos`, `email` y `password`
a `POST /auth/register`. El permiso HTTP sin cifrar está habilitado únicamente
en compilaciones de depuración; una versión de producción debe usar HTTPS.
