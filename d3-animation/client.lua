local menuOpen = false
local handsUp = false
local mp_pointing = false

local emotes = {
    ["handsup"] = "Hands Up",
    ["point"] = "Point",
    ["lean"] = "Hands Back"
}

RegisterNUICallback("selectEmote", function(data, cb)
    local emote = data.emote
    if emotes[emote] then
        TriggerEvent("emotewheel:playEmote", emote)
    end
    cb("ok")
end)

RegisterNUICallback("cancelEmote", function(_, cb)
    ClearPedTasks(PlayerPedId())
    handsUp = false
    if mp_pointing then stopPointing() end
    cb("ok")
end)

RegisterNUICallback("closeMenu", function(_, cb)
    closeMenu()
    cb("ok")
end)

RegisterNUICallback("closeWheel", function(_, cb)
    closeMenu()
    cb("ok")
end)

function openMenu()
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
end

function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

CreateThread(function()
    while true do
        Wait(0)

        if menuOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 289, true)

            if IsDisabledControlJustPressed(0, 25) then
                closeMenu()
            end
        end

        if IsControlJustPressed(0, 246) and not menuOpen then
            openMenu()
        end

        if IsControlJustPressed(0, 73) then
            local ped = PlayerPedId()
            ClearPedTasks(ped)
            ClearPedSecondaryTask(ped)
            handsUp = false
            if mp_pointing then stopPointing() end
            if menuOpen then closeMenu() end
        end
    end
end)

startPointing = function()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do Wait(0) end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    TaskMoveNetworkByName(ped, 'task_mp_pointing', 0.5, false, 'anim@mp_point', 24)
    RemoveAnimDict("anim@mp_point")

    mp_pointing = true
    CreateThread(function()
        while mp_pointing do
            local camPitch = GetGameplayCamRelativePitch()
            camPitch = math.clamp(camPitch, -70.0, 42.0)
            camPitch = (camPitch + 70.0) / 112.0

            local camHeading = GetGameplayCamRelativeHeading()
            camHeading = math.clamp(camHeading, -180.0, 180.0)
            local cosCamHeading = math.cos(camHeading)
            local sinCamHeading = math.sin(camHeading)
            camHeading = (camHeading + 180.0) / 360.0

            local coords = GetOffsetFromEntityInWorldCoords(ped,
                (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)),
                (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)),
                0.6)
            local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7)
            local _, blocked = GetRaycastResult(ray)

            SetTaskMoveNetworkSignalFloat(ped, "Pitch", camPitch)
            SetTaskMoveNetworkSignalFloat(ped, "Heading", camHeading * -1.0 + 1.0)
            SetTaskMoveNetworkSignalBool(ped, "isBlocked", blocked)
            SetTaskMoveNetworkSignalBool(ped, "isFirstPerson", GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
            Wait(1)
        end
    end)
end

stopPointing = function()
    local ped = PlayerPedId()
    RequestTaskMoveNetworkStateTransition(ped, 'Stop')
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(ped)
    mp_pointing = false
end

RegisterNetEvent("emotewheel:playEmote", function(emote)
    local ped = PlayerPedId()

    if emote == "handsup" then
        RequestAnimDict("missminuteman_1ig_2")
        while not HasAnimDictLoaded("missminuteman_1ig_2") do Wait(100) end
        if handsUp then
            handsUp = false
            ClearPedSecondaryTask(ped)
        else
            handsUp = true
            TaskPlayAnim(ped, "missminuteman_1ig_2", "handsup_base", 2.0, 2.5, -1, 49, 0, 0, 0, 0)
        end

    elseif emote == "point" then
        if mp_pointing then
            stopPointing()
        else
            startPointing()
        end

    elseif emote == "lean" then
        local dict = "anim@amb@world_human_valet@formal_right@base@"
        local anim = "base_a_m_y_vinewood_01"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    closeMenu()
end)
