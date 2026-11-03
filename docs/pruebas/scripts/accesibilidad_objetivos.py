# Analiza los volcados de uiautomator: objetivos clicables, tamaño en dp y etiquetas.
# Uso: python accesibilidad_objetivos.py <carpeta_xml>
import sys, re, csv, os, json
import xml.etree.ElementTree as ET
DENSITY = 480 / 160.0  # wm density 480 -> 3 px por dp
SCREENS = [("Inicio", "inicio"), ("Agregar", "agregar"), ("Monto", "monto"),
           ("Movimientos", "movimientos"), ("Estadisticas", "estadisticas"),
           ("Informe", "informe"), ("Perfil", "perfil"), ("Ajustes", "ajustes"),
           ("Limites", "limites")]
def bounds(s):
    m = re.findall(r"\d+", s); x1, y1, x2, y2 = map(int, m[:4]); return x1, y1, x2, y2
def analyze(path):
    root = ET.parse(path).getroot()
    rows = []
    seen = set()
    for n in root.iter("node"):
        if n.get("clickable") != "true":
            continue
        x1, y1, x2, y2 = bounds(n.get("bounds"))
        if (x2 - x1) <= 0 or (y2 - y1) <= 0:
            continue
        key = (x1, y1, x2, y2)
        if key in seen:
            continue
        seen.add(key)
        w = (x2 - x1) / DENSITY; h = (y2 - y1) / DENSITY
        label = (n.get("content-desc") or n.get("text") or "").replace("&#10;", " / ").replace("\n", " / ")
        rows.append(dict(x=x1, y=y1, w_dp=round(w, 1), h_dp=round(h, 1),
                         lt48=(w < 48 or h < 48), lt24=(w < 24 or h < 24),
                         labeled=bool(label.strip()), label=label[:70]))
    return rows
if __name__ == "__main__":
    folder = sys.argv[1]
    out_csv = os.path.join(folder, "accesibilidad.csv")
    summary = []
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["pantalla", "x_px", "y_px", "ancho_dp", "alto_dp", "menor_48dp", "menor_24dp", "con_etiqueta", "etiqueta"])
        for name, fn in SCREENS:
            p = os.path.join(folder, "scripts", "xml", fn + ".xml")
            if not os.path.exists(p):
                continue
            rows = analyze(p)
            for r in rows:
                w.writerow([name, r["x"], r["y"], r["w_dp"], r["h_dp"], int(r["lt48"]), int(r["lt24"]), int(r["labeled"]), r["label"]])
            summary.append(dict(pantalla=name, total=len(rows),
                                menor48=sum(r["lt48"] for r in rows),
                                menor24=sum(r["lt24"] for r in rows),
                                etiquetados=sum(r["labeled"] for r in rows),
                                sin_etiqueta=sum(not r["labeled"] for r in rows),
                                peores=sorted([r for r in rows if r["lt48"]], key=lambda r: r["w_dp"] * r["h_dp"])[:3]))
    json.dump(summary, open(os.path.join(folder, "scripts", "resumen_accesibilidad.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    for s in summary:
        print(s["pantalla"], "total", s["total"], "<48", s["menor48"], "<24", s["menor24"], "etiq", s["etiquetados"], "sin", s["sin_etiqueta"])
        for r in s["peores"]:
            print("   ", r["w_dp"], "x", r["h_dp"], "dp @", r["x"], r["y"], "|", r["label"][:50])
