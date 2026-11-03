# FinTrack: aplicación móvil para la gestión de gastos hormiga
## Segundo incremento · Prototipo móvil funcional (Examen 2)

**Integrantes:** Juan Sebastián Martínez Galeano, Cesar Ocampo Raigosa y Samuel Usma Brand
**Asignatura:** Desarrollo de Aplicaciones Móviles
**Docente:** Ing. Neider Xavier Vergara Humánez
**Institución:** Corporación Universitaria Lasallista
**Fecha:** noviembre de 2026
**Dispositivo de prueba:** Xiaomi Redmi Note 13 Pro 5G (pantalla 1220 × 2712), compilación *debug*

---

## 0. Introducción | Pequeños gastos, **grandes fugas**.

FinTrack es una aplicación para Android que funciona como un cuaderno personal de gastos e ingresos: permite anotar en segundos los gastos pequeños y frecuentes, ver cuánto suman y recibir un aviso antes de pasar un límite propio. No pretende ser una herramienta de control financiero avanzado ni de uso empresarial.

### El problema

Los gastos hormiga son desembolsos de bajo valor y alta frecuencia que pasan inadvertidos y reducen la capacidad de ahorro (Roldán, 2017; CONDUSEF, 2024). Como la gotera que vacía un balde, cada gasto parece insignificante, pero su repetición vacía el presupuesto. El problema no es un consumo aislado, sino la **falta de visibilidad sobre su repetición, su categoría y su impacto acumulado**.

### La población

La población principal son jóvenes y estudiantes universitarios mayores de 18 años, que empiezan a administrar ingresos propios o variables con poca experiencia financiera.

> **Dato:** 44 % | de los jóvenes colombianos no ahorró en los últimos 12 meses (CAF, 2019, citado por Konietzko, 2023).

> **Dato:** 58 % | no podría cubrir un gasto imprevisto sin un préstamo o ayuda (CAF, 2019, citado por Konietzko, 2023).

En una encuesta a 417 personas de la IU Digital de Antioquia (81,5 % estudiantes), 22,06 % gasta en cosas innecesarias siempre o casi siempre y 52,52 % a veces; 18,23 % nunca o casi nunca llega a fin de mes sin deudas y 19,4 % no ahorra (Gallego Palacio et al., 2023).

### Objetivo del incremento

Convertir el diseño del Examen 1 (prototipo en Figma y planificación de la segunda entrega) en un **prototipo móvil funcional** que se ejecute en un Android físico, guarde los datos en el teléfono y use capacidades propias del dispositivo. El flujo que guía la app es **registrar → clasificar → comprender → decidir**.

> **Nota:** Este informe describe lo que hace el código actual de `fintrack_app/lib`. Lo que aún no está construido se declara en los puntos 7 y 8.

## 1. Funcionalidades implementadas | Lo que la app **ya hace** en el teléfono.

La aplicación está hecha en Flutter (Dart) con arquitectura por capas: **vistas** (`views/`), **estado** (`AppState`, un `ChangeNotifier` publicado con Provider, en el papel de *ViewModel*), **servicios** (SQLite, preferencias y PDF) y **modelos**. Todo funciona sin servidor.

| Módulo | Qué hace |
|---|---|
| Arranque y cuenta | Splash con el gato; guía de 3 pasos (se puede omitir); bienvenida; crear cuenta e iniciar sesión con cuenta local; elección de «dónde guardar» (solo en el teléfono; la nube aparece como «Próximamente»); cerrar sesión. |
| Inicio | Saldo disponible, accesos «Añadir dinero» y «Añadir gasto», resumen semanal con gráfico de área y variación frente a la semana anterior, equivalencia «dinero invisible» del gasto hormiga (en cafés de $2.500 o almuerzos de $12.000) y los 5 movimientos más recientes. |
| Registro | Botón central «+»; tipo Ingreso/Gasto; 11 categorías de gasto y 5 de ingreso; fecha; teclado numérico propio (tecla «000»); montos rápidos de un toque ($2.000, $5.000, $10.000); nota; tiquete adjunto por cámara o galería; vibración al guardar. |
| Clasificación | Automática al guardar: gasto ≤ $20.000 = **hormiga**; Hogar, Educación, Salud y Teléfono = **fijo**; el resto = **necesario**. |
| Historial | Movimientos agrupados por día con pestañas Todos/Ingresos/Gastos y filtro por categoría en tiempo real (chips); detalle con nota, foto del tiquete y fecha; editar y eliminar con confirmación. |
| Estadísticas | Semana/Mes/Año, gastos o ingresos: dona fijo/necesario/hormiga, ingresos, gastos, balance y principales categorías. |
| Límites y avisos | Límite hormiga semanal ($50.000) y mensual ($150.000) por defecto, más límites por categoría; pausa de «fricción consciente» (diálogo «¿Seguro?») antes de guardar un gasto que supera un límite; aviso al registrar si se llega al 90 %; centro de notificaciones con avisos sin leer/leídos (hormiga de la semana, «vas por buen camino», límite al 80 % o superado). |
| Informe | Patrimonio neto (activos − pasivos + saldo); activos y pasivos; PDF tipo extracto bancario A4 por semana, mes o año, con visor y botón «Compartir». |
| Datos y ajustes | Exportar e importar una copia JSON; perfil, datos personales y eliminar cuenta; acerca de y política de privacidad; modo oscuro; avisos configurables; estados de carga, vacío, error y sin conexión con ilustraciones. |

## 2. Cambios respecto al diseño del Examen 1 | Qué **se mantuvo** y qué cambió.

El diseño de referencia es el prototipo de Figma (más de 60 pantallas) y los requisitos RF-01 a RF-18 de la segunda entrega.

| Decisión | Elemento | Detalle |
|---|---|---|
| Mantiene | Flujo y pantallas principales | Splash, guía, cuenta, inicio, agregar, monto, gasto registrado, movimientos, detalle, estadísticas, informe, límites, perfil y ajustes siguen el prototipo y su paleta ámbar. |
| Mantiene | RF-05 a RF-10, RF-12 a RF-14, RF-17 (modo oscuro) | Registro, categorías, historial, tablero, límites, PDF, háptica y exportar/importar. |
| Ajustó | Estado: Riverpod → **Provider** | Un solo `ChangeNotifier` basta para el tamaño actual de la app. |
| Ajustó | Cámara: paquete *camera* → **image_picker** | Usa la cámara o la galería del sistema; menos código y permite elegir una foto ya tomada. |
| Ajustó | Cuenta con servidor → **cuenta local** | Nombre, correo y contraseña con sal + SHA-256 en el teléfono, mientras llega Supabase. |
| Ajustó | Etiqueta «Hormiga» manual → **regla automática** | Umbral de $20.000 y categorías fijas definidas en `models.dart`. |
| Ajustó | Teclado de monto y tipografía | La tecla «.» pasó a «000» (pesos sin decimales); la app usa Roboto en lugar de Inter. |
| Aplazó | OTP, nube y notificaciones del sistema | RF-03, RF-15 y RF-18 quedan para el siguiente incremento (punto 8); la app muestra un aviso donde corresponden. |
| Aplazó | Moneda, idioma, filtros y nueva categoría | Las hojas existen, pero solo COP y español están activos; no hay categorías personalizadas. |
| Agregó | Montos rápidos, «dinero invisible» y fricción consciente | Tomados de la propuesta de ajustes del segundo avance: menos toques al registrar, cifras traducidas a cosas cotidianas y una pausa antes de pasar un límite. |
| Descartó | Geolocalización y geocercas | Se evita pedir el permiso de ubicación: rastrear al usuario no es necesario para anotar gastos y consume batería. |
| Descartó | OCR del tiquete | Ya estaba fuera de alcance en el Examen 1: el tiquete se guarda como imagen, sin leer su texto. |

## 3. Flujo implementado | De la primera apertura al **informe en PDF**.

<!-- flujo -->

1. **Arranque.** El splash dura 1,5 s y decide según las preferencias guardadas: con sesión abierta va al inicio; si ya se vio la guía, a la bienvenida; si no, a la guía de 3 pasos.
2. **Cuenta.** Crear cuenta valida nombre, correo con «@» y contraseña de 6 o más caracteres; después se elige dónde guardar y se entra al inicio. Iniciar sesión compara el correo y el hash guardados.
3. **Registro de un gasto.** «+» → elegir Gasto y categoría → fecha → Continuar → monto con el teclado, nota y tiquete opcional → «Guardar gasto». La app vibra, clasifica el gasto, lo inserta en SQLite, recarga el estado y muestra «¡Gasto registrado!», con aviso si el límite relacionado llegó al 90 %.
4. **Consulta.** El inicio y las estadísticas se recalculan solos (Provider notifica a las vistas). Desde «Ver más» se abre Movimientos; al tocar un movimiento, su detalle permite editar o eliminar.
5. **Decisión.** Límites de gasto y notificaciones muestran cuánto se lleva frente a cada límite; Informe genera el PDF del periodo, lo guarda en el teléfono y lo abre en el visor para compartirlo.

## 4. Persistencia utilizada | Tres capas de datos, **todas en el teléfono**.

| Mecanismo | Qué guarda | Implementación |
|---|---|---|
| **SQLite** (*sqflite*, s. f.) | Movimientos (monto, ingreso/gasto, categoría, clase, nota, fecha, ruta del tiquete), activos y pasivos, límites | Base `fintrack.db` versión 2 con tablas `movements`, `assets` y `limits` (`database_helper.dart`). Al crearla inserta los dos límites hormiga por defecto. |
| **SharedPreferences** | Cuenta local (nombre, correo, sal y hash SHA-256), sesión abierta, guía vista, modo oscuro, avisos hormiga, aviso al 80 %, recordatorio y notificaciones leídas | `preferences_service.dart`; la contraseña nunca se guarda en texto plano. |
| **Archivos** (*path_provider*) | Fotos de tiquetes, informes PDF y copia de respaldo | En la carpeta de documentos de la app: `tiquete_<milisegundos>.jpg`, `Informe_<mes>.pdf` (o `Informe_semana_<fecha>.pdf`, `Informe_<año>.pdf`) y `fintrack_respaldo.json`. |

Todas las escrituras pasan por `AppState`, que guarda en SQLite y vuelve a leer la base, de modo que la interfaz siempre muestra lo que quedó persistido. La copia JSON guarda movimientos, activos y límites; al importarla, la app pide confirmación y reemplaza los datos actuales. **Prueba de persistencia:** con tres movimientos registrados (saldo $ 91.500), se forzó el cierre de la app (`am force-stop`) y al abrirla de nuevo la sesión, el saldo y los mismos movimientos seguían ahí (capturas 17 y 18).

## 5. Capacidad móvil integrada | La cámara convierte el tiquete en **evidencia**.

**Cámara y galería (principal).** En la pantalla Monto, «Adjuntar tiquete» abre una hoja con «Escanear con la cámara» y «Elegir de la galería» (*image_picker*, calidad 75 %, ancho máximo 1600 px). La foto se copia a la carpeta privada de la app y su ruta se guarda en el movimiento; el detalle muestra la imagen. **Necesidad que resuelve:** el estudiante pierde los tiquetes de papel y olvida qué compró; con la foto asociada conserva el comprobante digital (RF-11) y puede revisar después en qué se fue el dinero.

**Capacidades de apoyo.**

- **Vibración háptica** (`HapticFeedback.mediumImpact`) al guardar: confirma el registro sin mirar la pantalla (RF-13).
- **Conectividad** (*connectivity_plus*): escucha los cambios de red; sin red, la cabecera muestra «Sin conexión» y lleva a una pantalla que explica que los datos siguen guardados en el teléfono.
- **Compartir archivos** (*printing*): el PDF del informe se abre en un visor y se envía con la hoja de compartir de Android.

## 6. Evidencia de ejecución en Android | Probado en un **Xiaomi real**.

La app se instaló con `flutter run` (compilación *debug*) en un **Xiaomi Redmi Note 13 Pro 5G** (pantalla 1220 × 2712) conectado por USB. La sección «Demostración visual» reúne 22 capturas tomadas en ese teléfono con el usuario de prueba «Samuel Usma»: arranque (01–05), registro y consulta (06–13), cámara (08a–08b), PDF (14–16), persistencia (17–18), límites y modo oscuro (19–20). Datos de la demo: un ingreso «Pago monitoria» de $ 120.000 (Trabajo) y dos gastos, «Cafe con Ana» de $ 3.500 (Alimentos, hormiga, con tiquete) y «Taxi a la u» de $ 25.000 (Transporte, necesario); saldo de $ 91.500 y $ 28.500 gastados en la semana. Las pruebas de tiempo y accesibilidad (arranque en frío 2,5 s en *debug*, registro de un gasto con montos rápidos en ~2,5 s con pausas de la prueba, 15 de 15 contrastes WCAG AA, objetivos táctiles de 48 dp corregidos tras la medición) están en `docs/pruebas/PRUEBAS.md`, con sus gráficas; la fluidez no se pudo medir. Quedaron sin captura: exportar/importar, activos y pasivos y la pantalla «Sin conexión» (el indicador de la cabecera existe, pero no se documentó con modo avión).

## 7. Limitaciones actuales | Lo que **todavía no** resuelve.

- **Cuenta solo local:** una cuenta por teléfono, sin recuperación de contraseña; «¿Olvidaste tu contraseña?» muestra un aviso. SharedPreferences no está cifrado (solo la contraseña va con hash).
- **Sin nube:** si se pierde el teléfono o se desinstala la app se pierden los datos. La copia JSON queda en la carpeta privada de la app, así que también se borra al desinstalar, y no incluye las fotos de los tiquetes.
- **Archivos huérfanos:** al eliminar un movimiento o reemplazar su tiquete, la foto anterior no se borra del almacenamiento.
- **Avisos solo dentro de la app:** no hay notificaciones del sistema ni recordatorio diario; la preferencia se guarda, pero no dispara nada.
- **Conectividad aproximada:** *connectivity_plus* detecta si hay una red activa, no si hay acceso real a internet.
- **Clasificación fija:** el umbral de $20.000 y las categorías fijas no son configurables; no hay categorías personalizadas ni filtros por fecha o monto.
- **Solo COP y español;** sin pruebas automatizadas; el APK de *release* se firma con la llave de depuración y la versión mínima de Android es la predeterminada de Flutter (no se fijó Android 8.0). La meta de registro en menos de 3 s (1,76 s medidos con práctica en octubre de 2026) no se volvió a cronometrar en esta app.

## 8. Funcionalidades pendientes para el siguiente incremento | Hacia la **entrega final** (3-dic-2026).

| Prioridad | Funcionalidad | Requisito |
|---|---|---|
| Must | Cuenta en Supabase y recuperación de contraseña con código OTP al correo (Supabase, s. f.) | RF-01 a RF-03 |
| Should | Respaldo y sincronización opcional en la nube (Supabase con seguridad por fila), sincronizar ahora y borrar la copia en la nube; subir fotos de tiquetes | RF-15, RF-16 |
| Could | Notificaciones del sistema y recordatorio diario (*flutter_local_notifications*) con su permiso | RF-10, RF-18 |
| Could | Hojas de filtros y nueva categoría; umbral hormiga configurable | RF-07, RF-08 |
| Could | Otras monedas e idiomas | RF-17 |
| Should | Limpieza de fotos huérfanas, exportar la copia fuera de la carpeta privada, cronometrar el registro con usuarios y piloto con 10 participantes | RNF-01, RNF-05 |

El OCR del tiquete sigue fuera de alcance.

## 9. Demostración visual | El recorrido completo **en el teléfono**.

Capturas tomadas en el Xiaomi Redmi Note 13 Pro 5G con la compilación *debug*. Cada una se acompaña de lo que muestra y de por qué importa.

### Inicio de la app

- ![Splash](capturas/01_splash.png) **01 · Splash.** Fondo ámbar, el gato y el lema. Tras 1,5 s la app decide a dónde ir según lo guardado en SharedPreferences.
- ![Guía](capturas/02_guia.png) **02 · Guía de bienvenida.** Primer paso de tres, con indicador y botón «Omitir». Al terminar se guarda que la guía ya se vio.
- ![Crear cuenta](capturas/03_crear_cuenta.png) **03 · Crear cuenta.** Nombre, correo y contraseña. Se validan los campos y la contraseña se guarda con sal y SHA-256.
- ![Dónde guardar](capturas/04_donde_guardar.png) **04 · Dónde guardar.** El usuario elige «Solo en este teléfono»; la nube aparece como «Próximamente».
- ![Inicio vacío](capturas/05_inicio_vacio.png) **05 · Inicio vacío.** Saldo en $ 0, resumen semanal sin datos e invitación a registrar el primer gasto.

### Flujo principal e ingreso de información

- ![Agregar](capturas/06_agregar.png) **06 · Agregar.** Ingreso o Gasto, cuadrícula de categorías con íconos y fecha. «Continuar» se activa al elegir una categoría.
- ![Monto](capturas/07_monto.png) **07 · Monto.** Teclado propio con «000», nota «Cafe con Ana» y campo «Adjuntar tiquete».
- ![Montos rápidos](capturas/07b_montos_rapidos.png) **07b · Montos rápidos.** Botones de $ 2.000, $ 5.000 y $ 10.000: un toque fija el monto y vibra levemente.
- ![Gasto registrado](capturas/09_gasto_registrado.png) **09 · Gasto registrado.** Confirmación con vibración; el gasto de $ 3.500 ya está en SQLite con la etiqueta «hormiga».
- ![Inicio con datos](capturas/10_inicio_con_datos.png) **10 · Inicio con datos.** Saldo de $ 91.500, $ 28.500 gastados en la semana, gráfico de área, la equivalencia «dinero invisible» (1 café) y la actividad reciente, recalculados al instante.
- ![Movimientos](capturas/11_movimientos.png) **11 · Movimientos.** Historial agrupado por día con pestañas Todos, Ingresos y Gastos.
- ![Filtro](capturas/11b_filtro_categoria.png) **11b · Filtro por categoría.** Los chips (Todas, Alimentos, Trabajo, Transporte…) filtran la lista al instante, sin recargar.
- ![Detalle](capturas/12_detalle.png) **12 · Detalle.** Monto, nota, foto del tiquete y fecha, con botones Editar y Eliminar.
- ![Estadísticas](capturas/13_estadisticas.png) **13 · Estadísticas.** Dona de fijos, necesarios y hormiga, balance del periodo y principales categorías.

### Capacidad móvil: cámara

- ![Permiso negado](capturas/08c_permiso_negado.png) **08c · Permiso de cámara rechazado.** Si el usuario toca «No permitir», la app muestra un aviso y deja guardar el gasto sin tiquete; no se bloquea.
- ![Permiso](capturas/08a_permiso_camara.png) **08a · Permiso de cámara.** Al tocar «Escanear con la cámara», Android pide el permiso; la app no accede a la cámara sin él.
- ![Cámara](capturas/08_camara_tiquete.png) **08 · Cámara abierta.** *image_picker* abre la cámara del sistema. La imagen sale oscura porque el teléfono estaba boca abajo durante la prueba.
- ![Tiquete adjunto](capturas/08b_tiquete_adjunto.png) **08b · Tiquete adjunto.** De vuelta en Monto aparece el archivo `tiquete_*.jpg`, ya copiado a la carpeta de documentos de la app.

### Informe en PDF

- ![Informe](capturas/14_informe.png) **14 · Informe.** Patrimonio neto, activos y pasivos, y elección de Semana, Mes o Año.
- ![Informe listo](capturas/15_informe_listo.png) **15 · Informe listo.** El PDF se generó en el teléfono y se guardó en la carpeta de documentos de la app.
- ![Visor PDF](capturas/16_pdf_visor.png) **16 · Visor del PDF.** Extracto A4 con la paleta de FinTrack y botón «Compartir».

### Prueba de persistencia

- ![Cierre forzado](capturas/17_cierre_forzado.png) **17 · Cierre forzado.** Vista de recientes con la tarjeta de FinTrack, justo antes de `am force-stop`, que termina el proceso y borra la memoria.
- ![Edición](capturas/12b_editar.png) **12b · Edición.** «Taxi a la u» se cambió de $ 25.000 a $ 22.000 en la pantalla «Editar movimiento».
- ![Cambio persiste](capturas/18b_cambio_persiste.png) **18b · El cambio persiste.** Tras cerrar la app por completo y abrirla de nuevo, el movimiento sigue en $ 22.000.
- ![Reabierta](capturas/18_reabierta_persistencia.png) **18 · App reabierta.** Saldo de $ 91.500 y los mismos movimientos: se leyeron de SQLite y SharedPreferences.

### Más pantallas en el Android físico

- ![Límites](capturas/19_limites.png) **19 · Límites de gasto.** Límites hormiga semanal y mensual con su barra de avance; se pueden añadir límites por categoría.
- ![Modo oscuro](capturas/20_modo_oscuro.png) **20 · Modo oscuro.** El ajuste se guarda en preferencias y cambia el tema de toda la app.
- ![Notificaciones](capturas/21_notificaciones.png) **21 · Notificaciones leídas.** Estado vacío «Todo al día» con su ilustración y el acceso a «Configurar avisos».

## 10. Guía de desarrollo | Compilar, instalar y **ubicarse en el código**.

### Requisitos

Flutter SDK con Dart 3, Android SDK (Android Studio o *command-line tools*) y un teléfono Android con depuración USB activa. Se comprueba con `flutter doctor` y `flutter devices` (Flutter, s. f.-b).

### Compilar e instalar

Pasos según la guía oficial de publicación para Android (Flutter, s. f.-a).

```
cd fintrack_app
flutter pub get                # descarga las dependencias de pubspec.yaml
flutter run                    # compila en debug e instala en el teléfono conectado
flutter build apk --release    # genera build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Estructura de `lib/`

| Ruta | Contenido |
|---|---|
| `main.dart` | Inicializa fechas en español, carga las preferencias, crea `AppState` y aplica el tema claro u oscuro. |
| `models/models.dart` | Categorías, regla de clasificación y modelos `Movement`, `AssetItem` y `LimitItem`. |
| `services/database_helper.dart` | SQLite `fintrack.db`: tablas y operaciones CRUD. |
| `services/preferences_service.dart` | Cuenta local, sesión y ajustes en SharedPreferences. |
| `services/pdf_report_service.dart` | Extracto A4 en PDF y nombre del archivo por periodo. |
| `state/app_state.dart` | Estado central: carga, escrituras, totales, series semanales, límites, avisos y conectividad. |
| `theme/fintrack_theme.dart` | Paleta ámbar clara y oscura y estilo de los componentes. |
| `views/` | `auth_screens` (splash, guía, cuenta), `shell` (barra inferior, inicio, estadísticas, informe, perfil), `add_flow` (agregar, monto, registrado, detalle, movimientos), `more_screens` (notificaciones, activos, límites, datos, sin conexión), `profile_screens`, `report_screens` y `common`. |

Dependencias principales: *provider*, *sqflite*, *shared_preferences*, *path_provider*, *image_picker*, *connectivity_plus*, *pdf*, *printing*, *crypto*, *intl* y *flutter_svg*. Permisos declarados: internet, estado de red, cámara y vibración.

## 11. Referencias | Fuentes **citadas**.

Banco de Desarrollo de América Latina y el Caribe. (2019). *Encuesta de medición de capacidades financieras de Colombia 2019*. https://scioteca.caf.com/bitstream/handle/123456789/1717/Encuesta%20de%20medici%C3%B3n%20de%20capacidades%20financieras%20de%20Colombia-2019.pdf

Comisión Nacional para la Protección y Defensa de los Usuarios de Servicios Financieros. (2024, junio). Gastos hormiga en tu rutina de trabajo. *Revista CONDUSEF*. https://revista.condusef.gob.mx/presupuesto/gastos/2024/06/gastos-hormiga-en-tu-rutina-de-trabajo/

Flutter. (s. f.-a). *Build and release an Android app*. https://docs.flutter.dev/deployment/android

Flutter. (s. f.-b). *Flutter documentation*. https://docs.flutter.dev/

Gallego Palacio, N., Agudelo Sánchez, A., Marín Quintana, M., & Romero Luján, F. (2023). Conocimiento, aplicación y manejo de las finanzas personales, y percepción del bienestar que genera en la comunidad educativa de la IU Digital de Antioquia. *Revista Innovación Digital y Desarrollo Sostenible - IDS, 4*(1), 55-65. https://doi.org/10.47185/27113760.v4n1.129

Konietzko, D. (2023, 27 de julio). Jóvenes y educación financiera en América Latina: ¿Cómo estamos y qué podemos mejorar? *Portal FinDev*. https://www.findevgateway.org/es/blog/2023/07/jovenes-y-educacion-financiera-en-america-latina-como-estamos-y-que-podemos-mejorar

Roldán, P. N. (2017). *Gastos hormiga: Qué son, ejemplos y cómo identificarlos*. Economipedia. https://economipedia.com/definiciones/gastos-hormiga.html

*sqflite* [Paquete de software]. (s. f.). pub.dev. https://pub.dev/packages/sqflite

Supabase. (s. f.). *Passwordless email logins*. https://supabase.com/docs/guides/auth/passwordless-login/auth-email-otp
