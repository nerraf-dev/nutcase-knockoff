extends PanelContainer

@onready var cover = $cover
@onready var word_label = $WordLabel

func set_word(text: String):
    word_label.text = text

func reveal():
    var tween = create_tween()
    #  slide to the right
    tween.tween_property(cover, "position:x", size.x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    # fade out
    tween.parallel().tween_property(cover, "modulate:a", 0, 0.3)

    