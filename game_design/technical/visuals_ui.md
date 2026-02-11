# Technical: Visual Style & UI/UX

## 1. Visual Target (Godot 4.6+)
*   **Art Direction:** "Dark Anime Realism." High-detail models for main characters (accurate to the anime/novel descriptions) set in highly realistic, moody environments.
*   **Lighting:** Heavy use of **SDFGI (Signed Distance Field Global Illumination)** or **VoxelGI** for dynamic, real-time global illumination. Magic spells should be the primary light source in dark dungeons, with [Fireball] or [Holy Light] casting realistic shadows via `OmniLight3D`.
*   **Particle Effects:** "Over-the-top" magical effects using **GPUParticles3D** with custom visual shaders. Tier 10 spells should distort the screen (screen-reading shaders) and create physics-based debris.
*   **Scale:** Using **MultiMeshInstance3D** and Godot's automatic **LOD (Level of Detail)** system to handle massive landscapes in the Strategy Layer and thousands of units in the ARPG Layer without loss of detail.

## 2. User Interface (UI) Design
The UI shifts significantly between the three gameplay layers, leveraging Godot's powerful **Control** nodes and **Theme** resources.

### 2.1 The Throne Room (Strategy View)
*   **Look:** Regal, dark wood and gold borders. A parchment-style map of the New World.
*   **Key HUD Elements:**
    *   *Sasuga Meter:* A glowing `TextureProgressBar` at the top center.
    *   *Resource Bar:* YGGDRASIL Gold, Souls, and Mana Crystals.
    *   *Guardian Portraits:* Quick-access to Guardian locations and tasks.

### 2.2 The Tomb (Sim View)
*   **Look:** Schematic/Blue-print style mixed with 3D room views (`SubViewport` integration).
*   **Key HUD Elements:**
    *   *Floor Status:* Maintenance cost vs. current defense rating.
    *   *Invader Alert:* Mini-map showing where intruders are on the path.

### 2.3 The Battlefield (ARPG View)
*   **Look:** Immersive and minimal.
*   **Key HUD Elements:**
    *   *Mana Wheel:* A stylized circular menu for spell selection (`RadialContainer` or custom shader).
    *   *Super-Tier Progress:* A large magical circle overlay on the HUD that fills as the spell channels.
    *   *Command HUD:* Small icons for giving orders to nearby troops (Charge, Defend, Focus).

## 3. Audio Direction
*   **Music:** Orchestral and operatic. Heavy use of choir for Super-Tier magic. Specific themes for each Guardian (e.g., intimidating classical for Albedo, eerie gothic for Shalltear).
*   **Sound Design:**
    *   *Magic:* Deep, bass-heavy "thrum" for high-tier spells.
    *   *Armor:* Heavy clanking for Momon and Cocytus to emphasize weight.
    *   *Ambient:* Eerie whispers in the lower floors of Nazarick.
    *   *Implementation:* Use `AudioStreamPlayer3D` with bus layouts for reverb zones in dungeons.

## 4. Accessibility
*   **Sim-Mode Automation:** For players who prefer ARPG/Strategy over Dungeon Management, a "Demiurge Auto-Manage" toggle can be enabled.
*   **Visual Cues:** High-contrast indicators for enemy spell-casting areas (AOE markers) using `Decal` nodes.