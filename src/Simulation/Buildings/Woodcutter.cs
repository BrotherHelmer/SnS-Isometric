using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Resources;

namespace SnsOneShard.Simulation.Buildings;

public sealed class Woodcutter : Building
{
    public const int DefaultOutputCapacity = 10;
    public const int DefaultProductionAmount = 1;
    public const int DefaultProductionIntervalTicks = 3;

    public Woodcutter(TilePosition position)
        : this(
            BuildingId.New(),
            position,
            new Inventory(DefaultOutputCapacity),
            DefaultProductionIntervalTicks,
            DefaultProductionAmount)
    {
    }

    public Woodcutter(BuildingId id, TilePosition position, Inventory outputInventory)
        : this(id, position, outputInventory, DefaultProductionIntervalTicks, DefaultProductionAmount)
    {
    }

    public Woodcutter(
        BuildingId id,
        TilePosition position,
        Inventory outputInventory,
        int productionIntervalTicks,
        int productionAmount)
        : base(id, BuildingType.Woodcutter, position, new Footprint(2, 2))
    {
        if (productionIntervalTicks <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(productionIntervalTicks),
                "Production interval must be positive.");
        }

        if (productionAmount <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(productionAmount),
                "Production amount must be positive.");
        }

        OutputInventory = outputInventory ?? throw new ArgumentNullException(nameof(outputInventory));
        ProductionIntervalTicks = productionIntervalTicks;
        ProductionAmount = productionAmount;
        TicksUntilNextProduction = productionIntervalTicks;
    }

    public Inventory OutputInventory { get; }

    public int ProductionIntervalTicks { get; }

    public int ProductionAmount { get; }

    public int TicksUntilNextProduction { get; private set; }

    public bool IsProductionBlocked => !OutputInventory.CanAdd(ResourceType.Wood, ProductionAmount);

    public WoodcutterProductionStatus ProductionStatus => new(
        ResourceType.Wood,
        ProductionAmount,
        ProductionIntervalTicks,
        TicksUntilNextProduction,
        OutputInventory.GetAmount(ResourceType.Wood),
        OutputInventory.Capacity,
        IsProductionBlocked);

    public void TickProduction()
    {
        if (IsProductionBlocked)
        {
            return;
        }

        TicksUntilNextProduction--;

        if (TicksUntilNextProduction > 0)
        {
            return;
        }

        OutputInventory.Add(ResourceType.Wood, ProductionAmount);
        TicksUntilNextProduction = ProductionIntervalTicks;
    }

    public void RestoreProductionTimer(int ticksUntilNextProduction)
    {
        if (ticksUntilNextProduction <= 0 || ticksUntilNextProduction > ProductionIntervalTicks)
        {
            throw new ArgumentOutOfRangeException(
                nameof(ticksUntilNextProduction),
                "Ticks until next production must be within the production interval.");
        }

        TicksUntilNextProduction = ticksUntilNextProduction;
    }
}
