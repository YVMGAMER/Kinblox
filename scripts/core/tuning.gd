class_name Tuning
extends Resource
## Every gameplay tuning constant lives here. The values in
## assets/data/tuning.tres are the shipped ones; the reasoning behind each
## is documented in docs/DESIGN.md ("Tuning").

@export_group("Scoring")
## Points for clearing 0..4 lines at once, multiplied by level.
@export var line_points := PackedInt32Array([0, 100, 300, 500, 800])
## Applied to a quad that directly follows another quad.
@export var back_to_back_multiplier := 1.5
## Per consecutive line-clearing piece after the first, times level.
@export var combo_points := 50
@export var soft_drop_points := 1
@export var hard_drop_points := 2
@export var lines_per_level := 10

@export_group("Gravity")
## Level is compressed by this factor before the speed curve, because touch
## input cannot keep up with the steepest desktop curves.
@export var gravity_level_scale := 0.7
## Fastest gravity, in seconds per row.
@export var gravity_min_interval := 0.033
@export var soft_drop_interval := 0.035
@export var zen_gravity_interval := 1.1

@export_group("Locking")
@export var lock_delay := 0.5
## Move/rotate resets of the lock timer allowed per piece (reset to zero
## whenever the piece reaches a new lowest row).
@export var lock_reset_limit := 15
## Upward kicks allowed per piece; stops pieces from climbing walls forever.
@export var floor_kick_limit := 4

@export_group("Pieces")
@export var next_count := 3
@export var unlock_level_corner := 4
@export var unlock_level_trio := 6
@export var unlock_level_cross := 9
## Chance per bag that an unlocked original piece is shuffled in.
@export var chance_corner := 0.25
@export var chance_trio := 0.2
@export var chance_cross := 0.07
## Daily mode unlocks by pieces dealt instead of level so every player gets
## the same sequence: one "virtual level" per this many pieces.
@export var sequence_pieces_per_level := 25

@export_group("Color Chain")
@export var chain_min_group := 4
## A group must span cells from at least this many different pieces.
@export var chain_min_pieces := 2
@export var chain_cell_points := 10
@export var chain_multiplier_start := 2
@export var chain_multiplier_cap := 8

@export_group("Timing")
@export var ready_delay := 0.9
@export var line_clear_delay := 0.28
@export var chain_highlight_delay := 0.45
@export var zen_sweep_rows := 12
@export var zen_sweep_delay := 0.8


func unlock_level(type: int) -> int:
	match type:
		PieceDefs.Type.V:
			return unlock_level_corner
		PieceDefs.Type.I3:
			return unlock_level_trio
		PieceDefs.Type.X:
			return unlock_level_cross
	return 1


func custom_chance(type: int) -> float:
	match type:
		PieceDefs.Type.V:
			return chance_corner
		PieceDefs.Type.I3:
			return chance_trio
		PieceDefs.Type.X:
			return chance_cross
	return 0.0


## Multiplier for the n-th chain step (1-based). The line clear that starts a
## chain counts as x1, so the first chain step is x2.
func chain_multiplier(step: int) -> int:
	return mini(chain_multiplier_start + step - 1, chain_multiplier_cap)
