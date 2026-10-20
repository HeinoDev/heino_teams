local Config = lib.load('config')

RegisterNUICallback('close', function(_, cb)
    Ui.hide()
    cb({})
end)

RegisterNUICallback('create', function(_, cb)
    cb(Ui.result(lib.callback.await('heino_teams:server:create', false)))
end)

RegisterNUICallback('invite', function(data, cb)
    cb(Ui.result(lib.callback.await('heino_teams:server:invite', false, data.id)))
end)

RegisterNUICallback('accept', function(_, cb)
    cb(Ui.result(lib.callback.await('heino_teams:server:accept', false), NotifyText('joined_team')))
end)

RegisterNUICallback('decline', function(_, cb)
    TriggerServerEvent('heino_teams:server:decline')
    cb({})
end)

RegisterNUICallback('leave', function(_, cb)
    TriggerServerEvent('heino_teams:server:leave')
    cb({})
end)

RegisterNUICallback('kick', function(data, cb)
    cb(Ui.result(lib.callback.await('heino_teams:server:kick', false, data.id)))
end)

RegisterNUICallback('nearby', function(_, cb)
    cb(lib.callback.await('heino_teams:server:nearby', false))
end)

RegisterNetEvent('heino_teams:client:update', function(team)
    Ui.send('team', team)
end)

RegisterNetEvent('heino_teams:client:invite', function(invite)
    Ui.send('invite', invite)
    if invite then
        Ui.toast(NotifyText('invite_received', invite.inviterName, Config.Command))
    end
end)

RegisterCommand(Config.Command, function()
    if Ui.open then Ui.hide() else Ui.show() end
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and Ui.open then SetNuiFocus(false, false) end
end)
