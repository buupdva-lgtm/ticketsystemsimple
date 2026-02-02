local addon = oasis_tickets

addon.VGUI = addon.VGUI or {}

local vguiLib = addon.VGUI
local config = addon.Config
local util = addon.Util

local colors = config.Colors

surface.CreateFont("oasis_tickets_title", {
    font = "Roboto",
    size = 22,
    weight = 600
})

surface.CreateFont("oasis_tickets_text", {
    font = "Roboto",
    size = 16,
    weight = 500
})

surface.CreateFont("oasis_tickets_small", {
    font = "Roboto",
    size = 14,
    weight = 500
})

local function applyFade(panel)
    panel:SetAlpha(0)
    panel:AlphaTo(255, 0.15, 0)
end

function vguiLib.CreateFrame(title, width, height)
    local frame = vgui.Create("DPanel")
    frame:SetSize(width, height)
    frame:Center()
    frame:MakePopup()
    frame:SetMouseInputEnabled(true)
    frame:SetKeyboardInputEnabled(true)

    applyFade(frame)

    local closeBtn = vgui.Create("DPanel", frame)
    closeBtn:SetSize(32, 24)
    closeBtn:SetPos(width - 44, 12)
    closeBtn.Hover = 0

    function closeBtn:Paint(w, h)
        self.Hover = Lerp(FrameTime() * 10, self.Hover, self:IsHovered() and 1 or 0)
        surface.SetDrawColor(236, 90, 90, 140 + (80 * self.Hover))
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("✕", "oasis_tickets_text", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function closeBtn:OnMousePressed()
        if IsValid(frame) then
            frame:Remove()
        end
    end

    function frame:Paint(w, h)
        surface.SetDrawColor(util.ColorFromTable(colors.Background))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(util.ColorFromTable(colors.Accent))
        surface.DrawRect(0, 0, w, 2)
        draw.SimpleText(title, "oasis_tickets_title", 20, 12, util.ColorFromTable(colors.Text))
    end

    function frame:PerformLayout(w, h)
        closeBtn:SetPos(w - 44, 12)
    end

    return frame
end

function vguiLib.CreateButton(parent, label, onClick)
    local button = vgui.Create("DPanel", parent)
    button:SetTall(36)
    button.Label = label
    button.Hover = 0

    function button:Paint(w, h)
        self.Hover = Lerp(FrameTime() * 10, self.Hover, self:IsHovered() and 1 or 0)
        local base = util.ColorFromTable(colors.Accent)
        local bg = Color(base.r, base.g, base.b, 120 + (80 * self.Hover))
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(self.Label, "oasis_tickets_text", w / 2, h / 2, util.ColorFromTable(colors.Text), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function button:OnMousePressed()
        if onClick then
            onClick()
        end
    end

    return button
end

function vguiLib.CreateTextEntry(parent, multiline)
    local entry = vgui.Create("DTextEntry", parent)
    entry:SetMultiline(multiline)
    entry:SetText("")
    entry:SetFont("oasis_tickets_text")
    entry:SetTextColor(util.ColorFromTable(colors.Text))
    entry:SetCursorColor(util.ColorFromTable(colors.Accent))
    entry:SetHighlightColor(Color(84, 162, 255, 120))
    entry:SetPaintBackground(false)

    function entry:Paint(w, h)
        surface.SetDrawColor(util.ColorFromTable(colors.Panel))
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(util.ColorFromTable(colors.Text), util.ColorFromTable(colors.Accent), util.ColorFromTable(colors.Text))
    end

    return entry
end

local function styleScroll(panel)
    local bar = panel:GetVBar()
    function bar:Paint() end
    function bar.btnUp:Paint() end
    function bar.btnDown:Paint() end
    function bar.btnGrip:Paint(w, h)
        surface.SetDrawColor(util.ColorFromTable(colors.Accent))
        surface.DrawRect(0, 0, w, h)
    end
end

function vguiLib.CreateScrollPanel(parent)
    local panel = vgui.Create("DScrollPanel", parent)
    styleScroll(panel)
    return panel
end

function vguiLib.CreateDropdown(parent, items, onSelect)
    local container = vgui.Create("DPanel", parent)
    container:SetTall(36)
    container.Selected = nil
    container.Items = items or {}
    container.Expanded = false

    local label = vgui.Create("DLabel", container)
    label:Dock(FILL)
    label:SetFont("oasis_tickets_text")
    label:SetTextColor(util.ColorFromTable(colors.Text))
    label:SetContentAlignment(4)
    label:DockMargin(12, 0, 0, 0)
    label:SetText("-")

    local arrow = vgui.Create("DLabel", container)
    arrow:Dock(RIGHT)
    arrow:SetWide(40)
    arrow:SetFont("oasis_tickets_text")
    arrow:SetTextColor(util.ColorFromTable(colors.Muted))
    arrow:SetContentAlignment(5)
    arrow:SetText("▾")

    local listPanel = vgui.Create("DPanel", container)
    listPanel:SetVisible(false)
    listPanel:SetPos(0, 36)
    listPanel:SetSize(container:GetWide(), 150)

    function listPanel:Paint(w, h)
        surface.SetDrawColor(util.ColorFromTable(colors.Panel))
        surface.DrawRect(0, 0, w, h)
    end

    local scroll = vguiLib.CreateScrollPanel(listPanel)
    scroll:Dock(FILL)

    local function refresh()
        scroll:Clear()
        for _, value in ipairs(container.Items) do
            local entry = vguiLib.CreateButton(scroll, tostring(value), function()
                container.Selected = value
                label:SetText(tostring(value))
                container.Expanded = false
                listPanel:SetVisible(false)
                if container.OnSelect then
                    container.OnSelect(value)
                end
            end)
            entry:Dock(TOP)
            entry:DockMargin(6, 6, 6, 0)
        end
    end

    function container:SetItems(newItems)
        self.Items = newItems or {}
        refresh()
    end

    function container:SetOnSelect(callback)
        self.OnSelect = callback
    end

    function container:SetSelected(value)
        self.Selected = value
        label:SetText(tostring(value))
    end

    function container:Paint(w, h)
        surface.SetDrawColor(util.ColorFromTable(colors.Panel))
        surface.DrawRect(0, 0, w, h)
    end

    function container:OnMousePressed()
        self.Expanded = not self.Expanded
        listPanel:SetVisible(self.Expanded)
    end

    function container:PerformLayout(w, h)
        listPanel:SetPos(0, h)
        listPanel:SetSize(w, 150)
    end

    refresh()

    if onSelect then
        container:SetOnSelect(onSelect)
    end

    return container
end

function vguiLib.CreateLabel(parent, text, font)
    local label = vgui.Create("DLabel", parent)
    label:SetText(text or "")
    label:SetFont(font or "oasis_tickets_text")
    label:SetTextColor(util.ColorFromTable(colors.Text))
    return label
end
