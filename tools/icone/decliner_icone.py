"""Décline l'icône 1024 dans toutes les tailles web et iOS, sans dépendance."""
import sys, os
sys.path.insert(0, "/tmp/claude-0/-home-user-app-lectricit-/21ba3ae3-226b-50ec-9bca-e4856d24f395/scratchpad/icon")
from resize import lire_png, ecrire_png

def redim(lignes, w, h, canaux, tw, th):
    out = []
    for y in range(th):
        y0 = y * h / th; y1 = (y + 1) * h / th
        ligne = bytearray()
        for x in range(tw):
            x0 = x * w / tw; x1 = (x + 1) * w / tw
            acc = [0.0] * canaux; poids = 0.0
            for sy in range(int(y0), int(-(-y1 // 1))):
                wy = min(y1, sy + 1) - max(y0, sy)
                if wy <= 0: continue
                row = lignes[sy]
                for sx in range(int(x0), int(-(-x1 // 1))):
                    wx = min(x1, sx + 1) - max(x0, sx)
                    if wx <= 0: continue
                    p = wx * wy; poids += p
                    base = sx * canaux
                    for c in range(canaux): acc[c] += row[base + c] * p
            ligne.extend(int(round(v / poids)) for v in acc)
        out.append(ligne)
    return out

def sans_alpha(lignes, w):
    return [bytearray(b for i, b in enumerate(l) if i % 4 != 3) for l in lignes]

def ecrire(src, dst, tw, th=None, opaque=False):
    th = th or tw
    w, h, canaux, lignes = lire_png(src)
    out = redim(lignes, w, h, canaux, tw, th)
    if opaque and canaux == 4:
        out = sans_alpha(out, tw); canaux = 3
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    ecrire_png(dst, tw, th, canaux, out)
    print(dst, tw, th)

S = "/tmp/claude-0/-home-user-app-lectricit-/21ba3ae3-226b-50ec-9bca-e4856d24f395/scratchpad"
P = "/home/user/app-lectricit-"
# Web
ecrire(f"{S}/icone/icone.png", f"{P}/web/icons/Icon-192.png", 192)
ecrire(f"{S}/icone/icone.png", f"{P}/web/icons/Icon-512.png", 512)
ecrire(f"{S}/icone/icone_maskable.png", f"{P}/web/icons/Icon-maskable-192.png", 192)
ecrire(f"{S}/icone/icone_maskable.png", f"{P}/web/icons/Icon-maskable-512.png", 512)
ecrire(f"{S}/icone/icone.png", f"{P}/web/favicon.png", 64)
# iOS : sans canal alpha (exigé par l'App Store)
ios = f"{P}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
for nom, px in [("20x20@1x", 20), ("20x20@2x", 40), ("20x20@3x", 60), ("29x29@1x", 29), ("29x29@2x", 58),
                ("29x29@3x", 87), ("40x40@1x", 40), ("40x40@2x", 80), ("40x40@3x", 120), ("60x60@2x", 120),
                ("60x60@3x", 180), ("76x76@1x", 76), ("76x76@2x", 152), ("83.5x83.5@2x", 167), ("1024x1024@1x", 1024)]:
    ecrire(f"{S}/icone/icone.png", f"{ios}/Icon-App-{nom}.png", px, opaque=True)
# Écran de lancement iOS : la mascotte seule, 150×200 points
lancement = f"{P}/ios/Runner/Assets.xcassets/LaunchImage.imageset"
ecrire(f"{S}/decor/pile_3.png", f"{lancement}/LaunchImage.png", 150, 200)
ecrire(f"{S}/decor/pile_3.png", f"{lancement}/LaunchImage@2x.png", 300, 400)
ecrire(f"{S}/decor/pile_3.png", f"{lancement}/LaunchImage@3x.png", 450, 600)
