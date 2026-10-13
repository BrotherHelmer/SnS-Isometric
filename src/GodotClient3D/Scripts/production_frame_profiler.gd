
extends RefCounted

## Hotfix 6: exact per-section frame timers. Off unless the gate harness
## (or --frame-profile) enables it; then each section costs two ticks_usec.

static var enabled := false
static var current: Dictionary = {}
static var previous: Dictionary = {}
## Whole-run totals (usec) and frame count, for the harness summary.
static var totals: Dictionary = {}
static var frames := 0


static func t0() -> int:
	return Time.get_ticks_usec() if enabled else 0


static func add(section: String, started: int) -> void:
	if started == 0:
		return
	current[section] = int(current.get(section, 0)) + Time.get_ticks_usec() - started


static func frame_begin() -> void:
	if not enabled:
		return
	for k in current:
		totals[k] = int(totals.get(k, 0)) + int(current[k])
	frames += 1
	previous = current
	current = {}
