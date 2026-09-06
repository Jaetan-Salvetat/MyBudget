"""Remise d'aplomb d'une photo de ticket avant structuration.

Un ticket long se photographie naturellement en paysage : plus de la moitié
du corpus réel a son texte à ±90°. Le clustering en lignes physiques
raisonne en recouvrement vertical et n'a aucun sens avant d'avoir retiré ce
quart de tour. On le retire ici, sur l'image, avant le second OCR — le
pipeline en aval ne voit qu'un ticket droit.
"""

from __future__ import annotations

QUARTER_TURN = 90
FULL_TURN = 360


def median_line_angle(dump: dict) -> float | None:
    """Inclinaison dominante du texte, en degrés, repère image."""
    angles = sorted(
        line["angle"]
        for block in dump["blocks"]
        for line in block["lines"]
        if line.get("angle") is not None
    )
    return angles[len(angles) // 2] if angles else None


def page_quadrant(angle_degrees: float) -> int:
    """Le quart de tour dont la page est tournée : 0, 90, 180 ou 270."""
    return round(angle_degrees / QUARTER_TURN) * QUARTER_TURN % FULL_TURN


def upright_rotation(dump: dict) -> int:
    """Rotation à appliquer à l'image, en degrés antihoraires, pour remettre
    son texte à l'horizontale. Zéro quand la page est déjà droite."""
    angle = median_line_angle(dump)
    if angle is None:
        return 0
    return (FULL_TURN - page_quadrant(angle)) % FULL_TURN
