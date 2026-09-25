namespace SnsOneShard.Simulation.World;

public enum PathfindingFailureReason
{
    None = 0,
    StartOutsideMap = 1,
    DestinationOutsideMap = 2,
    StartBlocked = 3,
    DestinationBlocked = 4,
    Unreachable = 5
}
