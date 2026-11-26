// Astra Machina Foundation Series SL1680, komplettes Board mit Core-Modul.
// Alle Maße in mm. Der Gehäuseboden ersetzt den serienmäßigen Trägerrahmen.
// Referenzen: SL1680 User Guide (I/O-Ansichten, Rev A), SL2600 User Guide
// (100 × 79 mm für die gemeinsame SL16X0-I/O-Platine). Das Lochraster
// wurde an einem SL1680-Kit mit der Schablone abgeglichen.

/* [Ausgabe] */
part = "base"; // [base:Boden, base_antenna:Boden mit Antennentaschen, lid:Deckel, lid_gpio:Deckel mit GPIO-Öffnung, fit:Lochschablone, assembly:Montageansicht]

/* [Platine] */
board_width = 100;
board_depth = 79;
board_thickness = 1.6;
// Koordinaten ab linker hinterer PCB-Ecke. USB/RJ45/HDMI an der Kante Y=79.
board_hole_left = 4;
board_hole_right = 96;
board_hole_rear = 4;
board_hole_front = 62;
board_standoff = 7;
board_screw_pilot = 2.15; // M2,5 direkt in Kunststoff

/* [Gehäuse] */
space_above_pcb = 27.8;
side_clearance = 7.6;
rear_clearance = 3;
front_clearance = 2;
wall = 2;
floor_thickness = 2.6;
lid_thickness = 2.4;
lid_screw_pilot = 2.65; // M3 direkt in Kunststoff

/* [GPIO-Öffnung] */
// J32 liegt bei X ≈ 4 mm und läuft in Y-Richtung. Die Öffnung liegt
// mittig über der Leiste. Koordinaten relativ zur I/O-Platine.
gpio_opening_x = -2;
gpio_opening_y = 4;
gpio_opening_width = 12;
gpio_opening_length = 58;

/* [Antennentaschen] */
antenna_pocket_length = 52;
antenna_pocket_width = 12;
antenna_pocket_depth = 3.5;

/* [Anschlussöffnungen] */
// Höhe der oberen Kante, gemessen von der Unterseite des Gehäuses.
front_otg_top = 19.5;
front_usb_ethernet_top = 29.5;
front_hdmi_power_top = 21.5;
rear_sd_top = 25;

/* [Hidden] */
$fn = 36;
eps = 0.02;
corner_radius = 3.5;
rim_height = 14;
board_z = floor_thickness + board_standoff;
ceiling = board_z + board_thickness + space_above_pcb;
lid_top = ceiling + lid_thickness;

x_min = -side_clearance - wall;
x_max = board_width + side_clearance + wall;
y_min = -rear_clearance - wall;
y_max = board_depth + front_clearance + wall;

antenna_lip = 2;
antenna_floor_z = max(wall, floor_thickness - 0.8);
antenna_top = antenna_floor_z + antenna_pocket_depth;
antenna_pocket_y = (board_hole_rear + board_hole_front - antenna_pocket_length) / 2;
antenna_pockets_x = [x_min + wall, x_max - wall - antenna_pocket_width];

board_holes = [for (x = [board_hole_left, board_hole_right],
                    y = [board_hole_rear, board_hole_front]) [x, y]];
lid_post_diameter = 6.6;
lid_post_rear_gap = 0.5;
lid_holes = [for (x = [-side_clearance / 2, board_width + side_clearance / 2],
                  y = [-rear_clearance + lid_post_diameter / 2 + lid_post_rear_gap,
                       board_depth - 8]) [x, y]];

module rounded_outline(x0, y0, x1, y1, r) {
    hull() {
        for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r])
            translate([x, y]) circle(r = r);
    }
}

module case_outline() {
    rounded_outline(x_min, y_min, x_max, y_max, corner_radius);
}

module shell(bottom, top, inner_bottom) {
    difference() {
        translate([0, 0, bottom]) linear_extrude(top - bottom) case_outline();
        translate([0, 0, inner_bottom]) linear_extrude(top - bottom + 2 * eps)
            offset(delta = -wall) case_outline();
    }
}

module upright_lid_shell() {
    // Deckel in Montageposition. Die Innenaussparung beginnt an der Fuge.
    difference() {
        translate([0, 0, rim_height]) linear_extrude(lid_top - rim_height) case_outline();
        translate([0, 0, rim_height - eps])
            linear_extrude(ceiling - rim_height + eps)
                offset(delta = -wall) case_outline();
    }
}

module opening(x0, y0, z0, x1, y1, z1) {
    translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
}

module front_port_opening() {
    // Flache Enden für USB-C und HDMI. Im mittleren Bereich bleiben
    // RJ45 und beide USB-A-Doppelbuchsen frei.
    front_port_bottom = 5.2;
    tall_start = 11;
    tall_end = board_width - 30.5;
    transition = 2;
    translate([0, y_max + eps, 0]) rotate([90, 0, 0])
        linear_extrude(y_max - board_depth + 0.2 + eps)
            polygon([[-2, front_port_bottom],
                     [board_width + 2, front_port_bottom],
                     [board_width + 2, front_hdmi_power_top],
                     [tall_end + transition, front_hdmi_power_top],
                     [tall_end, front_usb_ethernet_top],
                     [tall_start, front_usb_ethernet_top],
                     [tall_start - transition, front_otg_top],
                     [-2, front_otg_top]]);
}

module port_openings() {
    front_port_opening();
    // Hinten: microSD und Platz zum Greifen unter das Core-Modul.
    opening(13, y_min - eps, 8.2, board_width - 13, 0.2, rear_sd_top);
    // Rechts: Micro-HDMI-Eingang, MIPI-CSI und Zugang zu den Tastern.
    opening(board_width - 0.2, 3.0, 8.2, x_max + eps, board_depth - 12.5, 30);
}

module slot(x0, x1, y, z, width, depth) {
    translate([0, 0, z]) linear_extrude(depth)
        hull() {
            translate([x0 + width / 2, y]) circle(d = width);
            translate([x1 - width / 2, y]) circle(d = width);
        }
}

module board_standoffs(start_z) {
    for (p = board_holes)
        translate([p.x, p.y, start_z - eps]) cylinder(h = board_standoff + eps, d = 5.8);
}

module board_screw_holes(top_z) {
    for (p = board_holes)
        translate([p.x, p.y, top_z - 6]) cylinder(h = 6 + eps, d = board_screw_pilot);
}

module antenna_pocket_rims() {
    // Die Einfassungen sind mit der vorhandenen Seitenwand verbunden.
    for (x = antenna_pockets_x)
        opening(x - antenna_lip, antenna_pocket_y - antenna_lip, floor_thickness - eps,
                x + antenna_pocket_width + antenna_lip,
                antenna_pocket_y + antenna_pocket_length + antenna_lip, antenna_top);
}

module antenna_pocket_cuts() {
    for (side = [0, 1]) {
        x = antenna_pockets_x[side];
        y_end = antenna_pocket_y + antenna_pocket_length;
        opening(x, antenna_pocket_y, antenna_floor_z,
                x + antenna_pocket_width, y_end, antenna_top + eps);

        // Offener Kabelauslass zur M.2-Karte, mit Spiel für versetzte Lötpunkte.
        channel_x0 = side == 0 ? x + antenna_pocket_width - 2 : x - antenna_lip - 0.8;
        channel_x1 = side == 0 ? x + antenna_pocket_width + antenna_lip + 0.8 : x + 2;
        opening(channel_x0, antenna_pocket_y + 8, antenna_floor_z,
                channel_x1, y_end - 8, antenna_top + eps);
    }
}

module lid_post(p) {
    start_z = floor_thickness - eps;
    translate([p.x, p.y, start_z])
        cylinder(h = ceiling - start_z, d = lid_post_diameter);

    // Die Verstärkung verbindet den Dom unterhalb der Deckelfuge mit der Wand.
    side_wall_x = p.x < 0 ? x_min + wall : x_max - wall;
    opening(min(p.x, side_wall_x) - eps, p.y - 2, start_z,
            max(p.x, side_wall_x) + eps, p.y + 2, rim_height);
}

module base(with_antennas = false) {
    difference() {
        union() {
            shell(0, rim_height, floor_thickness);
            if (with_antennas)
                antenna_pocket_rims();
            board_standoffs(floor_thickness);
            for (p = lid_holes)
                lid_post(p);
        }
        port_openings();
        if (with_antennas)
            antenna_pocket_cuts();
        board_screw_holes(board_z);
        for (p = lid_holes)
            translate([p.x, p.y, ceiling - 9]) cylinder(h = 9 + eps, d = lid_screw_pilot);
        for (y = [20:6:56]) {
            slot(22, 45, y, -eps, 2.6, floor_thickness + 2 * eps);
            slot(55, 78, y, -eps, 2.6, floor_thickness + 2 * eps);
        }
    }
}

module lid(gpio_open = false) {
    left_vent_start = gpio_open ? max(13, gpio_opening_x + gpio_opening_width + 3) : 13;
    difference() {
        upright_lid_shell();
        port_openings();
        for (p = lid_holes)
            translate([p.x, p.y, ceiling - eps]) cylinder(h = lid_thickness + 2 * eps, d = 3.4);
        if (gpio_open)
            translate([0, 0, ceiling - eps]) linear_extrude(lid_thickness + 2 * eps)
                rounded_outline(gpio_opening_x, gpio_opening_y,
                                gpio_opening_x + gpio_opening_width,
                                gpio_opening_y + gpio_opening_length, 1.5);
        // Schlitze im Dach und an der GPIO-Seite für Luftaustausch.
        for (y = [14:5:64]) {
            slot(left_vent_start, 47, y, ceiling - eps, 2.8, lid_thickness + 2 * eps);
            slot(53, 87, y, ceiling - eps, 2.8, lid_thickness + 2 * eps);
        }
        for (y = [14:8:62])
            opening(x_min - eps, y, rim_height - eps, x_min + wall + eps, y + 4, rim_height + 8);
    }
}

module fit_template() {
    jig_floor = 1.6;
    jig_rail = 6.4;
    difference() {
        union() {
            for (y = [board_hole_rear, board_hole_front])
                translate([board_hole_left - jig_rail / 2, y - jig_rail / 2, 0])
                    cube([board_hole_right - board_hole_left + jig_rail, jig_rail, jig_floor]);
            for (x = [board_hole_left, board_hole_right])
                translate([x - jig_rail / 2, board_hole_rear, 0])
                    cube([jig_rail, board_hole_front - board_hole_rear, jig_floor]);
            board_standoffs(jig_floor);
        }
        board_screw_holes(jig_floor + board_standoff);
    }
}

if (part == "base" || part == "base_antenna")
    translate([-x_min, -y_min, 0]) base(with_antennas = part == "base_antenna");
else if (part == "lid" || part == "lid_gpio")
    // Drehung um die Längsachse, wie beim Aufsetzen des gedruckten Deckels.
    translate([x_max, -y_min, lid_top]) rotate([0, 180, 0]) lid(gpio_open = part == "lid_gpio");
else if (part == "fit")
    fit_template();
else if (part == "assembly") {
    color("#26323e") base();
    color("#86aabf") lid();
} else
    assert(false, str("Unbekanntes Druckteil: ", part));
