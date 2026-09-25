using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Resources;

namespace SnsOneShard.Simulation.Buildings;

public sealed class Warehouse : Building
{
    public const int DefaultCapacity = 100;

    public Warehouse(TilePosition position)
        : this(BuildingId.New(), position, new Inventory(DefaultCapacity))
    {
    }

    public Warehouse(BuildingId id, TilePosition position, Inventory inventory)
        : base(id, BuildingType.Warehouse, position, new Footprint(2, 2))
    {
        Inventory = inventory ?? throw new ArgumentNullException(nameof(inventory));
    }

    public Inventory Inventory { get; }
}
