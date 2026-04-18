hook.Add("PostDrawTranslucentRenderables", "MFS.DebugMaterialNodes", function()
    if not MFS then
        return
    end

    local player = LocalPlayer()
    if not IsValid(player) or not player:GetNWBool("MFSDebugMaterials", false) then
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
                draw.SimpleText(string.format("%s x%d", (matInfo and matInfo.name) or materialID, amount), "Trebuchet18", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end)
