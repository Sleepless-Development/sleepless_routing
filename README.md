# sleepless_routing

Named routing buckets for FiveM. Put players in an instance without keeping your own bucket counter.

![](https://img.shields.io/github/downloads/Sleepless-Development/sleepless_routing/total?logo=github)
![](https://img.shields.io/github/downloads/Sleepless-Development/sleepless_routing/latest/total?logo=github)
![](https://img.shields.io/github/contributors/Sleepless-Development/sleepless_routing?logo=github)
![](https://img.shields.io/github/v/release/Sleepless-Development/sleepless_routing?logo=github)\
[![](https://badges.5metrics.dev/sleepless_routing/serverRank.svg?style=for-the-badge)](https://5metrics.dev/resource/sleepless_routing)
[![](https://badges.5metrics.dev/sleepless_routing/servers.svg?style=for-the-badge)](https://5metrics.dev/resource/sleepless_routing)
[![](https://badges.5metrics.dev/sleepless_routing/players.svg?style=for-the-badge)](https://5metrics.dev/resource/sleepless_routing)

## Features

- Named buckets, created once and reused by name
- Global world on bucket `0`, hidden bucket on `1`
- Replicated player state: `currentBucket`, `oldBucket`, `currentBucketName`
- The player's vehicle and attached objects move with them
- Population flag per named bucket
- Framework agnostic. No framework resource is required

## Dependencies

- [ox_lib](https://github.com/communityox/ox_lib)

## Installation

1. Download the resource.
2. Place the `sleepless_routing` folder in your resources directory. Keep the folder name.
3. Add it to `server.cfg` after `ox_lib`:

```cfg
ensure ox_lib
ensure sleepless_routing
```

## Documentation

https://sleeplessdevelopment.dev/docs/routing

## Download

[sleepless_routing.zip](https://github.com/Sleepless-Development/sleepless_routing/releases/latest/download/sleepless_routing.zip)

## Usage

```lua
local bucketId = exports.sleepless_routing:requestBucketId(('house_%s'):format(propertyId), false)
if not bucketId then return end

exports.sleepless_routing:addPlayerToBucket(source, bucketId, true)

-- back to the world
exports.sleepless_routing:routePlayerToGlobalBucket(source)
```

Bucket `0` is the global world. Bucket `1` is the hidden bucket. Named buckets start at `2`.

Other players in the same vehicle move with the player. A third argument on `requestBucketId` sets the entity lockdown mode (`inactive`, `relaxed`, `strict`, `no_dummy`, or `full`). `setBucketOptions` changes population or lockdown later. `moveEntityToBucket` places a server-side entity in a bucket id or a registered name. `getPlayersInBucket` lists who is there. `triggerClientEventForBucket(eventName, bucket, ...)` sends one client event to those players through `lib.triggerClientEvent`.

`currentBucket` updates when any script moves the player, including `qbx_core`'s bucket helper.

Restarting the resource sends every online player back to bucket `0`.

## Player state

These state bag fields are replicated:

| Field | Type | Meaning |
| --- | --- | --- |
| `currentBucket` | `number` | Bucket the player was moved into |
| `oldBucket` | `number` | Bucket they were in before the last move |
| `currentBucketName` | `string \| nil` | Name of the current bucket. `nil` for global and hidden |

```lua
local bucket = Player(source).state.currentBucket
local name = Player(source).state.currentBucketName
```

## Debug

`/setroute [name]` is registered only when `debug` is true in `config.lua`. It is ACE restricted (`command.setroute`). With no name, it returns the player to the global bucket. The release default is `false`.

## License

[GPL-3.0](LICENSE)
