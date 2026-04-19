"""
Generate 9to5AI.png — monkey-plush-inspired app icon (1024×1024 RGBA).
Run: python make_icon.py
"""
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
cx, cy = SIZE // 2, SIZE // 2

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# --- dark charcoal background circle ---
draw.ellipse([0, 0, SIZE - 1, SIZE - 1], fill="#1a1a1a")

# --- main brown face ---
face_r = 440
draw.ellipse(
    [cx - face_r, cy - face_r, cx + face_r, cy + face_r],
    fill="#6b3a1f",
)

# --- subtle plush texture highlight (lighter inner ellipse, blurred) ---
tex = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
tex_draw = ImageDraw.Draw(tex)
tex_r = 320
tex_draw.ellipse(
    [cx - tex_r, cy - tex_r - 30, cx + tex_r, cy + tex_r - 30],
    fill="#8b5a2b",
)
tex = tex.filter(ImageFilter.GaussianBlur(radius=80))
img = Image.alpha_composite(img, tex)
draw = ImageDraw.Draw(img)

# --- cream muzzle ---
muz_w, muz_h = 280, 210
muz_cx, muz_cy = cx, cy + 160
draw.ellipse(
    [muz_cx - muz_w, muz_cy - muz_h, muz_cx + muz_w, muz_cy + muz_h],
    fill="#e8d5a3",
)

# --- eyes ---
eye_r = 52
eye_y = cy - 60
for ex in [cx - 145, cx + 145]:
    # white sclera base
    draw.ellipse([ex - eye_r, eye_y - eye_r, ex + eye_r, eye_y + eye_r], fill="#1a0a00")
    # shine
    shine_r = 14
    draw.ellipse(
        [ex - eye_r + 12, eye_y - eye_r + 10,
         ex - eye_r + 12 + shine_r * 2, eye_y - eye_r + 10 + shine_r * 2],
        fill="white",
    )

# --- nose ---
nose_w, nose_h = 68, 48
nose_cx, nose_cy = cx, muz_cy - 60
draw.ellipse(
    [nose_cx - nose_w, nose_cy - nose_h, nose_cx + nose_w, nose_cy + nose_h],
    fill="#2d1506",
)

img.save("ClaudeMusicSetup_icon.png")
print("Saved ClaudeMusicSetup_icon.png")
