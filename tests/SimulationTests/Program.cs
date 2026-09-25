using SnsOneShard.Simulation.Buildings;
using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Persistence;
using SnsOneShard.Simulation.Resources;
using SnsOneShard.Simulation.Workers;
using SnsOneShard.Simulation.World;

var tests = new (string Name, Action Run)[]
{
    ("Inventory can add and report Wood", InventoryCanAddAndReportWood),
    ("Inventory can remove Wood", InventoryCanRemoveWood),
    ("Inventory rejects negative amounts", InventoryRejectsNegativeAmounts),
    ("Inventory rejects removing more than available", InventoryRejectsOverRemoval),
    ("Inventory respects capacity", InventoryRespectsCapacity),
    ("WorldState can store and query buildings", WorldStateCanStoreAndQueryBuildings),
    ("WorldState can store and query workers", WorldStateCanStoreAndQueryWorkers),
    ("WorldState can increment simulation tick", WorldStateCanIncrementSimulationTick),
    ("Woodcutter produces Wood over time", WoodcutterProducesWoodOverTime),
    ("Woodcutter respects output capacity", WoodcutterRespectsOutputCapacity),
    ("Woodcutter reports blocked production when full", WoodcutterReportsBlockedProductionWhenFull),
    ("Woodcutter resumes production after Wood is removed", WoodcutterResumesProductionAfterWoodIsRemoved),
    ("Placement command can place Warehouse", PlacementCommandCanPlaceWarehouse),
    ("Placement command can place Woodcutter", PlacementCommandCanPlaceWoodcutter),
    ("Placement command rejects outside map", PlacementCommandRejectsOutsideMap),
    ("Placement command rejects overlap", PlacementCommandRejectsOverlap),
    ("WorldState can spawn Carrier worker", WorldStateCanSpawnCarrierWorker),
    ("Worker can path to reachable tile", WorkerCanPathToReachableTile),
    ("Worker refuses unreachable destination", WorkerRefusesUnreachableDestination),
    ("Worker avoids blocked tiles", WorkerAvoidsBlockedTiles),
    ("Worker moves along path over simulation ticks", WorkerMovesAlongPathOverSimulationTicks),
    ("World tick produces Woodcutter output", WorldTickProducesWoodcutterOutput),
    ("Carrier collects Wood from Woodcutter", CarrierCollectsWoodFromWoodcutter),
    ("Carrier delivers Wood to Warehouse", CarrierDeliversWoodToWarehouse),
    ("Carrier repeats hauling loop", CarrierRepeatsHaulingLoop),
    ("Save load round trip preserves world state", SaveLoadRoundTripPreservesWorldState),
    ("Save load file round trip preserves world state", SaveLoadFileRoundTripPreservesWorldState),
    ("Save load resets active worker path to idle", SaveLoadResetsActiveWorkerPathToIdle)
};

var failed = 0;

foreach (var test in tests)
{
    try
    {
        test.Run();
        Console.WriteLine($"PASS {test.Name}");
    }
    catch (Exception ex)
    {
        failed++;
        Console.WriteLine($"FAIL {test.Name}");
        Console.WriteLine($"     {ex.GetType().Name}: {ex.Message}");
    }
}

Console.WriteLine();
Console.WriteLine(failed == 0
    ? $"All {tests.Length} simulation tests passed."
    : $"{failed} of {tests.Length} simulation tests failed.");

return failed == 0 ? 0 : 1;

static void InventoryCanAddAndReportWood()
{
    var inventory = new Inventory(capacity: 10);

    inventory.Add(ResourceType.Wood, 4);
    inventory.Add(ResourceType.Wood, 3);

    Assert.Equal(7, inventory.GetAmount(ResourceType.Wood));
    Assert.Equal(7, inventory.TotalAmount);
    Assert.Equal(3, inventory.AvailableCapacity);
}

static void InventoryCanRemoveWood()
{
    var inventory = new Inventory(capacity: 10);
    inventory.Add(ResourceType.Wood, 7);

    inventory.Remove(ResourceType.Wood, 2);

    Assert.Equal(5, inventory.GetAmount(ResourceType.Wood));
    Assert.Equal(5, inventory.TotalAmount);
}

static void InventoryRejectsNegativeAmounts()
{
    var inventory = new Inventory(capacity: 10);

    Assert.Throws<ArgumentOutOfRangeException>(() => inventory.Add(ResourceType.Wood, -1));
    Assert.Throws<ArgumentOutOfRangeException>(() => inventory.Remove(ResourceType.Wood, -1));
}

static void InventoryRejectsOverRemoval()
{
    var inventory = new Inventory(capacity: 10);
    inventory.Add(ResourceType.Wood, 2);

    Assert.False(inventory.CanRemove(ResourceType.Wood, 3));
    Assert.Throws<InvalidOperationException>(() => inventory.Remove(ResourceType.Wood, 3));
    Assert.Equal(2, inventory.GetAmount(ResourceType.Wood));
}

static void InventoryRespectsCapacity()
{
    var inventory = new Inventory(capacity: 5);
    inventory.Add(ResourceType.Wood, 5);

    Assert.False(inventory.CanAdd(ResourceType.Wood, 1));
    Assert.Throws<InvalidOperationException>(() => inventory.Add(ResourceType.Wood, 1));
    Assert.Equal(5, inventory.GetAmount(ResourceType.Wood));
}

static void WorldStateCanStoreAndQueryBuildings()
{
    var world = new WorldState();
    var warehouse = new Warehouse(
        new BuildingId(Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")),
        new TilePosition(2, 3),
        new Inventory(Warehouse.DefaultCapacity));

    world.AddBuilding(warehouse);

    Assert.Equal(1, world.Buildings.Count);
    Assert.True(world.TryGetBuilding(warehouse.Id, out var queried));
    Assert.Same(warehouse, queried);
    Assert.Equal(BuildingType.Warehouse, world.GetBuilding(warehouse.Id).Type);
    Assert.Equal(new Footprint(2, 2), world.GetBuilding(warehouse.Id).Footprint);
}

static void WorldStateCanStoreAndQueryWorkers()
{
    var world = new WorldState();
    var worker = new Worker(
        new WorkerId(Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")),
        new TilePosition(4, 5));

    world.AddWorker(worker);

    Assert.Equal(1, world.Workers.Count);
    Assert.True(world.TryGetWorker(worker.Id, out var queried));
    Assert.Same(worker, queried);
    Assert.Equal(WorkerState.Idle, world.GetWorker(worker.Id).State);
    Assert.Equal(new TilePosition(4, 5), world.GetWorker(worker.Id).Position);
}

static void WorldStateCanIncrementSimulationTick()
{
    var world = new WorldState();

    world.IncrementTick();
    world.IncrementTick();

    Assert.Equal(2, world.TickNumber);
}

static void WoodcutterProducesWoodOverTime()
{
    var woodcutter = CreateTestWoodcutter(outputCapacity: 10);

    woodcutter.TickProduction();
    woodcutter.TickProduction();

    Assert.Equal(0, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
    Assert.Equal(1, woodcutter.TicksUntilNextProduction);
    Assert.False(woodcutter.ProductionStatus.IsBlocked);

    woodcutter.TickProduction();

    Assert.Equal(1, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
    Assert.Equal(3, woodcutter.TicksUntilNextProduction);
    Assert.Equal(1, woodcutter.ProductionStatus.OutputAmount);
}

static void WoodcutterRespectsOutputCapacity()
{
    var woodcutter = CreateTestWoodcutter(outputCapacity: 2);

    TickProduction(woodcutter, ticks: 20);

    Assert.Equal(2, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
    Assert.True(woodcutter.IsProductionBlocked);
    Assert.True(woodcutter.ProductionStatus.IsBlocked);
    Assert.Equal(2, woodcutter.ProductionStatus.OutputCapacity);
}

static void WoodcutterReportsBlockedProductionWhenFull()
{
    var woodcutter = CreateTestWoodcutter(outputCapacity: 1);
    woodcutter.OutputInventory.Add(ResourceType.Wood, 1);

    TickProduction(woodcutter, ticks: 10);

    Assert.Equal(1, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
    Assert.True(woodcutter.IsProductionBlocked);
    Assert.Equal(3, woodcutter.TicksUntilNextProduction);
    Assert.Equal(ResourceType.Wood, woodcutter.ProductionStatus.ResourceType);
}

static void WoodcutterResumesProductionAfterWoodIsRemoved()
{
    var woodcutter = CreateTestWoodcutter(outputCapacity: 1);

    TickProduction(woodcutter, ticks: 3);
    Assert.Equal(1, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
    Assert.True(woodcutter.IsProductionBlocked);

    woodcutter.OutputInventory.Remove(ResourceType.Wood, 1);
    Assert.False(woodcutter.IsProductionBlocked);

    TickProduction(woodcutter, ticks: 2);
    Assert.Equal(0, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));

    woodcutter.TickProduction();
    Assert.Equal(1, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
}

static void PlacementCommandCanPlaceWarehouse()
{
    var world = new WorldState(mapWidth: 8, mapHeight: 8);

    var result = world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Warehouse,
        new TilePosition(1, 1)));

    Assert.True(result.Succeeded);
    Assert.NotNull(result.Building);
    Assert.True(result.Building is Warehouse);
    Assert.Equal(BuildingType.Warehouse, result.Building!.Type);
    Assert.Equal(new TilePosition(1, 1), result.Building.Position);
    Assert.Equal(new Footprint(2, 2), result.Building.Footprint);
    Assert.Equal(1, world.Buildings.Count);
    Assert.Same(result.Building, world.GetBuilding(result.Building.Id));
}

static void PlacementCommandCanPlaceWoodcutter()
{
    var world = new WorldState(mapWidth: 8, mapHeight: 8);

    var result = world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Woodcutter,
        new TilePosition(3, 4)));

    Assert.True(result.Succeeded);
    Assert.NotNull(result.Building);
    Assert.True(result.Building is Woodcutter);
    Assert.Equal(BuildingType.Woodcutter, result.Building!.Type);
    Assert.Equal(new TilePosition(3, 4), result.Building.Position);
    Assert.Equal(1, world.Buildings.Count);
}

static void PlacementCommandRejectsOutsideMap()
{
    var world = new WorldState(mapWidth: 4, mapHeight: 4);

    var result = world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Warehouse,
        new TilePosition(3, 3)));

    Assert.False(result.Succeeded);
    Assert.Equal(PlacementFailureReason.OutsideMap, result.FailureReason);
    Assert.Equal(0, world.Buildings.Count);
}

static void PlacementCommandRejectsOverlap()
{
    var world = new WorldState(mapWidth: 8, mapHeight: 8);

    var first = world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Warehouse,
        new TilePosition(2, 2)));
    var second = world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Woodcutter,
        new TilePosition(3, 3)));

    Assert.True(first.Succeeded);
    Assert.False(second.Succeeded);
    Assert.Equal(PlacementFailureReason.OverlapsExistingBuilding, second.FailureReason);
    Assert.Equal(1, world.Buildings.Count);
}

static void WorldStateCanSpawnCarrierWorker()
{
    var world = new WorldState(mapWidth: 6, mapHeight: 6);

    var worker = world.SpawnCarrierWorker(new TilePosition(1, 1));

    Assert.Equal(WorkerType.Carrier, worker.Type);
    Assert.Equal(WorkerState.Idle, worker.State);
    Assert.Equal(new TilePosition(1, 1), worker.Position);
    Assert.Equal(1, world.Workers.Count);
}

static void WorkerCanPathToReachableTile()
{
    var world = new WorldState(mapWidth: 6, mapHeight: 6);

    var result = world.FindPath(new TilePosition(0, 0), new TilePosition(3, 0));

    Assert.True(result.Succeeded);
    Assert.Equal(PathfindingFailureReason.None, result.FailureReason);
    Assert.Equal(3, result.Path.Count);
    Assert.Equal(new TilePosition(3, 0), result.Path[^1]);
}

static void WorkerRefusesUnreachableDestination()
{
    var world = new WorldState(mapWidth: 6, mapHeight: 6);
    world.PlaceBuilding(new PlaceBuildingCommand(BuildingType.Warehouse, new TilePosition(2, 0)));
    world.PlaceBuilding(new PlaceBuildingCommand(BuildingType.Warehouse, new TilePosition(2, 2)));
    world.PlaceBuilding(new PlaceBuildingCommand(BuildingType.Warehouse, new TilePosition(2, 4)));
    var worker = world.SpawnCarrierWorker(new TilePosition(0, 2));

    var result = world.MoveWorkerTo(worker.Id, new TilePosition(5, 2));

    Assert.False(result.Succeeded);
    Assert.Equal(PathfindingFailureReason.Unreachable, result.FailureReason);
    Assert.Equal(WorkerState.Blocked, worker.State);
    Assert.Equal(0, worker.CurrentPath.Count);
    Assert.Equal(new TilePosition(0, 2), worker.Position);
}

static void WorkerAvoidsBlockedTiles()
{
    var world = new WorldState(mapWidth: 8, mapHeight: 5);
    world.PlaceBuilding(new PlaceBuildingCommand(BuildingType.Warehouse, new TilePosition(2, 1)));

    var result = world.FindPath(new TilePosition(0, 1), new TilePosition(5, 1));

    Assert.True(result.Succeeded);
    Assert.True(result.Path.Count > 5);
    Assert.False(result.Path.Any(world.IsTileOccupied));
}

static void WorkerMovesAlongPathOverSimulationTicks()
{
    var world = new WorldState(mapWidth: 6, mapHeight: 6);
    var worker = world.SpawnCarrierWorker(new TilePosition(0, 0));

    var result = world.MoveWorkerTo(worker.Id, new TilePosition(3, 0));

    Assert.True(result.Succeeded);
    Assert.Equal(WorkerState.Moving, worker.State);
    Assert.Equal(3, worker.CurrentPath.Count);

    world.IncrementTick();
    Assert.Equal(new TilePosition(1, 0), worker.Position);
    Assert.Equal(WorkerState.Moving, worker.State);
    Assert.Equal(2, worker.CurrentPath.Count);

    world.IncrementTick();
    Assert.Equal(new TilePosition(2, 0), worker.Position);
    Assert.Equal(WorkerState.Moving, worker.State);
    Assert.Equal(1, worker.CurrentPath.Count);

    world.IncrementTick();
    Assert.Equal(new TilePosition(3, 0), worker.Position);
    Assert.Equal(WorkerState.Idle, worker.State);
    Assert.Equal(0, worker.CurrentPath.Count);
}

static void WorldTickProducesWoodcutterOutput()
{
    var world = new WorldState(mapWidth: 8, mapHeight: 8);
    var result = world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Woodcutter,
        new TilePosition(1, 1)));
    var woodcutter = (Woodcutter)result.Building!;

    RunTicks(world, ticks: 3);

    Assert.Equal(1, woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
}

static void CarrierCollectsWoodFromWoodcutter()
{
    var setup = CreateHaulingWorld();

    RunUntil(setup.World, () => setup.Worker.CarriedAmount > 0, maxTicks: 20);

    Assert.Equal(ResourceType.Wood, setup.Worker.CarriedResourceType);
    Assert.Equal(1, setup.Worker.CarriedAmount);
    Assert.Equal(WorkerState.MovingToDropoff, setup.Worker.State);
    Assert.Equal(0, setup.Woodcutter.OutputInventory.GetAmount(ResourceType.Wood));
}

static void CarrierDeliversWoodToWarehouse()
{
    var setup = CreateHaulingWorld();

    RunUntil(
        setup.World,
        () => setup.Warehouse.Inventory.GetAmount(ResourceType.Wood) >= 1,
        maxTicks: 60);

    Assert.Equal(1, setup.Warehouse.Inventory.GetAmount(ResourceType.Wood));
    Assert.Equal(0, setup.Worker.CarriedAmount);
    Assert.Equal(WorkerState.Idle, setup.Worker.State);
}

static void CarrierRepeatsHaulingLoop()
{
    var setup = CreateHaulingWorld();

    RunUntil(
        setup.World,
        () => setup.Warehouse.Inventory.GetAmount(ResourceType.Wood) >= 2,
        maxTicks: 120);

    Assert.True(setup.Warehouse.Inventory.GetAmount(ResourceType.Wood) >= 2);
    Assert.Equal(0, setup.Worker.CarriedAmount);
}

static void SaveLoadRoundTripPreservesWorldState()
{
    var setup = CreateHaulingWorld();
    RunUntil(
        setup.World,
        () => setup.Warehouse.Inventory.GetAmount(ResourceType.Wood) >= 1,
        maxTicks: 80);
    setup.Woodcutter.OutputInventory.Add(ResourceType.Wood, 2);
    var savedWoodcutterOutput = setup.Woodcutter.OutputInventory.GetAmount(ResourceType.Wood);

    var saveService = new WorldSaveService();
    var loaded = saveService.Deserialize(saveService.Serialize(setup.World));

    var loadedWarehouse = loaded.Buildings.OfType<Warehouse>().Single();
    var loadedWoodcutter = loaded.Buildings.OfType<Woodcutter>().Single();
    var loadedWorker = loaded.Workers.Single();

    Assert.Equal(setup.World.MapWidth, loaded.MapWidth);
    Assert.Equal(setup.World.MapHeight, loaded.MapHeight);
    Assert.Equal(setup.World.TickNumber, loaded.TickNumber);
    Assert.Equal(1, loadedWarehouse.Inventory.GetAmount(ResourceType.Wood));
    Assert.Equal(savedWoodcutterOutput, loadedWoodcutter.OutputInventory.GetAmount(ResourceType.Wood));
    Assert.Equal(setup.Worker.Position, loadedWorker.Position);
}

static void SaveLoadFileRoundTripPreservesWorldState()
{
    var setup = CreateHaulingWorld();
    RunUntil(
        setup.World,
        () => setup.Warehouse.Inventory.GetAmount(ResourceType.Wood) >= 1,
        maxTicks: 80);

    var savePath = Path.Combine(Path.GetTempPath(), $"sns-one-shard-save-{Guid.NewGuid():N}.json");
    var saveService = new WorldSaveService();

    try
    {
        saveService.SaveToFile(setup.World, savePath);
        var loaded = saveService.LoadFromFile(savePath);

        Assert.Equal(setup.World.TickNumber, loaded.TickNumber);
        Assert.Equal(2, loaded.Buildings.Count);
        Assert.Equal(1, loaded.Workers.Count);
        Assert.Equal(1, loaded.Buildings.OfType<Warehouse>().Single().Inventory.GetAmount(ResourceType.Wood));
    }
    finally
    {
        if (File.Exists(savePath))
        {
            File.Delete(savePath);
        }
    }
}

static void SaveLoadResetsActiveWorkerPathToIdle()
{
    var world = new WorldState(mapWidth: 8, mapHeight: 8);
    var worker = world.SpawnCarrierWorker(new TilePosition(0, 0));

    world.MoveWorkerTo(worker.Id, new TilePosition(3, 0));

    var saveService = new WorldSaveService();
    var loaded = saveService.Deserialize(saveService.Serialize(world));
    var loadedWorker = loaded.Workers.Single();

    Assert.Equal(worker.Position, loadedWorker.Position);
    Assert.Equal(WorkerState.Idle, loadedWorker.State);
    Assert.Equal(0, loadedWorker.CurrentPath.Count);
}

static Woodcutter CreateTestWoodcutter(int outputCapacity)
{
    return new Woodcutter(
        new BuildingId(Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc")),
        new TilePosition(6, 7),
        new Inventory(outputCapacity),
        productionIntervalTicks: 3,
        productionAmount: 1);
}

static (WorldState World, Woodcutter Woodcutter, Warehouse Warehouse, Worker Worker) CreateHaulingWorld()
{
    var world = new WorldState(mapWidth: 10, mapHeight: 6);
    var woodcutter = (Woodcutter)world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Woodcutter,
        new TilePosition(1, 1))).Building!;
    var warehouse = (Warehouse)world.PlaceBuilding(new PlaceBuildingCommand(
        BuildingType.Warehouse,
        new TilePosition(6, 1))).Building!;
    var worker = world.SpawnCarrierWorker(new TilePosition(0, 1));

    return (world, woodcutter, warehouse, worker);
}

static void RunTicks(WorldState world, int ticks)
{
    for (var i = 0; i < ticks; i++)
    {
        world.IncrementTick();
    }
}

static void RunUntil(WorldState world, Func<bool> condition, int maxTicks)
{
    for (var i = 0; i < maxTicks; i++)
    {
        if (condition())
        {
            return;
        }

        world.IncrementTick();
    }

    if (!condition())
    {
        throw new InvalidOperationException($"Condition was not met within {maxTicks} tick(s).");
    }
}

static void TickProduction(Woodcutter woodcutter, int ticks)
{
    for (var i = 0; i < ticks; i++)
    {
        woodcutter.TickProduction();
    }
}

static class Assert
{
    public static void Equal<T>(T expected, T actual)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
        {
            throw new InvalidOperationException($"Expected {expected}, got {actual}.");
        }
    }

    public static void Same<T>(T expected, T? actual)
        where T : class
    {
        if (!ReferenceEquals(expected, actual))
        {
            throw new InvalidOperationException("Expected both references to point to the same object.");
        }
    }

    public static void NotNull<T>(T? value)
        where T : class
    {
        if (value is null)
        {
            throw new InvalidOperationException("Expected a non-null value.");
        }
    }

    public static void True(bool value)
    {
        if (!value)
        {
            throw new InvalidOperationException("Expected true, got false.");
        }
    }

    public static void False(bool value)
    {
        if (value)
        {
            throw new InvalidOperationException("Expected false, got true.");
        }
    }

    public static void Throws<TException>(Action action)
        where TException : Exception
    {
        try
        {
            action();
        }
        catch (TException)
        {
            return;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException(
                $"Expected {typeof(TException).Name}, got {ex.GetType().Name}.");
        }

        throw new InvalidOperationException($"Expected {typeof(TException).Name}, but no exception was thrown.");
    }
}
