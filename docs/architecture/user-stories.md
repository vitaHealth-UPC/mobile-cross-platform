# User stories

Flutter implementa las mismas historias de producto US-01 a US-45 del cliente Android. El Product Backlog conserva los identificadores, actores y objetivos; la aceptación identifica la plataforma cubierta. El nuevo Sprint Backlog selecciona esas historias y descompone el trabajo de Flutter en tareas verificables.

El enunciado 202620 presenta un Product Backlog con estimación, prioridad y sprint (p. 16), una sección por sprint (p. 25) y un Sprint Backlog con historias seleccionadas y sus tareas (p. 28). No exige duplicar el Product Backlog ni repetir literalmente las tareas técnicas de Android. AV2 corresponde al Sprint 2 y TB2 al Sprint 3 (pp. 34-35).

Las TS conservan sus identificadores cuando el catálogo establece una misma tarea aplicable a ambos clientes; las tareas específicas de plataforma describen widgets, BLoC, persistencia y pruebas Flutter. El trabajo completado en Android no acredita automáticamente aceptación en Flutter. La selección y estimación del sprint se registran con el equipo, sin inventar retrospectivamente fechas o esfuerzos.

Los commits originales y sus autores se conservan. Un commit que cubre varias historias mantiene ese alcance al integrar; las ramas no se utilizan para atribuir trabajo inexistente.

La asignación definitiva de `feature/us-xx-*` se contrasta con el catálogo del informe y los cambios reales antes de publicar ramas. `temp` reúne la integración actual; `develop`, la release y `main` reciben los cambios validados.

La aceptación de una historia requiere comportamiento por actor, errores, permisos, persistencia cuando corresponda y revisión visual. El mapa Figma mide variantes y no sustituye esta aceptación.


## Catálogo funcional compartido

| Story | Capability | Flutter context | Integration or output |
| --- | --- | --- | --- |
| US-01 | Older-adult PIN setup and access | `identity_subscription` | PIN credentials, PIN sessions |
| US-02 | Caregiver/adult linking | `care_link` | Link code and care-link acceptance |
| US-03 | Register medication | `treatment_management` | Medication creation |
| US-04 | Edit and deactivate medication | `treatment_management` | Medication update and lifecycle |
| US-05 | Scheduled dose reminder | `intake_execution` | Next intake and reminder presentation |
| US-06 | Touch or voice dose confirmation | `intake_execution` | Idempotent backend confirmation |
| US-07 | Missed-dose alert | `omission_escalation` / `family_monitoring` | Notification routing and alert display |
| US-08 | Weekly adherence summary | `adherence_analytics` | Adherence summary API |
| US-09 | Recurring omission patterns | `adherence_analytics` | Backend insight resources |
| US-10 | Caregiver registration | `identity_subscription` | Account registration |
| US-11 | Email verification | `identity_subscription` | Verification requests and confirmation |
| US-12 | Older-adult profile | `care_link` | Adult profile registration and editing |
| US-13 | Care consent | `care_link` | Care-link consent and withdrawal |
| US-14 | Create treatment | `treatment_management` | Treatment creation |
| US-15 | Configure dose/frequency | `treatment_management` | Regimen configuration |
| US-16 | Configure schedule/instructions | `treatment_management` | Regimen configuration |
| US-17 | Configure treatment reminders | `treatment_management` | Reminder lead and follow-up delay |
| US-18 | Activate or pause treatment | `treatment_management` | Treatment lifecycle operations |
| US-19 | Treatment detail | `treatment_management` | Read treatment configuration and state |
| US-20 | Next scheduled dose | `intake_execution` | Next-intake query |
| US-21 | Dose detail by outcome | `intake_execution` | Intake detail and mapped UI status |
| US-22 | Reinforced reminder | `intake_execution` / `omission_escalation` | Pending-intake UI and notification routing |
| US-23 | Late dose confirmation | `intake_execution` | Backend late/omitted distinction |
| US-24 | Daily and weekly agenda | `intake_execution` | Time-zone-aware agenda query |
| US-25 | Recent family-care status | `family_monitoring` | Caregiver status resource |
| US-26 | Recent intake history | `family_monitoring` / `adherence_analytics` | History resources and adherence views |
| US-27 | Alert detail | `family_monitoring` | Protected alert detail |
| US-28 | Notification preferences | `accessibility_preferences` | Channel and policy configuration |
| US-29 | Contact from an alert | `family_monitoring` | Contact-channel API and device launcher |
| US-30 | Caregiver follow-up note | `family_monitoring` | Follow-up note API |
| US-31 | Alert follow-up status | `family_monitoring` | Alert status transition |
| US-32 | Adherence history by period | `adherence_analytics` | Summary and trend queries |
| US-33 | Late/omitted classification | `adherence_analytics` | Read authoritative intake outcomes |
| US-34 | Adherence recommendations | `adherence_analytics` | Insights and recommendation presentation |
| US-35 | Text size | `accessibility_preferences` | Local/remote accessibility preference |
| US-36 | High contrast | `accessibility_preferences` | Local/remote contrast preference |
| US-37 | Reduced motion | `accessibility_preferences` | Local/remote motion preference |
| US-38 | Reading assistance | `accessibility_preferences` | Local/remote reading preference |
| US-39 | Quiet hours and channels | `accessibility_preferences` | Notification preference API |
| US-40 | Initial inventory | `inventory_replenishment` | Create stock record |
| US-41 | Stock balance | `inventory_replenishment` | Inventory query |
| US-42 | Low-stock indication | `inventory_replenishment` | Server low-stock flag and threshold |
| US-43 | Replenishment | `inventory_replenishment` | Register stock batch |
| US-44 | Current subscription | `identity_subscription` | Plans and account subscription |
| US-45 | Change subscription | `identity_subscription` | Update account plan |

## Cortes de contribución revisados

Los 19 cortes siguientes identifican contribuciones auténticas del historial compartido; no sustituyen las 45 historias ni el Sprint Backlog. Su distribución por ramas se ajusta al catálogo antes de publicar. Incluyen dependencias anteriores y, cuando el commit reúne varias capacidades, no representan una implementación aislada de una sola historia. Las correcciones de integración permanecen en `temp`. Los merges a `develop` registran la integración actual; no reconstruyen fechas ni autorías pasadas.

| Rama | Commit original de cierre |
| --- | --- |
| `feature/us-10-caregiver-registration` | `ce70f0d` |
| `feature/us-01-pin-access` | `b2493b3` |
| `feature/us-24-intake-agenda` | `6d2d8ab` |
| `feature/us-32-adherence-history` | `341810e` |
| `feature/us-03-medication-management` | `8cce4df` |
| `feature/us-35-accessibility-preferences` | `c9533e4` |
| `feature/us-19-treatment-detail` | `157acea` |
| `feature/us-07-omission-alerts` | `0d1e593` |
| `feature/us-25-family-monitoring` | `efc6d20` |
| `feature/us-06-voice-confirmation` | `ca0faf9` |
| `feature/us-40-inventory` | `270a898` |
| `feature/us-42-low-stock` | `e2c5d15` |
| `feature/us-44-subscription` | `564466a` |
| `feature/us-11-email-verification` | `cd772b4` |
| `feature/offline-confirmation-cache` | `03d2c86` |
| `feature/us-22-reinforced-reminders` | `6b336c1` |
| `feature/public-plans` | `a439d17` |
| `feature/us-05-scheduled-reminders` | `e604dd3` |
| `feature/us-12-linked-person` | `a0aa276` |
