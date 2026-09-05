"""Génère les schémas des fiches (assets/images/*.png).

Étape 1 : `python3 tools/schemas/generer_schemas.py` écrit les SVG dans ce dossier.
Étape 2 : chaque SVG est rendu en PNG 1200×750 (Chromium headless ou n'importe quel
outil SVG → PNG), puis copié dans assets/images/.
Les SVG sont la source : pour retoucher un schéma, modifier ce script, pas le PNG.
"""
import os
W, H = 1200, 750
OUT = os.path.dirname(os.path.abspath(__file__))
BLEU, AMBRE, ROUGE, VERT, GRIS, TXT, FIL = "#1565C0", "#FFB300", "#E53935", "#43A047", "#78909C", "#1F2933", "#37474F"
FONT = "DejaVu Sans, Liberation Sans, sans-serif"

def svg(nom, corps):
    doc = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="{FONT}">
<rect x="0" y="0" width="{W}" height="{H}" rx="36" fill="#F7F9FC"/>
{corps}
</svg>'''
    open(os.path.join(OUT, nom + ".svg"), "w", encoding="utf-8").write(doc)

def t(x, y, s, size=34, color=TXT, anchor="middle", weight="normal", extra=""):
    s = s.replace("&", "&amp;").replace("<", "&lt;")
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" text-anchor="{anchor}" font-weight="{weight}" {extra}>{s}</text>\n'

def titre(s): return t(W/2, 70, s, 40, BLEU, weight="bold")
def ligne(x1, y1, x2, y2, color=FIL, w=5, dash=""):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{w}" stroke-linecap="round"{d}/>\n'
def rect(x, y, w, h, fill="white", stroke=FIL, sw=5, rx=8):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>\n'
def cercle(cx, cy, r, fill="white", stroke=FIL, sw=5):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>\n'
def fleche(x1, y1, x2, y2, color=AMBRE, w=6):
    import math
    a = math.atan2(y2 - y1, x2 - x1); L = 22
    p1 = (x2 - L*math.cos(a - 0.5), y2 - L*math.sin(a - 0.5)); p2 = (x2 - L*math.cos(a + 0.5), y2 - L*math.sin(a + 0.5))
    return ligne(x1, y1, x2, y2, color, w) + f'<polygon points="{x2},{y2} {p1[0]:.1f},{p1[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}" fill="{color}"/>\n'

# --- symboles ---
def resistance(cx, cy, horizontal=True, label=""):
    s = rect(cx-50, cy-20, 100, 40) if horizontal else rect(cx-20, cy-50, 40, 100)
    if label: s += t(cx, cy - 34 if horizontal else cy + 4, label, 30, TXT, "middle" if horizontal else "start", extra=f'dx="{0 if horizontal else 34}"')
    return s
def lampe(cx, cy, r=32):
    k = r * 0.707
    return cercle(cx, cy, r) + ligne(cx-k, cy-k, cx+k, cy+k) + ligne(cx-k, cy+k, cx+k, cy-k)
def pile(cx, cy, vertical=True):
    # trait long = +, trait court = −
    if vertical:
        return ligne(cx-40, cy-12, cx+40, cy-12, w=6) + ligne(cx-18, cy+12, cx+18, cy+12, w=10) + t(cx+62, cy-8, "+", 30) + t(cx+62, cy+26, "−", 30)
    return ligne(cx-12, cy-40, cx-12, cy+40, w=6) + ligne(cx+12, cy-18, cx+12, cy+18, w=10) + t(cx-12, cy-52, "+", 30) + t(cx+12, cy-52, "−", 30)
def interrupteur(x, y, ouvert=True):
    return cercle(x, y, 6, FIL) + cercle(x+80, y, 6, FIL) + (ligne(x, y, x+72, y-34) if ouvert else ligne(x, y, x+80, y))
def terre(cx, cy):
    return ligne(cx, cy, cx, cy+30) + ligne(cx-36, cy+30, cx+36, cy+30) + ligne(cx-24, cy+44, cx+24, cy+44) + ligne(cx-12, cy+58, cx+12, cy+58)
def appareil(cx, cy, lettre):
    return cercle(cx, cy, 34) + t(cx, cy+12, lettre, 34, TXT, weight="bold")
def fusible(cx, cy):
    return rect(cx-50, cy-18, 100, 36) + ligne(cx-62, cy, cx+62, cy)

# ======================= Module 1 =======================
c = titre("Les quatre grandeurs de base")
cases = [("U", "Tension", "volt (V)", ("la « pression »", "qui pousse"), BLEU),
         ("I", "Intensité", "ampère (A)", ("le débit", "de courant"), AMBRE),
         ("R", "Résistance", "ohm (Ω)", ("ce qui freine", "le courant"), ROUGE),
         ("P", "Puissance", "watt (W)", ("l'énergie", "par seconde"), VERT)]
for i, (sym, nom, unite, desc, col) in enumerate(cases):
    x = 80 + i * 270
    c += rect(x, 130, 240, 470, "white", col, 6, 24)
    c += cercle(x+120, 230, 60, col, col) + t(x+120, 252, sym, 64, "white", weight="bold")
    c += t(x+120, 350, nom, 36, TXT, weight="bold") + t(x+120, 400, unite, 32, col, weight="bold")
    for j, mot in enumerate(desc):
        c += t(x+120, 470 + j*40, mot, 24, GRIS)
c += t(330, 690, "Loi d'Ohm : U = R × I", 34, TXT, weight="bold") + t(870, 690, "Puissance : P = U × I", 34, TXT, weight="bold")
svg("grandeurs", c)

def triangle(cx, cy, haut, bas_g, bas_d, col):
    s = f'<polygon points="{cx},{cy-190} {cx-220},{cy+150} {cx+220},{cy+150}" fill="white" stroke="{col}" stroke-width="8"/>\n'
    s += ligne(cx-130, cy+20, cx+130, cy+20, col, 8) + ligne(cx, cy+20, cx, cy+150, col, 8)
    s += t(cx, cy-40, haut, 80, col, weight="bold") + t(cx-65, cy+120, bas_g, 70, col, weight="bold") + t(cx+65, cy+120, bas_d, 70, col, weight="bold")
    return s
c = titre("La loi d'Ohm : le triangle magique")
c += triangle(340, 380, "U", "R", "I", BLEU)
c += t(340, 600, "Cache la grandeur cherchée :", 28, GRIS) + t(340, 640, "ce qui reste donne la formule", 28, GRIS)
for i, (f, ex) in enumerate([("U = R × I", "10 Ω × 2 A = 20 V"), ("I = U / R", "12 V / 4 Ω = 3 A"), ("R = U / I", "230 V / 0,5 A = 460 Ω")]):
    y = 190 + i * 150
    c += rect(660, y, 480, 110, "white", BLEU, 4, 18) + t(900, y+48, f, 40, BLEU, weight="bold") + t(900, y+90, ex, 28, GRIS)
svg("ohm", c)

c = titre("La puissance électrique")
c += triangle(340, 380, "P", "U", "I", VERT)
c += t(340, 600, "P = U × I", 44, VERT, weight="bold")
for i, (f, ex) in enumerate([("P = U × I", "230 V × 10 A = 2 300 W"), ("I = P / U", "1 150 W / 230 V = 5 A"), ("1 kW = 1 000 W", "2 300 W = 2,3 kW")]):
    y = 190 + i * 150
    c += rect(660, y, 480, 110, "white", VERT, 4, 18) + t(900, y+48, f, 40, VERT, weight="bold") + t(900, y+90, ex, 28, GRIS)
svg("puissance", c)

# ======================= Module 2 =======================
def axes(x0, y0, w, h, ylab, xlab):
    s = ligne(x0, y0, x0, y0-h, GRIS, 4) + ligne(x0, y0, x0+w, y0, GRIS, 4)
    s += t(x0-16, y0-h+10, ylab, 28, GRIS, "end") + t(x0+w, y0+40, xlab, 28, GRIS, "end")
    return s
c = titre("Courant continu (DC) : toujours le même sens")
c += axes(120, 520, 620, 360, "U", "temps")
c += ligne(120, 300, 740, 300, BLEU, 8) + t(430, 270, "tension constante", 28, BLEU)
c += ligne(120, 340, 740, 340, GRIS, 3, "12 12") + t(100, 350, "0", 26, GRIS, "end")
c += pile(980, 320) + t(980, 420, "pile, batterie,", 28, GRIS) + t(980, 456, "panneau solaire", 28, GRIS)
c += t(980, 190, "⎓  DC", 44, BLEU, weight="bold")
c += t(W/2, 650, "Une borne +, une borne − : le courant circule toujours dans le même sens.", 28, TXT)
svg("continu", c)

import math
c = titre("Courant alternatif (AC) : des allers-retours")
x0, y0, w, h = 120, 400, 740, 260
c += ligne(x0, y0, x0+w, y0, GRIS, 4) + ligne(x0, y0+180, x0, y0-180, GRIS, 4)
pts = " ".join(f"{x0 + i*w/400:.1f},{y0 - 150*math.sin(i/400*4*math.pi):.1f}" for i in range(401))
c += f'<polyline points="{pts}" fill="none" stroke="{BLEU}" stroke-width="8" stroke-linejoin="round"/>\n'
c += ligne(x0, y0-150, x0+w/2, y0-150, GRIS, 3, "10 10") + t(x0-16, y0-140, "+325 V", 24, GRIS, "end") + t(x0-16, y0+170, "−325 V", 24, GRIS, "end")
c += fleche(x0+10, y0+215, x0+w/2-10, y0+215, AMBRE, 5) + fleche(x0+w/2-10, y0+215, x0+10, y0+215, AMBRE, 5)
c += t(x0+w/4, y0+255, "1 période T = 20 ms", 30, AMBRE, weight="bold")
c += t(1030, 200, "~  AC", 44, BLEU, weight="bold") + t(1030, 260, "230 V", 34, TXT, weight="bold") + t(1030, 305, "(valeur efficace)", 22, GRIS)
c += t(1030, 370, "50 Hz", 34, TXT, weight="bold") + t(1030, 410, "50 cycles / seconde", 22, GRIS)
c += t(W/2, 700, "Phase (L) et neutre (N) : le courant change de sens 100 fois par seconde.", 26, TXT)
svg("alternatif", c)

c = titre("Passer de l'un à l'autre")
def boite(x, y, w, h, texte, col):
    return rect(x, y, w, h, "white", col, 6, 20) + t(x+w/2, y+h/2+12, texte, 34, col, weight="bold")
c += t(180, 235, "~ AC", 44, BLEU, weight="bold") + t(180, 275, "réseau 230 V", 24, GRIS)
c += fleche(280, 220, 400, 220, GRIS) + boite(410, 160, 340, 120, "Redresseur", AMBRE) + fleche(760, 220, 880, 220, GRIS)
c += t(1000, 235, "⎓ DC", 44, BLEU, weight="bold") + t(1000, 275, "chargeur, PC, LED", 24, GRIS)
c += t(180, 445, "⎓ DC", 44, BLEU, weight="bold") + t(180, 485, "batterie, solaire", 24, GRIS)
c += fleche(280, 430, 400, 430, GRIS) + boite(410, 370, 340, 120, "Onduleur", VERT) + fleche(760, 430, 880, 430, GRIS)
c += t(1000, 445, "~ AC", 44, BLEU, weight="bold") + t(1000, 485, "réseau, maison", 24, GRIS)
c += rect(120, 560, 960, 130, "white", BLEU, 4, 20) + t(W/2, 610, "Triphasé : 3 phases décalées", 32, BLEU, weight="bold")
c += t(380, 660, "phase ↔ neutre : 230 V", 30, TXT) + t(820, 660, "phase ↔ phase : 400 V", 30, TXT)
svg("conversion", c)

# ======================= Module 3 =======================
c = titre("Montage en série : un seul chemin")
c += pile(200, 400) + ligne(200, 388, 200, 200) + ligne(200, 200, 1000, 200) + ligne(1000, 200, 1000, 600) + ligne(1000, 600, 200, 600) + ligne(200, 600, 200, 412)
c += rect(450, 180, 100, 40) + t(500, 160, "R1", 30) + rect(700, 180, 100, 40) + t(750, 160, "R2", 30)
c += fleche(300, 240, 400, 240) + t(350, 285, "I", 34, AMBRE, weight="bold") + fleche(850, 240, 950, 240) + t(900, 285, "I", 34, AMBRE, weight="bold")
c += t(500, 260, "U1", 30, BLEU, weight="bold") + t(750, 260, "U2", 30, BLEU, weight="bold")
c += t(140, 420, "U", 34, BLEU, weight="bold")
for i, s in enumerate(["Même intensité I partout", "U = U1 + U2", "R = R1 + R2", "Un élément coupé → tout s'arrête"]):
    c += t(600, 360 + i*55, s, 32, TXT if i else AMBRE, weight="bold" if i in (0,) else "normal")
c += t(W/2, 690, "Exemple : 10 Ω + 20 Ω en série = 30 Ω", 30, GRIS)
svg("serie", c)

c = titre("Montage en parallèle : plusieurs branches")
c += pile(200, 400) + ligne(200, 388, 200, 180) + ligne(200, 180, 1000, 180) + ligne(200, 620, 200, 412) + ligne(200, 620, 1000, 620)
for x, lab, il in [(600, "R1", "I1"), (1000, "R2", "I2")]:
    c += ligne(x, 180, x, 620) + rect(x-20, 350, 40, 100) + t(x+40, 408, lab, 30, TXT, "start")
    c += fleche(x, 230, x, 320) + t(x-30, 285, il, 32, AMBRE, "end", "bold")
c += fleche(280, 180, 500, 180) + t(390, 160, "I = I1 + I2", 32, AMBRE, weight="bold")
c += t(140, 420, "U", 34, BLEU, weight="bold")
c += t(800, 300, "même U", 30, BLEU) + t(800, 520, "1/R = 1/R1 + 1/R2", 30, TXT)
c += t(W/2, 672, "Deux résistances de 20 Ω en parallèle = 10 Ω.", 26, GRIS) + t(W/2, 708, "Une branche en panne : les autres continuent.", 26, GRIS)
svg("parallele", c)

c = titre("Série ou parallèle : ce qu'il faut retenir")
cols = [("Série", BLEU, ["Un seul chemin", "Même I partout", "Les U s'ajoutent", "R = R1 + R2", "Un élément coupé : tout s'arrête", "Ex. : interrupteur + lampe"]),
        ("Parallèle", VERT, ["Plusieurs branches", "Même U partout", "Les I s'ajoutent", "1/R = 1/R1 + 1/R2", "Une panne : les autres continuent", "Ex. : prises de la maison"])]
for i, (nom, col, lignes) in enumerate(cols):
    x = 80 + i * 540
    c += rect(x, 120, 500, 570, "white", col, 6, 24) + rect(x, 120, 500, 90, col, col, 6, 24) + t(x+250, 180, nom, 40, "white", weight="bold")
    for j, l in enumerate(lignes):
        c += t(x+250, 270 + j*78, l, 30 if j < 4 else (26 if j == 4 else 24), TXT if j < 5 else GRIS, weight="bold" if j in (1, 2) else "normal")
svg("recap_circuits", c)

# ======================= Module 4 =======================
c = titre("Les symboles de base (norme européenne)")
items = [("Résistance", lambda x, y: resistance(x, y)), ("Lampe", lambda x, y: lampe(x, y)), ("Interrupteur", lambda x, y: interrupteur(x-40, y+10)),
         ("Pile / batterie", lambda x, y: pile(x, y, False)), ("Fusible", lambda x, y: fusible(x, y)), ("Terre", lambda x, y: terre(x, y-30)),
         ("Voltmètre", lambda x, y: appareil(x, y, "V")), ("Ampèremètre", lambda x, y: appareil(x, y, "A"))]
for i, (nom, draw) in enumerate(items):
    col, row = i % 4, i // 4
    x, y = 80 + col * 270, 120 + row * 290
    c += rect(x, y, 240, 250, "white", "#CFD8DC", 4, 20) + ligne(x+40, y+110, x+200, y+110, FIL, 5) + draw(x+120, y+110) + t(x+120, y+215, nom, 26, TXT, weight="bold")
svg("symboles", c)

c = titre("Le code couleur des conducteurs")
fils = [("Phase (L)", ["#C62828", "#6D4C41", "#212121"], "rouge, marron ou noir", "amène le courant"),
        ("Neutre (N)", ["#42A5F5"], "bleu clair", "retour du courant"),
        ("Terre (PE)", ["#43A047", "#FDD835"], "vert et jaune", "sécurité : jamais autre chose")]
for i, (nom, couleurs, desc, role) in enumerate(fils):
    y = 170 + i * 170
    c += t(80, y+16, nom, 34, TXT, "start", "bold")
    n = len(couleurs)
    for k, col in enumerate(couleurs):
        if nom.startswith("Terre"):
            c += f'<rect x="360" y="{y-22}" width="420" height="44" rx="22" fill="{couleurs[0]}"/>\n'
            for s in range(0, 420, 84): c += f'<rect x="{360+s+42}" y="{y-22}" width="42" height="44" fill="{couleurs[1]}"/>\n'
            c += f'<rect x="360" y="{y-22}" width="420" height="44" rx="22" fill="none" stroke="#37474F" stroke-width="3"/>\n'
            break
        c += f'<rect x="{360 + k*(420/n)}" y="{y-22}" width="{420/n-8}" height="44" rx="22" fill="{col}"/>\n'
    c += t(830, y-4, desc, 26, TXT, "start", "bold") + t(830, y+34, role, 24, GRIS, "start")
c += rect(80, 626, 1040, 96, "#FFF8E1", AMBRE, 4, 16) + t(W/2, 666, "Ancienne installation ? Les couleurs ne sont pas toujours fiables.", 24, TXT, weight="bold") + t(W/2, 702, "On vérifie toujours avec un appareil de mesure.", 24, TXT)
svg("couleurs", c)

c = titre("Lire un schéma : simple allumage et mesures")
# circuit : L en haut, interrupteur, lampe, N en bas
c += t(90, 210, "L", 36, ROUGE, weight="bold") + t(90, 560, "N", 36, "#1E88E5", weight="bold")
c += ligne(130, 200, 420, 200, ROUGE) + interrupteur(420, 200) + ligne(500, 200, 760, 200, ROUGE) + ligne(760, 200, 760, 340)
c += lampe(760, 375) + ligne(760, 410, 760, 550) + ligne(760, 550, 130, 550, "#1E88E5")
c += t(460, 150, "interrupteur", 26, GRIS) + t(710, 385, "lampe", 26, GRIS, "end")
# voltmètre en parallèle sur la lampe
c += ligne(760, 340, 960, 340, GRIS, 4, "10 8") + ligne(760, 410, 960, 410, GRIS, 4, "10 8") + ligne(960, 340, 960, 410, GRIS, 4, "10 8") + appareil(960, 375, "V")
c += t(1010, 385, "en parallèle", 24, GRIS, "start")
# ampèremètre en série
c += appareil(300, 550, "A") + t(300, 620, "en série", 24, GRIS)
c += rect(80, 640, 1040, 84, "white", BLEU, 4, 16) + t(W/2, 674, "L = phase  ·  N = neutre  ·  PE = terre", 26, TXT, weight="bold") + t(W/2, 710, "Voltmètre en parallèle, ampèremètre en série", 24, GRIS)
svg("schemas", c)

# ======================= Module 5 =======================
c = titre("Effets du courant sur le corps (alternatif 50 Hz)")
x0, x1, y = 120, 1080, 330
c += f'<defs><linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="{VERT}"/><stop offset="0.35" stop-color="{AMBRE}"/><stop offset="1" stop-color="{ROUGE}"/></linearGradient></defs>\n'
c += f'<rect x="{x0}" y="{y-24}" width="{x1-x0}" height="48" rx="24" fill="url(#g)"/>\n'
seuils = [(0.08, "0,5 mA", "picotement", "seuil de perception"), (0.36, "10 mA", "non-lâcher", "les muscles se contractent"),
          (0.64, "30 mA", "paralysie respiratoire", "seuil du différentiel"), (0.92, "> 50 mA", "fibrillation", "arrêt du cœur possible")]
for i, (p, val, nom, desc) in enumerate(seuils):
    x = x0 + p * (x1 - x0)
    c += ligne(x, y-40, x, y+40, FIL, 4) + t(x, y-60, val, 30, TXT, weight="bold")
    c += t(x, y+90, nom, 26, TXT, weight="bold") + t(x, y+124, desc, 22, GRIS)
c += t(x0, y+190 - 20, "", 1)
c += rect(80, 500, 1040, 200, "white", ROUGE, 4, 20)
c += t(W/2, 550, "Ce qui blesse : l'intensité qui traverse le corps et la durée du contact", 26, TXT, weight="bold")
c += t(W/2, 600, "Aggravant : humidité, pieds nus, trajet par le cœur", 26, TXT)
c += t(W/2, 660, "Tension limite de sécurité : 50 V en local sec, 25 V en local humide", 26, ROUGE, weight="bold")
svg("seuils", c)

def bonhomme(x, y, col=TXT):
    return cercle(x, y, 28, "white", col, 5) + ligne(x, y+28, x, y+130, col, 6) + ligne(x, y+60, x-60, y+30, col, 6) + ligne(x, y+60, x+60, y+30, col, 6) + ligne(x, y+130, x-40, y+210, col, 6) + ligne(x, y+130, x+40, y+210, col, 6)
def eclair(x, y, s=1.0, col=AMBRE):
    pts = [(0,0),(-28,44),(-9,44),(-15,78),(15,32),(-4,32)]
    return '<polygon points="' + " ".join(f"{x+px*s:.0f},{y+py*s:.0f}" for px, py in pts) + f'" fill="{col}" stroke="#FB8C00" stroke-width="2"/>\n'
c = titre("Contact direct et contact indirect")
# direct : main sur fil dénudé
c += rect(70, 120, 520, 580, "white", ROUGE, 5, 24) + t(330, 175, "Contact DIRECT", 34, ROUGE, weight="bold")
c += bonhomme(200, 300) + ligne(260, 330, 480, 330, "#212121", 10) + ligne(300, 330, 380, 330, "#B0BEC5", 10) + eclair(285, 300)
c += t(330, 590, "Toucher une partie normalement", 24, TXT) + t(330, 624, "sous tension : fil dénudé, borne…", 24, TXT)
c += t(330, 670, "Protection : isolation, capots, éloignement", 22, GRIS)
# indirect : main sur carcasse
c += rect(610, 120, 520, 580, "white", AMBRE, 5, 24) + t(870, 175, "Contact INDIRECT", 34, "#F57F17", weight="bold")
c += bonhomme(720, 300) + rect(820, 260, 200, 230, "#ECEFF1", FIL, 5, 12) + cercle(920, 375, 60, "white", FIL, 5) + cercle(920, 375, 40, "#B3E5FC", FIL, 3)
c += ligne(1020, 300, 1090, 300, "#212121", 8) + ligne(1060, 300, 1060, 260, ROUGE, 6) + t(1075, 250, "défaut", 20, ROUGE, "start") + eclair(800, 300, 0.8)
c += t(870, 590, "Toucher une masse métallique mise", 24, TXT) + t(870, 624, "sous tension par un défaut d'isolement", 24, TXT)
c += t(870, 670, "Protection : terre + différentiel 30 mA", 22, GRIS)
svg("contacts", c)

c = titre("Tableau électrique : qui protège quoi ?")
def module_tab(x, y, w, h, l1, l2, col):
    return rect(x, y, w, h, "white", col, 6, 16) + t(x+w/2, y+h/2-4, l1, 26, col, weight="bold") + t(x+w/2, y+h/2+30, l2, 20, GRIS)
c += module_tab(60, 130, 340, 100, "Disjoncteur général", "coupe tout", FIL)
c += fleche(230, 230, 230, 290, GRIS)
c += module_tab(60, 300, 340, 110, "Différentiel 30 mA", "protège les personnes", VERT)
c += fleche(400, 355, 470, 355, GRIS)
for i, (nom, cal) in enumerate([("Disjoncteur 16 A", "prises"), ("Disjoncteur 10 A", "éclairage"), ("Disjoncteur 20 A", "lave-linge")]):
    y = 160 + i * 130
    c += ligne(470, 355, 470, y+50, GRIS, 4) + fleche(470, y+50, 510, y+50, GRIS)
    c += module_tab(520, y, 340, 100, nom, "protège les câbles : " + cal, BLEU)
c += terre(1000, 300) + t(1000, 250, "Terre (PE)", 28, VERT, weight="bold") + t(1000, 400, "relie les masses", 22, GRIS) + t(1000, 430, "métalliques au sol", 22, GRIS)
c += rect(80, 560, 1040, 140, "white", ROUGE, 4, 20)
c += t(W/2, 610, "Disjoncteur : surcharge et court-circuit → protège l'installation (incendie)", 26, TXT)
c += t(W/2, 660, "Différentiel : fuite de 30 mA vers la terre → protège les personnes", 26, TXT)
svg("protections", c)
print("ok", len(os.listdir(OUT)))
