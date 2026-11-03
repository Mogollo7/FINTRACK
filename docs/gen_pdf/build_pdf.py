"""MD del informe FinTrack (Avance 2) -> HTML con el estilo del PDF de Figma -> PDF con Chrome headless.

Uso:  python build_pdf.py
Salida: ../FinTrack_Avance2_Informe_Tecnico.pdf  (y informe.html al lado de este script)
La paginación la hace un script en línea dentro del HTML (mide y reparte bloques en hojas A4).
"""
import html
import re
import subprocess
import sys
from pathlib import Path

import markdown

HERE = Path(__file__).resolve().parent
DOCS = HERE.parent
MD = DOCS / "Sustentacion_y_Guia_de_Desarrollo_FinTrack_Avance2.md"
OUT_HTML = HERE / "informe.html"
OUT_PDF = DOCS / "FinTrack_Avance2_Informe_Tecnico.pdf"
CAT_SVG = Path(r"D:\feibert\api\fintrack_app\assets\icon\cat_mascot.svg")
CHROME = r"C:/Program Files/Google/Chrome/Application/chrome.exe"

# Divisores: (número grande, título, secciones del MD que agrupa)
GROUPS = [
    ("00", "Introducción", [0]),
    ("01", "Lo implementado", [1, 2, 3]),
    ("04", "Datos, capacidad y evidencia", [4, 5, 6]),
    ("07", "Límites y siguiente incremento", [7, 8]),
    ("09", "Demostración visual", [9]),
    ("10", "Guía de desarrollo y referencias", [10, 11]),
]


def inline(s):
    out = markdown.markdown(s.strip())
    return re.sub(r"^<p>|</p>$", "", out)


def amber(s):
    """**palabra** -> <em> ámbar (titulares)."""
    return re.sub(r"\*\*(.+?)\*\*", r"<em>\1</em>", html.escape(s, quote=False))


def cat_svg(fill):
    s = CAT_SVG.read_text(encoding="utf-8")
    s = re.sub(r'\s(width|height|style|preserveAspectRatio|overflow)="[^"]*"', "", s, count=5)
    return s.replace('fill="#F2ECDD"', f'fill="{fill}"').replace('stroke="black"', 'stroke="none"')


def logo(dark_text=False):
    return (f'<div class="logo{" ink" if dark_text else ""}"><span class="dot">{cat_svg("#0F0D09")}</span>'
            f'FinTrack</div>')


def ring(pct, text):
    v = float(pct.replace(",", ".").replace("%", "").strip())
    c = 2 * 3.14159 * 40
    return (f'<div class="ring"><svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" class="trk"/>'
            f'<circle cx="50" cy="50" r="40" class="arc" stroke-dasharray="{c * v / 100:.1f} {c:.1f}" '
            f'transform="rotate(-90 50 50)"/><text x="50" y="57">{html.escape(pct.strip())}</text></svg>'
            f'<p>{inline(text)}</p></div>')


def phone(rel, cls="phone"):
    p = DOCS / rel
    if p.exists():
        return f'<div class="{cls}"><img src="{p.as_uri()}"></div>'
    return f'<div class="{cls} missing"><span>{html.escape(Path(rel).name)}<br>(captura pendiente)</span></div>'


FLOW = """<svg class="flow" viewBox="0 0 688 92">
<defs><marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
<path d="M0 0L10 5L0 10z" fill="#FFA914"/></marker></defs>
{boxes}</svg>"""


def flow_svg():
    steps = [("1", "Arranque", "splash · guía"), ("2", "Cuenta", "crear · entrar"), ("3", "Registrar", "+ · monto · tiquete"),
             ("4", "Consultar", "inicio · historial"), ("5", "Decidir", "límites · PDF")]
    out, w, gap = [], 116, 25
    for i, (n, t, s) in enumerate(steps):
        x = i * (w + gap) + 2
        out.append(f'<rect x="{x}" y="8" width="{w}" height="76" rx="12" fill="#211D15" stroke="#3D3629"/>'
                   f'<text x="{x + 14}" y="36" class="fn">{n}</text><text x="{x + 14}" y="58" class="ft">{t}</text>'
                   f'<text x="{x + 14}" y="74" class="fs">{s}</text>')
        if i < len(steps) - 1:
            out.append(f'<line x1="{x + w + 3}" y1="46" x2="{x + w + gap - 3}" y2="46" stroke="#FFA914" stroke-width="2" marker-end="url(#ar)"/>')
    return FLOW.format(boxes="".join(out))


def preprocess(body):
    """Convierte las convenciones del MD (Dato, Nota, capturas, flujo) en HTML antes de markdown."""
    lines, out, i = body.split("\n"), [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("> **Dato:**"):
            rings = []
            while i < len(lines) and (lines[i].startswith("> **Dato:**") or not lines[i].strip()):
                if lines[i].strip():
                    pct, txt = lines[i][len("> **Dato:**"):].split("|", 1)
                    rings.append(ring(pct, txt))
                i += 1
            out += ["", f'<div class="rings">{"".join(rings)}</div>', ""]
            continue
        if ln.startswith("> **Nota:**"):
            out += ["", f'<div class="note"><span class="plus">+</span><p>{inline(ln[len("> **Nota:**"):])}</p></div>', ""]
        elif ln.startswith("- ![") and "capturas/" in ln:
            figs = []
            while i < len(lines) and lines[i].startswith("- !["):
                m = re.match(r"- !\[[^\]]*\]\(([^)]+)\)\s*(.*)", lines[i])
                figs.append(f'<figure>{phone(m.group(1))}<figcaption>{inline(m.group(2))}</figcaption></figure>')
                i += 1
            out += ["", f'<div class="grid">{"".join(figs)}</div>', ""]
            continue
        elif ln.strip() == "<!-- flujo -->":
            out += ["", flow_svg(), ""]
        else:
            out.append(ln)
        i += 1
    return "\n".join(out)


def parse():
    text = MD.read_text(encoding="utf-8")
    head, *_ = re.split(r"^## \d", text, maxsplit=1, flags=re.M)
    meta = dict(re.findall(r"^\*\*(.+?):\*\*\s*(.+)$", head, flags=re.M))
    secs = {}
    for m in re.finditer(r"^## (\d+)\. ([^\n|]+?)(?: \| ([^\n]+))?\n(.*?)(?=^## \d|\Z)", text, flags=re.M | re.S):
        n = int(m.group(1))
        body = re.sub(r"\n---\s*$", "", m.group(4).strip())
        secs[n] = dict(n=n, title=m.group(2).strip(), head=m.group(3) or m.group(2), body=body,
                       subs=re.findall(r"^### (.+)$", body, flags=re.M))
    return meta, secs


def section_html(s):
    sec = f"{s['n']:02d} · {s['title']}"
    body = markdown.markdown(preprocess(s["body"]), extensions=["tables", "fenced_code"])
    if s["n"] == 11:
        body = body.replace("<p>", '<p class="ref">')
    return (f'<div class="kicker" id="s{s["n"]}" data-sec="{html.escape(sec)}">{html.escape(sec)}</div>'
            f'<h2 class="headline">{amber(s["head"])}</h2>{body}')


def build():
    meta, secs = parse()
    integ = [x.strip() for x in re.split(r",| y ", meta.get("Integrantes", ""))]
    cover = f"""
<section class="page dark cover">
  {logo()}
  <div class="tag">CONTROL EN<br>TUS MANOS</div>
  <div class="bigdollar">$</div>
  <div class="cphone-wrap">{phone("capturas/09_gasto_registrado.png", "phone cphone")}</div>
  <div class="ctitle"><div class="pre">Aplicación móvil para<br>la gestión de</div>
    <div class="huge">GASTOS<br><em>HORMIGA</em></div>
    <div class="sub">Segundo incremento · Prototipo<br>móvil funcional (Examen 2)</div><div class="bar"></div></div>
  <div class="cfoot"><b>{"<br>".join(map(html.escape, integ))}</b>
    <span class="asig">{html.escape(meta.get("Asignatura", ""))}</span>
    {html.escape(meta.get("Institución", ""))}<br>Docente: {html.escape(meta.get("Docente", ""))}<br>{html.escape(meta.get("Fecha", "").capitalize())}</div>
</section>"""

    rows = "".join(f'<div class="trow" data-target="s{n}"><span class="tn">{n:02d}</span>'
                   f'<span class="tt">{html.escape(s["title"])}</span><span class="tp"></span></div>'
                   for n, s in sorted(secs.items()))
    toc = f"""
<section class="page light toc">
  <div class="lhead">{logo(True)}</div>
  <h1>Tabla de<br>Contenido<em>.</em></h1>
  <div class="rows">{rows}</div>
  <div class="tend">Más control.<br>Más libertad.<div class="bar"></div></div>
  <div class="semi"></div>
</section>"""

    parts = [cover, toc]
    for num, title, ns in GROUPS:
        if len(ns) > 1:
            subs = [f"{n:02d} · {secs[n]['title']}" for n in ns]
        else:
            subs = secs[ns[0]]["subs"] or [secs[ns[0]]["title"]]
        parts.append(f"""
<section class="page dark divider">
  {logo()}<div class="dnum">{num}</div><div class="circle"></div>
  <div class="dbox"><div class="dbar"></div><h1>{html.escape(title)}</h1>
  <ul>{"".join(f"<li>{html.escape(x)}</li>" for x in subs)}</ul></div>
  <div class="pn"></div>
</section>""")
        parts.append(f'<div class="flow-src">{"".join(section_html(secs[n]) for n in ns)}</div>')

    parts.append(f"""
<section class="page dark back">
  <div class="dots"></div><div class="circle tr"></div>
  <div class="bcenter"><div class="bicon">{cat_svg("#0F0D09")}</div><h1>FinTrack</h1><p>Control de gastos en tus manos</p></div>
  <div class="glow"></div>
  <div class="bfoot">Proyecto académico · Corporación Universitaria Lasallista · 2026</div>
</section>""")

    doc = TEMPLATE.replace("{{LOGO}}", logo()).replace("{{BODY}}", "\n".join(parts))
    OUT_HTML.write_text(doc, encoding="utf-8")
    cmd = [CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--virtual-time-budget=30000",
           "--run-all-compositor-stages-before-draw", f"--print-to-pdf={OUT_PDF}", OUT_HTML.as_uri()]
    subprocess.run(cmd, check=True, capture_output=True, timeout=180)
    print("PDF:", OUT_PDF)
    try:
        import fitz
        print("Páginas:", len(fitz.open(OUT_PDF)))
    except ImportError:
        pass


TEMPLATE = r"""<!doctype html><html lang="es"><head><meta charset="utf-8"><title>FinTrack · Informe técnico Avance 2</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&family=JetBrains+Mono:wght@400&display=block" rel="stylesheet">
<style>
:root{--bg:#0F0D09;--card:#211D15;--line:#2E291F;--line2:#3D3629;--amber:#FFA914;--paper:#FFFDF3;--txt:#F2ECDD;--txt2:#BDB59E;--ink:#17140F;--ink2:#6B6454;--lline:#DDD5B8}
@page{size:A4;margin:0}
*{box-sizing:border-box;margin:0;padding:0}
html,body{background:var(--bg);-webkit-print-color-adjust:exact;print-color-adjust:exact}
body{font-family:Inter,Arial,sans-serif;color:var(--txt);font-size:10pt}
.page{width:210mm;height:297mm;position:relative;overflow:hidden;page-break-after:always;break-after:page}
.dark{background:var(--bg)}.light{background:var(--paper);color:var(--ink)}
em{font-style:italic}.headline em,.huge em,.toc h1 em{font-style:normal;color:var(--amber)}
.logo{position:absolute;top:13mm;left:16mm;display:flex;align-items:center;gap:2mm;font-weight:800;font-size:10.5pt;color:#fff;z-index:5}
.logo.ink{color:var(--ink);position:static}
.logo .dot{width:5mm;height:5mm;border-radius:50%;background:var(--amber);display:flex;align-items:center;justify-content:center}
.logo .dot svg{width:2.6mm;height:3.2mm}
/* portada */
.cover .tag{position:absolute;top:30mm;left:16mm;font-size:5.6pt;letter-spacing:.42em;color:var(--txt2);line-height:1.6}
.bigdollar{position:absolute;right:-30mm;top:-12mm;font:900 470pt/1 Inter,Arial;color:var(--amber);z-index:1}
.cphone-wrap{position:absolute;left:112mm;top:78mm;transform:rotate(12deg);z-index:2}
.phone{border:1.6mm solid #050403;border-radius:6mm;background:#000;overflow:hidden;aspect-ratio:1220/2712;box-shadow:0 0 0 .35mm #3D3629}
.phone img{width:100%;height:100%;object-fit:contain;display:block}
.cphone{width:64mm;border-width:2.6mm;border-radius:9mm;box-shadow:0 0 0 .5mm #3D3629,0 6mm 14mm rgba(0,0,0,.55)}
.phone.missing{background:var(--card);border-style:solid;display:flex;align-items:center;justify-content:center;text-align:center;font-size:7pt;color:var(--amber);padding:3mm}
.ctitle{position:absolute;top:96mm;left:16mm;z-index:3}
.ctitle .pre{font-size:19pt;font-weight:500;color:#fff;line-height:1.12;margin-bottom:3mm}
.ctitle .huge{font:900 50pt/0.95 Inter,Arial;color:#fff;letter-spacing:-.01em;text-shadow:0 1mm 3mm rgba(0,0,0,.35)}
.ctitle .sub{font-size:8.6pt;color:var(--txt);margin-top:8mm;line-height:1.4}
.bar{width:9mm;height:.7mm;background:var(--amber);margin-top:9mm}
.cfoot{position:absolute;left:16mm;bottom:16mm;font-size:7pt;color:var(--txt2);line-height:1.55;z-index:3}
.cfoot b{display:block;color:#fff;font-size:7.6pt;margin-bottom:4mm}
.cfoot .asig{display:block;color:var(--amber);font-weight:700;font-size:7.4pt}
/* tabla de contenido */
.lhead{position:absolute;top:11mm;left:16mm;right:16mm;padding-bottom:3mm;border-bottom:.25mm solid var(--lline)}
.toc h1{position:absolute;top:34mm;left:16mm;font:900 40pt/0.98 Inter,Arial;color:var(--ink);letter-spacing:-.02em}
.toc .rows{position:absolute;top:92mm;left:16mm;right:16mm}
.trow{display:flex;align-items:center;border-bottom:.25mm solid var(--lline);height:11.5mm;font-size:8.6pt}
.tn{width:18mm;font:900 13pt Inter,Arial;color:var(--amber)}.tt{flex:1}.tp{font-weight:600}
.tend{position:absolute;left:16mm;bottom:20mm;font:900 10.5pt/1.2 Inter,Arial}
.tend .bar{margin-top:5mm}
.semi{position:absolute;right:-24mm;bottom:-48mm;width:100mm;height:100mm;border-radius:50%;background:var(--amber)}
/* divisores */
.dnum{position:absolute;top:-6mm;right:6mm;font:900 300pt/0.9 Inter,Arial;color:var(--amber);letter-spacing:-.04em}
.circle{position:absolute;right:-30mm;bottom:40mm;width:110mm;height:110mm;border-radius:50%;border:.3mm solid var(--line2)}
.dbox{position:absolute;left:16mm;right:30mm;top:150mm}
.dbar{width:12mm;height:.8mm;background:#fff;margin-bottom:8mm}
.dbox h1{font:900 30pt/1.02 Inter,Arial;color:#fff;letter-spacing:-.015em;margin-bottom:8mm}
.dbox ul{list-style:none;font-size:8.4pt;color:var(--txt2);line-height:2}
.pn{position:absolute;left:16mm;bottom:11mm;font-size:6.5pt;color:var(--txt2)}
/* hojas de contenido */
.hsec{position:absolute;top:14mm;right:16mm;font-size:6.5pt;color:var(--txt2)}
.body{position:absolute;top:26mm;left:16mm;right:16mm;bottom:19mm;overflow:hidden}
.kicker{font-size:6.4pt;letter-spacing:.3em;text-transform:uppercase;color:var(--amber);font-weight:600;margin:5mm 0 2mm}
.body>.kicker:first-child{margin-top:0}
.headline{font:900 19pt/1.08 Inter,Arial;color:#fff;letter-spacing:-.015em;margin-bottom:4mm}
.body h3{font-size:10.5pt;font-weight:800;color:#fff;margin:4mm 0 1.6mm}
.body p{font-size:9.4pt;line-height:1.48;margin-bottom:2.4mm;color:var(--txt)}
.body strong{color:#fff}
.body ul,.body ol{margin:0 0 2.6mm 5mm;font-size:9.4pt;line-height:1.48}
.body li{margin-bottom:1.2mm}.body li::marker{color:var(--amber);font-weight:700}
.body code{font-family:'JetBrains Mono',Consolas,monospace;font-size:.86em;color:var(--amber)}
.body pre{background:var(--card);border:.25mm solid var(--line);border-radius:3mm;padding:3.5mm 4mm;margin:1mm 0 3mm;white-space:pre-wrap}
.body pre code{color:var(--txt);font-size:8.2pt;line-height:1.6}
table{width:100%;border-collapse:collapse;margin:1mm 0 3.5mm;font-size:8.1pt;line-height:1.38}
th{background:var(--amber);color:var(--bg);text-align:left;font-weight:800;padding:1.8mm 2.4mm}
td{padding:1.7mm 2.4mm;border-bottom:.25mm solid var(--line);vertical-align:top;color:var(--txt)}
td:first-child{font-weight:700;color:#fff;white-space:nowrap}
tr:nth-child(even) td{background:rgba(33,29,21,.55)}
.rings{display:flex;gap:5mm;margin:2mm 0 3.5mm}
.ring{flex:1;background:var(--card);border:.25mm solid var(--line);border-radius:4mm;padding:4mm;display:flex;align-items:center;gap:4mm}
.ring svg{width:26mm;height:26mm;flex:none}
.ring .trk{fill:none;stroke:var(--line2);stroke-width:10}.ring .arc{fill:none;stroke:var(--amber);stroke-width:10}
.ring text{font:800 17px Inter,Arial;fill:#fff;text-anchor:middle}
.body .ring p{font-size:8.4pt;color:var(--txt2);margin:0}
.note{display:flex;gap:3.5mm;align-items:flex-start;background:var(--card);border:.25mm solid var(--line);border-radius:4mm;padding:3.5mm 4mm;margin:2mm 0 3.5mm}
.plus{flex:none;width:6mm;height:6mm;border-radius:50%;background:var(--amber);color:var(--bg);font-weight:900;font-size:11pt;display:flex;align-items:center;justify-content:center;line-height:1}
.body .note p{font-size:8.6pt;margin:0;color:var(--txt)}
.flow{width:100%;margin:1mm 0 4mm}
.flow .fn{font:900 18px Inter,Arial;fill:#FFA914}.flow .ft{font:800 14px Inter,Arial;fill:#fff}.flow .fs{font:500 9.5px Inter,Arial;fill:#BDB59E}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:4mm 6mm;margin:1mm 0 4mm}
.grid figure{display:flex;flex-direction:column;align-items:center}
.grid .phone{width:35mm}
.grid figcaption{font-size:7.3pt;line-height:1.4;color:var(--txt2);margin-top:2.4mm}
.grid figcaption strong{color:#fff}
.body a{color:var(--txt2);text-decoration:none;word-break:break-all}
.body p.ref{padding-left:8mm;text-indent:-8mm;font-size:8.6pt}
/* contraportada */
.back .bcenter{position:absolute;top:96mm;left:0;right:0;text-align:center}
.bicon{width:21mm;height:21mm;border-radius:50%;background:var(--amber);margin:0 auto 7mm;display:flex;align-items:center;justify-content:center}
.bicon svg{width:10mm;height:12.5mm}
.back h1{font:900 42pt/1 Inter,Arial;color:#fff;letter-spacing:-.02em}
.back p{font-size:10pt;color:var(--txt);margin-top:4mm}
.glow{position:absolute;left:-55mm;bottom:-95mm;width:190mm;height:190mm;border-radius:50%;background:radial-gradient(circle at 60% 30%,#FFA914 0%,#B86A00 45%,#0F0D09 78%)}
.circle.tr{right:-45mm;top:-45mm;bottom:auto;width:110mm;height:110mm}
.dots{position:absolute;right:16mm;top:16mm;width:16mm;height:12mm;background-image:radial-gradient(#BDB59E 0.35mm,transparent 0.45mm);background-size:4mm 4mm;opacity:.7}
.bfoot{position:absolute;right:16mm;bottom:14mm;font-size:7pt;color:var(--txt2)}
.flow-src{display:none}
</style></head><body>
{{BODY}}
<template id="tpl"><section class="page dark content">{{LOGO}}<div class="hsec"></div><div class="body"></div><div class="pn"></div></section></template>
<script>
function paginate(){
  const tpl=document.getElementById('tpl');
  document.querySelectorAll('.flow-src').forEach(src=>{
    let body;
    const newPage=()=>{const p=tpl.content.firstElementChild.cloneNode(true);src.parentNode.insertBefore(p,src);body=p.querySelector('.body');};
    const over=()=>body.scrollHeight>body.clientHeight+1;
    const isHead=e=>e&&e.matches('h3,.kicker,.headline');
    const moveOn=(el)=>{ // lleva el bloque (y los títulos que lo preceden) a una hoja nueva
      const carry=[];while(isHead(body.lastElementChild)&&body.lastElementChild!==el){carry.unshift(body.lastElementChild);body.lastElementChild.remove();}
      if(!body.children.length&&!carry.length){body.appendChild(el);return;}
      newPage();carry.forEach(c=>body.appendChild(c));body.appendChild(el);};
    const split=(b)=>{
      const isT=b.matches('table'),cont=isT?b.querySelector('tbody'):b,items=[...cont.children];
      items.forEach(i=>i.remove());
      let cur=b,cc=cont,n=0,done=0;
      for(const it of items){
        cc.appendChild(it);
        if(!over()){n++;done++;continue;}
        it.remove();
        if(n===0){cur.remove();moveOn(cur);cc.appendChild(it);n=1;done++;continue;}
        const cl=cur.cloneNode(true),c2=isT?cl.querySelector('tbody'):cl;c2.innerHTML='';
        if(cl.matches('ol'))cl.setAttribute('start',done+1);
        newPage();body.appendChild(cl);cur=cl;cc=c2;cc.appendChild(it);n=1;done++;
      }};
    newPage();
    [...src.children].forEach(b=>{
      body.appendChild(b);
      if(!over())return;
      if(b.matches('table,.grid,ul,ol')){split(b);return;}
      b.remove();moveOn(b);});
    src.remove();
  });
  const pages=[...document.querySelectorAll('.page')],T=pages.length,pad=n=>String(n).padStart(2,'0');
  let last='';
  pages.forEach((p,i)=>{
    const pn=p.querySelector('.pn');if(pn)pn.textContent=pad(i+1)+' / '+pad(T);
    const b=p.querySelector('.body');if(!b)return;const f=b.firstElementChild;if(f&&f.matches('.kicker'))last=f.dataset.sec;
    p.querySelector('.hsec').textContent=last;const ks=b.querySelectorAll('.kicker');if(ks.length)last=ks[ks.length-1].dataset.sec;
  });
  document.querySelectorAll('.trow').forEach(r=>{
    const t=document.getElementById(r.dataset.target);
    if(t)r.querySelector('.tp').textContent=pad(pages.indexOf(t.closest('.page'))+1);});
  document.title+=' ['+T+']';
}
Promise.all(['400 10px Inter','700 10px Inter','800 10px Inter','900 10px Inter'].map(f=>document.fonts.load(f)))
  .catch(()=>{}).finally(paginate);
</script></body></html>"""

if __name__ == "__main__":
    sys.exit(build())
