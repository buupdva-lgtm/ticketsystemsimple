local addon = oasis_tickets

addon.ULX = addon.ULX or {}

local ulxHelper = addon.ULX

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
