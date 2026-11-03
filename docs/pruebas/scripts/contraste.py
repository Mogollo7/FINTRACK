# Razon de contraste WCAG 2.x (luminancia relativa). Escribe contraste.csv
import csv, os, sys
def lum(hx):
    hx = hx.lstrip('#'); c = [int(hx[i:i+2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def ratio(a, b):
    la, lb = lum(a), lum(b); hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)
PAIRS = [
 ("Claro", "Texto #17140F sobre fondo #FFFDF3", "#17140F", "#FFFDF3", "texto"),
 ("Claro", "Texto #17140F sobre tarjeta #FFFFFF", "#17140F", "#FFFFFF", "texto"),
 ("Claro", "Texto #17140F sobre ambar #FFA914", "#17140F", "#FFA914", "texto"),
 ("Claro", "Secundario #6B6454 sobre fondo #FFFDF3", "#6B6454", "#FFFDF3", "texto"),
 ("Claro", "Secundario #6B6454 sobre tarjeta #FFFFFF", "#6B6454", "#FFFFFF", "texto"),
 ("Claro", "Ingreso #1B7F37 sobre #FFFFFF", "#1B7F37", "#FFFFFF", "texto"),
 ("Claro", "Gasto #C62828 sobre #FFFFFF", "#C62828", "#FFFFFF", "texto"),
 ("Claro", "Texto #17140F sobre #F4F6C4", "#17140F", "#F4F6C4", "texto"),
 ("Oscuro", "Texto #F2ECDD sobre #0F0D09", "#F2ECDD", "#0F0D09", "texto"),
 ("Oscuro", "Texto #F2ECDD sobre #211D15", "#F2ECDD", "#211D15", "texto"),
 ("Oscuro", "Secundario #BDB59E sobre #0F0D09", "#BDB59E", "#0F0D09", "texto"),
 ("Oscuro", "Secundario #BDB59E sobre #211D15", "#BDB59E", "#211D15", "texto"),
 ("Oscuro", "Ingreso #5BD27A sobre #211D15", "#5BD27A", "#211D15", "texto"),
 ("Oscuro", "Gasto #FF5252 sobre #211D15", "#FF5252", "#211D15", "texto"),
 ("Oscuro", "Texto #17140F sobre ambar #FFB938", "#17140F", "#FFB938", "texto"),
]
def run(folder):
    rows = []
    for tema, nombre, fg, bg, tipo in PAIRS:
        r = ratio(fg, bg)
        aa_texto = r >= 4.5; aa_grande = r >= 3.0
        rows.append(dict(tema=tema, par=nombre, texto=fg, fondo=bg, razon=round(r, 2),
                         aa_texto_normal=("cumple" if aa_texto else "NO cumple"),
                         aa_texto_grande_componentes=("cumple" if aa_grande else "NO cumple")))
    with open(os.path.join(folder, "contraste.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    return rows
if __name__ == "__main__":
    for r in run(sys.argv[1]):
        print(f"{r['razon']:>6}  {r['aa_texto_normal']:<10} {r['aa_texto_grande_componentes']:<10} {r['par']}")
