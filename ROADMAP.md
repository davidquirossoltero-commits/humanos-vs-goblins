# Hoja de ruta

El prototipo ya se puede jugar de principio a fin en un solo mapa. Esto es lo que vendría después, en un orden que deja el juego más grande sin rehacer el combate.

## Mapas

- Más caminos: bosque, pantano y asedio de noche, cada uno con su JSON en `data/`.
- Atajos, cruces y dos puertas. El bloqueo de construcción ya mira el camino y rectángulos; un mapa nuevo es sobre todo datos y el dibujo.
- Selector de mapa en el menú.

## Torres y mejoras

- Más torres: ballesta, druida, barricada que no dispara y cuartel de lanceros.
- Árboles de mejoras de varias filas, con ramas que se excluyen (fuego o hielo, no las dos a la vez).
- El panel actual ya compra mejoras sueltas; el siguiente paso es un nivel por rama y un tope de puntos.

## Héroes

- Un héroe que se mueve por el camino o por la pradera: capitana, clériga o exploradora.
- Habilidad activa con enfriamiento (grito, cura, trampa).
- El héroe no sustituye a las torres; tapa los huecos entre oleadas.

## Partida guardada

- Guardar oro, vidas, oleada y torres en `user://` para continuar después de cerrar.
- El estado ya es una lista de torres con mejoras; serializarlo a JSON encaja con cómo está armado el mundo.

## Progresión entre partidas

- La aldea entre partidas: oro de meta que no se pierde al fallar.
- Desbloquear torres y mejoras permanentes (un arquero que empieza con disparo rápido, más vidas base).
- Récord de oleada y de mapa.

## Enemigos y oleadas

- Chamán que cura al de delante, globo de guerra que ignora el ralentí, y un jefe en la oleada 10.
- Oleadas escritas a mano más un modo infinito que genera grupos a partir de la amenaza (el cálculo de vidas que roba un enemigo ya está en `layers.gd`).
- Indicador de lo que viene, más claro que la línea de texto actual.

## Sensación de juego

- Música de loop, más efectos y un poco de temblor ya esbozado en los cañonazos.
- Velocidad ×3 y pausa.
- Opciones de accesibilidad: daltonismo en los goblins, texto más grande, menos destellos.

## Más adelante

- Tablas de clasificación locales.
- Cooperativo en el mismo mapa, cuando el estado de la partida se pueda sincronizar.
- Idiomas aparte del español, si el juego sale del prototipo. Hoy todo el texto visible está escrito en español a propósito.
