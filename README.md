# Gymkoda

Aplicación móvil para planificar y seguir rutinas de entrenamiento con una experiencia visual dinámica.

## Funciónes

- Autenticación de usuarios (Google) y gestión de perfil.
- Cuestionario inicial para crear el perfil (alias, edad, altura, peso, objetivo).
- Guarda el perfil en Firestore en /usuarios/{uid}.
- Objetivo compatible con rutinas: "Fuerza", "Resistencia" o "Hipertrofia".
- Carga de rutinas desde API/JSON y filtrado por:
  - Objetivo, rango de edad, rango de peso y nivel.
- Calcula el nivel del usuario según la fecha de registro:
  - base, intermedio, avanzado.
- Pantalla de inicio:
  - Lista de días con título, subtítulo y porcentaje de progreso por día.
  - Indicadores circulares de progreso con gradientes.
- Pantalla de rutina:
  - Checklist de ejercicios y cronómetro simple.
  - Devuelve el progreso del día al finalizar.
- Persistencia de progreso:
  - Guarda el progreso por día en Firestore (usuarios/{uid}.progreso) para mantenerlo entre reinicios.
- Perfil:
  - Muestra datos del usuario y el objetivo con su ícono correspondiente.
- UI con gradientes personalizables en app bar, fondos y tarjetas.
- Cierre de sesión que redirige a la pantalla de login.
