using SnsOneShard.Simulation.Core;

namespace SnsOneShard.Simulation.Buildings;

public abstract class Building
{
    protected Building(BuildingId id, BuildingType type, TilePosition position, Footprint footprint)
    {
        Id = id;
        Type = type;
        Position = position;
        Footprint = footprint;
    }

    public BuildingId Id { get; }

    public BuildingType Type { get; }

    public TilePosition Position { get; }

    public Footprint Footprint { get; }

    public IEnumerable<TilePosition> OccupiedTiles
    {
        get
        {
            for (var y = 0; y < Footprint.Height; y++)
            {
                for (var x = 0; x < Footprint.Width; x++)
                {
                    yield return new TilePosition(Position.X + x, Position.Y + y);
                }
            }
        }
    }
}
