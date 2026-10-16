# language: en
@nucleo
Feature: Sesión, perfil y cierre de cuenta
  Como cliente
  Quiero iniciar y cerrar sesión, ver y editar mi perfil y cerrar mi cuenta
  Para usar Qolqe de forma segura

  # ---------------------------------------------------------------------------
  # HU-N-02 · Iniciar sesión (Alta)
  # ---------------------------------------------------------------------------

  @HU-N-02
  Scenario: Ingreso con credenciales correctas
    When inicio sesión con el celular 987654321 y el PIN 4826
    Then la respuesta es 200
    And recibo un token válido por 30 minutos
    And se crea una sesión activa

  @HU-N-02
  Scenario Outline: Credenciales incorrectas con mensaje genérico
    When inicio sesión con el celular <celular> y el PIN <pin>
    Then la respuesta es 401 con el código "CREDENCIALES_INVALIDAS"
    And el mensaje es el mismo en todos los casos
    And el mensaje no indica qué dato es incorrecto

    Examples:
      | celular   | pin  |
      | 987654321 | 1111 |
      | 987654321 | 4827 |
      | 900999888 | 4826 |
      | 900999888 | 1111 |

  @HU-N-02
  Scenario Outline: Bloqueo al tercer intento fallido consecutivo
    Given que ya fallé <previos> veces el PIN del celular 912345678
    When inicio sesión con el celular 912345678 y el PIN 0000
    Then la respuesta es <estado> con el código "<codigo>"

    Examples: límite de 3 intentos
      | previos | estado | codigo                 |
      | 0       | 401    | CREDENCIALES_INVALIDAS |
      | 1       | 401    | CREDENCIALES_INVALIDAS |
      | 2       | 423    | CUENTA_BLOQUEADA       |

  @HU-N-02
  Scenario: Al bloquearse la cuenta recibo un SMS de aviso
    Given que ya fallé 2 veces el PIN del celular 912345678
    When inicio sesión con el celular 912345678 y el PIN 0000
    Then el celular 912345678 recibe un SMS de aviso de bloqueo

  @HU-N-02
  Scenario: Con la cuenta bloqueada ni el PIN correcto permite ingresar
    Given que la cuenta del celular 912345678 está bloqueada
    When inicio sesión con el celular 912345678 y el PIN 7391
    Then la respuesta es 423 con el código "CUENTA_BLOQUEADA"

  @HU-N-02
  Scenario Outline: El bloqueo dura 15 minutos
    Given que la cuenta del celular 912345678 se bloqueó hace <minutos> minutos y <segundos> segundos
    When inicio sesión con el celular 912345678 y el PIN 7391
    Then la respuesta es <estado>

    Examples: antes y después del límite de 15 minutos
      | minutos | segundos | estado |
      | 14      | 59       | 423    |
      | 15      | 1        | 200    |

    Examples: borde exacto (a los 15:00 ya no está bloqueada)
      | minutos | segundos | estado |
      | 15      | 0        | 200    |

  @HU-N-02
  Scenario: Un ingreso exitoso reinicia el conteo de intentos
    Given que ya fallé 2 veces el PIN del celular 912345678
    And que inicio sesión correctamente con el PIN 7391
    When fallo 2 veces más el PIN del celular 912345678
    Then la cuenta no está bloqueada
    And inicio sesión correctamente con el PIN 7391

  @HU-N-02
  Scenario: Una cuenta cerrada no puede iniciar sesión
    When inicio sesión con el celular 934567812 y el PIN 6029
    Then la respuesta es 401 con el código "CUENTA_CERRADA"

  @HU-N-02
  Scenario: Ingreso desde un dispositivo que no es de confianza
    When inicio sesión con el celular 987654321 y el PIN 4826 desde el dispositivo "ffffffffffffffff"
    Then la respuesta es 200
    And el celular 987654321 recibe un SMS de alerta de nuevo dispositivo

  @HU-N-02
  Scenario: Ingreso desde un dispositivo de confianza no genera alerta
    When inicio sesión con el celular 987654321 y el PIN 4826 desde el dispositivo "a1b2c3d4e5f60718"
    Then la respuesta es 200
    And el celular 987654321 no recibe un SMS de alerta de nuevo dispositivo

  @HU-N-02
  Scenario: Ingreso sin enviar el dispositivo
    When inicio sesión con el celular 987654321 y el PIN 4826 sin enviar el dispositivo
    Then la respuesta es 200
    And el celular 987654321 no recibe un SMS de alerta de nuevo dispositivo

  @HU-N-02
  Scenario: Faltan datos para iniciar sesión
    When inicio sesión sin enviar el PIN
    Then la respuesta es 422

  # ---------------------------------------------------------------------------
  # HU-N-03 · Cerrar sesión (Alta)
  # ---------------------------------------------------------------------------

  @HU-N-03
  Scenario: Después de cerrar sesión el token deja de ser válido
    Given que inicié sesión como Ana
    When cierro mi sesión
    And consulto mi saldo con el mismo token
    Then la respuesta es 401 con el código "NO_AUTENTICADO"

  @HU-N-03
  Scenario: Cerrar una sesión no afecta mis otras sesiones
    Given que inicié sesión como Ana en dos sesiones distintas
    When cierro la primera sesión
    Then el token de la segunda sesión sigue funcionando

  @HU-N-03
  Scenario: Cerrar sesión dos veces con el mismo token
    Given que inicié sesión como Ana
    And que cierro mi sesión
    When cierro mi sesión otra vez con el mismo token
    Then la respuesta es 401

  # ---------------------------------------------------------------------------
  # HU-N-04 · Consultar mi saldo y perfil (Alta)
  # ---------------------------------------------------------------------------

  @HU-N-04
  Scenario: Consultar mi saldo
    Given que inicié sesión como Ana
    When consulto mi saldo
    Then el saldo es "1500.00"
    And la moneda es "PEN"
    And veo la fecha de la última actualización

  @HU-N-04
  Scenario: El saldo se actualiza después de una operación
    Given que inicié sesión como Ana
    And que transferí S/ 100.00 a Bruno
    When consulto mi saldo
    Then el saldo es "1400.00"

  @HU-N-04
  Scenario: Consultar mi perfil con el DNI enmascarado
    Given que inicié sesión como Ana
    When consulto mi perfil
    Then veo mis nombres, celular y correo
    And el DNI solo muestra sus últimos 4 dígitos
    And el DNI completo no aparece en la respuesta

  @HU-N-04
  Scenario Outline: Consultar sin una sesión válida
    Given que uso <token>
    When consulto mi saldo
    Then la respuesta es 401 con el código "NO_AUTENTICADO"

    Examples:
      | token                   |
      | ningún token            |
      | un token inválido       |
      | un token de otra firma  |
      | un token alterado       |
      | un token vencido        |

  # ---------------------------------------------------------------------------
  # HU-N-05 · Editar mi perfil (Media)
  # ---------------------------------------------------------------------------

  @HU-N-05
  Scenario: Actualizar nombres y correo
    Given que inicié sesión como Ana
    When cambio mis nombres a "Ana Torres Q." y mi correo a "ana.nueva@correo.pe"
    Then la respuesta es 200
    And mi perfil muestra los datos nuevos

  @HU-N-05
  Scenario Outline: Longitud de los nombres al editar
    Given que inicié sesión como Ana
    When cambio mis nombres a un texto de <largo> caracteres
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: de 2 a 80 caracteres
      | largo | estado | codigo          |
      | 1     | 422    | PERFIL_INVALIDO |
      | 2     | 200    |                 |
      | 3     | 200    |                 |
      | 79    | 200    |                 |
      | 80    | 200    |                 |
      | 81    | 422    | PERFIL_INVALIDO |

  @HU-N-05
  Scenario Outline: Correo al editar el perfil
    Given que inicié sesión como Ana
    When cambio mi correo a "<correo>"
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples:
      | correo               | estado | codigo            |
      | sin-arroba.pe        | 422    | CORREO_INVALIDO   |
      | bruno.diaz@correo.pe | 409    | CORREO_REGISTRADO |
      | BRUNO.DIAZ@CORREO.PE | 409    | CORREO_REGISTRADO |
      | ANA.TORRES@CORREO.PE | 200    |                   |

  @HU-N-05
  Scenario: El DNI y el celular no se pueden modificar
    Given que inicié sesión como Ana
    When envío un cambio de perfil que incluye otro DNI y otro celular
    Then la respuesta es 200
    And mi DNI y mi celular siguen iguales

  @HU-N-05
  Scenario: Al cambiar el correo recibo un SMS de aviso
    Given que inicié sesión como Ana
    When cambio mi correo a "ana.nueva@correo.pe"
    Then el celular 987654321 recibe un SMS de aviso de cambio de correo

  # ---------------------------------------------------------------------------
  # HU-N-06 · Cerrar mi cuenta (Media)
  # ---------------------------------------------------------------------------

  @HU-N-06
  Scenario: Cerrar mi cuenta con saldo cero
    Given que tengo una cuenta nueva con saldo "0.00" y sesión iniciada
    When cierro mi cuenta confirmando con mi PIN
    Then la respuesta es 204

  @HU-N-06
  Scenario: El PIN de confirmación es incorrecto
    Given que tengo una cuenta nueva con saldo "0.00" y sesión iniciada
    When cierro mi cuenta con un PIN incorrecto
    Then la respuesta es 422 con el código "PIN_INCORRECTO"
    And mi cuenta sigue activa

  @HU-N-06
  Scenario Outline: Solo se cierra con saldo exactamente cero
    Given que tengo una cuenta nueva con saldo "<saldo>" y sesión iniciada
    When cierro mi cuenta confirmando con mi PIN
    Then la respuesta es <estado>
    And el código de error es "<codigo>"

    Examples: límite del saldo cero
      | saldo | estado | codigo          |
      | 0.00  | 204    |                 |
      | 0.01  | 422    | SALDO_PENDIENTE |
      | 1.00  | 422    | SALDO_PENDIENTE |

  @HU-N-06
  Scenario Outline: No se cierra con solicitudes de dinero pendientes
    Given que tengo una cuenta con saldo "0.00" y una solicitud de dinero <tipo> pendiente
    When cierro mi cuenta confirmando con mi PIN
    Then la respuesta es 409 con el código "SOLICITUDES_PENDIENTES"

    Examples:
      | tipo     |
      | enviada  |
      | recibida |

  @HU-N-06
  Scenario Outline: Una solicitud vencida no impide cerrar la cuenta
    Given que tengo una cuenta con saldo "0.00" y una solicitud enviada hace <horas> horas
    When cierro mi cuenta confirmando con mi PIN
    Then la respuesta es <estado>

    Examples: vencimiento a las 48 horas
      | horas | estado |
      | 47    | 409    |
      | 49    | 204    |

    Examples: borde exacto (a las 48 h ya está vencida)
      | horas | estado |
      | 48    | 204    |

  @HU-N-06
  Scenario: Al cerrar la cuenta se cierran todas mis sesiones y no puedo volver a ingresar
    Given que tengo una cuenta nueva con saldo "0.00" y dos sesiones iniciadas
    When cierro mi cuenta confirmando con mi PIN
    Then los tokens de ambas sesiones dejan de funcionar
    And iniciar sesión responde 401 con el código "CUENTA_CERRADA"

  @HU-N-06
  Scenario: Nadie puede transferirme después de cerrar mi cuenta
    Given que cerré mi cuenta nueva
    When Ana me transfiere S/ 10.00
    Then la respuesta es 422 con el código "DESTINO_INACTIVO"
