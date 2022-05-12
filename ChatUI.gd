extends Control

export (PackedScene) var offer_scene
onready var log_label : = $VBoxContainer/Log
onready var networking : = $Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _discard = networking.connect("logy", self, "logy")
	_discard = networking.connect("outgoing_bootstrap_answer", self, "display_answer")

	_discard = $VBoxContainer/HBoxContainer/ConnectButton.connect("pressed", self, "bootstrap")
	
	_discard = $AnswerPopup/VBoxContainer/HSplitContainer/Close.connect("pressed", $AnswerPopup, "hide")
	_discard = $AnswerPopup/VBoxContainer/HSplitContainer/Copy.connect("pressed", self, "copy_answer")
	pass # Replace with function body.

################################################################################
#Signal handlers
#####


func copy_answer():
	OS.clipboard=$AnswerPopup/VBoxContainer/AnswerOut.text

func logy(msg:String):
	log_label.text += msg + "\n"

func display_answer(answer):
	$AnswerPopup/VBoxContainer/AnswerOut.text = JSON.print(answer)
	$AnswerPopup.popup(Rect2( 0, 0, 100, 50 ))

func bootstrap():
	print("Bootstraping")
	var adrs = JSON.parse($VBoxContainer/HBoxContainer/BootstrapOffer.text)
	if adrs.error == OK:
		if "Offer" in adrs.result:
			networking.outgoing_bootstrap_offered($VBoxContainer/HBoxContainer/BootstrapOffer.text)
		elif "Answer" in adrs.result:
			networking.incoming_bootstrap_answered($VBoxContainer/HBoxContainer/BootstrapOffer.text)


func setup_offer():
	var boot = networking.create_incoming_bootstrap()
	var mob = offer_scene.instance()
	add_child(mob)
	mob.connect("got_answer", boot, "on_bootstrap_answered")
	boot.connect("incoming_bootstrap_offer", mob, "display_offer")
	boot.connect("incoming_bootstrap_answered", mob, "on_incoming_bootstrap_answered")
	boot.connect.create_offer()



################################################################################
#end sig handlers
#####
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
