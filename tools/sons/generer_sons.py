"""Génère les petits sons de l'appli (WAV mono 22 050 Hz, 16 bits) sans
aucune dépendance : bonne réponse, mauvaise réponse, combo, fin de quiz,
tic-tac du mode éclair. Lancer : python tools/sons/generer_sons.py"""
import math
import struct
import wave
from pathlib import Path

TAUX = 22050
SORTIE = Path(__file__).resolve().parents[2] / "assets" / "sons"


def note(freq, duree, volume=0.5, forme="sin", attaque=0.01, chute=0.08):
    """Une note avec une enveloppe douce (pas de clic au début ni à la fin)."""
    n = int(TAUX * duree)
    echantillons = []
    for i in range(n):
        t = i / TAUX
        if forme == "sin":
            v = math.sin(2 * math.pi * freq * t)
        elif forme == "carre":
            v = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        else:  # triangle
            v = 2 * abs(2 * ((t * freq) % 1) - 1) - 1
        env = min(1.0, t / attaque, max(0.0, (duree - t) / chute))
        echantillons.append(v * volume * env)
    return echantillons


def silence(duree):
    return [0.0] * int(TAUX * duree)


def ecrire(nom, sequences):
    donnees = [e for seq in sequences for e in seq]
    with wave.open(str(SORTIE / nom), "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(TAUX)
        f.writeframes(b"".join(
            struct.pack("<h", int(max(-1, min(1, e)) * 32767)) for e in donnees))
    print(nom, len(donnees) / TAUX, "s")


SORTIE.mkdir(parents=True, exist_ok=True)
# Bonne réponse : deux notes qui montent (do → sol).
ecrire("bonne.wav", [note(523, 0.10, 0.45), note(784, 0.18, 0.45)])
# Mauvaise réponse : note grave qui descend, un peu rêche.
ecrire("mauvaise.wav", [note(220, 0.12, 0.35, "triangle"), note(165, 0.22, 0.35, "triangle")])
# Combo : trois notes rapides qui montent.
ecrire("combo.wav", [note(659, 0.07, 0.4), note(784, 0.07, 0.4), note(1047, 0.16, 0.45)])
# Fin de quiz : petite fanfare (do mi sol do).
ecrire("fin.wav", [note(523, 0.12, 0.4), note(659, 0.12, 0.4), note(784, 0.12, 0.4),
                   silence(0.03), note(1047, 0.35, 0.45)])
# Tic du chrono éclair : un clic bref.
ecrire("tic.wav", [note(1200, 0.03, 0.25)])
