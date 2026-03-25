# Game Improvement Plan (Grim Depths)

This plan focuses on optimizing the game for mobile devices, improving gameplay balance, and adding variety to ensure a more engaging experience.

## Proposed Changes

### 1. Performance Optimization (Mobile-Focused)
To handle hundreds of entities on mobile, we need to minimize physics overhead and object instantiation.

#### [NEW] [object_pool.gd](file:///d:/Project/grim-depths/scripts/autoload/object_pool.gd)
- Implement a global object pooling system for `ExperienceGem` and `Enemy` instances.
- Pre-instantiate common entities to avoid frame drops during gameplay.

#### [MODIFY] [enemy.gd](file:///d:/Project/grim-depths/scenes/enemy/enemy.gd)
- Replace `move_and_slide()` with simple `global_position` updates for standard enemies to reduce physics calculations.
- Implement "hibernation" logic: stop processing logic for enemies far from the player.

#### [MODIFY] [experience_gem.gd](file:///d:/Project/grim-depths/scenes/experience_gem/experience_gem.gd)
- Integrate with `ObjectPool` to avoid constant `queue_free()` and `instantiate()`.

---

### 2. Gameplay Variety & Balance
Enhance the "survivors-like" core loop with more options and better data management.

#### [NEW] [upgrade_data.gd](file:///d:/Project/grim-depths/scripts/resources/upgrade_data.gd)
- Create a `Resource` type for upgrades to make them data-driven instead of hardcoded in `GameManager`.

#### [NEW] [projectile_weapon.gd](file:///d:/Project/grim-depths/scenes/player/weapons/projectile_weapon.gd)
- Add a new weapon type that fires projectiles at the nearest enemy, complementing the passive Aura.

#### [NEW] [slime.tscn](file:///d:/Project/grim-depths/scenes/enemy/slime/slime.tscn)
- Add a new "Slime" enemy that splits into smaller slimes on death, increasing tactical variety.

---

### 3. Balance Refinement
#### [MODIFY] [game_manager.gd](file:///d:/Project/grim-depths/scripts/autoload/game_manager.gd)
- Refactor `get_random_upgrades` to use the new `UpgradeData` resources.
- Adjust difficulty scaling to be "wave-based" or have progressive spikes rather than pure linear growth.

## Verification Plan

### Automated Tests
- Run the game and monitor FPS using Godot's built-in profiler (Target: 60 FPS with 100+ enemies).
- Verify `ObjectPool` functionality by checking `EntityContainer` child count consistency.

### Manual Verification
- **Stress Test**: Play for 5-10 minutes to ensure difficulty scaling feels natural and the mobile UI remains responsive.
- **Weapon Testing**: Ensure the new Projectile weapon targets enemies correctly and its upgrades (speed, damage) work as expected.
- **Enemy Variety**: Confirm the Slime enemy splits correctly and provides experience gems.
