local addon = oasis_tickets

local config = addon.Config
local addonUtil = addon.Util
local ulxHelper = addon.ULX

util.AddNetworkString("oasis_tickets_ulx_action")

local function isAdmin(ply)
    return addonUtil.HasAdminAccess(ply)
end

net.Receive("oasis_tickets_ulx_action", function(_, ply)
    if not isAdmin(ply) then
        return
    end

    local action = net.ReadString()
    local target = net.ReadEntity()
    if not addonUtil.IsValidPlayer(target) then
        return
    end

    local success, err = ulxHelper.Execute(action, ply, target)
    if not success then
        net.Start("oasis_tickets_notice")
        net.WriteString(err or addonUtil.Lang("ulx_missing"))
        net.Send(ply)
    end
end)
