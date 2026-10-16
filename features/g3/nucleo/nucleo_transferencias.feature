# language: en
@nucleo
Feature: Transferencias y comisión
  Como cliente
  Quiero enviar dinero a otros usuarios de Qolqe o a otros bancos
  Para pagar de inmediato

  Background:
    Given que inicié sesión como Ana

  # ---------------------------------------------------------------------------
  # HU-N-07 · Transferir a otro usuario Qolqe (Alta)
  # ---------------------------------------------------------------------------

  @HU-N-07 @api
  Scenario: Transferencia exitosa a un usuario registrado
    When transfiero S/ 100.00 al celular 912345678
    Then la respuesta es 201
    And la transferencia se realiza con un código de operación
    And mi saldo es "1400.00"
    And el saldo de Bruno es "900.00"
    And Bruno recibe un SMS con el monto

  @HU-N-07 @api
  Scenario Outline: Validación del monto por operación
    When transfiero S/ <monto> al celular 912345678
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: mayor a 0, máximo 2 decimales y hasta 500.00
      | monto  | estado | codigo         |
      | -1.00  | 422    | MONTO_INVALIDO |
      | 0.00   | 422    | MONTO_INVALIDO |
      | 0.01   | 201    |                |
      | 0.02   | 201    |                |
      | 0.001  | 422    | MONTO_INVALIDO |
      | 10.005 | 422    | MONTO_INVALIDO |
      | 100.50 | 201    |                |
      | 499.99 | 201    |                |
      | 500.00 | 201    |                |
      | 500.01 | 422    | MONTO_INVALIDO |
      | 501.00 | 422    | MONTO_INVALIDO |

  @HU-N-07 @api
  Scenario Outline: El monto debe ser un número
    When transfiero el monto "<monto>" al celular 912345678
    Then la respuesta es 422

    Examples:
      | monto |
      | abc   |
      | 1,50  |
      |       |

  @HU-N-07 @api
  Scenario: No puedo transferirme a mí mismo
    When transfiero S/ 10.00 al celular 987654321
    Then la respuesta es 422 con el código "TRANSFERENCIA_A_SI_MISMO"
    And mi saldo no cambia

  @HU-N-07 @api
  Scenario: Destino no registrado
    When transfiero S/ 10.00 al celular 900999888
    Then la respuesta es 404 con el código "DESTINO_NO_REGISTRADO"
    And mi saldo no cambia

  @HU-N-07 @api
  Scenario: Destino con cuenta cerrada
    When transfiero S/ 10.00 al celular 934567812
    Then la respuesta es 422 con el código "DESTINO_INACTIVO"
    And mi saldo no cambia

  @HU-N-07 @api
  Scenario Outline: El saldo debe cubrir el monto
    Given que inicié sesión como Carla
    When transfiero S/ <monto> al celular 987654321
    Then la respuesta es <estado>
    And el código de error es "<codigo>"
    And mi saldo es "<saldo_final>"

    Examples: Carla tiene S/ 50.00
      | monto | estado | codigo              | saldo_final |
      | 49.99 | 201    |                     | 0.01        |
      | 50.00 | 201    |                     | 0.00        |
      | 50.01 | 422    | SALDO_INSUFICIENTE  | 50.00       |

  @HU-N-07 @api
  Scenario Outline: Límite diario de S/ 2,000.00
    Given que hoy ya transferí S/ <previo> en el día
    When transfiero S/ <monto> al celular 912345678
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: Ana tiene S/ 1500.00 en saldo; el saldo se repone antes de cada caso
      | previo  | monto  | estado | codigo                 |
      | 1500.00 | 500.00 | 201    |                        |
      | 1600.00 | 400.01 | 422    | LIMITE_DIARIO_EXCEDIDO |
      | 1999.98 | 0.01   | 201    |                        |
      | 1999.99 | 0.01   | 201    |                        |
      | 2000.00 | 0.01   | 422    | LIMITE_DIARIO_EXCEDIDO |
      | 1999.99 | 0.02   | 422    | LIMITE_DIARIO_EXCEDIDO |

  @HU-N-07 @api
  Scenario Outline: Límite diario configurado por el usuario
    Given que inicié sesión como Diego
    And que hoy ya transferí S/ <previo> en el día
    When transfiero S/ <monto> al celular 912345678
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: Diego tiene un límite diario de S/ 1,000.00
      | previo  | monto  | estado | codigo                 |
      | 500.00  | 500.00 | 201    |                        |
      | 600.00  | 400.01 | 422    | LIMITE_DIARIO_EXCEDIDO |
      | 999.99  | 0.01   | 201    |                        |
      | 1000.00 | 0.01   | 422    | LIMITE_DIARIO_EXCEDIDO |

  @HU-N-07 @api
  Scenario: Las transferencias interbancarias cuentan para el límite diario
    Given que hoy ya hice una transferencia interbancaria de S/ 500.00 y otra a Qolqe de S/ 500.00 y otra de S/ 500.00
    And que mi saldo es "2000.00"
    When transfiero S/ 500.00 al celular 912345678
    Then la respuesta es 201
    When transfiero S/ 0.01 al celular 912345678
    Then la respuesta es 422 con el código "LIMITE_DIARIO_EXCEDIDO"

  @HU-N-07 @api
  Scenario Outline: El límite diario se reinicia a medianoche de Lima
    Given que ayer a las 23:59:59 transferí S/ 2000.00 en total
    And que ahora es "<ahora>"
    When transfiero S/ 100.00 al celular 912345678
    Then la respuesta es <estado>

    Examples:
      | ahora               | estado |
      | 2026-11-15T23:59:59 | 422    |
      | 2026-11-16T00:00:00 | 201    |

  @HU-N-07 @api
  Scenario Outline: Longitud de la descripción
    When transfiero S/ 10.00 al celular 912345678 con una descripción de <largo> caracteres
    Then la respuesta es <estado>

    Examples: hasta 60 caracteres
      | largo | estado |
      | 0     | 201    |
      | 1     | 201    |
      | 59    | 201    |
      | 60    | 201    |
      | 61    | 422    |

  @HU-N-07 @api
  Scenario: Ambos usuarios ven el movimiento con el mismo código de operación
    When transfiero S/ 100.00 al celular 912345678
    Then mi historial y el de Bruno muestran un movimiento con el mismo código de operación
    And el mío es "TRANSFERENCIA_ENVIADA" con importe "-100.00"
    And el de Bruno es "TRANSFERENCIA_RECIBIDA" con importe "100.00"

  @HU-N-07 @api
  Scenario: Dos transferencias distintas tienen códigos de operación distintos
    When transfiero S/ 10.00 al celular 912345678
    And transfiero S/ 10.00 al celular 912345678
    Then los dos códigos de operación son distintos

  @HU-N-07 @api
  Scenario: El comprobante muestra los datos de la operación
    When transfiero S/ 100.00 al celular 912345678
    Then el comprobante muestra el código de operación, el nombre del destinatario enmascarado y su celular
    And el comprobante muestra monto "100.00", comisión "0.00", total "100.00" y mi nuevo saldo "1400.00"
    And el comprobante muestra la fecha
    And el nombre completo del destinatario no aparece

  @HU-N-07 @api
  Scenario: Una transferencia rechazada no genera movimiento ni cambia saldos
    When transfiero S/ 500.01 al celular 912345678
    Then no se crea ningún movimiento
    And el saldo de Bruno no cambia

  @HU-N-07 @api
  Scenario: Transferir sin sesión
    Given que no tengo un token
    When transfiero S/ 10.00 al celular 912345678
    Then la respuesta es 401 con el código "NO_AUTENTICADO"

  @HU-N-07 @api @concurrencia
  Scenario: Transferencias simultáneas no dejan el saldo negativo
    Given que inicié sesión como Carla con saldo "50.00"
    When envío al mismo tiempo 5 transferencias de S/ 20.00 al celular 987654321
    Then exactamente 2 transferencias son exitosas
    And las demás responden "SALDO_INSUFICIENTE"
    And mi saldo es "10.00"

  @HU-N-07 @api @concurrencia
  Scenario: Transferencias simultáneas no superan el límite diario
    Given que mi saldo es "5000.00" y que hoy ya transferí S/ 1500.00
    When envío al mismo tiempo 3 transferencias de S/ 200.00 al celular 912345678
    Then exactamente 2 transferencias son exitosas
    And la otra responde "LIMITE_DIARIO_EXCEDIDO"
    And el total transferido hoy es S/ 1900.00

  # ---------------------------------------------------------------------------
  # HU-N-08 · Transferir a otro banco (Alta)
  # ---------------------------------------------------------------------------

  @HU-N-08 @api
  Scenario Outline: Validación del CCI
    When transfiero S/ 100.00 al CCI "<cci>"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: exactamente 20 dígitos
      | cci                   | estado | codigo       |
      | 0021930012345678901   | 422    | CCI_INVALIDO |
      | 00219300123456789012  | 201    |              |
      | 002193001234567890123 | 422    | CCI_INVALIDO |
      | 0021930012345678901A  | 422    | CCI_INVALIDO |

  @HU-N-08 @api
  Scenario: La transferencia interbancaria cobra comisión
    When transfiero S/ 100.00 al CCI "00219300123456789012"
    Then la respuesta es 201
    And la comisión es "1.50"
    And el total es "101.50"
    And mi saldo es "1398.50"

  @HU-N-08 @api
  Scenario Outline: El saldo debe cubrir el monto más la comisión
    Given que mi saldo es "<saldo>"
    When transfiero S/ 100.00 al CCI "00219300123456789012"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: el total es S/ 101.50
      | saldo  | estado | codigo             |
      | 101.49 | 422    | SALDO_INSUFICIENTE |
      | 101.50 | 201    |                    |
      | 101.51 | 201    |                    |
      | 100.00 | 422    | SALDO_INSUFICIENTE |

  @HU-N-08 @api
  Scenario Outline: Aplican las reglas de monto de las transferencias
    When transfiero S/ <monto> al CCI "00219300123456789012"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples:
      | monto  | estado | codigo         |
      | 0.00   | 422    | MONTO_INVALIDO |
      | 0.01   | 201    |                |
      | 500.00 | 201    |                |
      | 500.01 | 422    | MONTO_INVALIDO |
      | 10.005 | 422    | MONTO_INVALIDO |

  @HU-N-08 @api
  Scenario: El movimiento interbancario muestra el CCI enmascarado
    When transfiero S/ 100.00 al CCI "00219300123456789012"
    Then el movimiento muestra solo los últimos 4 dígitos del CCI
    And el CCI completo no aparece en el historial

  # ---------------------------------------------------------------------------
  # HU-N-09 · Simular la comisión (Media) · RN-09
  # ---------------------------------------------------------------------------

  @HU-N-09 @api
  Scenario Outline: Comisión de una transferencia interbancaria
    When simulo una transferencia INTERBANCARIA de S/ <monto>
    Then la comisión es "<comision>"
    And el total es "<total>"

    Examples: 1.5 % con mínimo S/ 1.00, máximo S/ 5.00 y redondeo comercial
      | monto  | comision | total  |
      | 0.01   | 1.00     | 1.01   |
      | 66.66  | 1.00     | 67.66  |
      | 66.67  | 1.00     | 67.67  |
      | 67.00  | 1.01     | 68.01  |
      | 100.00 | 1.50     | 101.50 |
      | 133.00 | 2.00     | 135.00 |
      | 200.00 | 3.00     | 203.00 |
      | 332.00 | 4.98     | 336.98 |
      | 333.00 | 5.00     | 338.00 |
      | 333.34 | 5.00     | 338.34 |
      | 500.00 | 5.00     | 505.00 |

  @HU-N-09 @api
  Scenario Outline: Las transferencias entre cuentas Qolqe no tienen comisión
    When simulo una transferencia QOLQE de S/ <monto>
    Then la comisión es "0.00"
    And el total es "<monto>"

    Examples:
      | monto  |
      | 0.01   |
      | 100.00 |
      | 500.00 |

  @HU-N-09 @api
  Scenario: Si no indico el tipo se simula una transferencia Qolqe
    When simulo una transferencia de S/ 100.00 sin indicar el tipo
    Then la comisión es "0.00"

  @HU-N-09 @api
  Scenario: Simular no realiza ninguna operación
    When simulo una transferencia INTERBANCARIA de S/ 100.00
    Then mi saldo no cambia
    And no se crea ningún movimiento

  @HU-N-09 @api
  Scenario Outline: La simulación valida el monto
    When simulo una transferencia QOLQE de S/ <monto>
    Then la respuesta es 422 con el código "MONTO_INVALIDO"

    Examples:
      | monto  |
      | 0.00   |
      | -5.00  |
      | 500.01 |
      | 10.005 |

  @HU-N-09 @api
  Scenario: Simular un tipo inexistente
    When simulo una transferencia de tipo "CRIPTO" de S/ 100.00
    Then la respuesta es 422

  @HU-N-09 @api
  Scenario: Simular sin sesión
    Given que no tengo un token
    When simulo una transferencia INTERBANCARIA de S/ 100.00
    Then la respuesta es 401 con el código "NO_AUTENTICADO"
