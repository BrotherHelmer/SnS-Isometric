
extends RefCounted

## Hotfix 6: exact per-section frame timers. Off unless the gate harness
## (or --frame-profile) enables it; then each section costs two ticks_usec.

static var enabled := false
static var current: Dictionary = {}
static var previous: Dictionary = {}


static func t0() -> int:
	return Time.get_ticks_usec() if enabled else 0


static func add(section: String, started: int) -> void:
	if started == 0:
		return
	current[section] = int(current.get(section, 0)) + Time.get_ticks_usec() - started


static func frame_begin() -> void:
	if not enabled:
		return
	previous = current
	current = {}
