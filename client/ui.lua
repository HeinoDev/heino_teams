local Config = lib.load('config')

Ui = { open = false }

function Ui.toast(description, type)
    lib.notify({ title = NotifyText('title'), description = description, type = type or 'inform' })
end

function Ui.send(action, data)
    SendNUIMessage({ action = action, data = data })
end

function Ui.show()
    if Ui.open then return end
    Ui.open = true
    SetNuiFocus(true, true)
    local state = lib.callback.await('heino_teams:server:getState', false)
    state.locale = UiLocale
    Ui.send('open', state)
end

function Ui.hide()
    if not Ui.open then return end
    Ui.open = false
    SetNuiFocus(false, false)
    Ui.send('close')
end

function Ui.result(res, okMessage)
    if res and res.success then
        if okMessage then Ui.toast(okMessage, 'success') end
    else
        Ui.toast(res and res.error and NotifyText('err_' .. res.error, Config.InviteDistance) or NotifyText('generic_error'), 'error')
    end
    return res
end
