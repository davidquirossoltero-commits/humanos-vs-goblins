#!/usr/bin/env python3
"""Arte original de fútbol fantástico. No usa material de Blood Bowl ni de Games Workshop."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "art"
INK = (22, 16, 12, 255)
SKIN = (232, 186, 150, 255)
SKIN_D = (196, 142, 108, 255)
GREEN = (58, 168, 52, 255)
GREEN_D = (32, 112, 36, 255)
JERSEY = (18, 58, 140, 255)
JERSEY_D = (10, 36, 96, 255)
GOLD = (226, 176, 58, 255)
GOLD_D = (168, 118, 28, 255)
STEEL = (214, 220, 228, 255)
STEEL_D = (120, 130, 142, 255)
RED = (186, 42, 40, 255)
BLACK = (18, 16, 18, 255)
WHITE = (248, 244, 236, 255)


def new(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def ellipse(draw, box, fill, outline=INK, width=7):
    if outline and width:
        draw.ellipse(box, fill=outline)
        inset = width
        inner = (box[0] + inset, box[1] + inset, box[2] - inset, box[3] - inset)
        if inner[2] > inner[0] and inner[3] > inner[1]:
            draw.ellipse(inner, fill=fill)
    else:
        draw.ellipse(box, fill=fill)


def poly(draw, pts, fill, outline=INK, width=6):
    if outline and width:
        draw.line(pts + [pts[0]], fill=outline, width=width + 4, joint="curve")
    draw.polygon(pts, fill=fill)
    if outline and width:
        draw.line(pts + [pts[0]], fill=outline, width=width, joint="curve")


def shadow(draw, cx, cy, rx, ry):
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(0, 0, 0, 70))


def eye(draw, x, y, r, pupil=(24, 18, 12, 255)):
    ellipse(draw, (x - r, y - r, x + r, y + r), WHITE, INK, 4)
    draw.ellipse((x - r * 0.35, y - r * 0.2, x + r * 0.45, y + r * 0.55), fill=pupil)
    draw.ellipse((x - r * 0.45, y - r * 0.55, x - r * 0.05, y - r * 0.15), fill=(255, 255, 255, 230))


def helmet(draw, cx, cy, rw, rh, stripe=GOLD):
    ellipse(draw, (cx - rw, cy - rh, cx + rw, cy + rh * 0.85), STEEL, INK, 7)
    ellipse(draw, (cx - rw * 0.55, cy - rh * 0.95, cx + rw * 0.55, cy - rh * 0.15), stripe, None, 0)
    # máscara
    for i, dx in enumerate((-0.45, 0.0, 0.45)):
        x = cx + rw * dx
        draw.line((x, cy - rh * 0.05, x - rw * 0.08, cy + rh * 0.72), fill=STEEL_D, width=5)
    draw.arc((cx - rw * 0.8, cy - rh * 0.1, cx + rw * 0.8, cy + rh * 0.95), 20, 160, fill=INK, width=5)


def jersey(draw, cx, cy, w, h, color, dark, number=None):
    body = [
        (cx - w, cy - h * 0.2),
        (cx - w * 0.72, cy - h),
        (cx + w * 0.72, cy - h),
        (cx + w, cy - h * 0.2),
        (cx + w * 0.78, cy + h),
        (cx - w * 0.78, cy + h),
    ]
    poly(draw, body, color, INK, 7)
    draw.polygon(
        [
            (cx - w * 0.35, cy - h * 0.15),
            (cx, cy + h * 0.55),
            (cx + w * 0.35, cy - h * 0.15),
        ],
        fill=dark,
    )
    if number:
        draw.text((cx - 10, cy - 8), str(number), fill=GOLD)


def boots(draw, x, y, scale=1.0):
    s = scale
    ellipse(draw, (x - 16 * s, y - 8 * s, x + 22 * s, y + 10 * s), (40, 36, 34, 255), INK, 4)


def football(draw, x, y, s=1.0):
    ellipse(draw, (x - 18 * s, y - 12 * s, x + 18 * s, y + 12 * s), (122, 62, 36, 255), INK, 4)
    draw.line((x - 6 * s, y - 8 * s, x + 2 * s, y + 8 * s), fill=WHITE, width=3)
    draw.line((x + 6 * s, y - 8 * s, x - 2 * s, y + 8 * s), fill=WHITE, width=3)


def spikes(draw, x, y, color=RED):
    poly(draw, [(x, y - 18), (x + 10, y + 4), (x - 10, y + 4)], color, INK, 4)


def human_player(kind: str) -> Image.Image:
    image, draw = new(384, 420)
    cx, cy = 192, 230
    shadow(draw, cx, 360, 70, 18)
    # piernas
    ellipse(draw, (cx - 48, cy + 40, cx - 12, cy + 130), JERSEY, INK, 5)
    ellipse(draw, (cx + 12, cy + 40, cx + 48, cy + 130), JERSEY, INK, 5)
    boots(draw, cx - 28, cy + 128)
    boots(draw, cx + 24, cy + 128)
    jersey(draw, cx, cy + 10, 78, 70, JERSEY, JERSEY_D)
    # hombreras
    ellipse(draw, (cx - 108, cy - 70, cx - 28, cy - 10), GOLD, INK, 6)
    ellipse(draw, (cx + 28, cy - 70, cx + 108, cy - 10), GOLD, INK, 6)
    # brazos
    ellipse(draw, (cx - 120, cy - 20, cx - 70, cy + 70), SKIN, INK, 5)
    ellipse(draw, (cx + 70, cy - 20, cx + 120, cy + 70), SKIN, INK, 5)
    helmet(draw, cx, cy - 108, 62, 58)
    eye(draw, cx - 22, cy - 96, 12)
    eye(draw, cx + 22, cy - 96, 12)
    if kind == "arquero":
        # arco
        draw.arc((cx + 20, cy - 40, cx + 130, cy + 90), 280, 80, fill=(92, 58, 32, 255), width=8)
        draw.line((cx + 70, cy - 30, cx + 120, cy + 10), fill=GOLD, width=4)
    elif kind == "mago":
        ellipse(draw, (cx - 70, cy - 150, cx + 70, cy - 40), (92, 48, 150, 255), INK, 6)
        draw.polygon([(cx - 16, cy - 150), (cx + 16, cy - 150), (cx, cy - 210)], fill=(92, 48, 150, 255))
        draw.line((cx + 90, cy - 10, cx + 150, cy - 120), fill=(92, 58, 32, 255), width=8)
        ellipse(draw, (cx + 132, cy - 150, cx + 176, cy - 106), GOLD, INK, 5)
        draw.ellipse((cx + 146, cy - 136, cx + 162, cy - 120), fill=WHITE)
    return image


def canon() -> Image.Image:
    image, draw = new(420, 280)
    shadow(draw, 210, 210, 120, 22)
    # ruedas
    ellipse(draw, (40, 150, 130, 240), (48, 40, 36, 255), INK, 7)
    ellipse(draw, (270, 150, 360, 240), (48, 40, 36, 255), INK, 7)
    ellipse(draw, (62, 172, 108, 218), GOLD_D, None, 0)
    ellipse(draw, (292, 172, 338, 218), GOLD_D, None, 0)
    # caja
    draw.rounded_rectangle((90, 90, 300, 180), 12, fill=(90, 58, 36, 255), outline=INK, width=7)
    # cañón
    draw.rounded_rectangle((180, 70, 390, 130), 18, fill=STEEL_D, outline=INK, width=7)
    draw.ellipse((360, 78, 404, 122), fill=(40, 44, 48, 255))
    draw.line((200, 82, 370, 82), fill=STEEL, width=4)
    spikes(draw, 150, 70, RED)
    football(draw, 250, 55, 0.8)
    return image


def goblin(armored=False, fury=False, number=13) -> Image.Image:
    image, draw = new(360, 400)
    cx, cy = 180, 210
    skin = (196, 70, 64, 255) if fury else GREEN
    skin_d = (140, 40, 38, 255) if fury else GREEN_D
    shadow(draw, cx, 340, 70, 16)
    ellipse(draw, (cx - 36, cy + 30, cx - 8, cy + 120), BLACK, INK, 5)
    ellipse(draw, (cx + 8, cy + 30, cx + 36, cy + 120), BLACK, INK, 5)
    boots(draw, cx - 22, cy + 118, 0.8)
    boots(draw, cx + 18, cy + 118, 0.8)
    jersey(draw, cx, cy + 6, 70, 64, BLACK, (40, 16, 16, 255))
    draw.rectangle((cx - 28, cy - 8, cx + 28, cy + 36), fill=RED)
    spikes(draw, cx - 78, cy - 46)
    spikes(draw, cx + 78, cy - 46)
    # orejas
    poly(draw, [(cx - 70, cy - 90), (cx - 120, cy - 150), (cx - 40, cy - 70)], skin, INK, 5)
    poly(draw, [(cx + 70, cy - 90), (cx + 120, cy - 150), (cx + 40, cy - 70)], skin, INK, 5)
    ellipse(draw, (cx - 58, cy - 130, cx + 58, cy - 20), skin, INK, 7)
    ellipse(draw, (cx - 34, cy - 78, cx + 34, cy - 28), skin_d, None, 0)
    eye(draw, cx - 20, cy - 86, 13, (240, 210, 40, 255))
    eye(draw, cx + 20, cy - 86, 13, (240, 210, 40, 255))
    draw.arc((cx - 22, cy - 58, cx + 22, cy - 34), 20, 160, fill=INK, width=4)
    # dientes
    draw.polygon([(cx - 10, cy - 52), (cx - 4, cy - 36), (cx - 16, cy - 36)], fill=WHITE)
    draw.polygon([(cx + 10, cy - 52), (cx + 4, cy - 36), (cx + 16, cy - 36)], fill=WHITE)
    if armored:
        ellipse(draw, (cx - 70, cy - 150, cx + 70, cy - 10), STEEL_D, INK, 7)
        spikes(draw, cx - 20, cy - 150, STEEL)
        spikes(draw, cx + 20, cy - 150, STEEL)
        eye(draw, cx - 18, cy - 80, 10, (240, 210, 40, 255))
        eye(draw, cx + 18, cy - 80, 10, (240, 210, 40, 255))
    football(draw, cx + 62, cy + 20, 0.9)
    return image


def hobgoblin() -> Image.Image:
    image = goblin()
    draw = ImageDraw.Draw(image)
    # maza
    draw.line((250, 80, 320, 200), fill=(92, 58, 32, 255), width=12)
    ellipse(draw, (286, 176, 346, 236), STEEL_D, INK, 6)
    return image


def jinete() -> Image.Image:
    image, draw = new(460, 360)
    shadow(draw, 230, 280, 140, 22)
    # jabalí
    ellipse(draw, (70, 150, 390, 290), (176, 96, 52, 255), INK, 8)
    ellipse(draw, (300, 170, 430, 270), (150, 78, 42, 255), INK, 7)
    ellipse(draw, (390, 200, 430, 230), WHITE, INK, 3)
    eye(draw, 360, 200, 10, (40, 20, 16, 255))
    ellipse(draw, (80, 230, 130, 310), (120, 64, 36, 255), INK, 5)
    ellipse(draw, (250, 230, 300, 310), (120, 64, 36, 255), INK, 5)
    rider = goblin().resize((200, 222), Image.Resampling.LANCZOS)
    image.alpha_composite(rider, (120, 20))
    return image


def ogre(armored: bool) -> Image.Image:
    image, draw = new(420, 460)
    cx, cy = 210, 240
    shadow(draw, cx, 400, 100, 20)
    ellipse(draw, (cx - 50, cy + 40, cx - 10, cy + 160), GREEN_D, INK, 6)
    ellipse(draw, (cx + 10, cy + 40, cx + 50, cy + 160), GREEN_D, INK, 6)
    boots(draw, cx - 30, cy + 160, 1.3)
    boots(draw, cx + 28, cy + 160, 1.3)
    jersey(draw, cx, cy + 10, 110, 90, (36, 40, 36, 255), (16, 18, 16, 255))
    ellipse(draw, (cx - 150, cy - 40, cx - 40, cy + 80), GREEN, INK, 7)
    ellipse(draw, (cx + 40, cy - 40, cx + 150, cy + 80), GREEN, INK, 7)
    if armored:
        ellipse(draw, (cx - 90, cy - 170, cx + 90, cy + 10), STEEL, INK, 8)
        spikes(draw, cx - 40, cy - 170, RED)
        spikes(draw, cx + 40, cy - 170, RED)
        draw.rectangle((cx - 70, cy - 80, cx + 70, cy - 58), fill=INK)
        eye(draw, cx - 28, cy - 90, 12, (240, 48, 40, 255))
        eye(draw, cx + 28, cy - 90, 12, (240, 48, 40, 255))
        ellipse(draw, (cx - 80, cy - 20, cx + 80, cy + 70), STEEL_D, INK, 6)
    else:
        ellipse(draw, (cx - 78, cy - 160, cx + 78, cy - 10), GREEN, INK, 8)
        eye(draw, cx - 26, cy - 100, 16, (240, 210, 40, 255))
        eye(draw, cx + 26, cy - 100, 16, (240, 210, 40, 255))
        draw.arc((cx - 30, cy - 70, cx + 30, cy - 30), 10, 170, fill=INK, width=5)
    football(draw, cx + 90, cy + 40, 1.3)
    return image


def trol(fury: bool) -> Image.Image:
    image, draw = new(460, 500)
    cx, cy = 230, 260
    skin = (150, 70, 78, 255) if fury else (78, 150, 168, 255)
    shadow(draw, cx, 440, 120, 22)
    ellipse(draw, (cx - 70, cy + 40, cx - 10, cy + 180), skin, INK, 7)
    ellipse(draw, (cx + 10, cy + 40, cx + 70, cy + 180), skin, INK, 7)
    boots(draw, cx - 40, cy + 180, 1.5)
    boots(draw, cx + 36, cy + 180, 1.5)
    ellipse(draw, (cx - 130, cy - 80, cx + 130, cy + 120), skin, INK, 8)
    ellipse(draw, (cx - 70, cy - 10, cx + 70, cy + 80), (210, 230, 220, 255) if not fury else (230, 180, 180, 255), None, 0)
    # casco diminuto
    ellipse(draw, (cx - 28, cy - 150, cx + 28, cy - 100), RED, INK, 5)
    ellipse(draw, (cx - 78, cy - 170, cx + 78, cy - 40), skin, INK, 8)
    # nariz
    ellipse(draw, (cx - 18, cy - 90, cx + 22, cy - 50), skin, INK, 4)
    eye(draw, cx - 30, cy - 120, 14, (220, 30, 30, 255) if fury else INK)
    eye(draw, cx + 30, cy - 120, 14, (220, 30, 30, 255) if fury else INK)
    if fury:
        ellipse(draw, (cx - 24, cy - 70, cx + 28, cy - 40), (90, 16, 16, 255), INK, 4)
    draw.line((cx + 80, cy - 20, cx + 190, cy + 80), fill=(70, 52, 36, 255), width=16)
    ellipse(draw, (cx + 160, cy + 50, cx + 230, cy + 120), STEEL_D, INK, 6)
    return image


def pitch() -> Image.Image:
    image = Image.new("RGBA", (1280, 720), (18, 16, 14, 255))
    draw = ImageDraw.Draw(image)
    # gradas
    for y in range(0, 720, 18):
        shade = 36 + (y // 18) % 2 * 10
        draw.rectangle((0, y, 1280, y + 18), fill=(shade, shade - 6, shade - 10, 255))
    # público
    for y in range(8, 110, 14):
        for x in range(16, 1260, 18):
            draw.ellipse((x, y, x + 8, y + 8), fill=((180, 60, 50, 255) if (x + y) % 36 == 0 else (40, 90, 160, 255)))
    for y in range(620, 712, 14):
        for x in range(16, 1260, 18):
            draw.ellipse((x, y, x + 8, y + 8), fill=((220, 180, 60, 255) if (x + y) % 28 == 0 else (30, 30, 30, 255)))
    # césped
    draw.rounded_rectangle((36, 108, 1244, 612), 18, fill=(24, 120, 52, 255))
    for i, x in enumerate(range(36, 1244, 56)):
        if i % 2 == 0:
            draw.rectangle((x, 108, min(x + 56, 1244), 612), fill=(20, 104, 44, 255))
    # líneas de yarda
    for x in range(80, 1220, 70):
        draw.line((x, 130, x, 590), fill=(255, 255, 255, 90), width=3)
    draw.rounded_rectangle((70, 140, 1210, 580), 8, outline=(255, 255, 255, 180), width=4)
    # zona final a la derecha
    draw.rectangle((1088, 140, 1210, 580), fill=(20, 58, 130, 160))
    draw.line((1088, 140, 1088, 580), fill=GOLD, width=6)
    # túnel a la izquierda
    draw.rounded_rectangle((8, 200, 90, 340), 16, fill=(12, 10, 10, 255), outline=GOLD, width=5)
    draw.ellipse((28, 250, 48, 270), fill=(255, 40, 40, 255))
    draw.ellipse((52, 252, 70, 270), fill=(255, 40, 40, 255))
    return image


def save(image: Image.Image, name: str) -> None:
    image.save(ROOT / name, "PNG")
    print(name, image.size)


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    save(pitch(), "pitch.png")
    save(human_player("arquero"), "arquero.png")
    save(human_player("mago"), "mago.png")
    save(canon(), "canon.png")
    save(goblin(), "goblin.png")
    save(jinete(), "jinete.png")
    save(hobgoblin(), "hobgoblin.png")
    save(ogre(True), "ogro_armadura.png")
    save(ogre(False), "ogro.png")
    save(trol(False), "trol.png")
    save(trol(True), "trol_furia.png")


if __name__ == "__main__":
    main()
