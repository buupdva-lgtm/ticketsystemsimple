local addon = oasis_tickets

local vguiLib = addon.VGUI
local config = addon.Config
local util = addon.Util

local lastTicketCount = 0

local function resolvePriorityName(priorityId)
    local entry = config.GetPriorityById(priorityId)
    return entry and entry.name or priorityId
end

local function findPlayerBySteamId(steamId)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamId then
            return ply
        end
    end
    return nil
end

local function showPopup(ticket, index)
    if IsValid(addon.AdminPopup) then
        addon.AdminPopup:Remove()
    end

    local popup = vgui.Create("DPanel")
    popup:SetSize(360, 200)
    popup:SetPos(ScrW() - 380, 40)
    popup:SetAlpha(0)
    popup:AlphaTo(255, 0.2, 0)

    function popup:Paint(w, h)
        surface.SetDrawColor(util.ColorFromTable(config.Colors.Panel))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(util.ColorFromTable(config.Colors.Accent))
        surface.DrawRect(0, 0, w, 2)
        draw.SimpleText(ticket.targetName .. " → " .. ticket.reporterName, "oasis_tickets_text", 12, 12, util.ColorFromTable(config.Colors.Text))
        draw.SimpleText(ticket.category .. " | " .. resolvePriorityName(ticket.priority), "oasis_tickets_small", 12, 34, util.ColorFromTable(config.Colors.Muted))
    end

    local actions = vgui.Create("DPanel", popup)
    actions:SetPos(12, 70)
    actions:SetSize(336, 120)
    function actions:Paint() end

    local function sendAdminAction(action)
        net.Start("oasis_tickets_admin_action")
        net.WriteUInt(index, 16)
        net.WriteString(action)
        net.SendToServer()
    end

    local function sendUlxAction(action)
        local target = findPlayerBySteamId(ticket.targetSteamId)
        if not IsValid(target) then
            notification.AddLegacy(util.Lang("ulx_missing"), NOTIFY_ERROR, 3)
            return
        end

        net.Start("oasis_tickets_ulx_action")
        net.WriteString(action)
        net.WriteEntity(target)
        net.SendToServer()
    end

    local claim = vguiLib.CreateButton(actions, util.Lang("ticket_claim"), function()
        sendAdminAction("claim")
    end)
    claim:Dock(TOP)

    local gotoBtn = vguiLib.CreateButton(actions, util.Lang("ticket_goto"), function()
        sendUlxAction("ulx goto")
    end)
    gotoBtn:Dock(TOP)
    gotoBtn:DockMargin(0, 6, 0, 0)

    local bringBtn = vguiLib.CreateButton(actions, util.Lang("ticket_bring"), function()
        sendUlxAction("ulx bring")
    end)
    bringBtn:Dock(TOP)
    bringBtn:DockMargin(0, 6, 0, 0)

    local bottom = vgui.Create("DPanel", actions)
    bottom:Dock(TOP)
    bottom:SetTall(36)
    bottom:DockMargin(0, 6, 0, 0)
    function bottom:Paint() end

    local jailBtn = vguiLib.CreateButton(bottom, util.Lang("ticket_jailtp"), function()
        sendUlxAction("ulx jailtp")
    end)
    jailBtn:Dock(LEFT)
    jailBtn:SetWide(100)

    local returnBtn = vguiLib.CreateButton(bottom, util.Lang("ticket_return"), function()
        sendUlxAction("ulx return")
    end)
    returnBtn:Dock(LEFT)
    returnBtn:SetWide(100)
    returnBtn:DockMargin(6, 0, 0, 0)

    local closeBtn = vguiLib.CreateButton(bottom, util.Lang("ticket_close"), function()
        sendAdminAction("close")
        popup:AlphaTo(0, 0.2, 0, function()
            if IsValid(popup) then
                popup:Remove()
            end
        end)
    end)
    closeBtn:Dock(RIGHT)
    closeBtn:SetWide(100)

    addon.AdminPopup = popup
end

net.Receive("oasis_tickets_admin_sync", function()
    local tickets = net.ReadTable() or {}
    if lastTicketCount == 0 then
        lastTicketCount = #tickets
        return
    end

    if #tickets <= lastTicketCount then
        return
    end

    local ticket = tickets[#tickets]
    if not ticket then
        return
    end

    lastTicketCount = #tickets

    if not config.IsAdminGroup(LocalPlayer():GetUserGroup()) then
        return
    end

    showPopup(ticket, #tickets)
end)
