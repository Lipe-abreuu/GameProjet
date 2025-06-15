extends Node

var events = [
	"Nacionalização do cobre",
	"Golpe militar no Cone Sul",
	"Invasão das Malvinas"
]

func pick_random():
	print(">> EVENTO: ", events[randi() % events.size()])
