local function ShouldDrawMaterials(player)
    return IsValid(player) and player:GetNWBool("MFSDebugMaterials", false)
end

local function ShouldDrawZones(player)
    return IsValid(player) and player:GetNWBool("MFSDebugZones", false)
end

local function ShouldDrawBuild(player)
    return IsValid(player) and player:GetNWBool("MFSDebugBuild", false)
end

local function DrawNodeOverlays()
    for _, node in ipairs(ents.FindByClass("mf_resource_node")) do
        if IsValid(node) then
            local pos = node:GetPos()
            local materialID = node:GetMaterialID()
            local amount = node:GetAmount()
            local matInfo = MFS.Materials[materialID]
            local color = (matInfo and matInfo.color) or Color(255, 255, 255)

            render.SetColorMaterial()
            render.DrawSphere(pos + Vector(0, 0, 18), 8, 10, 10, Color(color.r, color.g, color.b, 120))

            cam.Start3D2D(pos + Vector(0, 0, 24), Angle(0, EyeAngles().y - 90, 90), 0.12)
                draw.RoundedBox(4, -130, -20, 260, 40, Color(0, 0, 0, 180))
                draw.SimpleText(string.format("%s x%d", (matInfo and matInfo.name) or materialID, amount), "Trebuchet18", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end

local function DrawZoneOverlays()
    for _, zone in ipairs(ents.FindByClass("mf_trade_zone")) do
        if IsValid(zone) then
            local active = zone:GetZoneActive()
            local radius = zone:GetZoneRadius()
            local color = active and Color(70, 210, 130, 70) or Color(220, 150, 70, 45)
            local ringColor = active and Color(90, 240, 160, 120) or Color(235, 170, 95, 90)

            render.SetColorMaterial()
            render.DrawSphere(zone:GetPos() + Vector(0, 0, 12), radius, 24, 24, color)
            render.DrawWireframeSphere(zone:GetPos() + Vector(0, 0, 12), radius, 24, 24, ringColor, true)

            cam.Start3D2D(zone:GetPos() + Vector(0, 0, radius * 0.2), Angle(0, EyeAngles().y - 90, 90), 0.14)
                draw.RoundedBox(4, -160, -22, 320, 44, Color(0, 0, 0, 190))
                draw.SimpleText(
                    string.format("%s | %s", zone:GetZoneID(), active and "SAFE ACTIVE" or "Cooldown"),
                    "Trebuchet18",
                    0,
                    0,
                    active and Color(90, 240, 160) or Color(240, 190, 110),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            cam.End3D2D()
        end
    end
end

local function DrawBuildOverlays()
    for _, structure in ipairs(ents.FindByClass("mf_build_structure")) do
        if IsValid(structure) then
            local pos = structure:GetPos()
            local structureID = structure:GetStructureTypeID()
            local structureDef = MFS.GetStructureDef(structureID)
            local level = structure:GetStructureLevel()
            local hp = math.max(0, math.floor(structure:GetStructureHealth()))
            local hpMax = math.max(1, math.floor(structure:GetStructureMaxHealth()))
            local ownerFaction = structure:GetOwnerFaction()

            local ratio = hp / hpMax
            local statusColor = ratio > 0.66 and Color(110, 230, 120) or (ratio > 0.33 and Color(240, 210, 100) or Color(245, 120, 120))

            render.SetColorMaterial()
            render.DrawWireframeBox(
                pos,
                structure:GetAngles(),
                Vector(-20, -20, 0),
                Vector(20, 20, 72),
                statusColor,
                true
            )

            cam.Start3D2D(pos + Vector(0, 0, 78), Angle(0, EyeAngles().y - 90, 90), 0.1)
                draw.RoundedBox(4, -190, -34, 380, 68, Color(0, 0, 0, 190))
                draw.SimpleText(
                    string.format("%s L%d", (structureDef and structureDef.name) or structureID, level),
                    "Trebuchet18",
                    0,
                    -12,
                    Color(220, 220, 220),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
                draw.SimpleText(
                    string.format("HP %d/%d | %s", hp, hpMax, ownerFaction ~= "" and ownerFaction or "No faction"),
                    "Trebuchet18",
                    0,
                    14,
                    statusColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            cam.End3D2D()
        end
    end
end

hook.Add("PostDrawTranslucentRenderables", "MFS.DebugDrawOverlays", function()
    if not MFS then
        return
    end

    local player = LocalPlayer()
    if not IsValid(player) then
        return
    end

    if ShouldDrawMaterials(player) then
        DrawNodeOverlays()
    end

    if ShouldDrawZones(player) then
        DrawZoneOverlays()
    end

    if ShouldDrawBuild(player) then
        DrawBuildOverlays()
    end
end)
