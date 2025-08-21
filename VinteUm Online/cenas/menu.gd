extends Node2D

@onready var audio = $Audio

func _on_servidor_pressed():
	Global.play("res://sons/click-a.ogg")
	get_tree().change_scene_to_file("res://cenas/teste.tscn")

func _on_cliente_pressed():
	Global.play("res://sons/click-a.ogg")
	get_tree().change_scene_to_file("res://cenas/cliente.tscn")


func _on_line_edit_text_changed(new_text):
	Global.ip = new_text
