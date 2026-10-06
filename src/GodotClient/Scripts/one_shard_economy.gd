extends RefCounted

## The Director: stall diagnosis from existing building status. No new economy.
## World-space icons and hover copy make watching villagers a diagnosis loop.

const Defs = preload("one_shard_defs.gd")

const KIND_OK := "working"
const KIND_WORKER := "waiting_worker"
const KIND_INPUT := "waiting_input"
const KIND_STORAGE := "storage_full"
const KIND_PATH := "no_path"
const KIND_RANGE := "no_resources"
const KIND_NIGHT := "closed"
const KIND_BUILD := "construction"

const ICON_WORKER := "WKR"
const ICON_INPUT := "IN"
const ICON_STORAGE := "FULL"
const ICON_PATH := "PATH"
const ICON_RANGE := "OUT"


static func diagnose(building: Dictionary, elapsed: float = 0.0) -> Dictionary:
	var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
	var status := String(building.get("status", ""))
	var lower := status.to_lower()
	var kind := KIND_OK
	if bool(building.get("construction", false)):
		kind = KIND_BUILD
	elif "closed for the night" in lower:
		kind = KIND_NIGHT
	elif "no road" in lower:
		kind = KIND_PATH
	elif "needs workers" in lower or "needs a trained soldier" in lower or "waiting for a free worker" in lower:
		kind = KIND_WORKER
	elif lower.begins_with("waiting for") or "waiting for wheat" in lower:
		kind = KIND_INPUT
	elif "storage full" in lower or "central storage full" in lower:
		kind = KIND_STORAGE
	elif "forest exhausted" in lower or lower.begins_with("depleted") or "no resources" in lower:
		kind = KIND_RANGE
	var last_delivery := float(building.get("last_delivery_elapsed", -1.0))
	var last_ago := -1.0
	if last_delivery >= 0.0:
		last_ago = maxf(0.0, elapsed - last_delivery)
	var stalled := kind in [KIND_WORKER, KIND_INPUT, KIND_STORAGE, KIND_PATH, KIND_RANGE]
	var line := player_line(kind, status)
	return {
		"kind": kind,
		"stalled": stalled,
		"icon": icon_for(kind),
		"title": Defs.building_name(type_name).to_upper(),
		"line": line,
		"status": status,
		"last_delivery_seconds": last_ago,
		"hover": hover_text(type_name, line, last_ago)
	}


static func icon_for(kind: String) -> String:
	match kind:
		KIND_WORKER:
			return ICON_WORKER
		KIND_INPUT:
			return ICON_INPUT
		KIND_STORAGE:
			return ICON_STORAGE
		KIND_PATH:
			return ICON_PATH
		KIND_RANGE:
			return ICON_RANGE
		_:
			return ""


static func player_line(kind: String, status: String) -> String:
	var trimmed := status.trim_suffix(".")
	match kind:
		KIND_WORKER:
			return "Waiting for worker"
		KIND_INPUT:
			var lower := status.to_lower()
			if "wood" in lower:
				return "Waiting for logs"
			if "wheat" in lower:
				return "Waiting for wheat"
			if trimmed.begins_with("Waiting for "):
				return trimmed
			return "Waiting for input"
		KIND_STORAGE:
			return "Output storage full"
		KIND_PATH:
			return "No path"
		KIND_RANGE:
			if "forest" in status.to_lower():
				return "No resources in range"
			return "No resources in range"
		KIND_NIGHT:
			return "Closed for the night"
		KIND_BUILD:
			return trimmed if trimmed != "" else "Building"
		_:
			return "Working normally" if trimmed == "" or trimmed in ["Active", "Ready", "Watching"] else trimmed


static func hover_text(type_name: String, line: String, last_delivery_seconds: float) -> String:
	var title := Defs.building_name(type_name).to_upper()
	var parts: Array[String] = [title, line]
	if last_delivery_seconds >= 0.0:
		parts.append("Last delivery: %d sec ago" % int(round(last_delivery_seconds)))
	else:
		parts.append("Last delivery: none yet")
	return "\n".join(parts)


static func is_stalled(building: Dictionary) -> bool:
	return bool(diagnose(building).get("stalled", false))
