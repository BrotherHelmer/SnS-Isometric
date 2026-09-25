namespace SnsOneShard.Simulation.Core;

public readonly record struct Footprint
{
    public Footprint(int width, int height)
    {
        if (width <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(width), "Footprint width must be positive.");
        }

        if (height <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(height), "Footprint height must be positive.");
        }

        Width = width;
        Height = height;
    }

    public int Width { get; }

    public int Height { get; }

    public static Footprint SingleTile { get; } = new(1, 1);
}
