using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Resources;

namespace SnsOneShard.Simulation.Workers;

public sealed class Worker
{
    public const int DefaultCarryCapacity = 5;

    private readonly List<TilePosition> _currentPath = new();

    public Worker(TilePosition position)
        : this(WorkerId.New(), WorkerType.Carrier, position)
    {
    }

    public Worker(WorkerId id, TilePosition position)
        : this(id, WorkerType.Carrier, position)
    {
    }

    public Worker(WorkerId id, WorkerType type, TilePosition position)
        : this(id, type, position, DefaultCarryCapacity)
    {
    }

    public Worker(WorkerId id, WorkerType type, TilePosition position, int carryCapacity)
    {
        if (carryCapacity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(carryCapacity), "Carry capacity must be positive.");
        }

        Id = id;
        Type = type;
        Position = position;
        State = WorkerState.Idle;
        CarryCapacity = carryCapacity;
    }

    public WorkerId Id { get; }

    public WorkerType Type { get; }

    public TilePosition Position { get; private set; }

    public WorkerState State { get; private set; }

    public IReadOnlyList<TilePosition> CurrentPath => _currentPath;

    public int CarryCapacity { get; }

    public ResourceType? CarriedResourceType { get; private set; }

    public int CarriedAmount { get; private set; }

    public BuildingId? CurrentTaskSourceBuildingId { get; private set; }

    public BuildingId? CurrentTaskDestinationBuildingId { get; private set; }

    public void MoveTo(TilePosition position)
    {
        Position = position;
    }

    public void SetState(WorkerState state)
    {
        State = state;
    }

    public void AssignPath(IEnumerable<TilePosition> path)
    {
        ArgumentNullException.ThrowIfNull(path);

        _currentPath.Clear();
        _currentPath.AddRange(path);
        State = _currentPath.Count == 0 ? WorkerState.Idle : WorkerState.Moving;
    }

    public void AssignHaulPickupPath(
        BuildingId sourceBuildingId,
        BuildingId destinationBuildingId,
        IEnumerable<TilePosition> path)
    {
        ArgumentNullException.ThrowIfNull(path);

        CurrentTaskSourceBuildingId = sourceBuildingId;
        CurrentTaskDestinationBuildingId = destinationBuildingId;
        _currentPath.Clear();
        _currentPath.AddRange(path);
        State = _currentPath.Count == 0 ? WorkerState.PickingUp : WorkerState.MovingToPickup;
    }

    public void AssignHaulDropoffPath(IEnumerable<TilePosition> path)
    {
        ArgumentNullException.ThrowIfNull(path);

        _currentPath.Clear();
        _currentPath.AddRange(path);
        State = _currentPath.Count == 0 ? WorkerState.DroppingOff : WorkerState.MovingToDropoff;
    }

    public void BlockMovement()
    {
        _currentPath.Clear();
        State = WorkerState.Blocked;
    }

    public void PickUp(ResourceType resourceType, int amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Pickup amount must be positive.");
        }

        if (amount > CarryCapacity)
        {
            throw new InvalidOperationException(
                $"Cannot carry {amount} {resourceType}; carry capacity is {CarryCapacity}.");
        }

        CarriedResourceType = resourceType;
        CarriedAmount = amount;
    }

    public void ClearCarriedResource()
    {
        CarriedResourceType = null;
        CarriedAmount = 0;
    }

    public void CompleteHaulTask()
    {
        CurrentTaskSourceBuildingId = null;
        CurrentTaskDestinationBuildingId = null;
        ClearCarriedResource();
        _currentPath.Clear();
        State = WorkerState.Idle;
    }

    public void RestoreAfterLoad(
        ResourceType? carriedResourceType,
        int carriedAmount,
        BuildingId? sourceBuildingId,
        BuildingId? destinationBuildingId)
    {
        _currentPath.Clear();
        CurrentTaskSourceBuildingId = sourceBuildingId;
        CurrentTaskDestinationBuildingId = destinationBuildingId;

        if (carriedResourceType is null || carriedAmount <= 0)
        {
            ClearCarriedResource();
        }
        else
        {
            PickUp(carriedResourceType.Value, carriedAmount);
        }

        State = WorkerState.Idle;
    }

    public void AdvanceMovementOneStep()
    {
        if (_currentPath.Count == 0)
        {
            if (State == WorkerState.Moving)
            {
                State = WorkerState.Idle;
            }

            return;
        }

        Position = _currentPath[0];
        _currentPath.RemoveAt(0);
        State = _currentPath.Count == 0 ? GetArrivedState(State) : State;
    }

    private static WorkerState GetArrivedState(WorkerState state)
    {
        return state switch
        {
            WorkerState.MovingToPickup => WorkerState.PickingUp,
            WorkerState.MovingToDropoff => WorkerState.DroppingOff,
            WorkerState.Moving => WorkerState.Idle,
            _ => state
        };
    }
}
