local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config.PythonEliteConfig)
local CameraController = require(script.Parent.CameraController)
local player = Players.LocalPlayer
local Controller = {}

local equippedTool
local connections = {}
local lastShot = 0

local function disconnectAll()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	equippedTool = nil
end

local function getTool()
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")

	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") and string.lower(child.Name) == string.lower(Config.ToolName) then
				return child
			end
		end
	end

	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") and string.lower(child.Name) == string.lower(Config.ToolName) then
				return child
			end
		end
	end
end

local function fire()
	if not equippedTool then return end
	if os.clock() - lastShot < Config.FireRate then return end

	lastShot = os.clock()

	local camera = workspace.CurrentCamera
	if not camera then return end

	-- Strong kick is handled by the shared camera controller.
	local yaw = (math.random() * 2 - 1) * Config.RecoilYaw
	CameraController.AddRecoil(Config.RecoilPitch, yaw)

	local remote = ReplicatedStorage:FindFirstChild("WeaponRemotes")
	remote = remote and remote:FindFirstChild("FireWeapon")
	if remote then
		remote:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
	end
end

local function bindTool(tool)
	if equippedTool == tool then return end
	disconnectAll()
	equippedTool = tool

	table.insert(connections, tool.Activated:Connect(fire))
	table.insert(connections, tool.Equipped:Connect(function()
		equippedTool = tool
	end))
	table.insert(connections, tool.Unequipped:Connect(function()
		equippedTool = nil
	end))
end

local function scan()
	local tool = getTool()
	if tool then
		bindTool(tool)
	end
end

function Controller.Init()
	player.CharacterAdded:Connect(function()
		disconnectAll()
		task.defer(scan)
	end)

	player:WaitForChild("Backpack").ChildAdded:Connect(function(child)
		if child:IsA("Tool") and string.lower(child.Name) == string.lower(Config.ToolName) then
			bindTool(child)
		end
	end)

	scan()
end

return Controller
