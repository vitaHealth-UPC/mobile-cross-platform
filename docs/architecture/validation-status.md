# Validation status

## Evidencia del corte

| Comprobación | Resultado |
| --- | --- |
| Variantes representadas | 70 de 70 |
| Comparación visual proporcional | 70 de 70; detalle en figma-frame-map.md |
| Suite Flutter tras normalización | 849 pruebas aprobadas |
| Análisis estático tras normalización | Sin incidencias |
| APK debug tras normalización | Generado |
| Inicio social con cuentas reales | No verificado |
| Entrega push con adaptadores de producción | No acreditada; composición actual usa adaptadores no configurados |
| Normalización de archivos | 20 bibliotecas separadas en 83 archivos de responsabilidad; suite completa aprobada |

La aceptación visual no equivale al cierre funcional ni a una prueba contra Render.

## Registro de validación

Actualizar una fila por recorrido con el cambio real, prueba, entorno y resultado; sustituir los datos anteriores cuando dejan de describir el estado vigente.

| Recorrido | Cambio o alcance | Prueba y entorno | Resultado |
| --- | --- | --- | --- |
| Acceso social | SDK Google/Facebook, Firebase y sesión Tata con protección frente a logout | Pruebas locales de repositorio y BLoC; APK debug | Validación local aprobada; cuenta real separada |

La compilación conserva un aviso de compatibilidad futura de `flutter_tts` con Built-in Kotlin. Las pruebas imprimen un aviso de filtros SVG no soportados; estos controles no acreditan por sí solos la fidelidad de esos efectos.

La revisión de notificaciones añade pruebas de aislamiento de canales, callbacks compartidos, permisos y rotación FCM. El adaptador FCM está implementado; el registro de producción sigue desactivado hasta completar el recorrido de recepción y apertura.

## TS-06: avisos nativos

Siete pruebas acotadas aprueban inicialización compartida, aislamiento de canales, textos ES/EN y retirada del aviso ante cambio de sesión. El análisis estático del adaptador y su composición no presenta incidencias. El APK debug compila con el recurso nativo de notificación. El registro push permanece desactivado hasta completar recepción y apertura. Este resultado complementa la suite de 849 pruebas del corte publicado; no declara una nueva suite completa.

## TS-06: transporte y coordinación

Once pruebas acotadas aprueban el mapeo FCM y los permisos del token. Seis pruebas del coordinador aprueban restauración, autorización, cambio de actor y salida. El análisis del corte no presenta incidencias. El coordinador está compuesto mediante `AppDependencies`; el arranque y las rutas de pantalla aún requieren conexión antes de activar registro.
