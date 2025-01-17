-- Variables
ESX = nil
local beltStatus = false
local hunger, thirst, stress = 0, 0, 0

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

-- Principal Event
AddEventHandler('esx_status:onTick', function(data)
	local playerPed = PlayerPedId()
    
	for k, v in pairs(data) do
		if v.name == 'hunger' then
			hunger = v.percent
		elseif v.name == 'thirst' then
			thirst = v.percent
		elseif v.name == 'stress' then
			stress = v.percent
		end
	end
	
	if hunger == 0 or thirst == 0 then
        ForcePedMotionState(playerPed, 1110276645, 0, 0, 0)
    end
end)

-- Principal Loop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.TickTime)
        local pedID = PlayerPedId()

        -- Player ID
        if Config.ShowServerID then
            SendNUIMessage({
                pid = true,
                playerid = GetPlayerServerId(PlayerId()),
            })
        else
            SendNUIMessage({pid = false})
        end

        -- Ped oxygen underwater
        if IsPedSwimmingUnderWater(pedID) then
            SendNUIMessage({showOxygen = true})
        else
            SendNUIMessage({showOxygen = false})
        end

        -- Ped stamina while sprinting
        if Config.ShowStamina then
            SendNUIMessage({showStamina = true})
        else
            SendNUIMessage({showStamina = false})
        end
        
        -- Entity health
        if ((GetEntityHealth(pedID) - 100) >= 100) then
            SendNUIMessage({showHealth = false})
        else
            SendNUIMessage({showHealth = true})
        end
		
        -- Stress config
        if Config.ShowStress then
            if stress > 1 then
                SendNUIMessage({showStress = true})
            else
                SendNUIMessage({showStress = false})
            end
        else
            SendNUIMessage({showStress = false})
        end
        
        -- Belt config
        if Config.ShowBelt then
            SendNUIMessage({showBelt = true})
        else
            SendNUIMessage({showBelt = false})
        end
		
		-- Voice config
        if Config.ShowVoice then
            SendNUIMessage({showVoice = true})
        else
            SendNUIMessage({showVoice = false})
        end
        
        -- HUD visibility checks
        if IsPauseMenuActive() or IsPlayerSwitchInProgress() or (Config.HideWhileGameplayCameraIsNotRendering and not IsGameplayCamRendering()) then
            SendNUIMessage({showUi = false})
        elseif not IsPauseMenuActive() then
            SendNUIMessage({showUi = true})
        end

        -- SpeedO gonfig
        if Config.ShowSpeedO then
            if IsPedInAnyVehicle(pedID, false) 
            and not IsPedInFlyingVehicle(pedID) 
            and not IsPedInAnySub(pedID) then
                SendNUIMessage({showSpeedo = true})
            elseif not IsPedInAnyVehicle(pedID, false) then
                SendNUIMessage({showSpeedo = false})
            end
        end

        -- Fuel config
        if Config.ShowFuel then
            SendNUIMessage({showFuel = true})
        else
            SendNUIMessage({showFuel = false})
        end

        if Config.ShowFuel then
            if IsPedInAnyVehicle(pedID, true) then
                local veh = GetVehiclePedIsUsing(pedID, false)
                local fuellevel = exports["LegacyFuel"]:GetFuel(veh)
                SendNUIMessage({
                    action = "update_fuel",
                    fuel = fuellevel
                })
            end
        end

        -- Check if player is in radio
        if LocalPlayer.state['radioChannel'] ~= nil then
            if LocalPlayer.state['radioChannel'] > 0 and LocalPlayer.state['radioChannel'] ~= 0 then
                SendNUIMessage({inRadio = true})
            elseif LocalPlayer.state['radioChannel'] == 0 then
                SendNUIMessage({inRadio = false})
            end
        end

        -- Radar config
        if not Config.ShowRadar then
            if IsPedInAnyVehicle(pedID, false) then
                DisplayRadar(true)
                SendNUIMessage({showOutlines = true})
            else
                DisplayRadar(false)
                SendNUIMessage({showOutlines = false})
            end
        else
            DisplayRadar(true)
            SendNUIMessage({showOutlines = true})
        end

        -- Stress config
        if Config.ShowStress then
            if math.floor(stress) >= Config.MinStressEffect then
                Citizen.Wait(10000)
                forRepeat()
            elseif math.floor(stress) == 100 then
                Citizen.Wait(500)
                forRepeat()
            end
        end
        
		SetRadarZoom(1000)
		
        -- Information sent to JavaScript
        SendNUIMessage({
            action = "update_hud",
            hp = GetEntityHealth(pedID) - 100,
            armor = GetPedArmour(pedID),
            hunger = hunger,
            thirst = thirst,
            stress = stress,
            isBeltOn = beltStatus,
            oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10,
            stamina = GetPlayerSprintTimeRemaining(PlayerId()) * 10,
            talking = NetworkIsPlayerTalking(PlayerId())
        })
    end
end)

Citizen.CreateThread(function()
	while true do
        Citizen.Wait(100)
		local pedID = PlayerPedId()
		
		-- Vehicle config while entity inside
		if IsPedInAnyVehicle(pedID, true) then
			local veh = GetVehiclePedIsUsing(pedID, false)
			local speed = math.floor(GetEntitySpeed(veh) * 3.6)
			
			SendNUIMessage({
				speed = speed
			})
		end
	end
end)
-- Position
local posX, posY, width, height = -0.015, -0.015, 0.16, 0.25
-- Map stuff
Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimap) do Wait(100) end
    
    RequestStreamedTextureDict("circlemap", false)
    while not HasStreamedTextureDictLoaded("circlemap") do Wait(100) end
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
    
    SetMinimapClipType(1)
    SetMinimapComponentPosition('minimap', 'L', 'B', posX, posY, width, height)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', posX + 0.17, posY + 0.09, 0.072, 0.162)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.032, -0.035, 0.18, 0.22)
    ThefeedSpsExtendWidescreenOn()
	
    SetMapZoomDataLevel(0, 0.96, 0.9, 0.08, 0.0, 0.0) -- Level 0
    SetMapZoomDataLevel(1, 1.6, 0.9, 0.08, 0.0, 0.0) -- Level 1
    SetMapZoomDataLevel(2, 8.6, 0.9, 0.08, 0.0, 0.0) -- Level 2
    SetMapZoomDataLevel(3, 12.3, 0.9, 0.08, 0.0, 0.0) -- Level 3
    SetMapZoomDataLevel(4, 22.3, 0.9, 0.08, 0.0, 0.0) -- Level 4
	
    SetBigmapActive(true, false)
    Wait(0)
    SetBigmapActive(false, false)
    
    while true do
        Citizen.Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
    end
end)

-- Microphone
AddEventHandler('pma-voice:setTalkingMode', function(newTalkingRange) 
    SendNUIMessage({
        action = "voice_level", 
        voicelevel = newTalkingRange
    })
end)

-- Seatbelt events
RegisterNetEvent("cosmo_hud:isSeatbeltOn")
AddEventHandler("cosmo_hud:isSeatbeltOn", function(isOn)
    beltStatus = isOn
    SendNUIMessage({
        isBeltOn = beltStatus
    })
end)

if Config.ShowStress then
    -- Stress function that makes you close your eyes when stress is too high
    function forRepeat()
        Citizen.Wait(750)
        DoScreenFadeOut(200)
        Citizen.Wait(Config.TickTime)
        DoScreenFadeIn(200)
    end

    -- Updated stress from server
    RegisterNetEvent('cosmo_hud:UpdateStress')
    AddEventHandler('cosmo_hud:UpdateStress', function(newStress)
        stress = newStress
    end)
end