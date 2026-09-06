"""Images des questions de type `image` : symboles normalisés dessinés en
grand sur une carte 600×360, rendus en PNG par Chromium."""
import os

OUT = os.path.dirname(os.path.abspath(__file__))
W, H = 600, 360
FIL, TXT = "#37474F", "#1F2933"

def svg(nom, corps):
    doc = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="DejaVu Sans, sans-serif">\n<rect width="{W}" height="{H}" rx="28" fill="#F7F9FC"/>\n{corps}</svg>'
    open(os.path.join(OUT, nom + ".svg"), "w", encoding="utf-8").write(doc)

def t(x, y, s, size=34, color=TXT, weight="normal"):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" text-anchor="middle" font-weight="{weight}">{s}</text>\n'
def ligne(x1, y1, x2, y2, w=7):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{FIL}" stroke-width="{w}" stroke-linecap="round"/>\n'
def rect(x, y, w, h, rx=8):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="white" stroke="{FIL}" stroke-width="7"/>\n'
def cercle(cx, cy, r, fill="white"):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{FIL}" stroke-width="7"/>\n'

cx, cy = W / 2, H / 2
fils = ligne(60, cy, cx - 90, cy) + ligne(cx + 90, cy, W - 60, cy)

# Résistance : rectangle sur le fil
svg("sym_resistance", fils + rect(cx - 90, cy - 32, 180, 64))
# Lampe : cercle et croix
k = 60 * 0.707
svg("sym_lampe", ligne(60, cy, cx - 60, cy) + ligne(cx + 60, cy, W - 60, cy) + cercle(cx, cy, 60) +
    ligne(cx - k, cy - k, cx + k, cy + k) + ligne(cx - k, cy + k, cx + k, cy - k))
# Interrupteur ouvert
svg("sym_interrupteur", ligne(60, cy, cx - 80, cy) + ligne(cx + 80, cy, W - 60, cy) +
    cercle(cx - 80, cy, 9, FIL) + cercle(cx + 80, cy, 9, FIL) + ligne(cx - 80, cy, cx + 60, cy - 70))
# Pile : trait long (+), trait court (−)
svg("sym_pile", ligne(60, cy, cx - 22, cy) + ligne(cx + 22, cy, W - 60, cy) +
    ligne(cx - 22, cy - 70, cx - 22, cy + 70, 8) + ligne(cx + 22, cy - 32, cx + 22, cy + 32, 16) +
    t(cx - 22, cy - 92, "+", 40) + t(cx + 22, cy - 92, "−", 40))
# Fusible : rectangle traversé par le fil
svg("sym_fusible", ligne(60, cy, W - 60, cy) + rect(cx - 90, cy - 30, 180, 60))
# Terre
svg("sym_terre", ligne(cx, 70, cx, cy - 10) + ligne(cx - 70, cy - 10, cx + 70, cy - 10) +
    ligne(cx - 46, cy + 20, cx + 46, cy + 20) + ligne(cx - 22, cy + 50, cx + 22, cy + 50))
# Moteur et voltmètre : cercle avec une lettre
for nom, lettre in [("sym_moteur", "M"), ("sym_voltmetre", "V"), ("sym_amperemetre", "A")]:
    svg(nom, ligne(60, cy, cx - 64, cy) + ligne(cx + 64, cy, W - 60, cy) + cercle(cx, cy, 64) +
        t(cx, cy + 22, lettre, 64, TXT, "bold"))
# Disjoncteur (symbole unifilaire simplifié : interrupteur avec croix)
svg("sym_disjoncteur", ligne(60, cy, cx - 80, cy) + ligne(cx + 80, cy, W - 60, cy) +
    cercle(cx - 80, cy, 9, FIL) + ligne(cx - 80, cy, cx + 60, cy - 70) +
    ligne(cx + 64, cy - 16, cx + 96, cy + 16) + ligne(cx + 64, cy + 16, cx + 96, cy - 16))
print("ok")
