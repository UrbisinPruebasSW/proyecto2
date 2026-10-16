# language: en
@nucleo
Feature: Registrarme en Qolqe
  Como visitante
  Quiero crear una cuenta con mi DNI y celular
  Para usar la billetera

  @HU-N-01
  Scenario: Registro exitoso con todos los datos válidos
    When me registro con DNI "45678912", nombres "Lucía Mendoza", celular "987000111", PIN "5207" y correo "lucia@correo.pe"
    Then la respuesta es 201
    And mi saldo es "0.00"
    And mi límite diario es "2000.00"

  @HU-N-01
  Scenario: El correo es opcional
    When me registro con DNI "45678912", nombres "Lucía Mendoza", celular "987000111" y PIN "5207" sin correo
    Then la respuesta es 201

  @HU-N-01
  Scenario Outline: Validación del DNI
    When me registro con DNI "<dni>" y el resto de datos válidos
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: exactamente 8 dígitos numéricos
      | dni       | estado | codigo       |
      | 12345678  | 201    |              |
      | 123456789 | 422    | DNI_INVALIDO |
      | 1234567   | 422    | DNI_INVALIDO |
      | 1234567A  | 422    | DNI_INVALIDO |

  @HU-N-01
  Scenario Outline: Validación del celular
    When me registro con celular "<celular>" y el resto de datos válidos
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: 9 dígitos y empieza con 9
      | celular    | estado | codigo           |
      | 98765432   | 422    | CELULAR_INVALIDO |
      | 987000111  | 201    |                  |
      | 9870001112 | 422    | CELULAR_INVALIDO |
      | 887000111  | 422    | CELULAR_INVALIDO |
      | 900000000  | 201    |                  |
      | 99999999A  | 422    | CELULAR_INVALIDO |

  @HU-N-01
  Scenario: Celular ya registrado
    When me registro con el celular "987654321" y el resto de datos válidos
    Then la respuesta es 409
    And el código de error es "CELULAR_REGISTRADO"

  @HU-N-01
  Scenario: El celular de una cuenta cerrada no se puede reutilizar
    When me registro con el celular "934567812" y el resto de datos válidos
    Then la respuesta es 409
    And el código de error es "CELULAR_REGISTRADO"

  @HU-N-01
  Scenario Outline: Validación del PIN
    When me registro con el PIN "<pin>" y el resto de datos válidos
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: 4 dígitos, sin repetidos ni secuencias
      | pin    | estado | codigo       |
      | 5207   | 201    |              |
      | 1111   | 422    | PIN_INVALIDO |
      | 1234   | 422    | PIN_INVALIDO |
      | 4321   | 422    | PIN_INVALIDO |
      | 0123   | 422    | PIN_INVALIDO |
      | 123    | 422    | PIN_INVALIDO |
      | 52071  | 422    | PIN_INVALIDO |
      | 52A7   | 422    | PIN_INVALIDO |

  @HU-N-01
  Scenario Outline: Longitud de los nombres
    When me registro con nombres de <largo> caracteres y el resto de datos válidos
    Then la respuesta es <estado>

    Examples: de 2 a 80 caracteres
      | largo | estado |
      | 1     | 422    |
      | 2     | 201    |
      | 3     | 201    |
      | 79    | 201    |
      | 80    | 201    |
      | 81    | 422    |

  @HU-N-01
  Scenario Outline: Validación del correo
    When me registro con el correo "<correo>" y el resto de datos válidos
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples:
      | correo                 | estado | codigo            |
      | nuevo@correo.pe        | 201    |                   |
      | sin-arroba.pe          | 422    | CORREO_INVALIDO   |
      | ana.torres@correo.pe   | 409    | CORREO_REGISTRADO |
      | ANA.TORRES@CORREO.PE   | 409    | CORREO_REGISTRADO |

  @HU-N-01
  Scenario: El correo de una cuenta cerrada se puede volver a usar
    When me registro con el correo "fabian.rojas@correo.pe" y el resto de datos válidos
    Then la respuesta es 201

  @HU-N-01
  Scenario: Recibo un SMS de bienvenida
    When me registro con DNI "45678912", nombres "Lucía Mendoza", celular "987000111", PIN "5207" y correo "lucia@correo.pe"
    Then el celular "987000111" recibe un SMS de bienvenida

  @HU-N-01
  Scenario: Un registro rechazado no crea la cuenta ni envía SMS
    When me registro con DNI "123" y el resto de datos válidos
    Then el celular del intento no puede iniciar sesión
    And el celular del intento no recibe ningún SMS

  @HU-N-01
  Scenario: Faltan datos obligatorios
    When me registro sin enviar el DNI
    Then la respuesta es 422
