using SnsOneShard.Simulation.Core;

namespace SnsOneShard.Simulation.World;

public sealed class PathfindingResult
{
    private PathfindingResult(
        bool succeeded,
        IReadOnlyList<TilePosition> path,
        PathfindingFailureReason failureReason,
        string message)
    {
        Succeeded = succeeded;
        Path = path;
        FailureReason = failureReason;
        Message = message;
    }

    public bool Succeeded { get; }

    public IReadOnlyList<TilePosition> Path { get; }

    public PathfindingFailureReason FailureReason { get; }

    public string Message { get; }

    public static PathfindingResult Success(IReadOnlyList<TilePosition> path)
    {
        return new PathfindingResult(
            succeeded: true,
            path,
            PathfindingFailureReason.None,
            $"Path found with {path.Count} step(s).");
    }

    public static PathfindingResult Failure(PathfindingFailureReason reason, string message)
    {
        return new PathfindingResult(
            succeeded: false,
            Array.Empty<TilePosition>(),
            reason,
            message);
    }
}
