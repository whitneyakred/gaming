# Project Glossary

**Project:** Man the Ship

**Team:** Team 13 (Gaming)

**Client:** None — this is a student-proposed senior design project.

**Version:** 0.1

## Purpose and Project Context

This glossary establishes a shared vocabulary for Man the Ship, a top-down 2D cooperative sailing and survival game. The student development team defines the game concept and requirements; there is no external client. Intended players and course instructors are stakeholders whose feedback informs the project.

The current prototype is single-player. Four-player cooperative play is a planned direction, with networking deferred until the local sailing and station interactions are stable. Definitions describe the project vocabulary, not a commitment to implement every feature in the first milestone.

## Conventions

- Use one preferred term per concept across requirements, discussions, and code. List alternate names as synonyms instead of creating duplicate entries.
- Keep definitions in alphabetical order and cite entries by their term names.
- Define gameplay concepts rather than specific classes, controls, or numeric settings.
- Use **development team** for the students building the game and **crew** for the characters aboard the ship.
- Update this glossary when the team agrees on a new term or changes an existing meaning.

## Revision History

| Date | Version | Description | Author |
|---|---|---|---|
| 2026-09-11 | 0.1 | Initial project-specific glossary based on the Man the Ship prototype and student-proposed project context; prepared for team review. | Leiton Peterson (with AI assistance) |

## Definitions

### Capsize

A voyage-ending loss of the ship's balance. In the current prototype, capsize occurs when stability reaches zero; it does not require a physically simulated overturned hull.

### Cooperative Play

A game mode in which players work together as one crew to operate the same ship and survive a voyage. The planned mode supports up to four players; the current prototype supports one player.

**Synonyms:** Co-op.

### Crew

The characters aboard the ship who carry out sailing and survival tasks. In the current prototype, the crew consists of one player-controlled character.

**Not to be confused with:** The development team building the game.

### Crew Member

An individual character who can move around the deck and interact with stations. A crew member is the character in the game; a player is the person controlling that character.

### Deck

The walkable area aboard the ship where crew members move between stations. Crew positions on the deck also affect the ship's balance.

### Development Team

The Team 13 students designing, implementing, testing, and documenting Man the Ship. Because the project is student-proposed, the development team defines its product direction and scope without an external client.

### Heading

The direction the ship is pointing in the game world. Heading is distinct from the direction of the wind and from the direction a crew member faces.

### Heel

The ship's sideways lean in response to sailing forces, waves, and crew weight. Heel describes the lean itself; stability describes the ship's remaining ability to avoid capsizing.

### Helm

The station where a crew member steers the ship and changes its heading.

**Synonyms:** Wheel, steering station.

### Lookout

The station at the mast that gives a crew member an expanded view of the surrounding ocean. The term can also describe the crew member currently using that station; it does not imply a permanent character class.

**Synonyms:** Lookout station.

### Ocean Chunk

A reusable section of the ocean surrounding the ship. Chunks are repositioned as the ship travels so that ocean coverage can continue in any direction without requiring one enormous level.

### Paradise Cay

The destination the crew must reach to win the current prototype's voyage. Reaching it requires keeping the ship stable and managing survival needs along the way.

**Synonyms:** Paradise.

### Player

A person controlling a crew member. The current prototype has one player, while the planned cooperative mode allows multiple players to share responsibility for the same ship.

### Prototype

The early playable version used to test whether the core sailing, station, and survival interactions work well together. Its current single-player behavior does not imply that planned multiplayer features are already available.

### Sail Trim

The adjustment of the sail's angle relative to the wind to affect propulsion and the ship's balance. Raising or lowering the sail changes how much sail is exposed and is a separate adjustment.

### Sailing Station

The station where a crew member adjusts the sail's angle and raises or lowers it. Operating this station controls how the ship uses the wind, while the helm controls steering.

**Synonyms:** Sail station, sail ropes.

### Ship

The shared moving home that carries the crew, stations, and supplies through the ocean. Crew members cooperate to operate and balance this vessel rather than each controlling a separate vessel.

**Synonyms:** Boat, sailboat.

### Stability

The gameplay measure of the ship's ability to remain upright. Sailing conditions and crew balance affect stability; reaching zero causes a capsize in the current prototype.

**Not to be confused with:** Hull damage or a crew member's survival needs.

### Station

An interaction location aboard the ship where a crew member performs a particular task, such as steering, adjusting sails, keeping lookout, or satisfying a survival need. Responsibilities are associated with stations so crew members can change tasks during a voyage.

### Supplies

The food and drinking water carried aboard the ship to satisfy survival needs. The term does not imply a general inventory or crafting system.

### Survival Needs

The crew's bodily needs that must be managed during a voyage: hunger, thirst, and the need to urinate or defecate. The current prototype represents these with meters and can end a voyage when a need becomes critical and is not addressed.

### Voyage

One playable attempt to sail to the destination while keeping the crew alive and the ship stable. In the current prototype, a voyage ends with arrival at Paradise Cay or a failure condition, after which the player can restart.

### Wind Direction

The direction in which the wind blows through the game world. Together with sail trim, it affects how the ship moves and leans; it is not the ship's heading.
