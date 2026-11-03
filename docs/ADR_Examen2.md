# Decisiones técnicas del Examen 2 (continuación de los ADR-001 a ADR-006)

Los ADR-001 a ADR-006 (Flutter, SQLite, OTP, cámara, Supabase, modo sin conexión) están en el Anexo F de [`FinTrack_Segunda_Entrega.md`](FinTrack_Segunda_Entrega.md). Este archivo continúa la numeración con lo decidido al construir el prototipo. Formato de Nygard (2011), como en la entrega anterior.

## ADR-007: Provider con un único `ChangeNotifier` en lugar de Riverpod

- **Estado:** aceptado · **Fecha:** 2-nov-2026
- **Contexto:** la segunda entrega proponía `flutter_riverpod`. El prototipo tiene un solo modelo de estado compartido (movimientos, activos, límites y ajustes) y ninguna dependencia entre proveedores.
- **Decisión:** `AppState` (`lib/state/app_state.dart`) es un `ChangeNotifier` publicado con `provider`. Hace de *ViewModel*: calcula saldos, estadísticas, límites y avisos; las vistas solo lo leen con `watch`/`read`.
- **Alternativas:** Riverpod (más ceremonia para un solo estado); `setState` en cada pantalla (mezclaría reglas de negocio con la interfaz, lo que la rúbrica pide evitar).
- **Consecuencias:** menos código y dependencias. Si el estado crece (sincronización con Supabase), conviene dividir `AppState` o migrar a Riverpod.

## ADR-008: `image_picker` en lugar de `camera`

- **Estado:** aceptado · **Fecha:** 2-nov-2026
- **Contexto:** el tiquete solo necesita una foto, no una vista previa propia de la cámara.
- **Decisión:** `image_picker` abre la cámara o la galería del sistema; la imagen se copia a la carpeta de documentos de la app (`path_provider`) y la base guarda solo la ruta.
- **Consecuencias:** la pantalla de captura es la de Android (el permiso lo pide el sistema; si se rechaza, la app avisa y deja guardar el gasto sin tiquete). No hay control de enfoque ni recorte propio. Al eliminar un movimiento la foto queda en el teléfono (limitación conocida, ver punto 7 del informe).

## ADR-009: cuenta local con contraseña con sal y SHA-256

- **Estado:** aceptado hasta que llegue Supabase · **Fecha:** 2-nov-2026
- **Contexto:** el prototipo no tiene servidor; aun así el flujo de crear cuenta e iniciar sesión es parte del diseño.
- **Decisión:** nombre, correo y contraseña se guardan en `SharedPreferences`; la contraseña nunca se guarda en claro (sal + SHA-256 con `crypto`).
- **Consecuencias:** sirve para separar sesión y datos en el teléfono, pero **no protege** contra quien tenga acceso al dispositivo desbloqueado y no permite recuperar la contraseña. La recuperación por OTP queda para el siguiente incremento, con Supabase (ADR-003 y ADR-005).

## ADR-010: sin geolocalización

- **Estado:** aceptado · **Fecha:** 2-nov-2026
- **Contexto:** la rúbrica pide al menos una capacidad móvil y menciona la geolocalización como ejemplo.
- **Decisión:** no se usa ubicación. Las capacidades elegidas son cámara + almacenamiento (evidencia del tiquete), vibración (confirmación sin mirar) y conectividad (informar el estado de red).
- **Justificación:** anotar un gasto no necesita saber dónde ocurrió; pedir ubicación añade un permiso sensible y consumo de batería sin resolver una necesidad del proyecto.
- **Consecuencias:** no se puede sugerir comercios cercanos ni agrupar gastos por lugar. Se reevaluaría solo si un requisito futuro lo exige.

## ADR-011: regla automática para el gasto hormiga

- **Estado:** aceptado · **Fecha:** 2-nov-2026
- **Contexto:** etiquetar a mano cada gasto como «hormiga» agrega un toque al registro.
- **Decisión:** al guardar, un gasto de hasta $20.000 se clasifica como **hormiga**; Hogar, Educación, Salud y Teléfono como **fijo**; el resto como **necesario** (`classify` en `lib/models/models.dart`, con prueba en `test/widget_test.dart`).
- **Consecuencias:** el umbral es una suposición del equipo, no un dato medido; un gasto grande y frecuente no se marca como hormiga. Hacerlo configurable queda como mejora.
