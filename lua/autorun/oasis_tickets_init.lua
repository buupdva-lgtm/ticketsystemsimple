local addOnName = "OasisRPG Tickets"

oasis_tickets = oasis_tickets or {}

oasis_tickets.Name = addOnName
oasis_tickets.Author = "Pacey"
oasis_tickets.Prefix = "oasis_tickets"

local function includeShared(path)
    if SERVER then
        AddCSLuaFile(path)
    end
    include(path)
end

local function includeServer(path)
    if SERVER then
        include(path)
    end
end

local function includeClient(path)
    if SERVER then
        AddCSLuaFile(path)
        return
    end

    include(path)
end

includeShared("oasis_tickets/shared.lua")
includeShared("oasis_tickets/config.lua")
includeShared("oasis_tickets/language.lua")

local function includeServerFiles()
    if oasis_tickets.ServerLoaded then
        return
    end

    includeServer("oasis_tickets/server/sv_storage.lua")
    includeServer("oasis_tickets/server/sv_ulx.lua")
    includeServer("oasis_tickets/server/sv_core.lua")
    includeServer("oasis_tickets/server/sv_admin.lua")
    oasis_tickets.ServerLoaded = true
end

if SERVER then
    if ULib and ulx then
        includeServerFiles()
    else
        hook.Add("ULibLoaded", "oasis_tickets_load_after_ulib", function()
            includeServerFiles()
        end)

        hook.Add("InitPostEntity", "oasis_tickets_load_post_entity", function()
            includeServerFiles()
        end)
    end
end

includeClient("oasis_tickets/client/cl_vgui.lua")
includeClient("oasis_tickets/client/cl_menu.lua")
includeClient("oasis_tickets/client/cl_admin.lua")
includeClient("oasis_tickets/client/cl_popup.lua")
