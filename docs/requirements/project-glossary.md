# Project Glossary

**Project:** Man the Ship

**Team:** Team 13 (Gaming)

**Client:** None — this is a student-proposed senior design project.

**Version:** 0.2

## Purpose and Project Context

This glossary gives the development team a shared vocabulary for Man the Ship, a top-down 2D cooperative sailing and survival game. The ship is the primary focus: the crew operates it, maintains it, and uses it to travel toward Paradise Island.

The planned main game loop is: start aboard a docked ship, steer and adjust the sail according to the wind, manage hunger and thirst, optionally stop at nearby islands to dig up treasure chests and obtain supplies, then continue toward Paradise Island.

The current minimal MVP contains only a stationary ship and one player-controlled character who can walk around its deck. Sailing, survival, islands, swimming, repairs, and cooperative networking are not implemented in that MVP. Definitions below describe the intended vocabulary and planned features, not a claim that those features already work or a commitment to implement them all in the next milestone.

The supplied Miro board is the basis for this revision. Notes phrased as questions remain open ideas: additional chest loot, random events, broader island exploration, overboard rescue, and using Paradise Island as an extraction point. Exact player count, numerical settings, failure conditions, and detailed mechanics require team agreement.

## Conventions

- Use one preferred term per concept across requirements, discussions, and code. List alternate names as synonyms.
- Keep definitions in alphabetical order and refer to entries by their term names.
- Define gameplay concepts rather than specific scripts, keyboard controls, or numerical settings.
- Use **development team** for the students building the game, **crew member** for a character, and **player** for the person controlling that character.
- Treat a feature as planned unless it is explicitly included in the current MVP above. Entries labeled **open idea** need a team decision.

## Revision History

| Date | Version | Description | Author |
|---|---|---|---|
| 2026-09-11 | 0.1 | Initial project-specific glossary based on the earlier prototype; prepared for team review. | Leiton Peterson (with AI assistance) |
| 2026-09-13 | 0.2 | Align vocabulary with the Miro main game loop and feature board; distinguish the minimal MVP, planned features, and open ideas. | Leiton Peterson (with AI assistance) |

## Definitions

### Cooperative Play

A planned game mode in which multiple players work together as the crew of one shared ship. The minimal MVP currently supports one player; the supported multiplayer crew size is to be confirmed by the team.

**Synonym:** Co-op.

### Crew

The group of characters aboard the ship who carry out sailing, maintenance, and survival tasks. The minimal MVP has one player-controlled crew member.

### Crew Member

An individual character controlled by a player. A crew member can walk around the deck in the MVP; additional actions such as operating the ship or swimming are planned features.

### Deck

The walkable area aboard the ship. In the minimal MVP, its outer collision boundary keeps the player on the ship. Walking off the ship or going overboard is not currently supported.

### Development Team

The Team 13 students designing, implementing, testing, and documenting the game. The development team defines the project direction, informed by feedback from intended players and course instructors.

### Docked Ship

A ship positioned at a dock before departure. The planned game loop begins with the crew aboard a docked ship; docking interactions and departure mechanics are not yet specified. The MVP's stationary ship does not include a dock.

### Extraction Point

**Open idea:** A location where collected loot could be secured or a voyage could conclude. The board asks whether Paradise Island should serve this purpose; extraction rules are not yet agreed.

### Floating Chest

A chest encountered floating in the ocean. Floating chests are a planned feature, separate from treasure chests dug up on islands. Their contents and collection method are not yet defined.

### Food and Water

Consumable supplies intended to satisfy hunger and thirst. The board suggests finding food and water in chests; quantities, consumption rules, and storage are not yet defined.

### Game Loop

The sequence of activities that structures play: depart from the dock, sail toward Paradise Island, manage hunger and thirst, and make optional island stops for treasure and supplies before continuing the voyage.

### Heading

The direction the ship points. Heading is changed through steering and is distinct from wind direction or the direction a crew member faces.

### Helm

The ship's steering control, used by a crew member to change its heading. How the player interacts with the helm remains an implementation decision.

**Synonyms:** Wheel, steering station.

### Hull Damage

Damage to the ship's body that may require maintenance, such as holes. Ship damage and repair are planned; flooding, damage meters, and sinking or other failure rules have not been specified on the board.

### Hunger and Thirst

The two survival needs identified in the planned game loop. Players manage them by consuming food and water. Depletion rates, penalties, and failure conditions are not yet defined.

### Island

A land area the crew may stop at during a voyage. Planned island activities include walking and digging for treasure; the extent of exploration beyond those activities remains open.

### Loot

Items or resources collected during a voyage. Food and water are suggested chest contents; additional loot types and any inventory or progression system are undecided.

### Minimal MVP

The smallest playable starting point for the team: a stationary ship and a single player-controlled character moving around its bounded deck. This version establishes the basic scene structure and movement without implementing the full planned game loop.

### Overboard

The state of a crew member being in the water outside the ship. Swimming is planned, but the ways a character enters the water or returns aboard still need definition.

### Overboard Rescue

**Open idea:** Helping a crew member return to safety after going overboard. The board raises rescue as a question; its inclusion and mechanics are not yet agreed.

### Paradise Island

The destination the crew aims to reach in the planned main game loop. Whether arrival simply completes the voyage or also serves as loot extraction remains undecided.

**Earlier name:** Paradise Cay. Use Paradise Island to match the current board.

### Player

The person controlling a crew member. This distinguishes the human participant from the character in the game and from members of the development team.

### Random Event

**Open idea:** An encounter or occurrence that could vary a voyage. The board suggests random events but does not yet define event types, triggers, or whether they will be included.

### Repair

A planned maintenance action that fixes ship damage, such as holes. Repair tools, materials, timing, and interactions remain to be decided.

### Sail Adjustment

Changing the sail's orientation in relation to wind direction to influence the ship's movement and speed. This is separate from steering, which changes the ship's heading. The exact wind and speed model is not yet defined.

**Synonym:** Sail trim.

### Ship

The shared vessel that carries the crew through the ocean and is the primary focus of the game. Planned crew activities center on sailing, maintaining, and surviving aboard it. In the minimal MVP, the ship remains stationary.

**Synonyms:** Boat, sailboat.

### Sprinting

Planned movement faster than ordinary walking, associated with stamina use. Sprint speed and stamina costs are not yet defined.

### Stamina

A planned resource associated with sprinting and swimming and displayed through a stamina bar. Depletion, recovery, and the effects of exhaustion remain to be decided.

### Steering

Changing the ship's heading using its steering control. Steering and sail adjustment are separate responsibilities that together support sailing toward the destination.

### Swimming

Planned movement through the water outside the ship, associated with stamina. Entry into the water, boarding, exhaustion, and rescue behavior are not yet specified.

### Treasure Chest

A chest that the crew can dig up during a planned island stop. Food and water are suggested contents; additional rewards are undecided. This differs from a floating chest encountered at sea.

### Voyage

A planned journey beginning aboard the docked ship and progressing toward Paradise Island, with sailing, survival management, and optional island stops. The precise success, failure, restart, and extraction rules remain to be agreed.

### Wind Direction

The direction in which wind travels through the game world. The planned sailing system uses its relationship to the sail to affect movement and speed. This term describes where the wind blows toward, not where it comes from.
