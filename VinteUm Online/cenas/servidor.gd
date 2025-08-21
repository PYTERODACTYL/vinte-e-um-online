extends Node

var server : TCPServer = TCPServer.new()
var clients = {}
var ready_status = {"player1": false, "player2": false}
var player_hands = {"player1": [], "player2": []}
var rematch_votes = {"player1": null, "player2": null}
var next_client_id = 1
var deck = []
var current_player = "player1"
var game_started = false
@onready var jogador1 = $Jogador1
@onready var jogador2 = $Jogador2

func _ready():
	jogador1.hide()
	jogador2.hide()
	var port = 10000
	var result = server.listen(port, Global.ip)
	
	if result == OK:
		print("Servidor ouvindo no IP ", Global.ip, " na porta ", port)
	else:
		print("Erro ao tentar iniciar o servidor no IP ", Global.ip, ": código de erro ", result)
	
	set_process(true)

func _process(delta):
	if server.is_connection_available():
		var client = server.take_connection()
		if client:
			var client_id = next_client_id
			clients[client_id] = client
			next_client_id += 1
			print("Novo cliente conectado com ID:", client_id)
			if next_client_id > 2:
				print("Ambos os jogadores conectados")
	
	for id in clients.keys():
		var client = clients[id]
		if client.get_available_bytes() > 0:
			var data = client.get_var()
			print("Dados recebidos do cliente", id, ":", data)
			if data == "pronto":
				mostrar_jogador(id)
				ready_status["player%d" % id] = true
				check_start_game()
			elif data == "pedir":
				deal_card("player%d" % id)
			elif data == "parar":
				end_turn()
			elif data == "rematch_yes":
				rematch_votes["player%d" % id] = true
				check_new_game()
			elif data == "rematch_no":
				rematch_votes["player%d" % id] = false
				check_new_game()

func randomize_card():
	return randi() % 11 + 1 

func check_start_game():
	if ready_status["player1"] and ready_status["player2"]:
		print("Ambos os jogadores estão prontos. Começando o jogo!")
		initialize_deck()
		deal_initial_cards()
		game_started = true
		current_player = "player1"
		notify_turn()

func initialize_deck():
	deck = []
	for i in range(3):
		for j in range(1, 14):
			deck.append(j)
	deck.shuffle()

func deal_initial_cards():
	for player in ["player1", "player2"]:
		for i in range(1): 
			deal_card(player)
		send_hand_to_player(player)

func deal_card(player):
	if deck.size() > 0:
		var card = deck.pop_back()
		player_hands[player].append(card)
		send_hand_to_player(player)

func send_hand_to_player(player):
	var client = clients[int(player.right(1))]
	client.put_var(player_hands[player])

func end_turn():
	if !game_started:
		return
	
	if current_player == "player1":
		current_player = "player2"
	else:
		current_player = "player1"
		check_winner()
	notify_turn()

func notify_turn():
	for player in ["player1", "player2"]:
		var client = clients[int(player.right(1))]
		if player == current_player:
			client.put_var("Sua vez")
		else:
			client.put_var("Aguarde")

func mostrar_jogador(id):
	if id == 1:
		jogador1.show()
		
	if id == 2:
		jogador2.show()

func check_winner():
	var scores = {"player1": calculate_hand_value(player_hands["player1"]), "player2": calculate_hand_value(player_hands["player2"])}
	var winner = ""
	var winner_score = -1

	for player in ["player1", "player2"]:
		var score = scores[player]
		if score > 21:
			continue
		if score > winner_score:
			winner_score = score
			winner = player

	if winner == "":
		clients[1].put_var("Empate")
		clients[2].put_var("Empate")
	else:
		clients[int(winner.right(1))].put_var("Você venceu!")
	var loser = ""
	if winner == "player1":
		loser = "player2"
	else:
		loser = "player1"

	clients[int(loser)].put_var("Você perdeu!")

	game_started = false  # Finaliza o jogo

func calculate_hand_value(hand):
	var total = 0
	var num_aces = 0
	for card in hand:
		if card > 10:
			total += 10  
		else:
			total += card
		if card == 1:
			num_aces += 1  
	while num_aces > 0 and total + 10 <= 21:
		total += 10
		num_aces -= 1
	return total

func check_new_game():
	if rematch_votes["player1"] != null and rematch_votes["player2"] != null:
		if rematch_votes["player1"] and rematch_votes["player2"]:
			start_new_game()
		else:
			end_game()

func start_new_game():
	ready_status = {"player1": false, "player2": false}
	player_hands = {"player1": [], "player2": []}
	rematch_votes = {"player1": null, "player2": null}
	current_player = "player1"
	game_started = false

	for id in clients.keys():
		var client = clients[id]
		client.put_var("Novo jogo iniciado")
		client.put_var("Reiniciando...")

func end_game():
	for client_id in clients.keys():
		var client = clients[client_id]
		client.put_var("Jogo encerrado")
