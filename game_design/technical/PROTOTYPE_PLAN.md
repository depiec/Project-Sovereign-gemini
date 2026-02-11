# Technical Prototype Plan: Overlord: Supreme Being (Godot 4.6+)

## 1. Objective: The "Vertical Slice"
The goal of this prototype is not to build the whole game, but to validate the critical "Hybrid Loop"—the transition from **Grand Strategy** to **Dungeon Management** to **Action Combat**.

**Target Scenario:** "The Foresight Invasion"
*   **Step 1 (Strategy):** Detect the "Foresight" worker party approaching Nazarick on the World Map.
*   **Step 2 (Sim):** Deploy traps (Teleportation Circle) and mobs (Old Guarders) in the Arena (6th Floor).
*   **Step 3 (Combat):** Take direct control of Ainz in the Arena to fight the worker team leader, Hekkeran Termite.

## 2. Technical Stack & Tools
*   **Engine:** Godot 4.6+
*   **Language:** GDScript (Primary Gameplay Logic) + C# (Heavy Systems if needed).
*   **Key Godot Features:**
    *   **MultiMeshInstance3D:** For efficiently rendering 100+ "Skeleton" mobs.
    *   **Resource-Based Ability System:** Custom `Resource` classes for defining Spells, Tiers, and Cooldowns.
    *   **Scene Instancing:** Seamless switching between Strategy UI and 3D Combat scenes.
    *   **SDFGI / VoxelGI:** Real-time global illumination for dungeon atmosphere.

## 3. Development Phases

### Phase 1: The Core Loop (Greyboxing)
*Goal: Prove the data flows between layers.*

1.  **The Data Manager (Autoloads/Singletons):**
    *   Create a global `GameManager` script (`Autoload`) that holds:
        *   `WorldState` (Dictionary: Factions, Resources).
        *   `NazarickState` (Dictionary: Floor Levels, Trap Inventory).
        *   `PlayerState` (Resource: Ainz's MP, Known Spells).
2.  **Strategy Layer (Mockup):**
    *   Implement a `Control`-based UI with a `GridContainer` or `TileMapLayer` (if 2D) representing the map.
    *   Clicking a "Threat" button triggers a signal `raid_started` and changes the scene.
3.  **Sim Layer (Placement):**
    *   Load a blank 3D Scene (The Arena).
    *   Implement a "Placement Mode" where the player instantiates a static `Area3D` (Trap) or `CharacterBody3D` (Mob) using a resource cost.
4.  **Combat Layer (Transition):**
    *   On "Start Battle," instantiate the `AinzPlayer` scene.
    *   Implement Basic Movement (`move_and_slide`) and one Spell (Fireball `RigidBody3D` projectile).

### Phase 2: The Systems Implementation
*Goal: Implement the specific mechanics defined in the GDD.*

1.  **Ability System (Custom Resource):**
    *   **Base Class:** `SpellResource.gd` (Export variables: `mana_cost`, `icon`, `cooldown`).
    *   **Spells:**
        *   `Fireball.tres` (Script: Spawns projectile scene).
        *   `SummonUndead.tres` (Script: Instantiates Mob scene).
        *   `SuperTier_FallStart.tres` (Script: Enters Channeling State).
2.  **AI Logic (State Machines/Behavior Trees):**
    *   **Invader AI:** Use `NavigationAgent3D` to move toward "Objective Point." Attack "Hostiles" in detection `Area3D`.
    *   **Minion AI:** Simple State Machine (Idle -> Follow -> Attack).
3.  **The "Sasuga" Dialogue UI:**
    *   Create a `CanvasLayer` scene with a `VBoxContainer` of Buttons.
    *   Connecting button signals updates the `sasuga_meter` variable in the `GameManager`.

### Phase 3: The "Overlord" Feel (Visuals & Polish)
*Goal: Demonstrate the power fantasy.*

1.  **Visuals (GPUParticles3D):**
    *   Create a "Tier 10" visual effect using `GPUParticles3D` and `ShaderMaterial`.
    *   Use `WorldEnvironment` to adjust Glow and Volumetric Fog during the spell cast.
2.  **Camera System:**
    *   Implement a "Strategic Zoom": Mouse scroll transitions `SpringArm3D` length or switches from a `PhantomCamera` (if using addons) to a top-down `Camera3D`.
3.  **Skeletal Mesh Integration:**
    *   Import a placeholder "Ainz" model (glTF/GLB).
    *   Implement **PhysicalBone3D** or a JiggleBone script for the robe physics.

## 4. Success Criteria
The prototype is successful if:
1.  The player can move from Map -> Sim -> Combat scenes smoothly (`SceneTree.change_scene_to_packed`).
2.  The player feels "Overpowered" but "Resource Constrained" (MP drains fast).
3.  The "Sasuga" choice visibly changes the outcome (e.g., UI feedback or Guardian dialogue).