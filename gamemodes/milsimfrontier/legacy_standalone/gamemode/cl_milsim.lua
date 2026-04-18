local cachedMaterials = {}
local factionFrame = nil
local craftFrame = nil

surface.CreateFont("MFS.Header", {
    font = "Tahoma",
    size = 26,
    weight = 800
})

surface.CreateFont("MFS.Small", {
    font = "Tahoma",
    size = 17,
    weight = 650
})

local function SendFactionSelection(factionID, classID)
    net.Start(MFS.Net.submitFaction)
    net.WriteString(factionID)
    net.WriteString(classID or "")
    net.SendToServer()
end

local function BuildFactionPanel(parent, factionID, factionData)
    local panel = vgui.Create("DPanel", parent)
    panel:SetTall(120)
    panel:Dock(TOP)
    panel:DockMargin(0, 0, 0, 8)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 24, 28, 220))
        draw.SimpleText(factionData.name, "MFS.Header", 14, 10, Color(235, 235, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local defaultClass = MFS.DefaultClassByFaction[factionID]
    local defaultName = MFS.GetClassName(factionID, defaultClass)

    local info = vgui.Create("DLabel", panel)
    info:SetPos(16, 46)
    info:SetSize(420, 20)
    info:SetText("Default class: " .. defaultName)
    info:SetTextColor(Color(200, 205, 210))

    local choose = vgui.Create("DButton", panel)
    choose:SetText("Choose " .. factionData.name)
    choose:SetPos(16, 74)
    choose:SetSize(220, 34)
    choose.DoClick = function()
        SendFactionSelection(factionID, defaultClass)
        if IsValid(factionFrame) then
            factionFrame:Close()
        end
    end

    return panel
end

local function OpenFactionMenu(forced)
    if IsValid(factionFrame) then
        factionFrame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(560, 520)
    frame:Center()
    frame:SetTitle("Milsim Frontier - Choose Faction")
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    frame:SetDraggable(not forced)
    frame:ShowCloseButton(true)

    local hint = vgui.Create("DLabel", frame)
    hint:SetPos(14, 34)
    hint:SetSize(530, 22)
    hint:SetText("Pick your starting faction. You can reopen this with console command: mfs_choose_faction")
    hint:SetTextColor(Color(205, 205, 205))

    local list = vgui.Create("DScrollPanel", frame)
    list:SetPos(10, 60)
    list:SetSize(540, 450)

    for factionID, factionData in pairs(MFS.Factions) do
        BuildFactionPanel(list, factionID, factionData)
    end

    factionFrame = frame
end

local function BuildCostsText(costs)
    local rows = {}
    for materialID, amount in pairs(costs or {}) do
        local matName = (MFS.Materials[materialID] and MFS.Materials[materialID].name) or materialID
        table.insert(rows, string.format("%s x%d", matName, amount))
    end
    table.sort(rows)
    return table.concat(rows, ", ")
end

function MFS.OpenCraftMenu()
    if IsValid(craftFrame) then
        craftFrame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(760, 540)
    frame:Center()
    frame:SetTitle("Milsim Frontier - Crafting")
    frame:MakePopup()
    frame:SetDeleteOnClose(true)

    local invLabel = vgui.Create("DLabel", frame)
    invLabel:SetPos(16, 34)
    invLabel:SetSize(720, 22)
    invLabel:SetText("Inventory updates in real time.")
    invLabel:SetTextColor(Color(210, 210, 210))

    local function RefreshInventoryText()
        local parts = {}
        for _, materialID in ipairs(MFS.GetMaterialKeys()) do
            local matName = (MFS.Materials[materialID] and MFS.Materials[materialID].name) or materialID
            local amount = cachedMaterials[materialID] or 0
            table.insert(parts, string.format("%s: %d", matName, amount))
        end
        invLabel:SetText(table.concat(parts, " | "))
    end

    RefreshInventoryText()

    local list = vgui.Create("DScrollPanel", frame)
    list:SetPos(12, 64)
    list:SetSize(736, 462)

    for recipeID, recipe in pairs(MFS.Recipes) do
        local row = vgui.Create("DPanel", list)
        row:SetTall(110)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 8)
        row.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(22, 28, 34, 220))
            draw.SimpleText(recipe.name, "MFS.Header", 14, 8, Color(240, 240, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Cost: " .. BuildCostsText(recipe.costs), "MFS.Small", 14, 52, Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local craftButton = vgui.Create("DButton", row)
        craftButton:SetSize(170, 34)
        craftButton:SetPos(14, 72)
        craftButton:SetText("Craft")
        craftButton.DoClick = function()
            net.Start(MFS.Net.craftRequest)
            net.WriteString(recipeID)
            net.SendToServer()
        end
    end

    frame.Think = function()
        RefreshInventoryText()
    end

    craftFrame = frame
end

net.Receive(MFS.Net.openFactionMenu, function()
    local forced = net.ReadBool()
    OpenFactionMenu(forced)
end)

net.Receive(MFS.Net.syncMaterials, function()
    local count = net.ReadUInt(8)
    local updated = {}

    for _ = 1, count do
        local materialID = net.ReadString()
        local amount = net.ReadUInt(16)
        updated[materialID] = amount
    end

    cachedMaterials = updated
end)

net.Receive(MFS.Net.craftResult, function()
    local success = net.ReadBool()
    local message = net.ReadString()
    chat.AddText(success and Color(110, 220, 130) or Color(230, 90, 90), "[MFS] ", Color(240, 240, 240), message)
end)

concommand.Add("mfs_open_craft", function()
    MFS.OpenCraftMenu()
end)

hook.Add("HUDPaint", "MFS.HUDMaterials", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then
        return
    end

    local x = 24
    local y = ScrH() - 180
    draw.RoundedBox(6, x - 10, y - 8, 420, 156, Color(15, 18, 22, 160))

    local factionID = ply:GetNWString("MFSFaction", "")
    local classID = ply:GetNWString("MFSClass", "")
    draw.SimpleText("Faction: " .. MFS.GetFactionName(factionID), "MFS.Small", x, y, Color(235, 235, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Class: " .. MFS.GetClassName(factionID, classID), "MFS.Small", x, y + 22, Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local row = 0
    for _, materialID in ipairs(MFS.GetMaterialKeys()) do
        local matInfo = MFS.Materials[materialID]
        local amount = cachedMaterials[materialID] or 0
        local color = matInfo and matInfo.color or Color(220, 220, 220)
        local name = (matInfo and matInfo.name) or materialID
        draw.SimpleText(string.format("%s: %d", name, amount), "MFS.Small", x, y + 48 + (row * 20), color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        row = row + 1
    end
end)

hook.Add("PostDrawTranslucentRenderables", "MFS.DebugMaterialNodes", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNWBool("MFSDebugMaterials", false) then
        return
    end

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
                draw.SimpleText(string.format("%s x%d", (matInfo and matInfo.name) or materialID, amount), "MFS.Small", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end)
