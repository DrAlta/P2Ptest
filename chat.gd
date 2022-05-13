# An example P2P chat client (chat.gd)
extends Node

const BOOTSTRAP_DELAY = 1000

signal logy(type, msg)
signal outgoing_bootstrap_answer(answer)
signal outgoing_connected

class Peer:
	signal emit_ice(id, mid_name, index_name, sdp_name)
	var connection : WebRTCPeerConnection
	var channel : WebRTCDataChannel
	var id : String = "bootstrap"

	func _new_ice_candidate(mid_name, index_name, sdp_name):
	# warning-ignore:return_value_discarded
		emit_signal("emit_ice", id, mid_name, index_name, sdp_name)

class Boot:
	var peer: Peer
	var status : int = 0

class IncomingBootstrap:
	signal logy(type, msg)
	signal incoming_bootstrap_answered(incoming)
	signal incoming_bootstrap_offer(offer)

	var id : String
	var peer : Peer
	var incoming_offer
	var incoming_ice : = []

	func logy(type, msg : String):
		emit_signal("logy", type, msg)

	func on_ice_candidate(media, index, name):
		incoming_ice.append({"Media" : media, "Index" : index, "Name" : name})
		emit_signal("incoming_bootstrap_offer", {"ID" : id, "Offer" : incoming_offer, "ICE" : incoming_ice})

	func on_session_created(type, data):
		logy("incoming", str(type) + ":set incom local desc:" + str(peer.connection.set_local_description(type, data)))
		if type == "offer": 
			incoming_offer = data
			emit_signal("incoming_bootstrap_offer", {"Offer" : data, "ICE" : incoming_ice})

	func on_bootstrap_answered(answer):
			logy("incoming", "51:on_bootstrap_answered")
			if "Answer" in answer: 
				logy("incoming", "answer:incoming set Remote desc:" + str(peer.connection.set_remote_description("answer", answer.Answer)))
			if "ICE" in answer: 
				for ice in answer.ICE:
					peer.connection.add_ice_candidate(ice.Media, ice.Index, ice.Name)
			emit_signal("incoming_bootstrap_answered", self)
 
func on_incoming_bootstrap_answered(incoming : IncomingBootstrap):
	logy("debug", str(incoming.id) + " aswered")
	if incoming.id in my_connecting:
		logy("error", str(incoming.id) + "already in use in my_connecting")
	else:
		var boot = Boot.new()
		boot.peer = incoming.peer
		my_connecting[boot.peer.id] = boot
# warning-ignore:return_value_discarded
		incoming_bootstraps.erase(str(incoming.id))

var rand: RandomNumberGenerator = RandomNumberGenerator.new()

var myself_id
var my_peers : = {}

var incoming_bootstraps : = {}
var outgoing_bootstrap : Peer
var outgoing_ice : = []
var outgoing_answer
var outgoing_id : int
var bootstraps_count = 0

var my_connecting : = {}
var bootstrap_clock :int = 0
func _ready():
	myself_id = randi()
	create_outgoing_bootstrap()


	
################################################################################
func _process(_delta):
	# bootstrap_clock keeps tracks of how many frames we've provessed. when it 
	# reaches BOOTSTARP_DELAY we set it to 0 and then if it's 0 we ask unknown 
	# peers for their id
	bootstrap_clock += 1
	if bootstrap_clock == BOOTSTRAP_DELAY:
		bootstrap_clock = 0
	process_peers()
#	if incoming_bootstrap:
#		if incoming_bootstrap.channel.get_ready_state() != 0:
#			incoming_bootstrap.channel.get_ready_state()
#		incoming_bootstrap.connection.poll()

	if outgoing_bootstrap:
# warning-ignore:return_value_discarded
		outgoing_bootstrap.connection.poll()
		if outgoing_bootstrap.connection.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED:
			var boot = Boot.new()
			boot.peer = outgoing_bootstrap
			my_connecting[outgoing_bootstrap.id] = boot
			create_outgoing_bootstrap()
			emit_signal("outgoing_connected")


	for id in incoming_bootstraps.keys():
		incoming_bootstraps[id].peer.connection.poll()

	for boot_id in my_connecting.keys():
		process_bootstrap(my_connecting[boot_id])
	process_peers()

func process_peers():
	for peer_id in my_peers.keys():
		process_peer(my_peers[peer_id])


func process_bootstrap(boot):
	var peer = boot.peer
	peer.connection.poll()
	if peer.channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		if peer.channel.get_available_packet_count() > 0:
			var packet = peer.channel.get_packet().get_string_from_utf8()
			var temp : = JSON.parse(packet)
			if temp.error == 0:
				var msg = temp.result
				match msg:
					{"Type" : "Me", "Me" : var who}:
						if who in my_peers:
							logy("bootstrap", str(peer.id) + " identified itself as " + str(who) + " again...")
							send_message_to(JSON.print({"Type":"Not you again!"}), peer)
							peer.connection.close()
# warning-ignore:return_value_discarded
							my_connecting.erase(peer.id)
						else:
							logy("bootstrap", str(peer.id) + " identified itself as " + str(who))
# warning-ignore:return_value_discarded
							my_connecting.erase(peer.id)
							peer.id = who
							my_peers[peer.id] = peer
					{"Type" : "Who"}:
						send_message_to(JSON.print({"Type":"Me", "Me": myself_id}), peer)
					_ :
						logy("bootstrap_error", str(peer.id) + " sent unhandleed message:" + packet)
						peer.connection.close()
# warning-ignore:return_value_discarded
						my_connecting.erase(peer.id)
			else:
				logy("bootstrap_error", str(peer.id) + " sent invalid packet:" + packet)
				peer.connection.close()
# warning-ignore:return_value_discarded
				my_connecting.erase(peer.id)
		# If it's bootstraping idetify ourselves and set it's ID to sleeping so 
		# we don't keep spaming them
		if boot.status == 0:
			logy("bootstrap","identfiing myself")
			send_message_to(JSON.print({"Type":"Me", "Me": myself_id}), peer)
			boot.status = 1
		# If the peer hasn't idetified itself when the bootstrap_clock resets
		# ask it who it is.
		elif boot.status == 1 and bootstrap_clock == 0:
			send_message_to(JSON.print({"Type":"Who"}), peer)

func process_peer(peer):
	peer.connection.poll()
	if peer.channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		if peer.channel.get_available_packet_count() > 0:
			var msg = peer.channel.get_packet().get_string_from_utf8()
			logy("log", "163:%s received: \"%s\"From %s" % [str(myself_id), msg, str(peer.id)])
			_parse_msg(msg, peer)



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
	var boot = IncomingBootstrap.new()
	boot.peer = Peer.new()
	boot.connect("logy", self, "logy")
	boot.id = rand_id()
	boot.peer.id = "in" + str(bootstraps_count)
	boot.peer.connection = WebRTCPeerConnection.new()
	var _discard = boot.peer.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	print("178:", boot.peer.connection.connect("session_description_created", boot, "on_session_created"))

	# Create negotiated data channel
	boot.peer.channel = boot.peer.connection.create_data_channel("chat", {"id": 1, "negotiated": true})
	
	boot.peer.connection.connect("ice_candidate_created", boot, "on_ice_candidate")
	boot.connect("incoming_bootstrap_answered", self, "on_incoming_bootstrap_answered")
	incoming_bootstraps[boot.id] = boot
	return(boot)
#	incoming_bootstraps[boot.peer.id]

func rand_id():
	var id : = int(rand.randi())
	while id in incoming_bootstraps:
		id = int(rand.randi())
	return(id)



##
#outgoing bootstraps
##
func create_outgoing_bootstrap():
	outgoing_bootstrap = Peer.new()
	outgoing_bootstrap.id = "out" + str(bootstraps_count)
	outgoing_bootstrap.connection = WebRTCPeerConnection.new()
# warning-ignore:return_value_discarded
	outgoing_bootstrap.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	var _discard = outgoing_bootstrap.connection.connect("session_description_created", self, "_outgoing_session_description")

	# Create negotiated data channel
	outgoing_bootstrap.channel = outgoing_bootstrap.connection.create_data_channel("chat", {"id": 1, "negotiated": true})
	
# warning-ignore:return_value_discarded
	outgoing_bootstrap.connection.connect("ice_candidate_created", self, "outgoing_ice_candidate")
#	outgoing_bootstrap.connect("emit_ice", outgoing_bootstrap, "send_candidate")

func outgoing_ice_candidate(media, index, name):
	outgoing_ice.append({"Media" : media, "Index" : index, "Name" : name})
	print("211:outging ice")

##
## Send the anser to the offer given to the outgoing bootstrap
##
func _outgoing_session_description(type, data):
	print(type, "set out local desc:", outgoing_bootstrap.connection.set_local_description(type, data)) 
	if type == "answer": 
#		print("emiting out answer")
		yield(get_tree().create_timer(0.5), "timeout")
		emit_signal("outgoing_bootstrap_answer", ({"ID" : outgoing_id, "Answer" : data, "ICE": outgoing_ice}))
	else:
		print("oops2")
		
##
## give an offer to the outgoing bootstrap
##
func outgoing_bootstrap_offered(offer):
	if "Offer" in offer: 
		if "ID" in offer:
			outgoing_id = int(offer.ID)
			logy("bootstraping_outgoing", "253:offer:set outgoing remote desc" + str(outgoing_bootstrap.connection.set_remote_description("offer", offer.Offer)))
		else:
			logy("error", "offer had no ID")
	if "ICE" in offer: 
		for ice in offer.ICE:
# warning-ignore:return_value_discarded
			outgoing_bootstrap.connection.add_ice_candidate(ice.Media, ice.Index, ice.Name)


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
	peer.channel = peer.connection.create_data_channel("chat", {"id": 1, "negotiated": true})

	return peer

func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg("C", id, "\n%s\n%d\n%s" % [mid, index, sdp])


func _session_description_created(type, data, peer_id: int):
#	print(JSON.print({"Type": type, "Dest": peer.id, "Data": data}))

	if peer_id in my_peers:
		var peer =my_peers[peer_id]
# warning-ignore:return_value_discarded
		logy("network", str(peer.id) + " set local desc:" +  str(peer.connection.set_local_description(type, data)))
# warning-ignore:return_value_discarded
		if type == "offer": 
			send_offer(peer, data)
# warning-ignore:return_value_discarded
		else: 
			send_answer(peer, data)
	else:
		return

func send_offer(peer : Peer, offer) -> int:
	var msg = JSON.print({"Type": "Offer", "Src": myself_id, "Peer": peer.id, "Offer": offer})
	logy("network", "Sent to %s: %s" % [peer.id, msg])
	return(send_message_to(msg, peer))

func send_answer(peer : Peer, answer) -> int:
	var msg = JSON.print({"Type": "Answer", "Src": myself_id, "Peer": peer.id, "Answer": answer})
	logy("netork", "Sent to %s: %s" % [peer.id, msg])
	return(send_message_to(msg, peer))

func offer_received(peer : Peer,offer):
	logy("network", "Got offer:" + str(offer))

	logy("network", str(peer.id) + " RD:" + str(peer.connection.set_remote_description("offer", offer)))


################################################################################
# messaging
#####

func _send_msg(type, peer, data) -> int:
	var msg = JSON.print({"Type": type, "Src": myself_id, "Data": data})
	logy("network", "Sent to %s: %s" % [peer.id, msg])
	return(send_message_to(msg, peer))


func _parse_msg(msg: String, src : Peer):
	logy("network", src.id + " sent " + msg)
	var temp = JSON.parse(msg)
	if temp.error == 0:
		var req = JSON.parse(msg).result
		assert("Type" in req)

		match req:
			{"Type" : "Offer", "Peer" : var peer, "Offer" : var offer}:
				# Offer received
				var peer_id = src.id + str(peer)
				emit_signal("offer_received", peer_id, offer)
				#Try do connect it it's new peer or forward it along if we requested it for someone else

			{"Type" : "Answer", "Peer" : var peer, "Answer" : var answer}:
				# Answer received
				var peer_id = src.id + str(peer)
				#Try do connect it it's new peer or forward it along if we requested it for someone else
				if peer_id in my_connecting:
					pass
				emit_signal("answer_received", peer_id, answer)
			{"Type" : "Candidate", "Candidate" : var candidate}:
				# Candidate received
				emit_signal("candidate_received", src, candidate[0], int(candidate[1]), candidate[2])
			_:
				logy("error", "352: oops unhandleed" + str(msg))

func logy(type, msg):
	emit_signal("logy", type, msg)
