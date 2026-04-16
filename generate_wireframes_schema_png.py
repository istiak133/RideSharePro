from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


OUT_DIR = Path("generated_diagrams")


THEME = {
    "bg": "#f1f4f7",
    "panel": "#ffffff",
    "line": "#a6b0ba",
    "text": "#1f2a33",
    "muted": "#5e6a75",
    "blue": "#77add8",
    "blue_dark": "#4f8fbe",
    "green": "#3dac69",
    "red": "#d65d56",
    "chip": "#e8eef5",
}


def _font(size: int, bold: bool = False):
    candidates = []
    if bold:
        candidates.extend(
            [
                "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                "/System/Library/Fonts/Supplemental/Helvetica.ttc",
            ]
        )
    else:
        candidates.extend(
            [
                "/System/Library/Fonts/Supplemental/Arial.ttf",
                "/System/Library/Fonts/Supplemental/Helvetica.ttc",
            ]
        )
    for c in candidates:
        try:
            return ImageFont.truetype(c, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def rounded_rect(draw: ImageDraw.ImageDraw, xy, r=18, fill=None, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, x: int, y: int, s: str, size=18, bold=False, fill=None):
    draw.text((x, y), s, font=_font(size, bold=bold), fill=fill or THEME["text"])


def phone_shell(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, title: str):
    rounded_rect(draw, (x, y, x + w, y + h), r=40, fill="#edf1f4", outline="#9da8b1", width=3)
    inner = (x + 8, y + 8, x + w - 8, y + h - 8)
    rounded_rect(draw, inner, r=34, fill=THEME["bg"], outline="#c2cbd3", width=1)
    notch_w = int(w * 0.34)
    nx = x + (w - notch_w) // 2
    rounded_rect(draw, (nx, y + 6, nx + notch_w, y + 24), r=10, fill="#c6ced6")
    text(draw, x + 16, y + h + 10, title, size=28, bold=True)
    return inner


def screen_header(draw: ImageDraw.ImageDraw, rect, title, left_icon="<", right_icon=""):
    x1, y1, x2, _ = rect
    rounded_rect(draw, (x1 + 6, y1 + 34, x2 - 6, y1 + 88), r=8, fill="#d9e1e8", outline=THEME["line"])
    text(draw, x1 + 18, y1 + 48, left_icon, size=24, bold=True)
    text(draw, x1 + 84, y1 + 50, title, size=24, bold=True)
    if right_icon:
        text(draw, x2 - 44, y1 + 50, right_icon, size=22)


def bottom_nav(draw: ImageDraw.ImageDraw, rect, selected=0):
    x1, y1, x2, y2 = rect
    bar = (x1 + 12, y2 - 70, x2 - 12, y2 - 12)
    rounded_rect(draw, bar, r=16, fill="#f8fafc", outline=THEME["line"])
    labels = ["Home", "Search", "Orders", "Profile"]
    space = (bar[2] - bar[0]) // 4
    for i, lab in enumerate(labels):
        cx = bar[0] + i * space + 22
        cfill = THEME["blue_dark"] if i == selected else THEME["muted"]
        draw.ellipse((cx, bar[1] + 10, cx + 14, bar[1] + 24), outline=cfill, width=2)
        text(draw, cx - 8, bar[1] + 28, lab, size=12, fill=cfill)


def map_block(draw: ImageDraw.ImageDraw, rect, path="to_pickup"):
    x1, y1, x2, y2 = rect
    rounded_rect(draw, rect, r=16, fill="#d9dee4", outline=THEME["line"])
    for i in range(8):
        draw.line((x1 + 20 + i * 46, y1 + 8, x1 + 60 + i * 46, y2 - 8), fill="#edf2f6", width=4)
        draw.line((x1 + 8, y1 + 18 + i * 34, x2 - 8, y1 + 42 + i * 34), fill="#edf2f6", width=4)
    if path == "to_pickup":
        start = (x1 + 72, y2 - 58)
        end = (x2 - 80, y1 + 58)
        tag = "Shop"
        tfill = THEME["green"]
    elif path == "to_drop":
        start = (x1 + 72, y2 - 58)
        end = (x2 - 70, y1 + 58)
        tag = "Customer"
        tfill = THEME["red"]
    else:
        start = (x1 + 90, y2 - 70)
        end = (x2 - 90, y1 + 70)
        tag = "Destination"
        tfill = THEME["red"]
    draw.line((*start, *end), fill="#3e4650", width=4)
    sx, sy = start
    ex, ey = end
    draw.ellipse((sx - 12, sy - 12, sx + 12, sy + 12), fill=THEME["blue_dark"])
    draw.ellipse((ex - 12, ey - 12, ex + 12, ey + 12), fill=tfill)
    rounded_rect(draw, (ex - 52, ey - 58, ex + 78, ey - 24), r=8, fill=tfill)
    text(draw, ex - 40, ey - 54, tag, size=14, bold=True, fill="#ffffff")
    rounded_rect(draw, (sx - 28, sy - 58, sx + 30, sy - 24), r=8, fill=THEME["blue_dark"])
    text(draw, sx - 18, sy - 54, "You", size=14, bold=True, fill="#ffffff")


def pill(draw: ImageDraw.ImageDraw, x, y, w, h, s, fill, text_fill="#ffffff"):
    rounded_rect(draw, (x, y, x + w, y + h), r=12, fill=fill)
    tw = draw.textlength(s, font=_font(16, True))
    text(draw, int(x + (w - tw) / 2), y + 9, s, size=16, bold=True, fill=text_fill)


def rider_wireframes():
    canvas = Image.new("RGB", (3700, 2200), "#ffffff")
    draw = ImageDraw.Draw(canvas)

    text(draw, 60, 30, "RideShare MVP Rider Wireframes", size=46, bold=True)
    text(draw, 60, 88, "Theme matched to provided reference: low-fidelity mobile, gray cards, blue/green actions", size=24, fill=THEME["muted"])

    phones = [
        (60, 160, "Phone Login"),
        (480, 160, "OTP Verification"),
        (900, 160, "Home Screen"),
        (1320, 160, "Shop / Products"),
        (60, 1090, "Cart"),
        (480, 1090, "Checkout"),
        (900, 1090, "Track Order"),
        (1320, 1090, "Order History + Profile"),
    ]

    frames = [phone_shell(draw, x, y, 360, 860, title) for x, y, title in phones]

    # 1 Login
    r = frames[0]
    screen_header(draw, r, "Login with Phone", left_icon="")
    x1, y1, x2, y2 = r
    rounded_rect(draw, (x1 + 42, y1 + 124, x2 - 42, y1 + 250), r=8, outline=THEME["line"], fill="#e4ebf2")
    draw.line((x1 + 46, y1 + 128, x2 - 46, y1 + 246), fill=THEME["line"], width=2)
    draw.line((x1 + 46, y1 + 246, x2 - 46, y1 + 128), fill=THEME["line"], width=2)
    rounded_rect(draw, (x1 + 34, y1 + 310, x1 + 112, y1 + 360), r=8, fill="#f9fcff", outline=THEME["line"])
    text(draw, x1 + 50, y1 + 327, "+880", size=16)
    rounded_rect(draw, (x1 + 124, y1 + 310, x2 - 34, y1 + 360), r=8, fill="#f9fcff", outline=THEME["line"])
    text(draw, x1 + 142, y1 + 327, "Phone number", size=16, fill=THEME["muted"])
    pill(draw, x1 + 34, y1 + 380, x2 - x1 - 68, 54, "Send OTP", THEME["blue"])
    text(draw, x1 + 62, y1 + 448, "Terms of Service & Privacy Policy", size=13, fill=THEME["muted"])

    # 2 OTP
    r = frames[1]
    screen_header(draw, r, "Verify OTP")
    x1, y1, x2, y2 = r
    text(draw, x1 + 70, y1 + 146, "Code sent to +880 1XXXXXXX", size=16, fill=THEME["muted"])
    for i in range(6):
        bx = x1 + 36 + i * 52
        rounded_rect(draw, (bx, y1 + 196, bx + 42, y1 + 252), r=8, fill="#f9fcff", outline=THEME["line"])
    text(draw, x1 + 132, y1 + 276, "Resend in 45s", size=15, fill=THEME["muted"])
    pill(draw, x1 + 34, y1 + 316, x2 - x1 - 68, 54, "Verify & Continue", THEME["blue"])

    # 3 Home
    r = frames[2]
    screen_header(draw, r, "Banani, Dhaka", left_icon="", right_icon="*")
    x1, y1, x2, y2 = r
    rounded_rect(draw, (x1 + 18, y1 + 100, x2 - 18, y1 + 146), r=8, fill="#f9fcff", outline=THEME["line"])
    text(draw, x1 + 34, y1 + 114, "Search destination", size=16, fill=THEME["muted"])
    rounded_rect(draw, (x1 + 18, y1 + 160, x2 - 18, y1 + 266), r=10, fill="#e0e7ee", outline=THEME["line"])
    draw.line((x1 + 22, y1 + 164, x2 - 22, y1 + 262), fill=THEME["line"], width=2)
    cats = ["Grocery", "Fish", "Meat", "Pharmacy", "Parcel", "Car"]
    for i, c in enumerate(cats):
        cx = x1 + 30 + (i % 3) * 105
        cy = y1 + 294 + (i // 3) * 88
        draw.ellipse((cx, cy, cx + 54, cy + 54), fill=THEME["chip"], outline=THEME["line"])
        text(draw, cx - 4, cy + 58, c, size=13)
    text(draw, x1 + 20, y1 + 472, "Nearby Shops", size=20, bold=True)
    for i in range(2):
        yy = y1 + 504 + i * 92
        rounded_rect(draw, (x1 + 18, yy, x2 - 18, yy + 78), r=10, fill="#ffffff", outline=THEME["line"])
        rounded_rect(draw, (x1 + 30, yy + 12, x1 + 86, yy + 66), r=8, fill="#e8edf2", outline=THEME["line"])
        text(draw, x1 + 96, yy + 18, f"FreshMart #{i + 1}", size=16, bold=True)
        text(draw, x1 + 96, yy + 42, "1.2km   25-35 min", size=14, fill=THEME["muted"])
    bottom_nav(draw, r, selected=0)

    # 4 Shop/products
    r = frames[3]
    screen_header(draw, r, "Shop Detail")
    x1, y1, x2, y2 = r
    rounded_rect(draw, (x1 + 24, y1 + 102, x2 - 24, y1 + 238), r=10, fill="#e0e7ee", outline=THEME["line"])
    draw.line((x1 + 28, y1 + 106, x2 - 28, y1 + 234), fill=THEME["line"], width=2)
    text(draw, x1 + 28, y1 + 250, "Shop Banner", size=22, bold=True)
    text(draw, x1 + 28, y1 + 284, "4.5 (120)   1.2km   25-35 min", size=15, fill=THEME["muted"])
    for i, c in enumerate(["All", "Fruits", "Dairy", "Snacks", "Drink"]):
        rounded_rect(draw, (x1 + 24 + i * 66, y1 + 316, x1 + 80 + i * 66, y1 + 350), r=8, fill=THEME["chip"], outline=THEME["line"])
        text(draw, x1 + 40 + i * 66, y1 + 326, c, size=12)
    for i in range(2):
        yy = y1 + 368 + i * 116
        rounded_rect(draw, (x1 + 24, yy, x2 - 24, yy + 100), r=10, fill="#ffffff", outline=THEME["line"])
        rounded_rect(draw, (x1 + 34, yy + 14, x1 + 92, yy + 74), r=6, fill="#e8edf2", outline=THEME["line"])
        text(draw, x1 + 102, yy + 20, "Product Name", size=16, bold=True)
        text(draw, x1 + 102, yy + 50, "BDT 265", size=15)
        rounded_rect(draw, (x2 - 92, yy + 42, x2 - 56, yy + 72), r=6, fill="#f1f6fb", outline=THEME["line"])
        text(draw, x2 - 82, yy + 50, "+", size=16, bold=True)
    rounded_rect(draw, (x1 + 24, y2 - 140, x2 - 24, y2 - 96), r=10, fill="#eef4fa", outline=THEME["line"])
    text(draw, x1 + 34, y2 - 128, "2 items  -  BDT 265", size=15)
    pill(draw, x2 - 134, y2 - 136, 98, 36, "View Cart", THEME["blue"])
    bottom_nav(draw, r, selected=2)

    # 5 Cart
    r = frames[4]
    screen_header(draw, r, "My Cart")
    x1, y1, x2, y2 = r
    text(draw, x1 + 24, y1 + 108, "FreshMart (2 items)", size=16, bold=True)
    for i in range(2):
        yy = y1 + 138 + i * 108
        rounded_rect(draw, (x1 + 24, yy, x2 - 24, yy + 92), r=10, fill="#ffffff", outline=THEME["line"])
        rounded_rect(draw, (x1 + 34, yy + 12, x1 + 92, yy + 72), r=6, fill="#e8edf2", outline=THEME["line"])
        text(draw, x1 + 102, yy + 18, "Product", size=16, bold=True)
        text(draw, x1 + 102, yy + 48, "BDT 265", size=14)
        rounded_rect(draw, (x2 - 134, yy + 42, x2 - 100, yy + 72), r=6, fill="#f2f5f8", outline=THEME["line"])
        text(draw, x2 - 124, yy + 50, "-", size=18, bold=True)
        text(draw, x2 - 88, yy + 50, "1", size=15)
        rounded_rect(draw, (x2 - 64, yy + 42, x2 - 30, yy + 72), r=6, fill="#f2f5f8", outline=THEME["line"])
        text(draw, x2 - 54, yy + 50, "+", size=16, bold=True)
    rounded_rect(draw, (x1 + 24, y1 + 364, x2 - 24, y1 + 544), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 34, y1 + 386, "Subtotal", size=16)
    text(draw, x2 - 110, y1 + 386, "BDT 265", size=16, bold=True)
    text(draw, x1 + 34, y1 + 420, "Delivery Fee", size=16)
    text(draw, x2 - 110, y1 + 420, "BDT 20", size=16)
    text(draw, x1 + 34, y1 + 454, "Platform Fee", size=16)
    text(draw, x2 - 110, y1 + 454, "BDT 20", size=16)
    text(draw, x1 + 34, y1 + 498, "Total", size=18, bold=True)
    text(draw, x2 - 120, y1 + 498, "BDT 305", size=18, bold=True)
    rounded_rect(draw, (x1 + 24, y1 + 562, x2 - 24, y1 + 622), r=8, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 34, y1 + 580, "Add instructions", size=15, fill=THEME["muted"])
    pill(draw, x1 + 24, y2 - 132, x2 - x1 - 48, 56, "Proceed to Checkout", THEME["blue"])

    # 6 Checkout
    r = frames[5]
    screen_header(draw, r, "Checkout")
    x1, y1, x2, y2 = r
    text(draw, x1 + 22, y1 + 108, "Delivery Address", size=26, bold=True)
    for i, (nm, sel) in enumerate([("Home", True), ("Work", False), ("Add New", False)]):
        bx = x1 + 22 + i * 108
        rounded_rect(draw, (bx, y1 + 146, bx + 100, y1 + 238), r=10, fill="#ffffff", outline=THEME["line"])
        if sel:
            draw.ellipse((bx + 8, y1 + 156, bx + 24, y1 + 172), fill=THEME["blue_dark"])
        text(draw, bx + 12, y1 + 176, nm, size=15, bold=True)
    text(draw, x1 + 22, y1 + 276, "Payment Method", size=26, bold=True)
    rounded_rect(draw, (x1 + 22, y1 + 316, x2 - 22, y1 + 372), r=8, fill="#f9fcff", outline=THEME["blue_dark"], width=3)
    text(draw, x1 + 36, y1 + 334, "Cash on Delivery", size=18)
    draw.ellipse((x2 - 54, y1 + 332, x2 - 34, y1 + 352), fill=THEME["blue_dark"])
    rounded_rect(draw, (x1 + 22, y1 + 384, x2 - 22, y1 + 438), r=8, fill="#f1f4f8", outline=THEME["line"])
    text(draw, x1 + 36, y1 + 400, "Online Payment (Coming Soon)", size=16, fill=THEME["muted"])
    text(draw, x1 + 22, y1 + 566, "Order Summary", size=26, bold=True)
    rounded_rect(draw, (x1 + 22, y1 + 606, x2 - 22, y1 + 736), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 34, y1 + 632, "2 items from FreshMart", size=18, bold=True)
    text(draw, x1 + 34, y1 + 666, "Subtotal BDT 265 + Delivery BDT 42", size=16)
    text(draw, x1 + 34, y1 + 700, "Total: BDT 312", size=19, bold=True)
    pill(draw, x1 + 22, y2 - 132, x2 - x1 - 44, 56, "Place Order - BDT 312", THEME["blue"])

    # 7 Track order
    r = frames[6]
    screen_header(draw, r, "Order #07A3F2")
    x1, y1, x2, y2 = r
    map_block(draw, (x1 + 18, y1 + 102, x2 - 18, y1 + 344), path="to_destination")
    rounded_rect(draw, (x1 + 94, y1 + 292, x2 - 96, y1 + 334), r=10, fill="#5f6670")
    text(draw, x1 + 114, y1 + 304, "ETA: 15 min - 2.3 km", size=16, bold=True, fill="#ffffff")
    rounded_rect(draw, (x1 + 18, y1 + 360, x2 - 18, y2 - 82), r=12, fill="#ffffff", outline=THEME["line"])
    statuses = ["Order Placed", "Rider Assigned", "Picked Up", "On the Way", "Delivered"]
    for i, st in enumerate(statuses):
        cy = y1 + 390 + i * 44
        draw.ellipse((x1 + 34, cy, x1 + 48, cy + 14), outline=THEME["line"], width=2)
        if i < 4:
            draw.ellipse((x1 + 36, cy + 2, x1 + 46, cy + 12), fill=THEME["green"])
        text(draw, x1 + 60, cy - 2, st + (" ✓" if i < 4 else ""), size=16, fill=THEME["muted"])
    rounded_rect(draw, (x1 + 24, y2 - 210, x2 - 24, y2 - 104), r=10, fill="#f8fbff", outline=THEME["line"])
    draw.ellipse((x1 + 36, y2 - 194, x1 + 88, y2 - 142), fill="#dce3ea", outline=THEME["line"])
    text(draw, x1 + 98, y2 - 186, "Karim Ahmed", size=18, bold=True)
    text(draw, x1 + 98, y2 - 160, "Motorcycle", size=15, fill=THEME["muted"])
    text(draw, x2 - 90, y2 - 186, "★ 4.7", size=18, bold=True)
    rounded_rect(draw, (x2 - 162, y2 - 148, x2 - 90, y2 - 112), r=8, fill="#f1f6fb", outline=THEME["line"])
    text(draw, x2 - 150, y2 - 138, "Message", size=14)

    # 8 Order history + profile
    r = frames[7]
    x1, y1, x2, y2 = r
    screen_header(draw, r, "My Orders", left_icon="", right_icon="")
    rounded_rect(draw, (x1 + 24, y1 + 104, x1 + 170, y1 + 140), r=10, fill=THEME["chip"], outline=THEME["line"])
    rounded_rect(draw, (x1 + 178, y1 + 104, x1 + 324, y1 + 140), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 70, y1 + 116, "Active", size=14, bold=True)
    text(draw, x1 + 220, y1 + 116, "Completed", size=14)
    for i, st in enumerate([("#07A3F2 Grocery", "On the Way", THEME["green"]), ("#07B1C8 Parcel", "Delivered", THEME["green"])]):
        yy = y1 + 156 + i * 128
        rounded_rect(draw, (x1 + 24, yy, x2 - 24, yy + 112), r=10, fill="#ffffff", outline=THEME["line"])
        text(draw, x1 + 34, yy + 16, st[0], size=15, bold=True)
        text(draw, x1 + 34, yy + 42, st[1], size=14, fill=st[2])
        rounded_rect(draw, (x2 - 138, yy + 62, x2 - 36, yy + 94), r=8, fill="#f0f5fb", outline=THEME["line"])
        text(draw, x2 - 122, yy + 70, "Track", size=14)
    rounded_rect(draw, (x1 + 16, y1 + 430, x2 - 16, y2 - 90), r=14, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 28, y1 + 444, "My Profile", size=22, bold=True)
    draw.ellipse((x1 + 28, y1 + 486, x1 + 94, y1 + 552), fill="#dce3ea", outline=THEME["line"])
    text(draw, x1 + 104, y1 + 494, "Rahim Hasan", size=18, bold=True)
    text(draw, x1 + 104, y1 + 524, "+880 1XXXXXXXXX", size=15, fill=THEME["muted"])
    for i, m in enumerate(["My Addresses", "Payment Methods", "Notifications", "Help & Support", "About", "Logout"]):
        yy = y1 + 578 + i * 46
        text(draw, x1 + 34, yy, m, size=16, fill=THEME["red"] if m == "Logout" else THEME["text"])
        if m != "Logout":
            text(draw, x2 - 46, yy, ">", size=18, fill=THEME["muted"])
    bottom_nav(draw, r, selected=3)

    # flow arrows
    flow = [
        ((420, 590), (480, 590)),
        ((840, 590), (900, 590)),
        ((1260, 590), (1320, 590)),
        ((240, 1030), (240, 1090)),
        ((660, 1030), (660, 1090)),
        ((1080, 1030), (1080, 1090)),
        ((1500, 1030), (1500, 1090)),
    ]
    for a, b in flow:
        draw.line((*a, *b), fill=THEME["line"], width=4)
        draw.polygon([b, (b[0] - 8, b[1] - 14), (b[0] + 8, b[1] - 14)], fill=THEME["line"])

    out = OUT_DIR / "rideshare_rider_wireframes.png"
    canvas.save(out)


def driver_wireframes():
    canvas = Image.new("RGB", (2350, 1420), "#ffffff")
    draw = ImageDraw.Draw(canvas)
    text(draw, 50, 22, "RideShare MVP Driver Wireframes", size=42, bold=True)
    text(draw, 50, 74, "Incoming requests, active delivery states, and basic earnings as defined in MVP", size=22, fill=THEME["muted"])

    phones = [
        (40, 130, "Driver Dashboard"),
        (600, 130, "Active Delivery - To Pickup"),
        (1160, 130, "Active Delivery - To Customer"),
        (1720, 130, "Driver Earnings"),
    ]
    frames = [phone_shell(draw, x, y, 500, 1180, title) for x, y, title in phones]

    # Dashboard
    r = frames[0]
    x1, y1, x2, y2 = r
    screen_header(draw, r, "Karim Ahmed", left_icon="◉", right_icon="⚑")
    for i, (label, val) in enumerate([("Deliveries", "5"), ("Rating", "4.7"), ("Earnings", "Tk 425")]):
        bx = x1 + 24 + i * 154
        rounded_rect(draw, (bx, y1 + 108, bx + 142, y1 + 214), r=10, fill="#ffffff", outline=THEME["line"])
        text(draw, bx + 56, y1 + 132, val, size=28, bold=True)
        text(draw, bx + 26, y1 + 172, label, size=14)
    rounded_rect(draw, (x1 + 24, y1 + 230, x2 - 24, y1 + 286), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 40, y1 + 248, "Online/Offline", size=20, bold=True)
    draw.ellipse((x1 + 272, y1 + 248, x1 + 288, y1 + 264), fill=THEME["green"])
    text(draw, x1 + 292, y1 + 248, "Online", size=17, fill=THEME["green"])
    rounded_rect(draw, (x2 - 102, y1 + 244, x2 - 34, y1 + 270), r=13, fill="#d7e7d9", outline=THEME["line"])
    draw.ellipse((x2 - 58, y1 + 246, x2 - 36, y1 + 268), fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 24, y1 + 304, "Incoming Orders", size=26, bold=True)
    for i, itm in enumerate([("Grocery Order", "FreshMart -> Banani 5", "1.2 km pickup  |  2.3 km total", "Est. Earnings Tk 42"), ("Parcel Pickup", "Gulshan 2 -> Mirpur 10", "0.5 km pickup  |  5.1 km total", "Est. Earnings Tk 82")]):
        yy = y1 + 344 + i * 236
        rounded_rect(draw, (x1 + 24, yy, x2 - 24, yy + 214), r=12, fill="#ffffff", outline=THEME["line"])
        text(draw, x1 + 36, yy + 18, itm[0], size=17)
        text(draw, x1 + 36, yy + 50, itm[1], size=26, bold=True)
        text(draw, x1 + 36, yy + 90, itm[2], size=16, fill=THEME["muted"])
        text(draw, x1 + 36, yy + 122, itm[3], size=22)
        rounded_rect(draw, (x1 + 36, yy + 152, x1 + 190, yy + 198), r=10, fill="#f5f7fa", outline=THEME["line"])
        text(draw, x1 + 78, yy + 166, "Decline", size=18)
        rounded_rect(draw, (x1 + 206, yy + 152, x1 + 366, yy + 198), r=10, fill=THEME["green"])
        text(draw, x1 + 250, yy + 166, "Accept ✓", size=18, bold=True, fill="#ffffff")
        text(draw, x2 - 140, yy + 166, "Auto-decline: 45s", size=14, fill=THEME["muted"])
    bottom_nav(draw, r, selected=0)

    # To pickup
    r = frames[1]
    x1, y1, x2, y2 = r
    screen_header(draw, r, "Active Delivery")
    map_block(draw, (x1 + 24, y1 + 100, x2 - 24, y1 + 430), path="to_pickup")
    rounded_rect(draw, (x1 + 154, y1 + 374, x1 + 340, y1 + 416), r=10, fill="#6a7078")
    text(draw, x1 + 178, y1 + 386, "1.2 km - 5 min", size=18, bold=True, fill="#ffffff")
    rounded_rect(draw, (x1 + 24, y1 + 446, x2 - 24, y2 - 174), r=14, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 38, y1 + 470, "Order #07A3F2 - Grocery", size=26, bold=True)
    text(draw, x1 + 38, y1 + 514, "Pickup:", size=20, bold=True)
    text(draw, x1 + 162, y1 + 514, "FreshMart Grocery, Road 11, Banani", size=20)
    text(draw, x1 + 38, y1 + 560, "Drop-off:", size=20, bold=True)
    text(draw, x1 + 162, y1 + 560, "House 12, Road 5, Banani", size=20)
    text(draw, x1 + 38, y1 + 606, "Items:", size=20, bold=True)
    text(draw, x1 + 162, y1 + 606, "2 items  -  Tk 265", size=20)
    text(draw, x1 + 38, y1 + 652, "Customer:", size=20, bold=True)
    text(draw, x1 + 162, y1 + 652, "+880 1XXXXXXX", size=20)
    rounded_rect(draw, (x1 + 36, y2 - 304, x2 - 36, y2 - 248), r=10, fill="#f7fbff", outline=THEME["line"])
    text(draw, x1 + 164, y2 - 286, "Open in Google Maps", size=20)
    pill(draw, x1 + 36, y2 - 222, x2 - x1 - 72, 66, "PICKED UP ✓", THEME["green"])
    bottom_nav(draw, r, selected=2)

    # To customer
    r = frames[2]
    x1, y1, x2, y2 = r
    screen_header(draw, r, "Active Delivery")
    map_block(draw, (x1 + 24, y1 + 100, x2 - 24, y1 + 430), path="to_drop")
    rounded_rect(draw, (x1 + 158, y1 + 374, x1 + 346, y1 + 416), r=10, fill="#6a7078")
    text(draw, x1 + 182, y1 + 386, "2.3 km - 10 min", size=18, bold=True, fill="#ffffff")
    rounded_rect(draw, (x1 + 24, y1 + 446, x2 - 24, y2 - 174), r=14, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 38, y1 + 474, "Delivering to:", size=24, bold=True)
    rounded_rect(draw, (x1 + 36, y1 + 516, x2 - 36, y1 + 632), r=10, fill="#f8fbff", outline=THEME["line"])
    draw.ellipse((x1 + 52, y1 + 542, x1 + 104, y1 + 594), fill="#dce3ea", outline=THEME["line"])
    text(draw, x1 + 118, y1 + 548, "Customer Name", size=24, bold=True)
    text(draw, x1 + 118, y1 + 582, "House 12, Road 5, Banani", size=18)
    rounded_rect(draw, (x1 + 36, y1 + 650, x1 + 232, y1 + 696), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 64, y1 + 664, "Call Customer", size=18)
    rounded_rect(draw, (x1 + 244, y1 + 650, x2 - 36, y1 + 696), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x1 + 302, y1 + 664, "Message", size=18)
    rounded_rect(draw, (x1 + 36, y2 - 304, x2 - 36, y2 - 248), r=10, fill="#f7fbff", outline=THEME["line"])
    text(draw, x1 + 164, y2 - 286, "Open in Google Maps", size=20)
    pill(draw, x1 + 36, y2 - 222, x2 - x1 - 72, 66, "DELIVERED ✓", THEME["green"])
    bottom_nav(draw, r, selected=2)

    # Earnings
    r = frames[3]
    x1, y1, x2, y2 = r
    screen_header(draw, r, "My Earnings", left_icon="", right_icon="Tk")
    text(draw, x1 + 30, y1 + 108, "Today's earnings", size=30, bold=True)
    text(draw, x1 + 30, y1 + 158, "Tk 425.00", size=58, bold=True)
    rounded_rect(draw, (x1 + 30, y1 + 248, x2 - 30, y1 + 408), r=10, fill="#ffffff", outline=THEME["line"])
    bars = [52, 90, 126, 98, 132, 86, 64]
    for i, bh in enumerate(bars):
        bx = x1 + 54 + i * 58
        draw.rectangle((bx, y1 + 386 - bh, bx + 34, y1 + 386), fill=THEME["blue"])
    for i, tick in enumerate(["8am", "10am", "2pm", "5pm"]):
        text(draw, x1 + 38 + i * 116, y1 + 392, tick, size=16)
    for i, tab in enumerate(["Today", "Week", "Month"]):
        bx = x1 + 30 + i * 144
        rounded_rect(draw, (bx, y1 + 428, bx + 132, y1 + 472), r=10, fill=THEME["chip"] if i == 0 else "#ffffff", outline=THEME["line"])
        text(draw, bx + 40, y1 + 442, tab, size=16)
    text(draw, x1 + 30, y1 + 504, "Delivery Breakdown", size=30, bold=True)
    rows = ["#07A3F2 - Grocery", "#07B1C8 - Parcel", "#07C2D3 - Meat", "#07D4E5 - Pharmacy", "#07E6F7 - Fish"]
    vals = ["Tk 42", "Tk 82", "Tk 55", "Tk 38", "Tk 45"]
    for i, row in enumerate(rows):
        yy = y1 + 548 + i * 54
        text(draw, x1 + 30, yy, row, size=20)
        text(draw, x2 - 94, yy, vals[i], size=20, bold=True)
    text(draw, x1 + 30, y2 - 210, "Base Fees: Tk 150", size=24)
    text(draw, x2 - 170, y2 - 210, "Tips: Tk 25", size=24)
    text(draw, x1 + 30, y2 - 172, "Distance Bonus: Tk 250", size=24)
    bottom_nav(draw, r, selected=2)

    out = OUT_DIR / "rideshare_driver_wireframes.png"
    canvas.save(out)


def admin_wireframes():
    canvas = Image.new("RGB", (3400, 1900), "#ffffff")
    draw = ImageDraw.Draw(canvas)
    text(draw, 56, 24, "RideShare MVP Admin Web Wireframes", size=46, bold=True)
    text(draw, 56, 84, "Login + 2FA, live dashboard, driver verification, ride monitoring/dispute flow", size=24, fill=THEME["muted"])

    panels = [
        (56, 150, 780, 1680, "Admin Login + 2FA"),
        (860, 150, 1500, 1680, "Admin Dashboard"),
        (2440, 150, 900, 760, "Driver Verification"),
        (2440, 940, 900, 740, "Ride Monitoring + Disputes"),
    ]

    for x, y, w, h, title in panels:
        rounded_rect(draw, (x, y, x + w, y + h), r=20, fill="#f3f7fb", outline=THEME["line"], width=2)
        rounded_rect(draw, (x + 1, y + 1, x + w - 1, y + 58), r=20, fill="#d9e2ea", outline=THEME["line"])
        text(draw, x + 18, y + 18, title, size=24, bold=True)

    # Login panel
    x, y, w, h, _ = panels[0]
    text(draw, x + 40, y + 120, "Email", size=20, bold=True)
    rounded_rect(draw, (x + 40, y + 156, x + w - 40, y + 214), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 56, y + 174, "admin@ridesharepro.com", size=18, fill=THEME["muted"])
    text(draw, x + 40, y + 248, "Password", size=20, bold=True)
    rounded_rect(draw, (x + 40, y + 284, x + w - 40, y + 342), r=10, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 56, y + 302, "••••••••••••", size=22)
    pill(draw, x + 40, y + 370, w - 80, 56, "Login & Request 2FA", THEME["blue_dark"])
    rounded_rect(draw, (x + 40, y + 458, x + w - 40, y + 620), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 58, y + 486, "2FA Verification", size=24, bold=True)
    for i in range(6):
        bx = x + 58 + i * 102
        rounded_rect(draw, (bx, y + 530, bx + 72, y + 590), r=8, fill="#f8fbff", outline=THEME["line"])
    pill(draw, x + 58, y + 636, w - 116, 50, "Verify & Enter Dashboard", THEME["green"])
    rounded_rect(draw, (x + 40, y + 722, x + w - 40, y + h - 40), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 58, y + 748, "Security Notes", size=22, bold=True)
    notes = [
        "5 failed password attempts => 30 min lock",
        "Session expires in 8 hours",
        "All actions are written to audit logs",
        "RBAC enforced for verifier/super admin",
    ]
    for i, n in enumerate(notes):
        text(draw, x + 72, y + 790 + i * 42, "• " + n, size=18)

    # Dashboard panel
    x, y, w, h, _ = panels[1]
    stats = [
        ("Total Rides", "1,248"),
        ("Revenue Today", "Tk 125,430"),
        ("Active Drivers", "218"),
        ("Pending Verifications", "16"),
    ]
    for i, (k, v) in enumerate(stats):
        bx = x + 30 + (i % 2) * 330
        by = y + 92 + (i // 2) * 170
        rounded_rect(draw, (bx, by, bx + 300, by + 142), r=12, fill="#ffffff", outline=THEME["line"])
        text(draw, bx + 20, by + 24, k, size=18)
        text(draw, bx + 20, by + 66, v, size=34, bold=True)
    rounded_rect(draw, (x + 30, y + 450, x + w - 30, y + 838), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 50, y + 474, "Live Map: Active rides (blue), drivers (green), waiting riders (red)", size=18)
    map_box = (x + 48, y + 512, x + w - 48, y + 816)
    rounded_rect(draw, map_box, r=8, fill="#d9dee4", outline=THEME["line"])
    for i in range(20):
        px = map_box[0] + 20 + (i * 71) % (map_box[2] - map_box[0] - 40)
        py = map_box[1] + 30 + (i * 53) % (map_box[3] - map_box[1] - 60)
        col = THEME["blue_dark"] if i % 3 == 0 else THEME["green"] if i % 3 == 1 else THEME["red"]
        draw.ellipse((px, py, px + 12, py + 12), fill=col)
    rounded_rect(draw, (x + 30, y + 864, x + w - 30, y + h - 40), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 50, y + 892, "Pending Actions", size=24, bold=True)
    for i, n in enumerate(["Unverified drivers: 16", "Open disputes: 7", "Overdue settlements: 4"]):
        text(draw, x + 62, y + 938 + i * 42, "• " + n, size=18)

    # Verification panel
    x, y, w, h, _ = panels[2]
    rounded_rect(draw, (x + 22, y + 86, x + w - 22, y + h - 24), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 44, y + 108, "Pending Queue", size=22, bold=True)
    for i in range(4):
        yy = y + 152 + i * 130
        rounded_rect(draw, (x + 40, yy, x + w - 40, yy + 112), r=10, fill="#f9fcff", outline=THEME["line"])
        text(draw, x + 56, yy + 16, f"Driver #{1200 + i}  |  Submitted {i + 2}h ago", size=16)
        text(draw, x + 56, yy + 48, "NID + License + Vehicle + Bank", size=16, fill=THEME["muted"])
        rounded_rect(draw, (x + w - 240, yy + 36, x + w - 150, yy + 76), r=8, fill=THEME["green"])
        text(draw, x + w - 222, yy + 48, "Approve", size=14, bold=True, fill="#ffffff")
        rounded_rect(draw, (x + w - 140, yy + 36, x + w - 50, yy + 76), r=8, fill=THEME["red"])
        text(draw, x + w - 122, yy + 48, "Reject", size=14, bold=True, fill="#ffffff")

    # Ride monitoring panel
    x, y, w, h, _ = panels[3]
    rounded_rect(draw, (x + 22, y + 86, x + w - 22, y + h - 24), r=12, fill="#ffffff", outline=THEME["line"])
    text(draw, x + 44, y + 108, "Ride List + Filters", size=22, bold=True)
    for i, f in enumerate(["Status", "Date", "Driver", "Rider", "Ride ID"]):
        rounded_rect(draw, (x + 44 + i * 166, y + 144, x + 190 + i * 166, y + 184), r=8, fill="#f3f7fb", outline=THEME["line"])
        text(draw, x + 84 + i * 166, y + 156, f, size=14)
    for i in range(4):
        yy = y + 208 + i * 98
        rounded_rect(draw, (x + 44, yy, x + w - 44, yy + 86), r=8, fill="#f9fcff", outline=THEME["line"])
        text(draw, x + 60, yy + 18, f"Ride #0{i + 7}A3F2  |  Completed  |  Fare Tk {320 + i * 14}", size=16)
        text(draw, x + 60, yy + 46, "Tap to open timeline + route points + payment status", size=14, fill=THEME["muted"])
    text(draw, x + 44, y + 620, "Open Disputes", size=22, bold=True)
    for i in range(2):
        yy = y + 656 + i * 74
        rounded_rect(draw, (x + 44, yy, x + w - 44, yy + 62), r=8, fill="#fff7f7", outline=THEME["line"])
        text(draw, x + 60, yy + 20, f"Dispute #{502 + i}: route deviation / payment mismatch", size=16)

    out = OUT_DIR / "rideshare_admin_wireframes.png"
    canvas.save(out)


def schema_diagram():
    canvas = Image.new("RGB", (3600, 2300), "#ffffff")
    draw = ImageDraw.Draw(canvas)
    text(draw, 52, 22, "RideShare MVP Database Schema Diagram", size=46, bold=True)
    text(draw, 52, 82, "Core entities from RideShare_MVP_Final.txt (Rider + Driver + Admin + Payment + Notification)", size=23, fill=THEME["muted"])

    boxes = {
        "users": (80, 180, 420, 280),
        "user_profiles": (80, 500, 430, 300),
        "otp_verifications": (80, 860, 430, 250),
        "drivers": (560, 180, 420, 280),
        "driver_documents": (560, 500, 430, 300),
        "driver_vehicles": (560, 860, 430, 250),
        "bank_accounts": (560, 1170, 430, 250),
        "rides": (1060, 180, 560, 420),
        "ride_requests": (1060, 660, 560, 230),
        "ride_route_points": (1060, 950, 560, 260),
        "scheduled_ride_jobs": (1060, 1270, 560, 230),
        "ratings": (1060, 1560, 560, 220),
        "payments": (1700, 180, 560, 320),
        "payment_methods": (1700, 560, 560, 240),
        "driver_settlements": (1700, 860, 560, 260),
        "disputes": (1700, 1180, 560, 280),
        "device_tokens": (2340, 180, 500, 220),
        "notifications_log": (2340, 460, 500, 220),
        "broadcast_notifications": (2340, 740, 500, 260),
        "admin_users": (2340, 1080, 500, 220),
        "audit_logs": (2340, 1360, 500, 240),
        "verification_logs": (2340, 1660, 500, 220),
    }

    fields = {
        "users": ["id UUID PK", "phone UNIQUE", "role rider/driver", "status", "avg_rating", "created_at"],
        "user_profiles": ["user_id FK", "full_name", "photo_url", "dob", "email", "language_preference"],
        "otp_verifications": ["phone", "otp_hash", "attempts", "expires_at", "created_at"],
        "drivers": ["user_id FK", "status online/offline/busy", "current_lat/lng", "vehicle_type", "is_verified"],
        "driver_documents": ["user_id FK", "nid_front/back", "license_url", "verification_status", "verified_by"],
        "driver_vehicles": ["user_id FK", "vehicle_type car", "vehicle_model", "vehicle_year", "registration_number"],
        "bank_accounts": ["user_id FK", "holder_name", "account_number(enc)", "bank_name", "branch"],
        "rides": ["id UUID PK", "rider_id FK", "driver_id FK", "pickup/drop coords", "status", "estimated_fare", "final_fare", "scheduled_at", "otp_hash"],
        "ride_requests": ["ride_id FK", "driver_id FK", "sent_at", "response", "responded_at"],
        "ride_route_points": ["id PK", "ride_id FK", "lat/lng", "speed", "heading", "recorded_at"],
        "scheduled_ride_jobs": ["ride_id FK", "job_type", "scheduled_for", "executed_at", "status"],
        "ratings": ["id PK", "ride_id FK", "rated_by FK", "rated_user FK", "stars", "comment"],
        "payments": ["id PK", "ride_id FK UNIQUE", "amount", "payment_method", "platform_commission", "driver_earning", "status"],
        "payment_methods": ["id PK", "user_id FK", "stripe_payment_method_id", "last4", "brand", "is_default"],
        "driver_settlements": ["id PK", "driver_id FK", "period_start/end", "platform_commission", "settlement_status"],
        "disputes": ["id PK", "ride_id FK", "payment_id FK", "reported_by FK", "reported_against FK", "status", "resolution"],
        "device_tokens": ["user_id FK", "token", "platform", "updated_at"],
        "notifications_log": ["user_id FK", "type", "title", "body", "data", "sent_at"],
        "broadcast_notifications": ["id PK", "admin_id FK", "target_type", "title", "body", "scheduled_for", "status"],
        "admin_users": ["id PK", "email", "password_hash", "role", "is_active", "last_login"],
        "audit_logs": ["id PK", "admin_id FK", "action", "entity_type", "entity_id", "ip_address", "created_at"],
        "verification_logs": ["driver_id FK", "admin_id FK", "action approved/rejected", "reason", "created_at"],
    }

    for name, (x, y, w, h) in boxes.items():
        rounded_rect(draw, (x, y, x + w, y + h), r=14, fill="#f7fbff", outline=THEME["line"], width=2)
        rounded_rect(draw, (x + 1, y + 1, x + w - 1, y + 46), r=14, fill="#dbe6f0", outline=THEME["line"])
        text(draw, x + 16, y + 13, name, size=20, bold=True)
        y_cur = y + 58
        for f in fields[name]:
            if y_cur > y + h - 26:
                break
            text(draw, x + 14, y_cur, "- " + f, size=15, fill=THEME["text"])
            y_cur += 26

    def center_right(k):
        x, y, w, h = boxes[k]
        return x + w, y + h // 2

    def center_left(k):
        x, y, _, h = boxes[k]
        return x, y + h // 2

    def center_bottom(k):
        x, y, w, h = boxes[k]
        return x + w // 2, y + h

    def center_top(k):
        x, y, w, _ = boxes[k]
        return x + w // 2, y

    def link(a, b, label="1:N", mode="h"):
        if mode == "h":
            p1 = center_right(a)
            p2 = center_left(b)
        elif mode == "v":
            p1 = center_bottom(a)
            p2 = center_top(b)
        else:
            p1 = center_right(a)
            p2 = center_left(b)
        draw.line((*p1, *p2), fill="#4b5a67", width=3)
        mx = (p1[0] + p2[0]) // 2
        my = (p1[1] + p2[1]) // 2
        rounded_rect(draw, (mx - 26, my - 14, mx + 26, my + 14), r=6, fill="#ffffff", outline=THEME["line"])
        text(draw, mx - 18, my - 9, label, size=13, bold=True)

    # Core relationships
    link("users", "drivers")
    link("users", "user_profiles", mode="v", label="1:1")
    link("drivers", "driver_documents", mode="v", label="1:1")
    link("driver_documents", "driver_vehicles", mode="v", label="1:1")
    link("driver_vehicles", "bank_accounts", mode="v", label="1:1")
    link("drivers", "rides")
    link("rides", "payments")
    link("rides", "ride_requests", mode="v")
    link("ride_requests", "ride_route_points", mode="v")
    link("ride_route_points", "scheduled_ride_jobs", mode="v")
    link("scheduled_ride_jobs", "ratings", mode="v")
    link("payments", "payment_methods", mode="v")
    link("payment_methods", "driver_settlements", mode="v")
    link("driver_settlements", "disputes", mode="v")
    link("payments", "device_tokens")
    link("device_tokens", "notifications_log", mode="v")
    link("notifications_log", "broadcast_notifications", mode="v")
    link("broadcast_notifications", "admin_users", mode="v")
    link("admin_users", "audit_logs", mode="v")
    link("audit_logs", "verification_logs", mode="v")
    link("users", "payment_methods", label="1:N")
    link("users", "device_tokens", label="1:N")
    link("users", "rides", label="1:N")

    legend_x, legend_y = 2920, 1880
    rounded_rect(draw, (legend_x, legend_y, 3530, 2230), r=12, fill="#f7fbff", outline=THEME["line"])
    text(draw, legend_x + 18, legend_y + 16, "Legend", size=24, bold=True)
    text(draw, legend_x + 18, legend_y + 60, "PK = Primary Key", size=18)
    text(draw, legend_x + 18, legend_y + 92, "FK = Foreign Key", size=18)
    text(draw, legend_x + 18, legend_y + 124, "1:N = One-to-many", size=18)
    text(draw, legend_x + 18, legend_y + 156, "1:1 = One-to-one", size=18)
    text(draw, legend_x + 18, legend_y + 206, "Source: RideShare_MVP_Final.txt", size=16, fill=THEME["muted"])

    out = OUT_DIR / "rideshare_schema_diagram.png"
    canvas.save(out)


def main():
    OUT_DIR.mkdir(exist_ok=True)
    rider_wireframes()
    driver_wireframes()
    admin_wireframes()
    schema_diagram()
    print("Generated PNG files:")
    for p in sorted(OUT_DIR.glob("*.png")):
        print("-", p)


if __name__ == "__main__":
    main()
