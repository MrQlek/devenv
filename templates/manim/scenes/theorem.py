from manim import *

from common import title


class Theorem(Scene):
    def construct(self):
        heading = title("Pythagorean theorem")
        formula = MathTex(r"a^2 + b^2 = c^2").scale(1.5)
        triangle = Polygon(ORIGIN, 3 * RIGHT, 3 * RIGHT + 2 * UP, color=BLUE)
        triangle.next_to(formula, DOWN, buff=0.75)

        self.play(FadeIn(heading))
        self.play(Write(formula))
        self.play(Create(triangle))
        self.wait()
