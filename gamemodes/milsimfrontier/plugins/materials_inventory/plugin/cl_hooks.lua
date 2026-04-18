local cachedMaterials = {}

net.Receive("MFS.SyncMaterials", function()
    local amount = net.ReadUInt(8)
    local updated = {}

    for _ = 1, amount do
        local materialID = net.ReadString()
        local count = net.ReadUInt(16)
        updated[materialID] = count
    end

    cachedMaterials = updated
end)

hook.Add("HUDPaint", "MFS.MaterialHUD", function()
    if not MFS or not MFS.Materials then
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then
        return
    end

    local x = 24
    local y = ScrH() - 180

    draw.RoundedBox(6, x - 10, y - 8, 430, 156, Color(15, 18, 22, 160))
    draw.SimpleText("MATERIAL INVENTORY", "Trebuchet18", x, y, Color(235, 235, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local row = 0
    for _, materialID in ipairs(MFS.GetMaterialKeys()) do
        local matInfo = MFS.Materials[materialID]
        local count = cachedMaterials[materialID] or 0
        local color = (matInfo and matInfo.color) or Color(220, 220, 220)
        local name = (matInfo and matInfo.name) or materialID

        draw.SimpleText(string.format("%s: %d", name, count), "Trebuchet18", x, y + 24 + (row * 22), color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        row = row + 1
    end
end)
