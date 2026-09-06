"""OCR local de référence pour la recherche : Apple Vision (VNRecognizeTextRequest).

Le device tourne sous ML Kit ; ici on a besoin d'un moteur de qualité
comparable exécutable sur le Mac, pour itérer sur la structuration sans
rebrancher un téléphone. La sortie épouse exactement le format des dumps
device (`blocks[].lines[].elements[]`, boîtes en pixels image) : le même
`clustered_lines()` la relit sans le savoir.
"""

from __future__ import annotations

import math

import Quartz
import Vision
from Foundation import NSURL, NSRange

# pyobjc résout ses symboles à la première utilisation, et cette résolution
# n'est pas sûre en multithread : on la force au chargement du module.
CG_IMAGE_SOURCE_CREATE_WITH_URL = Quartz.CGImageSourceCreateWithURL
CG_IMAGE_SOURCE_CREATE_IMAGE = Quartz.CGImageSourceCreateImageAtIndex
CG_IMAGE_SOURCE_COPY_PROPERTIES = Quartz.CGImageSourceCopyPropertiesAtIndex
CG_IMAGE_GET_WIDTH = Quartz.CGImageGetWidth
CG_IMAGE_GET_HEIGHT = Quartz.CGImageGetHeight

RECOGNITION_LANGUAGES = ["fr-FR", "en-US"]
EXIF_TO_CGIMAGE_PROPERTY_ORIENTATION = {
    1: Quartz.kCGImagePropertyOrientationUp,
    2: Quartz.kCGImagePropertyOrientationUpMirrored,
    3: Quartz.kCGImagePropertyOrientationDown,
    4: Quartz.kCGImagePropertyOrientationDownMirrored,
    5: Quartz.kCGImagePropertyOrientationLeftMirrored,
    6: Quartz.kCGImagePropertyOrientationRight,
    7: Quartz.kCGImagePropertyOrientationRightMirrored,
    8: Quartz.kCGImagePropertyOrientationLeft,
}
UPRIGHT_ORIENTATIONS = (1, 2, 3, 4)


class OcrError(RuntimeError):
    pass


def _image_source(path: str):
    source = CG_IMAGE_SOURCE_CREATE_WITH_URL(NSURL.fileURLWithPath_(path), None)
    if source is None:
        raise OcrError(f"image illisible : {path}")
    return source


def _exif_orientation(source) -> int:
    properties = CG_IMAGE_SOURCE_COPY_PROPERTIES(source, 0, None) or {}
    return int(properties.get(Quartz.kCGImagePropertyOrientation, 1))


def _observations(image, orientation: int) -> list:
    request = Vision.VNRecognizeTextRequest.alloc().init()
    request.setRecognitionLevel_(Vision.VNRequestTextRecognitionLevelAccurate)
    request.setRecognitionLanguages_(RECOGNITION_LANGUAGES)
    request.setUsesLanguageCorrection_(False)
    handler = Vision.VNImageRequestHandler.alloc().initWithCGImage_orientation_options_(
        image, EXIF_TO_CGIMAGE_PROPERTY_ORIENTATION[orientation], None
    )
    ok, error = handler.performRequests_error_([request], None)
    if not ok:
        raise OcrError(f"Vision a échoué : {error}")
    return list(request.results() or [])


def _pixel_point(point, width: int, height: int) -> list[float]:
    return [round(point.x * width, 1), round((1.0 - point.y) * height, 1)]


def _pixel_corners(observation, width: int, height: int) -> list[list[float]]:
    """Le quadrilatère réel de Vision, dans l'ordre ML Kit : haut-gauche,
    haut-droit, bas-droit, bas-gauche."""
    return [
        _pixel_point(corner, width, height)
        for corner in (
            observation.topLeft(),
            observation.topRight(),
            observation.bottomRight(),
            observation.bottomLeft(),
        )
    ]


def _bounding_box(corners: list[list[float]]) -> list[float]:
    xs = [x for x, _ in corners]
    ys = [y for _, y in corners]
    return [round(min(xs), 1), round(min(ys), 1), round(max(xs), 1), round(max(ys), 1)]


def _angle_degrees(corners: list[list[float]]) -> float:
    """Inclinaison du bord supérieur, en degrés, repère image (y vers le bas)
    — la convention de `TextLine.angle` de ML Kit."""
    (left_x, left_y), (right_x, right_y) = corners[0], corners[1]
    return round(math.degrees(math.atan2(right_y - left_y, right_x - left_x)), 4)


def _word_boxes(candidate, text: str, width: int, height: int) -> list[dict]:
    words = []
    offset = 0
    for token in text.split(" "):
        if token:
            located = candidate.boundingBoxForRange_error_(
                NSRange(offset, len(token)), None
            )
            rectangle = located[0] if isinstance(located, tuple) else located
            if rectangle is not None:
                corners = _pixel_corners(rectangle, width, height)
                words.append(
                    {
                        "text": token,
                        "corners": corners,
                        "box": _bounding_box(corners),
                        "angle": _angle_degrees(corners),
                    }
                )
        offset += len(token) + 1
    return words


def _element(word: dict, confidence: float) -> dict:
    return {
        "text": word["text"],
        "box": word["box"],
        "corners": word["corners"],
        "confidence": confidence,
        "angle": word["angle"],
        "symbols": [],
    }


def recognize(path: str) -> dict:
    """Un dump OCR au format device pour l'image donnée."""
    source = _image_source(path)
    image = CG_IMAGE_SOURCE_CREATE_IMAGE(source, 0, None)
    if image is None:
        raise OcrError(f"image indécodable : {path}")
    orientation = _exif_orientation(source)
    stored_width = CG_IMAGE_GET_WIDTH(image)
    stored_height = CG_IMAGE_GET_HEIGHT(image)
    width, height = (
        (stored_width, stored_height)
        if orientation in UPRIGHT_ORIENTATIONS
        else (stored_height, stored_width)
    )

    blocks = []
    for observation in _observations(image, orientation):
        candidates = observation.topCandidates_(1)
        if not candidates:
            continue
        candidate = candidates[0]
        text = candidate.string()
        confidence = float(candidate.confidence())
        elements = [
            _element(word, confidence)
            for word in _word_boxes(candidate, text, width, height)
        ]
        if not elements:
            continue
        corners = _pixel_corners(observation, width, height)
        box = _bounding_box(corners)
        line = {
            "text": text,
            "box": box,
            "corners": corners,
            "confidence": confidence,
            "angle": _angle_degrees(corners),
            "elements": elements,
        }
        blocks.append(
            {
                "text": text,
                "box": box,
                "corners": corners,
                "languages": ["und"],
                "lines": [line],
            }
        )

    blocks.sort(key=lambda block: (block["box"][1], block["box"][0]))
    return {
        "image": path.rsplit("/", 1)[-1],
        "imageWidth": width,
        "imageHeight": height,
        "lineCount": len(blocks),
        "fullText": "\n".join(block["text"] for block in blocks),
        "blocks": blocks,
    }
