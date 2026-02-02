local addon = oasis_tickets

local vguiLib = addon.VGUI
local config = addon.Config
local util = addon.Util

addon.AdminTickets = addon.AdminTickets or {}

local function buildFilterOptions(values)
    local options = { "All" }
    for _, value in ipairs(values) do
        table.insert(options, value)
    end
    return options
end

local function formatTimestamp(timestamp)
    return os.date("%d.%m.%Y %H:%M", timestamp or 0)
end

local function resolvePriorityName(priorityId)
    local entry = config.GetPriorityById(priorityId)
    return entry and entry.name or priorityId
end

local function applyFilters(ticket, filters)
    if filters.status ~= "All" and ticket.status ~= filters.status then
        return false
    end
    if filters.category ~= "All" and ticket.category ~= filters.category then
        return false
    end
    if filters.priority ~= "All" and ticket.priority ~= filters.priority then
        return false
    end
    return true
end

local function openAdminMenu(skipRequest)
    if IsValid(addon.AdminMenu) then
        addon.AdminMenu:Remove()
    end

    local frame = vguiLib.CreateFrame(util.Lang("title_admin_menu"), 720, 560)
    addon.AdminMenu = frame

    local layout = vgui.Create("DPanel", frame)
    layout:Dock(FILL)
    layout:DockMargin(20, 50, 20, 20)
    function layout:Paint() end

    local filterRow = vgui.Create("DPanel", layout)
    filterRow:Dock(TOP)
    filterRow:SetTall(42)
    function filterRow:Paint() end

    local statusOptions = buildFilterOptions({ "open", "claimed", "closed" })
    local statusDropdown = vguiLib.CreateDropdown(filterRow, statusOptions, nil)
    statusDropdown:Dock(LEFT)
    statusDropdown:SetWide(150)
    statusDropdown:SetSelected("All")

    local categories = buildFilterOptions(config.TicketCategories)
    local categoryDropdown = vguiLib.CreateDropdown(filterRow, categories, nil)
    categoryDropdown:Dock(LEFT)
    categoryDropdown:SetWide(150)
    categoryDropdown:DockMargin(8, 0, 0, 0)
    categoryDropdown:SetSelected("All")

    local priorityIds = {}
    for _, priority in ipairs(config.TicketPriorities) do
        table.insert(priorityIds, priority.id)
    end
    local priorityOptions = buildFilterOptions(priorityIds)
    local priorityDropdown = vguiLib.CreateDropdown(filterRow, priorityOptions, nil)
    priorityDropdown:Dock(LEFT)
    priorityDropdown:SetWide(150)
    priorityDropdown:DockMargin(8, 0, 0, 0)
    priorityDropdown:SetSelected("All")

    local listPanel = vguiLib.CreateScrollPanel(layout)
    listPanel:Dock(FILL)
    listPanel:DockMargin(0, 12, 0, 0)

    local function rebuildList()
        listPanel:Clear()
        local filters = {
            status = statusDropdown.Selected or "All",
            category = categoryDropdown.Selected or "All",
            priority = priorityDropdown.Selected or "All"
        }

        if #addon.AdminTickets == 0 then
            local empty = vguiLib.CreateLabel(listPanel, util.Lang("no_tickets"), "oasis_tickets_text")
            empty:Dock(TOP)
            empty:DockMargin(8, 8, 8, 0)
            return
        end

        for index, ticket in ipairs(addon.AdminTickets) do
            if not applyFilters(ticket, filters) then
                continue
            end

            local card = vgui.Create("DPanel", listPanel)
            card:SetTall(150)
            card:Dock(TOP)
            card:DockMargin(0, 0, 0, 10)
            function card:Paint(w, h)
                surface.SetDrawColor(util.ColorFromTable(config.Colors.Panel))
                surface.DrawRect(0, 0, w, h)
            end

            local title = vguiLib.CreateLabel(card, ticket.targetName .. " → " .. ticket.reporterName, "oasis_tickets_text")
            title:Dock(TOP)
            title:DockMargin(12, 8, 12, 0)

            local meta = vguiLib.CreateLabel(card, string.format("%s | %s | %s", ticket.category, resolvePriorityName(ticket.priority), formatTimestamp(ticket.createdAt)), "oasis_tickets_small")
            meta:SetTextColor(util.ColorFromTable(config.Colors.Muted))
            meta:Dock(TOP)
            meta:DockMargin(12, 4, 12, 0)

            local desc = vguiLib.CreateLabel(card, ticket.description, "oasis_tickets_small")
            desc:SetWrap(true)
            desc:SetAutoStretchVertical(true)
            desc:Dock(TOP)
            desc:DockMargin(12, 8, 12, 0)

            local actions = vgui.Create("DPanel", card)
            actions:Dock(BOTTOM)
            actions:SetTall(36)
            actions:DockMargin(12, 6, 12, 8)
            function actions:Paint() end

            local claim = vguiLib.CreateButton(actions, util.Lang("ticket_claim"), function()
                net.Start("oasis_tickets_admin_action")
                net.WriteUInt(index, 16)
                net.WriteString("claim")
                net.SendToServer()
            end)
            claim:Dock(LEFT)
            claim:SetWide(100)

            local closeBtn = vguiLib.CreateButton(actions, util.Lang("ticket_close"), function()
                net.Start("oasis_tickets_admin_action")
                net.WriteUInt(index, 16)
                net.WriteString("close")
                net.SendToServer()
            end)
            closeBtn:Dock(LEFT)
            closeBtn:SetWide(100)
            closeBtn:DockMargin(8, 0, 0, 0)

            local historyBtn = vguiLib.CreateButton(actions, util.Lang("ticket_history"), function()
                local target = player.GetBySteamID64(ticket.targetSteamId)
                if not IsValid(target) then
                    return
                end

                net.Start("oasis_tickets_history_request")
                net.WriteEntity(target)
                net.SendToServer()
            end)
            historyBtn:Dock(RIGHT)
            historyBtn:SetWide(140)
        end
    end

    statusDropdown:SetOnSelect(function(value)
        statusDropdown:SetSelected(value)
        rebuildList()
    end)

    categoryDropdown:SetOnSelect(function(value)
        categoryDropdown:SetSelected(value)
        rebuildList()
    end)

    priorityDropdown:SetOnSelect(function(value)
        priorityDropdown:SetSelected(value)
        rebuildList()
    end)

    rebuildList()

    if not skipRequest then
        net.Start("oasis_tickets_admin_request")
        net.SendToServer()
    end
end

hook.Add("PlayerButtonDown", "oasis_tickets_open_admin", function(_, button)
    if button == config.AdminMenuKey then
        openAdminMenu()
    end
end)

net.Receive("oasis_tickets_admin_sync", function()
    addon.AdminTickets = net.ReadTable() or {}
    if IsValid(addon.AdminMenu) then
        openAdminMenu(true)
    end
end)

net.Receive("oasis_tickets_history_response", function()
    local target = net.ReadEntity()
    local history = net.ReadTable() or {}

    if not IsValid(target) then
        return
    end

    local historyFrame = vguiLib.CreateFrame(util.Lang("ticket_history") .. " - " .. target:Nick(), 520, 420)
    local body = vgui.Create("DPanel", historyFrame)
    body:Dock(FILL)
    body:DockMargin(20, 50, 20, 20)
    function body:Paint() end

    local scroll = vguiLib.CreateScrollPanel(body)
    scroll:Dock(FILL)

    for _, ticket in ipairs(history) do
        local entry = vgui.Create("DPanel", scroll)
        entry:SetTall(80)
        entry:Dock(TOP)
        entry:DockMargin(0, 0, 0, 8)
        function entry:Paint(w, h)
            surface.SetDrawColor(util.ColorFromTable(config.Colors.Panel))
            surface.DrawRect(0, 0, w, h)
        end

        local header = vguiLib.CreateLabel(entry, string.format("%s | %s", ticket.category, ticket.status), "oasis_tickets_text")
        header:Dock(TOP)
        header:DockMargin(12, 6, 12, 0)

        local meta = vguiLib.CreateLabel(entry, string.format("%s → %s | %s", ticket.reporterName, ticket.targetName, formatTimestamp(ticket.createdAt)), "oasis_tickets_small")
        meta:SetTextColor(util.ColorFromTable(config.Colors.Muted))
        meta:Dock(TOP)
        meta:DockMargin(12, 2, 12, 0)
    end
end)
