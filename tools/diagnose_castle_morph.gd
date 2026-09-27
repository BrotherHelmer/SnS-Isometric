extends SceneTree

# Diagnostic script to investigate castle morph failure in playtest.20
# Run with: godot --headless --script tools/diagnose_castle_morph.gd

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const PresentationAdapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")

func _init() -> void:
	print("\n=== CASTLE MORPH DIAGNOSTIC ===\n")
	
	var simulation := Simulation.new()
	simulation.initialize_new_game(Vector2i.ZERO)
	
	# Add a completed barracks
	var barracks_site := simulation.town_hall_position + Vector2i(6, 3)
	var barracks := simulation._add_completed_building(Defs.BUILDING_BARRACKS, barracks_site)
	barracks["connected"] = true
	barracks["completed"] = true
	barracks["construction"] = false
	simulation._rebuild_occupied_tiles()
	
	print("Step 1: Barracks created")
	print("  - Type: ", barracks.get("type"))
	print("  - Completed: ", barracks.get("completed"))
	print("  - Construction: ", barracks.get("construction"))
	print("  - Connected: ", barracks.get("connected"))
	
	# Check if _settlement_has_barracks would detect it
	var adapter := PresentationAdapter.new()
	var has_barracks_result := adapter._settlement_has_barracks(simulation)
	print("\nStep 2: _settlement_has_barracks() returned: ", has_barracks_result)
	
	# Check all buildings
	print("\nStep 3: All buildings in simulation:")
	for building in simulation.get_buildings():
		var btype := String(building.get("type", ""))
		var is_construction := bool(building.get("construction", false))
		var is_completed := bool(building.get("completed", false))
		print("  - ", btype, " (construction=", is_construction, ", completed=", is_completed, ")")
	
	# Get Town Hall descriptor
	var town_hall = null
	for building in simulation.get_buildings():
		if String(building.get("type", "")) == "TOWN_HALL":
			town_hall = building
			break
	
	if town_hall:
		print("\nStep 4: Creating Town Hall descriptor via PresentationAdapter")
		var descriptor := adapter.building_descriptor(town_hall, simulation)
		print("  - Original type: ", descriptor.get("type"))
		print("  - has_barracks flag: ", descriptor.get("has_barracks"))
		
		# Check asset paths
		print("\nStep 5: Asset Catalog paths")
		print("  - TOWN_HALL path: ", Catalog.building_path("TOWN_HALL"))
		print("  - CASTLE path: ", Catalog.building_path("CASTLE"))
		print("  - Paths are different: ", Catalog.building_path("TOWN_HALL") != Catalog.building_path("CASTLE"))
		
		# Check if files exist
		var castle_path := Catalog.building_path("CASTLE")
		var town_hall_path := Catalog.building_path("TOWN_HALL")
		print("\nStep 6: File existence")
		print("  - Castle file exists: ", ResourceLoader.exists(castle_path))
		print("  - Town Hall file exists: ", ResourceLoader.exists(town_hall_path))
		
	else:
		print("\nERROR: No Town Hall found!")
	
	print("\n=== DIAGNOSIS COMPLETE ===\n")
	quit()
