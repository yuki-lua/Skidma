--NotHm.. on youtube, and nothm_ on discord
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yuki-lua/Skidma/main/sigma5/LibraryPC.lua", true))()
local CoreGui = game:WaitForChild("CoreGui")
local Player = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = game.Players.LocalPlayer
local TeamsService = game:GetService("Teams")
local Camera = game:GetService("Workspace").CurrentCamera
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local KnitClient = debug.getupvalue(require(localPlayer.PlayerScripts.TS.knit).setup, 6)
local Client = require(ReplicatedStorage.TS.remotes).default.Client
local ClientStore = require(localPlayer.PlayerScripts.TS.ui.store).ClientStore
local KnockbackCont = debug.getupvalue(require(ReplicatedStorage.TS.damage["knockback-util"]).KnockbackUtil.calculateKnockbackVelocity, 1)
local SprintCont = KnitClient.Controllers.SprintController
local SwordCont = KnitClient.Controllers.SwordController
local BlockHit = ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].node_modules["@rbxts"].net.out._NetManaged.DamageBlock

local function isAlive(player)
	return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("Humanoid").Health > 0
end

local TeamCheck = false
local function GetNearestPlr(range)
	local nearestPlayer
	local nearestDistance = math.huge
	local localPlayer = game.Players.LocalPlayer

	for _, player in ipairs(game.Players:GetPlayers()) do
		if isAlive(player) and player ~= localPlayer and isAlive(localPlayer) then
			if not TeamCheck or player.Team ~= localPlayer.Team then
				local playerHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local localHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
				if playerHRP and localHRP then
					local distance = (playerHRP.Position - localHRP.Position).magnitude
					if distance < nearestDistance and distance <= range then
						nearestPlayer = player
						nearestDistance = distance
					end
				end
			end
		end
	end
	return nearestPlayer
end

local function GetBed(range)
	local nearestBed
	local nearestDistance = math.huge
	local localPlayer = game.Players.LocalPlayer

	for _, v in pairs(game.Workspace:GetChildren()) do
		if v.Name == "bed" and v.Covers.BrickColor ~= localPlayer.Team.TeamColor then
			local distance = (v.Position - localPlayer.Character.HumanoidRootPart.Position).magnitude
			if distance < nearestDistance and distance <= range then
				nearestBed = v
				nearestDistance = distance
			end
		end
	end
	return nearestBed
end

local function GetMatchState()
	return ClientStore:getState().Game.matchState
end

function getQueueType()
	local MatchState = ClientStore:getState()
	return MatchState.Game.queueType or "bedwars_test"
end

local function SetHotbar(item)
	if localPlayer.Character:FindFirstChild("HandInvItem").Value ~= item then
		local Inventories = game:GetService("ReplicatedStorage").Inventories:FindFirstChild(localPlayer.Name):FindFirstChild(item)

		ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.SetInvItem:InvokeServer({["hand"] = item})
	end
end

local function Value2Vector(vec)
	return { value = vec }
end

local MeleeRank = {
	[1] = { Name = "wood_sword", Rank = 1 },
	[2] = { Name = "stone_sword", Rank = 2 },
	[3] = { Name = "iron_sword", Rank = 3 },
	[4] = { Name = "diamond_sword", Rank = 4 },
	[5] = { Name = "void_sword", Rank = 5 },
	[6] = { Name = "emerald_sword", Rank = 6 },
	[7] = { Name = "rageblade", Rank = 7 },
}
function GetAttackPos(plrpos, nearpost, val)
	local newPos = (nearpost - plrpos).Unit * math.min(val, (nearpost - plrpos).Magnitude) + plrpos
	return newPos
end

local function GetMelee()
	local bestsword = nil
	local bestrank = 0
	for i, v in pairs(localPlayer.Character.InventoryFolder.Value:GetChildren()) do
		if v.Name:match("sword") or v.Name:match("blade") then
			for _, data in pairs(MeleeRank) do
				if data["Name"] == v.Name then
					if bestrank <= data["Rank"] then
						bestrank = data["Rank"]
						bestsword = v
					end
				end
			end
		end
	end
	return bestsword
end
--CreatingUI
Library:createScreenGui()
--Tabs
local GuiTab = Library:CreateTab("Gui")
local CombatTab = Library:CreateTab("Combat")
local RenderTab = Library:CreateTab("Render")
local PlayerTab = Library:CreateTab("Player")
local WorldTab = Library:CreateTab("World")
--Notification
CreateNotification("Loader", "Loaded Successfully", 3, true)
--ActiveMods
local ActiveMods = GuiTab:CreateToggle({
	Name = "ActiveMods",
	Description = "Render active mods",
	callback = function(enabled)
		CoreGui.SigmaVisualStuff.ArrayListHolder.Visible = not CoreGui.SigmaVisualStuff.ArrayListHolder.Visible
	end
})
--TabGUI
local TabGUI = GuiTab:CreateToggle({
	Name = "TabGUI",
	Description = "Just decorations",
	callback = function(enabled)
		CoreGui.SigmaVisualStuff.LeftHolder.TabHolder.Visible = not CoreGui.SigmaVisualStuff.LeftHolder.TabHolder.Visible
	end
})
--DeleteGui
local BlurEffect = Lighting:FindFirstChild("Blur")
local DeleteGui = GuiTab:CreateToggle({
	Name = "DeleteGUI",
	Description = "Does not uninject",
	callback = function(enabled)
		if enabled then
			BlurEffect:Destroy()
			CoreGui.sigma5:Destroy()
			print("Destroyed Main")
			CoreGui.sigma5Visual:Destroy()
			print("Destroyed Notif")
		end
	end
})
--Aimbot
local AimbotRange
local Aimbot = CombatTab:CreateToggle({
	Name = "Aimbot",
	Description = "Automatically aim at players",
	callback = function(enabled)
		if enabled then
			AimbotRange = 20
			while enabled do
				local NearestPlayer = GetNearestPlr(AimbotRange)
				if NearestPlayer and isAlive(NearestPlayer) and isAlive(localPlayer) then
					local direction = (NearestPlayer.Character.HumanoidRootPart.Position - Camera.CFrame.Position).unit
					local newLookAt = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
					Camera.CFrame = newLookAt
				end
				wait(0.01)
			end
		else
			AimbotRange = 0
		end
	end
})
local AimbotRangeCustom = Aimbot:CreateSlider({
	title = "Range",
	min = 0,
	max = 20,
	default = 20,
	callback = function(val)
		AimbotRange = val
	end
})
--AntiKnockback
local OriginalH = KnockbackCont.kbDirectionStrength
local OriginalY = KnockbackCont.kbUpwardStrength
local AntiKnockback = CombatTab:CreateToggle({
	Name = "AntiKnockback",
	Description = "Prevent you from taking knockback",
	callback = function(enabled)
		if enabled then
			KnockbackCont.kbDirectionStrength = 0
			KnockbackCont.kbUpwardStrength = 0
		else
