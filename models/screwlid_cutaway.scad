// Cutaway view of the lid — for inspecting internal threads.
// Not for printing.
include <screwlid_container.scad>;
render_assembly = false;   // override — must come AFTER include (last wins)

difference() {
    lid();
    // Cut front half (y > 0); camera at +Y will look into the cut face
    translate([-200, 0, -10]) cube([400, 400, 200]);
}
