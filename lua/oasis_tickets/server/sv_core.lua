local addon = oasis_tickets

local config = addon.Config
local storage = addon.Storage
local addonUtil = addon.Util

addon.Tickets = addon.Tickets or {}

local function debugPrint(message)
    if not config.Debug then
        return
    end

    MsgC(Color(84, 162, 255), "[OasisRPG Tickets] ", color_white, message .. "\n")
end

local function initPrint(message, color)
    MsgC(color or Color(84, 162, 255), "[OasisRPG Tickets] ", color_white, message .. "\n")
end

local function isAdmin(ply)
    return addonUtil.HasAdminAccess(ply)
end

local function buildTicket(payload)
    local now = addonUtil.GetTimestamp()
    return {
        reporterName = payload.reporterName,
        reporterSteamId = payload.reporterSteamId,
        targetName = payload.targetName,
        targetSteamId = payload.targetSteamId,
        category = payload.category,
        description = payload.description,
        priority = payload.priority,
        status = "open",
        createdAt = now,
        updatedAt = now,
        claimedBy = nil,
        claimedBySteamId = nil
    }
end

local function broadcastTickets()
    local recipients = {}
    for _, ply in ipairs(player.GetAll()) do
        if isAdmin(ply) then
            table.insert(recipients, ply)
        end
    end

    if #recipients == 0 then
        return
    end

    net.Start("oasis_tickets_admin_sync")
    net.WriteTable(storage.GetTickets())
    net.Send(recipients)
end

local rateLimit = {}
local function canSubmit(ply)
    local steamId = addonUtil.SafeSteamID64(ply)
    if steamId == "" then
        return false
    end

    local record = rateLimit[steamId] or { last = 0 }
    if CurTime() - record.last < 3 then
        return false
    end

    record.last = CurTime()
    rateLimit[steamId] = record
    return true
end

local function validateCategory(category)
    return addonUtil.TableHasValue(config.TicketCategories, category)
end

local function validatePriority(priority)
    for _, entry in ipairs(config.TicketPriorities) do
        if entry.id == priority then
            return true
        end
    end

    return false
end

util.AddNetworkString("oasis_tickets_submit")
util.AddNetworkString("oasis_tickets_notice")
util.AddNetworkString("oasis_tickets_admin_sync")
util.AddNetworkString("oasis_tickets_admin_request")
util.AddNetworkString("oasis_tickets_admin_action")
util.AddNetworkString("oasis_tickets_history_request")
util.AddNetworkString("oasis_tickets_history_response")
util.AddNetworkString("oasis_tickets_sound")

net.Receive("oasis_tickets_submit", function(_, ply)
    if not addonUtil.IsValidPlayer(ply) then
        return
    end

    if not canSubmit(ply) then
        net.Start("oasis_tickets_notice")
        net.WriteString(addonUtil.Lang("cooldown_notice"))
        net.Send(ply)
        return
    end

    local target = net.ReadEntity()
    local category = net.ReadString()
    local priority = net.ReadString()
    local description = net.ReadString()

    if not addonUtil.IsValidPlayer(target) or target == ply then
        net.Start("oasis_tickets_notice")
        net.WriteString(addonUtil.Lang("cannot_self_report"))
        net.Send(ply)
        return
    end

    if not validateCategory(category) then
        return
    end

    if not validatePriority(priority) then
        return
    end

    if not isstring(description) or #string.Trim(description) < config.MinimumDescriptionLength then
        net.Start("oasis_tickets_notice")
        net.WriteString(addonUtil.Lang("description_too_short"))
        net.Send(ply)
        return
    end

    local ticket = buildTicket({
        reporterName = ply:Nick(),
        reporterSteamId = addonUtil.SafeSteamID64(ply),
        targetName = target:Nick(),
        targetSteamId = addonUtil.SafeSteamID64(target),
        category = category,
        description = description,
        priority = priority
    })

    storage.AddTicket(ticket)
    broadcastTickets()

    net.Start("oasis_tickets_notice")
    net.WriteString(addonUtil.Lang("ticket_sent"))
    net.Send(ply)

    if config.Sounds.Enabled then
        net.Start("oasis_tickets_sound")
        net.WriteString(config.Sounds.NewTicket)
        net.Broadcast()
    end

    debugPrint("Ticket created by " .. ply:Nick())
end)

net.Receive("oasis_tickets_admin_request", function(_, ply)
    if not isAdmin(ply) then
        return
    end

    net.Start("oasis_tickets_admin_sync")
    net.WriteTable(storage.GetTickets())
    net.Send(ply)
end)

net.Receive("oasis_tickets_history_request", function(_, ply)
    if not isAdmin(ply) then
        return
    end

    local target = net.ReadEntity()
    if not addonUtil.IsValidPlayer(target) then
        return
    end

    net.Start("oasis_tickets_history_response")
    net.WriteEntity(target)
    net.WriteTable(storage.GetTicketsForSteamID(addonUtil.SafeSteamID64(target)))
    net.Send(ply)
end)

net.Receive("oasis_tickets_admin_action", function(_, ply)
    if not isAdmin(ply) then
        return
    end

    local index = net.ReadUInt(16)
    local action = net.ReadString()
    local tickets = storage.GetTickets()
    local ticket = tickets[index]
    if not ticket then
        return
    end

    if action == "claim" then
        ticket.status = "claimed"
        ticket.claimedBy = ply:Nick()
        ticket.claimedBySteamId = addonUtil.SafeSteamID64(ply)
        ticket.updatedAt = addonUtil.GetTimestamp()
        storage.UpdateTicket(index, ticket)

        if config.Sounds.Enabled then
            net.Start("oasis_tickets_sound")
            net.WriteString(config.Sounds.ClaimTicket)
            net.Broadcast()
        end
    elseif action == "close" then
        ticket.status = "closed"
        ticket.updatedAt = addonUtil.GetTimestamp()
        storage.UpdateTicket(index, ticket)
    end

    broadcastTickets()
end)

hook.Add("Initialize", "oasis_tickets_init_logs", function()
    initPrint("Initializing...")
    initPrint("Config loaded")
    if addon.ULX and addon.ULX.IsAvailable() then
        initPrint("ULX detected")
    else
        initPrint("ULX not detected (waiting for ULib/ULX)", Color(236, 90, 90))
    end
    initPrint("Language loaded (" .. (config.Language or "en") .. ")")
    initPrint("Ready")
end)

hook.Add("ULibLoaded", "oasis_tickets_ulx_loaded_log", function()
    initPrint("ULX detected")
end)
