using SnsOneShard.Simulation.Resources;

namespace SnsOneShard.Simulation.Buildings;

public sealed record WoodcutterProductionStatus(
    ResourceType ResourceType,
    int ProductionAmount,
    int ProductionIntervalTicks,
    int TicksUntilNextProduction,
    int OutputAmount,
    int OutputCapacity,
    bool IsBlocked);
