local RSGCore = exports['rsg-core']:GetCoreObject()
local Races = {}
local InRace = false
local RaceId = 0
local ShowCountDown = false
local RaceCount = 5

function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

local function RaceCountDown()
    ShowCountDown = true
    while RaceCount ~= 0 do
        FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), true)
        PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
        RSGCore.Functions.Notify(RaceCount, 'primary', 800)
        Wait(1000)
        RaceCount = RaceCount - 1
    end
    ShowCountDown = false
    RaceCount = 5
    FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), false)
    RSGCore.Functions.Notify("GOOOOOOOOO!!!")
end

CreateThread(function()
    while true do
        local sleep = 1000
        if Races ~= nil then
            -- No race yet
            local pos = GetEntityCoords(PlayerPedId(), true)
            if RaceId == 0 then
                for k in pairs(Races) do
                    if Races[k] ~= nil then
                        if #(pos - vector3(Races[k].startx, Races[k].starty, Races[k].startz)) < 15.0 and not Races[k].started then
                            sleep = 0
                            DrawText3D(Races[k].startx, Races[k].starty, Races[k].startz, "[~g~H~w~] To Join The Race (~g~$"..Races[k].amount..",-~w~)")
                            if IsControlJustReleased(0, 45) then --R
                                TriggerServerEvent("rsg-horseraces:JoinRace", k)
                            end
                        end
                    end

                end
            end
            -- Not started in race yet
            if RaceId ~= 0 and not InRace then
                if #(pos - vector3(Races[RaceId].startx, Races[RaceId].starty, Races[RaceId].startz)) < 15.0 and not Races[RaceId].started then
                    sleep = 0
                    DrawText3D(Races[RaceId].startx, Races[RaceId].starty, Races[RaceId].startz, "Race Will Start Soon")
                end
            end
            -- In race and started
            if RaceId ~= 0 and InRace then
                if #(pos - vector3(Races[RaceId].endx, Races[RaceId].endy, pos.z)) < 250.0 and Races[RaceId].started then
                    sleep = 0
                    DrawText3D(Races[RaceId].endx, Races[RaceId].endy, pos.z + 0.98, "FINISH")
                    if #(pos - vector3(Races[RaceId].endx, Races[RaceId].endy, pos.z)) < 15.0 then
                        TriggerServerEvent("rsg-horseraces:RaceWon", RaceId)
                        InRace = false
                    end
                end
            end

            if ShowCountDown then
                if #(pos - vector3(Races[RaceId].startx, Races[RaceId].starty, Races[RaceId].startz)) < 15.0 and Races[RaceId].started then
                    sleep = 0
                    DrawText3D(Races[RaceId].startx, Races[RaceId].starty, Races[RaceId].startz, "Race start in ~g~"..RaceCount)
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('rsg-horseraces:StartRace', function(race)
    if RaceId ~= 0 and RaceId == race then
     --   SetNewWaypoint(Races[RaceId].endx, Races[RaceId].endy)
        StartGpsMultiRoute(6, true, true)
        AddPointToGpsMultiRoute(Races[RaceId].endx, Races[RaceId].endy)
        SetGpsMultiRouteRender(true)
        InRace = true
        RaceCountDown()
    end
end)

RegisterNetEvent('rsg-horseraces:RaceDone', function(race, winner)
    if RaceId ~= 0 and RaceId == race then
        RaceId = 0
        InRace = false
        RSGCore.Functions.Notify("Race Is Over! The Winner Is "..winner.. "!")
    end
end)

RegisterNetEvent('rsg-horseraces:StopRace', function()
    RaceId = 0
    InRace = false
end)

RegisterNetEvent('rsg-horseraces:CreateRace', function(amount)
    local pos = GetEntityCoords(PlayerPedId(), true)
    local WaypointHandle = GetWaypointCoords()
   -- if DoesBlipExist(WaypointHandle) then
    if WaypointHandle then
        local c = WaypointHandle
        if #(pos - c) > 100.0 then
            local race = {
                creator = nil,
                started = false,
                startx = pos.x,
                starty = pos.y,
                startz = pos.z,
                endx = c.x,
                endy = c.y,
                endz = c.z,
                amount = amount,
                pot = amount,
                joined = {}
            }
            TriggerServerEvent("rsg-horseraces:NewRace", race)
            RSGCore.Functions.Notify("Race Made For $"..amount.."", "success")
        else
            RSGCore.Functions.Notify("End Position Is Too Close", "error")
        end
    else
        RSGCore.Functions.Notify("You Need To Drop A Marker", "error")
    end
end)

RegisterNetEvent('rsg-horseraces:SetRace', function(RaceTable)
    Races = RaceTable
end)

RegisterNetEvent('rsg-horseraces:SetRaceId', function(race)
    RaceId = race
    StartGpsMultiRoute(6, true, true)
    AddPointToGpsMultiRoute(Races[RaceId].endx, Races[RaceId].endy)
    SetGpsMultiRouteRender(true)
end)
