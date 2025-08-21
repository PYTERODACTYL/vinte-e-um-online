extends Node

var client : StreamPeerTCP = StreamPeerTCP.new()
var port : int = 10000
var connected = false
var jogoIniciado = false
var my_hand = []
var hand_container
var is_my_turn = false
var player_ready_for_rematch = false
@onready var botaoPronto = $Pronto
@onready var botaoPedir = $RequestCard
@onready var botaoPassar = $StopTurn
@onready var resultado = $Resultado
@onready var end_game = $EndGame
@onready var sim = $Sim
@onready var nao = $Nao

func _ready():
	botaoPassar.hide()
	botaoPedir.hide()
	sim.hide()
	nao.hide()
	var err = client.connect_to_host(Global.ip, port)
	if err != OK:
		print("não foi")
	else:
		print("foi")

	client.poll()
	set_process(true)
	hand_container = $HandContainer

func _process(delta):
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED and not connected:
			connected = true
			print("Conectado ao servidor")
		
		if connected and client.get_available_bytes() > 0:
			var data = client.get_var()
			handle_server_data(data)

func handle_server_data(data):
	if typeof(data) == TYPE_ARRAY:
		my_hand = data
		print("Minha mão:", my_hand)
		update_hand_display()
	elif typeof(data) == TYPE_STRING:
		match data:
			"Novo jogo iniciado":
				resultado.text = data
				is_my_turn = false
				update_button_state()
				botaoPronto.show()
				botaoPassar.hide()
				botaoPedir.hide()
				end_game.text = ""
				sim.hide()
				nao.hide()
				my_hand = []
			"Sua vez":
				is_my_turn = true
				update_button_state()
			"Aguarde":
				is_my_turn = false
				update_button_state()
			"Você venceu!":
				resultado.text = data
				handle_end_of_game()
			"Você perdeu!":
				resultado.text = data
				handle_end_of_game()
			"Empate":
				resultado.text = data
				handle_end_of_game()
			"Jogo encerrado":
				get_tree().quit()

func send_command(command: String):
	if is_my_turn or command.begins_with("rematch_"):
		client.put_var(command)
	else:
		print("Não é sua vez ainda.")

func update_button_state():
	botaoPedir.disabled = !is_my_turn
	botaoPassar.disabled = !is_my_turn
	 
func _on_pronto_pressed():
	Global.play("res://sons/click-a.ogg")
	if connected:
		client.put_var("pronto")
		print("Status enviado ao servidor: Pronto")
		botaoPassar.show()
		botaoPedir.show()
		botaoPronto.hide()

func _on_request_card_pressed():
	Global.play("res://sons/click-a.ogg")
	send_command("pedir")

func _on_stop_turn_pressed():
	Global.play("res://sons/click-a.ogg")
	send_command("parar")

func update_hand_display():
	for child in hand_container.get_children():
		child.queue_free()
	
	for card in my_hand:
		var card_texture_rect = TextureRect.new()
		var card_path = "res://texturas/cartas/card"+ str(card) + ".png"
		card_texture_rect.texture = load(card_path)
		hand_container.add_child(card_texture_rect)

func handle_end_of_game():
	end_game.text = "Nova partida?"
	sim.show()
	nao.show()

func _on_sim_pressed():
	send_command("rematch_yes")

func _on_nao_pressed():
	send_command("rematch_no")
