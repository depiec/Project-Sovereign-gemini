# Game Mechanic: The Battlefield (Action RPG Layer)

## 1. Overview
The **Battlefield** is the visceral execution layer. It triggers during large-scale army clashes, dungeon raids, or specific "Momon" quests. The game transitions to a 3rd-person perspective, combining "Horde" combat (killing hundreds of weak units) with "Boss" combat (duels against Hero-tier entities).

## 2. Character Switching & Roles
In large battles, you can hot-swap between Ainz and any Floor Guardian present in the combat zone.

*   **Ainz Ooal Gown (Overlord):** The "Artillery Mage." Slow movement, massive AOE damage, and crowd control.
*   **Albedo (Tank):** High defense, shield-bash mechanics, and "Taunt" abilities to protect Ainz.
*   **Shalltear (Life-Steal Brawler):** Fast, aggressive, and heals by damaging enemies. Excellent for 1v1.
*   **Cocytus (Multi-Weapon Master):** Can equip 4 weapons. Has different stances (AOE Cleave vs. Precision Piercing).
*   **Demiurge (Summoner/Tactician):** Doesn't fight directly as well; instead, he summons high-level demons and creates "Command Zones" that buff friendly troops.

## 3. The Magic System: Tiers & Super-Tier
Magic is the core of combat.

*   **Tier 1-10 Spells:**
    *   Assigned to a "Quick-Cast" wheel (8 slots).
    *   Consumes MP. MP regenerates based on the character's "Mana Recovery" stat.
    *   *Examples:* [Fireball] (Tier 3), [Reality Slash] (Tier 10), [Black Hole] (Tier 10).
*   **Super-Tier Magic:**
    *   Activated via a special "Rites" menu.
    *   **The Channeling Mechanic:** Once activated, the character enters a "Prayer" state. A massive magic circle appears. You cannot move or attack.
    *   **Defense:** You must switch to a Guardian to protect the caster (usually Ainz) until the timer hits zero.
    *   **The Payoff:** Massive, screen-clearing effects (e.g., [Creation] to freeze an entire lake, or [Iä Shub-Niggurath] to summon the Dark Young).

## 4. "General" Command Interface
While in 3rd-person, Ainz can issue "Strategic Orders" to the surrounding army (Death Knights, Soul Eaters, etc.).

*   **Formation Toggle:** Switch units between Offensive (Shields down, higher damage) and Defensive (Shield wall).
*   **Targeting:** Point at an enemy unit and command your minions to "Focus Fire."
*   **Execution Order:** A low-cooldown ability where your summons perform a synchronized attack on a specific target.

## 5. The "Momon" Restriction Mode
For specific missions (Infiltration, Hero Quests), Ainz must play as **Momon**.

*   **Restrictions:**
    *   Magic is locked (except for a few low-tier illusion/utility spells).
    *   Appearance is locked to the Black Plate Armor.
    *   Stats are shifted: Higher Physical Attack and Speed, lower Magic Defense.
*   **Hero Reputation:** Completing missions as Momon builds a separate "Hero Rank." Higher ranks allow you to enter human cities without a fight and gather intel for the Strategy Layer.
*   **Exposure Meter:** If you use high-tier magic or act "too evil," your cover is blown, failing the mission or triggering a high-level boss fight against the surrounding heroes.

## 6. Combat Physics & Godot 4.6+ Integration
*   **Destructible Environments:** Spells like [Nuclear Blast] should use `GeometryInstance3D` manipulation or CSG subtraction to physically alter terrain and buildings.
*   **Gore System:** Reflecting the "overwhelming power" of Nazarick, low-level human soldiers should be handled via `PhysicalBone3D` simulations or instanced gore meshes to emphasize the power gap.
