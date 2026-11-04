<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Prototype: Iron Halls (Doom-aehnlicher Raycaster)

**Status:** in-progress

## Hypothese
Ein Retro-Ego-Shooter im Stil der fruehen 90er (Raycasting, Sprite-Gegner,
Tueren, Schluesselkarte) fuehlt sich in einer einzigen HTML-Datei ohne externe
Assets bereits spielbar an: Bewegung, Schiessen und Gegnerdruck tragen ein Level.

## Starten
Datei `index.html` im Browser oeffnen (Chrome/Firefox). Kein Build, keine Abhaengigkeiten.

Optional ueber einen lokalen Server:

```bash
cd prototypes/doomlike && python3 -m http.server 8000
```

## Steuerung
| Taste | Aktion |
|---|---|
| W A S D | Bewegen / Seitwaerts |
| Maus oder Pfeil links/rechts | Drehen |
| Linke Maustaste, Strg, F | Schiessen |
| Leertaste, E | Tueren oeffnen |
| Shift | Rennen |
| 1 / 2 / Mausrad | Waffe wechseln (Shotgun erst nach Fund) |
| M | Karte ein/aus |
| P | Pause |
| R / Enter | Neustart nach Tod oder Sieg |

## Inhalt
- Texturierte Waende, Boden und Decke, Distanznebel
- Schiebetueren, Schluesselkarten-Tuer
- 3 Gegnertypen: Soldat (Hitscan), Imp (Feuerball/Nahkampf), Charger (Nahkampf)
- Gegner-Wegfindung per Distanzfeld, oeffnen Tueren selbst
- Pistole und Shotgun, Medikits, Munition, HUD mit Gesicht
- Synthetische Soundeffekte (WebAudio), keine Dateien

## Findings
Noch offen. Wird nach dem Playtest ergaenzt.
