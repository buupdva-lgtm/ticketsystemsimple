local addOnName = "OasisRPG Tickets"

oasis_tickets = oasis_tickets or {}

oasis_tickets.Name = addOnName
oasis_tickets.Author = "Pacey"
oasis_tickets.Prefix = "oasis_tickets"

local function includeFile(path)
    if SERVER then
        AddCSLuaFile(path)
    end
    include(path)
end

includeFile("oasis_tickets/shared.lua")
includeFile("oasis_tickets/config.lua")
includeFile("oasis_tickets/language.lua")

if SERVER then
    includeFile("oasis_tickets/server/sv_storage.lua")
    includeFile("oasis_tickets/server/sv_ulx.lua")
    includeFile("oasis_tickets/server/sv_core.lua")
    includeFile("oasis_tickets/server/sv_admin.lua")
else
    includeFile("oasis_tickets/client/cl_vgui.lua")
    includeFile("oasis_tickets/client/cl_menu.lua")
    includeFile("oasis_tickets/client/cl_admin.lua")
    includeFile("oasis_tickets/client/cl_popup.lua")
end
