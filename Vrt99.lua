--warn("INITED")

function antiafk()
   print("Anti-Afk Inited.")
   game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Core["Server Closing"].Enabled = false
   game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
   game.Players.LocalPlayer.Idled:Connect(function(IdledTime)
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end
antiafk()


local RunService = game:GetService("RunService")

local closestBreakables = {}
local PetTable = {}
local petGroup = {}
local PlayerPet = require(game.ReplicatedStorage.Library.Client.PlayerPet)
local EggOpening = getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.Scripts.Game["Egg Opening Frontend"])
local noti = require(game:GetService("ReplicatedStorage").Library.Client.NotificationCmds)

local instancingcmds = require(game:GetService("ReplicatedStorage").Library.Client.InstancingCmds)
local instancingzonecmds = require(game:GetService("ReplicatedStorage").Library.Client.InstanceZoneCmds)

local customeggscmds = require(game:GetService("ReplicatedStorage").Library.Client.CustomEggsCmds)
local eggcmds = require(game:GetService("ReplicatedStorage").Library.Client.EggCmds)

local questTypes = require(game:GetService("ReplicatedStorage").Library.Types.Quests)

local save = require(game.ReplicatedStorage.Library.Client.Save).Get()

local instanceSettings
local instanceID
local instancefolder
local instancesEventFolder
local instanceName

local quests = {}

getgenv().Lib = {
   functionToggles = {
       AutoOrbs = false,
       ClickAura = false,
       ClickAuraVisualizer = false,
       OptimizeBreakables = false,
       OptimizePets = false,
       FastFarm = false,
       OpenClosestEgg = false,
       HideEggAnimation = false,
       HookEggAnimation = false,
       HugePetSpeed = false,
       FarmLastArea = false,
       BuyEventUpgrades = false,
       Rebirth = false,
   },
   functionsValues = {
       ClickAuraValue = 75,
       EggAnimation = EggOpening.PlayEggAnimation,
       PetSpeed = PlayerPet.CalculateSpeedMultiplier
   },
   functions = {
        CollectOrbs = function()
            for i, v in pairs(game:GetService("Workspace").__THINGS:FindFirstChild("Orbs"):GetChildren()) do
                game:GetService("ReplicatedStorage"):WaitForChild("Network"):FindFirstChild("Orbs: Collect"):FireServer(
                    unpack({[1] = {[1] = tonumber(v.Name)}})
                )
                v:Destroy()
            end
        end,
        ClickAura = function()
            local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
            for i, v in pairs(workspace.__THINGS.Breakables:GetChildren()) do
                if
                    (hrp.Position - v.WorldPivot.Position).Magnitude < getgenv().Lib.functionsValues.ClickAuraValue and
                        v:IsA("Model")
                    then
                    game:GetService("ReplicatedStorage").Network.Breakables_PlayerDealDamage:FireServer(v.Name)
                    break
                end
            end
        end,
        VisualizeClickAura = function(Range)
            if workspace:FindFirstChild("M") and getgenv().Lib.functionToggles.ClickAuraVisualizer then
                local part = workspace:FindFirstChild("M")
                part.Size = Vector3.new(0.2, Range * 2, Range * 2)
                part.Rotation = Vector3.new(0, 0, 90)
                return part
            elseif getgenv().Lib.functionToggles.ClickAuraVisualizer then
                local part = Instance.new("Part", workspace)
                part.Name = "M"
                part.CanCollide = false
                part.Anchored = true
                part.Shape = "Cylinder"
                part.Size = Vector3.new(0.2, Range * 2, Range * 2)
                part.Transparency = 0.5
                part.BrickColor = BrickColor.new("Light green (Mint)")
                part.Rotation = Vector3.new(0, 0, 90)
                return part
            end
        end,
        OptimizeBreakables = function()
            getgenv().Lib.OptimizeBreakables = workspace.__DEBRIS.ChildAdded:Connect(function(child)
                game.Debris:AddItem(child, 0)
            end)
        end,
        OptimizePets = function()
            for i, v in pairs(workspace.__THINGS.Pets:GetChildren()) do
                for ii, vv in pairs(v:GetDescendants()) do
                    if vv:IsA("Part") then
                        vv.Color = Color3.fromRGB(255, 255, 255)
                        vv.Size = Vector3.new(2.5, 2.5, 2.5)
                        vv.Material = Enum.Material.SmoothPlastic
                    end
                    if vv:IsA("SpecialMesh") or vv:IsA("ParticleEmitter") or vv:IsA("MeshPart") or vv:IsA("Decal") then
                        vv:Destroy()
                    end
                end
            end
        end,
        FastFarm = function()
            table.clear(petGroup)
            local coins = GetClosestBreakables(player)
            local pets = PlayerPets()

            for _, pet in pairs(pets) do
                local breakable = RandomCoinNumber(coins)
                petGroup[pet.Name] = breakable
            end

            local args = {[1] = petGroup}
            game:GetService("ReplicatedStorage").Network.Breakables_JoinPetBulk:FireServer(unpack(args))

            return coins
        end,
        OpenClosestEgg = function()
            local r = require(game:GetService("ReplicatedStorage").Library.Client.EggCmds)
            local maxhatch = r.GetMaxHatch()
            local CustomEgg, CustomeEggDistance = FindClosestCustomEgg()
            local NormalEgg, NormalEggDistance = FindClosestEgg()
            if CustomeEggDistance < NormalEggDistance then
                local args = {
                    [1] = tostring(CustomEgg),
                    [2] = maxhatch
                }

                local x, y, z =
                    game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("CustomEggs_Hatch"):InvokeServer(
                    unpack(args)
                )
            elseif NormalEggDistance < CustomeEggDistance then
                local args = {
                    [1] = NormalEgg,
                    [2] = maxhatch
                }

                local x, y, z =
                    game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Eggs_RequestPurchase"):InvokeServer(
                    unpack(args)
                )
            end
        end,
        HugePetSpeed = function()
            PlayerPet.CalculateSpeedMultiplier = function()
                return math.huge
            end
        end,
        HideEggAnimation = function()
            print("HIDING EGG ANIM 2")
            EggOpening.PlayEggAnimation = function()
                return
            end
        end,
        HookEggAnimation = function()
            EggOpening.PlayEggAnimation = getgenv().Lib.functionsValues.EggAnimation
            EggOpening.PlayEggAnimation = function(self, ...)
                local r = require(game:GetService("ReplicatedStorage").Library.Client.EggCmds)
                noti.Message.Bottom(
                    {
                        ["Message"] = "Still Openin " .. self .. " gang. " .. tostring(r.GetMaxHatch()),
                        ["Color"] = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
                    }
                )
                return
            end
        end,
        FarmEventZones = function()
            while not GetCurrentEventInstance() do
                local teleport = workspace.__THINGS.Instances[instanceName].Teleports.Enter
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = teleport.CFrame
                task.wait(0.5)
            end
            if GetEventMaximumZoneNumber() ~= MaxEventZone() then
                MakeQuest()
            else
                TeleportToEventZone(GetEventMaximumZoneNumber())
            end
        end,
        BuyEventUpgrades = function()
            local upgradesfolder = game:GetService("ReplicatedStorage").__DIRECTORY.EventUpgrades.Event[instanceName]:GetChildren()
            for i,v in pairs(upgradesfolder) do
                local split = string.split(v.Name, " | ")
                if split[2] then
                    local args = {
                        [1] = split[2]
                    }
                    
                    local x,y,z = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("EventUpgrades: Purchase"):InvokeServer(unpack(args))
                end
            end
        end,
        EnterValentineEvent = function()
            if not workspace.__THINGS.__INSTANCE_CONTAINER.Active:FindFirstChild("TowerTycoon") then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.__THINGS.Instances.TowerTycoon.Teleports.Enter.CFrame
            end
        end,
        FarmValentineZone = function()
            if workspace.__THINGS.__INSTANCE_CONTAINER.Active:FindFirstChild("TowerTycoon") and workspace.__THINGS.__INSTANCE_CONTAINER.Active.TowerTycoon.BREAK_ZONES:FindFirstChild("Tower_Zone_" .. game.Players.LocalPlayer.Name) then
                local distance = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - workspace.__THINGS.__INSTANCE_CONTAINER.Active.TowerTycoon.BREAK_ZONES:FindFirstChild("Tower_Zone_" .. game.Players.LocalPlayer.Name).Position).Magnitude
                if distance > 20 then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.__THINGS.__INSTANCE_CONTAINER.Active.TowerTycoon.BREAK_ZONES:FindFirstChild("Tower_Zone_" .. game.Players.LocalPlayer.Name).CFrame + Vector3.new(0,2,0)
                end
            end
        end,
        HatchBestIslandEgg = function()
            local highest = 0
            for i,v in pairs(workspace.__THINGS.Islands:GetChildren()) do
                if v.Name:match("Island") and v.Name:match(game.Players.LocalPlayer.Name) then
                    local split = v.Name:split("_")
                    if tonumber(split[2]) > tonumber(highest) then
                        highest = split[2]
                    end
                end
            end
            local distance = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - workspace.__THINGS.Islands:FindFirstChild("Island_" .. highest .. "_" .. game.Players.LocalPlayer.Name).WorldPivot.Position).Magnitude
            if distance > 20 then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.__THINGS.Islands:FindFirstChild("Island_" .. highest .. "_" .. game.Players.LocalPlayer.Name).WorldPivot.Position) + Vector3.new(0,5,0) --workspace.__THINGS.Islands:FindFirstChild("Island_" .. highest .. "_" .. game.Players.LocalPlayer.Name).Part.CFrame + Vector3.new(0,5,0)
            end
        end,
        CraftLoveGift = function()
            local args = {[1] = 10}
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("ValentinesMachine_Activate"):InvokeServer(unpack(args))            
        end,
        UseTowerBoosts = function()
            local save = require(game.ReplicatedStorage.Library.Client.Save).Get().Inventory.Consumable

            for _,Boost in pairs(save) do
                if Boost.id:match("Tower") then
                    local args = {
                        [1] = _,
                        [2] = 1
                    }
                    
                    game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Consumables_Consume"):InvokeServer(unpack(args))
                end
            end
        end,
        Rebirth = function()
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Tycoons: Request Rebirth"):InvokeServer()
        end,
   }
}

function RandomCoinNumber(coins)
   if #coins == 0 then
       return nil
   end
   local randIndex = math.random(1, #coins)
   return coins[randIndex]
end

function PlayerPets()
   table.clear(PetTable)
   local PetFolder = workspace.__THINGS.Pets
   for _, v in pairs(PetFolder:GetChildren()) do
       if v:IsA("Model") then
           table.insert(PetTable, v)
       end
   end
   return PetTable
end

function partunderplayer()
   local part = nil
   local position = nil

   if game.Players.LocalPlayer and game.Players.LocalPlayer.Character then
       local character = game.Players.LocalPlayer.Character
       local rootPart = character:FindFirstChild("HumanoidRootPart")

       if rootPart then
           local rayDirection = Vector3.new(0, -500, 0)
           local ray = Ray.new(rootPart.Position, rayDirection)

           part, position = game.Workspace:FindPartOnRay(ray, character)
       end
   end

   return part, position
end

function GetClosestBreakables()
   table.clear(closestBreakables)
   local breakables = workspace.__THINGS.Breakables:GetChildren()
   local playerPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position

   for _, v in pairs(breakables) do
       if v:IsA("Model") then -- and v:GetAttribute("BreakableID") == "Ice Block"
           local magnitude = (v.WorldPivot.Position - playerPos).Magnitude
           if magnitude < 100 then
               table.insert(closestBreakables, v.Name)
           end
       end
   end

   return closestBreakables
end

local world = require(game:GetService("ReplicatedStorage").Library.Util.WorldsUtil)
local eggsDirectory = game:GetService("ReplicatedStorage").__DIRECTORY.Eggs["Zone Eggs"][world.GetWorld()._id]

function FindClosestCustomEgg()
   local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
   local customeggs = workspace.__THINGS.CustomEggs
   local distance = math.huge
   local closest = nil
   for i, v in pairs(customeggs:GetChildren()) do
       if v:IsA("Model") then
           local mag = (hrp.Position - v.WorldPivot.Position).Magnitude
           if mag < distance then
               distance = mag
               closest = v
           end
       end
   end
   return closest, distance
end

function FindClosestEgg()
   local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
   local eggs = workspace.__THINGS.Eggs[world.GetEggsModelName()]
   local distance = math.huge
   local closest = nil
   for i, v in pairs(eggs:GetChildren()) do
       if v:IsA("Model") then
           local mag = (hrp.Position - v:FindFirstChild("Light").CFrame.Position).Magnitude
           if mag < distance then
               distance = mag
               closest = v
           end
       end
   end
   if not closest then
       return
   end
   local split = string.split(closest.Name, " ")
   local eggmodule
   for i, v in pairs(eggsDirectory:GetDescendants()) do
       if v.Name:match(split[1]) then
           eggmodule = v
           local eggname = string.split(v.Name, " ")
           if eggname[6] then -- check jezeli jajko ma 3 czesci
               closest = eggname[3] .. " " .. eggname[4] .. " " .. eggname[5] .. " " .. eggname[6] -- gowno jebane jebac egg :D
           elseif eggname[5] then -- check jezeli jajko ma 3 czesci
               closest = eggname[3] .. " " .. eggname[4] .. " " .. eggname[5] -- [3] to pierwszy odlam nazwy np. Christmas [4] to drugi np. Tree [5] to koncowka Egg finalnie: Christmas Tree Egg
           else
               closest = eggname[3] .. " " .. eggname[4] -- jezeli jajko nie ma 3 czesci w nazwie to tutaj [3] to Christmas a [4] to Egg czyli: Christmas Egg
           end
           break
       end
   end
   return closest, distance, eggmodule
end

if workspace.__THINGS.Breakables:FindFirstChild("Highlight") then
   workspace.__THINGS.Breakables:FindFirstChild("Highlight"):Destroy()
end

function MaxEventZone()
   if instancingcmds.Get() then
       return #instancingcmds.Get().instanceZones
   else
       return
   end
end

function GetCurrentEvent()
   local instances = instancingcmds.All()
   for i, v in pairs(instances) do
       if v:match("Event") then
           instanceName = v
       end
   end
end

GetCurrentEvent()

function GetCurrentEventInstance()
   local instance = instancingcmds.Get()
   if not instance then
       return false
   end
   instanceSettings = instance
   instanceID = instance.instanceID
   return true
end

function GetCurrentEventInstanceZones()
   return instanceSettings.instanceZones
end

function GetCurrentEventInstanceFolder()
   instancesEventFolder = workspace.__THINGS.Instances:FindFirstChild(instanceID)
   return instancesEventFolder
end

function GetEventMaximumZoneNumber()
   return instancingzonecmds.GetMaximumOwnedZoneNumber()
end

-- function GetClosestEventEgg()
--    local folder = workspace.__THINGS.CustomEggs
--    local distance = math.huge
--    local closest
--    for i, v in pairs(folder:GetChildren()) do
--        if v:IsA("Model") then
--            local mag = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Light.Position).Magnitude
--            if mag < distance then
--                distance = mag
--                closest = v
--            end
--        end
--    end
--    return closest
-- end

-- function GetClosestEggInfo()
--    return customeggscmds.Get(GetClosestEventEgg().Name)
-- end

-- function GetCurrentCoins()
--    return require(game:GetService("ReplicatedStorage").Library.Client.CurrencyCmds).Get("GameCoins")
-- end

function GetMaxHatchCount()
   return eggcmds.GetMaxHatch()
end

function GetEventZoneToBuy()
   local instanceZones = GetCurrentEventInstanceZones()
   local eventmaxzone = GetEventMaximumZoneNumber()
   if instanceZones[eventmaxzone] and instanceZones[eventmaxzone + 1] then
       return instanceZones[eventmaxzone], instanceZones[eventmaxzone + 1]
   end
   return nil
end

function BuyZone()
   local coins = GetCurrentCoins()
   local zone = GetEventZoneToBuy()
   local zonecost = zone.CurrencyCost
   local zonename = zone.DisplayName
   if coins >= zonecost then
       local args = {
           [1] = instanceID,
           [2] = GetEventMaximumZoneNumber() + 1
       }
       game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("InstanceZones_RequestPurchase"):InvokeServer(
           unpack(args)
       )
       return true
   else
       return false
   end
end

function GetQuestFromId(id)
   for i, v in pairs(questTypes.Goals) do
       if id == v then
           return i
       end
   end
end

function GetIdFromQuest(quest)
   for i, v in pairs(questTypes.Goals) do
       if quest == i then
           return v
       end
   end
end

function CurrentZoneQuest()
   table.clear(quests)
   local InstanceVars = save.InstanceVars[instanceID].QuestActive
   quests.progress = InstanceVars.Progress
   quests.type = InstanceVars.Type
   quests.amount = InstanceVars.Amount
   return quests
end

function MakeQuest()
   local questTable = CurrentZoneQuest()
   local quest = GetQuestFromId(questTable.type)
   local boughtzone
   if questTable.progress >= questTable.amount then
       boughtzone = BuyZone()
   end
   warn(quest)
   if quest == "RAINBOW_PET" then
       local inventory = save.Inventory.Pet
       for uid, pet in pairs(inventory) do
           local amount = pet._am or 1
           local rarity = pet.pt
           local shiny = pet.sh or false
           if not shiny and rarity == 1 and amount > questTable.amount * 10 then
               local args = {
                   [1] = uid,
                   [2] = questTable.amount + 2
               }

               game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("RainbowMachine_Activate"):InvokeServer(
                   unpack(args)
               )
           end
       end
   elseif quest == "BREAKABLE" th