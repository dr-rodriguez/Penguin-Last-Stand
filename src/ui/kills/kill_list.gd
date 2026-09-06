class_name KillList
extends HBoxContainer

## Fills a container with one kill tally per enemy type, e.g. "Beavers: 12".
## The pause screen and the score screen both show the same readout, so it
## lives here once instead of twice, and a new enemy .tres turns up in both
## without either scene changing.
##
## This is never attached to a node — it is a shared helper, called as
## KillList.refresh(some_hbox_container).


## Replace whatever is in the container with a fresh tally per enemy type
static func refresh(container: HBoxContainer) -> void:
	# Clear out the previous tally. remove_child comes first because queue_free
	# only takes effect at the end of the frame, and the old labels would
	# otherwise still be sitting there beside the new ones.
	for old_entry: Node in container.get_children():
		container.remove_child(old_entry)
		old_entry.queue_free()

	for enemy_def: EnemyDef in Stats.enemy_list:
		# A divider between entries, but not in front of the first one
		if container.get_child_count() > 0:
			container.add_child(VSeparator.new())

		var label := Label.new()
		label.text = "%s: %d" % [enemy_def.plural, Stats.kills_of(enemy_def)]
		# Even share of the width, so two types or five all read the same
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(label)
