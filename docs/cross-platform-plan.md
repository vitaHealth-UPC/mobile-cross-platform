# Cross-platform implementation plan

La documentación técnica se organiza por responsabilidad, con la misma separación temática del cliente Android y contratos adaptados a Flutter.

| Documento | Contenido |
| --- | --- |
| [Arquitectura](architecture/mobile-architecture.md) | Cuatro capas, dependencias y responsabilidades |
| [Contextos](architecture/bounded-contexts.md) | Límites de los nueve contextos |
| [Integraciones técnicas](architecture/technical-stories.md) | TS, contratos móviles y ramas de integración |
| [Historias](architecture/user-stories.md) | Aceptación y trazabilidad de producto |
| [Inventario](architecture/implementation-inventory.md) | Archivos previstos, responsabilidades y pruebas |
| [Figma](architecture/figma-frame-map.md) | Las 70 variantes y su evidencia |
| [Sincronización](architecture/offline-sync.md) | Sesión, cola, reintentos y seguridad |
| [Convenciones](architecture/development-guidelines.md) | Figma, recursos, Flutter, formato y Dartdoc |
| [Requisitos](architecture/course-requirements.md) | Enunciado y referencias del curso |
| [Contratos API](api/contract-guidelines.md) | Transporte, autorización y recibos |
| [Identidad y vínculos](api/identity-and-care-links.md) | Acceso, proveedores y consentimiento |
| [Validación](architecture/validation-status.md) | Evidencia vigente y controles de cierre |

## Orden de integración

1. Completar la corrección local de Android y normalizar las responsabilidades de Flutter sin cambiar su comportamiento.
2. Actualizar las rutas del inventario al cerrar cada contexto y validar análisis, pruebas y compilación.
3. Contrastar la paridad funcional, los adaptadores de producción y las credenciales por plataforma.
4. Relacionar las contribuciones originales con historias reales, conservando hashes y autores.
5. Integrar a `develop`, preparar la release y publicar `main` y su tag tras validar el alcance. `temp` conserva las correcciones de Flutter.
