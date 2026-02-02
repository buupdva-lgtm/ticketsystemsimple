local addon = oasis_tickets

addon.Config = {
    Debug = false,
    Language = "de",
    AdminMenuKey = KEY_F8,
    PlayerMenuKey = KEY_F6,
    AdminUsergroups = {
        "superadmin",
        "admin",
        "moderator",
        "supporter"
    },
    MinimumDescriptionLength = 12,
    TicketCategories = {
        "Regelverstoß",
        "Frage",
        "Hilfe",
        "Bug",
        "Sonstiges"
    },
    TicketPriorities = {
        {
            id = "low",
            name = "Niedrig",
            color = { r = 96, g = 209, b = 130 }
        },
        {
            id = "medium",
            name = "Mittel",
            color = { r = 232, g = 180, b = 76 }
        },
        {
            id = "high",
            name = "Hoch",
            color = { r = 235, g = 88, b = 88 }
        }
    },
    AutoPriorityByCategory = {
        ["Regelverstoß"] = "high",
        ["Bug"] = "medium"
    },
    Sounds = {
        Enabled = true,
        Cooldown = 3,
        NewTicket = "buttons/button14.wav",
        ClaimTicket = "buttons/button15.wav"
    },
    Colors = {
        Background = { r = 20, g = 22, b = 28 },
        Panel = { r = 28, g = 31, b = 39 },
        Accent = { r = 84, g = 162, b = 255 },
        Text = { r = 229, g = 233, b = 240 },
        Muted = { r = 140, g = 146, b = 160 },
        Danger = { r = 236, g = 90, b = 90 }
    }
}

function addon.Config.IsAdminGroup(userGroup)
    if not isstring(userGroup) then
        return false
    end

    for _, group in ipairs(addon.Config.AdminUsergroups) do
        if group == userGroup then
            return true
        end
    end

    return false
end

function addon.Config.GetPriorityById(priorityId)
    for _, priority in ipairs(addon.Config.TicketPriorities) do
        if priority.id == priorityId then
            return priority
        end
    end

    return addon.Config.TicketPriorities[1]
end

function addon.Config.GetPriorityByCategory(category)
    local mapped = addon.Config.AutoPriorityByCategory[category]
    if not mapped then
        return addon.Config.TicketPriorities[1]
    end

    return addon.Config.GetPriorityById(mapped)
end
