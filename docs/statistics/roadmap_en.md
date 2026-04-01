# Roadmap: Statistics Feature & UI Unification (English)

## 1. Data Layer Expansion (GameManager.gd)
- **New Variables**:
  - `total_games_played`: int
  - `total_time_played`: float
  - `total_kills`: int
  - `total_boss_kills`: int
  - `total_deaths`: int
  - `total_shards_collected`: int
  - `total_damage_dealt`: float
  - `total_distance_traveled`: float
  - `total_potions_consumed`: int
  - `total_dashes_made`: int
  - `max_run_time`: float (Best)
  - `max_run_kills`: int (Best)
  - `max_run_level`: int (Best)
  - `max_kills_per_minute`: int (Fun Record)

- **Logic**:
  - Update `save_game()`/`load_game()` to support these.
  - Create `update_post_run_stats()` to be called on Game Over/Victory.

## 2. Integrated UI Utility (ui_effects.gd)
- Create a global script (Autoload) to unify the look and feel.
- **Methods**:
  - `apply_premium_style(control: Control)`: Sets the dark-blood-gold stylebox.
  - `animate_button_press(button: Button)`: Standardized hover/click scaling.
  - `setup_standard_label(label: Label, size: int)`: Unified font settings.

## 3. Statistics Menu (statistics_menu.tscn)
- **Top Bar**: Title "STATISTICS" and "Back" button.
- **Access**: Only from the Main Menu.
- **Main Body**: `TabContainer` with two pages:

  - **Best Game**: Grid of stats for the best single run.
  - **Overall**: Cumulative stats across all games.
- **Visuals**: Use the refined UI style from step 2.

## 4. Main Menu Refactoring (main_menu.gd/tscn)
- **Remove**: The `RecordFrame` (current High Score panel) on the right side.
- **Add**: A "STATISTICS" button to the main list of buttons.
- **Update**: Use the logic from `ui_effects.gd` to style the entire menu.

## 5. Localization
- Update Russian and English dictionaries in `GameManager.gd` with all new stat labels (e.g., "Total Deaths", "Best Run", etc.).
