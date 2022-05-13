extends Control

export (PackedScene) var offer_scene
onready var log_label : = $VBoxContainer/Log
onready var networking : = $Node

var outgoing_vacant : = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
# warning-ignore:return_value_discarded
	networking.connect("logy", self, "logy")
# warning-ignore:return_value_discarded
	networking.connect("outgoing_bootstrap_answer", self, "display_answer")
# warning-ignore:return_value_discarded
	networking.connect("outgoing_connected", $AnswerPopup, "hide")

# warning-ignore:return_value_discarded
	$VBoxContainer/HBoxContainer/ConnectButton.connect("pressed", self, "main_connect")
# warning-ignore:return_value_discarded
	$OffersWindow/VBoxContainer/HBoxContainer/Button.connect("pressed", self, "offers_connect")
# warning-ignore:return_value_discarded
	$VBoxContainer/HBoxContainer/MyOfferButton.connect("pressed", self, "setup_offer")
	
# warning-ignore:return_value_discarded
	$AnswerPopup/VBoxContainer/HSplitContainer/Close.connect("pressed", $AnswerPopup, "hide")
# warning-ignore:return_value_discarded
	$AnswerPopup/VBoxContainer/HSplitContainer/Copy.connect("pressed", self, "copy_answer")
	pass # Replace with function body.

################################################################################
#Signal handlers
#####


func copy_answer():
	OS.clipboard=$AnswerPopup/VBoxContainer/AnswerOut.text

func logy(type, msg:String):
	log_label.text += str(type) + ":" + msg + "\n"

func display_answer(answer):
	$AnswerPopup/VBoxContainer/AnswerOut.text = JSON.print(answer)
	var center=rect_position+(rect_size/2)
	$AnswerPopup.set_as_minsize()
	$AnswerPopup.rect_position=(center-($AnswerPopup.rect_size/2))
	$AnswerPopup.show()

func main_connect():
	var adrs = JSON.parse($VBoxContainer/HBoxContainer/BootstrapOffer.text)
	if adrs.error == OK:
		process_bootstrap(adrs.result)

func offers_connect():
	var adrs = JSON.parse($OffersWindow/VBoxContainer/HBoxContainer/Answer.text)
	if adrs.error == OK:
		process_bootstrap(adrs.result)

func process_bootstrap(adrs):
	print("Bootstraping")
	if "Offer" in adrs and outgoing_vacant:
		outgoing_vacant = false
		networking.outgoing_bootstrap_offered(adrs)
	elif "Answer" in adrs:
		if str(adrs.ID) in networking.incoming_bootstraps:
			networking.incoming_bootstraps[str(adrs.ID)].on_bootstrap_answered(adrs)
		else:
			logy("error", "no outstang offer with id:" + str(adrs.ID))
			logy("debug", str(networking.incoming_bootstraps.keys()))
	else:
		logy("error", "Invalid offer")


func setup_offer():
	if not($OffersWindow/VBoxContainer.get_child_count() != 1 and $OffersWindow/VBoxContainer.visible == true):  
		var mob = offer_scene.instance()
		mob.initialize(networking.create_incoming_bootstrap())
		$OffersWindow/VBoxContainer.add_child(mob)
	var center=rect_position+(rect_size/2)
	$OffersWindow.set_as_minsize()
	$OffersWindow.rect_position=(center-($OffersWindow.rect_size/2))
	$OffersWindow.show()


################################################################################
#end sig handlers
#####
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
func _process(_delta):
	# hide the offer window if there are no offers
	if $OffersWindow/VBoxContainer.get_child_count() == 1:
		$OffersWindow.hide()

func process_answer(answer):
	logy("debug", "85:process_answer" + JSON.print(answer))
	if "ID" in answer and str(answer.ID) in networking.incoming_bootstraps:
		networking.incoming_bootstraps[str(answer.ID)].on_bootstrap_answered(answer)

func on_outgoing_connected():
	print("91:debug not going ot see this am I")
	outgoing_vacant = true
	$AnswerPopup.hide()
