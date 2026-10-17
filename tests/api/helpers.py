"""Cliente de la API de Qolqe para las pruebas (httpx) y utilidades de datos."""
from __future__ import annotations

import itertools
from dataclasses import dataclass, field
from datetime import datetime

import httpx

# Usuarios semilla (README, sección 4): nombre -> (celular, PIN)
USUARIOS = {
    "Ana": ("987654321", "4826"),
    "Bruno": ("912345678", "7391"),
    "Carla": ("956781234", "5917"),
    "Diego": ("998877665", "3604"),
    "Elena": ("923456789", "8152"),
    "Fabián": ("934567812", "6029"),
}
CCI_VALIDO = "00219300123456789012"
HORA_FIJA = "12:00:00"

_contador_usuarios = itertools.count(1)


class Api:
    """Envoltorio fino de httpx con el token de cada usuario nombrado."""

    def __init__(self, cliente: httpx.Client):
        self.http = cliente

    # ------------------------------------------------------------ soporte
    def reiniciar(self) -> None:
        """Hora real y datos semilla de cero."""
        self.http.delete("/api/pruebas/reloj")
        self.reiniciar_sin_reloj()

    def reiniciar_sin_reloj(self) -> None:
        r = self.http.post("/api/pruebas/reiniciar")
        assert r.status_code == 200, r.text

    def fijar_reloj(self, momento: str) -> None:
        r = self.http.put("/api/pruebas/reloj", json={"ahora": momento})
        assert r.status_code == 200, r.text

    def fijar_saldo(self, celular: str, saldo: str) -> None:
        r = self.http.put("/api/pruebas/saldo", json={"celular": celular, "saldo": saldo})
        assert r.status_code == 200, r.text

    def sms(self, celular: str) -> list[dict]:
        return self.http.get("/api/pruebas/notificaciones", params={"celular": celular}).json()

    # ------------------------------------------------------------ llamadas
    def llamar(self, metodo: str, ruta: str, token: str | None = None, **kwargs) -> httpx.Response:
        cabeceras = kwargs.pop("headers", {})
        if token:
            cabeceras["Authorization"] = f"Bearer {token}"
        return self.http.request(metodo, ruta, headers=cabeceras, **kwargs)

    def login(self, celular: str, pin: str, **extra) -> httpx.Response:
        return self.llamar("POST", "/api/auth/login", json={"celular": celular, "pin": pin, **extra})

    def token(self, celular: str, pin: str) -> str:
        r = self.login(celular, pin)
        assert r.status_code == 200, r.text
        return r.json()["access_token"]

    def registrar(self, **datos) -> httpx.Response:
        return self.llamar("POST", "/api/usuarios", json=datos)

    def transferir(self, token: str, celular_destino: str, monto: str, **extra) -> httpx.Response:
        return self.llamar("POST", "/api/transferencias", token,
                           json={"celular_destino": celular_destino, "monto": monto, **extra})


@dataclass
class Usuario:
    nombre: str
    celular: str
    pin: str
    token: str | None = None


@dataclass
class Contexto:
    """Estado de un escenario: quién actúa, la última respuesta y datos recordados."""
    api: Api
    hoy: str = "2026-11-15"
    usuarios: dict[str, Usuario] = field(default_factory=dict)
    actor: str = "Ana"
    sin_token: bool = False
    respuesta: httpx.Response | None = None
    params: dict = field(default_factory=dict)
    memoria: dict = field(default_factory=dict)

    # ---------------------------------------------------------- sesión
    def iniciar_sesion(self, nombre: str) -> Usuario:
        celular, pin = USUARIOS[nombre]
        usuario = Usuario(nombre, celular, pin, self.api.token(celular, pin))
        self.usuarios[nombre] = usuario
        self.actor = nombre
        self.sin_token = False
        return usuario

    def nuevo_usuario(self, saldo: str = "10000.00") -> Usuario:
        """Crea un usuario nuevo y vacío (sin movimientos) y lo vuelve el actor."""
        n = next(_contador_usuarios)
        celular = f"9{(int(datetime.now().timestamp()) + n) % 10**8:08d}"
        nombre = f"Nuevo{n}"
        r = self.api.registrar(dni=f"{(int(celular) % 10**8):08d}", nombres=f"Usuario Nuevo {n}",
                               celular=celular, pin="5207")
        assert r.status_code == 201, r.text
        self.api.fijar_saldo(celular, saldo)
        usuario = Usuario(nombre, celular, "5207", self.api.token(celular, "5207"))
        self.usuarios[nombre] = usuario
        self.actor = nombre
        self.sin_token = False
        return usuario

    def reiniciar_con_fecha(self, hoy: str) -> None:
        """Fija el reloj, reinicia los datos (que dependen de la fecha) y renueva los tokens."""
        self.hoy = hoy
        self.api.fijar_reloj(f"{hoy}T{HORA_FIJA}")
        self.api.reiniciar_sin_reloj()
        for u in self.usuarios.values():
            u.token = self.api.token(u.celular, u.pin)

    @property
    def token(self) -> str | None:
        if self.sin_token:
            return None
        return self.usuarios[self.actor].token

    # ---------------------------------------------------------- llamadas del actor
    def pedir(self, metodo: str, ruta: str, **kwargs) -> httpx.Response:
        self.respuesta = self.api.llamar(metodo, ruta, self.token, **kwargs)
        return self.respuesta

    def como(self, nombre: str, metodo: str, ruta: str, **kwargs) -> httpx.Response:
        """Llamada de otro usuario sin cambiar el actor ni la última respuesta."""
        if nombre not in self.usuarios:
            actor, sin = self.actor, self.sin_token
            self.iniciar_sesion(nombre)
            self.actor, self.sin_token = actor, sin
        return self.api.llamar(metodo, ruta, self.usuarios[nombre].token, **kwargs)

    def en_fecha(self, momento: str, nombre: str, metodo: str, ruta: str, **kwargs) -> httpx.Response:
        """Hace una llamada con el reloj de la app en otra fecha y luego lo restituye."""
        self.api.fijar_reloj(momento)
        try:
            return self.como(nombre, metodo, ruta, **kwargs)
        finally:
            self.api.fijar_reloj(f"{self.hoy}T{HORA_FIJA}")
