# Planify Mobile

Aplicación Flutter de Planify.

## Ejecutar en desarrollo

Desde esta carpeta, conecta el teléfono por USB y autoriza la depuración USB:

```powershell
flutter pub get
adb reverse tcp:8000 tcp:8000
flutter run
```

Inicia el backend desde `C:\planify` con `npm run start:dev`. El backend debe
tener su conexión MySQL configurada en su propio `.env`; no copies ese archivo
ni sus credenciales a la aplicación. Mantén el teléfono conectado por USB
mientras usas la aplicación. El puente ADB evita depender de la red Wi-Fi o de
una regla de entrada en el firewall.

Para usar Wi-Fi, compila con `--dart-define=PLANIFY_API_BASE_URL=http://<IPv4-del-equipo>:8000`;
el teléfono debe poder acceder al puerto `8000` del equipo. Para el emulador
Android usa `http://10.0.2.2:8000`.

Si ejecutas la app desde VS Code, ejecuta `adb reverse tcp:8000 tcp:8000`
después de conectar el dispositivo. El puente se pierde al desconectar el USB.

El valor de `PLANIFY_API_BASE_URL` se incorpora al paquete durante la
compilación; recompila la app si cambias la dirección.

El registro envía `identificacion`, `nombres`, `apellidos`, `email` y `password`
a `POST /auth/register`. El permiso HTTP sin cifrar está habilitado únicamente
en compilaciones de depuración; una versión de producción debe usar HTTPS.

La pantalla **Crear Actividad** guarda actividades autenticadas en
`POST /activities`, y la pantalla principal consulta `GET /activities` para
mostrar las próximas ordenadas por la hora del recordatorio. La descripción es
opcional; las prioridades válidas son `Alta`, `Media` y `Baja`, y los intervalos
de recordatorio son 15, 25, 35, 45 o 60 minutos.

Desde el menú de tres puntos de cada actividad próxima se puede editar sus
datos o eliminarla tras confirmar la acción. Al editar fecha, hora o
recordatorio, el backend actualiza de forma atómica el recordatorio asociado.
