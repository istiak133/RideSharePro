import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw, ImageFont


SQL_PATH = Path("rideshare_schema_optimized.sql")
OUT_DIR = Path("generated_diagrams")
OUT_FILE = OUT_DIR / "rideshare_schema_diagram.png"
REL_OUT_FILE = OUT_DIR / "rideshare_relationship_definitions.png"


def load_font(size: int, bold: bool = False):
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
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def lighten(hex_color: str, ratio: float) -> str:
    h = hex_color.lstrip("#")
    r = int(h[0:2], 16)
    g = int(h[2:4], 16)
    b = int(h[4:6], 16)
    r = min(255, int(r + (255 - r) * ratio))
    g = min(255, int(g + (255 - g) * ratio))
    b = min(255, int(b + (255 - b) * ratio))
    return f"#{r:02x}{g:02x}{b:02x}"


def parse_schema(sql_text: str):
    table_pattern = re.compile(r"CREATE TABLE\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*?)\);", re.IGNORECASE | re.DOTALL)
    ref_pattern = re.compile(r"REFERENCES\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(", re.IGNORECASE)
    col_pattern = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*)\s+(.+)$")

    tables: Dict[str, List[Dict[str, object]]] = {}
    relations: List[Dict[str, object]] = []

    for table_name, body in table_pattern.findall(sql_text):
        cols: List[Dict[str, object]] = []
        for raw in body.splitlines():
            line = raw.strip().rstrip(",")
            if not line or line.startswith("--"):
                continue
            if line.upper().startswith(("CONSTRAINT ", "PRIMARY KEY", "FOREIGN KEY", "UNIQUE ", "CHECK ")):
                continue

            m = col_pattern.match(line)
            if not m:
                continue

            col_name = m.group(1)
            upper = line.upper()
            is_pk = "PRIMARY KEY" in upper
            mandatory = is_pk or ("NOT NULL" in upper)
            ref = ref_pattern.search(line)
            fk_to = ref.group(1) if ref else ""

            cols.append({"name": col_name, "is_pk": is_pk, "is_fk": bool(fk_to), "fk_to": fk_to, "mandatory": mandatory})
            if fk_to:
                relations.append({"child": table_name, "column": col_name, "parent": fk_to, "mandatory": mandatory})

        tables[table_name] = cols

    return tables, relations


def group_relations(relations: List[Dict[str, object]]):
    grouped = {}
    for rel in relations:
        key = (str(rel["child"]), str(rel["parent"]))
        if key not in grouped:
            grouped[key] = {"child": key[0], "parent": key[1], "columns": [], "mandatory_all": True}
        grouped[key]["columns"].append(str(rel["column"]))
        grouped[key]["mandatory_all"] = grouped[key]["mandatory_all"] and bool(rel["mandatory"])

    rows = []
    for key in sorted(grouped.keys(), key=lambda k: (k[1], k[0])):
        v = grouped[key]
        rows.append(v)
    return rows


def pick_fields(columns: List[Dict[str, object]], max_rows: int = 7) -> List[str]:
    selected: List[Dict[str, object]] = []
    for c in columns:
        if c["is_pk"] or c["is_fk"]:
            selected.append(c)

    seen = {c["name"] for c in selected}
    for c in columns:
        if len(selected) >= max_rows:
            break
        if c["name"] not in seen:
            selected.append(c)
            seen.add(c["name"])

    out = []
    for c in selected:
        suffix = ""
        if c["is_pk"]:
            suffix = " (PK)"
        elif c["is_fk"]:
            suffix = " (FK)"
        out.append(str(c["name"]) + suffix)

    if len(columns) > len(selected):
        out.append("...")
    return out


def draw_round(draw: ImageDraw.ImageDraw, xy, radius=18, fill=None, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def center(box):
    x, y, w, h = box
    return x + w // 2, y + h // 2


def anchor(box, side: str):
    x, y, w, h = box
    if side == "left":
        return x, y + h // 2
    if side == "right":
        return x + w, y + h // 2
    if side == "top":
        return x + w // 2, y
    return x + w // 2, y + h


def move_point(x: int, y: int, side: str, d: int):
    if side == "left":
        return x - d, y
    if side == "right":
        return x + d, y
    if side == "top":
        return x, y - d
    return x, y + d


def draw_one_marker(draw: ImageDraw.ImageDraw, x: int, y: int, side: str, color="#2f2f2f", width=4):
    bx, by = move_point(x, y, side, 10)
    if side in ("left", "right"):
        draw.line((bx, by - 14, bx, by + 14), fill=color, width=width)
    else:
        draw.line((bx - 14, by, bx + 14, by), fill=color, width=width)


def draw_many_marker(draw: ImageDraw.ImageDraw, x: int, y: int, side: str, mandatory: bool, color="#2f2f2f", width=4):
    base_x, base_y = move_point(x, y, side, 12)
    if not mandatory:
        draw.ellipse((base_x - 9, base_y - 9, base_x + 9, base_y + 9), outline=color, width=3, fill="#ffffff")
        base_x, base_y = move_point(base_x, base_y, side, 14)
    else:
        if side in ("left", "right"):
            draw.line((base_x, base_y - 12, base_x, base_y + 12), fill=color, width=width)
        else:
            draw.line((base_x - 12, base_y, base_x + 12, base_y), fill=color, width=width)
        base_x, base_y = move_point(base_x, base_y, side, 10)

    if side == "right":
        draw.line((base_x, base_y, base_x + 24, base_y), fill=color, width=width)
        draw.line((base_x, base_y, base_x + 24, base_y - 16), fill=color, width=width)
        draw.line((base_x, base_y, base_x + 24, base_y + 16), fill=color, width=width)
    elif side == "left":
        draw.line((base_x, base_y, base_x - 24, base_y), fill=color, width=width)
        draw.line((base_x, base_y, base_x - 24, base_y - 16), fill=color, width=width)
        draw.line((base_x, base_y, base_x - 24, base_y + 16), fill=color, width=width)
    elif side == "top":
        draw.line((base_x, base_y, base_x, base_y - 24), fill=color, width=width)
        draw.line((base_x, base_y, base_x - 16, base_y - 24), fill=color, width=width)
        draw.line((base_x, base_y, base_x + 16, base_y - 24), fill=color, width=width)
    else:
        draw.line((base_x, base_y, base_x, base_y + 24), fill=color, width=width)
        draw.line((base_x, base_y, base_x - 16, base_y + 24), fill=color, width=width)
        draw.line((base_x, base_y, base_x + 16, base_y + 24), fill=color, width=width)


def polyline(draw: ImageDraw.ImageDraw, pts: List[Tuple[int, int]], color="#333333", width=4):
    for p1, p2 in zip(pts, pts[1:]):
        draw.line((*p1, *p2), fill=color, width=width)


def major_segment_midpoint(pts: List[Tuple[int, int]]) -> Tuple[int, int]:
    best = (pts[0], pts[1])
    best_len = -1
    for p1, p2 in zip(pts, pts[1:]):
        seg_len = abs(p1[0] - p2[0]) + abs(p1[1] - p2[1])
        if seg_len > best_len:
            best_len = seg_len
            best = (p1, p2)
    p1, p2 = best
    return (p1[0] + p2[0]) // 2, (p1[1] + p2[1]) // 2


def choose_side_pair(child_box, parent_box):
    ccx, ccy = center(child_box)
    pcx, pcy = center(parent_box)
    dx = pcx - ccx
    dy = pcy - ccy

    if abs(dx) >= abs(dy):
        if dx >= 0:
            return "right", "left", "h"
        return "left", "right", "h"

    if dy >= 0:
        return "bottom", "top", "v"
    return "top", "bottom", "v"


def route_for_parent(parent: str, child_box, parent_box, lane: int):
    ccx, ccy = center(child_box)
    pcx, pcy = center(parent_box)

    if parent == "users":
        if ccx >= pcx:
            s_side, e_side = "left", "right"
            sx, sy = anchor(child_box, s_side)
            ex, ey = anchor(parent_box, e_side)
            hub_x = parent_box[0] + parent_box[2] + 200 + lane
            return s_side, e_side, [(sx, sy), (hub_x, sy), (hub_x, ey), (ex, ey)]
        s_side, e_side = "right", "left"
        sx, sy = anchor(child_box, s_side)
        ex, ey = anchor(parent_box, e_side)
        hub_x = parent_box[0] - 200 - lane
        return s_side, e_side, [(sx, sy), (hub_x, sy), (hub_x, ey), (ex, ey)]

    if parent == "admin_users":
        if ccx <= pcx:
            s_side, e_side = "right", "left"
            sx, sy = anchor(child_box, s_side)
            ex, ey = anchor(parent_box, e_side)
            hub_x = parent_box[0] - 180 - lane
            return s_side, e_side, [(sx, sy), (hub_x, sy), (hub_x, ey), (ex, ey)]
        s_side, e_side = "left", "right"
        sx, sy = anchor(child_box, s_side)
        ex, ey = anchor(parent_box, e_side)
        hub_x = parent_box[0] + parent_box[2] + 180 + lane
        return s_side, e_side, [(sx, sy), (hub_x, sy), (hub_x, ey), (ex, ey)]

    if parent == "rides":
        if ccy < pcy - 150:
            s_side, e_side = "bottom", "top"
            sx, sy = anchor(child_box, s_side)
            ex, ey = anchor(parent_box, e_side)
            hub_y = parent_box[1] - 180 - lane
            return s_side, e_side, [(sx, sy), (sx, hub_y), (ex, hub_y), (ex, ey)]
        if ccy > pcy + 150:
            s_side, e_side = "top", "bottom"
            sx, sy = anchor(child_box, s_side)
            ex, ey = anchor(parent_box, e_side)
            hub_y = parent_box[1] + parent_box[3] + 180 + lane
            return s_side, e_side, [(sx, sy), (sx, hub_y), (ex, hub_y), (ex, ey)]

    s_side, e_side, mode = choose_side_pair(child_box, parent_box)
    sx, sy = anchor(child_box, s_side)
    ex, ey = anchor(parent_box, e_side)

    if mode == "h":
        mid_x = (sx + ex) // 2 + lane
        return s_side, e_side, [(sx, sy), (mid_x, sy), (mid_x, ey), (ex, ey)]

    mid_y = (sy + ey) // 2 + lane
    return s_side, e_side, [(sx, sy), (sx, mid_y), (ex, mid_y), (ex, ey)]


def make_layout(table_names: List[str]) -> Dict[str, Tuple[int, int]]:
    layout = {
        "otp_verifications": (70, 180),
        "device_tokens": (70, 980),
        "notifications_log": (70, 1780),

        "driver_profiles": (1390, 180),
        "drivers": (1390, 980),
        "fare_rules": (1390, 1780),
        "driver_settlements": (1390, 2580),

        "users": (2710, 980),

        "ride_requests": (4030, 180),
        "rides": (4030, 980),
        "scheduled_ride_jobs": (4030, 1780),
        "ride_route_points": (4030, 2580),

        "payment_methods": (5350, 180),
        "payments": (5350, 980),
        "disputes": (5350, 1780),
        "ratings": (5350, 2580),

        "admin_users": (6670, 180),
        "audit_logs": (6670, 980),
        "verification_logs": (6670, 1780),
        "broadcast_notifications": (6670, 2580),
    }

    for t in table_names:
        layout.setdefault(t, (70, 180))
    return layout


def table_header_color(table: str) -> str:
    per_table = {
        "users": "#1e899f",
        "otp_verifications": "#4caebf",
        "device_tokens": "#4caebf",
        "notifications_log": "#d46566",
        "driver_profiles": "#5ca555",
        "drivers": "#5ca555",
        "fare_rules": "#5f7fc5",
        "driver_settlements": "#8f8f92",
        "ride_requests": "#de9a57",
        "rides": "#df7f34",
        "scheduled_ride_jobs": "#de9a57",
        "ride_route_points": "#de9a57",
        "payment_methods": "#7980c0",
        "payments": "#8b5aa7",
        "disputes": "#d0a53d",
        "ratings": "#ae63c2",
        "admin_users": "#2a7f96",
        "audit_logs": "#6a8eb3",
        "verification_logs": "#6a8eb3",
        "broadcast_notifications": "#cf6b6b",
    }
    return per_table.get(table, "#5a8fb3")


def short_label(cols: List[str]) -> str:
    if len(cols) <= 2:
        return ", ".join(cols)
    return f"{cols[0]}, {cols[1]} +{len(cols) - 2}"


def draw_relationship_definitions(grouped_relations: List[Dict[str, object]]):
    canvas = Image.new("RGB", (4200, 2600), "#f8f8f8")
    draw = ImageDraw.Draw(canvas)

    title_font = load_font(52, bold=True)
    text_font = load_font(28)

    draw.text((40, 24), "RIDESHARE RELATIONSHIP DEFINITIONS", font=title_font, fill="#1f1f1f")
    draw.text((40, 96), "Parent 1:N Child with FK columns", font=load_font(30), fill="#505050")

    lines = []
    for rel in grouped_relations:
        child = str(rel["child"])
        parent = str(rel["parent"])
        cols = ", ".join([str(c) for c in rel["columns"]])
        status = "mandatory" if bool(rel["mandatory_all"]) else "optional"
        lines.append(f"{parent} 1:N {child} | FK: {cols} | {status}")

    col1_x, col2_x = 50, 2120
    y0, lh = 170, 94
    split = (len(lines) + 1) // 2

    for i, line in enumerate(lines[:split]):
        y = y0 + i * lh
        draw_round(draw, (col1_x, y, col1_x + 1980, y + 74), radius=12, fill="#ffffff", outline="#cccccc", width=2)
        draw.text((col1_x + 14, y + 20), line, font=text_font, fill="#242424")
    for i, line in enumerate(lines[split:]):
        y = y0 + i * lh
        draw_round(draw, (col2_x, y, col2_x + 1980, y + 74), radius=12, fill="#ffffff", outline="#cccccc", width=2)
        draw.text((col2_x + 14, y + 20), line, font=text_font, fill="#242424")

    OUT_DIR.mkdir(exist_ok=True)
    canvas.save(REL_OUT_FILE)


def draw_schema():
    sql_text = SQL_PATH.read_text(encoding="utf-8")
    tables, relations = parse_schema(sql_text)
    grouped_relations = group_relations(relations)
    table_order = list(tables.keys())

    canvas = Image.new("RGB", (8200, 4000), "#f2f2f2")
    draw = ImageDraw.Draw(canvas)

    title_font = load_font(62, bold=True)
    subtitle_font = load_font(28)
    table_title_font = load_font(34, bold=True)
    table_body_font = load_font(24)
    edge_label_font = load_font(19, bold=True)
    legend_font = load_font(22)

    draw.text((52, 24), "RIDESHARE DATABASE SCHEMA (MVP)", font=title_font, fill="#1d1d1d")
    draw.text((52, 102), "Crystal-clear ERD with proper FK connections and crow-foot style markers", font=subtitle_font, fill="#555555")

    layout = make_layout(table_order)
    boxes: Dict[str, Tuple[int, int, int, int]] = {}

    for t in table_order:
        fields = pick_fields(tables[t], max_rows=7)
        x, y = layout[t]
        w = 1120
        h = 96 + len(fields) * 38
        boxes[t] = (x, y, w, h)

    for t in table_order:
        x, y, w, h = boxes[t]
        head = table_header_color(t)
        body = lighten(head, 0.82)
        draw_round(draw, (x, y, x + w, y + h), radius=22, fill=body, outline=head, width=4)
        draw_round(draw, (x, y, x + w, y + 66), radius=20, fill=head, outline=head, width=3)
        draw.rectangle((x, y + 34, x + w, y + 66), fill=head)

        title = t.upper()
        tw = draw.textlength(title, font=table_title_font)
        draw.text((x + (w - tw) / 2, y + 14), title, font=table_title_font, fill="#ffffff")

        y_cursor = y + 80
        for f in pick_fields(tables[t], max_rows=7):
            prefix = "*" if "(FK)" in f else ""
            draw.text((x + 18, y_cursor), prefix + f, font=table_body_font, fill="#1f1f1f")
            y_cursor += 38

    lane_map = defaultdict(int)
    lane_cycle = [0, -42, 42, -84, 84, -126, 126, -168, 168]

    for rel in grouped_relations:
        child = str(rel["child"])
        parent = str(rel["parent"])
        columns = [str(c) for c in rel["columns"]]
        mandatory_all = bool(rel["mandatory_all"])

        if child not in boxes or parent not in boxes:
            continue

        idx = lane_map[parent]
        lane_map[parent] += 1
        lane = lane_cycle[idx % len(lane_cycle)] + (idx // len(lane_cycle)) * 20

        child_box = boxes[child]
        parent_box = boxes[parent]
        c_side, p_side, pts = route_for_parent(parent, child_box, parent_box, lane)

        polyline(draw, pts, color="#2f2f2f", width=4)

        sx, sy = pts[0]
        ex, ey = pts[-1]
        draw_many_marker(draw, sx, sy, c_side, mandatory_all, color="#2f2f2f", width=4)
        draw_one_marker(draw, ex, ey, p_side, color="#2f2f2f", width=4)

        lx, ly = major_segment_midpoint(pts)
        lbl = short_label(columns)
        lw = int(draw.textlength(lbl, font=edge_label_font)) + 22
        draw_round(draw, (lx - lw // 2, ly - 16, lx + lw // 2, ly + 16), radius=10, fill="#ffffff", outline="#bfbfbf", width=2)
        draw.text((lx - lw // 2 + 11, ly - 11), lbl, font=edge_label_font, fill="#333333")

    legend_x, legend_y = 6740, 24
    draw_round(draw, (legend_x, legend_y, 8130, 410), radius=16, fill="#ffffff", outline="#bcbcbc", width=2)
    draw.text((legend_x + 22, legend_y + 20), "Notation", font=load_font(30, bold=True), fill="#1f1f1f")
    draw.text((legend_x + 22, legend_y + 72), "(PK) = Primary Key", font=legend_font, fill="#2b2b2b")
    draw.text((legend_x + 22, legend_y + 106), "*(FK) = Foreign Key", font=legend_font, fill="#2b2b2b")
    draw.text((legend_x + 22, legend_y + 140), "Crow-foot side = many", font=legend_font, fill="#2b2b2b")
    draw.text((legend_x + 22, legend_y + 174), "Single bar side = one", font=legend_font, fill="#2b2b2b")
    draw.text((legend_x + 22, legend_y + 208), "Open circle = optional FK", font=legend_font, fill="#2b2b2b")
    draw.text((legend_x + 22, legend_y + 260), "Relationship rule:", font=legend_font, fill="#2b2b2b")
    draw.text((legend_x + 22, legend_y + 292), "Parent 1 : N Child", font=legend_font, fill="#2b2b2b")

    OUT_DIR.mkdir(exist_ok=True)
    canvas.save(OUT_FILE)
    draw_relationship_definitions(grouped_relations)
    print(f"Generated: {OUT_FILE}")
    print(f"Generated: {REL_OUT_FILE}")


if __name__ == "__main__":
    draw_schema()
