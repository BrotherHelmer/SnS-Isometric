using SnsOneShard.Simulation.Buildings;
using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Resources;
using SnsOneShard.Simulation.Workers;

namespace SnsOneShard.Simulation.Persistence;

public sealed class WorldSaveData
{
    public int Version { get; init; } = 1;

    public int MapWidth { get; init; }

    public int MapHeight { get; init; }

    public int TickNumber { get; init; }

    public List<BuildingSaveData> Buildings { get; init; } = new();

    public List<WorkerSaveData> Workers { get; init; } = new();
}

public sealed class BuildingSaveData
{
    public string Id { get; init; } = "";

    public BuildingType Type { get; init; }

    public TilePosition Position { get; init; }

    public int InventoryWood { get; init; }

    public int OutputWood { get; init; }

    public int TicksUntilNextProduction { get; init; }
}

public sealed class WorkerSaveData
{
    public string Id { get; init; } = "";

    public WorkerType Type { get; init; }

    public TilePosition Position { get; init; }

    public ResourceType? CarriedResourceType { get; init; }

    public int CarriedAmount { get; init; }

    public string? SourceBuildingId { get; init; }

    public string? DestinationBuildingId { get; init; }
}
