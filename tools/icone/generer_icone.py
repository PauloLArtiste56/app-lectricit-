"""Icône de l'appli : la mascotte pile sur fond vert, en 1024×1024.
Deux variantes : `icone` (plein cadre, coins arrondis appliqués par
l'OS) et `icone_maskable` (contenu réduit dans la zone sûre)."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))
VERT, VERT_F = "#58CC02", "#46A302"
GRIS_F, GRIS_C, NOIR, BLANC = "#4A4A4A", "#E5E5E5", "#3C3C3C", "#FFFFFF"

def R(x, y, w, h, f, rx=10, extra=""): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{f}" {extra}/>\n'
def C(cx, cy, r, f, extra=""): return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{f}" {extra}/>\n'
def P(d, s, sw): return f'<path d="{d}" fill="none" stroke="{s}" stroke-width="{sw}" stroke-linecap="round"/>\n'

def mascotte(echelle, dx, dy):
    """La pile, dessinée dans un repère 300×400 puis mise à l'échelle."""
    c = R(126, 40, 48, 30, GRIS_F, 8) + R(72, 62, 156, 288, "#F5F5F5", 30, f'stroke="{GRIS_F}" stroke-width="10"')
    c += C(118, 130, 22, BLANC, f'stroke="{NOIR}" stroke-width="5"') + C(182, 130, 22, BLANC, f'stroke="{NOIR}" stroke-width="5"')
    c += C(124, 134, 10, NOIR) + C(188, 134, 10, NOIR)
    c += P("M120,172 Q150,196 180,172", NOIR, 7)
    c += C(98, 160, 9, "#FFB3B3") + C(202, 160, 9, "#FFB3B3")
    for y in (300, 258, 216):
        c += R(94, y, 112, 32, VERT, 8)
    return f'<g transform="translate({dx} {dy}) scale({echelle})">\n{c}</g>\n'

def eclair(echelle, dx, dy):
    pts = "60,0 0,60 38,60 22,110 84,44 46,44"
    return f'<g transform="translate({dx} {dy}) scale({echelle})"><polygon points="{pts}" fill="#FFC800" stroke="#E5A800" stroke-width="4" stroke-linejoin="round"/></g>\n'

def icone(nom, marge):
    # Fond vert plein cadre ; la mascotte occupe la hauteur moins la marge.
    h = 1024 - 2 * marge
    e = h / 400
    corps = R(0, 0, 1024, 1024, VERT, 0)
    corps += C(512, 1180, 900, VERT_F)  # ombre douce en bas
    corps += mascotte(e, 512 - 150 * e, marge)
    corps += eclair(e * 1.1, 512 + 120 * e, marge + 40 * e)
    doc = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">\n{corps}</svg>'
    open(os.path.join(OUT, nom + ".svg"), "w", encoding="utf-8").write(doc)

icone("icone", 150)
icone("icone_maskable", 240)
print("ok")
