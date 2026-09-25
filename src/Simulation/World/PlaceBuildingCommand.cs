using SnsOneShard.Simulation.Buildings;
using SnsOneShard.Simulation.Core;

namespace SnsOneShard.Simulation.World;

public sealed record PlaceBuildingCommand(BuildingType BuildingType, TilePosition Position);
