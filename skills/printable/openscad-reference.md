# OpenSCAD Language Reference

Comprehensive reference for OpenSCAD. Load this when you need syntax details beyond what's in SKILL.md.

## 3D Primitives

```openscad
cube(size = [x,y,z], center = false);           // single value = uniform cube
sphere(r = 1);  // or sphere(d = 2);             // resolution via $fn/$fa/$fs
cylinder(h, r1, r2, center = false);             // r1!=r2 makes cone; also d/d1/d2
polyhedron(points, faces, convexity);            // faces clockwise from outside
```

**Defaults:**
- `cube(size = [1,1,1], center = false)`
- `sphere(r = 1, $fn = 0, $fa = 12, $fs = 2)`
- `cylinder(h = 1, r1 = 1, r2 = 1, center = false)`

**Cylinder gotcha:** Using `cylinder()` with `difference()` for holes creates undersized holes because polygons are inscribed. Compensate: `r = desired_r / cos(180/$fn)`.

## 2D Primitives

```openscad
square(size = [x,y], center = false);
circle(r = 1);  // or circle(d = 2);
polygon(points, paths);                          // paths enables holes
text(t, size, font, halign, valign);
```

## Boolean Operations

```openscad
union() { a(); b(); }                            // combine
difference() { base(); cut1(); cut2(); }         // subtract children 2..N from child 1
intersection() { a(); b(); }                     // keep overlap only
```

**Critical rule:** Subtracted shapes MUST extend past the base. A cut that's flush creates ambiguous faces (non-manifold).

## Transformations

```openscad
translate([x,y,z])
rotate([x,y,z])              // or rotate(angle, [axis_x, axis_y, axis_z])
scale([x,y,z])
mirror([x,y,z])
color("name")                // or color([r,g,b,a])
multmatrix(m)                // 4x4 transformation matrix
offset(r|delta, chamfer)     // 2D only: r=round, delta=sharp
hull() { ... }               // convex hull of children
minkowski() { base(); tool(); }  // minkowski sum (slow but powerful for rounds)
```

## Extrusions

```openscad
linear_extrude(height, center, twist, scale, slices, $fn) 2d_shape;
rotate_extrude(angle, convexity, $fn) 2d_shape;
```

`rotate_extrude`: shape must be in the +X half-plane (x ≥ 0).

## Special Variables

| Variable | Purpose | Typical values |
|----------|---------|----------------|
| `$fn` | Fragment count (circle segments) | 32 preview, 64 render |
| `$fa` | Fragment angle min (degrees) | 12 default |
| `$fs` | Fragment size min (mm) | 2 default |
| `$preview` | true in F5, false in F6 | Conditional `$fn` |
| `$t` | Animation time (0-1) | Animation |
| `$children` | Number of child objects | Inside modules |

**Resolution pattern:** `$fn = $preview ? 32 : 64;`

## Modules & Functions

```openscad
module name(param1, param2 = default_value) {
    // geometry
    children();  // access child objects passed to this module
}

function name(x, y) = expression;  // single expression, returns value
```

## Control Flow

```openscad
for (i = [0:10]) { ... }             // range inclusive
for (i = [0:step:end]) { ... }       // stepped range
for (item = [a, b, c]) { ... }       // iterate vector
if (cond) { ... } else { ... }
cond ? true_val : false_val           // ternary
let (a = expr, b = expr) expression   // scoped binding
```

**List comprehensions:**
```openscad
[for (i = [0:10]) i * i]
[for (i = range) if (cond) expr]
```

## Data Types

- **Numbers:** 64-bit float. `PI` constant available.
- **Strings:** `"double-quoted"`. Escapes: `\"`, `\\`, `\t`, `\n`.
- **Vectors:** `[1, 2, 3]`. Access: `v[0]`, `v.x`, `v.y`, `v.z`.
- **Ranges:** `[start:end]` or `[start:step:end]`. Colons, not commas.
- **Boolean:** `true`, `false`. Falsy: `false`, `0`, `""`, `[]`, `undef`.
- **Undefined:** `undef`. Arithmetic with `undef` → `undef`.

## File Operations

```openscad
include <file.scad>    // executes everything (variables, modules, geometry)
use <file.scad>        // imports only modules and functions
import("file.stl");    // import external 3D geometry
```

## Debug Modifiers

Prefix any object:
- `%` — transparent/ghost (still rendered but see-through)
- `#` — highlight in pink (debug)
- `*` — disable/skip (comment out geometry)
- `!` — show ONLY this object (isolate)

## Math Functions

`abs`, `sign`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`,
`floor`, `ceil`, `round`, `pow`, `sqrt`, `exp`, `ln`, `log`,
`min`, `max`, `norm`, `cross`, `rands`

## String Functions

`str(a, b, ...)` — concatenate to string
`chr(code)` — character from code point
`ord(char)` — code point from character
`len(val)` — length of string/vector
`concat(a, b)` — concatenate vectors

## Key Gotchas

1. **Variables are compile-time constants.** Last assignment wins. You cannot reassign in a loop.
2. **Top-level evaluation order matters.** A variable referencing another must be defined AFTER it. (Inside modules, last-assignment-wins applies.)
3. **Semicolons:** Primitives and single-line transforms need `;`. Blocks wrapping children (`module`, `if`, `for`, `difference`) do NOT.
4. **Non-manifold geometry:** Every edge must connect exactly 2 faces. Causes: touching edges without overlap, flush subtractions, adjacent cut faces touching.
5. **render()** forces CGAL evaluation mid-model. Useful for debugging but slows preview.
