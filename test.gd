extends Control

class Peer:
	var connection : WebRTCPeerConnection
	var channel : WebRTCDataChannel
	var ID : String


# Create the two peers
var incoming_bootstrap
var p2 = WebRTCPeerConnection.new()
# And a negotiated channel for each each peer
var ch2 = p2.create_data_channel("chat", {"id": 1, "negotiated": true})



func _ready():
	create_incoming_bootstrap()
	# Connect P1 session created to itself to set local description
	# Connect P1 session and ICE created to p2 set remote description and candidates
	incoming_bootstrap.connection.connect("session_description_created", self, "incoming_description")
	incoming_bootstrap.connection.connect("ice_candidate_created", p2, "add_ice_candidate")

	# Same for P2
	p2.connect("session_description_created", self, "_outgoing_bootstrap_offer_created")
	p2.connect("session_description_created", self, "outging_description")
	p2.connect("ice_candidate_created", incoming_bootstrap.connection, "add_ice_candidate")
	$Button.connect("pressed", self, "but1")
	$start.connect("pressed", self, "start1")

func start1():
	# Let P1 create the offer
	incoming_bootstrap.connection.create_offer()


func _process(_delta):
	# Poll connections
	incoming_bootstrap.connection.poll()
	p2.poll()

	# Check for messages
	if incoming_bootstrap.channel.get_ready_state() == incoming_bootstrap.channel.STATE_OPEN and incoming_bootstrap.channel.get_available_packet_count() > 0:
		print("P1 received: ", incoming_bootstrap.channel.get_packet().get_string_from_utf8())
	if ch2.get_ready_state() == ch2.STATE_OPEN and ch2.get_available_packet_count() > 0:
		print("P2 received: ", ch2.get_packet().get_string_from_utf8())


func create_incoming_bootstrap():
	incoming_bootstrap = Peer.new()
	incoming_bootstrap.connection = WebRTCPeerConnection.new()
	incoming_bootstrap.connection.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	incoming_bootstrap.connection.connect("session_description_created", self, "_incoming_bootstrap_offer_created")
###connect on asnswer
#	peer.Connection.connect("ice_candidate_created", self, "_new_ice_candidate")

	# Create negotiated data channel
	incoming_bootstrap.channel = incoming_bootstrap.connection.create_data_channel("chat", {"negotiated": true, "id": 1})
func _incoming_bootstrap_offer_created(a, b):
	$out.text= JSON.print(b)
	#but1()

func _outgoing_bootstrap_offer_created(a, b):
	print(a,"p2L", p2.set_local_description(a, b))

func but1():
	print("offerp1L", incoming_bootstrap.connection.set_local_description("offer", JSON.parse($out.text).result))
	print("offerP2R", p2.set_remote_description("offer", JSON.parse($out.text).result))
	# Wait a second and send message from P1
	yield(get_tree().create_timer(1), "timeout")
	incoming_bootstrap.channel.put_packet("Hi from P1".to_utf8())

	# Wait a second and send message from P2
	yield(get_tree().create_timer(1), "timeout")
	ch2.put_packet("Hi from P2".to_utf8())

func incoming_description(a, b):
	$out.text= JSON.print(b)

func outging_description(a, b):
	print(a,"P1R", incoming_bootstrap.connection.set_remote_description(a, b))
