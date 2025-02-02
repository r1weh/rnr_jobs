local spawnedKopi = 0
local kopiPlants = {}
local isPickingUp = false
local CurrentCheckPointKopi = 0
local LastCheckPointKopi   = -1
local CheckPointsKopi = Config.CheckPoints.location_kopi
local onDutyKopi = 0
local blipkopi = nil
local countcabutkopi = 0


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local letSleep = true
        local coords = GetEntityCoords(PlayerPedId())
        
        if onDutyKopi == 2 then
		    if GetDistanceBetweenCoords(coords, Config.CircleZones.KopiField.coords, true) < 50 then
				letSleep = false
				SpawnTanamanKopi()
            end
        end

        if GetDistanceBetweenCoords(coords, -1140.39, 2671.08, 18.22, true) < 3 then
			letSleep = false
			DrawMarker(39, -1140.39, 2671.08, 18.22, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.5, 102, 204, 102, 100, false, true, 2, false, false, false, false)
			RNRFunctions.drawtext('E - Mengambil Traktor (Kopi)')
			if IsControlJustReleased(0, 38) and onDutyKopi == 0 then 
				RNRFunctions.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					elseif skin.sex == 1 then
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
					end
				end)
				Citizen.Wait(500)
				RNRFunctions.SpawnVehicle(Config.VehicleSpawnFarm['Kopi'].Codespawn ,Config.VehicleSpawnFarm['Kopi'].CoordsCabe, Config.VehicleSpawnFarm['Kopi'].Heading, function(callback_vehicle)
					onDutyKopi = 1
					TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
				end)
			end
		else
			RNRFunctions.hidedraw()
        end
		if letSleep then 
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(kopiPlants) do
			DeleteObject(v)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
        Citizen.Wait(0)
        local letSleep = true
		local playerPed      = PlayerPedId()
		local coords         = GetEntityCoords(playerPed)
		local nextCheckPoint = CurrentCheckPointKopi + 1

		if onDutyKopi == 1 then 
			if CheckPointsKopi[nextCheckPoint] == nil then
				if DoesBlipExist(blipkopi) then
					RemoveBlip(blipkopi)
				end

				vehicle = GetVehiclePedIsIn(playerPed, false)
				DeleteVehicle(vehicle)
				onDutyKopi = 2
			else
				if CurrentCheckPointKopi ~= LastCheckPointKopi then
					if DoesBlipExist(blipkopi) then
						RemoveBlip(blipkopi)
					end

					blipkopi = AddBlipForCoord(CheckPointsKopi[nextCheckPoint].Pos.x, CheckPointsKopi[nextCheckPoint].Pos.y, CheckPointsKopi[nextCheckPoint].Pos.z)
					SetBlipRoute(blipkopi, 1)

					LastCheckPointKopi = CurrentCheckPointKopi
				end

				local distance = GetDistanceBetweenCoords(coords, CheckPointsKopi[nextCheckPoint].Pos.x, CheckPointsKopi[nextCheckPoint].Pos.y, CheckPointsKopi[nextCheckPoint].Pos.z, true)

				if distance <= 100.0 then
					DrawMarker(20, CheckPointsKopi[nextCheckPoint].Pos.x, CheckPointsKopi[nextCheckPoint].Pos.y, CheckPointsKopi[nextCheckPoint].Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.5, 102, 204, 102, 100, false, true, 2, false, false, false, false)
				end

				if distance <= 3 then
					vehicle = GetVehiclePedIsIn(playerPed, false)
					if GetHashKey(Config.VehicleSpawnFarm.Kopi) == GetEntityModel(vehicle) then
						CurrentCheckPointKopi = CurrentCheckPointKopi + 1
					end
				end
			end
			
		end
	end
end)

Citizen.CreateThread(function()
	while true do
        Citizen.Wait(0)
        local letSleep = true
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #kopiPlants, 1 do
			if GetDistanceBetweenCoords(coords, GetEntityCoords(kopiPlants[i]), false) < 1 then
				nearbyObject, nearbyID = kopiPlants[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then

			if not isPickingUp  then
				RNRFunctions.drawtext("E - Mengambil")
			end

			if IsControlJustReleased(0, Keys['E']) and not isPickingUp then
                if countcabutkopi >= 80 then 
                    onDutyKopi = 0
					countcabutkopi = 0
				else
					isPickingUp = true

					RNRFunctions.TriggerServerCallback('rw:canPickUp', function(canPickUp)
							if canPickUp then
								if lib.progressBar({
									duration = 2500,
									label = 'Memetik Daun Kopi',
									useWhileDead = true,
									canCancel = true,
									disable = {
										car = true,
									},
									anim = {
										dict = "creatures@rottweiler@tricks@",
										clip = "petting_franklin"
									},
								}) then
									DeleteObject(nearbyObject)
									table.remove(kopiPlants, nearbyID)
									spawnedKopi = spawnedKopi - 1
									countcabutkopi = countcabutkopi + 1
									TriggerServerEvent('rw:pickedUpKopi')
								else 
									RNRFunctions.CLNotify('Kamu Cancel', 'error')
								end
							else
								RNRFunctions.CLNotify('Melebihi Batas', 'error')
							end

						isPickingUp = false

					end, 'kopi')
				end
			end

		else
			RNRFunctions.hidedraw()
			Citizen.Wait(500)
		end

	end

end)

function SpawnTanamanKopi()
	while spawnedKopi < 30 do
		Citizen.Wait(0)
		local kopiCoords = GenerateKopiCoords()

		RNRFunctions.SpawnLocalObject(Config.PropFarm.Kopi, kopiCoords, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)

			table.insert(kopiPlants, obj)
			spawnedKopi = spawnedKopi + 1
		end)
	end
end

function ValidateKopiCoord(plantCoord)
	if spawnedKopi > 0 then
		local validate = true

		for k, v in pairs(kopiPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.KopiField.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateKopiCoords()
	while true do
		Citizen.Wait(1)

		local kopiCoordX, kopiCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-15, 15)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-15, 15)

		kopiCoordX = Config.CircleZones.KopiField.coords.x + modX
		kopiCoordY = Config.CircleZones.KopiField.coords.y + modY

		local coordZ = GetCoordZ(kopiCoordX, kopiCoordY)
		local coord = vector3(kopiCoordX, kopiCoordY, coordZ)

		if ValidateKopiCoord(coord) then
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 75.0, 76.0, 77.0, 78.0, 79.0, 80.0, 81.0, 82.0, 83.0, 84.0, 85.0}

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 76.00
end