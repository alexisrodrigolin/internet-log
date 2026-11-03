# Internet Log

Monitor para Windows que registra en un archivo de texto cuándo se corta internet y cuándo vuelve, con la duración de cada corte.

No hace falta instalar nada: usa PowerShell, que ya viene con Windows.

## Uso

| Archivo | Qué hace |
| --- | --- |
| `iniciar.bat` | Arranca el monitor en segundo plano, sin ventana. Si ya está corriendo, avisa y no abre otro. |
| `detener.bat` | Frena el monitor y anota el cierre en el log. |

Hacé doble clic en el `.bat` que necesites. Los registros se guardan en `internet_log.txt`, en la misma carpeta, y se van sumando entre usos.

`monitor.ps1` es el script que hace el trabajo y tiene que quedar en la misma carpeta que los `.bat`.

## Ejemplo de log

```
2026-11-03 16:32:14  INICIO   Monitor iniciado - internet OK
2026-11-03 16:32:18  CORTE    Se corto internet
2026-11-03 16:32:24  VOLVIO   Volvio internet (duracion del corte: 00:00:06)
2026-11-03 16:32:28  CORTE    Se corto internet
2026-11-03 16:32:33  FIN      Monitor detenido - internet seguia cortado (hace 00:00:05)
```

| Evento | Significado |
| --- | --- |
| `INICIO` | Se inició el monitor, con el estado de la conexión en ese momento. |
| `CORTE` | Se cortó internet. |
| `VOLVIO` | Volvió internet, con la duración del corte. |
| `AVISO` | Hubo un tramo sin mediciones, probablemente porque la PC estuvo suspendida. |
| `FIN` | Se detuvo el monitor. |

## Cómo detecta un corte

Cada 5 segundos hace ping a `1.1.1.1`, `8.8.8.8` y `9.9.9.9`. La comprobación falla solo si no responde ninguno.

Para no anotar microcortes, recién cuenta como corte con 2 comprobaciones fallidas seguidas, y usa la hora de la primera. Por eso un corte de unos 10 segundos o menos puede no aparecer.

## Configuración

Los valores se cambian al principio de `monitor.ps1`:

| Variable | Valor por defecto | Descripción |
| --- | --- | --- |
| `$Targets` | `1.1.1.1`, `8.8.8.8`, `9.9.9.9` | Direcciones a las que se hace ping. |
| `$IntervalSeconds` | `5` | Segundos entre comprobaciones. |
| `$TimeoutMs` | `2000` | Espera máxima por cada ping, en milisegundos. |
| `$FailuresToConfirm` | `2` | Comprobaciones fallidas seguidas para contar como corte. |
| `$GapSeconds` | `60` | Hueco entre comprobaciones a partir del cual se anota un `AVISO`. |

Si ya está corriendo, detenelo e inicialo de nuevo para aplicar los cambios.

## Limitaciones

- **Solo mide con la PC prendida.** Si estaba cortado antes de suspenderse, la duración de ese corte incluye el tiempo suspendida.
- **No distingue dónde está el problema.** Un corte del proveedor, del router o del Wi-Fi de la PC se registran igual.
- **No arranca solo.** Después de reiniciar la PC hay que abrir `iniciar.bat` de nuevo.
