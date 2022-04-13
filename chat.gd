# An example P2P chat client (chat.gd)
extends Node

signal logy(msg)
signal incoming_offer(offer)
signal incoming_answer(answer)
signal outgoing_answer(answer)

class Peer:
	signal emit_ice(id, mid_name, index_name, sdp_name)
	var connection =2
	var channel =2

var incoming_bootstrap = 1
var outgoing_bootstrap = 2

func _ready():
	create_incoming_bootstrap()
	create_outgoing_bootstrap()

	incoming_bootstrap.connection.connect("ice_candidate_created", outgoing_bootstrap.connection, "add_ice_candidate")

	outgoing_bootstrap.connection.connect("session_description_created", outgoing_bootstrap.connection, "set_local_description")
	outgoing_bootstrap.connection.connect("session_description_created", incoming_bootstrap.connection, "set_remote_description")
	outgoing_bootstrap.connection.connect("session_description_created", self, "test")
	outgoing_bootstrap.connection.connect("ice_candidate_created", incoming_bootstrap.connection, "add_ice_candidate")

func _process(_delta):
	emit_signal("logy","\nincoming status"+ str(incoming_bootstrap.channel.get_ready_state()))
	
	if incoming_bootstrap:
		incoming_bootstrap.connection.poll()
	if outgoing_bootstrap:
		outgoing_bootstrap.connection.poll()

func test(a,b):
	yield(get_tree().create_timer(1), "timeout")
	print("Set incoming remote desc:", incoming_bootstrap.connection.set_remote_description("answer", b))
	print("is it working now")

func create_incoming_bootstrap():
	incoming_bootstrap = Peer.new()
	incoming_bootstrap.connection = WebRTCPeerConnection.new()
	var _discard = incoming_bootstrap.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	_discard = incoming_bootstrap.connection.connect("session_description_created", self, "_incoming_session_created")
	
	incoming_bootstrap.channel = incoming_bootstrap.connection.create_data_channel("chat", {"id": 1, "negotiated": true})

func _incoming_session_created(type, data):
	print("set incoming local desc:", incoming_bootstrap.connection.set_local_description(type, data))
	if type == "offer": 
		emit_signal("incoming_offer", data)

func create_outgoing_bootstrap():
	outgoing_bootstrap = Peer.new()
	outgoing_bootstrap.connection = WebRTCPeerConnection.new()
	outgoing_bootstrap.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	# Create negotiated data channel
	outgoing_bootstrap.channel = outgoing_bootstrap.connection.create_data_channel("chat", {"id": 1, "negotiated": true})

#func incoming_bootstrap_answer(answer):
#	print("Set incoming remote desc:", incoming_bootstrap.connection.set_remote_description("answer", answer))
#	emit_signal("incoming_answer", answer)

func outgoing_bootstrap_offer(offer):
	print( "Set outgoing remote desc:", outgoing_bootstrap.connection.set_remote_description("offer", offer))
