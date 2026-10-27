# Tata - Cross-platform mobile application

Cliente Flutter de Tata, desarrollado por VitaHealth. Una aplicaciÃ³n para Android e iOS que consume los servicios de Tata.

## Base

Proyecto inicial creado en Android Studio y aportado por el equipo en `tata.zip`. Se conservan los proyectos de plataforma y `.metadata`. El scaffold muestra una vista mÃ­nima y no implementa autenticaciÃ³n ni flujos clÃ­nicos.

- Flutter 3.47.8 stable, Dart 3.13.7.
- Paquete Dart: `tata`.
- Identificador Android/iOS: `com.vitahealth.tata`.
- VersiÃ³n inicial: `0.1.0+1`.

## EjecuciÃ³n

```sh
flutter pub get
flutter run
```

## ValidaciÃ³n

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

iOS se compila y prueba en macOS con Xcode. La presencia de `ios/` conserva el proyecto de plataforma y no acredita una ejecuciÃ³n en iPhone.

## Desarrollo

Se utiliza GitFlow: `main`, `develop`, `feature/*`, `fix/*` y `release/*`. La base se inicializa en `main`; los flujos posteriores se integran en `develop` despuÃ©s de sus verificaciones.

La implementaciÃ³n se organiza por los nueve bounded contexts de Tata, con separaciÃ³n de dominio, aplicaciÃ³n, infraestructura y presentaciÃ³n. BLoC se incorpora con el primer flujo funcional; no hay carpetas vacÃ­as ni dependencias de negocio sin consumidores en este scaffold. El plan de arquitectura y avance se conserva localmente fuera del repositorio.
