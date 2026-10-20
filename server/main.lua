lib.callback.register('heino_teams:server:getState', Teams.getState)

lib.callback.register('heino_teams:server:create', function(src)
    local id, err = Teams.create(src)
    return { success = id ~= nil, error = err }
end)

lib.callback.register('heino_teams:server:invite', function(src, target)
    local success, err = Teams.invite(src, target)
    return { success = success, error = err }
end)

lib.callback.register('heino_teams:server:accept', function(src)
    local success, err = Teams.accept(src)
    return { success = success, error = err }
end)

lib.callback.register('heino_teams:server:kick', function(src, target)
    return { success = Teams.kick(src, target) }
end)

lib.callback.register('heino_teams:server:nearby', Teams.nearby)

RegisterNetEvent('heino_teams:server:decline', function()
    Teams.decline(source)
end)

RegisterNetEvent('heino_teams:server:leave', function()
    Teams.remove(source)
end)

AddEventHandler('playerDropped', function()
    Teams.forget(source)
end)

exports('CreateTeam', Teams.create)
exports('InvitePlayer', Teams.invite)
exports('AcceptInvite', Teams.accept)
exports('DeclineInvite', Teams.decline)
exports('LeaveTeam', function(src) Teams.remove(src) return true end)
exports('IsInTeam', function(src) return Teams.get(src) ~= nil end)
exports('GetTeam', Teams.get)
exports('GetTeamMembers', function(src)
    local team = Teams.get(src)
    return team and team.members or { src }
end)
exports('ForEachTeamMember', function(src, fn)
    local team = Teams.get(src)
    if not team then return end
    for i = 1, #team.members do fn(team.members[i]) end
end)
