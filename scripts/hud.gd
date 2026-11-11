class_name GameHud
extends Control

var world: GameWorld
var gold_label: Label
var lives_label: Label
var wave_label: Label
var preview_label: Label
var start_button: Button
var speed_button: Button
var sound_button: Button
var cancel_button: Button
var toast_label: Label
var banner_label: Label
var countdown_label: Label
var bar: Panel
var card: Panel
var card_title: Label
var card_desc: Label
var card_stats: Label
var target_button: Button
var sell_button: Button
var close_button: Button
var upgrade_box: VBoxContainer
var upgrade_buttons: Dictionary = {}
var shop_buttons: Dictionary = {}
var overlay: Control
var overlay_title: Label
var overlay_body: Label
var overlay_button: Button
var emblem: Node2D
var _overlay_phase := ""
var menu_page := "title"
var story_button: Button
var levels_button: Button
var back_button: Button
var restart_button: Button
var chapter_box: VBoxContainer
var chapter_buttons: Array = []
var _card_key := ""
var _selected_style: StyleBoxFlat
var _normal_style: StyleBoxFlat


func setup(game: GameWorld) -> void:
	world = game
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 20
	set_anchors_preset(PRESET_FULL_RECT)
	_build_theme()
	_build_bar()
	_build_card()
	_build_toast()
	_build_overlay()


func layout(vp: Vector2, map_origin: Vector2, map_scale: float) -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	bar.position = Vector2.ZERO
	bar.size = Vector2(vp.x, 104)
	var corner := map_origin + Vector2(996, 116) * map_scale
	card.position = Vector2(clampf(corner.x, 8, vp.x - 276), clampf(corner.y, 108, maxf(108, vp.y - 280)))
	card.size = Vector2(268, 268)
	toast_label.position = Vector2(vp.x * 0.5 - 260, 112)
	banner_label.position = Vector2(vp.x * 0.5 - 260, 146)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0


func refresh() -> void:
	if world == null:
		return
	gold_label.text = "Oro %d" % world.gold
	lives_label.text = "Vidas %d" % world.lives
	lives_label.add_theme_color_override("font_color", Color("ffb0a4") if world.lives <= 10 else Color("ffe7b8"))
	wave_label.text = world.wave_label()
	preview_label.text = world.preview_text()
	var wait := world.seconds_until_next()
	if world.phase == "combat":
		start_button.disabled = true
		start_button.text = "Oleada en curso"
	elif wait >= 0:
		start_button.disabled = false
		start_button.text = "Empezar ya (%d)" % wait
	else:
		start_button.disabled = world.phase != "ready"
		start_button.text = "Iniciar oleada"
	speed_button.text = "×%d" % world.speed
	sound_button.text = "Sonido" if world.sfx.enabled else "Mudo"
	cancel_button.visible = world.placing != ""
	for id in shop_buttons:
		var button: Button = shop_buttons[id]
		var definition: Dictionary = world.catalog.tower(id)
		button.text = "%s\n%d" % [definition.name, int(definition.cost)]
		var selected: bool = world.placing == id
		button.disabled = world.gold < int(definition.cost) and not selected
		button.add_theme_stylebox_override("normal", _selected_style if selected else _normal_style)
	toast_label.text = world.current_toast()
	toast_label.visible = toast_label.text != ""
	banner_label.text = world.current_banner()
	banner_label.visible = banner_label.text != ""
	var countdown := world.seconds_until_next()
	if countdown >= 0 and (world.phase == "ready"):
		countdown_label.visible = true
		countdown_label.text = "Oleada %d\nen %d" % [mini(world.wave_number + 1, world.catalog.waves.size()), countdown]
	else:
		countdown_label.visible = false
	_refresh_overlay()
	_refresh_card()


func _build_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 16
	_normal_style = _box(Color("e2b43a"), Color("1a120c"), 10)
	var hover := _box(Color("f0cc62"), Color("1a120c"), 10)
	var pressed := _box(Color("b88828"), Color("1a120c"), 10)
	var disabled := _box(Color("5c5348"), Color("1a120c"), 10)
	_selected_style = _box(Color("d6453d"), Color("1a120c"), 10)
	theme.set_stylebox("normal", "Button", _normal_style)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", _normal_style)
	theme.set_color("font_color", "Button", Color("2a160c"))
	theme.set_color("font_hover_color", "Button", Color("2a160c"))
	theme.set_color("font_pressed_color", "Button", Color("2a160c"))
	theme.set_color("font_disabled_color", "Button", Color("3d3226"))
	theme.set_color("font_color", "Label", Color("ffe7b8"))
	theme.set_font_size("font_size", "Label", 16)
	theme.set_font_size("font_size", "Button", 15)
	self.theme = theme


func _build_bar() -> void:
	bar = Panel.new()
	bar.mouse_filter = MOUSE_FILTER_STOP
	bar.add_theme_stylebox_override("panel", _box(Color("161311"), Color("8d1d22"), 0))
	add_child(bar)
	gold_label = _chip(bar, 8, 8, 128, 52)
	lives_label = _chip(bar, 144, 8, 130, 52)
	wave_label = _chip(bar, 282, 8, 174, 52)
	var x := 468.0
	for id in world.catalog.tower_order:
		var button := _button("")
		_place(bar, button, x, 8, 132, 52)
		var tower_id := str(id)
		button.pressed.connect(func() -> void: world.pick_tower(tower_id))
		shop_buttons[tower_id] = button
		x += 140.0
	start_button = _button("Iniciar oleada")
	_place(bar, start_button, 892, 8, 196, 52)
	start_button.pressed.connect(func() -> void: world.start_wave())
	speed_button = _button("×1")
	_place(bar, speed_button, 1096, 8, 78, 52)
	speed_button.pressed.connect(func() -> void: world.toggle_speed())
	sound_button = _button("Sonido")
	_place(bar, sound_button, 1182, 8, 90, 52)
	sound_button.pressed.connect(func() -> void: world.toggle_sound())
	preview_label = Label.new()
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 15)
	_place(bar, preview_label, 12, 66, 860, 30)
	cancel_button = _button("Cancelar")
	_place(bar, cancel_button, 892, 64, 160, 32)
	cancel_button.pressed.connect(func() -> void: world.cancel_place())
	cancel_button.visible = false


func _build_card() -> void:
	card = Panel.new()
	card.visible = false
	card.mouse_filter = MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _box(Color("1c1612"), Color("c9a24a"), 14))
	add_child(card)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.offset_left = 10
	margin.offset_top = 8
	margin.offset_right = -10
	margin.offset_bottom = -8
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.set_anchors_preset(PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	card_title = _dark_label("")
	card_title.add_theme_font_size_override("font_size", 20)
	box.add_child(card_title)
	card_desc = _dark_label("")
	card_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(card_desc)
	card_stats = _dark_label("")
	card_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(card_stats)
	target_button = _button("Objetivo")
	target_button.custom_minimum_size = Vector2(0, 36)
	target_button.pressed.connect(func() -> void: world.cycle_target())
	box.add_child(target_button)
	upgrade_box = VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 4)
	box.add_child(upgrade_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	sell_button = _button("Vender")
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.custom_minimum_size = Vector2(0, 36)
	sell_button.pressed.connect(func() -> void: world.sell())
	row.add_child(sell_button)
	close_button = _button("Cerrar")
	close_button.custom_minimum_size = Vector2(84, 36)
	close_button.pressed.connect(func() -> void: world.clear_selection())
	row.add_child(close_button)
	for label in [card_title, card_desc, card_stats]:
		label.add_theme_color_override("font_color", Color("f6e7c4"))


func _build_toast() -> void:
	toast_label = Label.new()
	toast_label.mouse_filter = MOUSE_FILTER_IGNORE
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color("2a160c"))
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.custom_minimum_size = Vector2(520, 32)
	toast_label.visible = false
	add_child(toast_label)
	banner_label = Label.new()
	banner_label.mouse_filter = MOUSE_FILTER_IGNORE
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_color_override("font_color", Color("14301a"))
	banner_label.add_theme_font_size_override("font_size", 18)
	banner_label.custom_minimum_size = Vector2(520, 32)
	banner_label.visible = false
	add_child(banner_label)
	countdown_label = Label.new()
	countdown_label.mouse_filter = MOUSE_FILTER_IGNORE
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 48)
	countdown_label.add_theme_color_override("font_color", Color("2a160c"))
	countdown_label.add_theme_color_override("font_outline_color", Color("fff6d0"))
	countdown_label.add_theme_constant_override("outline_size", 10)
	countdown_label.z_index = 25
	countdown_label.visible = false
	countdown_label.set_anchors_preset(PRESET_CENTER)
	countdown_label.offset_left = -220
	countdown_label.offset_right = 220
	countdown_label.offset_top = -70
	countdown_label.offset_bottom = 70
	add_child(countdown_label)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.mouse_filter = MOUSE_FILTER_STOP
	overlay.z_as_relative = false
	overlay.z_index = 200
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.04, 0.02, 0.62)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.offset_left = -320
	panel.offset_right = 320
	panel.offset_top = -300
	panel.offset_bottom = 300
	panel.add_theme_stylebox_override("panel", _box(Color("f6e2bc"), Color("3a2414"), 18))
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.offset_left = 22
	margin.offset_top = 16
	margin.offset_right = -22
	margin.offset_bottom = -16
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.set_anchors_preset(PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 84)
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(holder)
	emblem = preload("res://scripts/emblem.gd").new()
	emblem.position = Vector2(268, 40)
	holder.add_child(emblem)
	overlay_title = _dark_label("Humanos vs Goblins")
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 34)
	box.add_child(overlay_title)
	overlay_body = _dark_label("")
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.custom_minimum_size = Vector2(520, 90)
	box.add_child(overlay_body)
	overlay_button = _button("Jugar")
	overlay_button.custom_minimum_size = Vector2(220, 52)
	overlay_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	overlay_button.pressed.connect(_on_overlay_button)
	box.add_child(overlay_button)
	story_button = _button("Historia")
	story_button.custom_minimum_size = Vector2(220, 46)
	story_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	story_button.pressed.connect(func() -> void:
		menu_page = "story"
		world.sfx.unlock()
		_overlay_phase = ""
		refresh()
	)
	box.add_child(story_button)
	levels_button = _button("Niveles")
	levels_button.custom_minimum_size = Vector2(220, 46)
	levels_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	levels_button.pressed.connect(func() -> void:
		menu_page = "levels"
		world.sfx.unlock()
		_overlay_phase = ""
		refresh()
	)
	box.add_child(levels_button)
	chapter_box = VBoxContainer.new()
	chapter_box.add_theme_constant_override("separation", 6)
	chapter_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(chapter_box)
	for i in world.chapter_count():
		var chapter_button := _button(world.chapter_name(i))
		chapter_button.custom_minimum_size = Vector2(460, 46)
		chapter_button.pressed.connect(_on_chapter.bind(i))
		chapter_box.add_child(chapter_button)
		chapter_buttons.append(chapter_button)
	back_button = _button("Menú")
	back_button.custom_minimum_size = Vector2(220, 46)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button = _button("Reiniciar capítulo")
	restart_button.custom_minimum_size = Vector2(260, 46)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.pressed.connect(func() -> void:
		world.paused = false
		world.restart()
	)
	box.add_child(restart_button)
	back_button.pressed.connect(_on_back)
	box.add_child(back_button)


func _refresh_overlay() -> void:
	var show := world.paused or world.phase == "menu" or world.phase == "won" or world.phase == "lost"
	overlay.visible = show
	bar.visible = world.phase == "ready" or world.phase == "combat"
	overlay.mouse_filter = MOUSE_FILTER_STOP if show else MOUSE_FILTER_IGNORE
	var page := "paused" if world.paused else (menu_page if world.phase == "menu" else world.phase)
	if not show or (_overlay_phase == page and world.phase != "menu"):
		if show and world.phase != "menu":
			overlay_body.text = _overlay_copy()
		return
	if _overlay_phase == page:
		return
	_overlay_phase = page
	emblem.mode = "menu" if world.phase == "menu" else world.phase
	emblem.queue_redraw()
	_fill_overlay(page)


func _fill_overlay(page: String) -> void:
	story_button.visible = false
	levels_button.visible = false
	chapter_box.visible = false
	back_button.visible = false
	restart_button.visible = false
	overlay_button.visible = true
	overlay_body.custom_minimum_size = Vector2(520, 96)
	if page == "title":
		overlay_title.text = "Humanos vs Goblins"
		overlay_button.text = "Jugar"
		story_button.visible = true
		levels_button.visible = true
		overlay_body.text = "%s\n\n%s\n\nJugar abre el primer capítulo. El sonido entra con el primer clic." % [world.campaign_title(), world.chapter_blurb(0)]
	elif page == "story":
		overlay_title.text = world.campaign_title()
		overlay_button.visible = false
		back_button.visible = true
		back_button.text = "Volver"
		overlay_body.custom_minimum_size = Vector2(520, 220)
		overlay_body.text = world.chronicle()
	elif page == "levels":
		overlay_title.text = "Elige capítulo"
		overlay_button.visible = false
		chapter_box.visible = true
		back_button.visible = true
		back_button.text = "Volver"
		overlay_body.text = "Tres campos, una copa. El orden del cronista es el del libro, y puedes entrar en cualquiera."
		for i in chapter_buttons.size():
			var button: Button = chapter_buttons[i]
			var mark := "  ·  superado" if world.chapter_cleared(i) else ""
			button.text = world.chapter_name(i) + mark
	elif page == "paused":
		overlay_title.text = "Pausa"
		overlay_button.text = "Continuar"
		restart_button.visible = true
		back_button.visible = true
		back_button.text = "Menú principal"
		overlay_body.text = "El partido está detenido. Escape o Continuar lo reanudan."
	elif page == "won":
		var last := not world.has_next_chapter()
		overlay_title.text = "¡La copa es del Roble!" if last else "¡Capítulo superado!"
		overlay_button.text = "Menú" if last else "Siguiente capítulo"
		back_button.visible = not last
		back_button.text = "Menú"
		overlay_body.text = _overlay_copy()
	else:
		overlay_title.text = "Derrota"
		overlay_button.text = "Reintentar"
		back_button.visible = true
		back_button.text = "Menú"
		overlay_body.text = _overlay_copy()


func _overlay_copy() -> String:
	if world.phase == "won":
		return "%s\n\n%s\nVidas restantes: %d · Oro: %d" % [world.chapter_name(world.chapter), str(world._chapter(world.chapter).get("win", "")), world.lives, world.gold]
	if world.phase == "lost":
		return "%s se tuerce. Los goblins cruzan la meta.\nCaíste en la oleada %d." % [world.chapter_name(world.chapter), maxi(world.wave_number, 1)]
	return ""


func _on_overlay_button() -> void:
	world.sfx.unlock()
	if world.paused:
		world.toggle_pause()
		return
	if world.phase == "menu":
		menu_page = "title"
		world.chapter = 0
		world.play()
	elif world.phase == "won" and world.has_next_chapter():
		world.start_chapter(world.chapter + 1)
	elif world.phase == "won":
		menu_page = "title"
		_overlay_phase = ""
		world.go_menu()
	else:
		world.restart()


func _on_back() -> void:
	world.sfx.unlock()
	if world.paused:
		menu_page = "title"
		_overlay_phase = ""
		world.go_menu()
		return
	if world.phase == "menu":
		menu_page = "title"
		_overlay_phase = ""
		refresh()
	else:
		menu_page = "title"
		_overlay_phase = ""
		world.go_menu()


func _on_chapter(index: int) -> void:
	world.sfx.unlock()
	menu_page = "title"
	world.start_chapter(index)


func _refresh_card() -> void:
	var tower := world.selected_tower()
	var show := not tower.is_empty() and (world.phase == "ready" or world.phase == "combat")
	card.visible = show
	if not show:
		_card_key = ""
		return
	var key := "%s|%s|%s" % [tower.id, tower.upgrades, tower.target_mode]
	if key != _card_key:
		_card_key = key
		_fill_upgrades(tower)
	var definition: Dictionary = world.catalog.tower(str(tower.def_id))
	var stats := world.catalog.stats_for(str(tower.def_id), tower.upgrades)
	card_title.text = str(definition.name)
	card_desc.text = str(definition.description)
	card_stats.text = _stats_line(stats)
	target_button.text = "Objetivo: %s" % Targeting.mode_label(str(tower.target_mode))
	var refund := Economy.sell_refund(int(tower.invested), float(world.catalog.balance.sell_ratio))
	sell_button.text = "Vender por %d" % refund
	for id in upgrade_buttons:
		var button: Button = upgrade_buttons[id]
		var up := world.catalog.upgrade_def(str(tower.def_id), id)
		var owned := (tower.upgrades as Array).has(id)
		button.disabled = owned or world.gold < int(up.cost)
		button.text = "%s\n%s" % [up.name, "Comprada" if owned else "%d oro" % int(up.cost)]


func _fill_upgrades(tower: Dictionary) -> void:
	for child in upgrade_box.get_children():
		child.queue_free()
	upgrade_buttons.clear()
	var definition: Dictionary = world.catalog.tower(str(tower.def_id))
	for upgrade in definition.upgrades:
		var uid := str(upgrade.id)
		var button := _button(str(upgrade.name))
		button.custom_minimum_size = Vector2(0, 42)
		button.tooltip_text = str(upgrade.description)
		button.pressed.connect(func() -> void: world.upgrade(uid))
		upgrade_box.add_child(button)
		upgrade_buttons[uid] = button


func _stats_line(stats: Dictionary) -> String:
	var parts := PackedStringArray()
	parts.append("Daño %d" % int(stats.damage))
	parts.append("Alcance %d" % int(round(float(stats.range))))
	parts.append("Cada %s s" % _comma(float(stats.cooldown)))
	if float(stats.splash) > 0.0:
		parts.append("Área %d" % int(round(float(stats.splash))))
	if int(stats.pierce) > 1:
		parts.append("Perfora %d" % int(stats.pierce))
	if float(stats.slow_duration) > 0.0:
		parts.append("Ralentiza")
	return " · ".join(parts)


func _comma(value: float) -> String:
	return ("%.2f" % value).replace(".", ",")


func _chip(parent: Node, x: float, y: float, w: float, h: float) -> Label:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _box(Color("100e0c"), Color("c9a24a"), 8))
	_place(parent, panel, x, y, w, h)
	var label := Label.new()
	label.set_anchors_preset(PRESET_FULL_RECT)
	label.offset_left = 0
	label.offset_top = 0
	label.offset_right = 0
	label.offset_bottom = 0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	return button


func _dark_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("2a160c"))
	return label


func _place(parent: Node, ctrl: Control, x: float, y: float, w: float, h: float) -> void:
	ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ctrl.offset_left = x
	ctrl.offset_top = y
	ctrl.offset_right = x + w
	ctrl.offset_bottom = y + h
	parent.add_child(ctrl)


func _box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(3 if radius > 0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box
