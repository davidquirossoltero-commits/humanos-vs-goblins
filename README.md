# Humanos vs Goblins

Prototipo jugable de defensa de torres. Los humanos protegen la aldea del robledal y los goblins avanzan por un camino hasta la meta. El arte es original, de caricatura, y no usa nombres ni material de otros juegos.

Hecho con **Godot 4.7** (GDScript). La interfaz del juego está en español.

## Qué incluye

- Tres campos en **La Copa del Robledal**: el prado de la aldea, el foso de los Colmillos y el coliseo de la final. Cada uno tiene su camino. No se puede construir sobre el camino, la meta ni demasiado cerca de otra torre.
- Tres torres, cada una con dos mejoras:
  - **Arquero**: disparo rápido y flechas perforantes.
  - **Mago**: estallido mayor y escarcha que ralentiza.
  - **Cañón**: metralla y largo alcance.
- Al colocar una torre se ve el círculo de alcance. Si pulsas una torre ya puesta puedes mejorarla, venderla (70 % del oro invertido) o cambiar el objetivo: Primero, El más fuerte, Último, El más cercano.
- Cinco enemigos con capas, al estilo de los globos: el ogro pierde la armadura y luego suelta hobgoblins; el hobgoblin suelta goblins; el jinete deja un goblin a pie; el trol entra en furia y al caer suelta un hobgoblin y dos goblins.
- El menú abre la crónica, elige capítulo o entra directo al prado. El primer capítulo tiene 10 oleadas, cada una más pesada. Los otros dos usan los tramos más duros de esa lista. Oro por baja y por oleada superada. Si un goblin entra en la meta, pierdes vidas según lo que todavía lleva dentro. Al ganar un capítulo se guarda la marca de superado. Si las vidas llegan a cero, derrota. Se puede reintentar o volver al menú.
- Botón de velocidad ×2, efectos y una música suave de estadio (órgano, murmullo y un tambor lejano; se silencian con Sonido) y controles de ratón, dedo y teclado.
- Torres, enemigos, oleadas, mapa y economía viven en JSON (`data/`), para poder añadir más sin reescribir el combate.

## Requisitos

- Godot **4.7** o posterior de la rama 4.7 (este proyecto se probó con 4.7.2).
- Para exportar: las plantillas de exportación de esa misma versión.

## Abrir y jugar

1. Instala Godot 4.7 desde [godotengine.org](https://godotengine.org/download).
2. En el gestor de proyectos, pulsa **Importar** y elige el `project.godot` de esta carpeta.
3. Pulsa **Jugar** (F5).

El juego se estira para llenar la ventana (en móvil, mejor en horizontal). Ratón y toque hacen lo mismo.

### Controles

| Acción | Cómo |
| --- | --- |
| Elegir torre | Botones Arquero, Mago y Cañón, o las teclas 1, 2 y 3 |
| Construir | Clic o toque en el prado. El círculo verde marca un sitio válido |
| Pausa | Escape abre el menú y detiene el partido. Continuar, Reiniciar capítulo o Menú principal. Espacio también continúa |
| Cancelar colocación | Botón Cancelar o clic derecho |
| Mejorar o vender | Clic en una torre ya puesta |
| Objetivo | En el panel de la torre: Primero, El más fuerte, Último, El más cercano |
| Empezar oleada | Sale sola: la primera a los 3 s de pulsar Jugar, y las demás a los 2,5 s de terminar la anterior. Espacio o Empezar ya la adelantan |
| Acelerar | Botón ×2, o la tecla F |
| Sonido | Botón Sonido |
| Menú | Historia, Niveles y Jugar. Espacio empieza el capítulo. Al terminar, Siguiente capítulo, Reintentar o Menú |

## Pruebas

Hacen falta el binario de Godot (el del editor vale en modo headless):

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

Comprueban la economía (oro, venta, bono de oleada), la rotura de capas (armadura del ogro, crías del hobgoblin, jinete y trol), que las 10 oleadas suben de amenaza, el bloqueo del camino y una partida simulada que gana con una defensa a lo largo del camino.

Si todo va bien, la última línea es `ALL TESTS PASSED`.

## Exportar

En el editor: **Proyecto → Exportar**. Hay tres presets:

- **Web**: HTML5 en un solo hilo (no pide cabeceras COOP/COEP).
- **Linux**: binario x86_64 con el paquete embebido.
- **Windows**: `humanos-vs-goblins.exe` con el paquete embebido.

Desde la terminal, con las plantillas instaladas (en Linux suelen vivir en `~/.local/share/godot/export_templates/4.7.2.stable/`):

```bash
mkdir -p build/web build/linux build/windows
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Linux" build/linux/humanos-vs-goblins.x86_64
godot --headless --path . --export-release "Windows" build/windows/humanos-vs-goblins.exe
```

La carpeta `build/` está ignorada por Git salvo `build/.gdignore`, que evita que Godot reimporte los binarios exportados.

### Probar la web en local

El navegador solo carga el `.wasm` si el servidor lo anuncia como `application/wasm`. Este script ya lo hace:

```bash
python3 tools/serve_web.py 5199 build/web
```

Abre [http://127.0.0.1:5199](http://127.0.0.1:5199).

## Servir con nginx en Linux

La exportación web de este repositorio va **sin hilos** (`variant/thread_support=false` en el preset Web). Así arranca detrás de un nginx normal: no hacen falta `Cross-Origin-Opener-Policy` ni `Cross-Origin-Embedder-Policy`.

Sí hace falta el tipo MIME de WebAssembly. El ejemplo está en `deploy/nginx.conf`.

```bash
# En el servidor, después de exportar:
sudo mkdir -p /var/www/humanos-vs-goblins
sudo cp -a build/web/. /var/www/humanos-vs-goblins/
sudo cp deploy/nginx.conf /etc/nginx/sites-available/humanos-vs-goblins
# Ajusta el root si no usas /usr/share/nginx/html, o sirve este sitio como default.
sudo ln -sf /etc/nginx/sites-available/humanos-vs-goblins /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

El `Dockerfile` y el `docker-compose.yml` publican esa misma exportación:

```bash
docker compose up --build
```

Queda en el puerto **8097**. La imagen copia `build/web`, así que hay que exportar antes de construirla.

### Si activas los hilos

En el preset Web, pon `variant/thread_support=true` y vuelve a exportar. El juego pasa a usar `SharedArrayBuffer` y **todas** las respuestas (html, js, wasm, pck, png) deben llevar:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

En `deploy/nginx.conf` esas dos líneas están comentadas. Quítales el `#` y recarga nginx. Sin esas cabeceras el navegador no arranca la build con hilos. La build de un solo hilo no las necesita y es la que viene configurada.

## Datos

| Archivo | Qué define |
| --- | --- |
| `data/towers.json` | Coste, alcance, daño, cadencia y las dos mejoras |
| `data/enemies.json` | Capas, vida, velocidad, oro, vidas que roba y en qué se rompe |
| `data/waves.json` | Los grupos de cada oleada |
| `data/map.json` | Camino del prado, radio del sendero y zonas bloqueadas |
| `data/campaign.json` | Crónica y los tres capítulos (campo, oleadas y texto) |
| `data/balance.json` | Oro y vidas iniciales, venta, hueco entre torres y bono de oleada |

Los scripts de `scripts/` leen ese JSON. `layers.gd`, `waves.gd`, `economy.gd`, `placement.gd` y `targeting.gd` no dependen de la escena, y por eso se pueden probar en headless.

## Siguientes pasos

Están en [ROADMAP.md](ROADMAP.md).
