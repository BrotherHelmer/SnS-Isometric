namespace SnsOneShard.Simulation.Core;

public readonly record struct WorkerId(Guid Value)
{
    public static WorkerId New() => new(Guid.NewGuid());

    public override string ToString() => Value.ToString("N");
}
