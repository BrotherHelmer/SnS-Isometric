namespace SnsOneShard.Simulation.Workers;

public enum WorkerState
{
    Idle = 1,
    MovingToPickup = 2,
    PickingUp = 3,
    MovingToDropoff = 4,
    DroppingOff = 5,
    Blocked = 6,
    Moving = 7
}
