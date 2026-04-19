local function IsEnabled()
    if MFS.CVars and MFS.CVars.enabled and not MFS.CVars.enabled:GetBool() then
        return false
    end

    if MFS.CVars and MFS.CVars.allyBuff and not MFS.CVars.allyBuff:GetBool() then
        return false
    end

    return true
end

function PLUGIN:UpdateResistanceValues()
    if not IsEnabled() then
        for _, target in ipairs(player.GetAll()) do
            if IsValid(target) then
                target:SetNWFloat("MFSAllyResistance", 0)
            end
        end
        return
    end

    local radiusSqr = MFS.AllyBuff.radius * MFS.AllyBuff.radius

    for _, subject in ipairs(player.GetAll()) do
        if IsValid(subject) and subject:Alive() then
            local factionName = subject:GetFaction()
            if not factionName or factionName == "Outcasts" then
                subject:SetNWFloat("MFSAllyResistance", 0)
            else
                local allies = 0
                local origin = subject:GetPos()

                for _, other in ipairs(player.GetAll()) do
                    if other ~= subject and IsValid(other) and other:Alive() then
                        if other:GetFaction() == factionName and origin:DistToSqr(other:GetPos()) <= radiusSqr then
                            allies = allies + 1
                        end
                    end
                end

                local resistance = math.min(MFS.AllyBuff.maxResistance, allies * MFS.AllyBuff.resistancePerAlly)
                subject:SetNWFloat("MFSAllyResistance", resistance)
            end
        end
    end
end

function PLUGIN:ClockworkInitialized()
    timer.Create("MFS.AllySynergy.Tick", 1, 0, function()
        if cwMFSAlly then
            cwMFSAlly:UpdateResistanceValues()
        end
    end)
end

function PLUGIN:PlayerDisconnected(player)
    if IsValid(player) then
        player:SetNWFloat("MFSAllyResistance", 0)
    end
end

function PLUGIN:PlayerTakeDamage(player, inflictor, attacker, hitGroup, damageInfo)
    local resistance = math.Clamp(player:GetNWFloat("MFSAllyResistance", 0), 0, 0.9)
    if resistance > 0 then
        damageInfo:ScaleDamage(1 - resistance)
    end
end
