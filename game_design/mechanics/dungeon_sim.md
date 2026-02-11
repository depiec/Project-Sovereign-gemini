# Game Mechanic: The Tomb (Dungeon Keeper Style Simulation)

## 1. Overview
The **Tomb** is a top-down, grid-based dungeon management simulation. Players do not just place units; they manage a living ecosystem. You must dig out the Great Tomb, build functional rooms, and keep your heteromorphic minions satisfied.

## 2. Core Dungeon Keeper Mechanics
### 2.1 Digging & Expansion
*   The dungeon starts as a block of unmined rock (except for the Throne Room).
*   **Imps (Undead Workers):** You command a swarm of low-tier undead to dig out tiles.
*   **Tiles:**
    *   **Rock:** Solid, must be dug.
    *   **Claimed Tile:** Once dug, Imps must "Claim" the floor for Nazarick (turning it purple/dark).
    *   **Reinforced Wall:** High-level walls that cannot be easily dug by invaders.

### 2.2 Room Types
Rooms are built by dragging over "Claimed Tiles." Each room type attracts or supports specific minions:
*   **The Treasury:** Required to store **YGGDRASIL Gold**. Without it, you cannot pay or resurrect minions.
*   **The Barracks:** Provides sleeping space for combat minions (Death Knights, Lizardmen).
*   **The Hatchery (The Happy Farm):** Provides "Food" (Sheep) to sustain non-undead minions.
*   **The Library:** Where Liches and Casters research new **Tier Magic** and produce **Scrolls**.
*   **The Workshop:** Where Gondo and the Dwarves produce **Runecraft™** items and traps.

## 3. Minion Management
*   **Attraction:** Unlike standard RTS games, you don't "build" minions. They are attracted to Nazarick based on the size and quality of your rooms (e.g., a large Library attracts high-level Elder Liches).
*   **Needs:** Minions have needs (Hunger, Sleep, Pay). If neglected, they become less efficient or may even abandon their post (except for Undead, who are 100% loyal but less "creative").
*   **The Slap (Supreme Authority):** Ainz can "slap" a minion to force them to work faster. This increases efficiency but slightly lowers happiness/morale.

## 4. Defense & Raids
*   Invaders (Heroes/Workers) enter through "Portals" or the main entrance.
*   They will attempt to "Dig" into your dungeon or find the shortest path to the **Treasury** or **Throne Room**.
*   **Combat:** You can drop minions directly onto invaders, or use the **Possession** mechanic to take direct control of a Guardian (ARPG Layer) to lead the defense.

## 5. Technical Implementation (Godot 4.6+)
*   **TileMap3D / GridMap:** Use Godot's `GridMap` or a custom `VoxelData` system to handle digging.
*   **Navigation:** Use `NavigationServer3D` to dynamically update paths as walls are dug out.
*   **Task System:** A central "Task Queue" where Imps look for work (Dig, Claim, Build).