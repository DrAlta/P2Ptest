extends PanelContainer
signal got_answer(answer)

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/OfferBox/Copy.connect("pressed", self, "copy_offer")
	$VBoxContainer/AnswerBox/Connect.connect("pressed", self, "process_answer")
	$VBoxContainer/AnswerBox/Cancel.connect("pressed", self, "on_cancel")
	pass # Replace with function body.



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
			emit_signal("got_answered", temp.result)

func on_cancel():
	queue_free()
	
