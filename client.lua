ESX = nil
PlayerData = {}
bekleme = true

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterCommand("aimedic", function(source, args, raw)
	ESX.TriggerServerCallback('esx_ambulancejob:getDeathStatus', function(isDead)
		if isDead and bekleme then
            ESX.TriggerServerCallback('pazzodoktor:doktorsOnline', function(EMSOnline, hasEnoughMoney)
				if EMSOnline <= Config.Doktor and hasEnoughMoney then
					TriggerEvent("pazzodoktor:canlan")
					TriggerServerEvent('pazzodoktor:odeme')
					bekleme = false
				else
					if EMSOnline > Config.Doktor then
						notification(_U('to_many_medics'))
					else
						notification(_U('not_enough_money'))
					end	
				end
			end)
		else
			notification(_U('only_when_dead'))
		end
	end)
end)


RegisterNetEvent('pazzodoktor:canlan')
AddEventHandler("pazzodoktor:canlan", function()
 
    player = GetPlayerPed(-1)
    playerPos = GetEntityCoords(player)
    local driverhash = GetHashKey(Config.Ped)
    RequestModel(driverhash)
    local vehhash = GetHashKey(Config.Vehicle)
    RequestModel(vehhash)
    while not HasModelLoaded(driverhash) and RequestModel(driverhash) or not HasModelLoaded(vehhash) and RequestModel(vehhash) do
        RequestModel(driverhash)
        RequestModel(vehhash)
        Citizen.Wait(0)
    end

    if DoesEntityExist(player) then
    	if DoesEntityExist(medicVeh) then
			DeleteVeh(medicVeh, medicPed)
			SpawnVehicle(playerPos.x, playerPos.y, playerPos.x, vehhash, driverhash)
		else
			SpawnVehicle(playerPos.x, playerPos.y, playerPos.x, vehhash, driverhash)
		end
		GoToTarget(GetEntityCoords(player).x, GetEntityCoords(player).y, GetEntityCoords(player).z, medicVeh, medicPed, vehhash, player)
    end
end)

function SpawnVehicle(x, y, z, vehhash, driverhash)                                                     
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(x + math.random(-100, 100), y + math.random(-100, 100), z, 1, 3, 0)

    if found and HasModelLoaded(vehhash) and HasModelLoaded(vehhash) then
        medicVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)                           
        ClearAreaOfVehicles(GetEntityCoords(medicVeh), 5000, false, false, false, false, false);  
        SetVehicleOnGroundProperly(medicVeh)    
        medicPed = CreatePedInsideVehicle(medicVeh, 26, driverhash, -1, true, false)
        medicBlip = AddBlipForEntity(medicVeh)
        SetBlipFlashes(medicBlip, true)  
        SetBlipColour(medicBlip, 5)
    end
end

function DeleteVeh(vehicle, driver)
    SetEntityAsMissionEntity(vehicle, false, false)
    DeleteEntity(vehicle)
    SetEntityAsMissionEntity(driver, false, false)
    DeleteEntity(driver)
    RemoveBlip(medicBlip)
end

function GoToTarget(x, y, z, vehicle, driver, vehhash, target)
	SetVehicleSiren(vehicle, true)
    TaskVehicleDriveToCoord(driver, vehicle, x, y, z, 17.0, 0, vehhash, 786603, 1, true)
    ESX.ShowAdvancedNotification(_U('dispath_company'), _U('dispatch_request'), _U('dispatch_message'),'CHAR_CALL911', 8)
    enroute = true
    while enroute do
		Citizen.Wait(500)
		local playerCoords = GetEntityCoords(target)
		local medicCoords = GetEntityCoords(vehicle)
        distanceToTarget = #(playerCoords - medicCoords)
        if distanceToTarget < 20 then
            TaskVehicleTempAction(driver, vehicle, 27, 6000)
		    SetVehicleUndriveable(vehicle, true)
		    SetVehicleDoorsLockedForAllPlayers(vehicle, true)
		    SetVehicleSiren(vehicle, false)
		    TaskLeaveVehicle(driver, vehicle, 1)
            GoToTargetWalking(target, vehicle, driver)
        end
    end
end

function GoToTargetWalking(target, vehicle, driver)
	local coords = GetEntityCoords(target)
    while enroute do
		Citizen.Wait(500)
		local medicCoords = GetEntityCoords(driver)
        TaskGoToCoordAnyMeans(driver, coords, 2.0, 0, 0, 786603, 0xbf800000)
        distanceToTarget = #(coords - medicCoords)
        norunrange = false 
        if distanceToTarget <= 10 and not norunrange then
            TaskGoToCoordAnyMeans(driver, coords, 1.0, 0, 0, 786603, 0xbf800000)
            norunrange = true
        end
		if distanceToTarget <= 2 then
			enroute = false
            TaskTurnPedToFaceCoord(driver, GetEntityCoords(target), -1)
			Citizen.Wait(1000)
			cagirma(driver, vehicle)
        end        
    end
end

function cagirma(DoktorP, vehicle)
	RequestAnimDict("mini@cpr@char_a@cpr_str")
	while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
	Citizen.Wait(0)
	end
	if Config.MythicProgbar then
		TaskPlayAnim(DoktorP, "mini@cpr@char_a@cpr_str","cpr_pumpchest",1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
        exports['mythic_progbar']:Progress({
        	name = "AI-Doctor_givingtreatment",
        	duration = 20000,
        	label = _U('getting_treatment'),
        	useWhileDead = true,
        	canCancel = false,
        	controlDisables = {
        		disableMovement = true,
        		disableCarMovement = true,
        		disableMouse = false,
        		disableCombat = true,
        	},
        })
        Citizen.Wait(20000)
        	ClearPedTasks(DoktorP)
			Tedavi(DoktorP, vehicle)
	else
		TaskPlayAnim(DoktorP, "mini@cpr@char_a@cpr_str","cpr_pumpchest",1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
		notification(_U('getting_treatment'))
		Citizen.Wait(20000)
        ClearPedTasks(DoktorP)
		Tedavi(DoktorP, vehicle)
	end	
end

function Tedavi(DoktorP, vehicle)
    Citizen.Wait(500)
	TriggerEvent('esx_ambulancejob:revive')
	notification(_U('treatment_done')..Config.Price..Config.MoneyFormat, 'success')
	RemovePedElegantly(DoktorP)
	bekleme = true
	Citizen.Wait(15000)
	DeleteVeh(vehicle, DoktorP)
end

function notification(text, type)
	if Config.MythicNotify then
		if type == nil then
			type = 'inform'
		end
    	exports['mythic_notify']:DoHudText(type, text)
	else
		ESX.ShowNotification(text)
	end
end