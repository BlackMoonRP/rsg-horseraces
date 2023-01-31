local RSGCore = exports['rsg-core']:GetCoreObject()

local Races = {}

local function GetCreatedRace(identifier)
    for key in pairs(Races) do
        if Races[key] ~= nil and Races[key].creator == identifier and not Races[key].started then
            return key
        end
    end
    return 0
end

local function RemoveFromRace(identifier)
    for key in pairs(Races) do
        if Races[key] ~= nil and not Races[key].started then
            for i, iden in pairs(Races[key].joined) do
                if iden == identifier then
                    table.remove(Races[key].joined, i)
                end
            end
        end
    end
end

local function CancelRace(source)
    local RaceId = GetCreatedRace(RSGCore.Functions.GetIdentifier(source, 'license'))
    local Player = RSGCore.Functions.GetPlayer(source)

    if RaceId ~= 0 then
        for key in pairs(Races) do
            if Races[key] ~= nil and Races[key].creator == Player.PlayerData.license then
                if not Races[key].started then
                    for _, iden in pairs(Races[key].joined) do
                        local xdPlayer = RSGCore.Functions.GetPlayer(iden)
                            xdPlayer.Functions.AddMoney('cash', Races[key].amount, "race-cancelled")
                            TriggerClientEvent('RSGCore:Notify', xdPlayer.PlayerData.source, "Race Has Stopped, You Got Back $"..Races[key].amount.."", 'error')
                            TriggerClientEvent('rsg-horseraces:StopRace', xdPlayer.PlayerData.source)
                            RemoveFromRace(iden)
                    end
                else
                    TriggerClientEvent('RSGCore:Notify', Player.PlayerData.source, "The Race Has Already Started", 'error')
                end
                TriggerClientEvent('RSGCore:Notify', source, "Race Stopped!", 'error')
                Races[key] = nil
            end
        end
        TriggerClientEvent('rsg-horseraces:SetRace', -1, Races)
    else
        TriggerClientEvent('RSGCore:Notify', source, "You Have Not Started A Race!", 'error')
    end
end

function GetJoinedRace(identifier)
    for key in pairs(Races) do
        if Races[key] ~= nil and not Races[key].started then
            for _, iden in pairs(Races[key].joined) do
                if iden == identifier then
                    return key
                end
            end
        end
    end
    return 0
end

RegisterNetEvent('rsg-horseraces:NewRace', function(RaceTable)
    local src = source
    local RaceId = math.random(1000, 9999)
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    if xPlayer.Functions.RemoveMoney('cash', RaceTable.amount, "horserace-created") then
        Races[RaceId] = RaceTable
        Races[RaceId].creator = RSGCore.Functions.GetIdentifier(src, 'license')
        Races[RaceId].joined[#Races[RaceId].joined+1] = RSGCore.Functions.GetIdentifier(src, 'license')
        TriggerClientEvent('rsg-horseraces:SetRace', -1, Races)
        TriggerClientEvent('rsg-horseraces:SetRaceId', src, RaceId)
        TriggerClientEvent('RSGCore:Notify', src, "You joind the race for $"..Races[RaceId].amount..",-", 'success')
    end
end)

RegisterNetEvent('rsg-horseraces:RaceWon', function(RaceId)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    xPlayer.Functions.AddMoney('cash', Races[RaceId].pot, "race-won")
    TriggerClientEvent('RSGCore:Notify', src, "You won the race and $"..Races[RaceId].pot..",- recieved", 'success')
    TriggerClientEvent('rsg-horseraces:SetRace', -1, Races)
    TriggerClientEvent('rsg-horseraces:RaceDone', -1, RaceId, GetPlayerName(src))
end)

RegisterNetEvent('rsg-horseraces:JoinRace', function(RaceId)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    local zPlayer = RSGCore.Functions.GetPlayer(Races[RaceId].creator)
    if zPlayer ~= nil then
        if xPlayer.PlayerData.money.cash >= Races[RaceId].amount then
            Races[RaceId].pot = Races[RaceId].pot + Races[RaceId].amount
            Races[RaceId].joined[#Races[RaceId].joined+1] = RSGCore.Functions.GetIdentifier(src, 'license')
            if xPlayer.Functions.RemoveMoney('cash', Races[RaceId].amount, "horserace-joined") then
                TriggerClientEvent('rsg-horseraces:SetRace', -1, Races)
                TriggerClientEvent('rsg-horseraces:SetRaceId', src, RaceId)
                TriggerClientEvent('RSGCore:Notify', zPlayer.PlayerData.source, GetPlayerName(src).." Joined the race", 'primary')
            end
        else
            TriggerClientEvent('RSGCore:Notify', src, "You dont have enough cash", 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, "The person who made the race is offline!", 'error')
        Races[RaceId] = {}
    end
end)

RSGCore.Commands.Add("createrace", "Start a Horse Race", {{name="amount", help="The Stake Amount For The Race."}}, false, function(source, args)
    local src = source
    local amount = tonumber(args[1])
    if GetJoinedRace(RSGCore.Functions.GetIdentifier(src, 'license')) == 0 then
        TriggerClientEvent('rsg-horseraces:CreateRace', src, amount)
    else
        TriggerClientEvent('RSGCore:Notify', src, "You Are Already In A Race", 'error')
    end
end)

RSGCore.Commands.Add("stoprace", "Stop The Race You Created", {}, false, function(source, _)
    CancelRace(source)
end)

RSGCore.Commands.Add("quitrace", "Get Out Of A Race. (You Will NOT Get Your Money Back!)", {}, false, function(source, _)
    local src = source
    local RaceId = GetJoinedRace(RSGCore.Functions.GetIdentifier(src, 'license'))
    if RaceId ~= 0 then
        if GetCreatedRace(RSGCore.Functions.GetIdentifier(src, 'license')) ~= RaceId then
            RemoveFromRace(RSGCore.Functions.GetIdentifier(src, 'license'))
            TriggerClientEvent('RSGCore:Notify', src, "You Have Stepped Out Of The Race! And You Lost Your Money", 'error')
        else
            TriggerClientEvent('RSGCore:Notify', src, "/stoprace To Stop The Race", 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, "You Are Not In A Race ", 'error')
    end
end)

RSGCore.Commands.Add("startrace", "Start The Race", {}, false, function(source)
    local src = source
    local RaceId = GetCreatedRace(RSGCore.Functions.GetIdentifier(src, 'license'))

    if RaceId ~= 0 then

        Races[RaceId].started = true
        TriggerClientEvent('rsg-horseraces:SetRace', -1, Races)
        TriggerClientEvent("rsg-horseraces:StartRace", -1, RaceId)
    else
        TriggerClientEvent('RSGCore:Notify', src, "You Have Not Started A Race", 'error')
    end
end)
