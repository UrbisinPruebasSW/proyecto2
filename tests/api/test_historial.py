 """G3 · Historial y categorías: automatiza features/g3/historial.feature."""
import csv
import io
import re
from datetime import date, timedelta

from pytest_bdd import given, parsers, scenarios, then, when

from tests.api.helpers import CCI_VALIDO, USUARIOS

scenarios("../../features/g3/historial.feature")

PALETA = ["#E53935", "#FB8C00", "#FDD835", "#43A047", "#00897B", "#1E88E5", "#8E24AA", "#6D4C41"]
CELULAR_BRUNO = USUARIOS["Bruno"][0]


def q(nombre: str) -> str:
    """Fragmento de expresión regular para un valor entre comillas."""
    return rf'"(?P<{nombre}>[^"]*)"'


# ------------------------------------------------------------------ utilidades

def fecha_hace(ctx, dias: int) -> str:
    return (date.fromisoformat(ctx.hoy) - timedelta(days=dias)).isoformat()


def historial_completo(ctx, params=None) -> list[dict]:
    """Todas las páginas del historial del actor con los filtros dados."""
    params = dict(params or {})
    movimientos, pagina = [], 1
    while True:
        r = ctx.api.llamar("GET", "/api/movimientos", ctx.token, params={**params, "pagina": pagina})
        assert r.status_code == 200, r.text
        cuerpo = r.json()
        movimientos += cuerpo["movimientos"]
        if pagina >= cuerpo["total_paginas"]:
            return movimientos
        pagina += 1


def buscar(movimientos: list[dict], codigo: str) -> dict | None:
    return next((m for m in movimientos if m["codigo_operacion"] == codigo), None)


def ayer(ctx) -> str:
    """Momento de los datos de prueba: ayer por la noche, cada vez un segundo después.

    Es el momento más reciente que el historial sí devuelve (los movimientos de hoy quedan fuera por
    DEF-01, que se prueba en sus propios escenarios). Los segundos distintos evitan que dos operaciones
    del mismo usuario compartan código de operación (DEF-04, que también tiene su propio escenario).
    """
    segundo = ctx.memoria["_segundo"] = ctx.memoria.get("_segundo", -1) + 1
    return f"{fecha_hace(ctx, 1)}T22:{segundo // 60:02d}:{segundo % 60:02d}"


def transferencia_de(ctx, nombre, destino, monto, momento=None) -> str:
    momento = momento or ayer(ctx)
    celular = USUARIOS[destino][0] if destino in USUARIOS else (
        ctx.usuarios[destino].celular if destino in ctx.usuarios else destino)
    cuerpo = {"celular_destino": celular, "monto": monto}
    r = ctx.en_fecha(momento, nombre, "POST", "/api/transferencias", json=cuerpo)
    assert r.status_code == 201, r.text
    return r.json()["codigo_operacion"]


def crear_movimientos_propios(ctx, n: int) -> None:
    """Deja al actor (un usuario nuevo) con exactamente n movimientos."""
    ctx.nuevo_usuario()
    for _ in range(n):
        transferencia_de(ctx, ctx.actor, "Bruno", "1.00")


def categorias(ctx, nombre=None) -> list[dict]:
    r = (ctx.como(nombre, "GET", "/api/categorias") if nombre
         else ctx.api.llamar("GET", "/api/categorias", ctx.token))
    assert r.status_code == 200, r.text
    return r.json()


def categoria(ctx, nombre: str) -> dict:
    return next(c for c in categorias(ctx) if c["nombre"].lower() == nombre.lower())


def id_categoria(ctx, nombre: str) -> int:
    ids = ctx.memoria.setdefault("cat_ids", {})
    try:
        ids[nombre] = categoria(ctx, nombre)["id"]
    except StopIteration:
        pass  # ya eliminada: se usa el id recordado
    return ids[nombre]


def clasificar(ctx, codigo: str, **cuerpo):
    return ctx.pedir("PUT", f"/api/movimientos/{codigo}/clasificacion", json=cuerpo)


def sin_categoria(ctx, tipo=None, solo_sin_nota=False) -> list[dict]:
    filtro = {"tipo": tipo} if tipo else {}
    return [m for m in historial_completo(ctx, filtro)
            if m["categoria"] is None and (not solo_sin_nota or m["nota"] is None)]


def asignar_a_categoria(ctx, nombre_categoria: str, n: int, tipo=None) -> list[str]:
    destino = id_categoria(ctx, nombre_categoria)
    if tipo == "TRANSFERENCIA_ENVIADA" and len(sin_categoria(ctx, tipo)) < n:
        transferencia_de(ctx, ctx.actor, "Bruno", "1.00")  # las enviadas de la semilla ya tienen categoría
    elegidos = sin_categoria(ctx, tipo)[:n]
    assert len(elegidos) == n, f"No hay {n} movimientos libres"
    for m in elegidos:
        r = ctx.api.llamar("PUT", f"/api/movimientos/{m['codigo_operacion']}/clasificacion", ctx.token,
                           json={"categoria_id": destino})
        assert r.status_code == 200, r.text
    return [m["codigo_operacion"] for m in elegidos]


def movimiento_actual(ctx) -> dict:
    return buscar(historial_completo(ctx, {"desde": fecha_hace(ctx, 89)}), ctx.memoria["mov"])


def filas_csv(ctx) -> list[list[str]]:
    return list(csv.reader(io.StringIO(ctx.respuesta.content.decode("utf-8")), delimiter=";"))


# ================================================================== HU-G3-01

@given("que tengo un movimiento de hoy y otro de hace 30 días y otro de hace 31 días")
def movimientos_de_tres_fechas(ctx):
    ctx.memoria["hace"] = {
        dias: transferencia_de(ctx, "Ana", "Bruno", "1.00", f"{fecha_hace(ctx, dias)}T12:00:00")
        for dias in (0, 30, 31)
    }


@when("consulto mi historial sin filtros")
def consulto_sin_filtros(ctx):
    ctx.params = {}
    ctx.pedir("GET", "/api/movimientos")


@when(parsers.re(rf"consulto mi historial desde {q('desde')} hasta {q('hasta')}"))
def consulto_con_rango(ctx, desde, hasta):
    ctx.params = {"desde": desde, "hasta": hasta}
    ctx.pedir("GET", "/api/movimientos", params=ctx.params)


@when(parsers.re(rf"consulto mi historial con el tipo {q('tipo')}"))
def consulto_con_tipo(ctx, tipo):
    ctx.params = {"tipo": tipo}
    ctx.pedir("GET", "/api/movimientos", params=ctx.params)


@when(parsers.re(rf"consulto mi historial con el tipo {q('tipo')} y esa categoría"))
def consulto_con_tipo_y_categoria(ctx, tipo):
    ctx.params = {"tipo": tipo, "categoria_id": ctx.memoria["cat_id"]}
    ctx.pedir("GET", "/api/movimientos", params=ctx.params)


@when("consulto mi historial con esa categoría")
def consulto_con_categoria(ctx):
    ctx.params = {"categoria_id": ctx.memoria["cat_id"]}
    ctx.pedir("GET", "/api/movimientos", params=ctx.params)


@when(parsers.re(r"consulto mi historial con la categoría (?P<cual>.+)"))
def consulto_con_categoria_ajena(ctx, cual):
    if cual.startswith("de otro usuario"):
        r = ctx.como("Bruno", "POST", "/api/categorias", json={"nombre": "Ajena", "color": PALETA[0]})
        identificador = r.json()["id"]
    else:
        identificador = int(re.search(r"\d+", cual).group())
    ctx.params = {"categoria_id": identificador}
    ctx.pedir("GET", "/api/movimientos", params=ctx.params)


@when(parsers.re(r"consulto la página (?P<pagina>\S+) de mi historial"))
def consulto_pagina(ctx, pagina):
    ctx.params = {"pagina": pagina}
    ctx.pedir("GET", "/api/movimientos", params=ctx.params)


@when(parsers.re(r"consulto las páginas (?P<a>\d+) y (?P<b>\d+) de mi historial"))
def consulto_dos_paginas(ctx, a, b):
    paginas = [ctx.api.llamar("GET", "/api/movimientos", ctx.token, params={"pagina": p}).json() for p in (a, b)]
    ctx.memoria["paginas"] = [p["movimientos"] for p in paginas]


@then(parsers.re(r"el rango consultado es desde (?P<desde>\S+) hasta (?P<hasta>\S+)"))
def rango_consultado(ctx, desde, hasta):
    cuerpo = ctx.respuesta.json()
    assert (cuerpo["desde"], cuerpo["hasta"]) == (desde, hasta)


@then(parsers.re(r"el historial incluye el movimiento de (hoy|hace (?P<dias>\d+) días)"))
def historial_incluye(ctx, dias):
    codigo = ctx.memoria["hace"][int(dias or 0)]
    assert buscar(historial_completo(ctx, ctx.params), codigo)


@then(parsers.re(r"el historial no incluye el movimiento de hace (?P<dias>\d+) días"))
def historial_no_incluye(ctx, dias):
    assert not buscar(historial_completo(ctx, ctx.params), ctx.memoria["hace"][int(dias)])


@given("que tengo una transferencia enviada, una recibida, una recarga y un pago de servicio ayer")
def un_movimiento_de_cada_tipo(ctx):
    ctx.nuevo_usuario()
    yo = ctx.actor
    transferencia_de(ctx, yo, "Bruno", "10.00")
    transferencia_de(ctx, "Bruno", yo, "10.00")
    r = ctx.en_fecha(ayer(ctx), yo, "POST", "/api/recargas", json={"celular": "987111222", "monto": "10"})
    assert r.status_code == 201, r.text
    deuda = ctx.como(yo, "GET", "/api/servicios/deudas",
                     params={"empresa": "ELECTRO", "suministro": "10000001"}).json()[0]
    r = ctx.en_fecha(ayer(ctx), yo, "POST", "/api/servicios/pagos", json={"deuda_id": deuda["id"]})
    assert r.status_code == 201, r.text


@then(parsers.re(rf"todos los movimientos devueltos son de tipo {q('tipo')}"))
def todos_son_del_tipo(ctx, tipo):
    movimientos = ctx.respuesta.json()["movimientos"]
    assert movimientos and all(m["tipo"] == tipo for m in movimientos)


@then(parsers.re(r"el total de movimientos es (?P<n>\d+)"))
def total_de_movimientos(ctx, n):
    assert ctx.respuesta.json()["total"] == int(n)


@then(parsers.re(r"el total de páginas es (?P<n>\d+)"))
def total_de_paginas(ctx, n):
    assert ctx.respuesta.json()["total_paginas"] == int(n)


@then(parsers.re(r"la página trae (?P<n>\d+) movimientos"))
def la_pagina_trae(ctx, n):
    assert len(ctx.respuesta.json()["movimientos"]) == int(n)


@given(parsers.re(rf"que tengo la categoría {q('nombre')} con (?P<n>\d+) movimientos asignados"))
@given(parsers.re(rf"que la categoría {q('nombre')} tiene (?P<n>\d+) movimientos"))
def categoria_con_n_movimientos(ctx, nombre, n):
    ctx.memoria["cat_id"] = id_categoria(ctx, nombre)
    ctx.memoria["asignados"] = asignar_a_categoria(ctx, nombre, int(n))


@given(parsers.re(rf"que la categoría {q('nombre')} tiene (?P<n>\d+) movimientos con sus montos conocidos"))
def categoria_con_montos_conocidos(ctx, nombre, n):
    categoria_con_n_movimientos(ctx, nombre, n)
    por_codigo = {m["codigo_operacion"]: m for m in historial_completo(ctx)}
    ctx.memoria["montos"] = {c: por_codigo[c]["monto"] for c in ctx.memoria["asignados"]}


@given(parsers.re(rf"que tengo la categoría {q('nombre')} con una recarga y una transferencia enviada"))
def categoria_con_recarga_y_transferencia(ctx, nombre):
    ctx.memoria["cat_id"] = id_categoria(ctx, nombre)
    asignar_a_categoria(ctx, nombre, 1, "RECARGA")
    asignar_a_categoria(ctx, nombre, 1, "TRANSFERENCIA_ENVIADA")


@then(parsers.re(rf"todos los movimientos devueltos pertenecen a la categoría {q('nombre')}"))
def todos_en_la_categoria(ctx, nombre):
    movimientos = ctx.respuesta.json()["movimientos"]
    assert movimientos and all(m["categoria"]["nombre"] == nombre for m in movimientos)


@given(parsers.re(rf"que tengo un movimiento con fecha {q('fecha')}"))
def movimiento_con_fecha(ctx, fecha):
    ctx.memoria["mov"] = transferencia_de(ctx, "Ana", "Bruno", "1.00", fecha)


@then(parsers.re(r"el movimiento (?P<resultado>aparece|no aparece) en el historial"))
def aparece_en_el_historial(ctx, resultado):
    encontrado = buscar(historial_completo(ctx, ctx.params), ctx.memoria["mov"]) is not None
    assert encontrado == (resultado == "aparece")


@given(parsers.re(r"que tengo exactamente (?P<n>\d+) movimientos en el rango consultado"))
def exactamente_n_movimientos(ctx, n):
    crear_movimientos_propios(ctx, int(n))


@given("que no tengo movimientos en el rango consultado")
def sin_movimientos(ctx):
    crear_movimientos_propios(ctx, 0)


@given("que tengo movimientos en el rango consultado")
@given("que tengo movimientos de varios tipos en el rango consultado")
def con_movimientos(ctx):
    pass  # Ana ya tiene movimientos de todos los tipos en los datos semilla


@then("las fechas están en orden descendente")
def fechas_descendentes(ctx):
    fechas = [m["fecha"] for pagina in ctx.memoria["paginas"] for m in pagina]
    assert len(fechas) == 15 and fechas == sorted(fechas, reverse=True)


@then("ningún movimiento aparece en las dos páginas")
def sin_repetidos(ctx):
    codigos = [m["codigo_operacion"] for pagina in ctx.memoria["paginas"] for m in pagina]
    assert len(codigos) == len(set(codigos))


@given(parsers.re(r"que hice una transferencia de S/ (?P<monto>[\d.]+) a Bruno"))
def hice_transferencia(ctx, monto):
    ctx.memoria["mov"] = transferencia_de(ctx, ctx.actor, "Bruno", monto)


@given(parsers.re(r"que hice una transferencia interbancaria de S/ (?P<monto>[\d.]+)"))
def hice_transferencia_interbancaria(ctx, monto):
    r = ctx.en_fecha(ayer(ctx), ctx.actor, "POST", "/api/transferencias",
                     json={"tipo": "INTERBANCARIA", "cci": CCI_VALIDO, "monto": monto})
    assert r.status_code == 201, r.text
    ctx.memoria["mov"] = r.json()["codigo_operacion"]


@given(parsers.re(r"que Bruno me transfirió S/ (?P<monto>[\d.]+)"))
def bruno_me_transfirio(ctx, monto):
    ctx.memoria["mov"] = transferencia_de(ctx, "Bruno", ctx.actor, monto)


def primer_movimiento(ctx) -> dict:
    return ctx.respuesta.json()["movimientos"][0]


@then("el primer movimiento muestra fecha, tipo, descripción, contraparte, monto, comisión, importe, saldo posterior, categoría y nota")
def muestra_todos_los_datos(ctx):
    m = primer_movimiento(ctx)
    for campo in ("fecha", "tipo", "descripcion", "contraparte", "monto", "comision", "importe",
                  "saldo_posterior", "categoria", "nota"):
        assert campo in m, campo
    assert m["saldo_posterior"] is not None


@then(parsers.re(rf"el importe es {q('importe')}"))
def el_importe_es(ctx, importe):
    assert primer_movimiento(ctx)["importe"] == importe


@then(parsers.re(rf"el monto es {q('monto')}"))
def el_monto_es(ctx, monto):
    assert primer_movimiento(ctx)["monto"] == monto


@then(parsers.re(rf"el primer movimiento tiene importe {q('importe')}"))
def primer_importe(ctx, importe):
    assert primer_movimiento(ctx)["importe"] == importe


@then(parsers.re(rf"el primer movimiento muestra comisión {q('comision')}"))
def primera_comision(ctx, comision):
    assert primer_movimiento(ctx)["comision"] == comision


@given("que Bruno tiene movimientos que yo no tengo")
@given("que Bruno tiene un movimiento que no es mío")
def bruno_con_movimiento_propio(ctx):
    ctx.memoria["ajeno"] = transferencia_de(ctx, "Bruno", "Carla", "5.00")


@then("ningún movimiento devuelto pertenece a Bruno")
def ninguno_de_bruno(ctx):
    assert buscar(historial_completo(ctx), ctx.memoria["ajeno"]) is None


# ================================================================== HU-G3-02

@when("consulto el detalle de ese movimiento por su código de operación")
def detalle_propio(ctx):
    ctx.pedir("GET", f"/api/movimientos/{ctx.memoria['mov']}")


@when("consulto el detalle de ese código de operación")
def detalle_ajeno(ctx):
    ctx.pedir("GET", f"/api/movimientos/{ctx.memoria['ajeno']}")


@when(parsers.re(rf"consulto el detalle del código {q('codigo')}"))
def detalle_de_codigo(ctx, codigo):
    ctx.pedir("GET", f"/api/movimientos/{codigo}")


@when("Bruno consulta el detalle de ese código de operación")
def bruno_consulta_detalle(ctx):
    ctx.respuesta = ctx.como("Bruno", "GET", f"/api/movimientos/{ctx.memoria['mov']}")


@then("el detalle coincide con el movimiento del historial")
def detalle_coincide(ctx):
    del_historial = buscar(historial_completo(ctx), ctx.memoria["mov"])
    detalle = ctx.respuesta.json()
    for campo in ("codigo_operacion", "fecha", "tipo", "descripcion", "contraparte", "monto", "comision",
                  "importe", "categoria", "nota"):
        assert detalle[campo] == del_historial[campo], campo


@then(parsers.re(rf"Bruno ve un movimiento de tipo {q('tipo')} con importe {q('importe')}"))
def bruno_ve(ctx, tipo, importe):
    cuerpo = ctx.respuesta.json()
    assert (cuerpo["tipo"], cuerpo["importe"]) == (tipo, importe), cuerpo


# ================================================================== HU-G3-03 · 04

@when(parsers.re(rf"creo la categoría {q('nombre')} con el color {q('color')}"))
def creo_categoria(ctx, nombre, color):
    ctx.pedir("POST", "/api/categorias", json={"nombre": nombre, "color": color})


@when(parsers.re(rf"creo la categoría {q('nombre')} sin enviar el color"))
def creo_categoria_sin_color(ctx, nombre):
    ctx.pedir("POST", "/api/categorias", json={"nombre": nombre})


@given(parsers.re(rf"que creo la categoría {q('nombre')}"))
def dado_creo_categoria(ctx, nombre):
    r = ctx.api.llamar("POST", "/api/categorias", ctx.token, json={"nombre": nombre, "color": PALETA[3]})
    assert r.status_code == 201, r.text


@then(parsers.re(r"la categoría tiene (?P<n>\d+) movimientos asignados"))
def categoria_tiene_n(ctx, n):
    assert ctx.respuesta.json()["cantidad_movimientos"] == int(n)


@then(parsers.re(rf"el nombre de la categoría es {q('nombre')}"))
def nombre_de_la_categoria(ctx, nombre):
    assert ctx.respuesta.json()["nombre"] == nombre


@then(parsers.re(rf"el color de la categoría es {q('color')}"))
def color_de_la_categoria(ctx, color):
    assert ctx.respuesta.json()["color"] == color


@given(parsers.re(r"que tengo (?P<n>\d+) categorías"))
def tengo_n_categorias(ctx, n):
    faltan = int(n) - len(categorias(ctx))
    for i in range(faltan):
        r = ctx.api.llamar("POST", "/api/categorias", ctx.token,
                           json={"nombre": f"Extra {i + 1}", "color": PALETA[i % 8]})
        assert r.status_code == 201, r.text


@when("consulto mis categorías")
def consulto_categorias(ctx):
    ctx.pedir("GET", "/api/categorias")


@then(parsers.re(r"los nombres salen en este orden: (?P<lista>.+)"))
def nombres_en_orden(ctx, lista):
    esperado = re.findall(r'"([^"]*)"', lista)
    assert [c["nombre"] for c in ctx.respuesta.json()] == esperado


@then("cada categoría indica la cantidad de movimientos asignados")
def cada_categoria_con_cantidad(ctx):
    assert all(isinstance(c["cantidad_movimientos"], int) for c in ctx.respuesta.json())


@when(parsers.re(rf"clasifico un movimiento más en {q('nombre')}"))
def clasifico_uno_mas(ctx, nombre):
    asignar_a_categoria(ctx, nombre, 1)


@then(parsers.re(rf"la categoría {q('nombre')} muestra (?P<n>\d+) movimientos asignados"))
@then(parsers.re(rf"la categoría {q('nombre')} sigue teniendo (?P<n>\d+) movimientos"))
def categoria_muestra_n(ctx, nombre, n):
    assert categoria(ctx, nombre)["cantidad_movimientos"] == int(n)


@given(parsers.re(rf"que Bruno tiene la categoría {q('nombre')}"))
def bruno_tiene_categoria(ctx, nombre):
    r = ctx.como("Bruno", "POST", "/api/categorias", json={"nombre": nombre, "color": PALETA[5]})
    assert r.status_code == 201, r.text
    ctx.memoria["cat_bruno"] = r.json()["id"]


@then(parsers.re(rf"la lista no contiene {q('nombre')}"))
def lista_sin(ctx, nombre):
    assert nombre not in [c["nombre"] for c in ctx.respuesta.json()]


# ================================================================== HU-G3-05 · 06

@when(parsers.re(rf"edito la categoría {q('actual')} con el nombre {q('nombre')} y el color {q('color')}"))
def edito_nombre_y_color(ctx, actual, nombre, color):
    ctx.pedir("PUT", f"/api/categorias/{id_categoria(ctx, actual)}", json={"nombre": nombre, "color": color})


@when(parsers.re(rf"edito la categoría {q('actual')} con el nombre {q('nombre')}"))
def edito_nombre(ctx, actual, nombre):
    ctx.pedir("PUT", f"/api/categorias/{id_categoria(ctx, actual)}", json={"nombre": nombre})


@when(parsers.re(rf"edito la categoría {q('actual')} enviando solo el color {q('color')}"))
def edito_color(ctx, actual, color):
    ctx.pedir("PUT", f"/api/categorias/{id_categoria(ctx, actual)}", json={"color": color})


@when(parsers.re(rf"intento editar la categoría de Bruno con el nombre {q('nombre')}"))
def edito_la_de_bruno(ctx, nombre):
    ctx.pedir("PUT", f"/api/categorias/{ctx.memoria['cat_bruno']}", json={"nombre": nombre})


@when(parsers.re(r"intento editar la categoría con id (?P<id>\d+)"))
def edito_con_id(ctx, id):
    ctx.pedir("PUT", f"/api/categorias/{id}", json={"nombre": "Cualquiera"})


@then(parsers.re(rf"la categoría {q('nombre')} tiene el color {q('color')}"))
def categoria_con_color(ctx, nombre, color):
    assert categoria(ctx, nombre)["color"] == color


@then(parsers.re(rf"la categoría se sigue llamando {q('nombre')}"))
def se_sigue_llamando(ctx, nombre):
    assert ctx.respuesta.json()["nombre"] == nombre


@when(parsers.re(rf"elimino la categoría {q('nombre')}"))
@given(parsers.re(rf"que eliminé la categoría {q('nombre')}"))
@when(parsers.re(rf"elimino otra vez la categoría {q('nombre')}"))
def elimino_categoria(ctx, nombre):
    ctx.pedir("DELETE", f"/api/categorias/{id_categoria(ctx, nombre)}")


@when(parsers.re(r"intento eliminar la categoría con id (?P<id>\d+)"))
def elimino_con_id(ctx, id):
    ctx.pedir("DELETE", f"/api/categorias/{id}")


@when("intento eliminar la categoría de Bruno")
def elimino_la_de_bruno(ctx):
    ctx.pedir("DELETE", f"/api/categorias/{ctx.memoria['cat_bruno']}")


@then("la categoría de Bruno sigue existiendo")
def la_de_bruno_existe(ctx):
    assert ctx.memoria["cat_bruno"] in [c["id"] for c in categorias(ctx, "Bruno")]


@then(parsers.re(rf"la categoría {q('nombre')} ya no aparece en mi lista"))
def ya_no_aparece(ctx, nombre):
    assert nombre.lower() not in [c["nombre"].lower() for c in categorias(ctx)]


@then(parsers.re(r"esos (?P<n>\d+) movimientos siguen en mi historial sin categoría"))
def siguen_sin_categoria(ctx, n):
    historial = historial_completo(ctx)
    assert len(ctx.memoria["asignados"]) == int(n)
    for codigo in ctx.memoria["asignados"]:
        assert buscar(historial, codigo)["categoria"] is None


@then("los montos de esos movimientos no cambiaron")
def montos_sin_cambio(ctx):
    historial = historial_completo(ctx)
    for codigo, monto in ctx.memoria["montos"].items():
        assert buscar(historial, codigo)["monto"] == monto


# ================================================================== HU-G3-07

def elegir_movimiento(ctx, **kw) -> None:
    libres = sin_categoria(ctx, **kw)
    ctx.memoria["mov"] = libres[0]["codigo_operacion"]


@given("que tengo un movimiento sin categoría")
def movimiento_sin_categoria(ctx):
    elegir_movimiento(ctx)


@given(parsers.re(rf"que tengo un movimiento en la categoría {q('nombre')}"))
def movimiento_en_categoria(ctx, nombre):
    elegir_movimiento(ctx)
    r = clasificar(ctx, ctx.memoria["mov"], categoria_id=id_categoria(ctx, nombre))
    assert r.status_code == 200, r.text


@given("que tengo un movimiento sin nota")
def movimiento_sin_nota(ctx):
    elegir_movimiento(ctx, solo_sin_nota=True)


@given(parsers.re(rf"que tengo un movimiento con la nota {q('nota')}"))
def movimiento_con_nota(ctx, nota):
    elegir_movimiento(ctx, solo_sin_nota=True)
    assert clasificar(ctx, ctx.memoria["mov"], nota=nota).status_code == 200


@given(parsers.re(rf"que tengo un movimiento con la categoría {q('cat')} y la nota {q('nota')}"))
def movimiento_con_categoria_y_nota(ctx, cat, nota):
    elegir_movimiento(ctx, solo_sin_nota=True)
    r = clasificar(ctx, ctx.memoria["mov"], categoria_id=id_categoria(ctx, cat), nota=nota)
    assert r.status_code == 200, r.text


@given("que tengo un movimiento con monto, fecha y tipo conocidos")
def movimiento_conocido(ctx):
    elegir_movimiento(ctx)
    m = movimiento_actual(ctx)
    ctx.memoria["antes"] = {k: m[k] for k in ("monto", "fecha", "tipo", "saldo_posterior")}
    ctx.memoria["saldo"] = ctx.api.llamar("GET", "/api/cuentas/me/saldo", ctx.token).json()["saldo"]


@given(parsers.re(rf"que tengo un movimiento con monto {q('monto')}"))
def movimiento_con_monto(ctx, monto):
    ctx.memoria["mov"] = transferencia_de(ctx, ctx.actor, "Bruno", monto)


@when(parsers.re(rf"le asigno la categoría {q('nombre')} y la nota {q('nota')}"))
def asigno_categoria_y_nota(ctx, nombre, nota):
    clasificar(ctx, ctx.memoria["mov"], categoria_id=id_categoria(ctx, nombre), nota=nota)


@when(parsers.re(rf"le asigno la categoría {q('nombre')}"))
def asigno_categoria(ctx, nombre):
    clasificar(ctx, ctx.memoria["mov"], categoria_id=id_categoria(ctx, nombre))


@when("le asigno la categoría de Bruno")
def asigno_la_de_bruno(ctx):
    clasificar(ctx, ctx.memoria["mov"], categoria_id=ctx.memoria["cat_bruno"])


@when(parsers.re(r"le asigno la categoría con id (?P<id>\d+)"))
def asigno_con_id(ctx, id):
    clasificar(ctx, ctx.memoria["mov"], categoria_id=int(id))


@when("le quito la categoría enviando categoria_id nulo")
def quito_categoria(ctx):
    clasificar(ctx, ctx.memoria["mov"], categoria_id=None)


@when(parsers.re(r"le agrego una nota de (?P<largo>\d+) caracteres"))
def agrego_nota_de_largo(ctx, largo):
    clasificar(ctx, ctx.memoria["mov"], nota="n" * int(largo))


@when(parsers.re(rf"le agrego la nota {q('nota')} sin enviar categoría"))
def agrego_nota(ctx, nota):
    clasificar(ctx, ctx.memoria["mov"], nota=nota)


@when(parsers.re(rf"cambio la nota a {q('nota')}"))
def cambio_nota(ctx, nota):
    clasificar(ctx, ctx.memoria["mov"], nota=nota)


@when("quito la nota")
def quito_nota(ctx):
    clasificar(ctx, ctx.memoria["mov"], nota=None)


@when(parsers.re(rf"intento asignarle la categoría {q('nombre')}"))
def intento_asignar_a_ajeno(ctx, nombre):
    clasificar(ctx, ctx.memoria["ajeno"], categoria_id=id_categoria(ctx, nombre))


@when(parsers.re(rf"intento asignar la categoría {q('nombre')} al movimiento {q('codigo')}"))
def intento_asignar_a_codigo(ctx, nombre, codigo):
    clasificar(ctx, codigo, categoria_id=id_categoria(ctx, nombre))


@when(parsers.re(rf"envío una clasificación que incluye el monto {q('monto')}"))
def clasificacion_con_monto(ctx, monto):
    clasificar(ctx, ctx.memoria["mov"], nota="Con monto", monto=monto)


@then(parsers.re(rf"el movimiento muestra la categoría {q('nombre')}"))
@then(parsers.re(rf"el movimiento sigue en la categoría {q('nombre')}"))
def movimiento_muestra_categoria(ctx, nombre):
    assert movimiento_actual(ctx)["categoria"]["nombre"] == nombre


@then("el movimiento queda sin categoría")
def movimiento_sin_cat(ctx):
    assert movimiento_actual(ctx)["categoria"] is None


@then(parsers.re(rf"el movimiento muestra la nota {q('nota')}"))
def movimiento_muestra_nota(ctx, nota):
    assert movimiento_actual(ctx)["nota"] == nota


@then("el movimiento queda sin nota")
def movimiento_sin_nota_final(ctx):
    assert movimiento_actual(ctx)["nota"] is None


@then("el monto, la fecha y el tipo del movimiento no cambian")
def sin_cambios_en_el_movimiento(ctx):
    m = movimiento_actual(ctx)
    for campo in ("monto", "fecha", "tipo"):
        assert m[campo] == ctx.memoria["antes"][campo], campo


@then("el saldo posterior del movimiento no cambia")
def saldo_posterior_igual(ctx):
    assert movimiento_actual(ctx)["saldo_posterior"] == ctx.memoria["antes"]["saldo_posterior"]


@then("mi saldo no cambia")
def saldo_igual(ctx):
    assert ctx.api.llamar("GET", "/api/cuentas/me/saldo", ctx.token).json()["saldo"] == ctx.memoria["saldo"]


@then(parsers.re(rf"el movimiento sigue con monto {q('monto')}"))
def sigue_con_monto(ctx, monto):
    assert movimiento_actual(ctx)["monto"] == monto


# ================================================================== HU-G3-08

@when("exporto mis movimientos sin filtros")
def exporto_sin_filtros(ctx):
    ctx.params = {}
    ctx.pedir("GET", "/api/movimientos/exportar")


@when(parsers.re(rf"exporto mis movimientos con el tipo {q('tipo')}"))
def exporto_con_tipo(ctx, tipo):
    ctx.params = {"tipo": tipo}
    ctx.pedir("GET", "/api/movimientos/exportar", params=ctx.params)


@when(parsers.re(rf"exporto mis movimientos desde {q('desde')} hasta {q('hasta')}"))
def exporto_con_rango(ctx, desde, hasta):
    ctx.params = {"desde": desde, "hasta": hasta}
    ctx.pedir("GET", "/api/movimientos/exportar", params=ctx.params)


@then("la respuesta es 200 con contenido CSV en UTF-8")
def csv_utf8(ctx):
    assert ctx.respuesta.status_code == 200
    tipo = ctx.respuesta.headers["content-type"].lower()
    assert "text/csv" in tipo and "utf-8" in tipo
    ctx.respuesta.content.decode("utf-8")


@then(parsers.re(rf"la primera fila es {q('fila')}"))
def primera_fila(ctx, fila):
    assert ";".join(filas_csv(ctx)[0]) == fila


@then(parsers.re(r"cada fila de datos tiene (?P<n>\d+) columnas separadas por punto y coma"))
def columnas_por_fila(ctx, n):
    datos = filas_csv(ctx)[1:]
    assert datos and all(len(f) == int(n) for f in datos)


@then("los decimales usan punto")
def decimales_con_punto(ctx):
    for f in filas_csv(ctx)[1:]:
        assert all(re.fullmatch(r"-?\d+\.\d{2}", f[i]) for i in (4, 5, 6)), f


@then("el archivo contiene solo la fila de encabezado")
def solo_encabezado(ctx):
    assert len(filas_csv(ctx)) == 1


@then(parsers.re(r"el archivo contiene (?P<n>\d+) filas de datos"))
def n_filas_de_datos(ctx, n):
    assert len(filas_csv(ctx)) - 1 == int(n)


@then(parsers.re(rf"todas las filas son de tipo {q('tipo')}"))
def filas_del_tipo(ctx, tipo):
    datos = filas_csv(ctx)[1:]
    assert datos and all(f[2] == tipo for f in datos)


@then("el número de filas es igual al total del historial con ese mismo filtro")
def filas_igual_al_total(ctx):
    total = ctx.api.llamar("GET", "/api/movimientos", ctx.token, params=ctx.params).json()["total"]
    assert len(filas_csv(ctx)) - 1 == total


def fila_del_movimiento(ctx) -> list[str]:
    return next(f for f in filas_csv(ctx)[1:] if f[1] == ctx.memoria["mov"])


@then("la fila del movimiento conserva la tilde y la ñ")
def fila_con_tilde(ctx):
    assert "Cumpleaños de Carla; ñandú" in fila_del_movimiento(ctx)[8]


@then("la nota con punto y coma no rompe el número de columnas")
def nota_con_punto_y_coma(ctx):
    assert len(fila_del_movimiento(ctx)) == 9
