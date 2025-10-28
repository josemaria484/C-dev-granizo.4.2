# Referencia de la imagen de radar

## Dónde guardar este documento

Coloca este archivo como `docs/radar_test_image.md` dentro del repositorio. Si la carpeta `docs/` aún no existe en tu copia local, créala primero y luego añade el archivo en ese directorio para conservar la estructura sugerida.

Este documento conserva la captura de radar de referencia suministrada para validar la canalización de procesamiento de radar. La imagen corresponde a un producto de reflectividad compuesta capturado el **17-12-2020 a las 17:04:00 UTC**, con pistas integradas hasta las **17:04:09 UTC** (TZ:35). Representa estructuras convectivas sobre el norte de Uruguay y el sur de Brasil, con celdas destacadas cerca de Tacuarembó, Rivera y Punta Gorda.

## Características visuales

* **Escala de colores:** La leyenda ubicada a la derecha muestra reflectividad medida en dBZ, desde azules claros (≈0 dBZ) pasando por verdes y amarillos hasta núcleos magenta intensos que superan los 60 dBZ. La rampa cromática coincide con la paleta utilizada por la red nacional de radares (VIL, VCP, VILGT, VLLGT, etc.).
* **Anotaciones geográficas:** Los rótulos de ciudades (p. ej., *Rivera*, *Tacuarembó*, *Paso de los Toros*, *Punta Gorda*) y los límites departamentales aportan contexto espacial para ubicar las tormentas.
* **Estructura de la tormenta:**
    * Un complejo convectivo dominante cubre el sector centro-norte con píxeles magenta y blancos, lo que indica núcleos de reflectividad muy alta asociados probablemente a granizo severo o lluvias intensas.
    * Un clúster secundario se sitúa al sur del sistema principal y muestra gradientes internos similares, aunque de menor extensión espacial.
    * Ecos dispersos y marcadores de seguimiento aparecen al este del complejo principal, ilustrando la evolución temporal de la tormenta.

## Recomendaciones de uso

* Almacena el archivo ráster en `assets/radar/radar_reference_20201217.png` (crea la carpeta si es necesario) para mantener los datos fuera del control de versiones y conservar rutas consistentes en las pruebas.
* Al escribir pruebas automatizadas, carga la imagen mediante un *fixture* (por ejemplo, `tests/data/test_radar_image.png`) copiado desde el recurso canónico para asegurar un comportamiento determinista.
* Contrasta las salidas del algoritmo —como máscaras de segmentación, histogramas de reflectividad u *overlays* de seguimiento de celdas— con las estructuras y la distribución de color descritas arriba.

## Cómo verificar que usas la imagen correcta

Si recibiste más de un archivo y no estás seguro de cuál es el definitivo, confirma que el recurso activo cumpla con estas señales:

1. **Marca de tiempo incrustada:** En la franja superior debe leerse `17-12-2020 17:04:00 UTC` y el texto de pistas debe indicar la actualización `17:04:09 UTC (TZ:35)`.
2. **Patrón de colores:** La banda magenta/blanca más intensa debe quedar sobre el norte de Uruguay, con transiciones a verdes y azules hacia los bordes.
3. **Etiquetas geográficas:** Deben ser visibles los rótulos de *Rivera*, *Tacuarembó*, *Paso de los Toros* y *Punta Gorda* con líneas departamentales superpuestas.
4. **Marcadores de seguimiento:** A la derecha del núcleo principal deben aparecer flechas o íconos de trayectorias que ilustran el movimiento de las celdas.

Si un archivo no cumple estos criterios, consérvalo como material de análisis pero no lo utilices como referencia canónica hasta validar su procedencia con el equipo de operaciones.

## Nota de procedencia

Esta descripción refleja el fotograma de radar auténtico proporcionado por el personal de operaciones para servir como referencia y debe tratarse como verdad de base en las comparaciones de regresión.