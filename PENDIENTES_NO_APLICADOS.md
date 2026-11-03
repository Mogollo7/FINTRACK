# FinTrack · funciones del mockup aún no aplicadas

Aplicado (local, sin servidor): splash, guía, registro/inicio de sesión (hash con sal), inicio, estadísticas, informe + PDF tipo extracto, agregar/monto/detalle/editar/eliminar, tiquete con cámara/galería, movimientos, notificaciones internas, activos y pasivos, límites, exportar/importar JSON, perfil, ajustes, modo oscuro, estados de carga/vacío/error, indicador sin conexión.

## No se puede aplicar todavía
| Función | Motivo |
|---|---|
| Recuperar contraseña con OTP por correo (Olvidé / Código OTP / Nueva contraseña) | Requiere proveedor de correo o Supabase; el enlace muestra un aviso |
| Respaldo en la nube, sincronizar, borrar nube | Requiere Supabase (entrega final 3-dic-2026) |
| Recordatorio diario y avisos del sistema | Falta `flutter_local_notifications` y permisos; hoy solo se guarda la preferencia y hay avisos dentro de la app |
| Moneda e idioma distintos de COP / Español | Sin conversión ni traducciones; las hojas los listan pero avisan |

## Pendiente por tiempo / sin verificar
- Hojas «Filtros» y «Nueva categoría» (categorías personalizadas); permisos de notificación y cámara como pantallas propias (se usa el permiso del sistema).
- Ilustraciones: ya usa las 9 del zip (assets/ilus). Tipografía Roboto en lugar de Inter.
- Tecla «.» del teclado de monto se cambió por «000» (pesos sin decimales).
- Clasificación hormiga: gasto ≤ $20.000; fijo = Hogar/Educación/Salud/Teléfono.
- Probado en el Xiaomi (Redmi, debug): guía, registro, guardado, inicio, Agregar/Monto, gasto registrado, estadísticas, informe, PDF (visor), perfil, ajustes, límites y modo oscuro. Sin probar aún: cámara/galería, exportar/importar, movimientos/detalle/editar, activos y pasivos, «Sin conexión».
