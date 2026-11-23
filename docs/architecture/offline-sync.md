# Offline synchronization


- Sesión: ownerId+role+generation; guardar secretos solo mediante puerto seguro. Limpiar estado sensible al logout/revocación/expiración; invalidar solicitudes pendientes antes de persistir respuesta.
- Offline: clave de idempotencia estable por operación; persistencia separada por propietario; distinguir pendiente local de recibo servidor. Reintentar errores transitorios, detener permisos/recurso eliminado y no reproducir con otro usuario.
- Formularios: controllers y focus se liberan con dispose; contraseña no se recorta; código y contraseña se borran tras éxito/salida; bloquear doble submit; cancelar no envía.
- Push: opt-in por entorno, token cambia de propietario mediante recibos y cleanup. Desuscripción de tópicos legacy si existen; ocultar notificación no protege transporte. Nunca loguear token.
- Recursos nativos: permisos Android e iOS específicos; no añadir permiso a scaffolding si no hay consumidor. Audio temporal se borra, formato/mime/longitud coinciden con backend.
- Transporte: HTTPS para backend remoto. AccesoHTTPloopback solo en configuración de desarrollo para integrar; sin permitir cleartext global productivo por facilidad.
- Datos del servidor: cache inválida no se presenta como vigente; refrescar tras mutación/retorno/foreground cuando corresponda. Servidor conserva autoridad de consentimiento, stock, omisiones y cálculos clínicos.

## Confirmación de tomas

La confirmación conserva la hora del toque en `confirmedAt` y la misma identidad de operación durante los reintentos. La clasificación definitiva corresponde al backend. La aceptación local permanece diferenciada de la confirmación remota.

La ejecución en segundo plano y la integración desplegada se comprueban por plataforma; una prueba de repositorio no acredita entrega con la aplicación cerrada.
