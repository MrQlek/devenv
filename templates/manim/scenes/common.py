"""Shared helpers for scenes. Import with `from common import ...` — manim puts the scene file's directory on sys.path."""

from manim import *

TITLE_COLOR = YELLOW


def title(text: str) -> Text:
    return Text(text, color=TITLE_COLOR).to_edge(UP)
