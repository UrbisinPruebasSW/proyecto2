# Análisis de particiones de equivalencia (PE) y valores límite (VL) · G3 Historial

## HU-N-01 CA2 · R-N-01 · Validar DNI

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | size(DNI) = 8 and is_numeric(DNI) | Válida | 12345678 | 201, DNI válido |
| PE-02 | size(DNI) ≠ 8 | Inválida | 123456789 | 422 `DNI_INVALIDO` |
| PE-03 | !is_numeric(DNI) | Inválida | 1234567A | 422 `DNI_INVALIDO` |

#### Valores límite (largo)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | 8 − 1 | 7 dígitos | 422 `DNI_INVALIDO` | `Validación del DNI` | Pendiente |
| VL-02 | 8 | 8 dígitos | 201 | `Validación del DNI` | Pendiente |
| VL-03 | 8 + 1 | 9 dígitos | 422 `DNI_INVALIDO` | `Validación del DNI` | Pendiente |

## HU-N-01 CA1 · Nombres

#### Valores límite (largo, de 2 a 80)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 1 | 1 | 422 | `Longitud de los nombres` | Pendiente |
| VL-02 | mín | 2 | 201 | `Longitud de los nombres` | Pendiente |
| VL-03 | mín + 1 | 3 | 201 | `Longitud de los nombres` | Pendiente |
| VL-04 | máx − 1 | 79 | 201 | `Longitud de los nombres` | Pendiente |
| VL-05 | máx | 80 | 201 | `Longitud de los nombres` | Pendiente |
| VL-06 | máx + 1 | 81 | 422 | `Longitud de los nombres` | Pendiente |

## HU-N-01 CA3 · R-N-02 · Validar celular

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | size(celular) = 9 and celular empieza con 9 and no registrado | Válida | 987000111 | 201, celular válido |
| PE-02 | size(celular) ≠ 9 | Inválida | 98765432 | 422 `CELULAR_INVALIDO` |
| PE-03 | celular no empieza con 9 | Inválida | 887000111 | 422 `CELULAR_INVALIDO` |
| PE-04 | celular no numérico | Inválida | 99999999A | 422 `CELULAR_INVALIDO` |
| PE-05 | celular registrado (activo) | Inválida | 987654321 | 409 `CELULAR_REGISTRADO` |
| PE-06 | celular de cuenta cerrada | Inválida | 934567812 | 409 `CELULAR_REGISTRADO` |

---

## HU-N-01 CA4 · R-N-03 · Validar PIN

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | size(PIN) = 4 and digitos diferentes and not secuencia ascendente o descendente | Válida | 5207 | 201, PIN válido |
| PE-02 | size(PIN) ≠ 4 | Inválida | 123 (3), 52071 (5) | 422 `PIN_INVALIDO` |
| PE-03 | dígitos iguales | Inválida | 1111 | 422 `PIN_INVALIDO` |
| PE-04 | secuencia ascendente o descendente | Inválida | 1234, 4321, 0123 | 422 `PIN_INVALIDO` |
| PE-05 | no numérico | Inválida | 52A7 | 422 `PIN_INVALIDO` |

---

## HU-N-01 CA5 · Validar correo (opcional)

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | correo con formato válido and no usado por cuenta activa | Válida | nuevo@correo.pe | 201 |
| PE-02 | correo omitido | Válida | (sin campo) | 201 |
| PE-03 | correo de una cuenta cerrada | Válida | fabian.rojas@correo.pe | 201 |
| PE-04 | correo con formato inválido | Inválida | sin-arroba.pe | 422 `CORREO_INVALIDO` |
| PE-05 | correo ya registrado (activo) | Inválida | ana.torres@correo.pe | 409 `CORREO_REGISTRADO` |
| PE-06 | correo ya registrado con otras mayúsculas | Inválida | ANA.TORRES@CORREO.PE | 409 `CORREO_REGISTRADO` |

---

## HU-N-02 CA2 · Credenciales

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | celular existe and PIN correcto | Válida | 987654321 / 4826 | 200, token |
| PE-02 | celular existe and PIN incorrecto | Inválida | 987654321 / 4827 | 401 `CREDENCIALES_INVALIDAS` |
| PE-03 | celular no existe (PIN cualquiera) | Inválida | 900999888 / 4826 | 401 `CREDENCIALES_INVALIDAS`, mismo mensaje que PE-02 |

## HU-N-02 CA3 · RN-04 · Bloqueo por intentos fallidos

#### Valores límite

| ID | Borde | Valor (intento fallido) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | máx − 2 | 1.º (previos = 0) | 401 `CREDENCIALES_INVALIDAS` | `Bloqueo al tercer intento fallido consecutivo` | Pendiente |
| VL-02 | máx − 1 | 2.º (previos = 1) | 401 `CREDENCIALES_INVALIDAS` | `Bloqueo al tercer intento fallido consecutivo` | Pendiente |
| VL-03 | máx | 3.º (previos = 2) | 423 `CUENTA_BLOQUEADA` + SMS | `Bloqueo al tercer intento fallido consecutivo` | Pendiente |

## HU-N-02 CA4 · RN-04 · Duración del bloqueo (15 min)

#### Valores límite (tiempo)

| ID | Borde | Valor (tiempo desde el bloqueo) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | 15:00 − 1 s | 14:59 | 423 `CUENTA_BLOQUEADA` | `El bloqueo dura 15 minutos` | Pendiente |
| VL-02 | 15:00 | 15:00 | 200 | `El bloqueo dura 15 minutos` | Pendiente |
| VL-03 | 15:00 + 1 s | 15:01 | 200 | `El bloqueo dura 15 minutos` | Pendiente |

**Decisión:** a los 15:00 exactos la cuenta ya no está bloqueada (el bloqueo rige mientras `ahora < bloqueado_hasta`). VL-02 queda con esperado 200.

## HU-N-02 CA5 · Estado de la cuenta

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | cuenta activa, PIN correcto | Válida | 987654321 / 4826 | 200 |
| PE-02 | cuenta bloqueada (PIN correcto) | Inválida | 912345678 / 7391 | 423 `CUENTA_BLOQUEADA` |
| PE-03 | cuenta cerrada | Inválida | 934567812 / 6029 | 401 `CUENTA_CERRADA` |

## HU-N-02 CA6 · Dispositivo

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | dispositivo de confianza | Válida | `a1b2c3d4e5f60718` | 200, sin SMS de alerta |
| PE-02 | dispositivo no registrado (nuevo) | Válida | `ffffffffffffffff` | 200, SMS "nuevo dispositivo" |
| PE-03 | dispositivo no enviado | Válida | (sin campo) | 200, sin SMS |

**Decisión:** sin `dispositivo_id` no se manda la alerta; solo se alerta cuando se envía un identificador que no está en los dispositivos del usuario. PE-03 queda con esperado 200, sin SMS.

---

## HU-N-04 CA3 · Token

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | token vigente | Válida | token recién emitido | 200 |
| PE-02 | token ausente | Inválida | (sin header) | 401 `NO_AUTENTICADO` |
| PE-03 | token con formato inválido | Inválida | `abc` | 401 `NO_AUTENTICADO` |
| PE-04 | token de otra firma | Inválida | JWT firmado con otra clave | 401 `NO_AUTENTICADO` |
| PE-05 | token alterado | Inválida | payload modificado | 401 `NO_AUTENTICADO` |
| PE-06 | token vencido (> 30 min) | Inválida | token con 31 min | 401 `NO_AUTENTICADO` · `Consultar sin una sesión válida` |

---

## HU-N-05 CA1 · Nombres

#### Valores límite (largo, de 2 a 80)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 1 | 1 | 422 `PERFIL_INVALIDO` | `Longitud de los nombres al editar` | Pendiente |
| VL-02 | mín | 2 | 200 | `Longitud de los nombres al editar` | Pendiente |
| VL-03 | mín + 1 | 3 | 200 | `Longitud de los nombres al editar` | Pendiente |
| VL-04 | máx − 1 | 79 | 200 | `Longitud de los nombres al editar` | Pendiente |
| VL-05 | máx | 80 | 200 | `Longitud de los nombres al editar` | Pendiente |
| VL-06 | máx + 1 | 81 | 422 `PERFIL_INVALIDO` | `Longitud de los nombres al editar` | Pendiente |

## HU-N-05 CA1 · Correo

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | formato válido and no usado por otra cuenta activa | Válida | ana.nueva@correo.pe | 200 |
| PE-02 | el propio correo con otras mayúsculas | Válida | ANA.TORRES@CORREO.PE | 200 |
| PE-03 | formato inválido | Inválida | sin-arroba.pe | 422 `CORREO_INVALIDO` |
| PE-04 | usado por otra cuenta (sin distinguir mayúsculas) | Inválida | BRUNO.DIAZ@CORREO.PE | 409 `CORREO_REGISTRADO` |

---

## HU-N-06 CA1 · PIN de confirmación

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | PIN igual al de la cuenta | Válida | PIN propio | 204 |
| PE-02 | PIN distinto | Inválida | PIN incorrecto | 422 `PIN_INCORRECTO`, cuenta sigue activa |

## HU-N-06 CA2 · Saldo para cerrar

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | saldo = 0.00 | Válida | 0.00 | 204 |
| PE-02 | saldo > 0.00 | Inválida | 1.00 | 422 `SALDO_PENDIENTE` |

#### Valores límite

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | límite | 0.00 | 204 | `Solo se cierra con saldo exactamente cero` | Pendiente |
| VL-02 | límite + 1 centavo | 0.01 | 422 `SALDO_PENDIENTE` | `Solo se cierra con saldo exactamente cero` | Pendiente |
| VL-03 | partición inválida | 1.00 | 422 `SALDO_PENDIENTE` | `Solo se cierra con saldo exactamente cero` | Pendiente |

## HU-N-06 CA3 · Solicitudes de dinero pendientes

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | sin solicitudes | Válida | — | 204 |
| PE-02 | solicitud enviada pendiente (no vencida) | Inválida | enviada hace 1 h | 409 `SOLICITUDES_PENDIENTES` |
| PE-03 | solicitud recibida pendiente (no vencida) | Inválida | recibida hace 1 h | 409 `SOLICITUDES_PENDIENTES` |
| PE-04 | solicitud vencida (> 48 h) | Válida | enviada hace 72 h | 204 |

#### Valores límite (tiempo, vencimiento a las 48 h)

| ID | Borde | Valor (antigüedad) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | 48 h − 1 | 47 h | 409 | `Una solicitud vencida no impide cerrar la cuenta` | Pendiente |
| VL-02 | 48 h | 48 h exactas | 204 (ya vencida) | `Una solicitud vencida no impide cerrar la cuenta` | Pendiente |
| VL-03 | 48 h + 1 | 49 h | 204 | `Una solicitud vencida no impide cerrar la cuenta` | Pendiente |

**Decisión:** a las 48 h exactas la solicitud ya está vencida (vence cuando `ahora >= vence_en`), por lo que no impide cerrar la cuenta.

---

## HU-N-07 CA1 · Descripción

#### Valores límite (largo, de 0 a 60; es opcional)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín | 0 | 201 | `Longitud de la descripción` | Pendiente |
| VL-02 | mín + 1 | 1 | 201 | `Longitud de la descripción` | Pendiente |
| VL-03 | máx − 1 | 59 | 201 | `Longitud de la descripción` | Pendiente |
| VL-04 | máx | 60 | 201 | `Longitud de la descripción` | Pendiente |
| VL-05 | máx + 1 | 61 | 422 | `Longitud de la descripción` | Pendiente |

**Decisión:** el requisito no define el código de error de una descripción de más de 60 caracteres, así que el escenario solo exige 422 y no fija el código.

## HU-N-07 CA2 · RN-05 · Monto por operación

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | 0.00 < monto ≤ 500.00 and máx. 2 decimales | Válida | 100.50 | 201 |
| PE-02 | monto ≤ 0.00 | Inválida | -1.00 | 422 `MONTO_INVALIDO` |
| PE-03 | monto > 500.00 | Inválida | 501.00 | 422 `MONTO_INVALIDO` |
| PE-04 | más de 2 decimales | Inválida | 10.005 | 422 `MONTO_INVALIDO` |
| PE-05 | no numérico o vacío | Inválida | `abc`, `1,50`, `` | 422 |

#### Valores límite

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 0.01 | 0.00 | 422 `MONTO_INVALIDO` | `Validación del monto por operación` | Pendiente |
| VL-02 | mín | 0.01 | 201 | `Validación del monto por operación` | Pendiente |
| VL-03 | mín + 0.01 | 0.02 | 201 | `Validación del monto por operación` | Pendiente |
| VL-04 | máx − 0.01 | 499.99 | 201 | `Validación del monto por operación` | Pendiente |
| VL-05 | máx | 500.00 | 201 | `Validación del monto por operación` | Pendiente |
| VL-06 | máx + 0.01 | 500.01 | 422 `MONTO_INVALIDO` | `Validación del monto por operación` | Pendiente |
| VL-07 | decimales: máx + 1 | 0.001 | 422 `MONTO_INVALIDO` | `Validación del monto por operación` | Pendiente |

## HU-N-07 CA2 · RN-07 · Destino

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | celular registrado, activo y distinto del propio | Válida | 912345678 | 201 |
| PE-02 | el propio celular | Inválida | 987654321 | 422 `TRANSFERENCIA_A_SI_MISMO` |
| PE-03 | celular no registrado | Inválida | 900999888 | 404 `DESTINO_NO_REGISTRADO` |
| PE-04 | cuenta cerrada | Inválida | 934567812 | 422 `DESTINO_INACTIVO` |

## HU-N-07 CA2 · RN-08 · Saldo contra monto (Carla, saldo S/ 50.00)

#### Valores límite

| ID | Borde | Valor (monto) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | saldo − 0.01 | 49.99 | 201, saldo final 0.01 | `El saldo debe cubrir el monto` | Pendiente |
| VL-02 | saldo | 50.00 | 201, saldo final 0.00 | `El saldo debe cubrir el monto` | Pendiente |
| VL-03 | saldo + 0.01 | 50.01 | 422 `SALDO_INSUFICIENTE`, saldo 50.00 | `El saldo debe cubrir el monto` | Pendiente |

## HU-N-07 CA2 · RN-06 · Límite diario (Ana S/ 2,000.00; Diego S/ 1,000.00)

#### Valores límite (acumulado del día + monto)

| ID | Borde | Valor (previo + monto) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | límite − 0.01 | 1999.98 + 0.01 = 1999.99 | 201 | `Límite diario de S/ 2,000.00` | Pendiente |
| VL-02 | límite | 1999.99 + 0.01 = 2000.00 | 201 | `Límite diario de S/ 2,000.00` | Pendiente |
| VL-03 | límite + 0.01 | 2000.00 + 0.01 | 422 `LIMITE_DIARIO_EXCEDIDO` | `Límite diario de S/ 2,000.00` | Pendiente |
| VL-04 | límite + 0.01 | 1999.99 + 0.02 = 2000.01 | 422 `LIMITE_DIARIO_EXCEDIDO` | `Límite diario de S/ 2,000.00` | Pendiente |
| VL-05 | límite de Diego | 999.99 + 0.01 = 1000.00 | 201 | `Límite diario configurado por el usuario` | Pendiente |
| VL-06 | límite de Diego + 0.01 | 1000.00 + 0.01 | 422 `LIMITE_DIARIO_EXCEDIDO` | `Límite diario configurado por el usuario` | Pendiente |

**Observación:** las filas `500.00 + 500.01` (Ana con 1500 y Diego con 500) no prueban el límite diario: fallan antes por RN-05 (`MONTO_INVALIDO`). Para probar el límite con un monto válido usar, por ejemplo, Diego `600.00 + 400.01` → 422 `LIMITE_DIARIO_EXCEDIDO`.

## HU-N-07 CA2 · RN-06 · Reinicio a medianoche de Lima

#### Valores límite (tiempo)

| ID | Borde | Valor (hora de Lima) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | 00:00:00 − 1 s | 23:59:59 | 422 (sigue el día anterior, límite agotado) | `El límite diario se reinicia a medianoche de Lima` | Pendiente |
| VL-02 | 00:00:00 | 00:00:00 | 201 (día nuevo) | `El límite diario se reinicia a medianoche de Lima` | Pendiente |

---

## HU-N-08 CA1 · CCI

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | size(CCI) = 20 and is_numeric(CCI) | Válida | 00219300123456789012 | 201 |
| PE-02 | size(CCI) ≠ 20 | Inválida | 0021930012345678901 | 422 `CCI_INVALIDO` |
| PE-03 | !is_numeric(CCI) | Inválida | 0021930012345678901A | 422 `CCI_INVALIDO` |

#### Valores límite (largo)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | 20 − 1 | 19 dígitos | 422 `CCI_INVALIDO` | `Validación del CCI` | Pendiente |
| VL-02 | 20 | 20 dígitos | 201 | `Validación del CCI` | Pendiente |
| VL-03 | 20 + 1 | 21 dígitos | 422 `CCI_INVALIDO` | `Validación del CCI` | Pendiente |

## HU-N-08 CA2 · RN-08 · Saldo contra monto + comisión (monto 100.00, total 101.50)

#### Valores límite

| ID | Borde | Valor (saldo) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | total − 0.01 | 101.49 | 422 `SALDO_INSUFICIENTE` | `El saldo debe cubrir el monto más la comisión` | Pendiente |
| VL-02 | total | 101.50 | 201 | `El saldo debe cubrir el monto más la comisión` | Pendiente |
| VL-03 | total + 0.01 | 101.51 | 201 | `El saldo debe cubrir el monto más la comisión` | Pendiente |
| VL-04 | solo el monto (sin comisión) | 100.00 | 422 `SALDO_INSUFICIENTE` | `El saldo debe cubrir el monto más la comisión` | Pendiente |

## HU-N-08 CA2 · RN-05 · Monto

Se aplica la misma partición y los mismos límites de HU-N-07 CA2 RN-05.

#### Valores límite

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 0.01 | 0.00 | 422 `MONTO_INVALIDO` | `Aplican las reglas de monto de las transferencias` | Pendiente |
| VL-02 | mín | 0.01 | 201 (comisión 1.00) | `Aplican las reglas de monto de las transferencias` | Pendiente |
| VL-03 | máx | 500.00 | 201 (comisión 5.00, total 505.00) | `Aplican las reglas de monto de las transferencias` | Pendiente |
| VL-04 | máx + 0.01 | 500.01 | 422 `MONTO_INVALIDO` | `Aplican las reglas de monto de las transferencias` | Pendiente |
| VL-05 | decimales: máx + 1 | 10.005 | 422 `MONTO_INVALIDO` | `Aplican las reglas de monto de las transferencias` | Pendiente |

---

## HU-N-09 CA1 · Tipo de transferencia

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | tipo = QOLQE | Válida | QOLQE | 200, comisión 0.00 |
| PE-02 | tipo = INTERBANCARIA | Válida | INTERBANCARIA | 200, comisión según RN-09 |
| PE-03 | tipo no indicado | Válida | (sin campo) | 200, se trata como QOLQE |
| PE-04 | tipo inexistente | Inválida | CRIPTO | 422 (el requisito no da código) |

## HU-N-09 CA1 · RN-09 · Comisión (1.5 %, mín. 1.00, máx. 5.00)

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | 1.5 % del monto < 1.00 (monto < 66.67) | Válida | 10.00 | comisión 1.00 (mínimo) |
| PE-02 | 1.00 ≤ 1.5 % del monto ≤ 5.00 | Válida | 200.00 | comisión 3.00 |
| PE-03 | 1.5 % del monto > 5.00 (monto > 333.33) | Válida | 500.00 | comisión 5.00 (máximo) |

#### Valores límite

| ID | Borde | Valor (monto) | Esperado (comisión / total) | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mínimo absoluto | 0.01 | 1.00 / 1.01 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-02 | mín comisión − 1 | 66.66 (0.9999) | 1.00 / 67.66 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-03 | mín comisión | 66.67 (1.00005) | 1.00 / 67.67 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-04 | mín comisión + 1 (redondeo sube) | 67.00 (1.005) | 1.01 / 68.01 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-05 | máx comisión − 1 | 332.00 (4.98) | 4.98 / 336.98 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-06 | máx comisión (redondeo sube) | 333.00 (4.995) | 5.00 / 338.00 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-07 | máx comisión + 1 | 333.34 (5.0001) | 5.00 / 338.34 | `Comisión de una transferencia interbancaria` | Pendiente |
| VL-08 | monto máximo | 500.00 (7.50) | 5.00 / 505.00 | `Comisión de una transferencia interbancaria` | Pendiente |

## HU-N-09 CA1 · RN-05 · Monto inválido

#### Valores límite

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 0.01 | 0.00 | 422 `MONTO_INVALIDO` | `La simulación valida el monto` | Pendiente |
| VL-02 | partición < 0 | -5.00 | 422 `MONTO_INVALIDO` | `La simulación valida el monto` | Pendiente |
| VL-03 | máx + 0.01 | 500.01 | 422 `MONTO_INVALIDO` | `La simulación valida el monto` | Pendiente |
| VL-04 | decimales: máx + 1 | 10.005 | 422 `MONTO_INVALIDO` | `La simulación valida el monto` | Pendiente |

---

## HU-G3-01 CA1 · R-G3-01 · Rango de fechas (hoy = 2026-11-15)

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | desde ≤ hasta ≤ hoy and hasta − desde ≤ 90 | Válida | 2026-11-01 a 2026-11-10 | 200 |
| PE-02 | sin `desde` ni `hasta` | Válida | (sin filtros) | 200, últimos 30 días hasta hoy |
| PE-03 | desde > hasta | Inválida | 2026-11-16 a 2026-11-15 | 422 `FILTRO_INVALIDO` |
| PE-04 | hasta futura | Inválida | hasta 2026-11-16 | 422 `FILTRO_INVALIDO` |
| PE-05 | hasta − desde > 90 días | Inválida | 2026-08-16 a 2026-11-15 | 422 `FILTRO_INVALIDO` |

#### Valores límite

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | desde = hasta − 1 | 2026-11-14 a 2026-11-15 | 200 | `Validación del rango de fechas` | Pendiente |
| VL-02 | desde = hasta | 2026-11-15 a 2026-11-15 | 200 | `Validación del rango de fechas` | Pendiente |
| VL-03 | desde = hasta + 1 | 2026-11-16 a 2026-11-15 | 422 `FILTRO_INVALIDO` | `Validación del rango de fechas` | Pendiente |
| VL-04 | hasta = hoy | hasta 2026-11-15 | 200 | `Validación del rango de fechas` | Pendiente |
| VL-05 | hasta = hoy + 1 | hasta 2026-11-16 | 422 `FILTRO_INVALIDO` | `Validación del rango de fechas` | Pendiente |
| VL-06 | rango máx − 1 | 89 días (desde 2026-08-18) | 200 | `Rango máximo de 90 días` | Pendiente |
| VL-07 | rango máx | 90 días (desde 2026-08-17) | 200 | `Rango máximo de 90 días` | Pendiente |
| VL-08 | rango máx + 1 | 91 días (desde 2026-08-16) | 422 `FILTRO_INVALIDO` | `Rango máximo de 90 días` | Pendiente |
| VL-09 | por defecto: 30 días | movimiento de hace 30 días | aparece | `Consulta sin filtros devuelve los últimos 30 días incluyendo hoy` | Pendiente |
| VL-10 | por defecto: 30 días + 1 | movimiento de hace 31 días | no aparece | `Consulta sin filtros devuelve los últimos 30 días incluyendo hoy` | Pendiente |

**Decisión:** "máximo 90 días" se mide como `hasta − desde ≤ 90`: 90 días de diferencia es válido y 91 no. No se cuentan ambos extremos.

## HU-G3-01 CA1 · Formato de fecha

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | formato AAAA-MM-DD de una fecha real | Válida | 2026-11-10 | 200 |
| PE-02 | otro formato | Inválida | 15-11-2026 | 422 |
| PE-03 | mes o día fuera de calendario | Inválida | 2026-13-01, 2026-02-30 | 422 |
| PE-04 | texto no fecha | Inválida | ayer | 422 |

**Decisión:** el requisito no define el código de error de una fecha mal formada, así que el escenario solo exige 422 y no fija el código.

## HU-G3-01 CA1 · Tipo de movimiento

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | TRANSFERENCIA_ENVIADA | Válida | TRANSFERENCIA_ENVIADA | 200, solo ese tipo |
| PE-02 | TRANSFERENCIA_RECIBIDA | Válida | TRANSFERENCIA_RECIBIDA | 200, solo ese tipo |
| PE-03 | RECARGA | Válida | RECARGA | 200, solo ese tipo |
| PE-04 | PAGO_SERVICIO | Válida | PAGO_SERVICIO | 200, solo ese tipo |
| PE-05 | tipo inexistente | Inválida | RETIRO | 422 `FILTRO_INVALIDO` |

## HU-G3-01 CA1 · Categoría

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | categoría propia | Válida | "Comida" | 200, solo sus movimientos |
| PE-02 | categoría de otro usuario | Inválida | id de "Viajes" de Bruno | 422 `FILTRO_INVALIDO` |
| PE-03 | categoría inexistente | Inválida | 999999 | 422 `FILTRO_INVALIDO` |

**Decisión:** en el historial la categoría es un **filtro**: HU-G3-01 CA1 pide `FILTRO_INVALIDO` (422) tanto para una categoría ajena como para una inexistente, y no se revela cuál de las dos es. En HU-G3-07 la categoría es un **recurso** que se asigna, y ahí rige la regla general (404 `CATEGORIA_NO_ENCONTRADA` si no existe o es de otro usuario). La diferencia es intencional.

## HU-G3-01 CA2 · Días completos (consulta desde 2026-11-10 hasta 2026-11-12)

#### Valores límite (tiempo, hora de Lima)

| ID | Borde | Valor (fecha del movimiento) | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | inicio − 1 s | 2026-11-09T23:59:59 | no aparece | `El rango incluye completos los días desde y hasta` | Pendiente |
| VL-02 | inicio | 2026-11-10T00:00:00 | aparece | `El rango incluye completos los días desde y hasta` | Pendiente |
| VL-03 | fin | 2026-11-12T23:59:59 | aparece | `El rango incluye completos los días desde y hasta` | Pendiente |
| VL-04 | fin + 1 s | 2026-11-13T00:00:00 | no aparece | `El rango incluye completos los días desde y hasta` | Pendiente |

## HU-G3-01 CA3 · R-G3-02 · Paginación (10 por página)

#### Valores límite (cantidad de movimientos, página 1)

| ID | Borde | Cantidad | En la página / páginas | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | vacío | 0 | 0 / 0 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-02 | mín | 1 | 1 / 1 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-03 | página llena − 1 | 9 | 9 / 1 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-04 | página llena | 10 | 10 / 1 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-05 | página llena + 1 | 11 | 10 / 2 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-06 | 2 páginas llenas | 20 | 10 / 2 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-07 | 2 páginas llenas + 1 | 21 | 10 / 3 | `Paginación de 10 movimientos por página` | Pendiente |

## HU-G3-01 CA3 · R-G3-02 · Número de página

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | página ≥ 1 y ≤ última | Válida | 1 | 200 |
| PE-02 | página < 1 | Inválida | 0, -1 | 422 |
| PE-03 | no numérica | Inválida | abc | 422 |
| PE-04 | página > última | Válida | 4 (de 3 páginas) | 200, lista vacía · `Pedir una página mayor a la última` |

#### Valores límite

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 1 | 0 | 422 | `Número de página inválido` | Pendiente |
| VL-02 | mín | 1 | 200 | `Paginación de 10 movimientos por página` | Pendiente |
| VL-03 | última | 3 (de 21 movimientos) | 200, 1 movimiento | `La última página trae el resto de los movimientos` | Pendiente |
| VL-04 | última + 1 | 4 (de 21 movimientos) | 200, 0 movimientos | `Pedir una página mayor a la última` | Pendiente |

**Decisión:** una página mayor a la última responde 200 con lista vacía; solo la página < 1 es inválida.

---

## HU-G3-02 CA1-2 · Código de operación

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | código de un movimiento propio | Válida | código de mi transferencia | 200, detalle |
| PE-02 | código de otro usuario | Inválida | código de un movimiento de Bruno | 404 `MOVIMIENTO_NO_ENCONTRADO` |
| PE-03 | código inexistente | Inválida | NOEXISTE000 | 404 `MOVIMIENTO_NO_ENCONTRADO` |

---

## HU-G3-03 CA1 · R-G3-03 · Nombre de la categoría

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | 3 ≤ size(nombre) ≤ 20 | Válida | "Ahorros" | 201 |
| PE-02 | size(nombre) < 3 | Inválida | "ab" | 422 `CATEGORIA_INVALIDA` |
| PE-03 | size(nombre) > 20 | Inválida | 21 caracteres | 422 `CATEGORIA_INVALIDA` |
| PE-04 | vacío o solo espacios | Inválida | `""`, `"   "` | 422 `CATEGORIA_INVALIDA` |

#### Valores límite (largo)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 1 | 2 | 422 `CATEGORIA_INVALIDA` | `Longitud del nombre de la categoría` | Pendiente |
| VL-02 | mín | 3 | 201 | `Longitud del nombre de la categoría` | Pendiente |
| VL-03 | mín + 1 | 4 | 201 | `Longitud del nombre de la categoría` | Pendiente |
| VL-04 | máx − 1 | 19 | 201 | `Longitud del nombre de la categoría` | Pendiente |
| VL-05 | máx | 20 | 201 | `Longitud del nombre de la categoría` | Pendiente |
| VL-06 | máx + 1 | 21 | 422 `CATEGORIA_INVALIDA` | `Longitud del nombre de la categoría` | Pendiente |

**Decisión:** el nombre se recorta (trim) antes de medir la longitud: `"  abc  "` cuenta 3 caracteres y se crea como `abc`. Escenario `Los espacios alrededor del nombre no cuentan en la longitud`.

## HU-G3-03 CA1 · Nombre duplicado

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | nombre no usado por mí | Válida | "Ahorros" | 201 |
| PE-02 | nombre igual a una categoría mía | Inválida | "Comida" | 409 `CATEGORIA_DUPLICADA` |
| PE-03 | igual con otras mayúsculas | Inválida | "COMIDA", "comida" | 409 `CATEGORIA_DUPLICADA` |
| PE-04 | mismo nombre en otro usuario | Válida | "Viajes" (de Bruno) | 201 |

## HU-G3-03 CA1 · Color

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | color dentro de la paleta de 8 | Válida | #43A047 (probar los 8) | 201 |
| PE-02 | hexadecimal fuera de la paleta | Inválida | #000000 | 422 |
| PE-03 | color de la paleta en minúsculas | Válida | #e53935 | 201, se guarda como #E53935 |
| PE-04 | texto que no es color | Inválida | rojo | 422 |
| PE-05 | color vacío o no enviado | Inválida | (sin campo) | 422 |

**Decisión:** el color no distingue mayúsculas: `#e53935` es `#E53935` y se guarda en mayúsculas (`Un color en minúsculas se guarda en mayúsculas`). Los 8 colores válidos se prueban en el segundo `Examples` de `Color de la paleta fija`.

## HU-G3-03 CA1 · R-G3-03 · Cantidad de categorías (máx. 10)

#### Valores límite (categorías existentes antes de crear)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | máx − 2 | 8 | 201 | `Límite de 10 categorías por usuario` | Pendiente |
| VL-02 | máx − 1 | 9 | 201 (llega a 10) | `Límite de 10 categorías por usuario` | Pendiente |
| VL-03 | máx | 10 | 422 `LIMITE_CATEGORIAS` | `Límite de 10 categorías por usuario` | Pendiente |

---

## HU-G3-05 CA1 · R-G3-03 · Nombre al editar

Misma partición y mismos límites que HU-G3-03 CA1 · Nombre.

#### Valores límite (largo)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín − 1 | 2 | 422 `CATEGORIA_INVALIDA` | `Longitud del nombre al editar` | Pendiente |
| VL-02 | mín | 3 | 200 | `Longitud del nombre al editar` | Pendiente |
| VL-03 | mín + 1 | 4 | 200 | `Longitud del nombre al editar` | Pendiente |
| VL-04 | máx − 1 | 19 | 200 | `Longitud del nombre al editar` | Pendiente |
| VL-05 | máx | 20 | 200 | `Longitud del nombre al editar` | Pendiente |
| VL-06 | máx + 1 | 21 | 422 `CATEGORIA_INVALIDA` | `Longitud del nombre al editar` | Pendiente |

## HU-G3-05 CA1 · Nombre repetido

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | nombre libre | Válida | "Restaurantes" | 200 |
| PE-02 | mismo nombre de la propia categoría con otras mayúsculas | Válida | "COMIDA" editando "Comida" | 200 |
| PE-03 | nombre de otra categoría mía (cualquier mayúscula) | Inválida | "comida" editando "Familia" | 409 `CATEGORIA_DUPLICADA` |

## HU-G3-05 CA1 · Id de la categoría

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | id de una categoría propia | Válida | id de "Comida" | 200 |
| PE-02 | id de otro usuario | Inválida | id de "Viajes" de Bruno | 404 |
| PE-03 | id inexistente | Inválida | 999999 | 404 |

---

## HU-G3-06 CA1 · Id de la categoría

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | id de una categoría propia | Válida | id de "Comida" | 204 |
| PE-02 | id de otro usuario | Inválida | id de "Viajes" de Bruno | 404, la categoría de Bruno sigue |
| PE-03 | id inexistente | Inválida | 999999 | 404 · `Eliminar una categoría que no existe` |
| PE-04 | id ya eliminado | Inválida | id de "Comida" eliminada | 404 |

---

## HU-G3-07 CA1 · Categoría asignada

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | categoría propia | Válida | "Familia" | 200 |
| PE-02 | `categoria_id` nulo | Válida | `null` | 200, queda sin categoría |
| PE-03 | categoría de otro usuario | Inválida | id de "Viajes" de Bruno | 404 `CATEGORIA_NO_ENCONTRADA` |
| PE-04 | categoría inexistente | Inválida | 999999 | 404 `CATEGORIA_NO_ENCONTRADA` · `Asignar una categoría que no existe` |

## HU-G3-07 CA2 · R-G3-04 · Nota

La partición está en el ejemplo trabajado (R-G3-04).

#### Valores límite (largo)

| ID | Borde | Valor | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín | 0 (quitar la nota) | 200, sin nota | `Editar y quitar una nota` | Pendiente |
| VL-02 | mín + 1 | 1 | 200 | `Longitud de la nota` | Pendiente |
| VL-03 | máx − 1 | 99 | 200 | `Longitud de la nota` | Pendiente |
| VL-04 | máx | 100 | 200 | `Longitud de la nota` | Pendiente |
| VL-05 | máx + 1 | 101 | 422 `NOTA_INVALIDA` | `Longitud de la nota` | Pendiente |

## HU-G3-07 CA3 · Movimiento

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | movimiento propio | Válida | código de mi movimiento | 200 |
| PE-02 | movimiento de otro usuario | Inválida | código de un movimiento de Bruno | 404 `MOVIMIENTO_NO_ENCONTRADO` |
| PE-03 | movimiento inexistente | Inválida | NOEXISTE000 | 404 `MOVIMIENTO_NO_ENCONTRADO` · `Clasificar un movimiento que no existe` |

---

## HU-G3-08 CA1 · Filtros y rango de la exportación

Misma partición y mismos límites que HU-G3-01 CA1 (rango, tipo, categoría). La exportación no pagina.

#### Particion de equivalencia

| ID | Partición | Tipo | Valor representativo | Esperado |
|---|---|---|---|---|
| PE-01 | rango válido (R-G3-01) | Válida | 2026-11-15 a 2026-11-15 | 200, CSV |
| PE-02 | filtro por tipo | Válida | RECARGA | 200, solo filas de ese tipo, igual al total del historial |
| PE-03 | desde > hasta | Inválida | 2026-11-16 a 2026-11-15 | 422 `FILTRO_INVALIDO` |
| PE-04 | hasta futura | Inválida | hasta 2026-11-16 | 422 `FILTRO_INVALIDO` |
| PE-05 | rango > 90 días | Inválida | 2026-08-16 a 2026-11-15 | 422 `FILTRO_INVALIDO` |

## HU-G3-08 CA3 · Cantidad de movimientos

#### Valores límite

| ID | Borde | Cantidad | Esperado | Escenario | Estado |
|---|---|---|---|---|---|
| VL-01 | mín | 0 | solo encabezado | `Exportar sin movimientos devuelve solo el encabezado` | Pendiente |
| VL-02 | mín + 1 | 1 | encabezado + 1 fila | `La exportación no se pagina` | Pendiente |
| VL-03 | tamaño de página | 10 | 10 filas | `La exportación no se pagina` | Pendiente |
| VL-04 | tamaño de página + 1 | 11 | 11 filas (no se pagina) | `La exportación no se pagina` | Pendiente |
| VL-05 | varias páginas | 25 | 25 filas | `La exportación no se pagina` | Pendiente |

---

## Checklist por HU (núcleo + G3)

Solo aparecen los criterios (CA) que tienen un **dato de entrada** al que se le puede aplicar partición de equivalencia (PE) o valores límite (VL). Los que solo verifican un efecto (SMS, comprobante, estado posterior) se cubren con escenarios normales, sin análisis PE/VL, y no están aquí.
Marca `[x]` cuando el análisis del criterio esté hecho **y** pasado a un `.feature`. Reglas del núcleo: RN-01 a RN-11 (`docs/requisitos.md`, sección 2).

### Núcleo

**HU-N-01 · Registrarme** (Alta)
- [x] CA2 DNI, RN-01: 9 dígitos y no numérico (PE)
- [x] CA3 Celular, RN-02: 9 dígitos; empieza con 9 o no; ya registrado; de cuenta cerrada (PE)
- [x] CA4 PIN, RN-03: repetido (1111), secuencia (1234, 4321), 3 y 5 dígitos, no numérico (PE)
- [x] CA5 Correo: formato inválido, duplicado sin distinguir mayúsculas, de cuenta cerrada, omitido (PE)

**HU-N-02 · Iniciar sesión** (Alta)
- [x] CA2 Credenciales: celular existente o no × PIN correcto o no (PE) · `nucleo_sesion.feature`
- [x] CA3 Bloqueo, RN-04: intento fallido 1, 2 y 3 (VL) · `Bloqueo al tercer intento fallido consecutivo`
- [x] CA4 Tiempo de bloqueo de 15 min: 14:59, 15:00, 15:01 (VL de tiempo) · `El bloqueo dura 15 minutos`
- [x] CA5 Estado de la cuenta: activa, bloqueada, cerrada (PE)
- [x] CA6 Dispositivo: de confianza, nuevo, no enviado (PE)

**HU-N-04 · Consultar saldo y perfil** (Alta)
- [x] CA3 Token: válido, ausente, inválido, alterado, vencido (PE)

**HU-N-05 · Editar mi perfil** (Media)
- [x] CA1 Nombres: 1, 2, 80, 81 caracteres (VL)
- [x] CA1 Correo: formato inválido, duplicado, el propio con otras mayúsculas (PE)

**HU-N-06 · Cerrar mi cuenta** (Media)
- [x] CA1 PIN de confirmación: correcto o incorrecto (PE)
- [x] CA2 Saldo: 0.00, 0.01, mayor a 0 (VL)
- [x] CA3 Solicitudes pendientes: enviada, recibida, vencida; borde de 48 h: 47 h y 49 h (PE + VL de tiempo)

**HU-N-07 · Transferir a otro usuario Qolqe** (Alta)
- [x] CA1 Descripción: 0, 1, 60, 61 caracteres (VL)
- [x] CA2 Monto, RN-05: -1, 0.00, 0.01, 0.001, 10.005, 500.00, 500.01 (VL + PE)
- [x] CA2 Destino: uno mismo, no registrado, cuenta cerrada, válido (PE)
- [x] CA2 Saldo, RN-08: saldo = monto y saldo = monto - 0.01 (VL)
- [x] CA2 Límite diario, RN-06: acumulado 1999.99, 2000.00, 2000.01; Diego con S/ 1,000 (VL)
- [x] CA2 Reinicio del límite a medianoche de Lima: 23:59:59 y 00:00:00 (VL de tiempo)

**HU-N-08 · Transferir a otro banco** (Alta)
- [x] CA1 CCI: 19, 20, 21 dígitos y no numérico (VL + PE)
- [x] CA2 Saldo contra monto + comisión: saldo = total y saldo = total - 0.01 (VL)
- [x] CA2 Monto, RN-05: 0.00, 500.00, 500.01 (VL)

**HU-N-09 · Simular la comisión** (Media)
- [x] CA1 Tipo: QOLQE, INTERBANCARIA, no indicado, inexistente (PE)
- [x] CA1 Comisión RN-09 (1.5 %, mín. 1.00, máx. 5.00): 0.01, 66.66, 66.67, 67.00, 332.00, 333.00, 500.00 (VL + redondeo)
- [x] CA1 Monto inválido: 0.00, -5.00, 500.01, 10.005 (VL)

### G3 · Historial y categorías

**HU-G3-01 · Consultar mis movimientos** (Alta)
- [x] CA1 Rango R-G3-01: `desde` ≤ `hasta`, `hasta` no futura, máximo 90 días, por defecto 30 días (VL)
- [x] CA1 Formato de fecha inválido (PE)
- [x] CA1 Tipo: los 4 válidos y uno inexistente (PE)
- [x] CA1 Categoría: propia, ajena, inexistente (PE)
- [x] CA2 Días completos: 00:00:00 y 23:59:59 de `desde` y `hasta` (VL de tiempo)
- [x] CA3 Paginación R-G3-02: 0, 1, 9, 10, 11, 20, 21 movimientos (VL)
- [x] CA3 Página: 0, 1, última (VL)

**HU-G3-02 · Detalle de un movimiento** (Alta)
- [x] CA1-2 Código de operación: propio, de otro usuario, inexistente (PE)

**HU-G3-03 · Crear una categoría** (Media)
- [x] CA1 Nombre R-G3-03: 2, 3, 4, 19, 20, 21 caracteres; vacío; solo espacios (VL)
- [x] CA1 Nombre duplicado: igual, otras mayúsculas, mismo nombre en otro usuario (PE)
- [x] CA1 Color: 8 válidos, fuera de paleta, vacío, minúsculas (PE) · minúsculas se acepta (201)
- [x] CA1 Cantidad de categorías existentes: 9 y 10 (VL)

**HU-G3-05 · Editar una categoría** (Baja)
- [x] CA1 Nombre: 2, 3, 20, 21 caracteres (VL)
- [x] CA1 Nombre repetido en otra categoría y propio con otras mayúsculas (PE)
- [x] CA1 Id de la categoría: propia, ajena, inexistente (PE)

**HU-G3-06 · Eliminar una categoría** (Media)
- [x] CA1 Id de la categoría: propia, ajena, inexistente, ya eliminada (PE)

**HU-G3-07 · Clasificar un movimiento** (Media)
- [x] CA1 Categoría: propia, ajena, nula (quitar), inexistente (PE)
- [x] CA2 Nota R-G3-04: 0, 1, 99, 100, 101 caracteres (VL) · el 0 se cubre en `Editar y quitar una nota`
- [x] CA3 Movimiento: propio, ajeno, inexistente (PE)

**HU-G3-08 · Exportar movimientos** (Media)
- [x] CA1 Mismos filtros y mismo rango que el historial (PE + VL)
- [x] CA3 Cantidad de movimientos: 0 y 1 (VL)

### Sin análisis PE/VL (se cubren con escenarios normales)

| HU | Criterios | Por qué |
|---|---|---|
| HU-N-01 | CA1 (saldo y límite iniciales), CA6 (SMS) | Verifican un resultado, no un dato de entrada |
| HU-N-02 | CA1 (token de 30 min) | Resultado de un ingreso válido |
| HU-N-03 | CA1, CA2 | Sin datos de entrada; solo efecto sobre la sesión |
| HU-N-04 | CA1, CA2 | Consulta sin parámetros |
| HU-N-05 | CA2, CA3 | Campos que se ignoran y SMS |
| HU-N-06 | CA4 | Efecto posterior al cierre |
| HU-N-07 | CA3, CA4 | Efectos de una transferencia ya válida |
| HU-N-07 | CA5 | Concurrencia, es una prueba especial |
| HU-N-08 | CA3 | Enmascarado del CCI |
| HU-G3-01 | CA4 | Campos de la respuesta |
| HU-G3-04 | CA1 | Consulta sin parámetros |
| HU-G3-07 | CA4 | Efecto de clasificar (RN-11) |
| HU-G3-08 | CA2 | Formato del archivo |

---

## Trazabilidad: regla → escenarios

| Regla / criterio | Escenario en `historial.feature` | Estado |
|---|---|---|
| R-G3-01 (rango, 90 días, 30 por defecto) | `Consulta sin filtros devuelve los últimos 30 días incluyendo hoy` · `Validación del rango de fechas` · `Rango máximo de 90 días` · `Formato de fecha inválido` · `El rango incluye completos los días desde y hasta` · `La exportación aplica las mismas reglas de rango` | Pendiente |
| R-G3-02 (10 por página, página ≥ 1) | `Paginación de 10 movimientos por página` · `La última página trae el resto de los movimientos` · `Número de página inválido` · `Pedir una página mayor a la última` · `La exportación no se pagina` | Pendiente |
| R-G3-03 (categorías: máx. 10, nombre 3-20, único, paleta de 8) | `Longitud del nombre de la categoría` · `Nombre solo con espacios` · `Nombre vacío` · `Nombre duplicado sin distinguir mayúsculas` · `Color de la paleta fija` · `Límite de 10 categorías por usuario` · `Longitud del nombre al editar` · `Cambiar solo las mayúsculas del propio nombre no es un duplicado` | Pendiente |
| R-G3-04 (nota ≤ 100) | `Longitud de la nota` · `Editar y quitar una nota` | Pendiente |
