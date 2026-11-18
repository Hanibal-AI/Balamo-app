#!/usr/bin/env python3
"""Dessine l'icône de Balamo : un jeton en hêtre marqué « B ».

Produit dans assets/icone/ :
  - icone.png            icône complète (iOS, anciens Android)
  - icone_avant.png      jeton seul sur fond transparent (icône adaptative Android)

Usage (Pillow requis : `pip install pillow`) :
    python3 tool/generer_icone.py
    dart run flutter_launcher_icons      # décline toutes les tailles
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "assets" / "icone"
POLICE = RACINE / "assets" / "fonts" / "Archivo.ttf"

TAILLE = 1024
SUR = 3  # suréchantillonnage, pour des bords lisses

ENCRE = (28, 34, 56)          # fond : l'encre noire-bleue de l'application
ENCRE_HAUT = (44, 52, 86)
BOIS_CLAIR = (243, 223, 180)
BOIS = (232, 207, 156)
BOIS_FONCE = (220, 191, 134)
BOIS_BORD = (184, 149, 90)
BOIS_ENCRE = (43, 29, 12)


def police(taille: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(POLICE), taille)
    try:  # police variable : graisse 800, largeur normale
        axes = [a["name"] if isinstance(a["name"], str) else a["name"].decode() for a in f.get_variation_axes()]
        valeurs = {"Weight": 800, "Width": 100}
        f.set_variation_by_axes([valeurs.get(nom, 100) for nom in axes])
    except Exception:
        pass
    return f


def degrade(taille, haut, bas, angle_x=0.0):
    """Dégradé linéaire du coin haut-gauche vers le bas (légèrement en biais)."""
    w, h = taille
    img = Image.new("RGB", taille)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (y / h) * (1 - angle_x) + (x / w) * angle_x
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(haut, bas))
    return img


def jeton(cote: int) -> Image.Image:
    """Le jeton seul, sur fond transparent, avec sa tranche et son ombre."""
    s = cote * SUR
    marge = round(s * 0.10)
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    corps = (marge, marge, s - marge, s - marge - round(s * 0.05))
    rayon = round(s * 0.11)
    epaisseur = round(s * 0.055)

    # Ombre portée.
    ombre = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(ombre).rounded_rectangle(
        (corps[0], corps[1] + epaisseur * 2, corps[2], corps[3] + epaisseur * 2),
        rayon, fill=(10, 6, 0, 120))
    img.alpha_composite(ombre.filter(ImageFilter.GaussianBlur(s * 0.03)))

    # Tranche du jeton.
    ImageDraw.Draw(img).rounded_rectangle(
        (corps[0], corps[1] + epaisseur, corps[2], corps[3] + epaisseur), rayon, fill=BOIS_BORD)

    # Face : dégradé de hêtre, découpé en rectangle arrondi.
    face = degrade((corps[2] - corps[0], corps[3] - corps[1]), BOIS_CLAIR, BOIS_FONCE, angle_x=0.35)
    masque = Image.new("L", face.size, 0)
    ImageDraw.Draw(masque).rounded_rectangle((0, 0, face.size[0] - 1, face.size[1] - 1), rayon, fill=255)
    img.paste(face, (corps[0], corps[1]), masque)

    d = ImageDraw.Draw(img)
    cx = (corps[0] + corps[2]) / 2
    cy = (corps[1] + corps[3]) / 2
    d.text((cx - s * 0.02, cy - s * 0.01), "B", font=police(round(s * 0.50)), fill=BOIS_ENCRE, anchor="mm")
    d.text((corps[2] - s * 0.075, corps[3] - s * 0.06), "3", font=police(round(s * 0.13)),
           fill=BOIS_ENCRE, anchor="rs")
    return img.resize((cote, cote), Image.Resampling.LANCZOS)


def main() -> None:
    SORTIE.mkdir(parents=True, exist_ok=True)

    # Icône adaptative : flutter_launcher_icons réduit déjà cette image de 16 %
    # sur chaque bord ; à 70 %, le jeton occupe la zone sûre sans être rogné
    # par les masques ronds des lanceurs.
    avant = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
    j = jeton(round(TAILLE * 0.70)).rotate(-6, resample=Image.Resampling.BICUBIC, expand=True)
    avant.alpha_composite(j, ((TAILLE - j.width) // 2, (TAILLE - j.height) // 2))
    avant.save(SORTIE / "icone_avant.png")

    # Icône complète, sans transparence (exigé par iOS).
    fond = degrade((TAILLE // 4, TAILLE // 4), ENCRE_HAUT, ENCRE).resize((TAILLE, TAILLE), Image.Resampling.BICUBIC)
    complete = fond.convert("RGBA")
    j = jeton(round(TAILLE * 0.74)).rotate(-6, resample=Image.Resampling.BICUBIC, expand=True)
    complete.alpha_composite(j, ((TAILLE - j.width) // 2, (TAILLE - j.height) // 2))
    complete.convert("RGB").save(SORTIE / "icone.png")
    print("Icônes écrites dans", SORTIE)


if __name__ == "__main__":
    main()
