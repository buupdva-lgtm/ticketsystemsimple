local addon = oasis_tickets

addon.ULX = addon.ULX or {}

local ulxHelper = addon.ULX

local function registerPermissions()
    if not ULib or not ULib.ucl or not ULib.ucl.registerAccess then
        return
    end

    if ulxHelper.PermissionsRegistered then
        return
    end

    ULib.ucl.registerAccess("oasis_tickets.admin", "admin", "Access to OasisRPG tickets admin tools.", "OasisRPG Tickets")
    ulxHelper.PermissionsRegistered = true
end

hook.Add("ULibLoaded", "oasis_tickets_register_permissions", function()
    registerPermissions()
end)

if ULib and ULib.ucl then
    registerPermissions()
end

function ulxHelper.IsAvailable()
    return ulx and ulx.goto and ulx.bring and ulx.jailtp and ulx.return and ULib and ULib.ucl
end

function ulxHelper.HasPermission(ply, action)
    if not ulxHelper.IsAvailable() then
        return false
    end

    return ULib.ucl.query(ply, action)
end

function ulxHelper.Execute(action, caller, target)
    if not ulxHelper.IsAvailable() then
        return false, "ULX missing"
    end

    if not ulxHelper.HasPermission(caller, action) then
        return false, "permission denied"
    end

    local function safeCall(func)
        local success, err = pcall(func)
        if not success then
            return false, err
        end
        return true
    end

    if action == "ulx goto" then
        return safeCall(function()
            ulx.goto(caller, { target })
        end)
    end

    if action == "ulx bring" then
        return safeCall(function()
            ulx.bring(caller, { target })
        end)
    end

    if action == "ulx jailtp" then
        return safeCall(function()
            ulx.jailtp(caller, { target })
        end)
    end

    if action == "ulx return" then
        return safeCall(function()
            ulx.return(caller, { target })
        end)
    end

    return false, "invalid action"
end
