using SnsOneShard.Simulation.Buildings;
using SnsOneShard.Simulation.Core;
using SnsOneShard.Simulation.Resources;
using SnsOneShard.Simulation.Workers;

namespace SnsOneShard.Simulation.World;

public sealed class WorldState
{
    public const int DefaultMapWidth = 24;
    public const int DefaultMapHeight = 18;

    private readonly Dictionary<BuildingId, Building> _buildings = new();
    private readonly Dictionary<WorkerId, Worker> _workers = new();

    public WorldState()
        : this(DefaultMapWidth, DefaultMapHeight)
    {
    }

    public WorldState(int mapWidth, int mapHeight)
    {
        if (mapWidth <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(mapWidth), "Map width must be positive.");
        }

        if (mapHeight <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(mapHeight), "Map height must be positive.");
        }

        MapWidth = mapWidth;
        MapHeight = mapHeight;
    }

    public int MapWidth { get; }

    public int MapHeight { get; }

    public int TickNumber { get; private set; }

    public IReadOnlyCollection<Building> Buildings => _buildings.Values;

    public IReadOnlyCollection<Worker> Workers => _workers.Values;

    public void IncrementTick()
    {
        TickNumber++;

        TickProduction();

        foreach (var worker in _workers.Values)
        {
            worker.AdvanceMovementOneStep();
        }

        foreach (var worker in _workers.Values)
        {
            ProcessCarrierHauling(worker);
        }
    }

    public void RestoreTickNumber(int tickNumber)
    {
        if (tickNumber < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(tickNumber), "Tick number cannot be negative.");
        }

        TickNumber = tickNumber;
    }

    public void AddBuilding(Building building)
    {
        ArgumentNullException.ThrowIfNull(building);
        _buildings.Add(building.Id, building);
    }

    public PlaceBuildingResult PlaceBuilding(PlaceBuildingCommand command)
    {
        var footprint = GetFootprint(command.BuildingType);

        if (footprint is null)
        {
            return PlaceBuildingResult.Failure(
                PlacementFailureReason.UnsupportedBuildingType,
                $"Unsupported building type: {command.BuildingType}.");
        }

        if (!IsFootprintInsideMap(command.Position, footprint.Value))
        {
            return PlaceBuildingResult.Failure(
                PlacementFailureReason.OutsideMap,
                $"{command.BuildingType} does not fit inside the map at {command.Position}.");
        }

        if (DoesFootprintOverlapBuilding(command.Position, footprint.Value))
        {
            return PlaceBuildingResult.Failure(
                PlacementFailureReason.OverlapsExistingBuilding,
                $"{command.BuildingType} overlaps an existing building at {command.Position}.");
        }

        var building = CreateBuilding(command.BuildingType, command.Position);
        AddBuilding(building);
        return PlaceBuildingResult.Success(building);
    }

    public bool IsTileInsideMap(TilePosition tile)
    {
        return tile.X >= 0
            && tile.Y >= 0
            && tile.X < MapWidth
            && tile.Y < MapHeight;
    }

    public bool IsTileOccupied(TilePosition tile)
    {
        return _buildings.Values.Any(building => building.OccupiedTiles.Contains(tile));
    }

    public bool IsTileBlocked(TilePosition tile)
    {
        return !IsTileInsideMap(tile) || IsTileOccupied(tile);
    }

    public PathfindingResult FindPath(TilePosition start, TilePosition destination)
    {
        if (!IsTileInsideMap(start))
        {
            return PathfindingResult.Failure(
                PathfindingFailureReason.StartOutsideMap,
                $"Start tile {start} is outside the map.");
        }

        if (!IsTileInsideMap(destination))
        {
            return PathfindingResult.Failure(
                PathfindingFailureReason.DestinationOutsideMap,
                $"Destination tile {destination} is outside the map.");
        }

        if (IsTileOccupied(start))
        {
            return PathfindingResult.Failure(
                PathfindingFailureReason.StartBlocked,
                $"Start tile {start} is blocked.");
        }

        if (IsTileOccupied(destination))
        {
            return PathfindingResult.Failure(
                PathfindingFailureReason.DestinationBlocked,
                $"Destination tile {destination} is blocked.");
        }

        if (start == destination)
        {
            return PathfindingResult.Success(Array.Empty<TilePosition>());
        }

        var frontier = new PriorityQueue<TilePosition, int>();
        var cameFrom = new Dictionary<TilePosition, TilePosition>();
        var costSoFar = new Dictionary<TilePosition, int>
        {
            [start] = 0
        };

        frontier.Enqueue(start, 0);

        while (frontier.Count > 0)
        {
            var current = frontier.Dequeue();

            if (current == destination)
            {
                return PathfindingResult.Success(ReconstructPath(start, destination, cameFrom));
            }

            foreach (var next in GetNeighbors(current))
            {
                if (IsTileBlocked(next))
                {
                    continue;
                }

                var newCost = costSoFar[current] + 1;
                if (costSoFar.TryGetValue(next, out var existingCost) && newCost >= existingCost)
                {
                    continue;
                }

                costSoFar[next] = newCost;
                cameFrom[next] = current;
                var priority = newCost + GetManhattanDistance(next, destination);
                frontier.Enqueue(next, priority);
            }
        }

        return PathfindingResult.Failure(
            PathfindingFailureReason.Unreachable,
            $"Destination tile {destination} is unreachable from {start}.");
    }

    public bool TryGetBuilding(BuildingId id, out Building? building)
    {
        return _buildings.TryGetValue(id, out building);
    }

    public Building GetBuilding(BuildingId id)
    {
        return _buildings.TryGetValue(id, out var building)
            ? building
            : throw new KeyNotFoundException($"No building exists with id {id}.");
    }

    public void AddWorker(Worker worker)
    {
        ArgumentNullException.ThrowIfNull(worker);
        _workers.Add(worker.Id, worker);
    }

    public Worker SpawnCarrierWorker(TilePosition position)
    {
        if (IsTileBlocked(position))
        {
            throw new InvalidOperationException($"Cannot spawn Carrier worker at blocked tile {position}.");
        }

        var worker = new Worker(position);
        AddWorker(worker);
        return worker;
    }

    public PathfindingResult MoveWorkerTo(WorkerId workerId, TilePosition destination)
    {
        var worker = GetWorker(workerId);
        var pathResult = FindPath(worker.Position, destination);

        if (!pathResult.Succeeded)
        {
            worker.BlockMovement();
            return pathResult;
        }

        worker.AssignPath(pathResult.Path);
        return pathResult;
    }

    public bool TryGetWorker(WorkerId id, out Worker? worker)
    {
        return _workers.TryGetValue(id, out worker);
    }

    public Worker GetWorker(WorkerId id)
    {
        return _workers.TryGetValue(id, out var worker)
            ? worker
            : throw new KeyNotFoundException($"No worker exists with id {id}.");
    }

    private static Footprint? GetFootprint(BuildingType buildingType)
    {
        return buildingType switch
        {
            BuildingType.Warehouse => new Footprint(2, 2),
            BuildingType.Woodcutter => new Footprint(2, 2),
            _ => null
        };
    }

    private static Building CreateBuilding(BuildingType buildingType, TilePosition position)
    {
        return buildingType switch
        {
            BuildingType.Warehouse => new Warehouse(position),
            BuildingType.Woodcutter => new Woodcutter(position),
            _ => throw new InvalidOperationException($"Unsupported building type: {buildingType}.")
        };
    }

    private bool IsFootprintInsideMap(TilePosition position, Footprint footprint)
    {
        return position.X >= 0
            && position.Y >= 0
            && position.X + footprint.Width <= MapWidth
            && position.Y + footprint.Height <= MapHeight;
    }

    private bool DoesFootprintOverlapBuilding(TilePosition position, Footprint footprint)
    {
        for (var y = 0; y < footprint.Height; y++)
        {
            for (var x = 0; x < footprint.Width; x++)
            {
                if (IsTileOccupied(new TilePosition(position.X + x, position.Y + y)))
                {
                    return true;
                }
            }
        }

        return false;
    }

    private static IReadOnlyList<TilePosition> ReconstructPath(
        TilePosition start,
        TilePosition destination,
        IReadOnlyDictionary<TilePosition, TilePosition> cameFrom)
    {
        var path = new List<TilePosition>();
        var current = destination;

        while (current != start)
        {
            path.Add(current);
            current = cameFrom[current];
        }

        path.Reverse();
        return path;
    }

    private static int GetManhattanDistance(TilePosition first, TilePosition second)
    {
        return Math.Abs(first.X - second.X) + Math.Abs(first.Y - second.Y);
    }

    private static IEnumerable<TilePosition> GetNeighbors(TilePosition tile)
    {
        yield return new TilePosition(tile.X + 1, tile.Y);
        yield return new TilePosition(tile.X - 1, tile.Y);
        yield return new TilePosition(tile.X, tile.Y + 1);
        yield return new TilePosition(tile.X, tile.Y - 1);
    }

    private void TickProduction()
    {
        foreach (var woodcutter in _buildings.Values.OfType<Woodcutter>())
        {
            woodcutter.TickProduction();
        }
    }

    private void ProcessCarrierHauling(Worker worker)
    {
        if (worker.Type != WorkerType.Carrier)
        {
            return;
        }

        switch (worker.State)
        {
            case WorkerState.Idle:
                if (worker.CarriedAmount > 0)
                {
                    TryAssignDropoff(worker);
                    return;
                }

                TryAssignPickup(worker);
                return;

            case WorkerState.PickingUp:
                TryPickupAndAssignDropoff(worker);
                return;

            case WorkerState.DroppingOff:
                TryDeposit(worker);
                return;
        }
    }

    private bool TryAssignPickup(Worker worker)
    {
        foreach (var woodcutter in _buildings.Values.OfType<Woodcutter>())
        {
            if (woodcutter.OutputInventory.GetAmount(ResourceType.Wood) <= 0)
            {
                continue;
            }

            foreach (var warehouse in _buildings.Values.OfType<Warehouse>())
            {
                if (warehouse.Inventory.AvailableCapacity <= 0)
                {
                    continue;
                }

                var pathResult = FindPathToBuilding(worker.Position, woodcutter);
                if (!pathResult.Succeeded)
                {
                    continue;
                }

                worker.AssignHaulPickupPath(woodcutter.Id, warehouse.Id, pathResult.Path);
                return true;
            }
        }

        return false;
    }

    private bool TryPickupAndAssignDropoff(Worker worker)
    {
        if (worker.CurrentTaskSourceBuildingId is null
            || worker.CurrentTaskDestinationBuildingId is null
            || GetBuilding(worker.CurrentTaskSourceBuildingId.Value) is not Woodcutter woodcutter
            || GetBuilding(worker.CurrentTaskDestinationBuildingId.Value) is not Warehouse warehouse)
        {
            worker.BlockMovement();
            return false;
        }

        var availableWood = woodcutter.OutputInventory.GetAmount(ResourceType.Wood);
        var amountToCarry = Math.Min(worker.CarryCapacity, Math.Min(availableWood, warehouse.Inventory.AvailableCapacity));
        if (amountToCarry <= 0)
        {
            worker.CompleteHaulTask();
            return false;
        }

        var pathResult = FindPathToBuilding(worker.Position, warehouse);
        if (!pathResult.Succeeded)
        {
            worker.BlockMovement();
            return false;
        }

        woodcutter.OutputInventory.Remove(ResourceType.Wood, amountToCarry);
        worker.PickUp(ResourceType.Wood, amountToCarry);
        worker.AssignHaulDropoffPath(pathResult.Path);
        return true;
    }

    private bool TryAssignDropoff(Worker worker)
    {
        if (worker.CurrentTaskDestinationBuildingId is null
            || GetBuilding(worker.CurrentTaskDestinationBuildingId.Value) is not Warehouse warehouse)
        {
            worker.BlockMovement();
            return false;
        }

        var pathResult = FindPathToBuilding(worker.Position, warehouse);
        if (!pathResult.Succeeded)
        {
            worker.BlockMovement();
            return false;
        }

        worker.AssignHaulDropoffPath(pathResult.Path);
        return true;
    }

    private bool TryDeposit(Worker worker)
    {
        if (worker.CurrentTaskDestinationBuildingId is null
            || GetBuilding(worker.CurrentTaskDestinationBuildingId.Value) is not Warehouse warehouse
            || worker.CarriedResourceType != ResourceType.Wood
            || worker.CarriedAmount <= 0)
        {
            worker.BlockMovement();
            return false;
        }

        if (!warehouse.Inventory.CanAdd(ResourceType.Wood, worker.CarriedAmount))
        {
            worker.BlockMovement();
            return false;
        }

        warehouse.Inventory.Add(ResourceType.Wood, worker.CarriedAmount);
        worker.CompleteHaulTask();
        return true;
    }

    private PathfindingResult FindPathToBuilding(TilePosition start, Building building)
    {
        PathfindingResult? bestResult = null;

        foreach (var interactionTile in GetInteractionTiles(building))
        {
            var pathResult = FindPath(start, interactionTile);
            if (!pathResult.Succeeded)
            {
                continue;
            }

            if (bestResult is null || pathResult.Path.Count < bestResult.Path.Count)
            {
                bestResult = pathResult;
            }
        }

        return bestResult ?? PathfindingResult.Failure(
            PathfindingFailureReason.Unreachable,
            $"No interaction tile for {building.Type} is reachable from {start}.");
    }

    private IEnumerable<TilePosition> GetInteractionTiles(Building building)
    {
        var seen = new HashSet<TilePosition>();

        foreach (var occupiedTile in building.OccupiedTiles)
        {
            foreach (var neighbor in GetNeighbors(occupiedTile))
            {
                if (!IsTileInsideMap(neighbor) || IsTileOccupied(neighbor) || !seen.Add(neighbor))
                {
                    continue;
                }

                yield return neighbor;
            }
        }
    }
}
