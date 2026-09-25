class_name ProductionPresentationAdapterHost3D
extends Node

const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")

var adapter := Adapter.new()


func capture_world(simulation) -> Dictionary:
	return adapter.capture_world(simulation)


func capture_frame(simulation, render_lead_seconds := 0.0) -> Dictionary:
	return adapter.capture_frame(simulation, render_lead_seconds)


func worker_descriptor(worker: Dictionary, simulation, render_lead_seconds := 0.0) -> Dictionary:
	return adapter.worker_descriptor(worker, simulation, render_lead_seconds)
