---@meta

---@alias RoutingBucketLockdown 'inactive' | 'relaxed' | 'strict' | 'no_dummy' | 'full'

---@class BucketOptions
---@field population? boolean `SetRoutingBucketPopulationEnabled`
---@field lockdown? RoutingBucketLockdown `SetRoutingBucketEntityLockdownMode`

---@class PlayerBucketState
---@field currentBucket number | nil Replicated `currentBucket` state. `0` is the global world.
---@field oldBucket number | nil Previous replicated bucket.
---@field bucket number Live routing bucket from `GetPlayerRoutingBucket`.

exports.sleepless_routing = {}

--- `server`
--- Returns the player's replicated bucket state and their live routing bucket.
---@param playerId number
---@return PlayerBucketState | nil
function exports.sleepless_routing:getPlayerBucket(playerId) end

--- `server`
--- Moves a player, the vehicle they are in, the other players in that vehicle, and objects attached to their ped.
--- Replicates `oldBucket`, `currentBucket`, and `currentBucketName`.
---@param playerId number
---@param bucket number
---@param force? boolean Move again when the player is already in the bucket.
---@return boolean applied
function exports.sleepless_routing:addPlayerToBucket(playerId, bucket, force) end

--- `server`
--- Moves a player into the hidden bucket (`1`). Population in that bucket is disabled.
---@param playerId number
---@return boolean
function exports.sleepless_routing:routePlayerToHiddenBucket(playerId) end

--- `server`
--- Moves a player into the global bucket (`0`).
---@param playerId number
---@return boolean
function exports.sleepless_routing:routePlayerToGlobalBucket(playerId) end

--- `server`
--- Creates a named bucket, or returns the existing id when the name is already registered.
--- Population and lockdown are stored only on the first create. Omitted population defaults to `false`. Omitted lockdown leaves the bucket on FiveM's default, `inactive`.
---@param name string
---@param population? boolean
---@param lockdown? RoutingBucketLockdown
---@return number | nil bucketId
function exports.sleepless_routing:createBucketId(name, population, lockdown) end

--- `server`
--- Returns the bucket id for `name`, creating it when missing.
---@param name string
---@param population? boolean
---@param lockdown? RoutingBucketLockdown
---@return number | nil bucketId
function exports.sleepless_routing:requestBucketId(name, population, lockdown) end

--- `server`
--- Updates population, lockdown, or both on an existing bucket. Accepts a bucket id or a registered name.
---@param bucket number | string
---@param options BucketOptions
---@return boolean
function exports.sleepless_routing:setBucketOptions(bucket, options) end

--- `server`
--- Returns the bucket id for a name, without creating one.
---@param name string
---@return number | nil
function exports.sleepless_routing:getBucketId(name) end

--- `server`
--- Returns the name registered for a bucket id. Global and hidden buckets have no name.
---@param bucketId number
---@return string | nil
function exports.sleepless_routing:getBucketName(bucketId) end

--- `server`
--- Returns the server ids of players whose live routing bucket matches. Accepts a bucket id or a registered name.
---@param bucket number | string
---@return number[] | nil playerIds `nil` when the name is not registered or the id is invalid
function exports.sleepless_routing:getPlayersInBucket(bucket) end

--- `server`
--- Sends a client event to every player currently in the bucket. Wraps `lib.triggerClientEvent`.
--- An empty bucket still returns `true`. An unknown name or invalid id returns `false`.
---@param eventName string
---@param bucket number | string
---@return boolean
function exports.sleepless_routing:triggerClientEventForBucket(eventName, bucket, ...) end

--- `server`
--- Forgets a bucket name. Players left inside that numeric bucket stay there, and their `currentBucketName` is cleared.
---@param name string
---@return boolean
function exports.sleepless_routing:removeBucketId(name) end

--- `server`
--- Moves an entity into a bucket. `bucket` is an id, or the name passed to `requestBucketId`.
---@param entityId number
---@param bucket number | string
---@return boolean
function exports.sleepless_routing:moveEntityToBucket(entityId, bucket) end

--- `server`
--- Moves an entity into the global bucket (`0`).
---@param entityId number
---@return boolean
function exports.sleepless_routing:moveEntityToGlobalBucket(entityId) end
