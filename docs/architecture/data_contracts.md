# Data Contracts

## Building Definition

Each building type should eventually be defined by data.

For now, hardcoded definitions are acceptable, but the structure should anticipate data-driven configuration.

## Warehouse

```json
{
  "building_id": "warehouse",
  "display_name": "Warehouse",
  "footprint": [2, 2],
  "storage_capacity": {
    "Wood": 100
  }
}
```

## Woodcutter

```json
{
  "building_id": "woodcutter",
  "display_name": "Woodcutter",
  "footprint": [2, 2],
  "produces": {
    "resource": "Wood",
    "amount": 1,
    "interval_seconds": 3
  },
  "output_capacity": {
    "Wood": 10
  }
}
```

## Worker

```json
{
  "worker_id": "carrier",
  "display_name": "Carrier",
  "carry_capacity": {
    "Wood": 5
  },
  "movement_speed_tiles_per_second": 2
}
```
