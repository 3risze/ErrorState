extends Control

var parallax_layer: Control
var title_label: Label
var settings_panel: PanelContainer
var ui_audio: AudioStreamPlayer
var ui_playback: AudioStreamGeneratorPlayback

var mono_font: SystemFont
var serif_font: SystemFont

func _ready() -> void:
	DisplayServer.window_set_title("ERROR_STATE // Obsidia Archive Terminal")
	_setup_fonts()
	_setup_ui_audio()
	_build_atmosphere()
	_build_menu()
	_build_settings_panel()

func _setup_fonts() -> void:
	mono_font = SystemFont.new()
	mono_font.font_names = PackedStringArray(["Consolas", "Courier New", "Lucida Console"])
	
	serif_font = SystemFont.new()
	serif_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])

func _setup_ui_audio() -> void:
	ui_audio = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.1
	ui_audio.stream = gen
	ui_audio.volume_db = -10.0
	add_child(ui_audio)
	ui_audio.play()
	ui_playback = ui_audio.get_stream_playback() as AudioStreamGeneratorPlayback

func _play_beep(freq: float, duration: float) -> void:
	if not ui_playback:
		return
	var samples: int = int(22050.0 * duration)
	var phase: float = 0.0
	for i in range(samples):
		if ui_playback.get_frames_available() <= 0:
			break
		phase = fmod(phase + (freq / 22050.0), 1.0)
		var env: float = 1.0 - (float(i) / float(samples))
		var sample: float = sin(phase * TAU) * 0.25 * env
		ui_playback.push_frame(Vector2(sample, sample))

func _build_atmosphere() -> void:
	# Latar gelap gradasi
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Partikel debu melayang
	var particles := CPUParticles2D.new()
	particles.position = Vector2(576, 660)
	particles.amount = 35
	particles.lifetime = 8.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(600, 10)
	particles.gravity = Vector2(0, -18)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	particles.color = Color(0.5, 0.65, 0.75, 0.22)
	add_child(particles)
	
	# Layer parallax yang bergerak halus mengikuti mouse
	parallax_layer = Control.new()
	parallax_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(parallax_layer)

func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parallax_layer.add_child(center)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)
	
	var tag := Label.new()
	tag.text = "[ OBSIDIA DATA SOLUTIONS // INTERNAL TERMINAL ]"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_override("font", mono_font)
	tag.add_theme_font_size_override("font_size", 13)
	tag.modulate = Color(0.45, 0.75, 0.85, 0.8)
	vbox.add_child(tag)
	
	title_label = Label.new()
	title_label.text = "ERROR_STATE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", serif_font)
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.modulate = Color(0.94, 0.94, 0.96)
	vbox.add_child(title_label)
	
	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_override("font", mono_font)
	status.add_theme_font_size_override("font_size", 14)
	if FailsafeManager.ending_status == "PURGED":
		status.text = "ARCHIVE BUILD 0.9.4 // STATUS: CONTAINMENT VERIFIED"
		status.modulate = Color(0.35, 1.0, 0.65)
	elif FailsafeManager.ending_status == "COEXIST":
		status.text = "ARCHIVE BUILD 0.9.4 // STATUS: UNKNOWN RESIDENT DETECTED"
		status.modulate = Color(0.55, 0.8, 1.0)
	else:
		status.text = "ARCHIVE BUILD 0.9.4 // LATE-SHIFT DECOMMISSION PROTOCOL"
		status.modulate = Color(0.6, 0.6, 0.65)
	vbox.add_child(status)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 22)
	vbox.add_child(spacer)
	
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 14)
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_box)
	
	var play_btn := _create_juicy_button("PLAY")
	play_btn.pressed.connect(func():
		_play_beep(620.0, 0.08)
		await get_tree().create_timer(0.12).timeout
		get_tree().change_scene_to_file("res://main.tscn")
	)
	btn_box.add_child(play_btn)
	
	var settings_btn := _create_juicy_button("SETTINGS")
	settings_btn.pressed.connect(func():
		_play_beep(520.0, 0.07)
		settings_panel.visible = true
		settings_panel.scale = Vector2(0.92, 0.92)
		create_tween().tween_property(settings_panel, "scale", Vector2.ONE, 0.15)
	)
	btn_box.add_child(settings_btn)
	
	var exit_btn := _create_juicy_button("EXIT")
	exit_btn.pressed.connect(func():
		_play_beep(240.0, 0.1)
		await get_tree().create_timer(0.12).timeout
		get_tree().quit()
	)
	btn_box.add_child(exit_btn)
	
	# CRT Scanline Overlay di atas seluruh menu
	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec2 uv = SCREEN_UV;
		float scan = sin(uv.y * 720.0) * 0.08;
		float vig = length(uv - 0.5) * 0.65;
		COLOR = vec4(0.0, 0.0, 0.0, clamp(scan + vig, 0.0, 0.75));
	}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	crt.material = mat
	add_child(crt)

func _create_juicy_button(base_text: String) -> Button:
	var btn := Button.new()
	btn.text = base_text
	btn.custom_minimum_size = Vector2(290, 50)
	btn.pivot_offset = Vector2(145, 25)
	btn.add_theme_font_override("font", mono_font)
	btn.add_theme_font_size_override("font_size", 20)
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.09, 0.12, 0.85)
	normal_style.border_width_left = 3
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.3, 0.45, 0.55, 0.7)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.14, 0.18, 0.24, 0.95)
	hover_style.border_width_left = 6
	hover_style.border_color = Color(0.4, 0.9, 1.0, 1.0)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	
	btn.mouse_entered.connect(func():
		btn.text = ">  " + base_text + "  <"
		btn.modulate = Color(0.5, 0.95, 1.0)
		_play_beep(440.0, 0.04)
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12)
	)
	btn.mouse_exited.connect(func():
		btn.text = base_text
		btn.modulate = Color.WHITE
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)
	return btn

func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(580, 390)
	settings_panel.pivot_offset = Vector2(290, 195)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.offset_left = -290
	settings_panel.offset_right = 290
	settings_panel.offset_top = -195
	settings_panel.offset_bottom = 195
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.07, 0.09, 0.97)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.4, 0.85, 0.95, 0.85)
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(settings_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	settings_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	var header := Label.new()
	header.text = "SYSTEM DIAGNOSTICS & PREFERENCES"
	header.add_theme_font_override("font", mono_font)
	header.add_theme_font_size_override("font_size", 19)
	header.modulate = Color(0.45, 0.9, 1.0)
	vbox.add_child(header)
	
	var vol_label := Label.new()
	vol_label.text = "Master Audio Output"
	vol_label.add_theme_font_override("font", mono_font)
	vbox.add_child(vol_label)
	
	var vol_slider := HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = 0.8
	vol_slider.value_changed.connect(func(val: float):
		AudioServer.set_bus_volume_db(0, linear_to_db(max(val, 0.001)))
	)
	vbox.add_child(vol_slider)
	
	var glitch_check := CheckButton.new()
	glitch_check.text = "CRT & Screen Tear Distortion"
	glitch_check.add_theme_font_override("font", mono_font)
	glitch_check.button_pressed = FailsafeManager.glitch_enabled
	glitch_check.toggled.connect(func(pressed: bool):
		FailsafeManager.glitch_enabled = pressed
	)
	vbox.add_child(glitch_check)
	
	var log_title := Label.new()
	log_title.text = "RECOVERED SUPERVISOR LOG [ENCRYPTED]:"
	log_title.add_theme_font_override("font", mono_font)
	log_title.modulate = Color(1.0, 0.4, 0.4)
	vbox.add_child(log_title)
	
	var log_body := Label.new()
	log_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	log_body.add_theme_font_override("font", mono_font)
	log_body.add_theme_font_size_override("font_size", 13)
	log_body.modulate = Color(0.78, 0.8, 0.85)
	log_body.text = (
		"MEMO #14: Under NO circumstances should 'entity.dat' be deleted. It is the quarantine seal holding Subject-09.\n"
		+ "In case of desktop breach, open its external text file, overwrite everything with 'PURGE', and save to force termination. (Legacy 'STAY' protocol deprecated.)"
	)
	vbox.add_child(log_body)
	
	var back_btn := _create_juicy_button("BACK")
	back_btn.custom_minimum_size = Vector2(180, 40)
	back_btn.pressed.connect(func():
		_play_beep(350.0, 0.06)
		settings_panel.visible = false
	)
	vbox.add_child(back_btn)

func _process(_delta: float) -> void:
	# Efek parallax halus mengikuti posisi mouse
	var viewport_center := get_viewport_rect().size / 2.0
	var mouse_offset := (get_global_mouse_position() - viewport_center) * -0.025
	parallax_layer.position = parallax_layer.position.lerp(mouse_offset, 0.1)
	
	# Efek kedip horor acak pada judul
	if randf() < 0.015:
		title_label.position.x += randf_range(-5.0, 5.0)
		title_label.modulate = Color(1.0, 0.35, 0.35)
	else:
		title_label.modulate = Color(0.94, 0.94, 0.96)
