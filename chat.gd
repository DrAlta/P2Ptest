# An example P2P chat client (chat.gd)
extends Node

const BOOTSTRAP_DELAY = 10

signal logy(msg)
signal incoming_bootstrap_offer(offer)
signal incoming_bootstrap_answer(answer)
signal outgoing_bootstrap_answer(answer)

class Peer:
	signal emit_ice(id, mid_name, index_name, sdp_name)
	var connection : WebRTCPeerConnection
	var channel : WebRTCDataChannel
	var id : String = "bootstrap"

	func _new_ice_candidate(mid_name, index_name, sdp_name):
	# warning-ignore:return_value_discarded
		emit_signal("new_ice", id, mid_name, index_name, sdp_name)


var myself_id
var my_peers : Array = []

var incoming_bootstrap : Peer
var outgoing_bootstrap : Peer
var bootstrap_clock :int = 0
var incoming_status
func _ready():
	myself_id = randi()




	
################################################################################
func _process(_delta):
	# bootstrap_clock keeps tracks of how many frames we've provessed. when it 
	# reaches BOOTSTARP_DELAY we set it to 0 and then if it's 0 we ask unknown 
	# peers for their id
	bootstrap_clock += 1
	if bootstrap_clock == BOOTSTRAP_DELAY:
		print("incoming status", incoming_bootstrap.channel.get_ready_state())
		bootstrap_clock = 0
	process_peers()
	if incoming_bootstrap:
#		print("incoming status", incoming_bootstrap.channel.get_ready_state())
		process_peer(incoming_bootstrap)
		if incoming_bootstrap.channel.get_ready_state() != 0:
			incoming_status = incoming_bootstrap.channel.get_ready_state()
			print("incoming status", incoming_status)


	if outgoing_bootstrap:
		process_peer(outgoing_bootstrap)

func process_peers():
	for peer in my_peers:
		process_peer(peer)


func process_peer(peer):
#	print("peer boop", peer.id)
	peer.connection.poll()
	if peer.channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		print("peer:", peer.id)
		if peer.channel.get_available_packet_count() > 0:
			var msg = peer.channel.get_packet().get_string_from_utf8()
			print("%s received: \"%s\"From %s" % [str(myself_id), msg, str(peer.id)])
			_parse_msg(msg, peer)
		# If it's bootstraping idetify ourselves and set it's ID to sleeping so 
		# we don't keep spaming them
		if peer.id == "bootstrap":
			print("identfiing myself")
			send_message_to(JSON.print({"Type":"Me", "Me": myself_id}), peer)
			peer.id = "sleeping"
		# If the peer hasn't idetified itself when the bootstrap_clock resets
		# ask it who it is.
		elif peer.id == "sleeping" and bootstrap_clock == 0:
			send_message_to(JSON.print({"Type":"Who"}), peer)


func send_message_to(msg, peer: Peer):
	return(peer.channel.put_packet(msg.to_utf8()))

func send_message(message):
	for peer in my_peers:
		send_message_to(message, peer)

################################################################################
#bootstap
#####
##
#incoming bootstraps
##
func create_incoming_bootstrap():
	incoming_bootstrap = Peer.new()
	incoming_bootstrap.connection = WebRTCPeerConnection.new()
	var _discard = incoming_bootstrap.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	_discard = incoming_bootstrap.connection.connect("session_description_created", self, "_incoming_session_created")
	
	# Create negotiated data channel
	incoming_bootstrap.channel = incoming_bootstrap.connection.create_data_channel("chat", {"negotiated": true, "id": 1})
	
	incoming_bootstrap.connection.connect("ice_candidate_created", incoming_bootstrap, "_new_ice_candidate")
	incoming_bootstrap.connect("emit_ice", incoming_bootstrap, "send_candidate")

func _incoming_session_created(type, data):
	print(type,":set incom local desc:", incoming_bootstrap.connection.set_local_description(type, data))
# warning-ignore:return_value_discarded
	if type == "offer": 
		emit_signal("incoming_bootstrap_offer", data)

func incoming_bootstrap_answer(answer):
	print("answer:incoming set Remote desc:", incoming_bootstrap.connection.set_remote_description("answer", answer))
	emit_signal("incoming_bootstrap_answer", answer)


##
#outgoing bootstraps
##
func create_outgoing_bootstrap():
	outgoing_bootstrap = Peer.new()
	outgoing_bootstrap.connection = WebRTCPeerConnection.new()
	outgoing_bootstrap.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	var _discard = outgoing_bootstrap.connection.connect("session_description_created", self, "_outgoing_session_description")

	# Create negotiated data channel
	outgoing_bootstrap.channel = outgoing_bootstrap.connection.create_data_channel("chat", {"negotiated": true, "id": 1})
	
	outgoing_bootstrap.connection.connect("ice_candidate_created", outgoing_bootstrap, "_new_ice_candidate")
	outgoing_bootstrap.connect("emit_ice", outgoing_bootstrap, "send_candidate")


func _outgoing_session_description(type, data):
	print(type, "set out local desc:", outgoing_bootstrap.connection.set_local_description(type, data)) 
	if type == "answer": 
#		print("emiting out answer")
		emit_signal("outgoing_bootstrap_answer", data)
	else:
		print("oops2")
		


#####
#end bootstrap
################################################################################


func _create_peer():
	var peer = Peer.new()
	peer.connection = WebRTCPeerConnection.new()
	peer.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	peer.connection.connect("session_description_created", peer, "_session_description_created")
	peer.connection.connect("ice_candidate_created", peer, "_new_ice_candidate")
	peer.connect("emit_ice", peer, "send_candidate")

	# Create negotiated data channel
	peer.channel = peer.connection.create_data_channel("chat", {"negotiated": true, "id": 1})

	return peer

func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg("C", id, "\n%s\n%d\n%s" % [mid, index, sdp])


func _session_description_created(type, data, peer_id: int):
#	print(JSON.print({"Type": type, "Dest": peer.id, "Data": data}))

	if peer_id in my_peers:
		var peer =my_peers[peer_id]
# warning-ignore:return_value_discarded
		print(peer.id, " set local desc:", peer.connection.set_local_description(type, data))
# warning-ignore:return_value_discarded
		if type == "offer": 
			send_offer(peer, data)
# warning-ignore:return_value_discarded
		else: 
			send_answer(peer, data)
	else:
		return

func send_offer(peer : Peer, offer) -> int:
	var msg = JSON.print({"Type": "O", "Src": myself_id, "Peer": peer.id, "Offer": offer})
	emit_signal("logy", "Sent to %s: %s" % [peer.id, msg])
	return(send_message_to(msg, peer))

func send_answer(peer : Peer, answer) -> int:
	return _send_msg("A", peer, answer)

func offer_received(peer : Peer,offer):
	emit_signal("logy", "Got offer:" + str(offer))

	print(peer.id, " RD:",peer.connection.set_remote_description("offer", offer))


################################################################################
# messaging
#####

func _send_msg(type, peer, data) -> int:
	var msg = JSON.print({"Type": type, "Src": myself_id, "Data": data})
	emit_signal("logy", "Sent to %s: %s" % [peer.id, msg])
	return(send_message_to(msg, peer))


func _parse_msg(msg: String, src : Peer):
	var req = JSON.parse(msg) 

	assert("Type" in req)
	var type = req["Type"]

	if type == "O":
		# Offer received
		if "Peer" in req and "Offer" in req:
			var peer_id = src.id + req["Peer"]
			emit_signal("offer_received", peer_id, req["Offer"])
		else:
			emit_signal("logy", "invalid offer from %s" % src.id)
			
	elif type == "A":
		# Answer received
		if "Peer" in req and "Offer" in req:
			var peer_id = src.id + req["Peer"]
			emit_signal("answer_received", peer_id, req["Data"])
	elif type == "C":
		# Candidate received
		var candidate: PoolStringArray = req["Data"].split("\n", false)
		if candidate.size() != 3:
			return
		if not candidate[1].is_valid_integer():
			return
		emit_signal("candidate_received", src, candidate[0], int(candidate[1]), candidate[2])
