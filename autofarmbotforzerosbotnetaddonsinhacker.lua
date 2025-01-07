--by exechack.cc 
local originalAngles = nil

-- Retrieve a list of all controllers within a 1000 unit sphere around the player
local controllers = ents.FindInSphere(LocalPlayer():GetPos(), 1000)
local Controller = nil

-- Go through the list of found entities and select the first controller found
for _, ent in ipairs(controllers) do
    if ent:GetClass() == "zbf_controller" then
        Controller = ent
        break
    end
end

if Controller == nil then
    print("No controllers found within range!")
    return
end

local function SetEyeAnglesToBot(bot)
    local ang = (bot:GetPos() - LocalPlayer():GetShootPos()):Angle()
    originalAngles = LocalPlayer():EyeAngles()

    hook.Add("CreateMove", "LookAtBot", function(cmd)
        cmd:SetViewAngles(ang)
    end)
end

local function InteractWithBot(bot, action)
    print("Attempting to " .. action .. " bot: " .. tostring(bot))

    if action == "repair" then
        net.Start("zbf_Controller_Repair")
        net.WriteEntity(bot)
        net.SendToServer()
    else
        RunConsoleCommand("+use")
        timer.Simple(0.1, function() RunConsoleCommand("-use") end)
    end

    timer.Simple(0.1, function()
        if originalAngles then
            LocalPlayer():SetEyeAngles(originalAngles)
            originalAngles = nil
        end

        hook.Remove("CreateMove", "LookAtBot")
    end)
end

timer.Create("CheckBotErrorsAndHealth", 2, 0, function()
    local pos = LocalPlayer():GetPos()

    for _, bot in pairs(ents.FindInSphere(pos, 1000)) do
        if bot:GetClass() == "zbf_bot" then
            if zbf.Bot.HasError(bot) then
                print("Bot error detected: " .. tostring(bot))

                SetEyeAnglesToBot(bot)
                InteractWithBot(bot, "resolve")
            elseif bot:Health() < 25 then
                print("Low health bot detected: " .. tostring(bot))

                SetEyeAnglesToBot(bot)
                InteractWithBot(bot, "repair")
            end
        end
    end
end)

print("Starting the CheckControllerWallet timer...")

-- A timer that checks the controller's wallet capacity every 10 seconds
timer.Create("CheckControllerWallet", 10, 0, function()
    print("Checking the Controller wallet...")

    -- Get the current wallet value
    local walletValue = zbf.Wallet.GetMoneyValue(Controller)
    print("Current wallet value: " .. walletValue)

    -- Check if maximum capacity is reached
    if walletValue >= 50000 then
        print("Maximum wallet capacity reached. Sending Bitcoin to the vault...")
        -- Transfer the money to the vault
        net.Start("zbf_Wallet_SendToVault")
        net.WriteEntity(Controller)
        net.WriteUInt(2, 8) -- The ID of Bitcoin is 2
        net.SendToServer()
        print("Attempted to send Bitcoin to the vault.")
    else
        print("Wallet capacity not yet reached.")
    end
end)
