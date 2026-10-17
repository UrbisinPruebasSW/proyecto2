"""Fixtures y pasos comunes de las pruebas de API (pytest + httpx + pytest-bdd).

Por defecto levanta su propio uvicorn con una base de datos temporal. Para probar un
servidor ya iniciado: QOLQE_URL=http://localhost:8000 pytest tests/api
"""
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

import httpx
import pytest
from pytest_bdd import given, parsers, then, when

from tests.api.helpers import Api, Contexto

RAIZ = Path(__file__).resolve().parents[2]


def _puerto_libre() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@pytest.fixture(scope="session")
def url_base(tmp_path_factory):
    externa = os.getenv("QOLQE_URL")
    if externa:
        yield externa.rstrip("/")
        return
    puerto = _puerto_libre()
    entorno = {**os.environ, "QOLQE_MODO_PRUEBA": "1",
               "QOLQE_BD": str(tmp_path_factory.mktemp("bd") / "qolqe.db")}
    proceso = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "qolqe.main:app", "--port", str(puerto), "--log-level", "warning"],
        cwd=RAIZ, env=entorno,
    )
    url = f"http://127.0.0.1:{puerto}"
    limite = time.time() + 120  # la primera vez se genera la plantilla de carga
    while time.time() < limite:
        try:
            if httpx.get(f"{url}/api/salud", timeout=2).status_code == 200:
                break
        except httpx.HTTPError:
            time.sleep(0.5)
    else:
        proceso.kill()
        raise RuntimeError("El servidor de Qolqe no respondió a tiempo")
    yield url
    proceso.terminate()
    proceso.wait(timeout=10)


@pytest.fixture(scope="session")
def cliente(url_base):
    with httpx.Client(base_url=url_base, timeout=30) as c:
        yield c


@pytest.fixture
def api(cliente):
    return Api(cliente)


@pytest.fixture(autouse=True)
def datos_limpios(api):
    """Independencia (FIRST): cada escenario parte de los datos semilla y la hora real."""
    api.reiniciar()
    yield
    api.http.delete("/api/pruebas/reloj")


@pytest.fixture
def ctx(api):
    return Contexto(api)


# ---------------------------------------------------------------- pasos comunes

@given(parsers.parse("que inicié sesión como {nombre}"))
def inicie_sesion_como(ctx, nombre):
    ctx.iniciar_sesion(nombre)


@given(parsers.re(r"que hoy es (?P<fecha>\d{4}-\d{2}-\d{2})"))
def hoy_es(ctx, fecha):
    ctx.reiniciar_con_fecha(fecha)


@given("que no tengo un token")
def sin_token(ctx):
    ctx.sin_token = True


@then(parsers.re(r"la respuesta es (?P<estado>\d{3})"))
def la_respuesta_es(ctx, estado):
    assert ctx.respuesta.status_code == int(estado), ctx.respuesta.text


@then(parsers.re(r'el código de error es "(?P<codigo>[^"]*)"'))
def el_codigo_de_error_es(ctx, codigo):
    if codigo == "":  # sin código: la respuesta no es un error
        assert ctx.respuesta.status_code < 400, ctx.respuesta.text
    else:
        assert ctx.respuesta.json().get("codigo") == codigo, ctx.respuesta.text
