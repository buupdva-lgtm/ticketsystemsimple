local addon = oasis_tickets

addon.Storage = addon.Storage or {}

local storage = addon.Storage
local dataFile = "oasis_tickets/tickets.json"

local function ensureDataFolder()
    if not file.IsDir("oasis_tickets", "DATA") then
        file.CreateDir("oasis_tickets")
    end
end

function storage.Load()
    ensureDataFolder()

    if not file.Exists(dataFile, "DATA") then
        storage.Tickets = {}
        return
    end

    local raw = file.Read(dataFile, "DATA")
    if not raw or raw == "" then
        storage.Tickets = {}
        return
    end

    local decoded = util.JSONToTable(raw)
    storage.Tickets = decoded or {}
end

function storage.Save()
    ensureDataFolder()

    local payload = util.TableToJSON(storage.Tickets or {}, true)
    file.Write(dataFile, payload or "{}")
end

function storage.AddTicket(ticket)
    storage.Tickets = storage.Tickets or {}
    table.insert(storage.Tickets, ticket)
    storage.Save()
end

function storage.UpdateTicket(index, updates)
    if not storage.Tickets or not storage.Tickets[index] then
        return
    end

    for key, value in pairs(updates) do
        storage.Tickets[index][key] = value
    end

    storage.Save()
end

function storage.GetTickets()
    storage.Tickets = storage.Tickets or {}
    return storage.Tickets
end

function storage.GetTicketsForSteamID(steamId)
    local history = {}
    for _, ticket in ipairs(storage.GetTickets()) do
        if ticket.reporterSteamId == steamId or ticket.targetSteamId == steamId then
            table.insert(history, ticket)
        end
    end

    return history
end

hook.Add("Initialize", "oasis_tickets_load_storage", function()
    storage.Load()
end)
