using System.Text.Json;
using SnsOneShard.Simulation.Buildings;
using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Resources;
using SnsOneShard.Simulation.Workers;
using SnsOneShard.Simulation.World;

namespace SnsOneShard.Simulation.Persistence;

public sealed class WorldSaveService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true
    };

    public void SaveToFile(WorldState world, string path)
    {
        ArgumentNullException.ThrowIfNull(world);

        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        File.WriteAllText(path, Serialize(world));
    }

    public WorldState LoadFromFile(string path)
    {
        return Deserialize(File.ReadAllText(path));
    }

    public string Serialize(WorldState world)
    {
        ArgumentNullException.ThrowIfNull(world);
        return JsonSerializer.Serialize(ToSaveData(world), JsonOptions);
    }

    public WorldState Deserialize(string json)
    {
        var saveData = JsonSerializer.Deserialize<WorldSaveData>(json, JsonOptions)
            ?? throw new InvalidOperationException("Save file did not contain world data.");

        return FromSaveData(saveData);
    }

    public WorldSaveData ToSaveData(WorldState world)
    {
        ArgumentNullException.ThrowIfNull(world);

        return new WorldSaveData
        {
            MapWidth = world.MapWidth,
            MapHeight = world.MapHeight,
            TickNumber = world.TickNumber,
            Buildings = world.Buildings.Select(ToBuildingSaveData).ToList(),
            Workers = world.Workers.Select(ToWorkerSaveData).ToList()
        };
    }

    public WorldState FromSaveData(WorldSaveData saveData)
    {
        ArgumentNullException.ThrowIfNull(saveData);

        var world = new WorldState(saveData.MapWidth, saveData.MapHeight);
        world.RestoreTickNumber(saveData.TickNumber);

        foreach (var buildingData in saveData.Buildings)
        {
            world.AddBuilding(FromBuildingSaveData(buildingData));
        }

        foreach (var workerData in saveData.Workers)
        {
            world.AddWorker(FromWorkerSaveData(workerData));
        }

        return world;
    }

    private static BuildingSaveData ToBuildingSaveData(Building building)
    {
        return building switch
        {
            Warehouse warehouse => new BuildingSaveData
            {
                Id = warehouse.Id.Value.ToString(),
                Type = warehouse.Type,
                Position = warehouse.Position,
                InventoryWood = warehouse.Inventory.GetAmount(ResourceType.Wood)
            },
            Woodcutter woodcutter => new BuildingSaveData
            {
                Id = woodcutter.Id.Value.ToString(),
                Type = woodcutter.Type,
                Position = woodcutter.Position,
                OutputWood = woodcutter.OutputInventory.GetAmount(ResourceType.Wood),
                TicksUntilNextProduction = woodcutter.TicksUntilNextProduction
            },
            _ => throw new InvalidOperationException($"Unsupported building type: {building.Type}.")
        };
    }

    private static WorkerSaveData ToWorkerSaveData(Worker worker)
    {
        return new WorkerSaveData
        {
            Id = worker.Id.Value.ToString(),
            Type = worker.Type,
            Position = worker.Position,
            CarriedResourceType = worker.CarriedResourceType,
            CarriedAmount = worker.CarriedAmount,
            SourceBuildingId = worker.CurrentTaskSourceBuildingId?.Value.ToString(),
            DestinationBuildingId = worker.CurrentTaskDestinationBuildingId?.Value.ToString()
        };
    }

    private static Building FromBuildingSaveData(BuildingSaveData saveData)
    {
        var id = new BuildingId(ParseGuid(saveData.Id, nameof(saveData.Id)));

        return saveData.Type switch
        {
            BuildingType.Warehouse => CreateWarehouse(id, saveData),
            BuildingType.Woodcutter => CreateWoodcutter(id, saveData),
            _ => throw new InvalidOperationException($"Unsupported building type in save data: {saveData.Type}.")
        };
    }

    private static Warehouse CreateWarehouse(BuildingId id, BuildingSaveData saveData)
    {
        var inventory = new Inventory(Warehouse.DefaultCapacity);
        inventory.Add(ResourceType.Wood, saveData.InventoryWood);
        return new Warehouse(id, saveData.Position, inventory);
    }

    private static Woodcutter CreateWoodcutter(BuildingId id, BuildingSaveData saveData)
    {
        var outputInventory = new Inventory(Woodcutter.DefaultOutputCapacity);
        outputInventory.Add(ResourceType.Wood, saveData.OutputWood);
        var woodcutter = new Woodcutter(id, saveData.Position, outputInventory);
        woodcutter.RestoreProductionTimer(
            saveData.TicksUntilNextProduction == 0
                ? Woodcutter.DefaultProductionIntervalTicks
                : saveData.TicksUntilNextProduction);
        return woodcutter;
    }

    private static Worker FromWorkerSaveData(WorkerSaveData saveData)
    {
        var worker = new Worker(
            new WorkerId(ParseGuid(saveData.Id, nameof(saveData.Id))),
            saveData.Type,
            saveData.Position);
        worker.RestoreAfterLoad(
            saveData.CarriedResourceType,
            saveData.CarriedAmount,
            ParseOptionalBuildingId(saveData.SourceBuildingId),
            ParseOptionalBuildingId(saveData.DestinationBuildingId));
        return worker;
    }

    private static BuildingId? ParseOptionalBuildingId(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return new BuildingId(ParseGuid(value, nameof(value)));
    }

    private static Guid ParseGuid(string value, string fieldName)
    {
        return Guid.TryParse(value, out var parsed)
            ? parsed
            : throw new InvalidOperationException($"Invalid GUID in save field {fieldName}: {value}.");
    }
}
