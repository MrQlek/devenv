from manim import *

from common import title


class Intro(Scene):
    def construct(self):
        heading = title("Pythagorean theorem")
        subtitle = Text("a quick visual", font_size=32).next_to(heading, DOWN)

        self.play(Write(heading))
        self.play(FadeIn(subtitle))
        self.wait()
        self.play(FadeOut(heading, subtitle))
