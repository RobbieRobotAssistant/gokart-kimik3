# Montauk Kart

A 3D go-kart racing game that runs in your browser, set on the real streets around
**9704 Montauk Ave, Bethesda, MD 20817**. Mario Kart vibes, real neighborhood.

## Play

Open `index.html` — that's it. The whole game (map data + satellite imagery + code) is
one self-contained file. No server, no build, works from `file://`.

## Features

- Real streets, buildings, and street names from OpenStreetMap (~1 km box around the house)
- Satellite ground imagery (Esri World Imagery) + procedural houses with hip roofs and facades
- 1.64 km lap circuit: Montauk Ave → Stoneham Rd → Ashburton Ln → Lone Oak Dr (47 gate arches, 3 laps)
- Best-race ghost kart (saved in localStorage)
- Boost pads + item boxes (mushroom / golden / star), `E` to use
- Street-corner name blades at real intersections, current-road HUD, minimap + full map on `Tab`
- Free-roam mode, 5 kart colors × 2 body styles, synthesized engine/drift/crash audio

## Controls

Desktop: **W/↑** accelerate · **S/↓** brake/reverse · **A D/← →** steer · **Space** drift · **E** item · **R** reset · **Tab** map · **M** menu · **H** help

Mobile (auto-detected): left-thumb floating analog stick to steer, **GAS / BRAKE / DRIFT** buttons on the right, tap the item panel to use items, tap the minimap for full-screen map. Force touch UI on desktop with `?touch`.

Debug: append `?demo` (auto-drive free roam), `?race` (auto-start race), `&warp=N` (spawn at gate N).

## Rebuilding the data

- `convert-osm.ps1` — converts `osm_raw.xml` (OSM `/api/0.6/map` bbox export) → compact `map.json`
- `circuit-trace.ps1` — traces the street loop from `map.json` → `circuit.json` (gate coordinates)
- `fetch-tiles.ps1` — downloads + stitches satellite tiles → `satellite.jpg` + `satbounds.json`
- Re-embed by replacing the `<script id="mapdata">`, `<script id="circuitdata">`, and `<script id="satdata">` contents in `index.html`.

## Credits

- Map data © OpenStreetMap contributors (ODbL)
- Imagery © Esri, Maxar, Earthstar Geographics
- 3D: three.js r160 (CDN)
