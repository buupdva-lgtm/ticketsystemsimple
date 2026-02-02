local addon = oasis_tickets

local vguiLib = addon.VGUI
local config = addon.Config
local util = addon.Util

local lastSound = 0

local function playSound(path)
    if not config.Sounds.Enabled then
        return
    end

    if CurTime() - lastSound < config.Sounds.Cooldown then
        return
    end

    lastSound = CurTime()
    surface.PlaySound(path)
end

local function buildPlayerList()
    local players = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() then
            table.insert(players, ply)
        end
    end

    table.sort(players, function(a, b)
        return a:Nick() < b:Nick()
    end)

    return players
end

local function openTicketMenu()
    if IsValid(addon.PlayerMenu) then
        addon.PlayerMenu:Remove()
        return
    end

    local width = math.min(math.floor(ScrW() * 0.6), 720)
    local height = math.min(math.floor(ScrH() * 0.7), 640)
    local frame = vguiLib.CreateFrame(util.Lang("title_player_menu"), width, height)
    addon.PlayerMenu = frame

    local body = vguiLib.CreateScrollPanel(frame)
    body:Dock(FILL)
    body:DockMargin(20, 50, 20, 20)
    function body:Paint() end

    local content = vgui.Create("DPanel", body)
    content:Dock(TOP)
    content:DockMargin(0, 0, 0, 0)
    content:SetTall(height)
    function content:Paint() end

    local playerLabel = vguiLib.CreateLabel(content, util.Lang("select_player"), "oasis_tickets_small")
    playerLabel:Dock(TOP)

    local playerItems = {}
    for _, ply in ipairs(buildPlayerList()) do
        table.insert(playerItems, { label = ply:Nick(), value = ply })
    end
    local playerDropdown = vguiLib.CreateDropdown(content, playerItems, nil)
    playerDropdown:Dock(TOP)
    playerDropdown:DockMargin(0, 6, 0, 12)

    local categoryLabel = vguiLib.CreateLabel(content, util.Lang("select_category"), "oasis_tickets_small")
    categoryLabel:Dock(TOP)

    local categoryDropdown = vguiLib.CreateDropdown(content, config.TicketCategories, nil)
    categoryDropdown:Dock(TOP)
    categoryDropdown:DockMargin(0, 6, 0, 12)

    local priorityLabel = vguiLib.CreateLabel(content, util.Lang("select_priority"), "oasis_tickets_small")
    priorityLabel:Dock(TOP)

    local priorityNames = {}
    local priorityMap = {}
    for _, priority in ipairs(config.TicketPriorities) do
        table.insert(priorityNames, priority.name)
        priorityMap[priority.name] = priority.id
    end

    local priorityDropdown = vguiLib.CreateDropdown(content, priorityNames, nil)
    priorityDropdown:Dock(TOP)
    priorityDropdown:DockMargin(0, 6, 0, 12)

    local descLabel = vguiLib.CreateLabel(content, util.Lang("description_label"), "oasis_tickets_small")
    descLabel:Dock(TOP)

    local descEntry = vguiLib.CreateTextEntry(content, true)
    descEntry:SetTall(140)
    descEntry:Dock(TOP)
    descEntry:DockMargin(0, 6, 0, 0)

    local hintLabel = vguiLib.CreateLabel(content, util.Lang("description_required"), "oasis_tickets_small")
    hintLabel:SetTextColor(util.ColorFromTable(config.Colors.Danger))
    hintLabel:Dock(TOP)
    hintLabel:DockMargin(0, 6, 0, 12)

    local submit = vguiLib.CreateButton(content, util.Lang("submit_ticket"), function()
        local target = playerDropdown.Selected
        local category = categoryDropdown.Selected
        local priority = priorityMap[priorityDropdown.Selected or ""]
        local description = string.Trim(descEntry:GetValue() or "")

        if not target or not IsValid(target) then
            return
        end

        if not category then
            return
        end

        if not priority then
            local auto = config.GetPriorityByCategory(category)
            priority = auto.id
        end

        if #description < config.MinimumDescriptionLength then
            hintLabel:SetText(util.Lang("description_too_short"))
            return
        end

        net.Start("oasis_tickets_submit")
        net.WriteEntity(target)
        net.WriteString(category)
        net.WriteString(priority)
        net.WriteString(description)
        net.SendToServer()
    end)
    submit:Dock(TOP)
    submit:DockMargin(0, 8, 0, 0)

    content:InvalidateLayout(true)
    content:SizeToChildren(false, true)
end

hook.Add("PlayerButtonDown", "oasis_tickets_open_menu", function(_, button)
    if button == config.PlayerMenuKey then
        openTicketMenu()
    end
end)

net.Receive("oasis_tickets_notice", function()
    local message = net.ReadString()
    notification.AddLegacy(message, NOTIFY_GENERIC, 3)
end)

net.Receive("oasis_tickets_sound", function()
    local path = net.ReadString()
    playSound(path)
end)
