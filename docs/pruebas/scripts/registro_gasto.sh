#!/bin/sh
# Un gasto por repeticion: Inicio -> + -> Alimentos -> Continuar -> $5.000 -> Guardar.
# Todo dentro de un solo "adb shell". Pausas fijas de 0.4 s entre toques (4 pausas = 1.6 s).
# Tiempo de reloj del propio telefono (date +%s%N) antes del primer toque y tras la pausa final.
FIXED_PAUSE_TOTAL_MS=1600
/system/bin/sh -c '
t0=$(date +%s%N)
input tap 610 2440; sleep 0.4
input tap 476 640;  sleep 0.4
input tap 610 2220; sleep 0.4
input tap 598 795;  sleep 0.4
input tap 612 2445; sleep 0.4
t1=$(date +%s%N)
echo "T0=$t0 T1=$t1"
'
