namespace SnsOneShard.Simulation.World;

public enum PlacementFailureReason
{
    None = 0,
    OutsideMap = 1,
    OverlapsExistingBuilding = 2,
    UnsupportedBuildingType = 3
}
