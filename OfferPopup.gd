extends PanelContainer
signal got_answer(answer)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$OfferBox/Copy.connect("pressed", self, "copy_offer")
	$OfferBox/Cancel.connect("pressed", self, "on_cancel")
	pass # Replace with function body.

func initialize(boot):
	boot.connect("incoming_bootstrap_offer", self, "display_offer")
	boot.connect("incoming_bootstrap_answered", self, "on_cancel")
	boot.peer.connection.create_offer()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
func copy_offer():
	OS.clipboard=$OfferBox/Offer.text

func display_offer(offer):
	$OfferBox/Offer.text = JSON.print(offer)

func on_cancel():
	queue_free()
	
