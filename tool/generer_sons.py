#!/usr/bin/env python3
"""Fabrique tous les sons de Balamo par synthèse, sans aucun échantillon externe.

Produit dans assets/sons/ :
  - les bruitages (WAV mono, très courts) ;
  - la musique d'ambiance (musique.m4a, boucle d'environ 1 min 30).

Parti pris sonore : du bois et des lames de marimba, comme les jetons. Des
attaques douces, des notes courtes, peu d'aigus, et tout dans la même gamme
(do majeur pentatonique) que la musique : un bruitage ne « frotte » jamais
contre l'accompagnement. Les sons les plus fréquents (poser un jeton) existent
en plusieurs variantes pour ne pas lasser.

Usage (numpy requis ; afconvert ou ffmpeg pour encoder la musique) :
    python3 tool/generer_sons.py
"""
import shutil
import subprocess
import wave
from pathlib import Path

import numpy as np

FE = 44100  # fréquence d'échantillonnage
RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "assets" / "sons"
hasard = np.random.default_rng(2026)


# --------------------------------------------------------------- outils


def temps(duree):
    return np.arange(int(FE * duree)) / FE


def note(midi):
    """Fréquence d'une note MIDI (60 = do central)."""
    return 440.0 * 2 ** ((midi - 69) / 12)


def filtre(x, bas=None, haut=None, ordre=2):
    """Filtre passe-bas (« bas » = coupure haute) et/ou passe-haut, sans déphasage."""
    spectre = np.fft.rfft(x, axis=0)
    f = np.fft.rfftfreq(x.shape[0], 1 / FE)
    gain = np.ones_like(f)
    if bas:
        gain /= np.sqrt(1 + (f / bas) ** (2 * ordre))
    if haut:
        gain *= 1 - 1 / np.sqrt(1 + (f / haut) ** (2 * ordre))
    if x.ndim == 2:
        gain = gain[:, None]
    return np.fft.irfft(spectre * gain, n=x.shape[0], axis=0)


def fondu(x, debut_ms=1.0, fin_ms=12.0):
    """Entrée et sortie progressives : aucun « clic » en début ou fin de son."""
    x = x.copy()
    a = max(1, int(FE * debut_ms / 1000))
    b = max(1, min(len(x), int(FE * fin_ms / 1000)))
    x[:a] *= np.linspace(0, 1, a)
    x[-b:] *= np.linspace(1, 0, b) ** 2
    return x


def bruit(n):
    return hasard.standard_normal(n)


def melange(*evenements, queue=0.0):
    """Superpose des sons placés à des instants donnés : (instant en s, signal)."""
    fin = max(int(t0 * FE) + len(y) for t0, y in evenements) + int(queue * FE)
    sortie = np.zeros(fin)
    for t0, y in evenements:
        i = int(t0 * FE)
        sortie[i:i + len(y)] += y
    return sortie


def reverb(x, duree=0.6, dose=0.15, couleur=4500):
    """Petite salle : convolution avec un bruit qui s'éteint en `duree` secondes."""
    n = int(FE * duree)
    queue = filtre(bruit(n) * np.exp(-temps(duree) * 6.9 / duree), bas=couleur, haut=250)
    queue /= np.sqrt(np.sum(queue ** 2))
    total = len(x) + n
    taille = 1 << (total - 1).bit_length()
    humide = np.fft.irfft(np.fft.rfft(x, taille) * np.fft.rfft(queue, taille), taille)[:total]
    sec = np.concatenate([x, np.zeros(n)])
    return sec + dose * humide


def niveau(x, crete):
    return x * (crete / np.max(np.abs(x)))


# ------------------------------------------------------------ instruments


def marimba(f, duree=0.6, force=1.0, tenue=1.0):
    """Lame de marimba : fondamentale ronde, harmonique 4 brève, coup de mailloche feutré."""
    t = temps(duree)
    tau = 0.26 * (440 / f) ** 0.6 * tenue
    y = np.sin(2 * np.pi * f * t) * np.exp(-t / tau)
    y += 0.20 * np.sin(2 * np.pi * 4 * f * t) * np.exp(-t / (tau * 0.22))
    y += 0.04 * np.sin(2 * np.pi * 9.2 * f * t) * np.exp(-t / (tau * 0.07))
    mailloche = filtre(bruit(len(t)), bas=3200, haut=500) * np.exp(-t / 0.004) * 0.18
    return fondu((y + mailloche) * force, 1.5, 20)


def clochette(f, duree=0.9, force=1.0):
    """Lame de métal très douce, pour les moments de réussite."""
    t = temps(duree)
    tau = 0.42 * (880 / f) ** 0.5
    y = np.sin(2 * np.pi * f * t) * np.exp(-t / tau)
    y += 0.22 * np.sin(2 * np.pi * 2.76 * f * t) * np.exp(-t / (tau * 0.35))
    y += 0.06 * np.sin(2 * np.pi * 5.4 * f * t) * np.exp(-t / (tau * 0.15))
    return fondu(y * force, 2.5, 30)


def bois(f, force=1.0, duree=0.12, sec=1.0):
    """Un jeton de bois qui en touche un autre : très bref, mat."""
    t = temps(duree)
    y = np.sin(2 * np.pi * f * t) * np.exp(-t / (0.014 * sec))
    y += 0.42 * np.sin(2 * np.pi * 2.41 * f * t + 0.3) * np.exp(-t / (0.007 * sec))
    y += 0.38 * np.sin(2 * np.pi * 0.5 * f * t) * np.exp(-t / (0.024 * sec))
    contact = filtre(bruit(len(t)), bas=4200, haut=900) * np.exp(-t / 0.0022) * 0.45
    return fondu((y + contact) * force, 0.5, 25)


def souffle(duree, f_debut, f_fin, force=1.0):
    """Froissement d'air (page qu'on tourne, jetons qui glissent)."""
    n = int(FE * duree)
    u = np.linspace(0, 1, n)
    source = bruit(n)
    f_milieu = np.sqrt(f_debut * f_fin)
    bandes = [filtre(source, bas=f * 1.5, haut=f * 0.7) for f in (f_debut, f_milieu, f_fin)]
    y = bandes[0] * (1 - u) ** 2 + bandes[1] * 2 * u * (1 - u) + bandes[2] * u ** 2
    return fondu(y * np.sin(np.pi * u) ** 1.5 * force, 5, 40)


# Gamme pentatonique de do majeur : do ré mi sol la.
DO4, RE4, MI4, SOL4, LA4 = 60, 62, 64, 67, 69
DO5, RE5, MI5, SOL5, LA5, DO6, MI6 = 72, 74, 76, 79, 81, 84, 88


def arpege(notes, pas, force=1.0, cloche=0.0, duree=0.7, tenue=1.0):
    """Notes de marimba enchaînées, avec une pointe de clochette si demandé."""
    evenements = []
    for i, n in enumerate(notes):
        f = note(n)
        v = force * (0.85 + 0.15 * i / max(1, len(notes) - 1))
        evenements.append((i * pas, marimba(f, duree, v, tenue)))
        if cloche:
            evenements.append((i * pas, clochette(2 * f, duree * 1.2, v * cloche)))
    return melange(*evenements)


# -------------------------------------------------------------- bruitages


def bruitages():
    sons = {}

    # Jeton posé sur le plateau : cinq variantes, tirées au hasard en jeu.
    for i, f in enumerate([980, 1060, 1130, 1010, 1190]):
        sons[f"pose_{i + 1}"] = niveau(bois(f, sec=1.0 + 0.08 * (i % 3)), 0.50)

    # Jeton rendu au chevalet : plus grave, plus sourd. Trois variantes.
    for i, f in enumerate([640, 700, 600]):
        sons[f"retour_{i + 1}"] = niveau(bois(f, sec=1.25, duree=0.14), 0.42)

    # Jeton soulevé pour un glisser : à peine un effleurement.
    sons["saisie"] = niveau(bois(1500, sec=0.6, duree=0.06), 0.22)

    # Mélanger : une poignée de jetons qui s'entrechoquent.
    instants = np.cumsum(hasard.uniform(0.028, 0.055, 7))
    sons["melanger"] = niveau(melange(*[
        (t0, bois(hasard.uniform(620, 1250), force=1 - 0.09 * i, sec=hasard.uniform(0.9, 1.3)))
        for i, t0 in enumerate(instants)
    ]), 0.50)

    # Tout ramener : les jetons glissent, puis se rangent.
    sons["ramener"] = niveau(melange(
        (0.00, souffle(0.20, 2200, 900, 0.55)),
        (0.12, bois(720, 0.8, sec=1.2)),
        (0.17, bois(610, 0.9, sec=1.3)),
        (0.23, bois(560, 0.7, sec=1.3)),
    ), 0.44)

    # Choix d'une option (oui / non, nombre, niveau) et boutons.
    sons["choix"] = niveau(marimba(note(LA4), 0.22, tenue=0.45), 0.34)
    sons["bouton"] = niveau(marimba(note(DO5), 0.25, tenue=0.5), 0.34)

    # Indice : deux notes légères qui montent, comme une idée qui vient.
    sons["indice"] = niveau(reverb(melange(
        (0.00, marimba(note(MI5), 0.45, 0.8) + 0.25 * clochette(note(MI6), 0.45)),
        (0.11, marimba(note(LA5), 0.6, 0.9) + 0.30 * clochette(note(LA5 + 12), 0.6)),
    ), 0.5, 0.14), 0.46)

    # Indice refusé (pas assez de points) : une note sourde, sans reproche.
    sons["indice_refuse"] = niveau(marimba(note(SOL4), 0.3, tenue=0.45) + 0.5 * bois(520, sec=1.4, duree=0.3), 0.40)

    # Pari.
    sons["pari_juste"] = niveau(reverb(arpege([DO5, MI5, SOL5], 0.085, cloche=0.18, duree=0.55), 0.5, 0.14), 0.50)
    sons["pari_rate"] = niveau(reverb(arpege([MI5, DO5], 0.14, duree=0.45, tenue=0.8), 0.4, 0.10), 0.42)

    # Recherche.
    sons["mot_trouve"] = niveau(reverb(arpege([SOL4, DO5, MI5, SOL5], 0.075, cloche=0.25, duree=0.7), 0.7, 0.16), 0.54)
    final = melange(
        (0.00, arpege([DO5, MI5, SOL5, DO6, MI6], 0.085, cloche=0.28, duree=0.9, tenue=1.2)),
        (0.46, sum(marimba(note(n), 1.1, 0.42, 1.6) for n in (DO5, MI5, SOL5, DO6))),
        (0.46, 0.20 * clochette(note(DO6 + 12), 1.1)),
    )
    sons["toutes_trouvees"] = niveau(reverb(final, 0.9, 0.18), 0.56)
    # Mot refusé : deux petits coups de bois graves. Jamais de buzzer.
    sons["mot_refuse"] = niveau(melange(
        (0.00, bois(430, sec=1.6, duree=0.16)),
        (0.105, bois(380, 0.85, sec=1.6, duree=0.16)),
    ), 0.44)
    # Mot de départ ou déjà trouvé : un seul coup, neutre.
    sons["mot_neutre"] = niveau(bois(540, sec=1.5, duree=0.15), 0.36)

    # Chrono : tic discret des dernières secondes, puis fin du temps.
    sons["tic"] = niveau(bois(1700, sec=0.55, duree=0.05), 0.20)
    sons["temps_ecoule"] = niveau(reverb(arpege([SOL5, MI5, DO5], 0.16, duree=0.7, tenue=1.1), 0.6, 0.14), 0.46)

    # Déroulement de la partie.
    sons["reponses"] = niveau(melange(
        (0.00, souffle(0.30, 2600, 1100, 0.6)),
        (0.16, marimba(note(RE5), 0.4, 0.5, 0.7)),
    ), 0.38)
    sons["suivant"] = niveau(melange(
        (0.00, souffle(0.26, 1500, 2600, 0.55)),
        (0.12, marimba(note(SOL4), 0.35, 0.6, 0.7)),
        (0.20, marimba(note(DO5), 0.45, 0.7, 0.8)),
    ), 0.40)
    sons["debut"] = niveau(reverb(arpege([SOL4, DO5, RE5, SOL5], 0.09, cloche=0.15, duree=0.7), 0.7, 0.16), 0.50)
    bilan = melange(*[
        (i * 0.13, marimba(note(n), 1.3, 0.75, 1.5) + 0.12 * clochette(note(n + 12), 1.3))
        for i, n in enumerate([SOL4, DO5, RE5, MI5, SOL5])
    ])
    sons["bilan"] = niveau(reverb(bilan, 1.0, 0.20), 0.50)
    record = melange(
        (0.00, arpege([DO5, MI5, SOL5, DO6], 0.09, cloche=0.3, duree=0.8)),
        (0.42, arpege([RE5, SOL5, DO6, MI6], 0.09, cloche=0.35, duree=1.1, tenue=1.4)),
        (0.78, sum(marimba(note(n), 1.3, 0.4, 1.7) for n in (DO5, SOL5, DO6, MI6))),
    )
    sons["record"] = niveau(reverb(record, 1.1, 0.20), 0.56)
    sons["quitter"] = niveau(melange(
        (0.00, marimba(note(SOL5), 0.35, 0.6, 0.7)),
        (0.10, marimba(note(DO5), 0.45, 0.6, 0.8)),
    ), 0.34)
    return sons


# ---------------------------------------------------------------- musique

TEMPO = 66
TEMPS = 60 / TEMPO
MESURE = 4 * TEMPS
MESURES = 24

# Quatre accords de deux mesures, joués trois fois : do maj9, la m9, fa maj9, sol 6 sus.
ACCORDS = [
    [36, 48, 55, 64, 71, 74],
    [33, 45, 52, 60, 67, 71],
    [29, 41, 48, 57, 64, 67],
    [31, 43, 50, 57, 60, 64],
]
PENTA = [72, 74, 76, 79, 81, 84]


def piano_feutre(f, duree=2.6, force=1.0):
    """Piano électrique très rond (modulation de fréquence légère)."""
    t = temps(duree)
    indice = 0.95 * force * np.exp(-t / 0.35)
    y = np.sin(2 * np.pi * f * t + indice * np.sin(2 * np.pi * f * t))
    y += 0.05 * np.sin(2 * np.pi * 7 * f * t) * np.exp(-t / 0.05)
    y *= np.exp(-t / 1.15) * (1 - np.exp(-t / 0.004))
    return fondu(y * force, 2, 120)


def nappe(f, duree, attaque=1.6, relache=2.2):
    """Tenue de cordes très lointaine : trois sinus à peine désaccordés."""
    t = temps(duree + relache)
    y = sum(np.sin(2 * np.pi * f * (1 + d) * t + p)
            for d, p in ((-0.0017, 0.0), (0.0, 1.3), (0.0019, 2.1)))
    y += 0.18 * np.sin(2 * np.pi * 2 * f * t)
    enveloppe = np.ones_like(t)
    a, r = int(FE * attaque), int(FE * relache)
    enveloppe[:a] = 0.5 - 0.5 * np.cos(np.pi * np.linspace(0, 1, a))
    enveloppe[-r:] = 0.5 + 0.5 * np.cos(np.pi * np.linspace(0, 1, r))
    return y * enveloppe / 3


def basse(f, duree):
    t = temps(duree)
    y = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) + 0.12 * np.sin(2 * np.pi * 3 * f * t)
    return fondu(y * np.exp(-t / 3.2) * (1 - np.exp(-t / 0.05)), 5, 400)


def musique():
    """Une boucle calme : nappe, piano feutré clairsemé, quelques notes de marimba.

    Elle respire : la fin s'éteint jusqu'au silence et le début entre en
    douceur, si bien que le point de bouclage ne s'entend pas.
    """
    alea = np.random.default_rng(11)
    duree = MESURES * MESURE
    n = int(FE * duree) + FE * 4
    gauche, droite = np.zeros(n), np.zeros(n)

    def placer(y, instant, gain=1.0, pan=0.5):
        i = int(max(0.0, instant) * FE)
        y = y[: n - i]
        gauche[i:i + len(y)] += y * gain * np.cos(pan * np.pi / 2)
        droite[i:i + len(y)] += y * gain * np.sin(pan * np.pi / 2)

    probabilites = [0.92, 0.22, 0.48, 0.52, 0.62, 0.28, 0.5, 0.32]
    precedente = 2
    melodie = 2

    for m in range(MESURES):
        accord = ACCORDS[(m // 2) % 4]
        debut = m * MESURE
        # Densité : entrée et sortie dépouillées, cœur un peu plus habité.
        densite = 0.45 if m < 2 else (0.25 if m >= MESURES - 1 else (0.6 if m >= MESURES - 2 else 1.0))

        if m % 2 == 0:
            for v, midi in enumerate(accord[2:]):
                placer(nappe(note(midi + (12 if v == 0 else 0)), 2 * MESURE), debut - 0.4, 0.042, 0.3 + 0.4 * (v % 2))
            placer(basse(note(accord[0] + 12), 2 * MESURE), debut, 0.04, 0.5)

        hauteurs = accord[3:] + [accord[2] + 12, accord[3] + 12, accord[4] + 12]
        for k, p in enumerate(probabilites):
            if alea.random() > p * densite:
                continue
            precedente = int(np.clip(precedente + alea.integers(-2, 3), 0, len(hauteurs) - 1))
            force = (0.62 if k == 0 else 0.42) + alea.uniform(-0.08, 0.08)
            instant = debut + k * TEMPS / 2 + alea.uniform(-0.008, 0.008)
            placer(piano_feutre(note(hauteurs[precedente]), force=force), instant, 0.115, alea.uniform(0.35, 0.65))

        # Une petite phrase de marimba toutes les deux mesures, pas toujours.
        if m % 2 == 1 and 2 <= m < MESURES - 2 and alea.random() < 0.8:
            instant = debut + alea.choice([0.0, 0.5, 1.0]) * TEMPS
            for _ in range(int(alea.integers(3, 6))):
                melodie = int(np.clip(melodie + alea.choice([-2, -1, -1, 1, 1, 2]), 0, len(PENTA) - 1))
                f = note(PENTA[melodie])
                son = marimba(f, 1.4, 1.0, 1.8) + 0.10 * clochette(2 * f, 1.4)
                placer(son, instant, 0.075 + alea.uniform(0, 0.02), alea.uniform(0.25, 0.75))
                instant += alea.choice([0.5, 1.0, 1.0, 1.5]) * TEMPS
                if instant > debut + MESURE * 1.9:
                    break

    stereo = np.stack([gauche, droite], axis=1)

    # Réverbération ample, différente à gauche et à droite.
    longueur = int(FE * 2.4)
    t = temps(2.4)
    queue = np.stack([filtre(bruit(longueur) * np.exp(-t * 6.9 / 2.4), bas=3800, haut=220) for _ in range(2)], axis=1)
    queue /= np.sqrt(np.sum(queue ** 2, axis=0))
    taille = 1 << (n + longueur - 1).bit_length()
    humide = np.fft.irfft(np.fft.rfft(stereo, taille, axis=0) * np.fft.rfft(queue, taille, axis=0), taille, axis=0)[:n]
    stereo = filtre(stereo + 0.30 * humide, bas=8500, haut=70)

    # Bouclage : on coupe à la longueur exacte, avec entrée et sortie en fondu.
    total = int(FE * duree)
    stereo = stereo[:total]
    entree, sortie = int(FE * 0.6), int(FE * 5.0)
    stereo[:entree] *= (0.5 - 0.5 * np.cos(np.pi * np.linspace(0, 1, entree)))[:, None]
    stereo[-sortie:] *= (0.5 + 0.5 * np.cos(np.pi * np.linspace(0, 1, sortie)))[:, None]

    # Niveau discret : c'est un fond sonore.
    efficace = np.sqrt(np.mean(stereo ** 2))
    gain = min(10 ** (-19 / 20) / efficace, 10 ** (-3 / 20) / np.max(np.abs(stereo)))
    return stereo * gain


# ---------------------------------------------------------------- fichiers


def ecrire_wav(chemin, x):
    x = np.clip(x, -1, 1)
    canaux = 1 if x.ndim == 1 else x.shape[1]
    with wave.open(str(chemin), "wb") as f:
        f.setnchannels(canaux)
        f.setsampwidth(2)
        f.setframerate(FE)
        f.writeframes((x * 32767).astype("<i2").tobytes())


def encoder_aac(wav, m4a):
    if shutil.which("afconvert"):
        commande = ["afconvert", "-f", "m4af", "-d", "aac", "-b", "112000", "-q", "127", str(wav), str(m4a)]
    elif shutil.which("ffmpeg"):
        commande = ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "aac", "-b:a", "112k", str(m4a)]
    else:
        raise SystemExit("Ni afconvert ni ffmpeg : impossible d'encoder la musique.")
    subprocess.run(commande, check=True)


def main():
    SORTIE.mkdir(parents=True, exist_ok=True)
    for ancien in SORTIE.glob("*.wav"):
        ancien.unlink()

    for nom, signal in bruitages().items():
        # Un souffle de silence en fin de fichier : le son n'est jamais tronqué.
        signal = np.concatenate([fondu(signal, 0.5, 15), np.zeros(int(FE * 0.02))])
        ecrire_wav(SORTIE / f"{nom}.wav", signal)
        print(f"  {nom:16s} {len(signal) / FE:5.2f} s  crête {np.max(np.abs(signal)):.2f}")

    piste = musique()
    provisoire = SORTIE / "_musique.wav"
    ecrire_wav(provisoire, piste)
    encoder_aac(provisoire, SORTIE / "musique.m4a")
    provisoire.unlink()
    efficace = 20 * np.log10(np.sqrt(np.mean(piste ** 2)))
    print(f"  musique.m4a      {len(piste) / FE:5.1f} s  niveau moyen {efficace:.1f} dBFS")
    print("Sons écrits dans", SORTIE)


if __name__ == "__main__":
    main()
