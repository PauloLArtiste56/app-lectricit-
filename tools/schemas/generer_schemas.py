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

# ======================= Module 6 : mesures =======================
c = titre("Le multimètre")
# corps de l'appareil
c += rect(120, 120, 420, 560, "white", FIL, 6, 28)
c += rect(160, 150, 340, 110, "#E3F2FD", BLEU, 4, 12) + t(330, 220, "230.4", 56, TXT, weight="bold", extra='font-family="DejaVu Sans Mono"')
c += cercle(330, 430, 90, "#ECEFF1", FIL, 5) + ligne(330, 430, 330, 355, ROUGE, 8)
for ang, lab in [(-135, "V~"), (-90, "V⎓"), (-45, "Ω"), (45, "A"), (135, "OFF"), (90, "•)))")]:
    import math as _m
    x = 330 + 125*_m.cos(_m.radians(ang)); y = 430 + 125*_m.sin(_m.radians(ang))
    c += t(x, y+10, lab, 26, TXT, weight="bold")
for x, lab, col in [(220, "A", ROUGE), (330, "COM", "#212121"), (440, "V/Ω", ROUGE)]:
    c += cercle(x, 620, 20, "white", col, 6) + t(x, 662, lab, 22, TXT)
# légende
items = [("V~", "tension alternative (prise)", BLEU), ("V⎓", "tension continue (pile)", BLEU), ("Ω", "résistance, hors tension", ROUGE),
         ("A", "intensité, en série", AMBRE), ("COM", "cordon noir, référence", TXT), ("V/Ω", "cordon rouge (V et Ω)", ROUGE)]
for i, (k, d, col) in enumerate(items):
    y = 160 + i * 80
    c += t(620, y, k, 32, col, "start", "bold") + t(740, y, d, 26, TXT, "start")
c += rect(600, 620, 520, 70, "#FFF8E1", AMBRE, 4, 16) + t(860, 664, "Valeur inconnue ? Calibre le plus grand d'abord.", 24, TXT)
svg("multimetre", c)

c = titre("Tension en parallèle, intensité en série")
# circuit gauche : voltmètre
c += pile(180, 400) + ligne(180, 388, 180, 220) + ligne(180, 220, 480, 220) + ligne(480, 220, 480, 340) + lampe(480, 375) + ligne(480, 410, 480, 580) + ligne(480, 580, 180, 580) + ligne(180, 580, 180, 412)
c += ligne(480, 340, 330, 340, GRIS, 4, "10 8") + ligne(480, 410, 330, 410, GRIS, 4, "10 8") + ligne(330, 340, 330, 410, GRIS, 4, "10 8") + appareil(330, 375, "V")
c += t(330, 470, "en parallèle", 26, BLEU, weight="bold") + t(330, 505, "sur les deux bornes", 22, GRIS)
# circuit droit : ampèremètre + pince
c += pile(700, 400) + ligne(700, 388, 700, 220) + ligne(700, 220, 1000, 220) + ligne(1000, 220, 1000, 340) + lampe(1000, 375) + ligne(1000, 410, 1000, 580) + ligne(1000, 580, 700, 580) + ligne(700, 580, 700, 412)
c += appareil(850, 220, "A") + t(850, 165, "en série", 26, AMBRE, weight="bold")
c += cercle(850, 580, 42, "none", VERT, 8) + t(850, 650, "pince : un seul conducteur", 22, VERT, weight="bold")
c += t(W/2, 710, "Résistance et continuité : toujours hors tension, composant isolé.", 24, ROUGE, weight="bold")
svg("mesurer", c)

c = titre("Le VAT : tester, vérifier, retester")
etapes = [("1", "Tester le VAT", "sur une source, sous tension connue", VERT), ("2", "Vérifier l'ouvrage", "phase-neutre, phase-phase, chaque conducteur-terre", BLEU), ("3", "Retester le VAT", "sur la même, source connue", VERT)]
for i, (n, l1, l2, col) in enumerate(etapes):
    x = 80 + i * 360
    c += rect(x, 150, 320, 300, "white", col, 6, 24) + cercle(x+160, 220, 40, col, col) + t(x+160, 236, n, 40, "white", weight="bold")
    c += t(x+160, 310, l1, 30, TXT, weight="bold")
    mots = l2.split(", ")
    for j, m in enumerate(mots): c += t(x+160, 355 + j*32, m, 22, GRIS)
    if i < 2: c += fleche(x+330, 300, x+350, 300, GRIS)
c += rect(80, 500, 1040, 190, "white", ROUGE, 4, 20)
c += t(W/2, 550, "Pourquoi retester ? Un VAT en panne afficherait « pas de tension » à tort.", 26, TXT)
c += t(W/2, 600, "Un multimètre ne remplace pas un VAT (calibre, pile, cordon…).", 26, TXT)
c += t(W/2, 655, "Obligatoire avant tout travail hors tension (NF C 18-510)", 28, ROUGE, weight="bold")
svg("vat", c)

# ======================= Module 7 : installation =======================
c = titre("Le tableau électrique, de haut en bas")
rangs = [("Disjoncteur de branchement", "coupe tout, limite la puissance souscrite", FIL, 1),
         ("Interrupteurs différentiels 30 mA", "protègent les personnes (type A : plaque, lave-linge)", VERT, 2),
         ("Disjoncteurs divisionnaires", "un par circuit, calibrés selon le câble", BLEU, 6),
         ("Bornier de terre", "tous les fils vert/jaune → prise de terre", "#43A047", 1)]
y = 120
for nom, desc, col, n in rangs:
    c += rect(80, y, 1040, 120, "white", col, 5, 18)
    for k in range(n):
        w = 60 if n > 1 else 120
        c += rect(110 + k*(w+10), y+20, w, 80, "#ECEFF1", col, 3, 8) + rect(120 + k*(w+10), y+40, w-20, 16, col, col, 1, 3)
    c += t(560, y+50, nom, 28, col, "start", "bold") + t(560, y+90, desc, 22, GRIS, "start")
    y += 140
svg("tableau", c)

c = titre("Sections de câbles et calibres (NF C 15-100)")
lignes = [("Éclairage", 1.5, "16 A", "8 points max", BLEU), ("Prises", 2.5, "20 A", "12 prises max", VERT),
          ("Spécialisé (lave-linge, four)", 2.5, "20 A", "1 prise par circuit", AMBRE), ("Plaque de cuisson", 6, "32 A", "circuit dédié", ROUGE)]
c += t(90, 150, "Usage", 24, GRIS, "start", "bold") + t(560, 150, "Section", 24, GRIS, "middle", "bold") + t(760, 150, "Disjoncteur", 24, GRIS, "middle", "bold") + t(960, 150, "Limite", 24, GRIS, "middle", "bold")
for i, (usage, sec, cal, lim, col) in enumerate(lignes):
    y = 210 + i * 110
    c += rect(80, y-40, 1040, 90, "white", "#CFD8DC", 3, 14)
    c += t(90, y+10, usage, 26, TXT, "start", "bold")
    r = 6 + sec * 4
    c += cercle(520, y, r, col, col) + t(560, y+10, f"{sec} mm²".replace(".", ","), 26, col, "start", "bold")
    c += t(760, y+10, cal, 28, TXT, weight="bold") + t(960, y+10, lim, 24, GRIS)
c += rect(80, 650, 1040, 70, "#FFEBEE", ROUGE, 4, 16) + t(W/2, 694, "Le disjoncteur protège le câble : trop gros pour le câble, c'est un risque d'incendie.", 24, TXT)
svg("sections", c)

c = titre("Salle de bains : les volumes")
# baignoire vue de côté
c += rect(120, 470, 420, 140, "#B3E5FC", BLEU, 5, 20) + t(330, 550, "Volume 0", 28, BLEU, weight="bold") + t(330, 585, "rien", 22, GRIS)
c += rect(120, 150, 420, 320, "#E3F2FD", BLEU, 3, 0) + t(330, 200, "Volume 1", 28, BLEU, weight="bold") + t(330, 240, "TBTS 12 V seulement", 22, GRIS) + t(330, 270, "jusqu'à 2,25 m", 22, GRIS)
c += rect(540, 150, 200, 460, "#F1F8E9", VERT, 3, 0) + t(640, 200, "Volume 2", 28, VERT, weight="bold") + t(640, 240, "IPX4", 22, GRIS) + t(640, 270, "classe II", 22, GRIS) + t(640, 300, "60 cm", 22, GRIS)
c += t(900, 200, "Hors volumes", 28, TXT, weight="bold") + t(900, 240, "prises et appareils", 22, GRIS) + t(900, 270, "classiques", 22, GRIS)
c += rect(860, 330, 80, 80, "white", FIL, 4, 10) + cercle(885, 370, 6, FIL) + cercle(915, 370, 6, FIL) + t(900, 440, "prise 230 V", 20, GRIS)
c += ligne(120, 610, 1120, 610, FIL, 6)
c += rect(80, 640, 1040, 80, "white", BLEU, 4, 16) + t(W/2, 672, "IP X4 : 1er chiffre = solides, 2e chiffre = eau (4 = projections)", 24, TXT) + t(W/2, 704, "Liaison équipotentielle : toutes les masses métalliques reliées à la terre", 22, GRIS)
svg("salle_de_bain", c)

# ======================= Module 8 : énergie =======================
c = titre("Puissance et énergie : E = P × t")
c += rect(80, 130, 480, 260, "white", BLEU, 6, 24) + t(320, 190, "Puissance P", 32, BLEU, weight="bold") + t(320, 240, "en watts (W)", 26, GRIS)
c += t(320, 300, "ce que l'appareil consomme", 24, TXT) + t(320, 335, "à un instant donné", 24, TXT)
c += rect(640, 130, 480, 260, "white", VERT, 6, 24) + t(880, 190, "Énergie E", 32, VERT, weight="bold") + t(880, 240, "en kilowattheures (kWh)", 26, GRIS)
c += t(880, 300, "puissance × durée", 24, TXT) + t(880, 335, "ce que mesure le compteur", 24, TXT)
c += rect(80, 430, 1040, 260, "white", AMBRE, 6, 24) + t(W/2, 490, "Exemple", 26, GRIS)
c += t(W/2, 545, "Radiateur 2 000 W pendant 3 heures", 30, TXT, weight="bold")
c += t(W/2, 600, "E = 2 kW × 3 h = 6 kWh", 40, AMBRE, weight="bold")
c += t(W/2, 655, "1 kWh = un appareil de 1 000 W pendant 1 heure", 24, GRIS)
svg("energie", c)

c = titre("Ordres de grandeur de puissance")
apps = [("LED", 10, BLEU), ("Télévision", 100, BLEU), ("Réfrigérateur", 150, BLEU), ("Four", 2500, AMBRE), ("Plaque induction", 7000, ROUGE)]
maxw = 7000
for i, (nom, p, col) in enumerate(apps):
    y = 150 + i * 90
    w = max(12, 760 * p / maxw)
    c += t(250, y+10, nom, 22, TXT, "end", "bold") + f'<rect x="270" y="{y-22}" width="{w:.0f}" height="44" rx="12" fill="{col}"/>\n' + t(280 + w, y+10, f"{p:,} W".replace(",", " "), 24, TXT, "start")
c += rect(80, 610, 1040, 100, "white", BLEU, 4, 20) + t(W/2, 650, "Puissance souscrite (6, 9, 12 kVA) = maximum utilisable en même temps", 24, TXT, weight="bold") + t(W/2, 688, "Dépassement → le disjoncteur de branchement coupe", 24, GRIS)
svg("facture", c)

c = titre("Où part l'électricité d'un logement tout électrique ?")
parts = [("Chauffage", 0.55, ROUGE), ("Eau chaude", 0.15, AMBRE), ("Cuisson", 0.08, "#FB8C00"), ("Froid, lavage", 0.12, BLEU), ("Éclairage, TV, veilles", 0.10, VERT)]
import math as _m
cx, cy, r = 330, 400, 200
ang = -90
for nom, p, col in parts:
    a0 = _m.radians(ang); a1 = _m.radians(ang + 360*p)
    x0, y0 = cx + r*_m.cos(a0), cy + r*_m.sin(a0); x1, y1 = cx + r*_m.cos(a1), cy + r*_m.sin(a1)
    grand = 1 if p > 0.5 else 0
    c += f'<path d="M{cx},{cy} L{x0:.1f},{y0:.1f} A{r},{r} 0 {grand} 1 {x1:.1f},{y1:.1f} Z" fill="{col}" stroke="white" stroke-width="4"/>\n'
    ang += 360*p
for i, (nom, p, col) in enumerate(parts):
    y = 200 + i * 70
    c += f'<rect x="620" y="{y-20}" width="36" height="36" rx="8" fill="{col}"/>\n' + t(680, y+8, f"{nom} ~ {int(p*100)} %", 26, TXT, "start")
c += rect(80, 620, 1040, 100, "white", VERT, 4, 20) + t(W/2, 660, "Rendement = énergie utile / énergie consommée", 26, TXT, weight="bold") + t(W/2, 698, "Veilles : peu de watts, mais 24 h/24. Heures creuses : moins cher la nuit.", 22, GRIS)
svg("economies", c)

# ======================= Module 9 : habilitation =======================
c = titre("L'habilitation électrique : le parcours")
etapes = [("Formation", "théorie + pratique", BLEU), ("Évaluation", "des connaissances", BLEU), ("Aptitude", "visite médicale", VERT), ("Titre", "par l'employeur", AMBRE)]
for i, (l1, l2, col) in enumerate(etapes):
    x = 80 + i * 270
    c += rect(x, 170, 230, 200, "white", col, 6, 24) + cercle(x+115, 230, 34, col, col) + t(x+115, 244, str(i+1), 34, "white", weight="bold")
    c += t(x+115, 305, l1, 28, TXT, weight="bold") + t(x+115, 340, l2, 22, GRIS)
    if i < 3: c += fleche(x+235, 270, x+265, 270, GRIS)
c += rect(80, 430, 1040, 260, "white", ROUGE, 4, 24)
c += t(W/2, 480, "Ce n'est pas un diplôme", 28, ROUGE, weight="bold")
c += t(W/2, 530, "C'est la reconnaissance, par l'employeur, de la capacité à accomplir", 24, TXT)
c += t(W/2, 565, "en sécurité les tâches confiées (norme NF C 18-510).", 24, TXT)
c += t(W/2, 620, "Liée à un poste et à des tâches précises", 24, GRIS) + t(W/2, 660, "Recyclage recommandé tous les 3 ans", 24, GRIS)
svg("habilitation", c)

c = titre("Lire un symbole d'habilitation")
c += t(330, 230, "B", 150, BLEU, weight="bold") + t(520, 230, "1", 150, AMBRE, weight="bold") + t(700, 230, "V", 150, VERT, weight="bold")
c += rect(80, 290, 320, 400, "white", BLEU, 5, 20) + t(240, 335, "Domaine de tension", 24, BLEU, weight="bold")
c += t(240, 390, "B = basse tension", 24, TXT) + t(240, 420, "(≤ 1 000 V alternatif)", 20, GRIS) + t(240, 470, "H = haute tension", 24, TXT)
c += rect(430, 290, 420, 400, "white", AMBRE, 5, 20) + t(640, 335, "Rôle", 24, "#F57F17", weight="bold")
roles = ["0 : non-électricien", "1 : exécutant électricien", "2 : chargé de travaux", "R : intervention générale", "S : intervention élémentaire", "C : chargé de consignation", "E : essai, mesure, manœuvre"]
for i, rl in enumerate(roles): c += t(450, 385 + i*42, rl, 22, TXT, "start")
c += rect(880, 290, 240, 400, "white", VERT, 5, 20) + t(1000, 335, "Option", 24, VERT, weight="bold")
c += t(1000, 400, "V = voisinage", 24, TXT) + t(1000, 435, "de pièces nues", 20, GRIS) + t(1000, 462, "sous tension", 20, GRIS)
c += t(1000, 560, "Exemples :", 22, GRIS) + t(1000, 600, "B0 · BS · BR", 24, TXT, weight="bold") + t(1000, 640, "B1V · B2V · BC", 24, TXT, weight="bold")
svg("symboles_hab", c)

c = titre("La consignation : S-C-I-V")
etapes = [("S", "Séparation", "ouvrir l'appareil", "de coupure", BLEU),
          ("C", "Condamnation", "cadenas + pancarte", "remise impossible", ROUGE),
          ("I", "Identification", "être sûr d'être", "sur le bon ouvrage", AMBRE),
          ("V", "VAT", "absence de tension", "VAT testé avant / après", VERT)]
for i, (l, nom, d1, d2, col) in enumerate(etapes):
    x = 80 + i * 270
    c += rect(x, 130, 230, 330, "white", col, 6, 24) + rect(x, 130, 230, 90, col, col, 6, 24) + t(x+115, 195, l, 56, "white", weight="bold")
    c += t(x+115, 275, nom, 26, TXT, weight="bold") + t(x+115, 330, d1, 19, GRIS) + t(x+115, 360, d2, 19, GRIS)
    if i < 3: c += fleche(x+232, 295, x+268, 295, GRIS)
c += rect(80, 500, 1040, 200, "white", FIL, 4, 24)
c += t(W/2, 550, "En haute tension, ou s'il y a un risque de réalimentation :", 24, TXT) + t(W/2, 585, "+ mise à la terre et en court-circuit", 26, TXT, weight="bold")
c += t(W/2, 640, "Déconsignation : dans l'ordre inverse", 24, GRIS) + t(W/2, 675, "EPI : gants isolants, écran facial, tapis et outils isolés", 22, GRIS)
svg("consignation", c)

# ======================= Gabarit "fiche résumé" =======================
# Pour illustrer une fiche sans dessin spécifique : titre, pictogramme
# (initiales), 3 à 4 points clés.
def carte_resume(nom, titre_s, initiales, points, col):
    c = titre(titre_s)
    taille = 72 if len(initiales) <= 2 else (56 if len(initiales) <= 3 else 40)
    c += cercle(190, 330, 110, col, col) + t(190, 330 + taille * 0.36, initiales, taille, "white", weight="bold")
    y0 = 200 if len(points) > 3 else 240
    for i, (gras, detail) in enumerate(points):
        y = y0 + i * 115
        c += cercle(380, y - 8, 12, col, col)
        c += t(420, y, gras, 30, TXT, "start", "bold")
        c += t(420, y + 40, detail, 24, GRIS, "start")
    svg(nom, c)

RESUMES = [
 ("principe_moteur", "Le moteur électrique", "M", [("Électrique → mécanique", "un courant dans un champ magnétique subit une force"), ("Stator fixe, rotor tournant", "l'arbre de sortie est sur le rotor"), ("Asynchrone triphasé", "le plus répandu : robuste, sans balais"), ("Plaque signalétique", "tension, courant, puissance, tr/min, cos φ")], BLEU),
 ("demarrage", "Démarrer et protéger un moteur", "5×", [("Courant de démarrage", "5 à 8 × le courant nominal"), ("Disjoncteur moteur + relais thermique", "court-circuit + surcharge"), ("Contacteur et auto-maintien", "Marche / Arrêt à distance"), ("Étoile sur 400 V, triangle sur 230 V", "permuter 2 phases = sens inverse")], AMBRE),
 ("transformateur", "Le transformateur", "U2/U1", [("Alternatif uniquement", "primaire et secondaire sur un noyau de fer"), ("m = U2 / U1 = N2 / N1", "abaisseur si m < 1"), ("Puissance conservée", "tension ÷ 10 → courant × 10"), ("Séparation et sécurité", "prise rasoir, TBTS 12 V")], VERT),
 ("lampes", "Les types de lampes", "LED", [("Lumens = lumière, watts = conso", "LED 10 W ≈ 800 lm ≈ incandescence 60-75 W"), ("Culots", "E27, E14 à vis · GU10 230 V · GU5.3 12 V"), ("Température de couleur", "2 700 K chaud · 4 000 K neutre · 6 500 K froid"), ("Durée de vie LED", "15 000 à 50 000 heures")], AMBRE),
 ("commandes", "Commander l'éclairage", "VV", [("Simple allumage", "1 interrupteur, coupe la phase"), ("Va-et-vient", "2 interrupteurs, 2 navettes"), ("Télérupteur", "boutons-poussoirs, points illimités"), ("Minuterie, détecteur", "extinction auto, allumage au passage")], BLEU),
 ("variation", "Variateurs et pièges des LED", "~", [("Variateur", "lampes dimmables seulement"), ("LED qui reste allumée", "courant de fuite : voyant, neutre coupé"), ("Détecteurs", "crépusculaire, mouvement"), ("Spots 12 V", "transformateur ou driver adapté")], VERT),
 ("prises", "Prises de courant", "16A", [("Prise 16 A 2P+T", "phase, neutre, terre, obturateurs"), ("Hauteur mini", "5 cm (16 A), 12 cm (32 A)"), ("Multiprise 16 A", "3 500 W maximum"), ("Prise commandée", "via un interrupteur, pour une lampe")], BLEU),
 ("raccordement", "Raccorder proprement", "⏚", [("Hors tension, vérifiée", "couper le disjoncteur, VAT"), ("Dénuder 10 à 12 mm", "aucun cuivre apparent"), ("L, N, ⏚", "phase, neutre, terre vert/jaune"), ("Bornes", "à vis serrées, ou automatiques (section admise)")], VERT),
 ("cables", "Fils, câbles et gaines", "R2V", [("H07V-U rigide, H07V-K souple", "fils isolés"), ("U-1000 R2V", "câble extérieur et enterré"), ("Gaine ICTA", "protège et guide les conducteurs"), ("Enterré : 50 cm", "grillage avertisseur rouge au-dessus")], AMBRE),
 ("zones", "Zones de voisinage (BT)", "30cm", [("Zone 4 : 0 à 30 cm", "voisinage renforcé, lettre V + EPI"), ("Zone 1 : 30 cm à 3 m", "voisinage simple"), ("Zone 0 : au-delà de 3 m", "hors voisinage"), ("Armoire fermée", "pas de voisinage tant que fermée")], ROUGE),
 ("hors_portee", "Mettre hors de portée", "STOP", [("Éloignement", "rester hors des zones"), ("Obstacle", "écran, capot, protecteur"), ("Isolation", "nappe isolante sur les pièces nues"), ("Balisage et LAREE", "zone délimitée, local verrouillé")], AMBRE),
 ("qui_peut", "Qui peut faire quoi", "B0", [("Zone 1", "B0 encadré : travaux non électriques"), ("Zone 4", "habilités avec V, EPI obligatoires"), ("Surveillant de sécurité", "veille en permanence"), ("Réflexe", "privilégier la mise hors tension")], BLEU),
 ("epi_liste", "Les EPI", "EPI", [("Gants isolants", "classe 00 : 500 V · classe 0 : 1 000 V"), ("Écran facial", "projections et UV de l'arc"), ("Casque, chaussures isolantes", "vêtements coton, sans métal"), ("Ni montre ni bague", "le métal conduit et brûle")], ROUGE),
 ("epc", "Protections collectives et outils", "1000V", [("Tapis, nappe, écran", "protègent tout le monde"), ("Outils isolés 1 000 V", "double triangle, IEC 60900"), ("Cadenas + pancarte", "personne ne remet sous tension"), ("Échelle isolante", "jamais métallique près des lignes")], VERT),
 ("verifier", "Vérifier avant d'utiliser", "✓", [("Gants", "date, classe, visuel, gonflage"), ("Outils", "marquage 1000 V, isolant intact"), ("VAT", "test avant et après"), ("EPI abîmé", "ne protège plus : on remplace")], BLEU),
]
for nom, titre_s, ini, points, col in RESUMES:
    carte_resume(nom, titre_s, ini, points, col)

RESUMES_B = [
 ("surtensions", "D'où viennent les surtensions", "kV", [("Quelques microsecondes", "plusieurs milliers de volts"), ("Foudre à distance", "par le réseau ou par le sol"), ("Manœuvres réseau, retours de coupure", "aussi des sources de pointes"), ("Type 1 · 2 · 3", "coup direct · tableau · près des appareils")], ROUGE),
 ("installation_pf", "Installer un parafoudre", "50cm", [("En tête du tableau", "après le disjoncteur de branchement"), ("Déconnecteur dédié", "l'isole en fin de vie"), ("Liaisons < 50 cm", "sinon protection dégradée"), ("Obligatoire", "zones orageuses en aérien, paratonnerre")], BLEU),
 ("proteger_appareils", "Protéger ses appareils", "UPS", [("Terre indispensable", "c'est le chemin d'évacuation"), ("Multiprise parafoudre = type 3", "complément, pas remplacement"), ("Onduleur", "coupures et microcoupures"), ("Orage violent", "débrancher le plus sensible")], VERT),
 ("exterieur", "L'électricité en extérieur", "IP44", [("IP44 minimum", "IP55 / IP65 si exposé"), ("Différentiel 30 mA", "sur tout circuit extérieur"), ("U-1000 R2V", "enterré à 50 cm + grillage rouge"), ("Enrouleur déroulé", "section selon la puissance, jamais dans l'eau")], BLEU),
 ("garage_atelier", "Garage et atelier", "IRVE", [("Prises et circuit dédié", "pour les outils puissants"), ("IP5X, arrêt d'urgence", "poussière, machines fixes"), ("Borne de recharge", "circuit dédié, différentiel type A ou F"), ("Pas de prise classique", "pour recharger des heures")], AMBRE),
 ("piscine", "Piscine et bassins", "12V", [("Volume 0 : l'eau", "TBTS 12 V uniquement"), ("Volume 1 : 2 m", "TBTS ou matériel IPX5 fixe"), ("Volume 2 : + 1,5 m", "IPX4, différentiel 30 mA"), ("Liaison équipotentielle", "échelle, structure, garde-corps")], BLEU),
 ("b0_detail", "B0 et H0 : le non-électricien", "B0", [("Travaux non électriques", "peinture, plomberie, maçonnerie"), ("Aucune opération électrique", "ne touche à aucun conducteur"), ("Exécutant ou chargé de chantier", "dirige et veille à la sécurité"), ("Zone 1 oui, zone 4 non", "sauf pièces hors de portée")], BLEU),
 ("bs_detail", "BS : l'intervention élémentaire", "BS", [("Hors tension, ≤ 400 V, ≤ 32 A", "circuits terminaux protégés"), ("Remplacer, raccorder", "prise, interrupteur, lampe, fusible, radiateur"), ("Mise en sécurité", "identifier, séparer, condamner, VAT"), ("Seul, avec du matériel adapté", "signale toute anomalie")], VERT),
 ("limites_b0_bs", "Ce que B0 et BS ne font pas", "STOP", [("Pas de recherche de défaut", "ni mesure sous tension : c'est le BR"), ("Pas plus de 32 A", "pas de HT, pas de sous tension"), ("BE Manœuvre, BP", "réarmer un disjoncteur ; photovoltaïque"), ("Doute ?", "on s'arrête, on appelle un BR ou un B1")], ROUGE),
 ("br_role", "BR : l'intervention générale", "BR", [("Dépannage, recherche de défaut", "remplacement, raccordement, mesures"), ("BT ≤ 1 000 V, circuits ≤ 63 A", "32 A en continu"), ("Consignation pour son propre compte", "sans attestation"), ("Mesures sous tension", "avec EPI, pour chercher le défaut")], BLEU),
 ("br_etapes", "Déroulé d'une intervention", "1→5", [("1. Analyse", "ordre, identification, risque"), ("2. Mise hors tension ou mesures avec EPI", "séparer, condamner, identifier, VAT"), ("3. Réparation · 4. Remise en service", "vérifier que personne n'est exposé"), ("5. Compte rendu", "au chargé d'exploitation")], VERT),
 ("br_limites", "Limites du BR", "63A", [("Pas de travaux programmés", "c'est B1 / B2 sous consignation BC"), ("Pas de HT, pas plus de 63 A", "pas de TST"), ("Aidé par un B1", "sous sa responsabilité"), ("BE Essai, Mesurage, Vérification", "opérations spécifiques")], AMBRE),
 ("electrisation", "Secourir une personne électrisée", "15", [("Protéger", "couper le courant, objet isolant sec"), ("Alerter", "15 · 18 · 112"), ("Secourir", "PLS si respire, RCP + DAE sinon"), ("Toujours consulter", "troubles cardiaques différés")], ROUGE),
 ("incendie", "Feu d'origine électrique", "CO2", [("Couper le courant", "disjoncteur général"), ("Extincteur CO2 ou poudre", "jamais d'eau sous tension"), ("Alerter 18 / 112, évacuer", "fermer les portes derrière soi"), ("DAAF obligatoire", "détecteur de fumée")], ROUGE),
 ("prevention", "Prévenir les accidents", "!", [("À la maison", "obturateurs, rien près de l'eau, débrancher"), ("Diagnostic > 15 ans", "obligatoire à la vente"), ("Au travail", "habilitation, EPI, procédures"), ("Signaux d'alerte", "odeur, prise noircie, picotements")], AMBRE),
]
for nom, titre_s, ini, points, col in RESUMES_B:
    carte_resume(nom, titre_s, ini, points, col)
RESUMES_C = [
 ("b1_exec", "B1 / B1V : l'exécutant", "B1", [("Travaux hors tension", "sous la direction d'un B2"), ("V : zone 4 avec EPI", "voisinage renforcé"), ("Ne consigne pas, ne dirige pas", "signale toute anomalie"), ("H1 en haute tension", "même rôle")], BLEU),
 ("b2_chef", "B2 / B2V : le chargé de travaux", "B2", [("Responsable de la sécurité", "de son équipe"), ("Reçoit l'attestation de consignation", "vérifie l'absence de tension, balise"), ("Informe, surveille", "peut participer"), ("Avis de fin de travail", "sans lui, pas de déconsignation")], VERT),
 ("deroule_travaux", "Travaux hors tension : le déroulé", "1→6", [("Préparation", "ordre de travail, analyse"), ("Consignation par le BC", "attestation"), ("Vérification, balisage, travaux", "sous surveillance du B2"), ("Avis de fin de travail", "puis déconsignation")], AMBRE),
 ("bc_role", "BC : le chargé de consignation", "BC", [("Consigne et déconsigne", "désigné par l'employeur"), ("Une étape", "S-C-I-V + attestation"), ("Deux étapes", "S-C par le BC, I-V par le B2"), ("Déconsigne après l'avis de fin de travail", "tout le monde dégagé")], ROUGE),
 ("documents", "Les documents", "DOC", [("Titre d'habilitation", "symboles, domaine, tâches"), ("Ordre de travail, attestation de consignation", "écrits et signés"), ("Avis de fin de travail", "signé par le chargé de travaux"), ("Carnet de prescriptions", "les règles, remises à chacun")], BLEU),
 ("acteurs", "Les acteurs d'un chantier", "CEE", [("Employeur", "forme, habilite, fournit les EPI"), ("Chargé d'exploitation électrique", "accès et autorisations"), ("BC · B2 · B1", "consigne · dirige · exécute"), ("Chargé de chantier, surveillant", "non électrique · risque électrique")], VERT),
 ("aimants", "Aimants et champ magnétique", "N·S", [("Pôles nord et sud", "opposés s'attirent, identiques se repoussent"), ("Un courant crée un champ", "expérience d'Œrsted"), ("Électroaimant", "bobine + noyau de fer, coupable"), ("Relais, contacteur, serrure", "déclencheur magnétique")], BLEU),
 ("induction", "L'induction", "Φ", [("Champ variable → tension induite", "loi de Faraday"), ("Alternateur, transformateur", "les deux reposent dessus"), ("Loi de Lenz", "le courant induit s'oppose à la cause"), ("Courants de Foucault", "chauffent : induction, tôles feuilletées")], AMBRE),
 ("applications_mag", "Applications", "F", [("Moteur", "force de Laplace"), ("Plaque à induction", "chauffe le fond ferromagnétique"), ("Pince ampèremétrique", "mesure le champ autour du fil"), ("Disjoncteur magnétothermique", "magnétique = court-circuit, thermique = surcharge")], VERT),
 ("composants", "Les composants", "Ω F", [("Résistance, condensateur, bobine", "limite, stocke, filtre"), ("Diode : un seul sens", "seuil 0,7 V, bague = cathode"), ("LED", "toujours avec une résistance"), ("Transistor", "interrupteur ou amplificateur commandé")], BLEU),
 ("alimentation", "L'alimentation", "5V", [("Transformateur", "abaisse le 230 V"), ("Redresseur", "pont de diodes"), ("Filtrage", "condensateur"), ("Régulateur", "tension de sortie fixe")], VERT),
 ("securite_elec", "Sécurité en électronique", "!", [("Condensateurs chargés", "décharger avec une résistance"), ("Électricité statique", "bracelet antistatique"), ("Batteries lithium", "court-circuit = incendie"), ("Polarité et tensions maximales", "à respecter")], ROUGE),
 ("principe_pv", "Le photovoltaïque", "Wc", [("Lumière → courant continu", "panneau ≈ 400 Wc"), ("1 kWc ≈ 1 000 à 1 300 kWh / an", "sud, incliné à 30°"), ("Onduleur", "continu → alternatif 230 V"), ("Micro-onduleurs", "un par panneau")], AMBRE),
 ("installation_pv", "Installer et raccorder", "PV", [("Autoconsommation ou vente", "surplus vendu ou non"), ("Mairie, Enedis, Consuel", "déclaration, raccordement, conformité"), ("Câbles solaires, sectionneur DC", "protections AC"), ("Cadres à la terre", "parafoudre recommandé")], BLEU),
 ("securite_pv", "Sécurité photovoltaïque", "BP", [("Sous tension dès la lumière", "impossible d'éteindre"), ("Arc continu", "jamais de MC4 sous charge"), ("Habilitation BP", "coupure d'urgence pompiers"), ("Chute", "le premier danger sur un toit")], ROUGE),
]
for nom, titre_s, ini, points, col in RESUMES_C:
    carte_resume(nom, titre_s, ini, points, col)
RESUMES_D = [
 ("production", "De la centrale à la prise", "kV", [("Produite = consommée", "l'électricité ne se stocke presque pas"), ("Transport 225 / 400 kV", "RTE, pertes limitées"), ("Distribution HTA 20 kV", "Enedis, postes sources"), ("Poste de quartier", "400 V triphasé / 230 V")], BLEU),
 ("branchement", "Branchement et compteur", "PDL", [("Monophasé 230 V ou triphasé 400 V", "selon la puissance"), ("Compteur communicant", "index, puissance à distance, suivi"), ("Disjoncteur de branchement", "limite réseau / installation"), ("Coupure si dépassement", "de la puissance souscrite")], VERT),
 ("regimes_neutre", "Les régimes de neutre", "TT", [("TT : habitations", "différentiel 30 mA + prise de terre"), ("TN : industrie", "défaut = court-circuit, le disjoncteur coupe"), ("IT : hôpitaux, process", "premier défaut signalé, pas coupé"), ("Contrôleur d'isolement", "en IT")], AMBRE),
 ("appareils_chauffage", "Les appareils de chauffage", "°C", [("Convecteur, rayonnant, inertie", "air, surfaces, accumulation"), ("Plancher chauffant", "confort homogène"), ("Pompe à chaleur", "COP 3 à 4"), ("≈ 100 W par m²", "logement bien isolé")], ROUGE),
 ("regulation", "Régulation et économies", "-1°C", [("Thermostat et programmateur", "1 °C de moins ≈ 7 % d'économie"), ("Fil pilote", "confort, éco, hors gel, arrêt"), ("Délestage", "évite de disjoncter"), ("Circuits dédiés", "2,5 mm² / 20 A")], BLEU),
 ("eau_chaude", "Le chauffe-eau", "55°C", [("Ballon 100 à 300 L", "résistance 1 500 à 3 000 W"), ("Heures creuses", "contacteur jour / nuit"), ("50 à 55 °C", "bactéries vs tartre"), ("Groupe de sécurité", "goutte à la chauffe : normal")], AMBRE),
 ("principe_domotique", "Ce que fait la domotique", "D", [("Capteurs", "température, présence, ouverture"), ("Centrale", "décide selon les scénarios"), ("Actionneurs", "relais, modules, moteurs"), ("Scénarios", "départ, nuit, arrivée")], VERT),
 ("technologies", "Filaire ou sans fil", "RF", [("KNX filaire", "neuf, rénovation lourde"), ("Zigbee, Z-Wave", "maillé, basse consommation"), ("Module derrière interrupteur", "neutre souvent nécessaire"), ("Matter", "interopérabilité")], BLEU),
 ("securite_domotique", "Sécurité et bon sens", "!", [("Règles électriques inchangées", "hors tension, boîtes, sections"), ("Contacteur pour les fortes puissances", "module 16 A maximum"), ("Mots de passe, mises à jour", "réseau séparé"), ("Mode manuel", "si la box tombe")], ROUGE),
 ("modes_recharge", "Les modes de recharge", "kW", [("Prise classique : 2 kW", "dépannage seulement"), ("Prise renforcée : 3,7 kW", "circuit dédié"), ("Wallbox : 7,4 / 11 / 22 kW", "une nuit suffit"), ("Rapide DC : 50 à 350 kW", "bornes publiques")], VERT),
 ("installation_ve", "Installer une borne", "IRVE", [("Circuit dédié 10 mm²", "disjoncteur 40 A"), ("Différentiel type A 6 mA DC", "ou F, ou B"), ("Installateur IRVE", "au-delà de 3,7 kW"), ("Abonnement 12 kVA", "pilotage énergétique")], BLEU),
 ("securite_ve", "Sécurité et bonnes pratiques", "800V", [("Batterie 400 à 800 V DC", "habilitation spécifique"), ("Câble verrouillé", "arrêter la session avant"), ("Ni rallonge ni multiprise", "surveiller la prise"), ("Incendie", "s'éloigner, appeler le 18")], ROUGE),
 ("technologies_bat", "Piles et batteries", "Li", [("Pile : usage unique", "batterie : rechargeable"), ("Plomb 12 V, NiMH 1,2 V", "lithium 3,7 V, LFP 3,2 V"), ("BMS", "protège le lithium"), ("Série : tensions", "parallèle : capacités")], AMBRE),
 ("capacite", "Capacité et autonomie", "Ah", [("Ah : quantité de charge", "100 Ah = 10 A pendant 10 h"), ("E = U × Ah", "12 V × 100 Ah = 1,2 kWh"), ("Autonomie = E / P", "1 200 Wh / 60 W ≈ 20 h"), ("Cycles", "500 à 2 000 pour le lithium")], BLEU),
 ("securite_batteries", "Charger en sécurité", "!", [("Chargeur adapté", "à la technologie"), ("Court-circuit = incendie", "protéger les bornes"), ("Plomb : hydrogène", "lithium : ni percer ni chauffer"), ("Recyclage obligatoire", "points de collecte")], ROUGE),
]
for nom, titre_s, ini, points, col in RESUMES_D:
    carte_resume(nom, titre_s, ini, points, col)
RESUMES_E = [
 ("unites_si", "Les unités", "V A Ω", [("V, A, Ω, W", "tension, intensité, résistance, puissance"), ("Wh, J", "énergie"), ("Hz, F, Ah, T", "fréquence, capacité, batterie, champ"), ("lm, lx", "flux lumineux, éclairement")], BLEU),
 ("prefixes", "Les préfixes", "k m", [("méga M : × 1 000 000", "kilo k : × 1 000"), ("milli m : ÷ 1 000", "micro µ : ÷ 1 000 000"), ("M ≠ m", "un milliard d'écart"), ("2 300 W = 2,3 kW", "0,5 A = 500 mA")], AMBRE),
 ("ordres_grandeur", "Ordres de grandeur", "≈", [("1,5 V · 12 V · 230 V · 400 V", "pile, voiture, prise, triphasé"), ("10 W · 100 W · 2 500 W · 7 000 W", "LED, TV, four, plaque"), ("0,5 mA · 10 mA · 30 mA", "perception, non-lâcher, différentiel"), ("50 Hz · 20 ms", "réseau, période")], VERT),
 ("marquages", "Les marquages", "CE", [("230 V~ 50 Hz", "tension, fréquence, puissance"), ("Classe I ⏚ · II ▣ · III", "terre, double isolation, TBTS"), ("IP", "solides, eau"), ("CE, poubelle barrée", "conformité, recyclage")], BLEU),
 ("plaque_moteur", "La plaque d'un moteur", "Δ Y", [("230 V Δ / 400 V Y", "étoile sur 400 V"), ("kW = puissance utile", "absorbée = utile / rendement"), ("1 450 tr/min", "4 pôles à 50 Hz"), ("cos φ, η, IP, S1", "facteur de puissance, rendement, service")], AMBRE),
 ("classes_ip", "Classes et IP", "IP44", [("Classe I", "terre, fiche à broche"), ("Classe II", "double isolation, sans terre"), ("Classe III", "TBTS 12 / 24 V"), ("IP20 · IP44 · IP65 · IP68", "sec, dehors, exposé, immergé")], VERT),
 ("vmc", "La VMC", "VMC", [("Renouvelle l'air", "extrait l'humidité"), ("Autoréglable, hygroréglable", "débit fixe ou selon l'humidité"), ("Double flux", "récupère la chaleur"), ("24 h/24, circuit dédié", "20 à 80 W")], BLEU),
 ("climatisation", "La climatisation", "kW", [("Pompe à chaleur inversée", "réversible : chauffe aussi"), ("Split", "unité extérieure + intérieures"), ("≈ 100 W frigorifiques par m²", "2,5 kW pour 25 m²"), ("Fluide", "professionnel attesté")], VERT),
 ("raccordement_clim", "Raccorder et entretenir", "30mA", [("Circuit dédié", "différentiel 30 mA"), ("Unité extérieure", "antivibratile, interrupteur de proximité"), ("Condensats", "à évacuer"), ("Filtres tous les mois", "étanchéité périodique")], AMBRE),
 ("outils_electro", "Outils électroportatifs", "18V", [("Secteur : classe II", "câble et fiche vérifiés"), ("Batterie 18 V", "attention au lithium"), ("Câble abîmé", "on remplace"), ("EPI selon l'outil", "lunettes, gants, auditif")], BLEU),
 ("chantier", "L'électricité sur un chantier", "RCD", [("Coffret 30 mA", "rallonges H07RN-F déroulées"), ("RCD portable", "sans coffret"), ("Cuve, fosse : TBTS 24 V", "jamais de 230 V"), ("DT-DICT, lignes aériennes", "avant de creuser, distances")], ROUGE),
 ("bonnes_pratiques", "Bonnes pratiques", "✓", [("Débrancher avant de changer un accessoire", "jamais d'interrupteur bloqué"), ("Deux mains, pas de vêtements flottants", "poussière : aspiration ou masque"), ("Batteries au sec, à l'ombre", "contrôles périodiques"), ("Picotement, odeur, chauffe", "on arrête")], VERT),
 ("les_normes", "Les normes", "NF C", [("NF C 15-100", "installations BT"), ("NF C 18-510", "opérations et habilitation"), ("NF C 14-100", "branchement"), ("Version en vigueur", "à la date des travaux")], BLEU),
 ("consuel", "Consuel et conformité", "OK", [("Attestation visée", "avant mise sous tension"), ("Sans visa, pas de raccordement", "neuf ou rénovation totale"), ("Mise en conformité", "tout aux normes, neuf"), ("Mise en sécurité", "points essentiels, existant")], AMBRE),
 ("diagnostic", "Le diagnostic électrique", "15ans", [("Vente et location", "installation de plus de 15 ans"), ("Validité 3 ans / 6 ans", "vente / location"), ("6 points de sécurité", "AGCP, différentiel, protections, SdB, vétuste, conducteurs"), ("Informe", "n'oblige pas, mais engage")], ROUGE),
]
for nom, titre_s, ini, points, col in RESUMES_E:
    carte_resume(nom, titre_s, ini, points, col)
RESUMES_F = [
 ("organisation_tableau", "Organisation d'un tableau", "TAB", [("Un différentiel par rangée", "peigne d'alimentation"), ("Circuits d'une pièce répartis", "sur plusieurs différentiels"), ("Type A", "plaque, lave-linge"), ("20 % de réserve", "borniers terre et neutre")], BLEU),
 ("reperage", "Repérer les circuits", "L N PE", [("Étiquettes sur chaque disjoncteur", "sinon chasse au trésor"), ("Lampe + disjoncteurs un par un", "méthode simple"), ("Schéma unifilaire dans la porte", "obligatoire dans le neuf"), ("L1 L2 L3, N, PE", "repères normalisés")], VERT),
 ("calibres_lecture", "Lire un disjoncteur", "C16", [("Calibre et courbe", "C standard, B sensible, D moteurs"), ("Pouvoir de coupure", "3 000 / 4 500 A"), ("Manette haut / bas", "enclenché / déclenché"), ("Différentiel", "30 mA, type, calibre, bouton T")], AMBRE),
 ("methode", "La méthode de dépannage", "1→6", [("Observer, localiser", "quoi, où, depuis quand"), ("Le plus simple d'abord", "disjoncteur, ampoule, appareil"), ("Isoler, mesurer", "hors tension si possible"), ("Réparer, tester", "jamais de protection plus grosse")], BLEU),
 ("pannes_courantes", "Les pannes courantes", "?", [("Différentiel qui saute", "appareil en fuite : un par un"), ("Disjoncteur sur un appareil", "défaut dans l'appareil"), ("Prise morte", "connexion desserrée"), ("Prise chaude, odeur", "couper, ne plus utiliser")], ROUGE),
 ("mesures_depannage", "Mesurer pour comprendre", "Ω V", [("Continuité", "fil coupé, fusible, interrupteur"), ("Résistance de chauffe", "1 000 W ≈ 50 Ω"), ("Phase-neutre 230 V, neutre-terre ≈ 0 V", "avec précautions BR"), ("Pince, testeur de prise", "consommation, câblage")], VERT),
 ("definition_cf", "Courants forts, courants faibles", "mA", [("Forts : énergie", "230 V, prises, chauffage"), ("Faibles : information", "téléphone, réseau, TV, alarme"), ("Gaines séparées", "croisements à angle droit"), ("Sans danger", "mais propreté et repérage")], BLEU),
 ("coffret_com", "Le coffret de communication", "RJ45", [("Arrivée opérateur, box", "panneau de brassage"), ("Cat 5e, 6, 6A", "100 m maximum"), ("TV : coaxial ou réseau", "coffret relié à la terre"), ("Parafoudre ligne", "protège la box")], VERT),
 ("fibre_reseau", "Fibre, Wi-Fi, bonnes pratiques", "PoE", [("Fibre : lumière", "fragile, outillage spécifique"), ("Câble > Wi-Fi", "pour les postes fixes"), ("Repérer, tester", "rayon de courbure, pas d'agrafes"), ("PoE 48 V", "caméra, borne Wi-Fi")], AMBRE),
 ("choix_ext", "Choisir l'éclairage extérieur", "IP65", [("IP44 → IP65 → IP67/68", "exposé, enterré"), ("LED, 2 700 à 4 000 K", "ambiance ou sécurité"), ("Détecteur, crépusculaire, horloge", "commandes"), ("Vers le bas", "pollution lumineuse")], BLEU),
 ("cablage_ext", "Câbler dehors", "TPC", [("Différentiel 30 mA", "circuit dédié"), ("R2V en gaine TPC rouge", "50 cm, grillage"), ("Boîtes IP55, entrées par le bas", "presse-étoupes"), ("Classe I à la terre", "12 V : transfo au sec")], VERT),
 ("solaire_ext", "Solaire, 12 V, entretien", "12V", [("Solaire autonome", "balisage seulement"), ("TBTS 12 / 24 V", "sans risque"), ("Chute de tension", "section plus grosse"), ("Optiques, joints, bouton T", "luminaire noyé : remplacer")], AMBRE),
 ("alarme_intrusion", "L'alarme intrusion", "ALM", [("Détecteurs", "ouverture, mouvement, bris de vitre"), ("Centrale 230 V + batterie", "filaire ou radio"), ("Sirènes et alerte", "intérieure, extérieure, téléphone"), ("Total / partiel", "code, badge, télécommande")], ROUGE),
 ("video", "La vidéosurveillance", "CAM", [("PoE ou Wi-Fi", "NVR, carte, cloud"), ("IP66, infrarouge, 2,5 à 3 m", "extérieur"), ("Sa propriété seulement", "pas la rue ni le voisin"), ("Mots de passe, mises à jour", "sécurité numérique")], BLEU),
 ("installation_alarme", "Installer et entretenir", "OK", [("Centrale hors de vue", "sirène extérieure en hauteur"), ("Détecteurs dans les angles à 2,2 m", "pas face aux fenêtres"), ("Batterie 3 à 5 ans", "piles radio"), ("Tester", "coupler à la domotique")], VERT),
]
for nom, titre_s, ini, points, col in RESUMES_F:
    carte_resume(nom, titre_s, ini, points, col)
RESUMES_G = [
 ("principe_tri", "Trois phases décalées", "3~", [("L1, L2, L3 à 120°", "plus le neutre"), ("230 V simple, 400 V composée", "rapport √3"), ("Courants plus faibles", "champ tournant pour les moteurs"), ("Au-delà de 12 kVA", "ou moteur triphasé")], BLEU),
 ("equilibrage", "Équilibrer les phases", "=", [("Même courant par phase", "répartir les circuits"), ("12 kVA = 20 A par phase", "pas 60 A au total"), ("Pince sur chaque phase", "vérifier"), ("Neutre coupé", "tensions déséquilibrées, danger")], AMBRE),
 ("couplages", "Étoile et triangle", "Y Δ", [("Étoile : 230 V par enroulement", "sur réseau 400 V"), ("Triangle : 400 V par enroulement", "boucle"), ("230 V Δ / 400 V Y → étoile", "triangle par erreur = grillé"), ("P = √3 × U × I × cos φ", "U composée")], VERT),
 ("isolement", "Mesurer l'isolement", "MΩ", [("Résistance conducteurs / terre", "sain : dizaines de MΩ"), ("Contrôleur à 500 V continu", "hors tension, appareils débranchés"), ("Minimum 0,5 MΩ", "en 230 / 400 V"), ("Quelques kΩ", "défaut : fuite, humidité")], BLEU),
 ("prise_terre", "Mesurer la terre", "Ω", [("≤ 100 Ω avec 30 mA", "on vise < 50 Ω"), ("Telluromètre, 62 %", "barrette ouverte"), ("Mesure de boucle", "depuis une prise, sous tension"), ("Améliorer", "piquet en plus, fond de fouille")], VERT),
 ("controleur", "Le contrôleur d'installation", "TEST", [("Isolement, continuité, boucle, terre", "tout-en-un"), ("Différentiel : 15 à 30 mA", "en moins de 300 ms"), ("Bouton T = mécanique", "contrôleur = sensibilité réelle"), ("Rapport de vérification", "initiale ou périodique")], AMBRE),
 ("etat_des_lieux", "Faire l'état des lieux", "30ans", [("Pas de terre, pas de différentiel", "fusibles, fils en tissu"), ("Couper, repérer, mesurer", "photographier"), ("Sécurité ou rénovation complète", "selon l'état des câbles"), ("Amiante, plomb", "diagnostic avant de percer")], ROUGE),
 ("priorites", "Les priorités", "1→6", [("1. Terre · 2. Différentiels", "3. Un disjoncteur par circuit"), ("4. Salle de bains", "5. Matériel vétuste"), ("6. Conducteurs protégés", "boîtes fermées"), ("Calibre selon le câble", "jamais l'inverse")], BLEU),
 ("chantier_renovation", "Conduire le chantier", "OK", [("Nouveau tableau à côté", "transfert circuit par circuit"), ("ICTA, goulottes, plinthes", "20 % de réserve"), ("Enedis si le branchement change", "Consuel si rénovation totale"), ("Schéma, étiquettes, mesures", "dossier remis")], VERT),
 ("groupe", "Le groupe électrogène", "kVA", [("Moteur + alternateur", "2 à 10 kVA domestique"), ("Moteurs : 3 × au démarrage", "1 kVA ≈ 0,8 à 1 kW"), ("Inverter", "courant propre pour l'électronique"), ("Dehors uniquement", "monoxyde de carbone")], AMBRE),
 ("inverseur", "Raccorder un groupe", "⇄", [("Jamais de câble mâle-mâle", "retour sur le réseau : danger"), ("Inverseur de source", "isole le réseau, commute phase et neutre"), ("Circuits prioritaires", "frigo, chaudière, éclairage"), ("Terre reliée", "pose par un professionnel")], ROUGE),
 ("onduleur_secours", "Onduleurs de secours", "UPS", [("Batterie + filtrage", "minutes à heures"), ("Off-line, line-interactive, on-line", "du simple au sans coupure"), ("Informatique, box, alarme, chaudière", "VA et autonomie"), ("Batteries 3 à 5 ans", "solaire en mode backup")], BLEU),
 ("puissances", "Active, réactive, apparente", "cosφ", [("P (W) travaille", "Q (VAR) circule sans produire"), ("S (VA) = √(P² + Q²)", "ce que fournit le réseau"), ("cos φ = P / S", "1 résistance, 0,8 moteur"), ("Abonnement en kVA", "dimensionné sur S")], BLEU),
 ("consequences", "Pourquoi ça compte", "I↑", [("I = P / (U × cos φ)", "cos φ 0,5 : courant doublé"), ("Câbles surchargés, pertes", "disjoncteurs"), ("Industriels : réactif facturé", "au-delà d'un seuil"), ("Particulier : kWh facturés", "mais kVA à couvrir")], AMBRE),
 ("compensation", "Compenser le réactif", "C", [("Condensateurs", "fournissent le réactif"), ("Globale au tableau", "ou locale près du moteur"), ("Objectif cos φ ≥ 0,93", "sans surcompenser"), ("Condensateurs chargés", "attendre la décharge")], VERT),
]
for nom, titre_s, ini, points, col in RESUMES_G:
    carte_resume(nom, titre_s, ini, points, col)
RESUMES_H = [
 ("pionniers", "Les pionniers", "1800", [("Franklin 1752", "l'éclair est électrique, paratonnerre"), ("Volta 1800", "la pile"), ("Œrsted, Ampère 1820 · Ohm 1827", "magnétisme, U = R × I"), ("Faraday 1831", "l'induction")], BLEU),
 ("industrialisation", "L'électricité devient une industrie", "1879", [("Edison 1879", "lampe, premier réseau (continu)"), ("Tesla, Westinghouse", "alternatif, moteur asynchrone"), ("Guerre des courants", "l'alternatif gagne : transport HT"), ("EDF 1946", "campagnes électrifiées vers 1950")], AMBRE),
 ("aujourdhui", "D'hier à aujourd'hui", "2012", [("NF C 15-100 : 1911", "différentiel 30 mA obligatoire : 1991"), ("Habilitation", "UTE C 18-510 1988, NF C 18-510 2012"), ("Nucléaire années 70-80", "LED, renouvelables, VE"), ("Les normes naissent des accidents", "pas de contraintes abstraites")], VERT),
 ("deux_reseaux", "Deux réseaux à bord", "12V", [("12 / 24 V continu", "batterie de servitude, coupleur"), ("230 V", "quai, camping ou convertisseur"), ("Forts courants en 12 V", "120 W = 10 A"), ("Fusibles près de la batterie", "un par circuit")], BLEU),
 ("branchement_quai", "Le branchement 230 V", "CEE", [("Câble H07RN-F, fiche bleue", "jamais de rallonge domestique"), ("Disjoncteur + différentiel 30 mA", "à bord"), ("Isolateur galvanique", "contre la corrosion"), ("Tester le différentiel", "à chaque branchement")], VERT),
 ("energie_bord", "Produire et stocker à bord", "MPPT", [("Panneaux + régulateur MPPT", "alternateur en roulant"), ("Plomb AGM / gel ou LFP", "BMS et chargeur adaptés"), ("Bilan Wh par jour", "plomb : pas sous 50 %"), ("Compartiment ventilé, fusible, coupe-batterie", "sécurité")], AMBRE),
 ("taux", "Taux d'autoconsommation", "%", [("Autoconsommation", "part de la production consommée"), ("Autoproduction", "part de la consommation couverte"), ("30 à 40 % sans stockage", "midi vs soir"), ("Déplacer, dimensionner, stocker", "pour progresser")], BLEU),
 ("pilotage", "Piloter les consommations", "⇉", [("Routeur solaire", "surplus vers le chauffe-eau"), ("Programmer en journée", "lave-linge, recharge, PAC"), ("Compteur bidirectionnel", "kWh injectés et soutirés"), ("Application de suivi", "voir pour agir")], VERT),
 ("stockage_domestique", "La batterie domestique", "kWh", [("LFP 5 à 15 kWh", "onduleur hybride"), ("60 à 80 % d'autoconsommation", "rentabilité à calculer"), ("Local ventilé, protections, Consuel", "coupure d'urgence"), ("Backup", "seulement si le réseau est isolé")], AMBRE),
 ("statique", "L'électricité statique", "kV", [("Haute tension, faible énergie", "sans danger pour le corps"), ("Détruit l'électronique", "enflamme les vapeurs"), ("Moquette, tuyaux, courroies, synthétique", "sources"), ("Terre, bracelet, humidité, coton", "protection")], BLEU),
 ("zones_atex", "Les zones ATEX", "Ex", [("Gaz, vapeur, poussière + air", "station-service, silo, peinture"), ("Zones 0, 1, 2", "permanent, occasionnel, rare"), ("Zones 20, 21, 22", "poussières"), ("Matériel certifié Ex", "une étincelle suffit")], ROUGE),
 ("prevention_atex", "Prévenir l'explosion", "△", [("Combustible + air + inflammation", "supprimer un côté"), ("Ventiler, limiter les fuites", "pas d'étincelle ni surface chaude"), ("Terre et équipotentialité", "cuves, tuyauteries"), ("Permis, détection de gaz", "formation ATEX")], AMBRE),
 ("arc", "L'arc électrique", "5000°", [("Courant dans l'air ionisé", "court-circuit, ouverture sous charge"), ("Brûlures, projections, souffle", "sans contact"), ("Puissance de court-circuit, durée", "près du transfo : pire"), ("Écran, vêtements ignifugés", "et surtout : hors tension")], ROUGE),
 ("tst", "Le travail sous tension", "TST", [("L'exception", "quand couper est impossible"), ("Habilitation TST", "formation, outils, EPI certifiés"), ("Au contact, à distance, à potentiel", "méthodes"), ("Le BR ne fait pas de TST", "mesures et manœuvres seulement")], BLEU),
 ("presence_tension", "En présence de tension", "1 main", [("Mesures, essais, manœuvres", "sans consigner, avec précautions"), ("Gants, écran, outillage isolé", "une seule main"), ("Pas de bijou, pas d'appui conducteur", "balisage"), ("Hors tension possible ?", "plus souvent qu'on ne croit")], VERT),
]
for nom, titre_s, ini, points, col in RESUMES_H:
    carte_resume(nom, titre_s, ini, points, col)
