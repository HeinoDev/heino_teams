local Config = lib.load('config')

Teams = { invites = {} }

local teams, playerTeam, lastInvite = {}, {}, {}
local invites = Teams.invites
local nextTeamId = 1

local function getTeam(src)
    local teamId = playerTeam[src]
    return teamId and teams[teamId] or nil
end

local function serialize(team)
    if not team then return nil end

    local members = {}
    for i = 1, #team.members do
        local memberSrc = team.members[i]
        members[i] = { id = memberSrc, name = Framework.playerName(memberSrc), leader = memberSrc == team.leader }
    end

    return { id = team.id, leader = team.leader, maxSize = team.maxSize, members = members }
end

local function setState(src, teamId)
    Player(src).state:set('heino_teams:team', teamId or false, true)
end

local function push(src)
    TriggerClientEvent('heino_teams:client:update', src, serialize(getTeam(src)))
end

local function pushTeam(team)
    for i = 1, #team.members do push(team.members[i]) end
end

local function notify(src, description, type)
    TriggerClientEvent('ox_lib:notify', src, { title = NotifyText('title'), description = description, type = type or 'inform' })
end

local function isNear(a, b)
    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= Config.InviteDistance
end

function Teams.get(src)
    return getTeam(src)
end

function Teams.register(leader, members)
    local id = nextTeamId
    nextTeamId = nextTeamId + 1

    teams[id] = { id = id, leader = leader, maxSize = Config.MaxSize, members = members }

    return id
end

function Teams.remove(src)
    local team = getTeam(src)
    if not team then return end

    for i = 1, #team.members do
        if team.members[i] == src then
            table.remove(team.members, i)
            break
        end
    end

    playerTeam[src] = nil
    setState(src, nil)

    if #team.members == 0 then
        teams[team.id] = nil
    else
        if team.leader == src then team.leader = team.members[1] end
        pushTeam(team)
    end

    if GetPlayerName(src) then push(src) end
end

function Teams.create(src)
    if playerTeam[src] then return nil, 'alreadyInTeam' end

    local id = Teams.register(src, { src })
    playerTeam[src] = id
    setState(src, id)
    push(src)

    return id
end

function Teams.invite(src, target)
    target = tonumber(target)
    if not target or target % 1 ~= 0 or target == src or not GetPlayerName(target) then return false, 'invalidTarget' end

    local team = getTeam(src)
    if not team then return false, 'notInTeam' end
    if team.leader ~= src then return false, 'notLeader' end
    if #team.members >= team.maxSize then return false, 'teamFull' end
    if playerTeam[target] then return false, 'targetInTeam' end
    if not isNear(src, target) then return false, 'tooFar' end

    local now = GetGameTimer()
    if lastInvite[src] and now - lastInvite[src] < Config.InviteCooldown then return false, 'tooFast' end
    lastInvite[src] = now

    local invite = { teamId = team.id, from = src, expiresAt = now + Config.InviteTimeout }
    invites[target] = invite

    TriggerClientEvent('heino_teams:client:invite', target, { inviterName = Framework.playerName(src), inviterId = src })
    notify(src, NotifyText('invite_sent', Framework.playerName(target)), 'success')

    SetTimeout(Config.InviteTimeout, function()
        if invites[target] == invite then
            invites[target] = nil
            if GetPlayerName(target) then
                TriggerClientEvent('heino_teams:client:invite', target, nil)
                notify(target, NotifyText('invite_expired'), 'error')
            end
        end
    end)

    return true
end

function Teams.accept(src)
    local invite = invites[src]
    if not invite or invite.expiresAt < GetGameTimer() then
        invites[src] = nil
        return false, 'noInvite'
    end

    local team = teams[invite.teamId]
    if team and GetPlayerName(team.leader) and not playerTeam[src] and #team.members < team.maxSize and not isNear(src, team.leader) then
        return false, 'tooFar'
    end

    invites[src] = nil
    TriggerClientEvent('heino_teams:client:invite', src, nil)

    if not team then return false, 'teamGone' end
    if playerTeam[src] then return false, 'alreadyInTeam' end
    if #team.members >= team.maxSize then return false, 'teamFull' end

    team.members[#team.members + 1] = src
    playerTeam[src] = team.id
    setState(src, team.id)
    pushTeam(team)

    for i = 1, #team.members do
        if team.members[i] ~= src then notify(team.members[i], NotifyText('member_joined', Framework.playerName(src)), 'success') end
    end

    return true
end

function Teams.decline(src)
    local invite = invites[src]
    if not invite then return end

    invites[src] = nil
    TriggerClientEvent('heino_teams:client:invite', src, nil)
    if GetPlayerName(invite.from) then notify(invite.from, NotifyText('invite_declined', Framework.playerName(src)), 'error') end
end

function Teams.kick(src, target)
    target = tonumber(target)
    local team = getTeam(src)
    if not team or team.leader ~= src or not target or target == src or playerTeam[target] ~= team.id then return false end

    Teams.remove(target)
    notify(target, NotifyText('kicked'), 'error')
    return true
end

function Teams.nearby(src)
    local coords = GetEntityCoords(GetPlayerPed(src))
    local list = {}

    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target ~= src and not playerTeam[target] and #(GetEntityCoords(GetPlayerPed(target)) - coords) <= Config.InviteDistance then
            list[#list + 1] = { id = target, name = Framework.playerName(target) }
        end
    end

    return list
end

function Teams.getState(src)
    local invite = invites[src]
    local inviter = invite and invite.expiresAt > GetGameTimer() and { inviterName = Framework.playerName(invite.from), inviterId = invite.from } or nil
    return { team = serialize(getTeam(src)), invite = inviter, self = src }
end

function Teams.forget(src)
    Teams.remove(src)
    invites[src] = nil
    lastInvite[src] = nil
end
