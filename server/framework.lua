local Config = lib.load('config')

Framework = {}

local frameworks = {
    qbox = {
        resource = 'qbx_core',
        playerName = function(src)
            local player = exports.qbx_core:GetPlayer(src)
            local info = player and player.PlayerData.charinfo
            return info and ('%s %s'):format(info.firstname, info.lastname)
        end,
    },
    esx = {
        resource = 'es_extended',
        playerName = function(src)
            local xPlayer = exports.es_extended:getSharedObject().GetPlayerFromId(src)
            return xPlayer and xPlayer.getName()
        end,
    },
}

local detectionOrder = { 'qbox', 'esx' }

function Framework.name()
    if Config.Framework ~= 'auto' then return Config.Framework end

    for _, key in ipairs(detectionOrder) do
        if GetResourceState(frameworks[key].resource) == 'started' then return key end
    end

    return 'standalone'
end

function Framework.playerName(src)
    local framework = frameworks[Framework.name()]

    if framework then
        local ok, name = pcall(framework.playerName, src)
        if ok and name then return name end
    end

    return GetPlayerName(src) or ('ID ' .. src)
end
