# Genera tiempos.csv y las graficas PNG a partir de los datos crudos de la carpeta docs/pruebas.
import csv, os, statistics, json
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG, FG, AMB, RED, GRN = "#0F0D09", "#F2ECDD", "#FFA914", "#C62828", "#5BD27A"
plt.rcParams.update({"figure.facecolor": BG, "axes.facecolor": BG, "savefig.facecolor": BG,
                     "text.color": FG, "axes.labelcolor": FG, "xtick.color": FG, "ytick.color": FG,
                     "axes.edgecolor": "#5a5244", "font.family": "DejaVu Sans", "font.size": 12})
W, H, DPI = 1600, 900, 100
def fig():
    return plt.subplots(figsize=(W / DPI, H / DPI), dpi=DPI)

# ---- datos
arr = [r for r in csv.DictReader(open(os.path.join(P, "arranque_raw.csv")))]
arr_total = [int(r["TotalTime"]) for r in arr]
reg = [r for r in csv.DictReader(open(os.path.join(P, "registro_raw.csv")))]
reg_ms = [int(r["ms_total"]) for r in reg]
FIXED_MS = 2000  # 5 pausas de 0.4 s dentro del script
reg_net = [v - FIXED_MS for v in reg_ms]

with open(os.path.join(P, "tiempos.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["prueba", "repeticion", "valor_ms", "nota"])
    for r in arr:
        w.writerow(["arranque_frio_TotalTime", r["rep"], r["TotalTime"], "am start -W; ThisTime no devuelto por el equipo"])
    for r, net in zip(reg, reg_net):
        w.writerow(["registro_gasto_total", r["rep"], r["ms_total"], "incluye 2000 ms de pausas fijas"])
        w.writerow(["registro_gasto_neto_estimado", r["rep"], net, "total menos pausas fijas"])

# (a) arranque
fg, ax = fig()
xs = list(range(1, len(arr_total) + 1))
ax.bar(xs, arr_total, color=AMB, width=0.6)
m = statistics.mean(arr_total)
ax.axhline(m, color=FG, ls="--", lw=2, label=f"Media {m:.0f} ms")
for x, v in zip(xs, arr_total):
    ax.text(x, v + 20, f"{v}", ha="center", color=FG, fontsize=11)
ax.set_xticks(xs); ax.set_xlabel("Repetición de arranque en frío (n = %d)" % len(xs))
ax.set_ylabel("Tiempo de arranque TotalTime (ms)")
ax.set_title("Arranque en frío de FinTrack (build debug, Redmi Note 13 Pro 5G)", color=AMB, fontsize=15)
ax.set_ylim(0, max(arr_total) * 1.2); ax.legend(facecolor=BG, edgecolor=FG, labelcolor=FG)
fg.tight_layout(); fg.savefig(os.path.join(P, "grafica_arranque.png")); plt.close(fg)

# (b) registro
fg, ax = fig()
xs = list(range(1, len(reg_ms) + 1))
ax.bar(xs, [v / 1000 for v in reg_ms], color=[AMB] * len(xs), width=0.6, label="Total medido (incluye 2 s de pausas)")
ax.bar(xs, [v / 1000 for v in reg_net], color=GRN, width=0.35, label="Neto estimado (sin pausas fijas)")
ax.axhline(3.0, color=RED, lw=2.5, label="Meta: 3 s")
mt = statistics.mean(reg_ms) / 1000; mn = statistics.mean(reg_net) / 1000
ax.axhline(mt, color=FG, ls="--", lw=1.5, label=f"Media total {mt:.2f} s")
for x, v in zip(xs, reg_ms):
    ax.text(x, v / 1000 + 0.05, f"{v/1000:.2f}", ha="center", color=FG, fontsize=10)
ax.set_xticks(xs); ax.set_xlabel("Repetición del flujo (Inicio → + → Alimentos → Continuar → $5.000 → Guardar)")
ax.set_ylabel("Tiempo (s)"); ax.set_ylim(0, 3.6)
ax.set_title(f"Registro de un gasto: media total {mt:.2f} s, neta estimada {mn:.2f} s", color=AMB, fontsize=15)
ax.legend(facecolor=BG, edgecolor=FG, labelcolor=FG, loc="lower right", fontsize=10)
fg.tight_layout(); fg.savefig(os.path.join(P, "grafica_registro.png")); plt.close(fg)

# (d) objetivos tactiles
summ = json.load(open(os.path.join(P, "scripts", "resumen_accesibilidad.json"), encoding="utf-8"))
names = [s["pantalla"] for s in summ]
lt48 = [s["menor48"] for s in summ]
ge48 = [s["total"] - s["menor48"] for s in summ]
fg, ax = fig()
x = list(range(len(names)))
ax.bar(x, ge48, color=GRN, label="≥ 48 dp")
ax.bar(x, lt48, bottom=ge48, color=RED, label="< 48 dp")
for i, s in enumerate(summ):
    ax.text(i, s["total"] + 0.3, f"{s['menor48']} de {s['total']}", ha="center", color=FG, fontsize=11)
ax.set_xticks(x); ax.set_xticklabels(names, rotation=0, fontsize=11)
ax.set_xlabel("Pantalla (solo lo visible en el volcado de ese momento)")
ax.set_ylabel("Objetivos táctiles clicables (nº)")
ax.set_title("Objetivos táctiles por pantalla: cuántos miden menos de 48 dp", color=AMB, fontsize=15)
ax.legend(facecolor=BG, edgecolor=FG, labelcolor=FG)
ax.set_ylim(0, max(s["total"] for s in summ) + 3)
fg.tight_layout(); fg.savefig(os.path.join(P, "grafica_objetivos_tactiles.png")); plt.close(fg)

# (e) contraste
rows = list(csv.DictReader(open(os.path.join(P, "contraste.csv"), encoding="utf-8")))
fg, ax = fig()
labels = [r["par"] for r in rows]; vals = [float(r["razon"]) for r in rows]
colors = [GRN if float(r["razon"]) >= 4.5 else RED for r in rows]
y = list(range(len(rows)))
ax.barh(y, vals, color=colors)
ax.axvline(4.5, color=FG, ls="--", lw=2, label="4,5:1 (texto normal, AA)")
ax.axvline(3.0, color=AMB, ls=":", lw=2, label="3:1 (texto grande y componentes, AA)")
for yi, v in zip(y, vals):
    ax.text(v + 0.2, yi, f"{v:.2f}:1", va="center", color=FG, fontsize=10)
ax.set_yticks(y); ax.set_yticklabels(labels, fontsize=10); ax.invert_yaxis()
ax.set_xlabel("Razón de contraste (x:1)"); ax.set_xlim(0, 20)
ax.set_title("Contraste WCAG por par de color: todos cumplen AA", color=AMB, fontsize=15)
ax.legend(facecolor=BG, edgecolor=FG, labelcolor=FG, loc="lower right", fontsize=10)
fg.tight_layout(); fg.savefig(os.path.join(P, "grafica_contraste.png")); plt.close(fg)

print("arranque media ms", round(m), "min", min(arr_total), "max", max(arr_total))
print("registro total media s", round(mt, 3), "neto media s", round(mn, 3), "min", min(reg_ms), "max", max(reg_ms), ">3s:", sum(v > 3000 for v in reg_ms))
