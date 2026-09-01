local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config.PythonEliteConfig)

local remotes = ReplicatedStorage:FindFirstChild("WeaponRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "WeaponRemotes"
	remotes.Parent = ReplicatedStorage
end

local fireRemote = remotes:FindFirstChild("FireWeapon")
if not fireRemote then
	fireRemote = Instance.new("RemoteEvent")
	fireRemote.Name = "FireWeapon"
	fireRemote.Parent = remotes
end

local lastShot = {}

local function hasEquippedWeapon(player)
	local character = player.Character
	if not character then return false end
	local tool = character:FindFirstChild(Config.ToolName)
	return tool and tool:IsA("Tool")
end

fireRemote.OnServerEvent:Connect(function(player, clientOrigin, clientDirection)
	if typeof(clientOrigin) ~= "Vector3" or typeof(clientDirection) ~= "Vector3" then return end
	if clientDirection.Magnitude < 0.9 then return end
	if not hasEquippedWeapon(player) then return end

	local now = os.clock()
	if now - (lastShot[player] or 0) < Config.FireRate * 0.85 then return end
	lastShot[player] = now

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local origin = head and head.Position or clientOrigin
	local direction = clientDirection.Unit * Config.Range

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	if not result then return end

	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
	local targetHumanoid = hitModel and hitModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then return end

	local damage = Config.Damage
	if result.Instance.Name == "Head" then
		damage *= Config.HeadshotMultiplier
	end

	targetHumanoid:TakeDamage(damage)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShot[player] = nil
end)

return true
