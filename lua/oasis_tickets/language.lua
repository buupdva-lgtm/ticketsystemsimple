local addon = oasis_tickets

addon.Language = addon.Language or {}

local language = addon.Language

local strings = {
    en = {
        title_player_menu = "Create Ticket",
        title_admin_menu = "Ticket Management",
        submit_ticket = "Submit Ticket",
        select_player = "Select player",
        select_category = "Select category",
        select_priority = "Select priority",
        description_label = "Problem description",
        description_required = "This field must be filled in",
        description_too_short = "Description is too short",
        cannot_self_report = "You cannot report yourself",
        ticket_sent = "Ticket submitted",
        ticket_status_open = "Open",
        ticket_status_claimed = "Claimed",
        ticket_status_closed = "Closed",
        ticket_history = "Ticket history",
        ticket_claim = "Claim",
        ticket_close = "Close",
        ticket_goto = "Goto",
        ticket_bring = "Bring",
        ticket_jailtp = "JailTP",
        ticket_return = "Return",
        filter_status = "Status",
        filter_category = "Category",
        filter_priority = "Priority",
        ulx_missing = "ULX not available",
        no_tickets = "No tickets available",
        cooldown_notice = "Please wait before sending another ticket"
    },
    de = {
        title_player_menu = "Ticket erstellen",
        title_admin_menu = "Ticket Verwaltung",
        submit_ticket = "Ticket senden",
        select_player = "Spieler auswählen",
        select_category = "Kategorie auswählen",
        select_priority = "Priorität auswählen",
        description_label = "Problembeschreibung",
        description_required = "Dieses Feld muss ausgefüllt werden",
        description_too_short = "Beschreibung ist zu kurz",
        cannot_self_report = "Du kannst dich nicht selbst melden",
        ticket_sent = "Ticket gesendet",
        ticket_status_open = "Offen",
        ticket_status_claimed = "Übernommen",
        ticket_status_closed = "Geschlossen",
        ticket_history = "Ticket Verlauf",
        ticket_claim = "Claim",
        ticket_close = "Close",
        ticket_goto = "Goto",
        ticket_bring = "Bring",
        ticket_jailtp = "JailTP",
        ticket_return = "Return",
        filter_status = "Status",
        filter_category = "Kategorie",
        filter_priority = "Priorität",
        ulx_missing = "ULX nicht verfügbar",
        no_tickets = "Keine Tickets verfügbar",
        cooldown_notice = "Bitte warte bevor du ein weiteres Ticket sendest"
    }
}

function language.Get(key, langOverride)
    local lang = langOverride or addon.Config.Language or "en"
    if strings[lang] and strings[lang][key] then
        return strings[lang][key]
    end

    if strings.en[key] then
        return strings.en[key]
    end

    return key
end
