using SnsOneShard.Simulation.Buildings;

namespace SnsOneShard.Simulation.World;

public sealed class PlaceBuildingResult
{
    private PlaceBuildingResult(
        bool succeeded,
        Building? building,
        PlacementFailureReason failureReason,
        string message)
    {
        Succeeded = succeeded;
        Building = building;
        FailureReason = failureReason;
        Message = message;
    }

    public bool Succeeded { get; }

    public Building? Building { get; }

    public PlacementFailureReason FailureReason { get; }

    public string Message { get; }

    public static PlaceBuildingResult Success(Building building)
    {
        return new PlaceBuildingResult(
            succeeded: true,
            building,
            PlacementFailureReason.None,
            $"{building.Type} placed.");
    }

    public static PlaceBuildingResult Failure(PlacementFailureReason reason, string message)
    {
        return new PlaceBuildingResult(
            succeeded: false,
            building: null,
            reason,
            message);
    }
}
