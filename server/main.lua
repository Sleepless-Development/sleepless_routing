local config = require 'config'

local GLOBAL_BUCKET = 0
local HIDDEN_BUCKET = 1

local LOCKDOWN_MODES = {
    inactive = true,
    relaxed = true,
    strict = true,
    no_dummy = true,
    full = true,
}

local nextBucketId = 2

local buckets = {}
local bucketNames = {}
local routingPlayers = {}

local addPlayerToBucket

local function isLockdownMode(mode)
    return type(mode) == 'string' and LOCKDOWN_MODES[mode] == true
end

local function publishBucketState(playerState, bucket, previousBucket)
    if previousBucket ~= nil then
        playerState:set('oldBucket', previousBucket, true)
    end

    playerState:set('currentBucket', bucket, true)
    playerState:set('currentBucketName', bucketNames[bucket], true)
end

local function resolveBucketId(bucket)
    if type(bucket) == 'string' then
        if bucket == '' then return end
        return buckets[bucket]
    end

    bucket = tonumber(bucket)
    if bucket == nil or bucket < 0 then return end
    return bucket
end

local function applyBucketRules(bucketId, population, lockdown)
    if type(population) == 'boolean' then
        SetRoutingBucketPopulationEnabled(bucketId, population)
    end

    if lockdown ~= nil then
        SetRoutingBucketEntityLockdownMode(bucketId, lockdown)
    end
end

local function getPlayerIdFromPed(ped)
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if playerId and GetPlayerPed(playerId) == ped then
            return playerId
        end
    end
end

local function movePlayerEntities(playerId, bucket)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetEntityRoutingBucket(vehicle, bucket)

        local seats = GetVehicleMaxNumberOfPassengers(vehicle)
        for seat = -1, seats - 1 do
            local occupant = GetPedInVehicleSeat(vehicle, seat)
            if occupant ~= 0 and occupant ~= ped and DoesEntityExist(occupant) then
                local occupantId = getPlayerIdFromPed(occupant)
                if occupantId then
                    addPlayerToBucket(occupantId, bucket, true)
                else
                    SetEntityRoutingBucket(occupant, bucket)
                end
            end
        end
    end

    local objects = GetAllObjects()
    for i = 1, #objects do
        local object = objects[i]
        if DoesEntityExist(object) and GetEntityAttachedTo(object) == ped then
            SetEntityRoutingBucket(object, bucket)
        end
    end
end

---@param playerId number
---@return { currentBucket: number|nil, oldBucket: number|nil, bucket: number } | nil
local function getPlayerBucket(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    local player = Player(playerId)
    if not player or not player.state then return end

    return {
        currentBucket = player.state.currentBucket,
        oldBucket = player.state.oldBucket,
        bucket = GetPlayerRoutingBucket(playerId),
    }
end

---@param playerId number
---@param bucket number
---@param force? boolean
---@return boolean
function addPlayerToBucket(playerId, bucket, force)
    playerId = tonumber(playerId)
    bucket = tonumber(bucket)
    if not playerId or bucket == nil or bucket < 0 then return false end

    if routingPlayers[playerId] then
        return GetPlayerRoutingBucket(playerId) == bucket
    end

    local player = Player(playerId)
    if not player or not player.state then return false end

    local playerState = player.state
    local liveBucket = GetPlayerRoutingBucket(playerId)

    if liveBucket == bucket and not force then
        if playerState.currentBucket ~= bucket then
            local previousBucket = playerState.oldBucket
            if previousBucket == nil then
                previousBucket = liveBucket
            end

            publishBucketState(playerState, liveBucket, previousBucket)
        end

        return true
    end

    routingPlayers[playerId] = true

    playerState:set('oldBucket', liveBucket, true)
    SetPlayerRoutingBucket(playerId, bucket)
    movePlayerEntities(playerId, bucket)

    local applied = GetPlayerRoutingBucket(playerId)
    publishBucketState(playerState, applied)
    routingPlayers[playerId] = nil
    return applied == bucket
end

---@param playerId number
---@return boolean
local function routePlayerToHiddenBucket(playerId)
    return addPlayerToBucket(playerId, HIDDEN_BUCKET, true)
end

---@param playerId number
---@return boolean
local function routePlayerToGlobalBucket(playerId)
    return addPlayerToBucket(playerId, GLOBAL_BUCKET, true)
end

---@param name string
---@param population? boolean
---@param lockdown? string
---@return number | nil
local function createBucketId(name, population, lockdown)
    if type(name) ~= 'string' or name == '' then return end
    if lockdown ~= nil and not isLockdownMode(lockdown) then return end

    local existing = buckets[name]
    if existing then return existing end

    if type(population) ~= 'boolean' then
        population = false
    end

    local bucketId = nextBucketId
    nextBucketId += 1
    buckets[name] = bucketId
    bucketNames[bucketId] = name
    applyBucketRules(bucketId, population, lockdown)
    return bucketId
end

---@param name string
---@param population? boolean
---@param lockdown? string
---@return number | nil
local function requestBucketId(name, population, lockdown)
    if type(name) ~= 'string' or name == '' then return end
    if lockdown ~= nil and not isLockdownMode(lockdown) then return end
    return buckets[name] or createBucketId(name, population, lockdown)
end

---@param bucket number | string
---@param options { population?: boolean, lockdown?: string }
---@return boolean
local function setBucketOptions(bucket, options)
    if type(options) ~= 'table' then return false end

    local bucketId = resolveBucketId(bucket)
    if bucketId == nil then return false end

    local hasPopulation = type(options.population) == 'boolean'
    local hasLockdown = options.lockdown ~= nil
    if not hasPopulation and not hasLockdown then return false end
    if hasLockdown and not isLockdownMode(options.lockdown) then return false end

    local population = nil
    if hasPopulation then
        population = options.population
    end

    local lockdown = nil
    if hasLockdown then
        lockdown = options.lockdown
    end

    applyBucketRules(bucketId, population, lockdown)
    return true
end

---@param name string
---@return number | nil
local function getBucketId(name)
    if type(name) ~= 'string' then return end
    return buckets[name]
end

---@param bucketId number
---@return string | nil
local function getBucketName(bucketId)
    bucketId = tonumber(bucketId)
    if bucketId == nil then return end
    return bucketNames[bucketId]
end

---@param bucket number | string
---@return number[] | nil
local function getPlayersInBucket(bucket)
    local bucketId = resolveBucketId(bucket)
    if bucketId == nil then return end

    local players = GetPlayers()
    local occupants = {}
    local count = 0

    for i = 1, #players do
        local playerId = tonumber(players[i])
        if playerId and GetPlayerRoutingBucket(playerId) == bucketId then
            count += 1
            occupants[count] = playerId
        end
    end

    return occupants
end

---@param eventName string
---@param bucket number | string
---@return boolean
local function triggerClientEventForBucket(eventName, bucket, ...)
    if type(eventName) ~= 'string' or eventName == '' then return false end

    local playerIds = getPlayersInBucket(bucket)
    if not playerIds then return false end

    lib.triggerClientEvent(eventName, playerIds, ...)
    return true
end

local function clearBucketNameState(bucketId)
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        local player = playerId and Player(playerId)
        if player and player.state.currentBucket == bucketId then
            player.state:set('currentBucketName', nil, true)
        end
    end
end

---@param name string
---@return boolean
local function removeBucketId(name)
    if type(name) ~= 'string' then return false end

    local bucketId = buckets[name]
    if not bucketId then return false end

    buckets[name] = nil
    bucketNames[bucketId] = nil
    clearBucketNameState(bucketId)
    return true
end

---@param entityId number
---@param bucket number | string
---@return boolean
local function moveEntityToBucket(entityId, bucket)
    if not entityId or not DoesEntityExist(entityId) then return false end

    local bucketId = resolveBucketId(bucket)
    if bucketId == nil then return false end

    SetEntityRoutingBucket(entityId, bucketId)
    return GetEntityRoutingBucket(entityId) == bucketId
end

---@param entityId number
---@return boolean
local function moveEntityToGlobalBucket(entityId)
    return moveEntityToBucket(entityId, GLOBAL_BUCKET)
end

local function initPlayerBucket(playerId)
    playerId = tonumber(playerId)
    if not playerId or playerId <= 0 then return end

    local player = Player(playerId)
    if not player or not player.state then return end
    if player.state.currentBucket ~= nil then return end

    local liveBucket = GetPlayerRoutingBucket(playerId)
    publishBucketState(player.state, liveBucket, liveBucket)
end

local function initJoiningPlayer()
    local playerId = source

    SetTimeout(0, function()
        initPlayerBucket(playerId)
    end)
end

local function resetOnlinePlayers()
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        local player = playerId and Player(playerId)
        if player and player.state then
            SetPlayerRoutingBucket(playerId, GLOBAL_BUCKET)
            movePlayerEntities(playerId, GLOBAL_BUCKET)
            publishBucketState(player.state, GLOBAL_BUCKET, GLOBAL_BUCKET)
        end
    end
end

local function onResourceStart(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    resetOnlinePlayers()
end

local function onQbPlayerLoaded(player)
    local playerId = player and player.PlayerData and player.PlayerData.source
    if not playerId then return end
    initPlayerBucket(playerId)
end

local function onPlayerBucketChanged(playerId, bucket, oldBucket)
    playerId = tonumber(playerId)
    bucket = tonumber(bucket)
    oldBucket = tonumber(oldBucket)
    if not playerId or bucket == nil then return end

    local player = Player(playerId)
    if not player or not player.state then return end

    publishBucketState(player.state, bucket, oldBucket)
end

local function setRouteCommand(playerId, args)
    if playerId == 0 then return end

    local name = args[1]
    if not name or name == '' then
        routePlayerToGlobalBucket(playerId)
        return
    end

    local bucketId = requestBucketId(name, false)
    if not bucketId then return end

    addPlayerToBucket(playerId, bucketId, true)
end

SetRoutingBucketPopulationEnabled(HIDDEN_BUCKET, false)

AddEventHandler('onResourceStart', onResourceStart)
AddEventHandler('playerJoining', initJoiningPlayer)
AddEventHandler('ox:playerLoaded', initPlayerBucket)
AddEventHandler('esx:playerLoaded', initPlayerBucket)
AddEventHandler('QBCore:Server:PlayerLoaded', onQbPlayerLoaded)
AddEventHandler('onPlayerBucketChange', onPlayerBucketChanged)

exports('getPlayerBucket', getPlayerBucket)
exports('addPlayerToBucket', addPlayerToBucket)
exports('routePlayerToHiddenBucket', routePlayerToHiddenBucket)
exports('routePlayerToGlobalBucket', routePlayerToGlobalBucket)
exports('createBucketId', createBucketId)
exports('requestBucketId', requestBucketId)
exports('setBucketOptions', setBucketOptions)
exports('getBucketId', getBucketId)
exports('getBucketName', getBucketName)
exports('getPlayersInBucket', getPlayersInBucket)
exports('triggerClientEventForBucket', triggerClientEventForBucket)
exports('removeBucketId', removeBucketId)
exports('moveEntityToBucket', moveEntityToBucket)
exports('moveEntityToGlobalBucket', moveEntityToGlobalBucket)

if config.debug then
    RegisterCommand('setroute', setRouteCommand, true)
end
