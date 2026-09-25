namespace SnsOneShard.Simulation.Resources;

public sealed class Inventory
{
    private readonly Dictionary<ResourceType, int> _amounts = new();

    public Inventory(int capacity)
    {
        if (capacity < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(capacity), "Inventory capacity cannot be negative.");
        }

        Capacity = capacity;
    }

    public int Capacity { get; }

    public int TotalAmount => _amounts.Values.Sum();

    public int AvailableCapacity => Capacity - TotalAmount;

    public int GetAmount(ResourceType resourceType) => _amounts.GetValueOrDefault(resourceType);

    public bool CanAdd(ResourceType resourceType, int amount)
    {
        ValidateAmount(amount);
        return amount <= AvailableCapacity;
    }

    public void Add(ResourceType resourceType, int amount)
    {
        ValidateAmount(amount);

        if (amount > AvailableCapacity)
        {
            throw new InvalidOperationException(
                $"Cannot add {amount} {resourceType}; only {AvailableCapacity} capacity remains.");
        }

        _amounts[resourceType] = GetAmount(resourceType) + amount;
    }

    public bool CanRemove(ResourceType resourceType, int amount)
    {
        ValidateAmount(amount);
        return amount <= GetAmount(resourceType);
    }

    public void Remove(ResourceType resourceType, int amount)
    {
        ValidateAmount(amount);

        var currentAmount = GetAmount(resourceType);
        if (amount > currentAmount)
        {
            throw new InvalidOperationException(
                $"Cannot remove {amount} {resourceType}; only {currentAmount} is available.");
        }

        var remainingAmount = currentAmount - amount;
        if (remainingAmount == 0)
        {
            _amounts.Remove(resourceType);
            return;
        }

        _amounts[resourceType] = remainingAmount;
    }

    public IReadOnlyDictionary<ResourceType, int> Snapshot()
    {
        return new Dictionary<ResourceType, int>(_amounts);
    }

    private static void ValidateAmount(int amount)
    {
        if (amount < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Inventory amount cannot be negative.");
        }
    }
}
