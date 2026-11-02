# FinTrack — Control Consciente de Gastos Hormiga

> **Aplicación Móvil para la Gestión de Gastos Hormiga en Jóvenes Universitarios**  
> **Examen 2: Segundo Incremento del Proyecto — Prototipo Móvil Funcional (MVP)**  
> **Asignatura:** Aplicaciones Móviles / Gestión de Proyectos  
> **Docente:** Neider Xavier Vergara Humánez  
> **Institución:** Corporación Universitaria Lasallista (2026)  

---

## Integrantes del Equipo
* **Juan Sebastián Martínez Galeano**
* **Cesar Ocampo Raigosa**
* **Samuel Usma Brand**

---

## Enlaces del Proyecto
* 📱 **Prototipo Navegable en Figma:** [Abrir prototipo interactivo de FinTrack](https://www.figma.com/proto/3dFgO0jReUQgWHXaXLZOin/fintrak?node-id=15-312&viewport=165%2C-459%2C1.73&t=SwoJydV9BxnrWMR0-1&scaling=min-zoom&content-scaling=fixed&starting-point-node-id=15%3A293&show-proto-sidebar=1&page-id=3%3A3)
* 📄 **Documento PDF Corregido en Figma (Nueva Página):** [Ver entrega en Figma (Página PDF Final)](https://www.figma.com/design/9vhSrNs3T7t50uCKancJrI/pdf?node-id=59-2)
* 📑 **Informe Técnico de Examen 2 (3-5 páginas):** [Ver Informe Técnico Oficial](docs/INFORME_TECNICO_EXAMEN2_FLUTTER.md)
* 📘 **Planificación Integral Extensa (WBS, Gantt, Riesgos):** [Ver Planificación Integral](docs/FinTrack_Segunda_Entrega.md)

---

## Descripción del Incremento (MVP Funcional)

FinTrack resuelve el problema de la **"gotera financiera"**: los microgastos frecuentes y de bajo valor que pasan desapercibidos y deterioran el presupuesto mensual del universitario.

Este incremento implementa el **flujo principal completo de 5 pasos**:
1. **Captura ultrarrápida (< 1.5 s):** Con accesos directos de un solo toque para montos frecuentes ($2.000, $5.000, $10.000) y selección categorizada.
2. **Validación reactiva:** Reglas de validación en tiempo real y alerta reflexiva al aproximarse o superar el presupuesto semanal.
3. **Persistencia local verificable:** Motor relacional SQLite (`sqflite`), configuración en `shared_preferences` y archivos en `path_provider` que persisten tras cerrar completamente la app.
4. **Visualización y "Dinero Invisible":** Tablero principal con acumulados y cálculo de equivalencias cotidianas (*"equivale a 3 almuerzos universitarios"*).
5. **Mantenimiento interactivo:** Consulta, edición de montos y eliminación con recálculo dinámico en el historial.

### Capacidades Móviles Integradas
1. **Cámara y Filesystem (`camera` / `image_picker` + `path_provider`):** Captura y almacenamiento local privado de comprobantes o tiquetes físicos de compra.
2. **Respuesta Háptica (`HapticFeedback`):** Confirmación táctil física inmediata al tocar montos rápidos y guardar transacciones en la calle.
3. **Monitoreo de Conectividad (`connectivity_plus`):** Detección explícita de red operando bajo una arquitectura 100% *Offline-First*.

---

## Arquitectura de Software (MVVM)

```
lib/
├── main.dart                      # Punto de entrada y configuración de Provider
├── models/
│   └── expense.dart               # Modelo de datos con serialización SQLite
├── services/
│   ├── database_helper.dart       # CRUD relacional SQLite local (sqflite)
│   └── preferences_service.dart   # Almacenamiento clave-valor (shared_preferences)
├── viewmodels/
│   └── expense_viewmodel.dart     # Estado reactivo (ChangeNotifier) y reglas de negocio
└── views/
    ├── home_screen.dart           # Tablero "Dinero Invisible", historial y navegación
    └── widgets/
        └── add_expense_sheet.dart # Modal de captura rápida con cámara y háptica
```

---

## Instrucciones para Ejecutar la Aplicación

### Requisitos Previos
* Flutter SDK (3.0.0 o superior)
* Android Studio / SDK (API 26 mínima: Android 8.0 Oreo hasta API 34: Android 14)

### Pasos de Instalación y Ejecución
1. Clonar el repositorio:
   ```bash
   git clone https://github.com/Mogollo7/FINTRACK.git
   cd FINTRACK
   ```
2. Instalar dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecutar en emulador o dispositivo físico Android conectado:
   ```bash
   flutter run
   ```
4. Para compilar el APK instalable:
   ```bash
   flutter build apk --release
   ```
   El APK resultante se ubicará en `build/app/outputs/flutter-apk/app-release.apk`.

