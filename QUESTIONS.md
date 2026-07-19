# Montauk Kart — Decision & Question Log

## Round 6 (your requests)

- **Signs to corners** → placement now picks the best of the 4 intersection corner candidates (diagonal offset ~10 m from center, ~6 m off the pavement) by road clearance. You can only hit one by cutting across a yard.
- **Current-road HUD** → yellow road name under the speedometer (top-left), shows the named road you're on, or "OFF ROAD".
- **Gates are now arches** → rings enlarged (r 2.3→3.2 m) and centered at road level so they read as arches you drive through. Trigger radius tightened 13 m→4.5 m — you must actually pass through.

## Round 5 (your requests)

- **Off-road too punishing** → retuned: engine penalty 0.45→0.72, extra rolling resistance 10→3.5, grip penalty 0.5→0.8. Grass is now slower/bumpier but driveable (~75% of road pace).
- **True-to-life street labels** → floating sprites removed. Now: real street-corner name blades at ~90 intersections, detected from the road graph (nodes where 2+ named roads meet). Green blades with white border/text (Montgomery County style), abbreviated suffixes (MONTAUK AVE), blade oriented parallel to the street it names, stacked for multi-street corners, readable from the road. Also added `?warp=N` URL param (spawn at circuit gate N in the current mode).

## Round 4 (your requests)

- **Heavier driving feel** → steering authority reduced (0.55→0.42 rad), much less lock at speed (falloff 17→13.5), asymmetric steering rate (slow 4.5/s turn-in = weight, fast 7.5/s return-to-center), longer wheelbase (1.7→1.85 m). Tune further by editing `P.steerMax` / the `13.5` falloff / `4.5` rate.
- **Impressive buildings** → two-part upgrade:
  - **Satellite ground imagery**: 100 Esri World Imagery tiles (z17, ~1.2 m/px) stitched into a 2560×2560 texture draped over the whole map (`fetch-tiles.ps1` → `satellite.jpg`, embedded base64). Real yards, driveways, and tree canopy are now visible.
  - **Realistic houses**: hip/gable roofs fitted to each footprint's oriented bounding box (flat roof fallback for complex shapes), roof palette (slate/brown/terracotta), chimneys on ~1/3 of houses, window-textured facades (2 floors).
  - Street View was NOT used — Google's Street View/photorealistic-3D APIs require an API key. If you get a Google Maps Platform key, photorealistic 3D Tiles could replace the procedural buildings entirely.
- Attribution added in-game (OSM + Esri), bottom-right corner.

## Round 3 (answered by you)

- Lap length → **Keep 1.64 km**
- Race extras → **Boost pads + item boxes** on the circuit
  - 6 cyan chevron boost pads (+45% top speed for 1.4 s, FOV kick, whoosh sfx)
  - 7 floating item boxes → roulette → Mushroom (boost) / Golden Mushroom (long boost) / Star (6 s: faster, off-road immune, crash immune). `E` to use.
- Ghost kart → **Yes**: your best total race is recorded (5 Hz samples) and replays as a translucent ghost next race. Persisted in localStorage, shown on the menu.
- Big map → **Tab toggles a 760 px full-circuit map overlay**

## Round 2 (answered by you)

- Game mode → **Lap race** (3 laps, checkpoints, best-lap timing)
- Audio → **Yes, WebAudio synth** (engine, drift screech, crash, gate chime, lap jingle, countdown beeps)
- Kart look → **Kart picker** (5 colors × 2 body styles: Standard / Racer)
- Street labels → **Yes** (floating labels along all named roads, ~170 m spacing)
- Map extent → **Keep 1 km**
- Handling → **Grippier / sim-lite** (grip 7.5→11, drift 2.1→3.4, stronger brakes, harsher off-road)
- Touch controls → **Not now**
- Multiplayer → **Maybe later** (kart state is already isolated in one object + fixed-timestep physics, so a networked model won't need a rewrite)

## The circuit

- **Montauk Ave → Stoneham Rd → Ashburton Ln → Lone Oak Dr**, traced from real OSM geometry (`circuit-trace.ps1` → `circuit.json`)
- 1.64 km lap, 47 gates (~35 m apart), start/finish on Montauk Ave closest to your house
- Orange gate rings, white start ring, cyan sky-beacon + minimap marker + on-screen arrow point to the next gate
- `R` during a race respawns you at the last passed gate; `M` returns to menu

## Round 1 decisions (for reference)

OSM `/api/0.6/map` bbox data · PowerShell converter to embedded `map.json` · single HTML file, three.js r160 via CDN · kinematic bicycle physics @120 Hz · buildings extruded from footprints · procedural street trees · colorful arcade style

## Known limitations

- Multipolygon buildings (relations) skipped (~5% of houses)
- No elevation (OSM has none); gravity implemented but the world is flat
- No wrong-way detection yet
- Audio starts after first keypress (browser autoplay policy)

## New questions (round 5)

1. **Google Maps Platform key?** With a key I could use Photorealistic 3D Tiles (real per-house geometry) or Street View facades. Want to go that route, or are the new roofs+satellite enough?
2. **Driving feel now?** If still not right, tell me which way: heavier (slower steering) or more responsive.
3. **Winter imagery?** Esri's current pass is leaf-off winter. If it looks too dark I can tint the ground brighter, or check other providers (Bing/USGS) for a summer pass.
4. **AI racers next?** With the circuit, ghost replay, and item system in place, CPU opponents are the natural next big feature (they'd follow the racing line with rubber-banding). Want that?
5. **Music?** A simple chiptune loop is possible with WebAudio, or leave it engine-sfx only.

## Previous round (answered in round 3)

1. **Lap length OK?** 1.64 km ≈ 60–90 s/lap. I can shorten (smaller loop) or offer 2 circuits.
2. **Race extras?** Item boxes / boost pads are easy to scatter on the racing line — very Mario Kart.
3. **Time-trial ghost?** I can record your best lap and race a translucent ghost kart against it next time.
4. **Minimap size?** Currently 210 px — want a bigger toggleable map (Tab)?
