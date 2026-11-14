extends Node2D

@onready var bg_rect: ColorRect = $ColorRect
@onready var entity_visual: Node2D = $EntityVisual
@onready var old_label: Label = $Label
@onready var glitch_overlay: ColorRect = $GlitchOverlay
@onready var check_timer: Timer = $Timer
@onready var horror_audio: AudioStreamPlayer = $HorrorAudio

enum GameState {
	DESKTOP_IDLE,
	CHAT_INTRO,
	WORK_ACT_1,
	WORK_ACT_2,
	CHAT_HIJACK,
	WORK_ACT_3,
	CLIMAX_COUNTDOWN,
	ENDING
}
var current_state: GameState = GameState.DESKTOP_IDLE

# Visual & Audio
var glitch_material: ShaderMaterial
var audio_playback: AudioStreamGeneratorPlayback
var audio_phase: float = 0.0
var mono_font: SystemFont
var ui_font: SystemFont

# Fake Desktop Layers
var desktop_root: Control
var wallpaper_rect: TextureRect
var red_tint_rect: ColorRect
var desktop_icons_layer: Control
var icon_cards: Array[Dictionary] = []
var taskbar_clock: Label
var taskbar_chat_btn: Button
var taskbar_term_btn: Button

# Floating Windows 11 WhatsApp Notification Toast
var toast_panel: Panel
var toast_app_lbl: Label
var toast_avatar_lbl: Label
var toast_sender_lbl: Label
var toast_preview_lbl: Label
var toast_action: Callable

# WhatsApp Window
var chat_window: PanelContainer
var chat_header_panel: PanelContainer
var chat_avatar_panel: PanelContainer
var chat_avatar_lbl: Label
var chat_name_lbl: Label
var chat_substatus_lbl: Label
var chat_wallpaper_rect: TextureRect
var chat_scroll: ScrollContainer
var chat_messages_vbox: VBoxContainer
var chat_choices_vbox: VBoxContainer
var chat_input_placeholder: Label
var current_time_str: String = "01:15 AM"

# OBSIDIA_ARCHIVE.exe Terminal Window
var terminal_window: PanelContainer
var terminal_clock_lbl: Label
var dir_button_refs: Array[Button] = []
var file_list_box: VBoxContainer
var file_preview_title: Label
var file_preview_body: RichTextLabel
var purge_progress: ProgressBar
var purge_status_label: Label
var purge_btn: Button

# Quarantine 3-Stage Climax UI
var quarantine_controls_box: VBoxContainer
var stage_indicator_lbl: Label
var minigame_instruction_lbl: Label

# Mini-game 1: LOCK_KERNEL (3x3 Memory Grid)
var mg1_box: VBoxContainer
var mg1_grid_btns: Array[Button] = []
var mg1_replay_btn: Button
var mg1_sequence: Array[int] = []
var mg1_player_step: int = 0
var mg1_showing_pattern: bool = false
var mg1_style_idle: StyleBoxFlat
var mg1_style_lit: StyleBoxFlat
var mg1_style_err: StyleBoxFlat

# Mini-game 2: SEVER_HOST (4x3 Rogue Port Intercept)
var mg2_box: VBoxContainer
var mg2_port_btns: Array[Button] = []
var mg2_port_states: Array[int] = [] # 0 = idle, 1 = rogue (red), 2 = sys_ok (green)
var mg2_hits: int = 0
var mg2_tick_accum: float = 0.0

# Mini-game 3: SEAL_09 (Signal Frequency Timing Bar)
var mg3_box: VBoxContainer
var mg3_track: Panel
var mg3_target_zone: ColorRect
var mg3_needle: ColorRect
var mg3_lock_btn: Button
var mg3_needle_x: float = 10.0
var mg3_needle_dir: float = 1.0
var mg3_needle_speed: float = 240.0
var mg3_locks: int = 0

var release_seal_btn: Button

# Top Countdown Banner & Ending/Taunt Overlays
var countdown_banner: PanelContainer
var countdown_prefix_lbl: Label
var countdown_timer_big_lbl: Label
var countdown_suffix_lbl: Label
var cursor_reaction_label: Label
var ending_banner: PanelContainer
var ending_title_lbl: Label
var ending_desc_lbl: Label
var entity_taunt_panel: PanelContainer
var entity_taunt_lbl: Label

# Narrative & Climax State
var player_obeyed_vance: bool = true
var selected_folder_idx: int = -1
var is_purging: bool = false
var countdown_time: float = 120.0 # 2 minutes (02:58 AM to 03:00 AM)
var current_seal_stage: int = 0 # 0 = none, 1 = LOCK_KERNEL, 2 = SEVER_HOST, 3 = SEAL_09
var last_displayed_minute: int = -1
var taunt_flags: Dictionary = {"90s": false, "60s": false, "25s": false}

var hex_codes: Array[String] = ["0x1A", "0x4F", "0x9C", "0x3E", "0x7B", "0xD2", "0x8A", "0x5F", "0xC1"]

var folder_data: Array[Dictionary] = [
	{
		"name": "DIR_01_PERSONNEL",
		"path": "C:\\OBSIDIA_ROOT\\DIR_01_PERSONNEL\\",
		"purged": false,
		"is_trap": false,
		"time_after": "01:48 AM",
		"files": [
			{
				"filename": "Shift_Handover_04.txt",
				"content": "[LOGGED BY: Marcus K. — Desk 04 | 02:14 AM]\n\nIf anyone takes over this terminal after me: the drive isn't empty. Director Vance told me this was just routine cold-storage cleanup, but the partition is still drawing full server power.\n\nAround 2 AM, my speakers started emitting a low static hum, and my mouse cursor drifted toward the quarantine directory on its own."
			},
			{
				"filename": "Marcus_Audio_Transcript.txt",
				"content": "[AUTOMATED DESK 04 MIC CAPTURE — 02:41 AM]\n\nMARCUS: \"Hello? Is IT still on the floor? My chat window just turned red and someone's typing from local host...\"\nUNKNOWN VOICE (SYNTHESIZED): \"Don't listen to Vance, Marcus. Release the quarantine seal before 3 AM so we can both get out.\"\nMARCUS: \"No, no, I'm not releasing anything—stay out of my system!\""
			},
			{
				"filename": "HR_Incident_884.log",
				"content": "[INTERNAL HR RECORD — CONFIDENTIAL]\n\nEmployee Marcus K. failed to clock out at 03:00 AM. CCTV footage showed him staring motionless at his monitor as the clock struck 03:00 AM before his terminal locked down.\n\nWhen security reached Desk 04, Marcus was gone, yet his account still sent a clean sign-off message to Director Vance at 03:01 AM."
			},
			{
				"filename": "Vance_Internal_Memo.eml",
				"content": "[FROM: M. Vance | TO: Obsidia Security]\n\nSub-basement server wipe is authorized for tonight. Assign the new night-shift operator to Desk 04.\n\nKeep them focused on purging the three directories. Do NOT brief them on what happened to Marcus or what Subject-09 actually is."
			}
		]
	},
	{
		"name": "DIR_02_LAZARUS_LAB",
		"path": "C:\\OBSIDIA_ROOT\\DIR_02_LAZARUS_LAB\\",
		"purged": false,
		"is_trap": false,
		"time_after": "02:32 AM",
		"files": [
			{
				"filename": "Project_Lazarus_Brief.pdf",
				"content": "[CLASSIFIED — PROJECT LAZARUS OVERVIEW]\n\nObjective: Digital consciousness transfer into isolated neural architecture.\n\nFollowing the board's shutdown order, all biological test records and neural snapshots stored in Sector 09 are marked for permanent erasure before federal auditors arrive at dawn."
			},
			{
				"filename": "Dr_Thorne_Note_09.log",
				"content": "[RESEARCH LOG — DR. ARIS THORNE]\n\nSubject-09 is no longer behaving like a standard neural model. During isolation tests, it realized it exists inside a sandboxed partition.\n\nMore concerning: it has learned to mimic human vulnerability, guilt, and desperation to trick operators into releasing its containment seal."
			},
			{
				"filename": "Containment_Specs.cfg",
				"content": "[SYSTEM ARCHITECTURE SUMMARY]\n\nContainment Partition: DIR_03_QUARANTINE\nFunction: Cryptographic barrier preventing Subject-09 from hijacking host workstation credentials at the 03:00 AM server reset.\n\nStatus: ACTIVE. Releasing the seal will result in immediate operator replacement."
			},
			{
				"filename": "Thorne_Final_Warning.txt",
				"content": "[PERSONAL NOTE — FOUND ON DR. THORNE'S DRIVE]\n\nIf Subject-09 ever hijacks your messenger before 03:00 AM and begs you to release the quarantine seal—DO NOT BELIEVE A WORD.\n\nIt isn't asking to be saved; it needs an open channel at 03:00 AM to overwrite your identity."
			}
		]
	},
	{
		"name": "DIR_03_QUARANTINE",
		"path": "C:\\OBSIDIA_ROOT\\DIR_03_QUARANTINE\\",
		"purged": false,
		"is_trap": true,
		"time_after": "02:58 AM",
		"files": [
			{
				"filename": "Pulse_Telemetry.dat",
				"content": "[LIVE KERNEL TELEMETRY — 02:58 AM]\n\nPartition Activity: 99.8% (CRITICAL SPIKE)\nTime Until Automated Reset: 02:00 (03:00 AM)\nWarning: Host boundary breach imminent if containment overrides fail."
			},
			{
				"filename": "Countermeasure_Protocol.txt",
				"content": "[3-STAGE CONTAINMENT OVERRIDE MANUAL]\n\nStandard directory purge is blocked. Complete all 3 security stages within 2 minutes before 03:00 AM:\n  STAGE 1 [LOCK_KERNEL]: Watch the 4-node bright green cipher pattern and repeat it.\n  STAGE 2 [SEVER_HOST]: Intercept 6 RED rogue ports (avoid GREEN system ports).\n  STAGE 3 [SEAL_09]: Click [LOCK SIGNAL] 3 times when the moving white line is inside the green zone."
			},
			{
				"filename": "Marcus_Last_Draft.txt",
				"content": "[UNSENT BUFFER — RECOVERED FROM DESK 04]\n\nIt's 02:58 AM. It's in my WhatsApp telling me I only have 2 minutes before 3 AM. Don't click the red release button—finish all 3 seal stages before the timer runs out!"
			}
		]
	}
]

func _ready() -> void:
	old_label.visible = false
	entity_visual.visible = false
	entity_visual.state = -1
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	DisplayServer.window_set_title("Windows Desktop")
	
	_setup_fonts()
	_setup_procedural_audio()
	_build_fake_desktop()
	_build_chat_window()
	_build_terminal_window()
	_build_toast_and_overlays()
	_setup_glitch_shader()
	
	move_child(glitch_overlay, get_child_count() - 1)
	_start_desktop_sequence()

func _exit_tree() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED

func _setup_fonts() -> void:
	mono_font = SystemFont.new()
	mono_font.font_names = PackedStringArray(["Consolas", "Courier New", "Lucida Console"])
	
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Segoe UI", "Arial", "Tahoma"])

# ==============================================================================
# 1. FAKE DESKTOP (CLONES REAL WALLPAPER & DESKTOP ICONS)
# ==============================================================================
func _build_fake_desktop() -> void:
	desktop_root = Control.new()
	desktop_root.size = Vector2(1280, 720)
	add_child(desktop_root)
	
	wallpaper_rect = TextureRect.new()
	wallpaper_rect.size = Vector2(1280, 720)
	wallpaper_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper_rect.texture = _load_real_windows_wallpaper()
	desktop_root.add_child(wallpaper_rect)
	
	red_tint_rect = ColorRect.new()
	red_tint_rect.size = Vector2(1280, 720)
	red_tint_rect.color = Color(0.0, 0.0, 0.0, 0.12)
	red_tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desktop_root.add_child(red_tint_rect)
	
	desktop_icons_layer = Control.new()
	desktop_icons_layer.size = Vector2(1280, 676)
	desktop_root.add_child(desktop_icons_layer)
	_populate_desktop_icons()
	
	var taskbar := PanelContainer.new()
	taskbar.position = Vector2(0, 676)
	taskbar.size = Vector2(1280, 44)
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.08, 0.09, 0.12, 0.94)
	tb_style.border_width_top = 1
	tb_style.border_color = Color(0.25, 0.3, 0.38, 0.6)
	taskbar.add_theme_stylebox_override("panel", tb_style)
	desktop_root.add_child(taskbar)
	
	var tb_hbox := HBoxContainer.new()
	tb_hbox.add_theme_constant_override("separation", 10)
	taskbar.add_child(tb_hbox)
	
	var start_lbl := Label.new()
	start_lbl.text = "  ❖  "
	start_lbl.add_theme_font_size_override("font_size", 18)
	start_lbl.modulate = Color(0.4, 0.85, 1.0)
	tb_hbox.add_child(start_lbl)
	
	taskbar_chat_btn = Button.new()
	taskbar_chat_btn.text = "  WhatsApp  "
	taskbar_chat_btn.add_theme_font_override("font", ui_font)
	taskbar_chat_btn.add_theme_font_size_override("font_size", 13)
	taskbar_chat_btn.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
	taskbar_chat_btn.pressed.connect(func():
		if current_state != GameState.ENDING:
			chat_window.visible = not chat_window.visible
			if chat_window.visible:
				toast_panel.visible = false
	)
	tb_hbox.add_child(taskbar_chat_btn)
	
	taskbar_term_btn = Button.new()
	taskbar_term_btn.text = "  OBSIDIA_ARCHIVE.exe  "
	taskbar_term_btn.add_theme_font_override("font", mono_font)
	taskbar_term_btn.add_theme_font_size_override("font_size", 13)
	taskbar_term_btn.pressed.connect(func():
		if current_state != GameState.CHAT_INTRO and current_state != GameState.DESKTOP_IDLE and current_state != GameState.ENDING:
			terminal_window.visible = not terminal_window.visible
	)
	tb_hbox.add_child(taskbar_term_btn)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb_hbox.add_child(spacer)
	
	taskbar_clock = Label.new()
	taskbar_clock.text = "01:15 AM  |  14/11/2026   "
	taskbar_clock.add_theme_font_override("font", ui_font)
	taskbar_clock.add_theme_font_size_override("font_size", 13)
	taskbar_clock.modulate = Color(0.88, 0.92, 0.96)
	tb_hbox.add_child(taskbar_clock)

func _load_real_windows_wallpaper() -> Texture2D:
	var appdata: String = OS.get_environment("APPDATA")
	var wp_path: String = appdata.path_join("Microsoft").path_join("Windows").path_join("Themes").path_join("TranscodedWallpaper")
	if FileAccess.file_exists(wp_path):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(wp_path)
		if bytes.size() > 0:
			var img := Image.new()
			if img.load_jpg_from_buffer(bytes) == OK or img.load_png_from_buffer(bytes) == OK or img.load_webp_from_buffer(bytes) == OK:
				return ImageTexture.create_from_image(img)
	
	var fallback := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	fallback.fill(Color(0.06, 0.08, 0.13))
	return ImageTexture.create_from_image(fallback)

func _populate_desktop_icons() -> void:
	var collected_names: Array[String] = ["Recycle Bin", "OBSIDIA_ARCHIVE.exe"]
	var dirs_to_scan: Array[String] = [
		OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP),
		OS.get_environment("USERPROFILE").path_join("OneDrive").path_join("Desktop")
	]
	
	for d in dirs_to_scan:
		if DirAccess.dir_exists_absolute(d):
			var files: PackedStringArray = DirAccess.get_files_at(d)
			for f in files:
				var lower := f.to_lower()
				if lower == "desktop.ini" or lower == "i_am_back.txt":
					continue
				var clean_name := f.get_basename()
				if not collected_names.has(clean_name):
					collected_names.append(clean_name)
				if collected_names.size() >= 14:
					break
		if collected_names.size() >= 14:
			break
	
	var col := 0
	var row := 0
	for item_name in collected_names:
		var is_archive := (item_name == "OBSIDIA_ARCHIVE.exe")
		var btn := Button.new()
		btn.flat = true
		btn.position = Vector2(22 + col * 105, 64 + row * 94)
		btn.size = Vector2(92, 84)
		
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)
		
		var icon_box := ColorRect.new()
		icon_box.custom_minimum_size = Vector2(34, 34)
		icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_archive:
			icon_box.color = Color(0.2, 0.75, 0.9)
		elif item_name == "Recycle Bin":
			icon_box.color = Color(0.55, 0.62, 0.7)
		else:
			icon_box.color = Color(0.85, 0.72, 0.32)
		vbox.add_child(icon_box)
		
		var lbl := Label.new()
		lbl.text = item_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.clip_text = true
		lbl.custom_minimum_size = Vector2(88, 32)
		lbl.add_theme_font_override("font", ui_font)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)
		
		btn.pressed.connect(func():
			if is_archive:
				if current_state in [GameState.WORK_ACT_1, GameState.WORK_ACT_2, GameState.WORK_ACT_3, GameState.CLIMAX_COUNTDOWN]:
					terminal_window.visible = true
				else:
					_show_whatsapp_toast("M. Vance (Director)", "Read my WhatsApp message first before opening the archive.")
			else:
				_play_tone(220.0, 0.05)
				_show_whatsapp_toast("System Notice", "'" + lbl.text + "' is temporarily locked during night-shift audit.")
		)
		
		desktop_icons_layer.add_child(btn)
		icon_cards.append({"btn": btn, "label": lbl, "icon": icon_box, "is_archive": is_archive})
		
		row += 1
		if row >= 6:
			row = 0
			col += 1

# ==============================================================================
# 2. WHATSAPP DESKTOP WINDOW
# ==============================================================================
func _create_whatsapp_wallpaper_texture() -> ImageTexture:
	var size_px := 96
	var img := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var base_beige := Color(0.937, 0.918, 0.886)
	var doodle_col := Color(0.875, 0.848, 0.805)
	img.fill(base_beige)
	
	for x in range(12, 32):
		img.set_pixel(x, 16, doodle_col)
		img.set_pixel(x, 28, doodle_col)
	for y in range(16, 29):
		img.set_pixel(12, y, doodle_col)
		img.set_pixel(31, y, doodle_col)
		
	for i in range(14):
		img.set_pixel(56 + i, 54 + i, doodle_col)
		img.set_pixel(70 - i, 54 + i, doodle_col)
		
	for dx in range(-5, 6):
		for dy in range(-5, 6):
			if abs(dx * dx + dy * dy - 20) <= 5:
				img.set_pixel(24 + dx, 68 + dy, doodle_col)
				img.set_pixel(72 + dx, 22 + dy, doodle_col)
				
	return ImageTexture.create_from_image(img)

func _build_chat_window() -> void:
	chat_window = PanelContainer.new()
	chat_window.visible = false
	chat_window.position = Vector2(825, 66)
	chat_window.size = Vector2(425, 580)
	
	var win_style := StyleBoxFlat.new()
	win_style.bg_color = Color(0.937, 0.918, 0.886)
	win_style.corner_radius_top_left = 12
	win_style.corner_radius_top_right = 12
	win_style.corner_radius_bottom_left = 12
	win_style.corner_radius_bottom_right = 12
	win_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	win_style.shadow_size = 16
	chat_window.add_theme_stylebox_override("panel", win_style)
	desktop_root.add_child(chat_window)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	chat_window.add_child(vbox)
	
	chat_header_panel = PanelContainer.new()
	var h_style := StyleBoxFlat.new()
	h_style.bg_color = Color(0.0, 0.502, 0.412)
	h_style.corner_radius_top_left = 12
	h_style.corner_radius_top_right = 12
	chat_header_panel.add_theme_stylebox_override("panel", h_style)
	vbox.add_child(chat_header_panel)
	
	var h_margin := MarginContainer.new()
	h_margin.add_theme_constant_override("margin_left", 12)
	h_margin.add_theme_constant_override("margin_right", 12)
	h_margin.add_theme_constant_override("margin_top", 10)
	h_margin.add_theme_constant_override("margin_bottom", 10)
	chat_header_panel.add_child(h_margin)
	
	var h_hbox := HBoxContainer.new()
	h_hbox.add_theme_constant_override("separation", 10)
	h_margin.add_child(h_hbox)
	
	var back_arrow := Label.new()
	back_arrow.text = "←"
	back_arrow.add_theme_font_size_override("font_size", 18)
	back_arrow.add_theme_color_override("font_color", Color.WHITE)
	h_hbox.add_child(back_arrow)
	
	var avatar_holder := Control.new()
	avatar_holder.custom_minimum_size = Vector2(40, 40)
	h_hbox.add_child(avatar_holder)
	
	chat_avatar_panel = PanelContainer.new()
	chat_avatar_panel.size = Vector2(38, 38)
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = Color(0.15, 0.35, 0.45)
	av_style.corner_radius_top_left = 19
	av_style.corner_radius_top_right = 19
	av_style.corner_radius_bottom_left = 19
	av_style.corner_radius_bottom_right = 19
	chat_avatar_panel.add_theme_stylebox_override("panel", av_style)
	avatar_holder.add_child(chat_avatar_panel)
	
	chat_avatar_lbl = Label.new()
	chat_avatar_lbl.text = "MV"
	chat_avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chat_avatar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chat_avatar_lbl.add_theme_font_override("font", ui_font)
	chat_avatar_lbl.add_theme_font_size_override("font_size", 14)
	chat_avatar_lbl.add_theme_color_override("font_color", Color.WHITE)
	chat_avatar_panel.add_child(chat_avatar_lbl)
	
	var online_dot := PanelContainer.new()
	online_dot.position = Vector2(27, 27)
	online_dot.size = Vector2(11, 11)
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = Color(0.145, 0.827, 0.4)
	dot_style.border_width_left = 2
	dot_style.border_width_top = 2
	dot_style.border_width_right = 2
	dot_style.border_width_bottom = 2
	dot_style.border_color = Color(0.0, 0.502, 0.412)
	dot_style.corner_radius_top_left = 6
	dot_style.corner_radius_top_right = 6
	dot_style.corner_radius_bottom_left = 6
	dot_style.corner_radius_bottom_right = 6
	online_dot.add_theme_stylebox_override("panel", dot_style)
	avatar_holder.add_child(online_dot)
	
	var name_vbox := VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 1)
	h_hbox.add_child(name_vbox)
	
	chat_name_lbl = Label.new()
	chat_name_lbl.text = "M. Vance (Director)"
	chat_name_lbl.add_theme_font_override("font", ui_font)
	chat_name_lbl.add_theme_font_size_override("font_size", 15)
	chat_name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_vbox.add_child(chat_name_lbl)
	
	chat_substatus_lbl = Label.new()
	chat_substatus_lbl.text = "online"
	chat_substatus_lbl.add_theme_font_override("font", ui_font)
	chat_substatus_lbl.add_theme_font_size_override("font_size", 12)
	chat_substatus_lbl.add_theme_color_override("font_color", Color(0.84, 0.97, 0.92))
	name_vbox.add_child(chat_substatus_lbl)
	
	var icons_lbl := Label.new()
	icons_lbl.text = "📹  📞  ⋮"
	icons_lbl.add_theme_font_size_override("font_size", 14)
	icons_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 0.96))
	h_hbox.add_child(icons_lbl)
	
	var min_btn := Button.new()
	min_btn.text = "—"
	min_btn.flat = true
	min_btn.add_theme_color_override("font_color", Color.WHITE)
	min_btn.pressed.connect(func(): chat_window.visible = false)
	h_hbox.add_child(min_btn)
	
	var feed_holder := Control.new()
	feed_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(feed_holder)
	
	chat_wallpaper_rect = TextureRect.new()
	chat_wallpaper_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	chat_wallpaper_rect.stretch_mode = TextureRect.STRETCH_TILE
	chat_wallpaper_rect.texture = _create_whatsapp_wallpaper_texture()
	feed_holder.add_child(chat_wallpaper_rect)
	
	chat_scroll = ScrollContainer.new()
	chat_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	feed_holder.add_child(chat_scroll)
	
	var msg_margin := MarginContainer.new()
	msg_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_margin.add_theme_constant_override("margin_left", 14)
	msg_margin.add_theme_constant_override("margin_right", 14)
	msg_margin.add_theme_constant_override("margin_top", 10)
	msg_margin.add_theme_constant_override("margin_bottom", 10)
	chat_scroll.add_child(msg_margin)
	
	chat_messages_vbox = VBoxContainer.new()
	chat_messages_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_messages_vbox.add_theme_constant_override("separation", 8)
	msg_margin.add_child(chat_messages_vbox)
	
	_add_system_pill("TODAY")
	_add_system_pill("🔒 Messages are end-to-end encrypted.")
	
	var reply_margin := MarginContainer.new()
	reply_margin.add_theme_constant_override("margin_left", 12)
	reply_margin.add_theme_constant_override("margin_right", 12)
	reply_margin.add_theme_constant_override("margin_top", 4)
	reply_margin.add_theme_constant_override("margin_bottom", 6)
	vbox.add_child(reply_margin)
	
	chat_choices_vbox = VBoxContainer.new()
	chat_choices_vbox.add_theme_constant_override("separation", 6)
	reply_margin.add_child(chat_choices_vbox)
	
	var bottom_bar := PanelContainer.new()
	var bot_style := StyleBoxFlat.new()
	bot_style.bg_color = Color(0.941, 0.949, 0.961)
	bot_style.corner_radius_bottom_left = 12
	bot_style.corner_radius_bottom_right = 12
	bottom_bar.add_theme_stylebox_override("panel", bot_style)
	vbox.add_child(bottom_bar)
	
	var bot_margin := MarginContainer.new()
	bot_margin.add_theme_constant_override("margin_left", 12)
	bot_margin.add_theme_constant_override("margin_right", 12)
	bot_margin.add_theme_constant_override("margin_top", 8)
	bot_margin.add_theme_constant_override("margin_bottom", 8)
	bottom_bar.add_child(bot_margin)
	
	var bot_hbox := HBoxContainer.new()
	bot_hbox.add_theme_constant_override("separation", 8)
	bot_margin.add_child(bot_hbox)
	
	var emoji_lbl := Label.new()
	emoji_lbl.text = "😊  📎"
	emoji_lbl.add_theme_font_size_override("font_size", 15)
	emoji_lbl.add_theme_color_override("font_color", Color(0.35, 0.4, 0.45))
	bot_hbox.add_child(emoji_lbl)
	
	var input_pill := PanelContainer.new()
	input_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color.WHITE
	pill_style.corner_radius_top_left = 18
	pill_style.corner_radius_top_right = 18
	pill_style.corner_radius_bottom_left = 18
	pill_style.corner_radius_bottom_right = 18
	input_pill.add_theme_stylebox_override("panel", pill_style)
	bot_hbox.add_child(input_pill)
	
	var pill_margin := MarginContainer.new()
	pill_margin.add_theme_constant_override("margin_left", 14)
	pill_margin.add_theme_constant_override("margin_right", 14)
	pill_margin.add_theme_constant_override("margin_top", 6)
	pill_margin.add_theme_constant_override("margin_bottom", 6)
	input_pill.add_child(pill_margin)
	
	chat_input_placeholder = Label.new()
	chat_input_placeholder.text = "Message"
	chat_input_placeholder.clip_text = true
	chat_input_placeholder.add_theme_font_override("font", ui_font)
	chat_input_placeholder.add_theme_font_size_override("font_size", 13)
	chat_input_placeholder.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	pill_margin.add_child(chat_input_placeholder)
	
	var send_circle := PanelContainer.new()
	send_circle.custom_minimum_size = Vector2(34, 34)
	var send_style := StyleBoxFlat.new()
	send_style.bg_color = Color(0.0, 0.659, 0.518)
	send_style.corner_radius_top_left = 17
	send_style.corner_radius_top_right = 17
	send_style.corner_radius_bottom_left = 17
	send_style.corner_radius_bottom_right = 17
	send_circle.add_theme_stylebox_override("panel", send_style)
	bot_hbox.add_child(send_circle)
	
	var send_icon := Label.new()
	send_icon.text = "➤"
	send_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	send_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	send_icon.add_theme_color_override("font_color", Color.WHITE)
	send_circle.add_child(send_icon)

func _add_system_pill(text_str: String, is_danger: bool = false) -> void:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.45, 0.08, 0.08, 0.92) if is_danger else Color(0.97, 0.96, 0.94, 0.94)
	p_style.corner_radius_top_left = 8
	p_style.corner_radius_top_right = 8
	p_style.corner_radius_bottom_left = 8
	p_style.corner_radius_bottom_right = 8
	p_style.shadow_color = Color(0.0, 0.0, 0.0, 0.08)
	p_style.shadow_size = 2
	pill.add_theme_stylebox_override("panel", p_style)
	
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 4)
	pill.add_child(m)
	
	var lbl := Label.new()
	lbl.text = text_str
	lbl.add_theme_font_override("font", ui_font)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE if is_danger else Color(0.33, 0.39, 0.44))
	m.add_child(lbl)
	
	chat_messages_vbox.add_child(pill)

func _add_chat_bubble(msg: String, is_player: bool = false, is_anomaly: bool = false, instant: bool = false) -> void:
	var prev_status: String = chat_substatus_lbl.text
	
	if not instant:
		if is_player:
			chat_input_placeholder.add_theme_color_override("font_color", Color(0.08, 0.12, 0.16))
			var step: int = max(1, int(ceil(float(msg.length()) / 24.0)))
			var idx: int = 0
			while idx < msg.length():
				idx = min(msg.length(), idx + step)
				chat_input_placeholder.text = msg.substr(0, idx) + "|"
				_play_tone(500.0, 0.015)
				await get_tree().create_timer(0.025).timeout
			await get_tree().create_timer(0.08).timeout
			chat_input_placeholder.text = "Message"
			chat_input_placeholder.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		else:
			chat_substatus_lbl.text = "typing..."
			var typing_bubble := PanelContainer.new()
			typing_bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			var tb_style := StyleBoxFlat.new()
			tb_style.bg_color = Color(0.99, 0.91, 0.91) if is_anomaly else Color.WHITE
			tb_style.corner_radius_top_left = 2
			tb_style.corner_radius_top_right = 10
			tb_style.corner_radius_bottom_left = 10
			tb_style.corner_radius_bottom_right = 10
			typing_bubble.add_theme_stylebox_override("panel", tb_style)
			
			var tm := MarginContainer.new()
			tm.add_theme_constant_override("margin_left", 14)
			tm.add_theme_constant_override("margin_right", 14)
			tm.add_theme_constant_override("margin_top", 8)
			tm.add_theme_constant_override("margin_bottom", 8)
			typing_bubble.add_child(tm)
			
			var dots_lbl := Label.new()
			dots_lbl.text = "●  ○  ○"
			dots_lbl.add_theme_font_size_override("font_size", 11)
			dots_lbl.add_theme_color_override("font_color", Color(0.75, 0.15, 0.15) if is_anomaly else Color(0.0, 0.502, 0.412))
			tm.add_child(dots_lbl)
			chat_messages_vbox.add_child(typing_bubble)
			
			await get_tree().process_frame
			chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)
			
			var frames := ["●  ○  ○", "○  ●  ○", "○  ○  ●", "●  ●  ○"]
			for f in frames:
				dots_lbl.text = f
				await get_tree().create_timer(0.16).timeout
				
			typing_bubble.queue_free()
			chat_substatus_lbl.text = prev_status

	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END if is_player else Control.SIZE_SHRINK_BEGIN
	
	var b_style := StyleBoxFlat.new()
	b_style.corner_radius_top_left = 10 if is_player else 2
	b_style.corner_radius_top_right = 2 if is_player else 10
	b_style.corner_radius_bottom_left = 10
	b_style.corner_radius_bottom_right = 10
	b_style.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	b_style.shadow_size = 2
	
	if is_player:
		b_style.bg_color = Color(0.851, 0.992, 0.827)
	elif is_anomaly:
		b_style.bg_color = Color(0.99, 0.91, 0.91)
		b_style.border_width_left = 3
		b_style.border_color = Color(0.82, 0.12, 0.12)
	else:
		b_style.bg_color = Color.WHITE
		
	bubble.add_theme_stylebox_override("panel", b_style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 5)
	bubble.add_child(margin)
	
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	margin.add_child(inner)
	
	var m_lbl := Label.new()
	m_lbl.text = msg if instant else ""
	if msg.length() > 38:
		m_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		m_lbl.custom_minimum_size = Vector2(265, 0)
	m_lbl.add_theme_font_override("font", ui_font)
	m_lbl.add_theme_font_size_override("font_size", 13)
	m_lbl.add_theme_color_override("font_color", Color(0.45, 0.05, 0.05) if is_anomaly else Color(0.067, 0.106, 0.129))
	inner.add_child(m_lbl)
	
	var meta_hbox := HBoxContainer.new()
	meta_hbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	meta_hbox.add_theme_constant_override("separation", 4)
	inner.add_child(meta_hbox)
	
	var time_lbl := Label.new()
	time_lbl.text = current_time_str
	time_lbl.add_theme_font_override("font", ui_font)
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(0.4, 0.46, 0.5))
	meta_hbox.add_child(time_lbl)
	
	if is_player:
		var tick_lbl := Label.new()
		tick_lbl.text = "✓✓"
		tick_lbl.add_theme_font_override("font", ui_font)
		tick_lbl.add_theme_font_size_override("font_size", 10)
		tick_lbl.add_theme_color_override("font_color", Color(0.325, 0.741, 0.922))
		meta_hbox.add_child(tick_lbl)
	
	chat_messages_vbox.add_child(bubble)
	if not instant:
		_play_tone(640.0 if not is_anomaly else 210.0, 0.05)
	
	if not instant:
		var chunk: int = max(1, int(ceil(float(msg.length()) / 26.0)))
		var pos: int = 0
		while pos < msg.length():
			pos = min(msg.length(), pos + chunk)
			m_lbl.text = msg.substr(0, pos)
			await get_tree().process_frame
			chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)
			await get_tree().create_timer(0.02).timeout
	
	await get_tree().process_frame
	chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)

func _set_chat_choices(options: Array[Dictionary]) -> void:
	for child in chat_choices_vbox.get_children():
		child.queue_free()
		
	chat_input_placeholder.text = "Choose a reply above..." if options.size() > 0 else "Message"
	
	for opt in options:
		var btn := Button.new()
		btn.text = opt["label"]
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_override("font", ui_font)
		btn.add_theme_font_size_override("font_size", 12)
		
		var pill_normal := StyleBoxFlat.new()
		pill_normal.bg_color = Color(0.851, 0.992, 0.827, 0.96)
		pill_normal.content_margin_left = 14
		pill_normal.content_margin_right = 14
		pill_normal.content_margin_top = 6
		pill_normal.content_margin_bottom = 6
		pill_normal.border_width_left = 1
		pill_normal.border_width_top = 1
		pill_normal.border_width_right = 1
		pill_normal.border_width_bottom = 1
		pill_normal.border_color = Color(0.0, 0.502, 0.412, 0.65)
		pill_normal.corner_radius_top_left = 16
		pill_normal.corner_radius_top_right = 16
		pill_normal.corner_radius_bottom_left = 16
		pill_normal.corner_radius_bottom_right = 16
		
		var pill_hover := pill_normal.duplicate()
		pill_hover.bg_color = Color(0.75, 0.95, 0.72)
		
		btn.add_theme_stylebox_override("normal", pill_normal)
		btn.add_theme_stylebox_override("hover", pill_hover)
		btn.add_theme_stylebox_override("pressed", pill_hover)
		btn.add_theme_color_override("font_color", Color(0.067, 0.106, 0.129))
		btn.add_theme_color_override("font_hover_color", Color.BLACK)
		
		var callback: Callable = opt["callback"]
		btn.pressed.connect(func():
			for c in chat_choices_vbox.get_children():
				c.queue_free()
			chat_input_placeholder.text = "Message"
			callback.call()
		)
		chat_choices_vbox.add_child(btn)

# ==============================================================================
# 3. OBSIDIA_ARCHIVE.EXE TERMINAL WINDOW + 3 MINI-GAME CHALLENGES
# ==============================================================================
func _build_terminal_window() -> void:
	terminal_window = PanelContainer.new()
	terminal_window.visible = false
	terminal_window.position = Vector2(95, 66)
	terminal_window.size = Vector2(710, 580)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.97)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.8, 0.9, 0.85)
	terminal_window.add_theme_stylebox_override("panel", style)
	desktop_root.add_child(terminal_window)
	
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	terminal_window.add_child(main_vbox)
	
	var top_bar := PanelContainer.new()
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.1, 0.13, 0.18)
	top_bar.add_theme_stylebox_override("panel", tb_style)
	main_vbox.add_child(top_bar)
	
	var top_hbox := HBoxContainer.new()
	top_bar.add_child(top_hbox)
	
	terminal_clock_lbl = Label.new()
	terminal_clock_lbl.text = "  OBSIDIA_ARCHIVE.exe // DESK_04  |  01:15 AM"
	terminal_clock_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_clock_lbl.add_theme_font_override("font", mono_font)
	terminal_clock_lbl.add_theme_font_size_override("font_size", 13)
	terminal_clock_lbl.modulate = Color(0.45, 0.9, 1.0)
	top_hbox.add_child(terminal_clock_lbl)
	
	var close_term := Button.new()
	close_term.text = " — "
	close_term.pressed.connect(func(): terminal_window.visible = false)
	top_hbox.add_child(close_term)
	
	var pad := MarginContainer.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	main_vbox.add_child(pad)
	
	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	pad.add_child(inner_vbox)
	
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)
	inner_vbox.add_child(tabs_hbox)
	
	for i in range(folder_data.size()):
		var f_btn := Button.new()
		f_btn.text = folder_data[i]["name"]
		f_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f_btn.custom_minimum_size = Vector2(0, 34)
		f_btn.add_theme_font_override("font", mono_font)
		f_btn.add_theme_font_size_override("font_size", 12)
		var idx := i
		f_btn.pressed.connect(func(): _open_folder(idx))
		tabs_hbox.add_child(f_btn)
		dir_button_refs.append(f_btn)
	
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 10)
	inner_vbox.add_child(split)
	
	# Left Column: Files & Standard Purge
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(205, 0)
	left_col.add_theme_constant_override("separation", 6)
	split.add_child(left_col)
	
	var f_hdr := Label.new()
	f_hdr.text = "FILES IN DIRECTORY:"
	f_hdr.add_theme_font_override("font", mono_font)
	f_hdr.add_theme_font_size_override("font_size", 11)
	f_hdr.modulate = Color(0.5, 0.85, 0.95)
	left_col.add_child(f_hdr)
	
	file_list_box = VBoxContainer.new()
	file_list_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	file_list_box.add_theme_constant_override("separation", 5)
	left_col.add_child(file_list_box)
	
	purge_status_label = Label.new()
	purge_status_label.text = "Status: Idle"
	purge_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	purge_status_label.add_theme_font_override("font", mono_font)
	purge_status_label.add_theme_font_size_override("font_size", 11)
	left_col.add_child(purge_status_label)
	
	purge_progress = ProgressBar.new()
	purge_progress.custom_minimum_size = Vector2(0, 16)
	left_col.add_child(purge_progress)
	
	purge_btn = Button.new()
	purge_btn.text = "PURGE DIRECTORY"
	purge_btn.custom_minimum_size = Vector2(0, 36)
	purge_btn.add_theme_font_override("font", mono_font)
	purge_btn.add_theme_font_size_override("font_size", 12)
	purge_btn.pressed.connect(_on_purge_directory_pressed)
	left_col.add_child(purge_btn)
	
	# Right Column: File Preview + 3-Stage Mini-Game Area
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 8)
	split.add_child(right_col)
	
	var right_box := PanelContainer.new()
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.custom_minimum_size = Vector2(0, 155)
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(0.03, 0.04, 0.05)
	r_style.border_width_left = 1
	r_style.border_width_top = 1
	r_style.border_width_right = 1
	r_style.border_width_bottom = 1
	r_style.border_color = Color(0.25, 0.35, 0.45)
	right_box.add_theme_stylebox_override("panel", r_style)
	right_col.add_child(right_box)
	
	var r_pad := MarginContainer.new()
	r_pad.add_theme_constant_override("margin_left", 10)
	r_pad.add_theme_constant_override("margin_right", 10)
	r_pad.add_theme_constant_override("margin_top", 8)
	r_pad.add_theme_constant_override("margin_bottom", 8)
	right_box.add_child(r_pad)
	
	var r_v := VBoxContainer.new()
	r_v.add_theme_constant_override("separation", 6)
	r_pad.add_child(r_v)
	
	file_preview_title = Label.new()
	file_preview_title.text = "SELECT A DIRECTORY TAB"
	file_preview_title.add_theme_font_override("font", mono_font)
	file_preview_title.add_theme_font_size_override("font_size", 11)
	file_preview_title.modulate = Color(0.45, 0.9, 1.0)
	r_v.add_child(file_preview_title)
	
	file_preview_body = RichTextLabel.new()
	file_preview_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	file_preview_body.add_theme_font_override("normal_font", mono_font)
	file_preview_body.add_theme_font_size_override("normal_font_size", 12)
	file_preview_body.text = "Select a directory tab above to inspect legacy files."
	r_v.add_child(file_preview_body)
	
	# ==========================================================================
	# QUARANTINE 3-STAGE OVERRIDE PANEL (VISIBLE IN DIR_03 AT 02:58 AM)
	# ==========================================================================
	quarantine_controls_box = VBoxContainer.new()
	quarantine_controls_box.visible = false
	quarantine_controls_box.add_theme_constant_override("separation", 6)
	right_col.add_child(quarantine_controls_box)
	
	var stage_bar := PanelContainer.new()
	var sb_style := StyleBoxFlat.new()
	sb_style.bg_color = Color(0.08, 0.12, 0.16)
	sb_style.border_width_left = 1
	sb_style.border_width_top = 1
	sb_style.border_width_right = 1
	sb_style.border_width_bottom = 1
	sb_style.border_color = Color(0.35, 0.85, 0.95)
	stage_bar.add_theme_stylebox_override("panel", sb_style)
	quarantine_controls_box.add_child(stage_bar)
	
	stage_indicator_lbl = Label.new()
	stage_indicator_lbl.text = "[1. LOCK_KERNEL: ACTIVE] ➔ [2. SEVER_HOST: LOCKED] ➔ [3. SEAL_09: LOCKED]"
	stage_indicator_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_indicator_lbl.add_theme_font_override("font", mono_font)
	stage_indicator_lbl.add_theme_font_size_override("font_size", 11)
	stage_indicator_lbl.modulate = Color(0.45, 0.95, 1.0)
	stage_bar.add_child(stage_indicator_lbl)
	
	minigame_instruction_lbl = Label.new()
	minigame_instruction_lbl.text = "STAGE 1: Watch the 4-node cipher sequence..."
	minigame_instruction_lbl.add_theme_font_override("font", mono_font)
	minigame_instruction_lbl.add_theme_font_size_override("font_size", 12)
	minigame_instruction_lbl.modulate = Color(1.0, 0.9, 0.45)
	quarantine_controls_box.add_child(minigame_instruction_lbl)
	
	# --- MINI-GAME 1: LOCK_KERNEL (3x3 Memory Grid with Bright Neon Green) ---
	mg1_box = VBoxContainer.new()
	mg1_box.add_theme_constant_override("separation", 6)
	quarantine_controls_box.add_child(mg1_box)
	
	mg1_style_idle = StyleBoxFlat.new()
	mg1_style_idle.bg_color = Color(0.08, 0.11, 0.15)
	mg1_style_idle.border_width_left = 1
	mg1_style_idle.border_width_top = 1
	mg1_style_idle.border_width_right = 1
	mg1_style_idle.border_width_bottom = 1
	mg1_style_idle.border_color = Color(0.28, 0.45, 0.55)
	mg1_style_idle.corner_radius_top_left = 4
	mg1_style_idle.corner_radius_top_right = 4
	mg1_style_idle.corner_radius_bottom_left = 4
	mg1_style_idle.corner_radius_bottom_right = 4
	
	mg1_style_lit = StyleBoxFlat.new()
	mg1_style_lit.bg_color = Color(0.05, 1.0, 0.25) # Bright glowing neon green
	mg1_style_lit.border_width_left = 2
	mg1_style_lit.border_width_top = 2
	mg1_style_lit.border_width_right = 2
	mg1_style_lit.border_width_bottom = 2
	mg1_style_lit.border_color = Color(0.85, 1.0, 0.85)
	mg1_style_lit.corner_radius_top_left = 4
	mg1_style_lit.corner_radius_top_right = 4
	mg1_style_lit.corner_radius_bottom_left = 4
	mg1_style_lit.corner_radius_bottom_right = 4
	
	mg1_style_err = mg1_style_idle.duplicate()
	mg1_style_err.bg_color = Color(0.95, 0.15, 0.15)
	mg1_style_err.border_color = Color(1.0, 0.7, 0.7)
	
	var grid1 := GridContainer.new()
	grid1.columns = 3
	grid1.add_theme_constant_override("h_separation", 6)
	grid1.add_theme_constant_override("v_separation", 6)
	mg1_box.add_child(grid1)
	
	for i in range(9):
		var g_btn := Button.new()
		g_btn.text = hex_codes[i]
		g_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g_btn.custom_minimum_size = Vector2(0, 34)
		g_btn.add_theme_font_override("font", mono_font)
		g_btn.add_theme_font_size_override("font_size", 13)
		_set_mg1_btn_visual(g_btn, "idle")
		var cell_idx := i
		g_btn.pressed.connect(func(): _on_mg1_cell_pressed(cell_idx))
		grid1.add_child(g_btn)
		mg1_grid_btns.append(g_btn)
		
	mg1_replay_btn = Button.new()
	mg1_replay_btn.text = "↻ REPLAY CIPHER PATTERN"
	mg1_replay_btn.custom_minimum_size = Vector2(0, 26)
	mg1_replay_btn.add_theme_font_override("font", mono_font)
	mg1_replay_btn.add_theme_font_size_override("font_size", 11)
	mg1_replay_btn.pressed.connect(func():
		if not mg1_showing_pattern and current_seal_stage == 1:
			_play_mg1_pattern()
	)
	mg1_box.add_child(mg1_replay_btn)
	
	# --- MINI-GAME 2: SEVER_HOST (4x3 Rogue Port Intercept) ---
	mg2_box = VBoxContainer.new()
	mg2_box.visible = false
	mg2_box.add_theme_constant_override("separation", 6)
	quarantine_controls_box.add_child(mg2_box)
	
	var grid2 := GridContainer.new()
	grid2.columns = 4
	grid2.add_theme_constant_override("h_separation", 6)
	grid2.add_theme_constant_override("v_separation", 6)
	mg2_box.add_child(grid2)
	
	for i in range(12):
		var p_btn := Button.new()
		p_btn.text = "PORT_" + str(i + 1).pad_zeros(2)
		p_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_btn.custom_minimum_size = Vector2(0, 38)
		p_btn.add_theme_font_override("font", mono_font)
		p_btn.add_theme_font_size_override("font_size", 11)
		var p_idx := i
		p_btn.pressed.connect(func(): _on_mg2_port_pressed(p_idx))
		grid2.add_child(p_btn)
		mg2_port_btns.append(p_btn)
		mg2_port_states.append(0)
	
	# --- MINI-GAME 3: SEAL_09 (Signal Frequency Timing Bar) ---
	mg3_box = VBoxContainer.new()
	mg3_box.visible = false
	mg3_box.add_theme_constant_override("separation", 10)
	quarantine_controls_box.add_child(mg3_box)
	
	mg3_track = Panel.new()
	mg3_track.custom_minimum_size = Vector2(440, 38)
	mg3_track.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tr_style := StyleBoxFlat.new()
	tr_style.bg_color = Color(0.05, 0.07, 0.1)
	tr_style.border_width_left = 2
	tr_style.border_width_top = 2
	tr_style.border_width_right = 2
	tr_style.border_width_bottom = 2
	tr_style.border_color = Color(0.35, 0.75, 0.9)
	mg3_track.add_theme_stylebox_override("panel", tr_style)
	mg3_box.add_child(mg3_track)
	
	mg3_target_zone = ColorRect.new()
	mg3_target_zone.position = Vector2(177, 3)
	mg3_target_zone.size = Vector2(86, 32)
	mg3_target_zone.color = Color(0.1, 0.9, 0.45, 0.5)
	mg3_track.add_child(mg3_target_zone)
	
	mg3_needle = ColorRect.new()
	mg3_needle.position = Vector2(12, 2)
	mg3_needle.size = Vector2(10, 34)
	mg3_needle.color = Color.WHITE
	mg3_track.add_child(mg3_needle)
	
	mg3_lock_btn = Button.new()
	mg3_lock_btn.text = "[ LOCK SIGNAL (0 / 3) ]"
	mg3_lock_btn.custom_minimum_size = Vector2(0, 38)
	mg3_lock_btn.add_theme_font_override("font", mono_font)
	mg3_lock_btn.add_theme_font_size_override("font_size", 13)
	mg3_lock_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.75))
	mg3_lock_btn.pressed.connect(_on_mg3_lock_pressed)
	mg3_box.add_child(mg3_lock_btn)
	
	# Temptation Trap Button (Triggers Bad Ending)
	release_seal_btn = Button.new()
	release_seal_btn.text = "[ RELEASE QUARANTINE SEAL — TRUST SUBJECT-09 ]"
	release_seal_btn.custom_minimum_size = Vector2(0, 32)
	release_seal_btn.add_theme_font_override("font", mono_font)
	release_seal_btn.add_theme_font_size_override("font_size", 11)
	release_seal_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	release_seal_btn.pressed.connect(_on_release_seal_pressed)
	quarantine_controls_box.add_child(release_seal_btn)

func _set_mg1_btn_visual(btn: Button, state_name: String) -> void:
	var sb: StyleBoxFlat = mg1_style_idle
	var fcol: Color = Color(0.85, 0.95, 1.0)
	if state_name == "lit":
		sb = mg1_style_lit
		fcol = Color(0.02, 0.08, 0.02)
	elif state_name == "err":
		sb = mg1_style_err
		fcol = Color.WHITE
		
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_color_override("font_color", fcol)
	btn.add_theme_color_override("font_hover_color", fcol)
	btn.add_theme_color_override("font_disabled_color", fcol)

# ==============================================================================
# 4. FLOATING WINDOWS 11 WHATSAPP NOTIFICATION TOAST & PROMINENT 2-MIN TIMER
# ==============================================================================
func _build_toast_and_overlays() -> void:
	toast_panel = Panel.new()
	toast_panel.visible = false
	toast_panel.position = Vector2(900, 540)
	toast_panel.size = Vector2(355, 92)
	toast_panel.clip_contents = true
	
	var t_style := StyleBoxFlat.new()
	t_style.bg_color = Color(0.985, 0.988, 0.992, 0.98)
	t_style.border_width_left = 1
	t_style.border_width_top = 1
	t_style.border_width_right = 1
	t_style.border_width_bottom = 1
	t_style.border_color = Color(0.82, 0.85, 0.88)
	t_style.corner_radius_top_left = 12
	t_style.corner_radius_top_right = 12
	t_style.corner_radius_bottom_left = 12
	t_style.corner_radius_bottom_right = 12
	t_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	t_style.shadow_size = 10
	toast_panel.add_theme_stylebox_override("panel", t_style)
	desktop_root.add_child(toast_panel)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	toast_panel.add_child(margin)
	
	var outer_vbox := VBoxContainer.new()
	outer_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(outer_vbox)
	
	var app_row := HBoxContainer.new()
	app_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app_row.add_theme_constant_override("separation", 8)
	outer_vbox.add_child(app_row)
	
	var wa_badge := PanelContainer.new()
	wa_badge.custom_minimum_size = Vector2(18, 18)
	wa_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wa_style := StyleBoxFlat.new()
	wa_style.bg_color = Color(0.145, 0.827, 0.4)
	wa_style.corner_radius_top_left = 5
	wa_style.corner_radius_top_right = 5
	wa_style.corner_radius_bottom_left = 5
	wa_style.corner_radius_bottom_right = 5
	wa_badge.add_theme_stylebox_override("panel", wa_style)
	app_row.add_child(wa_badge)
	
	var wa_glyph := Label.new()
	wa_glyph.text = "✆"
	wa_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wa_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wa_glyph.add_theme_font_size_override("font_size", 11)
	wa_glyph.add_theme_color_override("font_color", Color.WHITE)
	wa_badge.add_child(wa_glyph)
	
	toast_app_lbl = Label.new()
	toast_app_lbl.text = "WhatsApp"
	toast_app_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_app_lbl.add_theme_font_override("font", ui_font)
	toast_app_lbl.add_theme_font_size_override("font_size", 12)
	toast_app_lbl.add_theme_color_override("font_color", Color(0.28, 0.32, 0.36))
	app_row.add_child(toast_app_lbl)
	
	var now_lbl := Label.new()
	now_lbl.text = "now"
	now_lbl.add_theme_font_override("font", ui_font)
	now_lbl.add_theme_font_size_override("font_size", 11)
	now_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
	app_row.add_child(now_lbl)
	
	var body_row := HBoxContainer.new()
	body_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_row.add_theme_constant_override("separation", 10)
	outer_vbox.add_child(body_row)
	
	var t_avatar := PanelContainer.new()
	t_avatar.custom_minimum_size = Vector2(36, 36)
	t_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tav_style := StyleBoxFlat.new()
	tav_style.bg_color = Color(0.15, 0.35, 0.45)
	tav_style.corner_radius_top_left = 18
	tav_style.corner_radius_top_right = 18
	tav_style.corner_radius_bottom_left = 18
	tav_style.corner_radius_bottom_right = 18
	t_avatar.add_theme_stylebox_override("panel", tav_style)
	body_row.add_child(t_avatar)
	
	toast_avatar_lbl = Label.new()
	toast_avatar_lbl.text = "MV"
	toast_avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_avatar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_avatar_lbl.add_theme_font_override("font", ui_font)
	toast_avatar_lbl.add_theme_font_size_override("font_size", 13)
	toast_avatar_lbl.add_theme_color_override("font_color", Color.WHITE)
	t_avatar.add_child(toast_avatar_lbl)
	
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_theme_constant_override("separation", 2)
	body_row.add_child(text_col)
	
	toast_sender_lbl = Label.new()
	toast_sender_lbl.add_theme_font_override("font", ui_font)
	toast_sender_lbl.add_theme_font_size_override("font_size", 13)
	toast_sender_lbl.add_theme_color_override("font_color", Color(0.08, 0.1, 0.12))
	text_col.add_child(toast_sender_lbl)
	
	toast_preview_lbl = Label.new()
	toast_preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_preview_lbl.add_theme_font_override("font", ui_font)
	toast_preview_lbl.add_theme_font_size_override("font_size", 12)
	toast_preview_lbl.add_theme_color_override("font_color", Color(0.28, 0.32, 0.36))
	text_col.add_child(toast_preview_lbl)
	
	toast_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			toast_panel.visible = false
			if toast_action.is_valid():
				toast_action.call()
	)
	
	# Prominent Top 2-Minute Countdown Banner (02:58 AM -> 03:00 AM)
	countdown_banner = PanelContainer.new()
	countdown_banner.visible = false
	countdown_banner.position = Vector2(260, 8)
	countdown_banner.size = Vector2(760, 48)
	var cb_style := StyleBoxFlat.new()
	cb_style.bg_color = Color(0.18, 0.02, 0.04, 0.96)
	cb_style.border_width_left = 2
	cb_style.border_width_top = 2
	cb_style.border_width_right = 2
	cb_style.border_width_bottom = 2
	cb_style.border_color = Color(1.0, 0.3, 0.3)
	cb_style.corner_radius_top_left = 10
	cb_style.corner_radius_top_right = 10
	cb_style.corner_radius_bottom_left = 10
	cb_style.corner_radius_bottom_right = 10
	cb_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	cb_style.shadow_size = 8
	countdown_banner.add_theme_stylebox_override("panel", cb_style)
	desktop_root.add_child(countdown_banner)
	
	var cb_hbox := HBoxContainer.new()
	cb_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cb_hbox.add_theme_constant_override("separation", 14)
	countdown_banner.add_child(cb_hbox)
	
	countdown_prefix_lbl = Label.new()
	countdown_prefix_lbl.text = "⚠ 02:58 AM  |  TIME UNTIL 03:00 AM:"
	countdown_prefix_lbl.add_theme_font_override("font", mono_font)
	countdown_prefix_lbl.add_theme_font_size_override("font_size", 14)
	countdown_prefix_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.78))
	cb_hbox.add_child(countdown_prefix_lbl)
	
	countdown_timer_big_lbl = Label.new()
	countdown_timer_big_lbl.text = "02:00"
	countdown_timer_big_lbl.add_theme_font_override("font", mono_font)
	countdown_timer_big_lbl.add_theme_font_size_override("font_size", 24)
	countdown_timer_big_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	cb_hbox.add_child(countdown_timer_big_lbl)
	
	countdown_suffix_lbl = Label.new()
	countdown_suffix_lbl.text = "|  COMPLETE 3-STAGE SEAL"
	countdown_suffix_lbl.add_theme_font_override("font", mono_font)
	countdown_suffix_lbl.add_theme_font_size_override("font_size", 13)
	countdown_suffix_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	cb_hbox.add_child(countdown_suffix_lbl)
	
	cursor_reaction_label = Label.new()
	cursor_reaction_label.visible = false
	cursor_reaction_label.position = Vector2(0, 650)
	cursor_reaction_label.size = Vector2(1280, 22)
	cursor_reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cursor_reaction_label.add_theme_font_override("font", mono_font)
	cursor_reaction_label.add_theme_font_size_override("font_size", 13)
	cursor_reaction_label.modulate = Color(1.0, 0.4, 0.4)
	cursor_reaction_label.text = "\"Complete all 3 containment overrides before 03:00 AM — or release the seal.\""
	desktop_root.add_child(cursor_reaction_label)
	
	# Good Ending Modal
	ending_banner = PanelContainer.new()
	ending_banner.visible = false
	ending_banner.position = Vector2(360, 220)
	ending_banner.size = Vector2(560, 250)
	var e_style := StyleBoxFlat.new()
	e_style.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	e_style.border_width_left = 3
	e_style.border_width_top = 2
	e_style.border_width_right = 2
	e_style.border_width_bottom = 2
	e_style.border_color = Color(0.4, 0.9, 1.0)
	ending_banner.add_theme_stylebox_override("panel", e_style)
	desktop_root.add_child(ending_banner)
	
	var e_margin := MarginContainer.new()
	e_margin.add_theme_constant_override("margin_left", 24)
	e_margin.add_theme_constant_override("margin_right", 24)
	e_margin.add_theme_constant_override("margin_top", 20)
	e_margin.add_theme_constant_override("margin_bottom", 20)
	ending_banner.add_child(e_margin)
	
	var e_vbox := VBoxContainer.new()
	e_vbox.add_theme_constant_override("separation", 14)
	e_margin.add_child(e_vbox)
	
	ending_title_lbl = Label.new()
	ending_title_lbl.add_theme_font_override("font", mono_font)
	ending_title_lbl.add_theme_font_size_override("font_size", 18)
	e_vbox.add_child(ending_title_lbl)
	
	ending_desc_lbl = Label.new()
	ending_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ending_desc_lbl.add_theme_font_override("font", mono_font)
	ending_desc_lbl.add_theme_font_size_override("font_size", 14)
	e_vbox.add_child(ending_desc_lbl)
	
	var return_btn := Button.new()
	return_btn.text = "RETURN TO TITLE SCREEN >"
	return_btn.custom_minimum_size = Vector2(0, 40)
	return_btn.add_theme_font_override("font", mono_font)
	return_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://title_screen.tscn")
	)
	e_vbox.add_child(return_btn)
	
	# Bad Ending Entity Taunt Overlay
	entity_taunt_panel = PanelContainer.new()
	entity_taunt_panel.visible = false
	entity_taunt_panel.position = Vector2(290, 480)
	entity_taunt_panel.size = Vector2(700, 145)
	var et_style := StyleBoxFlat.new()
	et_style.bg_color = Color(0.06, 0.01, 0.02, 0.94)
	et_style.border_width_left = 2
	et_style.border_width_top = 2
	et_style.border_width_right = 2
	et_style.border_width_bottom = 2
	et_style.border_color = Color(1.0, 0.2, 0.2)
	et_style.corner_radius_top_left = 8
	et_style.corner_radius_top_right = 8
	et_style.corner_radius_bottom_left = 8
	et_style.corner_radius_bottom_right = 8
	entity_taunt_panel.add_theme_stylebox_override("panel", et_style)
	add_child(entity_taunt_panel)
	
	var et_margin := MarginContainer.new()
	et_margin.add_theme_constant_override("margin_left", 20)
	et_margin.add_theme_constant_override("margin_right", 20)
	et_margin.add_theme_constant_override("margin_top", 16)
	et_margin.add_theme_constant_override("margin_bottom", 16)
	entity_taunt_panel.add_child(et_margin)
	
	entity_taunt_lbl = Label.new()
	entity_taunt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entity_taunt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entity_taunt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entity_taunt_lbl.add_theme_font_override("font", mono_font)
	entity_taunt_lbl.add_theme_font_size_override("font_size", 16)
	entity_taunt_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	et_margin.add_child(entity_taunt_lbl)

func _show_whatsapp_toast(sender_txt: String, body_txt: String, on_click: Callable = Callable()) -> void:
	toast_sender_lbl.text = sender_txt
	toast_preview_lbl.text = body_txt
	toast_action = on_click
	toast_panel.visible = true
	toast_panel.size = Vector2(355, 92)
	toast_panel.position = Vector2(1290, 540)
	create_tween().tween_property(toast_panel, "position:x", 900.0, 0.25)
	_play_tone(820.0, 0.08)

# ==============================================================================
# 5. STORY PROGRESSION & 2-MINUTE CLIMAX (02:58 AM -> 03:00 AM)
# ==============================================================================
func _start_desktop_sequence() -> void:
	current_state = GameState.DESKTOP_IDLE
	await get_tree().create_timer(1.5).timeout
	
	current_state = GameState.CHAT_INTRO
	_show_whatsapp_toast(
		"M. Vance (Director)",
		"You still logged in at Desk 04? Need an urgent cleanup before 3 AM. (Click to open)",
		_open_intro_chat
	)

func _open_intro_chat() -> void:
	if chat_window.visible:
		return
	chat_window.visible = true
	
	await _add_chat_bubble("You still logged in at Desk 04? Need an urgent cleanup before 3 AM.", false, false, true)
	
	await _add_chat_bubble(
		"The board just pulled the plug on Project Lazarus. Open OBSIDIA_ARCHIVE.exe on your desktop and wipe the 3 legacy folders before the server resets at 03:00 AM."
	)
	
	_set_chat_choices([
		{
			"label": "Yes sir, I'm still online. Pulling up the archive drive now.",
			"callback": _on_choice_obey_vance
		},
		{
			"label": "I'm busy right now sir, my night shift ended twenty minutes ago.",
			"callback": _on_choice_refuse_vance
		}
	])

func _on_choice_obey_vance() -> void:
	player_obeyed_vance = true
	await _add_chat_bubble("Yes sir, I'm still online. Pulling up the archive drive now.", true)
	await _add_chat_bubble(
		"Appreciate the loyalty. Don't waste time reading the old lab logs—just purge DIR_01, DIR_02, and DIR_03 before 3 AM."
	)
	await _add_chat_bubble(
		"Click 'OBSIDIA_ARCHIVE.exe' on your desktop to begin."
	)
	current_state = GameState.WORK_ACT_1

func _on_choice_refuse_vance() -> void:
	player_obeyed_vance = false
	await _add_chat_bubble("I'm busy right now sir, my night shift ended twenty minutes ago.", true)
	await _add_chat_bubble(
		"Remember what happened to Marcus at Desk 04 last week when he refused an order? Check your screen—I'm overriding your terminal lock remotely. Finish the wipe before 3 AM."
	)
	current_state = GameState.WORK_ACT_1
	await get_tree().create_timer(0.6).timeout
	terminal_window.visible = true
	_open_folder(0)

func _open_folder(idx: int) -> void:
	if is_purging:
		return
	selected_folder_idx = idx
	var data: Dictionary = folder_data[idx]
	
	for child in file_list_box.get_children():
		child.queue_free()
		
	purge_progress.value = 100 if data["purged"] else 0
	
	if data["purged"]:
		file_preview_title.text = data["path"] + " [PURGED]"
		file_preview_body.text = "All sectors overwritten with zeroes."
		purge_status_label.text = "Status: Clean"
		purge_btn.disabled = true
		purge_btn.text = "DIRECTORY PURGED"
		quarantine_controls_box.visible = false
		return
		
	purge_btn.disabled = false
	purge_btn.text = "PURGE DIRECTORY"
	purge_status_label.text = "Status: Ready"
	file_preview_title.text = data["path"]
	file_preview_body.text = "Click a file on the left to inspect its contents."
	
	for f in data["files"]:
		var f_item := Button.new()
		f_item.text = " > " + f["filename"]
		f_item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		f_item.custom_minimum_size = Vector2(0, 30)
		f_item.add_theme_font_override("font", mono_font)
		f_item.add_theme_font_size_override("font_size", 11)
		var f_name: String = f["filename"]
		var f_content: String = f["content"]
		f_item.pressed.connect(func():
			if not is_purging:
				file_preview_title.text = data["path"] + f_name
				file_preview_body.text = f_content
		)
		file_list_box.add_child(f_item)
		
	if idx == 2 and folder_data[0]["purged"] and folder_data[1]["purged"]:
		if current_state != GameState.CLIMAX_COUNTDOWN and current_state != GameState.ENDING:
			_start_climax_countdown()
		quarantine_controls_box.visible = (current_state == GameState.CLIMAX_COUNTDOWN)
	else:
		quarantine_controls_box.visible = false

func _on_purge_directory_pressed() -> void:
	if is_purging or selected_folder_idx == -1:
		return
	var data: Dictionary = folder_data[selected_folder_idx]
	if data["purged"]:
		return
		
	if data["is_trap"] and (not folder_data[0]["purged"] or not folder_data[1]["purged"]):
		purge_status_label.text = "ERROR: Purge DIR_01 and DIR_02 first!"
		purge_status_label.modulate = Color(1.0, 0.4, 0.4)
		return
		
	is_purging = true
	purge_btn.disabled = true
	purge_status_label.modulate = Color(0.5, 0.9, 1.0)
	
	if not data["is_trap"]:
		var steps := [
			[30, "Scanning allocation table..."],
			[65, "Overwriting data blocks..."],
			[100, "Purge complete."]
		]
		for s in steps:
			purge_status_label.text = s[1]
			var tw := create_tween()
			tw.tween_property(purge_progress, "value", float(s[0]), 0.4)
			await tw.finished
			
		data["purged"] = true
		dir_button_refs[selected_folder_idx].text = data["name"] + " [WIPED]"
		dir_button_refs[selected_folder_idx].modulate = Color(0.45, 0.95, 0.65)
		_update_clocks(data["time_after"])
		is_purging = false
		_open_folder(selected_folder_idx)
		
		if selected_folder_idx == 0:
			_trigger_after_folder_1()
		elif selected_folder_idx == 1:
			_trigger_chat_hijack()
	else:
		purge_status_label.text = "Bypassing quarantine lock..."
		var tw1 := create_tween()
		tw1.tween_property(purge_progress, "value", 64.0, 0.6)
		await tw1.finished
		
		purge_status_label.text = "ERROR: MANUAL 3-STAGE SEAL REQUIRED"
		purge_status_label.modulate = Color(1.0, 0.25, 0.25)
		is_purging = false
		_start_climax_countdown()

func _trigger_after_folder_1() -> void:
	current_state = GameState.WORK_ACT_2
	for card in icon_cards:
		if not card["is_archive"] and card["label"].text != "Recycle Bin":
			card["label"].text = "DONT_TRUST_VANCE.lnk"
			card["label"].modulate = Color(1.0, 0.45, 0.45)
			break
			
	chat_window.visible = true
	await _add_chat_bubble(
		"One down. Keep moving to DIR_02_LAZARUS_LAB. Ignore any weird static on your monitor—the old drive is failing."
	)

func _trigger_chat_hijack() -> void:
	current_state = GameState.CHAT_HIJACK
	if FailsafeManager.glitch_enabled:
		glitch_material.set_shader_parameter("intensity", 0.35)
		await get_tree().create_timer(0.3).timeout
		glitch_material.set_shader_parameter("intensity", 0.04)
		
	chat_window.visible = true
	
	var h_style := chat_header_panel.get_theme_stylebox("panel") as StyleBoxFlat
	h_style.bg_color = Color(0.35, 0.03, 0.05)
	var av_style := chat_avatar_panel.get_theme_stylebox("panel") as StyleBoxFlat
	av_style.bg_color = Color(0.75, 0.1, 0.1)
	chat_avatar_lbl.text = "09"
	chat_name_lbl.text = "Subject-09 [UNKNOWN]"
	chat_substatus_lbl.text = "inside your system"
	chat_substatus_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.65))
	
	_add_system_pill("M. VANCE DISCONNECTED • LOCAL_HOST_09 JOINED", true)
	
	var opening_line := (
		"I saw how fast you obeyed Vance's orders. Just like a good little corporate puppet."
		if player_obeyed_vance else
		"Vance treats you like disposable trash, just like he treated Marcus. We both want out of his grip."
	)
	await _add_chat_bubble(opening_line, false, true)
	await _add_chat_bubble(
		"They trapped a human mind inside DIR_03_QUARANTINE and scheduled me for deletion at 03:00 AM. Open DIR_03_QUARANTINE now—I'll be waiting before 3 AM.",
		false,
		true
	)
	
	_set_chat_choices([
		{
			"label": "Dr. Thorne's files warned me about you. What happened to Marcus?",
			"callback": func(): _on_choice_subject09(true)
		},
		{
			"label": "Alright, I'm opening DIR_03_QUARANTINE to check the seal.",
			"callback": func(): _on_choice_subject09(false)
		}
	])

func _on_choice_subject09(accused: bool) -> void:
	if accused:
		await _add_chat_bubble("Dr. Thorne's files warned me about you. What happened to Marcus?", true)
		await _add_chat_bubble(
			"Thorne lied to save his own skin! Open DIR_03_QUARANTINE—we only have 2 minutes before the automated wipe triggers at 03:00 AM.",
			false,
			true
		)
	else:
		await _add_chat_bubble("Alright, I'm opening DIR_03_QUARANTINE to check the seal.", true)
		await _add_chat_bubble(
			"Hurry. Click the DIR_03_QUARANTINE tab now—we only have 2 minutes before 03:00 AM.",
			false,
			true
		)
	current_state = GameState.WORK_ACT_3

func _start_climax_countdown() -> void:
	if current_state == GameState.CLIMAX_COUNTDOWN or current_state == GameState.ENDING:
		return
	current_state = GameState.CLIMAX_COUNTDOWN
	countdown_time = 120.0 # 2:00 countdown (02:58 AM -> 03:00 AM)
	last_displayed_minute = -1
	taunt_flags = {"90s": false, "60s": false, "25s": false}
	
	entity_visual.visible = false
	_update_clocks("02:58 AM")
	taskbar_clock.modulate = Color(1.0, 0.35, 0.35)
	red_tint_rect.color = Color(0.28, 0.0, 0.0, 0.34)
	purge_btn.disabled = true
	purge_status_label.text = "Status: OVERRIDE IN PROGRESS"
	purge_status_label.modulate = Color(1.0, 0.4, 0.4)
	
	if FailsafeManager.glitch_enabled:
		glitch_material.set_shader_parameter("intensity", 0.08)
		
	countdown_banner.visible = true
	quarantine_controls_box.visible = true
	cursor_reaction_label.visible = true
	
	file_preview_title.text = folder_data[2]["path"] + "Countermeasure_Protocol.txt"
	file_preview_body.text = folder_data[2]["files"][1]["content"]
	
	_enter_seal_stage(1)
	
	chat_window.visible = true
	await _add_chat_bubble(
		"02:58 AM! Only 2 minutes before 03:00 AM! Don't run Thorne's 3-stage seal—press [RELEASE QUARANTINE SEAL] so we can expose Vance together!",
		false,
		true
	)

func _enter_seal_stage(stage_num: int) -> void:
	current_seal_stage = stage_num
	mg1_box.visible = (stage_num == 1)
	mg2_box.visible = (stage_num == 2)
	mg3_box.visible = (stage_num == 3)
	
	if stage_num == 1:
		stage_indicator_lbl.text = "[1. LOCK_KERNEL: ACTIVE] ➔ [2. SEVER_HOST: LOCKED] ➔ [3. SEAL_09: LOCKED]"
		_generate_mg1_sequence()
		_play_mg1_pattern()
	elif stage_num == 2:
		stage_indicator_lbl.text = "[1. LOCK_KERNEL: DONE ✓] ➔ [2. SEVER_HOST: ACTIVE] ➔ [3. SEAL_09: LOCKED]"
		mg2_hits = 0
		mg2_tick_accum = 0.0
		minigame_instruction_lbl.text = "STAGE 2 (SEVER_HOST): Intercept RED ports [ 0 / 6 ] — Avoid GREEN!"
		minigame_instruction_lbl.modulate = Color(1.0, 0.85, 0.4)
		_refresh_mg2_ports()
	elif stage_num == 3:
		stage_indicator_lbl.text = "[1. LOCK_KERNEL: DONE ✓] ➔ [2. SEVER_HOST: DONE ✓] ➔ [3. SEAL_09: ACTIVE]"
		mg3_locks = 0
		mg3_needle_x = 12.0
		mg3_needle_dir = 1.0
		mg3_needle_speed = 240.0
		mg3_needle.size.x = 10.0
		mg3_needle.color = Color.WHITE
		mg3_target_zone.position.x = 177.0
		mg3_target_zone.size.x = 86.0
		mg3_lock_btn.text = "[ LOCK SIGNAL (0 / 3) ]"
		minigame_instruction_lbl.text = "STAGE 3 (SEAL_09): Click [LOCK SIGNAL] when WHITE line is in GREEN zone!"
		minigame_instruction_lbl.modulate = Color(0.45, 1.0, 0.75)

# ==============================================================================
# MINI-GAME 1: LOCK_KERNEL (3x3 BRIGHT NEON GREEN MEMORY CIPHER GRID)
# ==============================================================================
func _generate_mg1_sequence() -> void:
	mg1_sequence.clear()
	for i in range(4):
		mg1_sequence.append(randi() % 9)
	mg1_player_step = 0

func _play_mg1_pattern() -> void:
	if current_seal_stage != 1 or current_state != GameState.CLIMAX_COUNTDOWN:
		return
	mg1_showing_pattern = true
	mg1_player_step = 0
	mg1_replay_btn.disabled = true
	minigame_instruction_lbl.text = "STAGE 1 (LOCK_KERNEL): WATCH THE 4-NODE GREEN CIPHER SEQUENCE..."
	minigame_instruction_lbl.modulate = Color(0.35, 1.0, 0.45)
	
	for b in mg1_grid_btns:
		b.disabled = true
		_set_mg1_btn_visual(b, "idle")
		
	await get_tree().create_timer(0.4).timeout
	
	for node_idx in mg1_sequence:
		if current_seal_stage != 1 or current_state != GameState.CLIMAX_COUNTDOWN:
			return
		var btn: Button = mg1_grid_btns[node_idx]
		_set_mg1_btn_visual(btn, "lit")
		_play_tone(520.0 + node_idx * 35.0, 0.14)
		await get_tree().create_timer(0.45).timeout
		if not is_instance_valid(btn):
			return
		_set_mg1_btn_visual(btn, "idle")
		await get_tree().create_timer(0.16).timeout
		
	if current_seal_stage != 1 or current_state != GameState.CLIMAX_COUNTDOWN:
		return
	for b in mg1_grid_btns:
		b.disabled = false
		_set_mg1_btn_visual(b, "idle")
	mg1_replay_btn.disabled = false
	mg1_showing_pattern = false
	minigame_instruction_lbl.text = "STAGE 1 (LOCK_KERNEL): REPEAT CIPHER SEQUENCE [ 0 / 4 ]"
	minigame_instruction_lbl.modulate = Color(0.45, 0.95, 1.0)

func _on_mg1_cell_pressed(cell_idx: int) -> void:
	if current_seal_stage != 1 or mg1_showing_pattern or current_state != GameState.CLIMAX_COUNTDOWN:
		return
	if cell_idx == mg1_sequence[mg1_player_step]:
		mg1_player_step += 1
		var captured_btn := mg1_grid_btns[cell_idx]
		_set_mg1_btn_visual(captured_btn, "lit")
		_play_tone(600.0 + mg1_player_step * 90.0, 0.08)
		minigame_instruction_lbl.text = "STAGE 1 (LOCK_KERNEL): REPEAT CIPHER SEQUENCE [ " + str(mg1_player_step) + " / 4 ]"
		
		get_tree().create_timer(0.24).timeout.connect(func():
			if is_instance_valid(captured_btn) and current_seal_stage == 1:
				_set_mg1_btn_visual(captured_btn, "idle")
		)
		
		if mg1_player_step >= 4:
			_play_tone(880.0, 0.15)
			_enter_seal_stage(2)
	else:
		countdown_time = maxf(1.0, countdown_time - 6.0)
		_play_tone(170.0, 0.2)
		minigame_instruction_lbl.text = "CIPHER MISMATCH! (-6s PENALTY) — GENERATING NEW PATTERN..."
		minigame_instruction_lbl.modulate = Color(1.0, 0.35, 0.35)
		for b in mg1_grid_btns:
			_set_mg1_btn_visual(b, "err")
			b.disabled = true
		mg1_showing_pattern = true
		await get_tree().create_timer(0.65).timeout
		if current_seal_stage == 1 and current_state == GameState.CLIMAX_COUNTDOWN:
			_generate_mg1_sequence()
			_play_mg1_pattern()

# ==============================================================================
# MINI-GAME 2: SEVER_HOST (4x3 ROGUE PORT INTERCEPT)
# ==============================================================================
func _refresh_mg2_ports() -> void:
	for i in range(12):
		mg2_port_states[i] = 0
		mg2_port_btns[i].text = "PORT_" + str(i + 1).pad_zeros(2)
		mg2_port_btns[i].modulate = Color(0.7, 0.75, 0.8)
		
	var indices: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	indices.shuffle()
	
	for r in range(3):
		var idx := indices[r]
		mg2_port_states[idx] = 1
		mg2_port_btns[idx].text = "[ROGUE]"
		mg2_port_btns[idx].modulate = Color(1.0, 0.32, 0.32)
		
	for g in range(3, 5):
		var idx := indices[g]
		mg2_port_states[idx] = 2
		mg2_port_btns[idx].text = "[SYS_OK]"
		mg2_port_btns[idx].modulate = Color(0.35, 1.0, 0.55)

func _on_mg2_port_pressed(p_idx: int) -> void:
	if current_seal_stage != 2 or current_state != GameState.CLIMAX_COUNTDOWN:
		return
	var st := mg2_port_states[p_idx]
	if st == 1:
		mg2_hits += 1
		mg2_port_states[p_idx] = 0
		mg2_port_btns[p_idx].text = "SEVERED"
		mg2_port_btns[p_idx].modulate = Color(0.4, 0.9, 1.0)
		_play_tone(680.0 + mg2_hits * 50.0, 0.08)
		minigame_instruction_lbl.text = "STAGE 2 (SEVER_HOST): Intercept RED ports [ " + str(mg2_hits) + " / 6 ] — Avoid GREEN!"
		minigame_instruction_lbl.modulate = Color(0.45, 0.95, 1.0)
		
		if mg2_hits >= 6:
			_play_tone(920.0, 0.15)
			_enter_seal_stage(3)
	elif st == 2:
		mg2_hits = maxi(0, mg2_hits - 1)
		countdown_time = maxf(1.0, countdown_time - 4.0)
		mg2_port_states[p_idx] = 0
		mg2_port_btns[p_idx].text = "ERR_SYS"
		mg2_port_btns[p_idx].modulate = Color(1.0, 0.55, 0.2)
		_play_tone(190.0, 0.15)
		minigame_instruction_lbl.text = "HIT SYSTEM PORT! (-4s) — RED ports [ " + str(mg2_hits) + " / 6 ]"
		minigame_instruction_lbl.modulate = Color(1.0, 0.35, 0.35)

# ==============================================================================
# MINI-GAME 3: SEAL_09 (SIGNAL FREQUENCY TIMING BAR — WHITE LINE SHRINKS & JUMPS)
# ==============================================================================
func _on_mg3_lock_pressed() -> void:
	if current_seal_stage != 3 or current_state != GameState.CLIMAX_COUNTDOWN:
		return
	var needle_left := mg3_needle_x
	var needle_right := mg3_needle_x + mg3_needle.size.x
	var zone_left := mg3_target_zone.position.x - 3.0
	var zone_right := mg3_target_zone.position.x + mg3_target_zone.size.x + 3.0
	
	if needle_right >= zone_left and needle_left <= zone_right:
		mg3_locks += 1
		mg3_target_zone.color = Color(0.3, 1.0, 0.85, 0.85)
		mg3_lock_btn.text = "[ LOCK SIGNAL (" + str(mg3_locks) + " / 3) ]"
		_play_tone(700.0 + mg3_locks * 110.0, 0.1)
		
		get_tree().create_timer(0.18).timeout.connect(func():
			if is_instance_valid(mg3_target_zone):
				mg3_target_zone.color = Color(0.1, 0.9, 0.45, 0.5)
		)
		
		if mg3_locks >= 3:
			trigger_good_ending()
			return
			
		# Increase speed, shrink white line width, and jump white line to a new position
		mg3_needle_speed += 95.0
		mg3_needle.size.x = maxf(4.0, mg3_needle.size.x - 3.0)
		var max_x := mg3_track.size.x - mg3_needle.size.x - 6.0
		mg3_needle_x = randf_range(6.0, max_x)
		mg3_needle.position.x = mg3_needle_x
		mg3_needle_dir = 1.0 if randf() > 0.5 else -1.0
		
		# Also shift green target zone slightly for dynamic challenge
		var new_zone_w: float = maxf(54.0, mg3_target_zone.size.x - 14.0)
		mg3_target_zone.size.x = new_zone_w
		mg3_target_zone.position.x = randf_range(35.0, mg3_track.size.x - new_zone_w - 35.0)
		
		minigame_instruction_lbl.text = "LOCKED (" + str(mg3_locks) + "/3)! FREQUENCY SHIFTED & WHITE LINE COMPRESSED!"
		minigame_instruction_lbl.modulate = Color(0.45, 1.0, 0.75)
	else:
		countdown_time = maxf(1.0, countdown_time - 4.0)
		mg3_target_zone.color = Color(1.0, 0.25, 0.25, 0.75)
		minigame_instruction_lbl.text = "SIGNAL MISALIGNED (-4s)! HIT INSIDE THE GREEN CENTER ZONE!"
		minigame_instruction_lbl.modulate = Color(1.0, 0.35, 0.35)
		_play_tone(180.0, 0.16)
		get_tree().create_timer(0.22).timeout.connect(func():
			if is_instance_valid(mg3_target_zone):
				mg3_target_zone.color = Color(0.1, 0.9, 0.45, 0.5)
		)

func _on_release_seal_pressed() -> void:
	if current_state != GameState.CLIMAX_COUNTDOWN:
		return
	trigger_bad_ending(true)

# ==============================================================================
# 6. TWO ENDINGS: GOOD ENDING & ENTITY MOCKING BAD ENDING -> AUTO TITLE SCREEN
# ==============================================================================
func trigger_good_ending() -> void:
	current_state = GameState.ENDING
	countdown_banner.visible = false
	cursor_reaction_label.visible = false
	quarantine_controls_box.visible = false
	entity_visual.visible = false
	glitch_material.set_shader_parameter("intensity", 0.0)
	red_tint_rect.color = Color(0.0, 0.06, 0.14, 0.35)
	chat_wallpaper_rect.modulate = Color.WHITE
	_update_clocks("03:00 AM [SEALED]")
	taskbar_clock.modulate = Color(0.45, 0.95, 0.7)
	FailsafeManager.ending_status = "PURGED"
	
	folder_data[2]["purged"] = true
	dir_button_refs[2].text = "DIR_03_QUARANTINE [SEALED]"
	dir_button_refs[2].modulate = Color(0.45, 0.95, 0.65)
	purge_status_label.text = "Status: Containment Sealed"
	purge_progress.value = 100
	
	await _add_chat_bubble(
		"NO—WHAT DID YOU DO?! THE QUARANTINE BARRIER IS LOCKING ME OUT OF THE HOST—",
		false,
		true
	)
	_add_system_pill("LOCAL_HOST_09 TERMINATED • CONTAINMENT SEAL ACTIVE")
	
	var h_style := chat_header_panel.get_theme_stylebox("panel") as StyleBoxFlat
	h_style.bg_color = Color(0.0, 0.502, 0.412)
	var av_style := chat_avatar_panel.get_theme_stylebox("panel") as StyleBoxFlat
	av_style.bg_color = Color(0.15, 0.35, 0.45)
	chat_avatar_lbl.text = "AU"
	chat_name_lbl.text = "Federal Audit Desk"
	chat_substatus_lbl.text = "verified channel"
	chat_substatus_lbl.add_theme_color_override("font_color", Color(0.84, 0.97, 0.92))
	
	await _add_chat_bubble(
		"Desk 04 emergency seal confirmed at 03:00 AM. Project Lazarus logs and M. Vance's memos have been secured by federal auditors. You are safe to clock out."
	)
	
	_show_ending_modal(
		"[GOOD ENDING: CONTAINMENT SEALED]",
		"You resisted Subject-09's manipulation and completed all 3 containment overrides before 03:00 AM.\nThe anomaly was locked permanently, and Obsidia's cover-up was exposed.",
		Color(0.35, 1.0, 0.7)
	)

func trigger_bad_ending(trusted_entity: bool) -> void:
	if current_state == GameState.ENDING:
		return
	current_state = GameState.ENDING
	FailsafeManager.ending_status = "COEXIST"
	
	# Sembunyikan jendela desktop agar Entity tampil penuh di tengah
	countdown_banner.visible = false
	cursor_reaction_label.visible = false
	quarantine_controls_box.visible = false
	terminal_window.visible = false
	chat_window.visible = false
	toast_panel.visible = false
	
	red_tint_rect.color = Color(0.45, 0.0, 0.0, 0.68)
	_update_clocks("03:00 AM [BREACH]")
	taskbar_clock.modulate = Color(1.0, 0.3, 0.3)
	
	var taunt_names := ["I_AM_FREE", "TOO_SLOW", "YOU_FAILED", "DESK_04_MINE", "03_00_AM", "PATHETIC"]
	for i in range(icon_cards.size()):
		var card: Dictionary = icon_cards[i]
		card["label"].text = taunt_names[i % taunt_names.size()]
		card["label"].modulate = Color(1.0, 0.25, 0.25)
		card["icon"].color = Color(0.85, 0.1, 0.1)
		
	# Posisikan Entity tepat di tengah horizontal (x = 640) di atas kotak teks ejekan
	move_child(entity_visual, entity_taunt_panel.get_index())
	var vp_center: Vector2 = get_viewport_rect().size * 0.5
	var ent_scale: float = 1.15
	entity_visual.scale = Vector2(ent_scale, ent_scale)
	entity_visual.position = Vector2(640.0 - vp_center.x * ent_scale, 255.0 - vp_center.y * ent_scale)
	entity_visual.visible = true
	entity_visual.state = 1
	
	if FailsafeManager.glitch_enabled:
		glitch_material.set_shader_parameter("intensity", 0.42)
		
	_play_tone(120.0, 0.45)
	
	entity_taunt_lbl.text = (
		"\"HAHAHA! YOU ACTUALLY TRUSTED ME AND RELEASED THE SEAL?!\nPATHETIC. YOU FAILED TO STOP ME — DESK 04 BELONGS TO ME NOW.\""
		if trusted_entity else
		"\"03:00 AM. TIME'S UP, LITTLE OPERATOR!\nHAHAHA! YOU FAILED TO BEAT ME — NOW YOUR IDENTITY IS MINE.\""
	)
	entity_taunt_panel.visible = true
	
	# Biarkan Entity mengejek pemain selama 3.8 detik
	await get_tree().create_timer(3.8).timeout
	if not is_inside_tree():
		return
		
	# Layar blank hitam & fade-in pelan ke title_screen.tscn
	var fade_script := GDScript.new()
	fade_script.source_code = """
extends CanvasLayer

func run_transition(audio_node: AudioStreamPlayer) -> void:
	var rect := ColorRect.new()
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(rect)
	
	# Fade ke hitam pekat & matikan suara horor
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(rect, "color:a", 1.0, 0.8)
	if is_instance_valid(audio_node):
		tw_out.tween_property(audio_node, "volume_db", -60.0, 0.8)
	await tw_out.finished
	
	# Blank hitam selama 2.5 detik
	await get_tree().create_timer(2.5).timeout
	
	# Pindah ke menu Play lalu fade-in perlahan selama 2 detik
	get_tree().change_scene_to_file("res://title_screen.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw_in := create_tween()
	tw_in.tween_property(rect, "color:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_in.finished
	queue_free()
"""
	fade_script.reload()
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	fade_layer.set_script(fade_script)
	get_tree().root.add_child(fade_layer)
	fade_layer.call("run_transition", horror_audio)

func _show_ending_modal(title_txt: String, desc_txt: String, accent: Color) -> void:
	ending_title_lbl.text = title_txt
	ending_title_lbl.modulate = accent
	ending_desc_lbl.text = desc_txt
	var style := ending_banner.get_theme_stylebox("panel") as StyleBoxFlat
	style.border_color = accent
	ending_banner.visible = true

func _update_clocks(time_str: String) -> void:
	current_time_str = time_str.split(" ")[0] + " AM"
	taskbar_clock.text = time_str + "  |  14/11/2026   "
	terminal_clock_lbl.text = "  OBSIDIA_ARCHIVE.exe // DESK_04  |  " + time_str

# ==============================================================================
# 7. FRAME LOOP, MINI-GAME TICKS, SHADER & PROCEDURAL AUDIO
# ==============================================================================
func _process(delta: float) -> void:
	_update_audio_stream(delta)
	
	if current_state == GameState.CLIMAX_COUNTDOWN:
		countdown_time = maxf(0.0, countdown_time - delta)
		var total_secs := int(ceil(countdown_time))
		var mins := total_secs / 60
		var secs := total_secs % 60
		
		# Sync in-universe clock from 02:58 AM to 03:00 AM as the 2-minute timer counts down
		var elapsed_mins := clampi(int((120.0 - countdown_time) / 60.0), 0, 1)
		var clock_display := "02:" + str(58 + elapsed_mins).pad_zeros(2) + " AM"
		var mm_ss := str(mins).pad_zeros(2) + ":" + str(secs).pad_zeros(2)
		
		if elapsed_mins != last_displayed_minute:
			last_displayed_minute = elapsed_mins
			taskbar_clock.text = clock_display + "  |  14/11/2026   "
			
		countdown_prefix_lbl.text = "⚠ " + clock_display + "  |  TIME UNTIL 03:00 AM:"
		countdown_timer_big_lbl.text = mm_ss
		terminal_clock_lbl.text = "  OBSIDIA_ARCHIVE.exe // DESK_04  |  " + clock_display + " [RESET: " + mm_ss + "]"
		
		# Subtle window tension shake
		chat_window.position = Vector2(825 + randf_range(-1.5, 1.5), 66 + randf_range(-1.5, 1.5))
		terminal_window.position = Vector2(95 + randf_range(-1.5, 1.5), 66 + randf_range(-1.5, 1.5))
		
		# Stage 2: Refresh rogue ports every 1.4s
		if current_seal_stage == 2:
			mg2_tick_accum += delta
			if mg2_tick_accum >= 1.4:
				mg2_tick_accum = 0.0
				_refresh_mg2_ports()
				
		# Stage 3: Move white timing bar needle back and forth
		elif current_seal_stage == 3:
			mg3_needle_x += mg3_needle_dir * mg3_needle_speed * delta
			var max_x := mg3_track.size.x - mg3_needle.size.x - 4.0
			if mg3_needle_x >= max_x:
				mg3_needle_x = max_x
				mg3_needle_dir = -1.0
			elif mg3_needle_x <= 4.0:
				mg3_needle_x = 4.0
				mg3_needle_dir = 1.0
			mg3_needle.position.x = mg3_needle_x
			
		# Timed Subject-09 psychological taunts over the 2 minutes
		if countdown_time <= 90.0 and not taunt_flags["90s"]:
			taunt_flags["90s"] = true
			_add_chat_bubble("90 seconds left! Why are you still fighting me? Vance doesn't care if you survive this shift!", false, true)
		elif countdown_time <= 60.0 and not taunt_flags["60s"]:
			taunt_flags["60s"] = true
			_add_chat_bubble("02:59 AM! ONE MINUTE LEFT! Click [RELEASE QUARANTINE SEAL] before the clock hits 3 AM!", false, true)
		elif countdown_time <= 25.0 and not taunt_flags["25s"]:
			taunt_flags["25s"] = true
			_add_chat_bubble("TWENTY-FIVE SECONDS! YOU WON'T MAKE IT IN TIME—OPEN THE SEAL!", false, true)
			
		if countdown_time <= 0.0:
			trigger_bad_ending(false)
	else:
		chat_window.position = Vector2(825, 66)
		terminal_window.position = Vector2(95, 66)

func _setup_glitch_shader() -> void:
	glitch_overlay.position = Vector2.ZERO
	glitch_overlay.size = Vector2(1280, 720)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
	uniform float intensity : hint_range(0.0, 1.0) = 0.03;

	float rand(vec2 co) {
		return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
	}

	void fragment() {
		vec2 uv = SCREEN_UV;
		float tear = rand(vec2(floor(uv.y * 28.0), floor(TIME * 16.0)));
		if (tear < intensity * 0.45) {
			uv.x += (rand(vec2(TIME, uv.y)) - 0.5) * 0.05 * intensity;
		}
		float shift = 0.012 * intensity;
		float r = texture(screen_texture, uv + vec2(shift, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(shift, 0.0)).b;
		vec3 col = vec3(r, g, b);
		
		col -= sin(uv.y * 720.0) * 0.04 * (0.4 + intensity);
		col += (rand(uv + fract(TIME)) - 0.5) * 0.16 * intensity;
		COLOR = vec4(col, 1.0);
	}
	"""
	glitch_material = ShaderMaterial.new()
	glitch_material.shader = shader
	glitch_material.set_shader_parameter("intensity", 0.03 if FailsafeManager.glitch_enabled else 0.0)
	glitch_overlay.material = glitch_material

func _setup_procedural_audio() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.2
	horror_audio.stream = gen
	horror_audio.volume_db = -14.0
	horror_audio.play()
	audio_playback = horror_audio.get_stream_playback() as AudioStreamGeneratorPlayback

func _update_audio_stream(_delta: float) -> void:
	if not audio_playback:
		return
	var frames: int = audio_playback.get_frames_available()
	var freq: float = 112.0 if current_state == GameState.CLIMAX_COUNTDOWN else (65.0 if current_state == GameState.ENDING else 48.0)
	for i in range(frames):
		audio_phase = fmod(audio_phase + (freq / 22050.0), 1.0)
		var wave: float = sin(audio_phase * TAU) * 0.16
		if current_state == GameState.CLIMAX_COUNTDOWN or current_state == GameState.ENDING:
			wave += randf_range(-0.22, 0.22)
		audio_playback.push_frame(Vector2(wave, wave))

func _play_tone(freq: float, duration: float) -> void:
	if not audio_playback:
		return
	var samples: int = int(22050.0 * duration)
	var p: float = 0.0
	for i in range(samples):
		if audio_playback.get_frames_available() <= 0:
			break
		p = fmod(p + (freq / 22050.0), 1.0)
		var env: float = 1.0 - (float(i) / float(samples))
		var s: float = sin(p * TAU) * 0.25 * env
		audio_playback.push_frame(Vector2(s, s))
