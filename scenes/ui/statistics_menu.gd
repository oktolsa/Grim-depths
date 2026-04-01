extends Control

@onready var tabs: TabContainer = %TabContainer
@onready var best_stats_list: VBoxContainer = %BestStatsList
@onready var total_stats_list: VBoxContainer = %TotalStatsList
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel

func _ready() -> void:
	UIEffects.setup_button(back_button)
	UIEffects.style_premium_panel($Panel, true) # Gold border for stats
	_localize_ui()
	_populate_stats()
	_animate_entrance()

func _localize_ui() -> void:
	title_label.text = tr("STATISTICS")
	back_button.text = tr("BACK")
	
	# Tab titles are localized via TabContainer child names or set_tab_title
	tabs.set_tab_title(0, tr("BEST GAME"))
	tabs.set_tab_title(1, tr("OVERALL"))

func _populate_stats() -> void:
	_clear_lists()
	
	var best = GameManager.best_run_stats
	_add_stat_row(best_stats_list, "Max Time:", _format_time(best.get("time", 0.0)))
	_add_stat_row(best_stats_list, "Max Kills:", str(best.get("kills", 0)))
	_add_stat_row(best_stats_list, "Max Boss Kills:", str(best.get("boss_kills", 0)))
	_add_stat_row(best_stats_list, "Max Level:", str(best.get("level", 1)))
	_add_stat_row(best_stats_list, "Max Shards:", str(best.get("shards", 0)))
	_add_stat_row(best_stats_list, "Max Kills/Min:", str(best.get("kills_per_min", 0)))
	
	var total = GameManager.total_stats
	_add_stat_row(total_stats_list, "Games Played:", str(total.get("games_played", 0)))
	_add_stat_row(total_stats_list, "Total Time:", _format_time(total.get("time_played", 0.0)))
	_add_stat_row(total_stats_list, "Total Kills:", str(total.get("kills", 0)))
	_add_stat_row(total_stats_list, "Total Bosses:", str(total.get("boss_kills", 0)))
	_add_stat_row(total_stats_list, "Total Deaths:", str(total.get("deaths", 0)))
	_add_stat_row(total_stats_list, "Total Shards:", str(total.get("shards_collected", 0)))
	_add_stat_row(total_stats_list, "Total Damage:", _format_large_number(total.get("damage_dealt", 0.0)))
	_add_stat_row(total_stats_list, "Total Distance:", str(int(total.get("distance_traveled", 0.0) / 100.0)) + " m")
	_add_stat_row(total_stats_list, "Total Potions:", str(total.get("potions_consumed", 0)))
	_add_stat_row(total_stats_list, "Total Dashes:", str(total.get("dashes_made", 0)))

func _clear_lists() -> void:
	for child in best_stats_list.get_children():
		child.queue_free()
	for child in total_stats_list.get_children():
		child.queue_free()

func _add_stat_row(container: Control, label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl = Label.new()
	lbl.text = tr(label_text)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var val = Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", Color.WHITE)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	hbox.add_child(lbl)
	hbox.add_child(val)
	container.add_child(hbox)
	
	# Add separator
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(1, 1, 1, 0.1)
	container.add_child(sep)

func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%02d:%02d" % [m, s]

func _format_large_number(n: float) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(int(n))

func _animate_entrance() -> void:
	UIEffects.fade_in(self)
	UIEffects.slide_up($Panel)

func _on_back_button_pressed() -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func():
		back_pressed.emit()
		queue_free()
	)

signal back_pressed

