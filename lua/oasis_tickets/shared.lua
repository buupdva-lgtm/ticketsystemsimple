local addon = oasis_tickets

addon.Util = addon.Util or {}
addon.Data = addon.Data or {}

local util = addon.Util

function util.ColorFromTable(colorTable)
    if not istable(colorTable) then
        return Color(255, 255, 255)
    end

    return Color(colorTable.r or 255, colorTable.g or 255, colorTable.b or 255, colorTable.a or 255)
end

function util.TableHasValue(values, value)
    for _, entry in ipairs(values) do
        if entry == value then
            return true
        end
    end

    return false
end

function util.IsValidPlayer(ply)
    return IsValid(ply) and ply:IsPlayer()
end

function util.HasAdminAccess(ply)
    if not util.IsValidPlayer(ply) then
        return false
    end

    local config = addon.Config
    if config and config.IsAdminGroup(ply:GetUserGroup()) then
        return true
    end

    if ULib and ULib.ucl and ULib.ucl.query then
        return ULib.ucl.query(ply, "oasis_tickets.admin")
    end

    return false
end

function util.SafeSteamID64(ply)
    if not util.IsValidPlayer(ply) then
        return ""
    end

    return ply:SteamID64() or ""
end

function util.GetTimestamp()
    return os.time()
end

function util.Lang(key, lang)
    local language = addon.Language
    if not language then
        return key
    end

    return language.Get(key, lang)
end
