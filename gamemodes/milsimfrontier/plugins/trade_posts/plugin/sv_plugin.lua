PLUGIN.zones = PLUGIN.zones or {}

local function IsCombatEntity(entity)
    return IsValid(entity) and (entity:IsPlayer() or entity:IsNPC() or entity:IsNextBot())
end

function PLUGIN:IsEnabled()
    if MFS.CVars and MFS.CVars.enabled and not MFS.CVars.enabled:GetBool() then
        return false
    end

    if MFS.CVars and MFS.CVars.tradePosts and not MFS.CVars.tradePosts:GetBool() then
        return false
    end

    return MFS.TradePosts.enabled
end

function PLUGIN:ClearZones()
    for _, zoneState in ipairs(self.zones) do
        if IsValid(zoneState.entity) then
            zoneState.entity:Remove()
        end
    end

    self.zones = {}
end

function PLUGIN:SpawnZone(zoneDefinition, index)
    if not zoneDefinition.position or not util.IsInWorld(zoneDefinition.position + Vector(0, 0, 8)) then
        return
    end

    local zoneEntity = ents.Create("mf_trade_zone")
    if not IsValid(zoneEntity) then
        return
    end

    zoneEntity:SetPos(zoneDefinition.position)
    zoneEntity:Spawn()
    zoneEntity:Activate()
    zoneEntity:SetZoneID(zoneDefinition.id or ("zone_" .. tostring(index)))
    zoneEntity:SetZoneRadius(zoneDefinition.radius or 420)
    zoneEntity:SetZoneActive(false)

    local offset = tonumber(zoneDefinition.activeOffset) or ((index - 1) * 60)
    zoneEntity:SetNextSwitchAt(CurTime() + offset)

    self.zones[#self.zones + 1] = {
        id = zoneEntity:GetZoneID(),
        entity = zoneEntity,
        activeDuration = zoneDefinition.activeDuration or MFS.TradePosts.activeDuration,
        cooldownDuration = zoneDefinition.cooldownDuration or MFS.TradePosts.cooldownDuration
    }
end

function PLUGIN:BuildZones()
    self:ClearZones()
    if not self:IsEnabled() then
        return
    end

    local mapZones = MFS.GetTradeZonesForMap(game.GetMap())
    for index, zoneDefinition in ipairs(mapZones) do
        self:SpawnZone(zoneDefinition, index)
    end
end

function PLUGIN:TickZones()
    if not self:IsEnabled() then
        return
    end

    local now = CurTime()
    for _, zoneState in ipairs(self.zones) do
        local zoneEntity = zoneState.entity
        if IsValid(zoneEntity) and now >= zoneEntity:GetNextSwitchAt() then
            local active = not zoneEntity:GetZoneActive()
            zoneEntity:SetZoneActive(active)
            zoneEntity:SetNextSwitchAt(now + (active and zoneState.activeDuration or zoneState.cooldownDuration))
        end
    end
end

function PLUGIN:IsPointInsideZone(position, zoneEntity, requireActive)
    if not IsValid(zoneEntity) then
        return false
    end

    if requireActive and not zoneEntity:GetZoneActive() then
        return false
    end

    local radius = zoneEntity:GetZoneRadius()
    return position:DistToSqr(zoneEntity:GetPos()) <= (radius * radius)
end

function PLUGIN:IsPointInActiveZone(position)
    for _, zoneState in ipairs(self.zones) do
        if self:IsPointInsideZone(position, zoneState.entity, true) then
            return true, zoneState.entity
        end
    end

    return false, nil
end

function PLUGIN:IsPointInAnyZone(position)
    for _, zoneState in ipairs(self.zones) do
        if self:IsPointInsideZone(position, zoneState.entity, false) then
            return true, zoneState.entity
        end
    end

    return false, nil
end

function PLUGIN:GetDebugCounts()
    local total, active = 0, 0
    for _, zoneState in ipairs(self.zones) do
        if IsValid(zoneState.entity) then
            total = total + 1
            if zoneState.entity:GetZoneActive() then
                active = active + 1
            end
        end
    end

    return total, active
end

local function ShouldBlockDamageByZone(plugin, entity)
    if not IsCombatEntity(entity) then
        return false
    end

    local pos = entity.WorldSpaceCenter and entity:WorldSpaceCenter() or entity:GetPos()
    local inside = plugin:IsPointInActiveZone(pos)
    return inside
end

function PLUGIN:EntityTakeDamage(target, damageInfo)
    if not self:IsEnabled() then
        return
    end

    local attacker = damageInfo:GetAttacker()
    local inflictor = damageInfo:GetInflictor()

    if ShouldBlockDamageByZone(self, target) or ShouldBlockDamageByZone(self, attacker) or ShouldBlockDamageByZone(self, inflictor) then
        damageInfo:SetDamage(0)
        return true
    end
end

function PLUGIN:PlayerShouldTakeDamage(player, attacker)
    if not self:IsEnabled() then
        return
    end

    if ShouldBlockDamageByZone(self, player) or ShouldBlockDamageByZone(self, attacker) then
        return false
    end
end

function PLUGIN:ClockworkInitialized()
    timer.Create("MFS.TradePosts.Tick", MFS.TradePosts.tickInterval, 0, function()
        if cwMFSTradePosts then
            cwMFSTradePosts:TickZones()
        end
    end)
end

function PLUGIN:ClockworkInitPostEntity()
    self:BuildZones()
end

function PLUGIN:ShutDown()
    self:ClearZones()
end

concommand.Add("mfs_trade_status", function(player)
    if not cwMFSTradePosts then
        return
    end

    local rows = {}
    rows[#rows + 1] = "[MilsimFrontier] Trade zones:\n"

    for _, zoneState in ipairs(cwMFSTradePosts.zones) do
        local zoneEntity = zoneState.entity
        if IsValid(zoneEntity) then
            rows[#rows + 1] = string.format(
                " - %s | %s | next switch: %.0fs\n",
                zoneEntity:GetZoneID(),
                zoneEntity:GetZoneActive() and "ACTIVE" or "COOLDOWN",
                math.max(0, zoneEntity:GetNextSwitchAt() - CurTime())
            )
        end
    end

    if IsValid(player) then
        for _, row in ipairs(rows) do
            player:PrintMessage(HUD_PRINTCONSOLE, row)
        end
    else
        for _, row in ipairs(rows) do
            print(string.Trim(row))
        end
    end
end)
