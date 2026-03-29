# ClaudeCAD

A Claude Code plugin for 3D modeling — design, validate, and export 3D models using natural language.

## Installation

### From GitHub

```bash
claude /install-plugin github:rohittp0/ClaudeCAD
```

### Local Development

```bash
claude --plugin-dir /path/to/ClaudeCAD
```

## Skills

### printable

Design 3D-printable models using OpenSCAD. Generates parametric `.scad` files with automatic mesh validation.

**Workflow:** Interview → Design → Code → Validate → Export STL

**Triggers on:** mentions of 3D printing, OpenSCAD, STL export, printable parts, or physical object design.

## Dependencies

The plugin checks for required tools on session start and warns if any are missing.

### Required

- **OpenSCAD** — Renders `.scad` files to STL

  ```bash
  # macOS
  brew install openscad

  # Ubuntu/Debian
  sudo apt install openscad
  ```

### Recommended

- **admesh** — Validates mesh integrity (disconnected facets, degenerate geometry)

  ```bash
  # macOS
  brew install admesh

  # Ubuntu/Debian
  sudo apt install admesh
  ```

## Hooks

- **SessionStart** — Checks that OpenSCAD and admesh are installed, warns if missing
- **Stop** — Auto-validates any `.scad` files modified during the session

## Roadmap

- [ ] **Blender modeling skill** — Generate 3D models via Python/bpy scripting for complex organic shapes, sculpting, and non-printable visual models
- [ ] **Animation support** — Create model animations and turntable renders for preview and presentation

## License

MIT
