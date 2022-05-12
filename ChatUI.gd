extends Control

export (PackedScene) var offer_scene
onready var log_label : = $VBoxContainer/Log
onready var networking : = $Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	networking.connect("logy", self, "logy")
	networking.connect("outgoing_bootstrap_answer", self, "display_answer")

	$VBoxContainer/HBoxContainer/ConnectButton.connect("pressed", self, "bootstrap")
	$VBoxContainer/HBoxContainer/MyOfferButton.connect("pressed", self, "setup_offer")
	
	$AnswerPopup/VBoxContainer/HSplitContainer/Close.connect("pressed", $AnswerPopup, "hide")
	$AnswerPopup/VBoxContainer/HSplitContainer/Copy.connect("pressed", self, "copy_answer")
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
		else:
			logy("Invalid offer")


func setup_offer():
	if not($OffersWindow/VBoxContainer.get_child_count() != 0 and $OffersWindow/VBoxContainer.visible == true):  
		var mob = offer_scene.instance()
		mob.initialize(networking.create_incoming_bootstrap())
		$OffersWindow/VBoxContainer.add_child(mob)
	$OffersWindow.show()


################################################################################
#end sig handlers
#####
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
