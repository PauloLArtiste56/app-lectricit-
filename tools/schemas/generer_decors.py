"""Illustrations plates du parcours (style Duolingo) : un SVG 300×300 par
décor, plus la mascotte « pile » en quatre niveaux de charge (300×400).
Rendu PNG ensuite par Chromium sans tête. Aucune dépendance externe."""
import math, os

OUT = os.path.dirname(os.path.abspath(__file__))
VERT, VERT_F = "#58CC02", "#46A302"
BLEU, BLEU_F, BLEU_C = "#1CB0F6", "#1899D6", "#84D8FF"
JAUNE, JAUNE_F = "#FFC800", "#E5A800"
ORANGE, ORANGE_F = "#FF9600", "#E08600"
ROUGE, ROUGE_F = "#FF4B4B", "#D33131"
GRIS, GRIS_F, GRIS_C = "#AFAFAF", "#777777", "#E5E5E5"
BRUN, BRUN_F = "#A5673F", "#7A4A2B"
BLANC, NOIR = "#FFFFFF", "#3C3C3C"
VIOLET, ROSE, TEAL = "#CE82FF", "#FF86D0", "#00CD9C"
OMBRE = "rgba(0,0,0,0.13)"

def svg(nom, corps, w=300, h=300, ombre=True):
    sol = f'<ellipse cx="{w/2}" cy="{h-22}" rx="{w*0.32}" ry="14" fill="{OMBRE}"/>' if ombre else ""
    doc = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">\n{sol}\n{corps}\n</svg>'
    open(os.path.join(OUT, nom + ".svg"), "w", encoding="utf-8").write(doc)

def R(x, y, w, h, f, rx=10, extra=""): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{f}" {extra}/>\n'
def C(cx, cy, r, f, extra=""): return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{f}" {extra}/>\n'
def E(cx, cy, rx, ry, f, extra=""): return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{f}" {extra}/>\n'
def P(d, f="none", s="none", sw=0, extra=""): return f'<path d="{d}" fill="{f}" stroke="{s}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" {extra}/>\n'
def L(x1, y1, x2, y2, s, sw=8): return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{s}" stroke-width="{sw}" stroke-linecap="round"/>\n'
def G(corps, tr): return f'<g transform="{tr}">\n{corps}</g>\n'
def poly(pts, f, extra=""): return f'<polygon points="{" ".join(f"{x},{y}" for x, y in pts)}" fill="{f}" {extra}/>\n'

D = {}
# --- Chapitre 1 : les fondamentaux -------------------------------------
D["ampoule"] = (C(150, 125, 78, JAUNE) + C(128, 100, 22, "#FFE47A") +
    R(118, 190, 64, 22, GRIS) + R(122, 212, 56, 34, GRIS_F, 8) + L(126, 224, 174, 224, GRIS, 4) + L(126, 236, 174, 236, GRIS, 4) +
    L(150, 22, 150, 40, JAUNE, 9) + L(70, 55, 84, 67, JAUNE, 9) + L(230, 55, 216, 67, JAUNE, 9) + L(40, 125, 58, 125, JAUNE, 9) + L(260, 125, 242, 125, JAUNE, 9))
D["pile"] = (R(128, 40, 44, 26, GRIS_F, 8) + R(88, 60, 124, 190, VERT, 18) + R(88, 120, 124, 60, VERT_F, 0) +
    L(150, 84, 150, 106, BLANC, 9) + L(139, 95, 161, 95, BLANC, 9) + L(139, 218, 161, 218, BLANC, 9) + R(100, 72, 14, 166, "#7EE04A", 7))
D["aimant"] = (P("M95,72 V170 A55,55 0 0 0 205,170 V72", "none", ROUGE, 42) + R(74, 40, 42, 52, GRIS_C, 6) + R(184, 40, 42, 52, GRIS_C, 6) +
    L(110, 120, 110, 165, "#FF8A8A", 8) + L(60, 250, 84, 250, BLEU, 8) + L(216, 250, 240, 250, BLEU, 8) + C(72, 250, 6, BLEU) + C(228, 250, 6, BLEU))
# --- Chapitre 2 : la maison --------------------------------------------
D["maison"] = (R(70, 130, 160, 120, "#FFF3D6", 8) + poly([(50, 140), (150, 55), (250, 140)], ROUGE) + poly([(72, 140), (150, 74), (228, 140)], ROUGE_F) +
    R(128, 175, 44, 75, BRUN, 8) + C(160, 214, 4, JAUNE) + R(84, 150, 34, 34, BLEU_C, 6) + R(182, 150, 34, 34, BLEU_C, 6) + R(196, 70, 22, 40, GRIS_F, 4))
D["prise"] = (R(50, 50, 200, 200, GRIS_C, 30) + C(150, 150, 82, BLANC) + C(150, 150, 82, "none", f'stroke="{GRIS}" stroke-width="6"') +
    C(120, 168, 12, NOIR) + C(180, 168, 12, NOIR) + C(150, 112, 11, GRIS_F) + C(64, 64, 6, GRIS) + C(236, 64, 6, GRIS) + C(64, 236, 6, GRIS) + C(236, 236, 6, GRIS))
D["tableau"] = (R(50, 50, 200, 200, GRIS_C, 18) + R(64, 64, 172, 172, BLANC, 12) + R(74, 110, 40, 70, "#F3F3F3", 6) + R(120, 110, 40, 70, "#F3F3F3", 6) + R(166, 110, 40, 70, "#F3F3F3", 6) +
    R(84, 118, 20, 26, VERT, 4) + R(130, 118, 20, 26, VERT, 4) + R(176, 118, 20, 26, ROUGE, 4) + R(74, 76, 132, 22, GRIS, 6) + L(84, 200, 216, 200, BLEU, 8))
# --- Chapitre 3 : sécurité de base ------------------------------------
D["casque"] = (P("M62,178 A88,88 0 0 1 238,178 Z", ORANGE) + R(40, 172, 220, 26, ORANGE_F, 12) + R(138, 92, 24, 80, "#FFB74D", 10) + E(105, 130, 14, 22, "#FFC77A"))
D["panneau_danger"] = (poly([(150, 40), (270, 250), (30, 250)], NOIR) + poly([(150, 66), (248, 236), (52, 236)], JAUNE) +
    poly([(160, 110), (128, 175), (152, 175), (140, 222), (178, 150), (154, 150), (168, 110)], NOIR))
D["gants"] = (P("M95,250 V150 Q95,95 150,95 Q205,95 205,150 V250 Z", ORANGE) + P("M95,175 Q60,150 70,120 Q85,100 105,125 Z", ORANGE) +
    R(88, 214, 124, 40, ORANGE_F, 10) + L(150, 110, 150, 200, "#FFB066", 6) + L(120, 135, 180, 135, "#FFB066", 6))
# --- Chapitre 4 : habilitation -----------------------------------------
D["cadenas"] = (P("M100,140 V105 A50,50 0 0 1 200,105 V140", "none", GRIS_F, 22) + R(72, 130, 156, 120, JAUNE, 22) + C(150, 180, 16, NOIR) + R(143, 185, 14, 34, NOIR, 6) + R(84, 142, 22, 90, "#FFE070", 8))
D["testeur"] = (R(108, 50, 84, 170, ROUGE, 18) + R(122, 66, 56, 40, GRIS_C, 8) + C(136, 132, 11, VERT) + C(164, 132, 11, JAUNE) + C(136, 164, 11, ROUGE) + C(164, 164, 11, GRIS_C) +
    L(128, 220, 118, 262, NOIR, 7) + L(172, 220, 182, 262, NOIR, 7) + R(120, 192, 60, 14, ROUGE_F, 6))
D["badge"] = (R(56, 76, 188, 150, BLANC, 16, f'stroke="{GRIS}" stroke-width="6"') + R(56, 76, 188, 36, VIOLET, 14) + R(56, 96, 188, 16, VIOLET, 0) +
    C(104, 160, 24, BLEU_C) + C(104, 150, 10, "#FFD8B0") + L(144, 148, 220, 148, GRIS, 9) + L(144, 172, 200, 172, GRIS, 9) + L(144, 196, 212, 196, GRIS_C, 9) + R(130, 50, 40, 30, GRIS_F, 6))
# --- Chapitre 5 : dépanner ---------------------------------------------
D["multimetre"] = (R(88, 46, 124, 196, JAUNE, 20) + R(104, 62, 92, 50, GRIS_C, 8) + R(112, 70, 76, 34, "#DDE9C8", 4) + C(150, 160, 34, NOIR) + C(150, 160, 26, GRIS_F) + L(150, 160, 150, 138, BLANC, 6) +
    C(120, 218, 8, ROUGE) + C(180, 218, 8, NOIR) + L(120, 218, 90, 262, ROUGE, 6) + L(180, 218, 210, 262, NOIR, 6))
D["boite_outils"] = (R(48, 128, 204, 106, ROUGE, 16) + R(48, 128, 204, 30, ROUGE_F, 12) + P("M105,128 V96 A45,45 0 0 1 195,96 V128", "none", GRIS_F, 16) +
    R(128, 150, 44, 30, JAUNE, 6) + R(60, 176, 180, 12, ROUGE_F, 4))
D["cle"] = (G(R(120, 40, 60, 210, GRIS, 16) + C(150, 70, 52, GRIS) + R(132, 30, 36, 50, "#F7F7F7", 6) + C(150, 230, 30, GRIS_F), "rotate(40 150 150)"))
# --- Chapitre 6 : industrie --------------------------------------------
D["moteur"] = (R(58, 118, 150, 104, BLEU, 16) + R(96, 88, 64, 34, BLEU_F, 8) + R(208, 150, 46, 30, GRIS_F, 6) + R(70, 222, 40, 18, GRIS_F, 4) + R(156, 222, 40, 18, GRIS_F, 4) +
    L(78, 132, 78, 208, BLEU_F, 6) + L(102, 132, 102, 208, BLEU_F, 6) + L(126, 132, 126, 208, BLEU_F, 6) + L(150, 132, 150, 208, BLEU_F, 6) + L(174, 132, 174, 208, BLEU_F, 6))
def engrenage(cx, cy, r, dents, col, trou):
    pts = []
    for i in range(dents * 2):
        a = i * math.pi / dents
        rr = r if i % 2 == 0 else r * 0.78
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return poly(pts, col) + C(cx, cy, r * 0.62, col) + C(cx, cy, r * 0.28, trou)
D["engrenage"] = engrenage(150, 150, 100, 10, GRIS_F, "#F7F7F7") + engrenage(150, 150, 60, 10, "#8B8B8B", "#F7F7F7")
D["robot"] = (R(80, 80, 140, 120, BLEU_C, 24) + R(66, 120, 20, 40, BLEU, 6) + R(214, 120, 20, 40, BLEU, 6) + C(120, 135, 20, BLANC) + C(180, 135, 20, BLANC) + C(120, 135, 9, NOIR) + C(180, 135, 9, NOIR) +
    R(118, 168, 64, 14, NOIR, 7) + L(150, 80, 150, 52, GRIS_F, 6) + C(150, 44, 12, ROUGE) + R(110, 200, 80, 40, BLEU, 10))
# --- Chapitre 7 : énergies ---------------------------------------------
def pale(a): return G(E(150, 100, 14, 62, BLANC, f'stroke="{GRIS}" stroke-width="4"'), f"rotate({a} 150 150)")
D["eolienne"] = (poly([(140, 150), (160, 150), (172, 262), (128, 262)], GRIS_C) + pale(0) + pale(120) + pale(240) + C(150, 150, 16, GRIS_F) + C(150, 150, 8, BLANC))
D["panneau_solaire"] = (G(R(60, 70, 180, 130, BLEU_F, 10) + L(60, 113, 240, 113, BLANC, 4) + L(60, 157, 240, 157, BLANC, 4) + L(120, 70, 120, 200, BLANC, 4) + L(180, 70, 180, 200, BLANC, 4), "skewX(-12) translate(30 0)") +
    L(150, 200, 150, 262, GRIS_F, 12) + R(110, 250, 80, 14, GRIS_F, 6))
D["pylone"] = (L(100, 262, 140, 60, GRIS_F, 10) + L(200, 262, 160, 60, GRIS_F, 10) + L(140, 60, 160, 60, GRIS_F, 10) + L(70, 110, 230, 110, GRIS_F, 9) + L(85, 170, 215, 170, GRIS_F, 9) +
    L(110, 262, 190, 170, GRIS, 6) + L(190, 262, 110, 170, GRIS, 6) + L(120, 170, 180, 110, GRIS, 6) + L(180, 170, 120, 110, GRIS, 6) + C(70, 128, 8, BLEU) + C(230, 128, 8, BLEU))
# --- Chapitre 8 : transports -------------------------------------------
D["voiture"] = (P("M45,200 V160 Q50,140 80,138 L110,95 Q118,84 132,84 H190 Q206,84 214,96 L238,138 Q252,142 254,162 V200 Z", JAUNE) + P("M118,136 L136,100 H186 L206,136 Z", BLEU_C) +
    R(45, 178, 209, 26, JAUNE_F, 8) + C(90, 206, 26, NOIR) + C(90, 206, 11, GRIS) + C(210, 206, 26, NOIR) + C(210, 206, 11, GRIS) + R(232, 150, 18, 12, "#FFF1A6", 4) + L(60, 130, 60, 118, VERT, 8))
D["velo"] = (C(80, 200, 52, "none", f'stroke="{NOIR}" stroke-width="10"') + C(220, 200, 52, "none", f'stroke="{NOIR}" stroke-width="10"') +
    L(80, 200, 130, 120, TEAL, 10) + L(130, 120, 175, 200, TEAL, 10) + L(80, 200, 175, 200, TEAL, 10) + L(175, 200, 205, 110, TEAL, 10) + L(190, 110, 226, 110, NOIR, 10) + L(118, 118, 148, 118, NOIR, 10) + C(175, 200, 12, GRIS_F) + R(120, 150, 44, 22, VERT, 6))
D["train"] = (R(70, 60, 160, 170, ROUGE, 26) + R(84, 80, 132, 60, BLEU_C, 12) + R(70, 150, 160, 40, BLANC, 0) + C(150, 208, 16, JAUNE) + R(52, 230, 196, 14, GRIS_F, 6) +
    L(40, 262, 260, 262, GRIS_F, 8) + L(70, 250, 70, 262, GRIS_F, 8) + L(230, 250, 230, 262, GRIS_F, 8))
# --- Chapitre 9 : tertiaire --------------------------------------------
def fenetres(x0, y0, cols, rows, pas, col):
    return "".join(R(x0 + i * pas, y0 + j * pas, 20, 20, col, 4) for i in range(cols) for j in range(rows))
D["immeuble"] = (R(70, 40, 160, 220, ROSE, 14) + fenetres(92, 62, 4, 5, 34, "#FFF3FA") + R(130, 212, 40, 48, "#B2447F", 8))
D["extincteur"] = (R(108, 80, 84, 170, ROUGE, 24) + R(122, 120, 56, 70, BLANC, 8) + R(128, 132, 44, 12, ROUGE_F, 4) + R(128, 152, 44, 12, ROUGE_F, 4) + R(134, 48, 32, 40, NOIR, 8) + L(120, 60, 90, 60, NOIR, 10) +
    P("M100,70 Q60,110 80,180", "none", NOIR, 9) + R(118, 60, 64, 18, GRIS_F, 6))
D["ascenseur"] = (R(60, 40, 180, 220, GRIS_F, 12) + R(72, 52, 74, 196, GRIS_C, 6) + R(154, 52, 74, 196, GRIS_C, 6) + R(60, 40, 180, 30, NOIR, 10) +
    poly([(130, 62), (140, 48), (150, 62)], VERT) + poly([(160, 48), (170, 62), (180, 48)], ROUGE))
# --- Chapitre 10 : milieux spécialisés et métier -----------------------
D["tracteur"] = (R(70, 120, 120, 70, VERT, 14) + R(150, 80, 70, 60, VERT_F, 10) + R(160, 90, 44, 34, BLEU_C, 6) + R(60, 140, 30, 20, VERT_F, 4) + L(90, 60, 90, 120, NOIR, 10) +
    C(90, 210, 46, NOIR) + C(90, 210, 22, GRIS) + C(210, 222, 30, NOIR) + C(210, 222, 13, GRIS) + R(80, 190, 150, 14, NOIR, 6))
D["hopital"] = (R(50, 70, 200, 190, BLANC, 14, f'stroke="{GRIS}" stroke-width="6"') + R(120, 40, 60, 40, BLANC, 8, f'stroke="{GRIS}" stroke-width="6"') + R(138, 48, 24, 8, ROUGE, 2) + R(146, 40, 8, 24, ROUGE, 2) +
    R(112, 96, 76, 76, ROUGE, 10) + R(140, 108, 20, 52, BLANC, 3) + R(124, 124, 52, 20, BLANC, 3) + fenetres(66, 188, 2, 1, 40, BLEU_C) + fenetres(194, 188, 2, 1, 40, BLEU_C) + R(130, 210, 40, 50, BLEU_C, 6))
D["projecteur"] = (poly([(120, 120), (180, 120), (250, 262), (50, 262)], "rgba(255,200,0,0.28)") + R(108, 62, 84, 70, NOIR, 14) + E(150, 128, 44, 12, JAUNE) +
    L(150, 62, 150, 34, GRIS_F, 10) + L(110, 34, 190, 34, GRIS_F, 10) + R(112, 74, 20, 40, GRIS_F, 4))

for nom, corps in D.items():
    svg(nom, corps)

# --- Mascotte : la pile, quatre niveaux de charge ---------------------
def pile_mascotte(niveau):
    corps = R(126, 40, 48, 30, GRIS_F, 8) + R(72, 62, 156, 288, "#F5F5F5", 30, f'stroke="{GRIS_F}" stroke-width="10"')
    # Visage
    corps += C(118, 130, 22, BLANC, f'stroke="{NOIR}" stroke-width="5"') + C(182, 130, 22, BLANC, f'stroke="{NOIR}" stroke-width="5"')
    corps += C(124, 134, 10, NOIR) + C(188, 134, 10, NOIR)
    corps += P("M120,172 Q150,196 180,172", "none", NOIR, 7)
    corps += C(98, 160, 9, "#FFB3B3") + C(202, 160, 9, "#FFB3B3")
    # Barres de charge, de bas en haut
    couleurs = [VERT, VERT, VERT]
    for i, y in enumerate([300, 258, 216]):
        actif = i < niveau
        corps += R(94, y, 112, 32, couleurs[i] if actif else GRIS_C, 8)
    # Bras et pieds
    corps += L(72, 220, 40, 250, GRIS_F, 10) + L(228, 220, 262, 190, GRIS_F, 10)
    corps += E(112, 352, 26, 12, GRIS_F) + E(188, 352, 26, 12, GRIS_F)
    return corps

for n in range(4):
    svg(f"pile_{n}", pile_mascotte(n), 300, 400, ombre=True)
print(len(D) + 4, "dessins")
