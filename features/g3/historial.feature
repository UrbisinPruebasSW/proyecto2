# language: en
@g3
Feature: Historial de movimientos y categorías
  Como cliente
  Quiero consultar, clasificar y exportar mis movimientos
  Para controlar y organizar mis gastos

  # Datos: Ana Torres (987654321, PIN 4826). Reinicio de datos antes de cada escenario.
  # "Hoy" es la fecha del reloj de la app (PUT /api/pruebas/reloj).
  # Los valores límite salen de R-G3-01 a R-G3-04 de docs/requisitos.md.
  Background:
    Given que inicié sesión como Ana
    And que hoy es 2026-11-15

  # ---------------------------------------------------------------------------
  # HU-G3-01 · Consultar mis movimientos (Alta)
  # R-G3-01: desde <= hasta, máximo 90 días, hasta no futura, por defecto 30 días
  # ---------------------------------------------------------------------------

  @HU-G3-01 @api
  Scenario: Consulta sin filtros devuelve los últimos 30 días incluyendo hoy
    Given que tengo un movimiento de hoy y otro de hace 30 días y otro de hace 31 días
    When consulto mi historial sin filtros
    Then el rango consultado es desde 2026-10-16 hasta 2026-11-15
    And el historial incluye el movimiento de hoy
    And el historial incluye el movimiento de hace 30 días
    And el historial no incluye el movimiento de hace 31 días

  @HU-G3-01 @api
  Scenario Outline: Validación del rango de fechas
    When consulto mi historial desde "<desde>" hasta "<hasta>"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: límites del rango
      | desde      | hasta      | estado | codigo          |
      | 2026-11-15 | 2026-11-15 | 200    |                 |
      | 2026-11-14 | 2026-11-15 | 200    |                 |
      | 2026-11-16 | 2026-11-15 | 422    | FILTRO_INVALIDO |
      | 2026-11-15 | 2026-11-16 | 422    | FILTRO_INVALIDO |
      | 2026-11-01 | 2026-11-16 | 422    | FILTRO_INVALIDO |

  @HU-G3-01 @api
  Scenario Outline: Rango máximo de 90 días
    # "Máximo 90 días" se mide como hasta - desde <= 90 (90 es válido, 91 no).
    When consulto mi historial desde "<desde>" hasta "2026-11-15"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: 89, 90 y 91 días de diferencia
      | desde      | estado | codigo          |
      | 2026-08-18 | 200    |                 |
      | 2026-08-17 | 200    |                 |
      | 2026-08-16 | 422    | FILTRO_INVALIDO |

  @HU-G3-01 @api
  Scenario Outline: Formato de fecha inválido
    When consulto mi historial desde "<desde>" hasta "2026-11-15"
    Then la respuesta es 422

    Examples:
      | desde      |
      | 15-11-2026 |
      | 2026-13-01 |
      | 2026-02-30 |
      | ayer       |

  @HU-G3-01 @api
  Scenario Outline: Filtro por tipo de movimiento
    Given que tengo una transferencia enviada, una recibida, una recarga y un pago de servicio ayer
    When consulto mi historial con el tipo "<tipo>"
    Then todos los movimientos devueltos son de tipo "<tipo>"
    And el total de movimientos es 1

    Examples:
      | tipo                   |
      | TRANSFERENCIA_ENVIADA  |
      | TRANSFERENCIA_RECIBIDA |
      | RECARGA                |
      | PAGO_SERVICIO          |

  @HU-G3-01 @api
  Scenario: Tipo de movimiento inexistente
    When consulto mi historial con el tipo "RETIRO"
    Then la respuesta es 422
    And el código de error es "FILTRO_INVALIDO"

  @HU-G3-01 @api
  Scenario: Filtro por una de mis categorías
    Given que tengo la categoría "Comida" con 2 movimientos asignados
    When consulto mi historial con esa categoría
    Then el total de movimientos es 2
    And todos los movimientos devueltos pertenecen a la categoría "Comida"

  @HU-G3-01 @api
  Scenario Outline: Filtro por una categoría que no es mía
    When consulto mi historial con la categoría <categoria>
    Then la respuesta es 422
    And el código de error es "FILTRO_INVALIDO"

    Examples:
      | categoria                   |
      | de otro usuario             |
      | inexistente (id 999999)     |

  @HU-G3-01 @api
  Scenario: Los filtros se combinan
    Given que tengo la categoría "Comida" con una recarga y una transferencia enviada
    When consulto mi historial con el tipo "RECARGA" y esa categoría
    Then el total de movimientos es 1

  @HU-G3-01 @api
  Scenario Outline: El rango incluye completos los días desde y hasta
    Given que tengo un movimiento con fecha "<fecha_movimiento>"
    When consulto mi historial desde "2026-11-10" hasta "2026-11-12"
    Then el movimiento <resultado> en el historial

    Examples: bordes de día en hora de Lima
      | fecha_movimiento    | resultado  |
      | 2026-11-09T23:59:59 | no aparece |
      | 2026-11-10T00:00:00 | aparece    |
      | 2026-11-12T23:59:59 | aparece    |
      | 2026-11-13T00:00:00 | no aparece |

  @HU-G3-01 @api
  Scenario Outline: Paginación de 10 movimientos por página
    Given que tengo exactamente <cantidad> movimientos en el rango consultado
    When consulto la página 1 de mi historial
    Then la página trae <en_pagina> movimientos
    And el total de movimientos es <cantidad>
    And el total de páginas es <paginas>

    Examples: límites de página
      | cantidad | en_pagina | paginas |
      | 0        | 0         | 0       |
      | 1        | 1         | 1       |
      | 9        | 9         | 1       |
      | 10       | 10        | 1       |
      | 11       | 10        | 2       |
      | 20       | 10        | 2       |
      | 21       | 10        | 3       |

  @HU-G3-01 @api
  Scenario: La última página trae el resto de los movimientos
    Given que tengo exactamente 21 movimientos en el rango consultado
    When consulto la página 3 de mi historial
    Then la página trae 1 movimientos

  @HU-G3-01 @api
  Scenario Outline: Número de página inválido
    When consulto la página <pagina> de mi historial
    Then la respuesta es 422

    Examples: la página es mayor o igual a 1
      | pagina |
      | 0      |
      | -1     |
      | abc    |

  @HU-G3-01 @api
  Scenario: Pedir una página mayor a la última
    Given que tengo exactamente 21 movimientos en el rango consultado
    When consulto la página 4 de mi historial
    Then la respuesta es 200
    And la página trae 0 movimientos

  @HU-G3-01 @api
  Scenario: Los movimientos van del más reciente al más antiguo y sin repetirse entre páginas
    Given que tengo exactamente 15 movimientos en el rango consultado
    When consulto las páginas 1 y 2 de mi historial
    Then las fechas están en orden descendente
    And ningún movimiento aparece en las dos páginas

  @HU-G3-01 @api
  Scenario: Cada movimiento muestra todos sus datos
    Given que hice una transferencia de S/ 100.00 a Bruno
    When consulto mi historial sin filtros
    Then el primer movimiento muestra fecha, tipo, descripción, contraparte, monto, comisión, importe, saldo posterior, categoría y nota
    And el importe es "-100.00"
    And el monto es "100.00"

  @HU-G3-01 @api
  Scenario: El importe de un ingreso es positivo
    Given que Bruno me transfirió S/ 40.00
    When consulto mi historial con el tipo "TRANSFERENCIA_RECIBIDA"
    Then el primer movimiento tiene importe "40.00"

  @HU-G3-01 @api
  Scenario: Una transferencia interbancaria muestra su comisión en el movimiento
    Given que hice una transferencia interbancaria de S/ 100.00
    When consulto mi historial sin filtros
    Then el primer movimiento muestra comisión "1.50"
    And el importe es "-101.50"

  @HU-G3-01 @api
  Scenario: Consultar el historial sin sesión
    Given que no tengo un token
    When consulto mi historial sin filtros
    Then la respuesta es 401
    And el código de error es "NO_AUTENTICADO"

  @HU-G3-01 @api
  Scenario: Solo veo mis propios movimientos
    Given que Bruno tiene movimientos que yo no tengo
    When consulto mi historial sin filtros
    Then ningún movimiento devuelto pertenece a Bruno

  # ---------------------------------------------------------------------------
  # HU-G3-02 · Ver el detalle de un movimiento (Alta)
  # ---------------------------------------------------------------------------

  @HU-G3-02 @api
  Scenario: Detalle de un movimiento propio
    Given que hice una transferencia de S/ 100.00 a Bruno
    When consulto el detalle de ese movimiento por su código de operación
    Then la respuesta es 200
    And el detalle coincide con el movimiento del historial

  @HU-G3-02 @api
  Scenario: Detalle de un movimiento de otro usuario
    Given que Bruno tiene un movimiento que no es mío
    When consulto el detalle de ese código de operación
    Then la respuesta es 404
    And el código de error es "MOVIMIENTO_NO_ENCONTRADO"

  @HU-G3-02 @api
  Scenario: Detalle de un código que no existe
    When consulto el detalle del código "NOEXISTE000"
    Then la respuesta es 404
    And el código de error es "MOVIMIENTO_NO_ENCONTRADO"

  @HU-G3-02 @api
  Scenario: Ambos usuarios ven la misma transferencia con el mismo código
    Given que hice una transferencia de S/ 25.00 a Bruno
    When Bruno consulta el detalle de ese código de operación
    Then Bruno ve un movimiento de tipo "TRANSFERENCIA_RECIBIDA" con importe "25.00"

  @HU-G3-02 @api
  Scenario: Detalle sin sesión
    Given que no tengo un token
    When consulto el detalle del código "NOEXISTE000"
    Then la respuesta es 401

  # ---------------------------------------------------------------------------
  # HU-G3-03 · Crear una categoría (Media)
  # R-G3-03: máx. 10, nombre 3-20 único sin distinguir mayúsculas, paleta de 8 colores
  # Ana parte con 3 categorías (Comida, Familia, Servicios).
  # ---------------------------------------------------------------------------

  @HU-G3-03 @api
  Scenario: Crear una categoría válida
    When creo la categoría "Ahorros" con el color "#43A047"
    Then la respuesta es 201
    And la categoría tiene 0 movimientos asignados

  @HU-G3-03 @api
  Scenario Outline: Longitud del nombre de la categoría
    When creo la categoría "<nombre>" con el color "#43A047"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: límites de 3 a 20 caracteres
      | nombre                | estado | codigo             |
      | ab                    | 422    | CATEGORIA_INVALIDA |
      | abc                   | 201    |                    |
      | abcd                  | 201    |                    |
      | ABCDEFGHIJKLMNOPQRS   | 201    |                    |
      | ABCDEFGHIJKLMNOPQRST  | 201    |                    |
      | ABCDEFGHIJKLMNOPQRSTU | 422    | CATEGORIA_INVALIDA |

  @HU-G3-03 @api
  Scenario: Los espacios alrededor del nombre no cuentan en la longitud
    When creo la categoría "  abc  " con el color "#43A047"
    Then la respuesta es 201
    And el nombre de la categoría es "abc"

  @HU-G3-03 @api
  Scenario: Nombre solo con espacios
    When creo la categoría "   " con el color "#43A047"
    Then la respuesta es 422
    And el código de error es "CATEGORIA_INVALIDA"

  @HU-G3-03 @api
  Scenario: Nombre vacío
    When creo la categoría "" con el color "#43A047"
    Then la respuesta es 422
    And el código de error es "CATEGORIA_INVALIDA"

  @HU-G3-03 @api
  Scenario Outline: Nombre duplicado sin distinguir mayúsculas
    When creo la categoría "<nombre>" con el color "#1E88E5"
    Then la respuesta es 409
    And el código de error es "CATEGORIA_DUPLICADA"

    Examples: ya tengo "Comida"
      | nombre |
      | Comida |
      | comida |
      | COMIDA |

  @HU-G3-03 @api
  Scenario: Otro usuario puede tener una categoría con el mismo nombre
    Given que Bruno tiene la categoría "Viajes"
    When creo la categoría "Viajes" con el color "#1E88E5"
    Then la respuesta es 201

  @HU-G3-03 @api
  Scenario Outline: Color de la paleta fija
    When creo la categoría "Color prueba" con el color "<color>"
    Then la respuesta es <estado>

    Examples: los 8 colores de la paleta
      | color    | estado |
      | #E53935  | 201    |
      | #FB8C00  | 201    |
      | #FDD835  | 201    |
      | #43A047  | 201    |
      | #00897B  | 201    |
      | #1E88E5  | 201    |
      | #8E24AA  | 201    |
      | #6D4C41  | 201    |

    Examples: colores fuera de la paleta
      | color    | estado |
      | #000000  | 422    |
      | rojo     | 422    |

    Examples: color de la paleta en minúsculas (se acepta sin distinguir mayúsculas)
      | color    | estado |
      | #e53935  | 201    |

  @HU-G3-03 @api
  Scenario: Un color en minúsculas se guarda en mayúsculas
    When creo la categoría "Color minus" con el color "#e53935"
    Then la respuesta es 201
    And el color de la categoría es "#E53935"

  @HU-G3-03 @api
  Scenario Outline: Límite de 10 categorías por usuario
    Given que tengo <existentes> categorías
    When creo la categoría "Nueva cat" con el color "#8E24AA"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples:
      | existentes | estado | codigo            |
      | 8          | 201    |                   |
      | 9          | 201    |                   |
      | 10         | 422    | LIMITE_CATEGORIAS |

  @HU-G3-03 @api
  Scenario: Crear una categoría sin enviar el color
    When creo la categoría "Sin color" sin enviar el color
    Then la respuesta es 422

  @HU-G3-03 @api
  Scenario: Crear una categoría sin sesión
    Given que no tengo un token
    When creo la categoría "Ahorros" con el color "#43A047"
    Then la respuesta es 401

  # ---------------------------------------------------------------------------
  # HU-G3-04 · Ver mis categorías (Baja)
  # ---------------------------------------------------------------------------

  @HU-G3-04 @api
  Scenario: Las categorías salen en orden alfabético con su cantidad de movimientos
    Given que creo la categoría "Ahorros"
    When consulto mis categorías
    Then los nombres salen en este orden: "Ahorros", "Comida", "Familia", "Servicios"
    And cada categoría indica la cantidad de movimientos asignados

  @HU-G3-04 @api
  Scenario: La cantidad de movimientos se actualiza al clasificar
    Given que la categoría "Comida" tiene 2 movimientos
    When clasifico un movimiento más en "Comida"
    Then la categoría "Comida" muestra 3 movimientos asignados

  @HU-G3-04 @api
  Scenario: Solo veo mis categorías
    Given que Bruno tiene la categoría "Viajes"
    When consulto mis categorías
    Then la lista no contiene "Viajes"

  # ---------------------------------------------------------------------------
  # HU-G3-05 · Editar una categoría (Baja)
  # ---------------------------------------------------------------------------

  @HU-G3-05 @api
  Scenario: Cambiar el nombre y el color
    When edito la categoría "Comida" con el nombre "Restaurantes" y el color "#FB8C00"
    Then la respuesta es 200
    And la categoría "Restaurantes" tiene el color "#FB8C00"

  @HU-G3-05 @api
  Scenario: Cambiar solo el color conserva el nombre
    When edito la categoría "Comida" enviando solo el color "#1E88E5"
    Then la respuesta es 200
    And la categoría se sigue llamando "Comida"

  @HU-G3-05 @api
  Scenario Outline: Cambiar el nombre de una categoría por uno que ya uso en otra
    When edito la categoría "Familia" con el nombre "<nombre>"
    Then la respuesta es 409
    And el código de error es "CATEGORIA_DUPLICADA"

    Examples:
      | nombre   |
      | Comida   |
      | comida   |

  @HU-G3-05 @api
  Scenario Outline: Cambiar solo las mayúsculas del propio nombre no es un duplicado
    When edito la categoría "Comida" con el nombre "<nombre>"
    Then la respuesta es 200

    Examples: la categoría no se compara consigo misma
      | nombre |
      | Comida |
      | COMIDA |
      | comida |

  @HU-G3-05 @api
  Scenario Outline: Longitud del nombre al editar
    When edito la categoría "Comida" con el nombre "<nombre>"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: límites de 3 a 20 caracteres
      | nombre                | estado | codigo             |
      | ab                    | 422    | CATEGORIA_INVALIDA |
      | abc                   | 200    |                    |
      | abcd                  | 200    |                    |
      | ABCDEFGHIJKLMNOPQRS   | 200    |                    |
      | ABCDEFGHIJKLMNOPQRST  | 200    |                    |
      | ABCDEFGHIJKLMNOPQRSTU | 422    | CATEGORIA_INVALIDA |

  @HU-G3-05 @api
  Scenario: Editar una categoría que no es mía
    Given que Bruno tiene la categoría "Viajes"
    When intento editar la categoría de Bruno con el nombre "Mia"
    Then la respuesta es 404

  @HU-G3-05 @api
  Scenario: Editar una categoría que no existe
    When intento editar la categoría con id 999999
    Then la respuesta es 404

  @HU-G3-05 @api
  Scenario: Editar una categoría no cambia sus movimientos
    Given que la categoría "Comida" tiene 2 movimientos
    When edito la categoría "Comida" con el nombre "Restaurantes"
    Then la categoría "Restaurantes" sigue teniendo 2 movimientos

  # ---------------------------------------------------------------------------
  # HU-G3-06 · Eliminar una categoría (Media)
  # ---------------------------------------------------------------------------

  @HU-G3-06 @api
  Scenario: Eliminar una categoría deja sus movimientos sin categoría
    Given que la categoría "Comida" tiene 2 movimientos con sus montos conocidos
    When elimino la categoría "Comida"
    Then la respuesta es 204
    And la categoría "Comida" ya no aparece en mi lista
    And esos 2 movimientos siguen en mi historial sin categoría
    And los montos de esos movimientos no cambiaron

  @HU-G3-06 @api
  Scenario: Eliminar una categoría que no es mía
    Given que Bruno tiene la categoría "Viajes"
    When intento eliminar la categoría de Bruno
    Then la respuesta es 404
    And la categoría de Bruno sigue existiendo

  @HU-G3-06 @api
  Scenario: Eliminar una categoría que no existe
    When intento eliminar la categoría con id 999999
    Then la respuesta es 404

  @HU-G3-06 @api
  Scenario: Eliminar una categoría que ya fue eliminada
    Given que eliminé la categoría "Comida"
    When elimino otra vez la categoría "Comida"
    Then la respuesta es 404

  @HU-G3-06 @api
  Scenario: Al eliminar una categoría puedo volver a usar su nombre y el cupo
    Given que tengo 10 categorías
    When elimino la categoría "Comida"
    And creo la categoría "Comida" con el color "#43A047"
    Then la respuesta es 201

  # ---------------------------------------------------------------------------
  # HU-G3-07 · Clasificar un movimiento (Media)
  # R-G3-04: nota de máximo 100 caracteres. RN-11: no cambia monto, fecha ni tipo.
  # ---------------------------------------------------------------------------

  @HU-G3-07 @api
  Scenario: Asignar una categoría propia a un movimiento propio
    Given que tengo un movimiento sin categoría
    When le asigno la categoría "Familia"
    Then la respuesta es 200
    And el movimiento muestra la categoría "Familia"

  @HU-G3-07 @api
  Scenario: Cambiar la categoría de un movimiento
    Given que tengo un movimiento en la categoría "Comida"
    When le asigno la categoría "Servicios"
    Then el movimiento muestra la categoría "Servicios"

  @HU-G3-07 @api
  Scenario: Quitar la categoría de un movimiento
    Given que tengo un movimiento en la categoría "Comida"
    When le quito la categoría enviando categoria_id nulo
    Then el movimiento queda sin categoría

  @HU-G3-07 @api
  Scenario Outline: Longitud de la nota
    Given que tengo un movimiento sin nota
    When le agrego una nota de <largo> caracteres
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: límites de 100 caracteres
      | largo | estado | codigo        |
      | 1     | 200    |               |
      | 99    | 200    |               |
      | 100   | 200    |               |
      | 101   | 422    | NOTA_INVALIDA |

  @HU-G3-07 @api
  Scenario: Editar y quitar una nota
    Given que tengo un movimiento con la nota "Cumpleaños"
    When cambio la nota a "Regalo"
    Then el movimiento muestra la nota "Regalo"
    When quito la nota
    Then el movimiento queda sin nota

  @HU-G3-07 @api
  Scenario: Enviar solo la nota no cambia la categoría
    Given que tengo un movimiento en la categoría "Comida"
    When le agrego la nota "Almuerzo" sin enviar categoría
    Then el movimiento sigue en la categoría "Comida"

  @HU-G3-07 @api
  Scenario: Asignar una categoría de otro usuario
    Given que Bruno tiene la categoría "Viajes"
    And que tengo un movimiento sin categoría
    When le asigno la categoría de Bruno
    Then la respuesta es 404
    And el código de error es "CATEGORIA_NO_ENCONTRADA"

  @HU-G3-07 @api
  Scenario: Asignar una categoría que no existe
    Given que tengo un movimiento sin categoría
    When le asigno la categoría con id 999999
    Then la respuesta es 404
    And el código de error es "CATEGORIA_NO_ENCONTRADA"

  @HU-G3-07 @api
  Scenario: Clasificar un movimiento de otro usuario
    Given que Bruno tiene un movimiento que no es mío
    When intento asignarle la categoría "Familia"
    Then la respuesta es 404
    And el código de error es "MOVIMIENTO_NO_ENCONTRADO"

  @HU-G3-07 @api
  Scenario: Clasificar un movimiento que no existe
    When intento asignar la categoría "Familia" al movimiento "NOEXISTE000"
    Then la respuesta es 404
    And el código de error es "MOVIMIENTO_NO_ENCONTRADO"

  @HU-G3-07 @api
  Scenario: Clasificar no modifica monto, fecha ni tipo
    Given que tengo un movimiento con monto, fecha y tipo conocidos
    When le asigno la categoría "Familia" y la nota "Prueba"
    Then el monto, la fecha y el tipo del movimiento no cambian
    And el saldo posterior del movimiento no cambia
    And mi saldo no cambia

  @HU-G3-07 @api
  Scenario: Intentar cambiar el monto al clasificar no tiene efecto
    Given que tengo un movimiento con monto "100.00"
    When envío una clasificación que incluye el monto "1.00"
    Then el movimiento sigue con monto "100.00"

  # ---------------------------------------------------------------------------
  # HU-G3-08 · Exportar mis movimientos (Media)
  # ---------------------------------------------------------------------------

  @HU-G3-08 @api
  Scenario: Exportar con el formato de columnas requerido
    Given que tengo movimientos en el rango consultado
    When exporto mis movimientos sin filtros
    Then la respuesta es 200 con contenido CSV en UTF-8
    And la primera fila es "fecha;codigo_operacion;tipo;descripcion;monto;comision;importe;categoria;nota"
    And cada fila de datos tiene 9 columnas separadas por punto y coma
    And los decimales usan punto

  @HU-G3-08 @api
  Scenario: Exportar sin movimientos devuelve solo el encabezado
    Given que no tengo movimientos en el rango consultado
    When exporto mis movimientos sin filtros
    Then el archivo contiene solo la fila de encabezado

  @HU-G3-08 @api
  Scenario Outline: La exportación no se pagina
    Given que tengo exactamente <cantidad> movimientos en el rango consultado
    When exporto mis movimientos sin filtros
    Then el archivo contiene <cantidad> filas de datos

    Examples: alrededor del tamaño de página
      | cantidad |
      | 1        |
      | 10       |
      | 11       |
      | 25       |

  @HU-G3-08 @api
  Scenario: La exportación respeta los mismos filtros que el historial
    Given que tengo movimientos de varios tipos en el rango consultado
    When exporto mis movimientos con el tipo "RECARGA"
    Then todas las filas son de tipo "RECARGA"
    And el número de filas es igual al total del historial con ese mismo filtro

  @HU-G3-08 @api
  Scenario Outline: La exportación aplica las mismas reglas de rango
    When exporto mis movimientos desde "<desde>" hasta "<hasta>"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples:
      | desde      | hasta      | estado | codigo          |
      | 2026-11-15 | 2026-11-15 | 200    |                 |
      | 2026-11-16 | 2026-11-15 | 422    | FILTRO_INVALIDO |
      | 2026-11-01 | 2026-11-16 | 422    | FILTRO_INVALIDO |

  @HU-G3-08 @api
  Scenario: La exportación aplica el máximo de 90 días
    When exporto mis movimientos desde "2026-08-16" hasta "2026-11-15"
    Then la respuesta es 422
    And el código de error es "FILTRO_INVALIDO"

  @HU-G3-08 @api
  Scenario: El CSV incluye categoría y nota con caracteres especiales
    Given que tengo un movimiento con la categoría "Comida" y la nota "Cumpleaños de Carla; ñandú"
    When exporto mis movimientos sin filtros
    Then la fila del movimiento conserva la tilde y la ñ
    And la nota con punto y coma no rompe el número de columnas

  @HU-G3-08 @api
  Scenario: Exportar sin sesión
    Given que no tengo un token
    When exporto mis movimientos sin filtros
    Then la respuesta es 401
