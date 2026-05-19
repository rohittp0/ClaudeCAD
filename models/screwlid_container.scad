// === Screw-Lid Container ===
// All dimensions in mm
// Material: PETG
// Inner cavity: 63mm dia x 96mm deep
// Print orientation: body base-down, lid closed-top-down (no bridging)

$fn = $preview ? 48 : 96;

// --- User-facing dimensions ---
inner_d        = 63;     // usable internal diameter
inner_h        = 96;     // usable internal depth (base of cavity to underside of lid)

// --- Wall / structure ---
side_wall      = 2.5;    // body side wall thickness
base_wall      = 2.0;    // body base thickness
lid_top_wall   = 2.5;    // lid roof thickness
lid_wall       = 2.0;    // lid skirt side-wall thickness

// --- Thread parameters (right-hand) ---
pitch          = 4.0;    // axial distance per turn
thread_depth   = 1.4;    // radial tooth height
neck_h         = 14.0;   // axial length of threaded neck (~3.5 turns)
neck_minor_d   = inner_d + 2*side_wall;       // 68mm — flush with body OD at valley
neck_major_d   = neck_minor_d + 2*thread_depth; // 70.8mm at tooth crest

// --- Fit clearance (PETG snug) ---
radial_clear   = 0.30;   // per-side radial gap between body crest and lid valley
axial_clear    = 0.40;   // gap between body neck shoulder and lid interior roof

// --- Lid geometry ---
lid_skirt_h    = neck_h + axial_clear + 1.0;       // a bit longer than neck
lid_h          = lid_skirt_h + lid_top_wall;       // total lid height
lid_inner_minor_d = neck_minor_d + 2*radial_clear; // bore at valley (body crest fits)
lid_inner_major_d = neck_major_d + 2*radial_clear; // bore at thread crest (clearance)
lid_od         = lid_inner_major_d + 2*lid_wall;   // outer diameter of lid skirt

// --- Body geometry ---
body_od        = neck_minor_d;          // body OD flush with thread valley
body_h         = base_wall + inner_h;   // height to top of cavity (= base of neck)
total_body_h   = body_h + neck_h;

// --- Detailing ---
fillet_r       = 1.2;
knurl_count    = 24;     // grip ridges around lid OD
knurl_depth    = 0.8;

// --- Resolution for helical extrusion ---
thread_fn      = 64;                              // segments around circumference of thread profile
thread_slices  = ceil(neck_h / pitch * 24);       // vertical slices per thread region

// =========================================================
// === Thread profile (2D): a circle + outward triangular tooth.
// Extruding this with twist creates a single helical external thread.
// =========================================================
module thread_profile_2d(minor_d, depth, pitch_axial) {
    // tooth axial footprint (controls flank slope)
    tooth_w = pitch_axial * 0.55;
    union() {
        circle(d = minor_d);
        // Tooth sticking out radially. polygon is in the X-Z plane of the
        // 2D shape's local frame: X = radial, Y = axial direction (becomes Z
        // after extrusion). The Y coords here become axial offsets after
        // extrusion; with twist they create the helix.
        translate([minor_d/2 - 0.05, 0])
            polygon([
                [0,           -tooth_w/2],
                [depth,        0],
                [0,            tooth_w/2]
            ]);
    }
}

// External thread as a solid helix
module external_thread(minor_d, length, pitch_axial, depth) {
    turns = length / pitch_axial;
    linear_extrude(height = length,
                   twist = -360 * turns,   // negative = right-hand
                   slices = thread_slices,
                   convexity = 10,
                   $fn = thread_fn)
        thread_profile_2d(minor_d, depth, pitch_axial);
}

// Negative used to cut internal threads: same helix, oversized for clearance.
// The bore that receives the screw is cut separately at lid_inner_minor_d.
module internal_thread_cutter(minor_d, length, pitch_axial, depth) {
    turns = length / pitch_axial;
    linear_extrude(height = length,
                   twist = -360 * turns,
                   slices = thread_slices,
                   convexity = 10,
                   $fn = thread_fn)
        thread_profile_2d(minor_d, depth, pitch_axial);
}

// =========================================================
// === Fillet helper (outer convex edge of a cylinder of dia d at height z)
// Subtract from model.
// =========================================================
module outer_fillet(d, z, r) {
    translate([0, 0, z - r])
        rotate_extrude($fn = $fn)
            translate([d/2 - r, 0])
                difference() {
                    square(r + 0.01);
                    circle(r = r);
                }
}

// =========================================================
// === Body ===
// =========================================================
module body() {
    difference() {
        union() {
            // Outer body shell (solid)
            cylinder(d = body_od, h = body_h);
            // Neck shaft (smooth core at thread valley diameter)
            translate([0, 0, body_h])
                cylinder(d = neck_minor_d, h = neck_h);
            // External thread on neck
            translate([0, 0, body_h])
                external_thread(neck_minor_d, neck_h, pitch, thread_depth);
        }
        // Interior cavity — cut at assembly level (extends through neck top)
        translate([0, 0, base_wall])
            cylinder(d = inner_d, h = total_body_h);  // overshoots top => through-hole at top
        // Round bottom outer edge for bed adhesion / comfort
        outer_fillet(body_od, fillet_r, fillet_r);
        // Round top of neck (outside) so thread peaks don't end as a sharp ring
        // (small chamfer 0.5mm)
        translate([0, 0, total_body_h - 0.5])
            difference() {
                cylinder(d = neck_major_d + 4, h = 1);
                cylinder(d1 = neck_major_d, d2 = neck_major_d - 1.0, h = 1);
            }
    }
}

// =========================================================
// === Lid ===
// Printed with closed top on the build plate (top first, skirt grows up).
// Modeled in print orientation: roof at z=0..lid_top_wall, skirt above.
// =========================================================
module lid() {
    difference() {
        union() {
            // Solid outer
            cylinder(d = lid_od, h = lid_h);
            // Grip knurls around skirt
            for (i = [0:knurl_count - 1]) {
                rotate([0, 0, i * 360 / knurl_count])
                    translate([lid_od/2 - 0.01, 0, lid_top_wall + 0.5])
                        cylinder(d = knurl_depth * 2, h = lid_skirt_h - 1);
            }
        }
        // Bore at thread crest diameter (clearance) — this is the "open mouth"
        translate([0, 0, lid_top_wall])
            cylinder(d = lid_inner_major_d, h = lid_skirt_h + 1);
        // Cut the helical thread cavity into the bore wall
        translate([0, 0, lid_top_wall + axial_clear])
            internal_thread_cutter(lid_inner_minor_d,
                                   neck_h,
                                   pitch,
                                   thread_depth);
        // Chamfer the lid mouth (outside-bottom edge) for easy starting
        translate([0, 0, lid_h - 0.6])
            difference() {
                cylinder(d = lid_od + 2, h = 0.8);
                cylinder(d1 = lid_od, d2 = lid_od - 1.2, h = 0.8);
            }
        // Round top outer edge of lid for comfort
        outer_fillet(lid_od, fillet_r, fillet_r);
    }
}

// =========================================================
// === Part selector ===
// Override from CLI: openscad -D 'part="body"' ...    (or "lid", "both")
// =========================================================
part = "both";

if (part == "body")      body();
else if (part == "lid")  lid();
else {
    body();
    translate([body_od/2 + lid_od/2 + 8, 0, 0]) lid();
}
