extends CanvasLayer

onready var text_editor = get_node("Panel/HSplitContainer/HSplitContainer/TextEdit")
onready var texture_rect = get_node("Panel/HSplitContainer/HSplitContainer/TextureRect")

onready var save_button = get_node("Panel/HSplitContainer/VBoxContainer/SaveButton")

onready var characters_container = get_node("Panel/HSplitContainer/VBoxContainer/CharactersContainer")

const EROSteganography = preload("res://EROSteganography.gd")

var current_file_path

var image


func _ready():
	var image_texture = load("res://Content/ModTest/modtest.png")
	texture_rect.texture = image_texture
	
func open_file(path):

	image = Image.new()
	image.load(path)

	current_file_path = path

	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image)
	texture_rect.texture = image_texture
	save_button.disabled = false
	var data = EROSteganography.get_steganographic_data_from_image(image)
	if not typeof(data) == TYPE_INT:
		text_editor.text = data

func save_image():
	image = EROSteganography.store_string_in_image(image, text_editor.text)
	image.save_png(current_file_path)