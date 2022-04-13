extends Control

onready var log_label : = $VBoxContainer/Log
onready var networking : = $Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _discard = networking.connect("logy", self, "logy")
	_discard = networking.connect("outgoing_answer", self, "display_answer")
	_discard = networking.connect("incoming_offer", self, "display_offer")

	_discard = $VBoxContainer/HBoxContainer/BootstrapButton.connect("pressed", self, "bootstrap")
	#networking.create_incoming_bootstrap()
	#networking.create_outgoing_bootstrap()
	networking.incoming_bootstrap.connection.create_offer()
	
	_discard = $AnswerPopup/VBoxContainer/HSplitContainer/Close.connect("pressed", $AnswerPopup, "hide")
	_discard = $AnswerPopup/VBoxContainer/HSplitContainer/Copy.connect("pressed", self, "copy_answer")
	_discard = $VBoxContainer/HBoxContainer/MyOfferButton.connect("pressed", self, "copy_offer")
	pass # Replace with function body.

################################################################################
#Signal handlers
#####

func copy_offer():
	OS.clipboard=$VBoxContainer/HBoxContainer/MyOffer.text

func copy_answer():
	OS.clipboard=$AnswerPopup/VBoxContainer/AnswerOut.text

func logy(msg:String):
	log_label.text += msg

func display_answer(answer):
	$AnswerPopup/VBoxContainer/AnswerOut.text = JSON.print({"Answer": answer})
	$AnswerPopup.popup(Rect2( 0, 0, 100, 50 ))

func display_offer(offer):
	$VBoxContainer/HBoxContainer/MyOffer.text = JSON.print({"Offer": offer})

func bootstrap():
	print("Bootstraping")
	var adrs = JSON.parse($VBoxContainer/HBoxContainer/BootstrapOffer.text)
	if adrs.error == OK:
		if "Offer" in adrs.result:
			networking.outgoing_bootstrap_offer(adrs.result["Offer"])
		elif "Answer" in adrs.result:
			networking.incoming_bootstrap_answer(adrs.result["Answer"])

################################################################################
#end sig handlers
#####
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
