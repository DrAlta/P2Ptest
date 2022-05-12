extends PanelContainer
signal got_answer(answer)

var boot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/OfferBox/Copy.connect("pressed", self, "copy_offer")
	$VBoxContainer/AnswerBox/Connect.connect("pressed", self, "process_answer")
	$VBoxContainer/AnswerBox/Cancel.connect("pressed", self, "on_cancel")
	pass # Replace with function body.

func _process(_delta):
	boot.peer.connection.poll()

func initialize(incoming):
	boot = incoming
	connect("got_answer", boot, "on_bootstrap_answered")
	boot.connect("incoming_bootstrap_offer", self, "display_offer")
	boot.connect("incoming_bootstrap_answered", self, "on_incoming_bootstrap_answered")
	boot.connect("incoming_bootstrap_answered", self, "on_cancel")
	boot.peer.connection.create_offer()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
func copy_offer():
	OS.clipboard=$VBoxContainer/OfferBox/Offer.text

func display_offer(offer):
	$VBoxContainer/OfferBox/Offer.text = JSON.print(offer)

func process_answer():
	var temp = JSON.parse($VBoxContainer/AnswerBox/Answer.text)
	if temp.error == OK:
		if "Answer" in temp.result:
			print("36:process_answer:answer found")
			emit_signal("got_answer", temp.result)

func on_cancel():
	queue_free()
	
