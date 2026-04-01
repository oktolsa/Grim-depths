# Grim Depths Alpha Roadmap

Plan for improvements and new features required for a pleasant gameplay experience and Alpha mobile release.

## User Review Required

> [!IMPORTANT]
> The "Talents" system requires a UI implementation to make the meta-currency (Soul Shards) useful.
> We should decide on the "Win Condition" - is it a timer (e.g., 10 minutes) or a specific boss defeat?

## Proposed Changes

### Meta-Progression
- **[NEW] [talents_menu.tscn](file:///d:/Project/grim-depths/Grim-depths/scenes/ui/talents_menu.tscn)**: A new menu to spend Soul Shards on permanent buffs (HP, Speed, Aura power).
- **[MODIFY] [main_menu.gd](file:///d:/Project/grim-depths/Grim-depths/scenes/ui/main_menu.gd)**: Connect the "Character Talents" button to the new menu.

### Enemy Variety & AI
- **[NEW] [charger_enemy.gd](file:///d:/Project/grim-depths/Grim-depths/scenes/enemy/charger_enemy.gd)**: A new enemy type that telegraphs and then dashes towards the player.
- **[MODIFY] [enemy_spawner.gd](file:///d:/Project/grim-depths/Grim-depths/scenes/spawner/enemy_spawner.gd)**: Integrate the new enemy type into the spawn waves based on time.

### Gameplay & Balance
- **[MODIFY] [game_manager.gd](file:///d:/Project/grim-depths/Grim-depths/scripts/autoload/game_manager.gd)**: Add more upgrade types (Crit Chance, Regeneration).
- **[MODIFY] [player.gd](file:///d:/Project/grim-depths/Grim-depths/scenes/player/player.gd)**: Implement basic health regeneration logic if the upgrade is picked.

### Game Loop & Polish
- **[MODIFY] [main.gd](file:///d:/Project/grim-depths/Grim-depths/scenes/main/main.gd)**: Implement a survival timer (10:00) that triggers a "Victory" state.
- **[NEW] [victory_screen.tscn](file:///d:/Project/grim-depths/Grim-depths/scenes/ui/victory_screen.tscn)**: A premium-styled screen shown upon successful survival.
- **[NEW] [death_particles.tscn](file:///d:/Project/grim-depths/Grim-depths/scenes/vfx/death_particles.tscn)**: Simple GPU particles for enemy death feedback.

## Verification Plan

### Automated Tests
- No automated tests currently exist. I will verify via manual playtesting using the Godot editor's "Run" feature.

### Manual Verification
- **Talents**: Buy an upgrade in the menu, restart the game, and verify the stat is applied to the player.
- **Enemies**: Observe the "Charger" enemy's telegraph and dash behavior.
- **Win Condition**: Set the timer to 10 seconds for testing and verify the Victory screen appears.
- **Mobile**: Use the editor's "Emulate Touch" feature to verify the new UI elements are reachable and sized correctly for mobile.
