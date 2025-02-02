local ox_inventory = exports.ox_inventory
local spawnedChickenAlive = 0
local Chickens = {}

RegisterNetEvent('rw:spawnayam')
AddEventHandler('rw:spawnayam', function()
	SpawnChickens()
end)

CreateThread(function()
	while true do
		local inRange = false
		local coords = GetEntityCoords(cache.ped)
		local distance = #(coords - Config.ChickenField)

		if distance < 50 then
			SpawnChickens()
			Wait(500)
			inRange = true
		end

		if not inRange then 
			Wait(1000)
		end
		Wait(500)
	end
end)

RegisterNetEvent("rnr_chicken:catch")
AddEventHandler("rnr_chicken:catch", function()
    local dead = false
    local plyCoords = GetEntityCoords(PlayerPedId())

    -- Loop untuk mencari ped terdekat
    local closestAnimal = -1
    local closestDistance = 9999 -- Set jarak awal sangat jauh

    for _, ped in ipairs(Chickens) do
        local pedCoords = GetEntityCoords(ped)
        local dist = #(plyCoords - pedCoords) -- Menghitung jarak antara player dan ped

        if dist < closestDistance then
            closestDistance = dist
            closestAnimal = ped
        end
    end

    if Config.Debug then
        print("Closest animal:", closestAnimal)
        print("Closest distance:", closestDistance)
    end

    if closestAnimal ~= -1 and closestDistance <= 2.0 then
        if Config.Debug then
            print("Entity Health:", GetEntityHealth(closestAnimal))
            print("Entity Source of Death:", GetPedSourceOfDeath(closestAnimal))
        end
        if GetPedType(closestAnimal) == 28 then
            local health = GetEntityHealth(closestAnimal)
            if health <= 0 then
                if GetPedSourceOfDeath(closestAnimal) == PlayerPedId() then
                    print("Chicken is dead and killed by player.")
                    dead = true
                else
                    if Config.Debug then
                        print("Chicken is dead but not killed by player.")
                    end
                end
            else
                if Config.Debug then
                    print("Chicken is still alive with health:", health)
                end
            end
        end

        -- Lakukan proses jika ayam mati
        if dead then
            local attempt = 0
            while not NetworkHasControlOfEntity(closestAnimal) and attempt < 10 and DoesEntityExist(closestAnimal) do
                Wait(100)
                NetworkRequestControlOfEntity(closestAnimal)
                attempt = attempt + 1
            end

            local netid = NetworkGetNetworkIdFromEntity(closestAnimal)
            if DoesEntityExist(closestAnimal) and NetworkHasControlOfNetworkId(netid) then
                local ent = Entity(NetworkGetEntityFromNetworkId(netid))
                if lib.progressBar({
                    duration = 1500,
                    label = "Pick up",
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        move = true,
                        car = true,
                        combat = false,
                    },
                    anim = {
                        dict = "random@domestic",
                        clip = "pickup_low",
                        flags = 49,
                    },
                }) then 
                    ClearPedTasksImmediately(PlayerPedId())
                    isButchering = false
                    for k, v in pairs(Config.Items['TakeChicken'].Take) do
                        lib.callback.await('rnr_jobs:server:item_add', false, {
                            item = v.item,
                            amount = v.amount
                        })
                        if Config.Debug then
                            print('Ayam Potong: '..v.item..' x '..v.amount..' berhasil diambil')
                        end
                    end
                    Wait(150)
                    SetEntityAsMissionEntity(closestAnimal, true, true)
                    SetEntityAsNoLongerNeeded(closestAnimal)
                    DeleteEntity(closestAnimal)
                    table.remove(Chickens, nearbyID)
                    spawnedChickenAlive = spawnedChickenAlive - 1
                    if Config.Debug then
                        print('sisa di ladang' .. spawnedChickenAlive)
                    end
                 else
                    if Config.Debug then
                        print('Do stuff when cancelled')
                    end
                 end
            end
        else
            RNRFunctions.ShowHelpNotification(Config.Locales.Notify['chicken_not_dead'], "error")
        end
    else
        if Config.Debug then
            print("No chicken nearby or too far away.")
        end
    end
end)

function SpawnChickens()
    while spawnedChickenAlive < 5 do
        Wait(0)
        local rnr_model = 'a_c_hen'
        local chickenCoords = GenerateChickenAliveCoords()
        lib.requestModel(rnr_model, 5000) -- Meminta model dengan timeout (dalam ms)
        local Animal = CreatePed(5, rnr_model, chickenCoords, 0.0, true, false)
        SetEntityAsMissionEntity(Animal, false, false)
        TaskWanderStandard(Animal, 10.0, 10) -- 10.0 adalah radius bergerak, 10 adalah durasi
        table.insert(Chickens, Animal)
        spawnedChickenAlive = spawnedChickenAlive + 1
    end
end

function ValidateChickenAliveCoord(chickenCoord)
	if spawnedChickenAlive > 0 then
		local validate = true

		for k, v in pairs(Chickens) do
			if GetDistanceBetweenCoords(chickenCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(chickenCoord, Config.ChickenField, false) > 50 then
			validate = false
		end
		return validate
	else
		return true
	end
end

function GenerateChickenAliveCoords()
	while true do
		Wait(1)

		local chickenCordX, chickenCordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-5, 5)

		Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-5, 5)

		chickenCordX = Config.ChickenField.x + modX
		chickenCordY = Config.ChickenField.y + modY

		local coordZ = GetCoordZChicken(chickenCordX, chickenCordY)
		local coord = vector3(chickenCordX, chickenCordY, coordZ)

		if ValidateChickenAliveCoord(coord) then
			return coord
		end
	end
end

function GetCoordZChicken(x, y)
	local groundCheckHeights = { 50, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0, 59.0, 60.0 }
	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end
	return 53.85
end

RegisterNetEvent('rnr_chicken:Process', function()
	potongAyam()
end)

RegisterNetEvent('rnr_chicken:Process2', function()
	potongAyam()
end)

function potongAyam()
    for k, v in pairs(Config.Items['CutChicken'].Needed) do
        local a = ox_inventory:Search('count', v.item)
        if a < v.amount then
            RNRFunctions.ShowHelpNotification(string.format(Config.Locales.Notify['not_item']..'%s (x%d)', ox_inventory:Items()[v.item].label), "info")
            RNRFunctions.ShowHelpNotification(string.format(Config.Locales.Notify['required']..'%s', v.amount), "info")
            return
        end
    end

    Wait(200)
    local minigame = false
    if Config.Lokasi['CutChicken'].minigame then
        minigame = exports.ox_lib:skillCheck(Config.Lokasi['CutChicken'].minigame)
    else
        minigame = true
    end
    if not minigame then return end

    local plyCoords = GetEntityCoords(cache.ped)
    local propKnife = CreateObject('prop_knife',plyCoords.x, plyCoords.y,plyCoords.z, true, true, true)
    AttachEntityToEntity(propKnife, cache.ped, GetPedBoneIndex(cache.ped, 0xDEAD), 0.13, 0.14, 0.09, 40.0, 0.0, 0.0, false, false, false, false, 2, true)
    if lib.progressBar({
        duration = 10000,
        label = 'Memotong Ayam',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'anim@amb@business@coc@coc_unpack_cut_left@',
            clip = 'coke_cut_v1_coccutter'
        }
    }) then
        for k, v in pairs(Config.Items['CutChicken'].Needed) do
            lib.callback.await('rnr_jobs:server:item_remove', false, {
                item = v.item,
                amount = v.amount
            })
            if Config.Debug then
                print('Ayam Potong: '..v.item..' x '..v.amount..' berhasil diambil')
            end
        end
        for k, v in pairs(Config.Items['CutChicken'].Take) do
            lib.callback.await('rnr_jobs:server:item_add', false, {
                item = v.item,
                amount = v.amount
            })
            if Config.Debug then
                print('Ayam Potong: '..v.item..' x '..v.amount..' berhasil ditambah')
            end
        end
        DeleteEntity(propKnife)
    else
        DeleteEntity(propKnife)
    end
end

RegisterNetEvent('rnr_chicken:Pack')
AddEventHandler('rnr_chicken:Pack', function(rnr_heading)
	packAyam(rnr_heading)
end)

function packAyam(heading)
    for k, v in pairs(Config.Items['ChickenPacking'].Needed) do
        local a = ox_inventory:Search('count', v.item)
        if a < v.amount then
            RNRFunctions.ShowHelpNotification(string.format(Config.Locales.Notify['not_item']..'%s (x%d)', ox_inventory:Items()[v.item].label), "info")
            RNRFunctions.ShowHelpNotification(string.format(Config.Locales.Notify['required']..'%s', v.amount), "info")
            return
        end
    end

    local minigame = false
    if Config.Lokasi['ChickenPacking'].minigame then
        minigame = exports.ox_lib:skillCheck(Config.Lokasi['CutChicken'].minigame)
    else
        minigame = true
    end
    if not minigame then return end

    local PedCoords = GetEntityCoords(cache.ped)
    SetEntityHeading(cache.ped, heading)
    local meatProp = CreateObject('prop_cs_steak', PedCoords.x, PedCoords.y,PedCoords.z, true, true, true)
    AttachEntityToEntity(meatProp, cache.ped, GetPedBoneIndex(cache.ped, 0x49D9), 0.15, 0.0, 0.01, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

    local boxProp = CreateObject('prop_cs_clothes_box',PedCoords.x, PedCoords.y,PedCoords.z, true, true, true)
    AttachEntityToEntity(boxProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.13, 0.0, -0.16, 250.0, -30.0, 0.0, false, false, false, false, 2, true)
    if lib.progressBar({
        duration = 7000,
        label = 'Mengemas Ayam',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@ornate_bank@grab_cash_heels',
            clip = 'grab'
        }
    }) then
        for k, v in pairs(Config.Items['ChickenPacking'].Needed) do
            lib.callback.await('rnr_jobs:server:item_remove', false, {
                item = v.item,
                amount = v.amount
            })
            if Config.Debug then
                print('Ayam Potong: '..v.item..' x '..v.amount..' berhasil diambil')
            end
        end
        for k, v in pairs(Config.Items['ChickenPacking'].Take) do
            lib.callback.await('rnr_jobs:server:item_add', false, {
                item = v.item,
                amount = v.amount
            })
            if Config.Debug then
                print('Ayam Potong: '..v.item..' x '..v.amount..' berhasil ditambah')
            end
        end
        DeleteEntity(meatProp)
        DeleteEntity(boxProp)
    else
        DeleteEntity(meatProp)
        DeleteEntity(boxProp)
    end
end