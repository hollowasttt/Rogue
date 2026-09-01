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
	print("[PythonElite] FIRE EVENT RECEIVED")

	if not equippedTool then
		warn("[PythonElite] Fire called but no equippedTool")
		return
	end
	if os.clock() - lastShot < Config.FireRate then return end

	lastShot = os.clock()

	local camera = workspace.CurrentCamera
	if not camera then
		warn("[PythonElite] CurrentCamera yok")
		return
	end

	local yaw = (math.random() * 2 - 1) * Config.RecoilYaw
	print("[PythonElite] ADDING RECOIL", Config.RecoilPitch, yaw)
	CameraController.AddRecoil(Config.RecoilPitch, yaw)

	local remote = ReplicatedStorage:FindFirstChild("WeaponRemotes")
	remote = remote and remote:FindFirstChild("FireWeapon")
	if remote then
		remote:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
	else
		warn("[PythonElite] FireWeapon remote bulunamadı")
	end
end

local function bindTool(tool)
	if equippedTool == tool then return end
	disconnectAll()
	equippedTool = tool
	print("[PythonElite] TOOL BOUND", tool:GetFullName())

	table.insert(connections, tool.Activated:Connect(fire))
	table.insert(connections, tool.Equipped:Connect(function()
		equippedTool = tool
		print("[PythonElite] EQUIPPED", tool:GetFullName())
	end))
	table.insert(connections, tool.Unequipped:Connect(function()
		equippedTool = nil
		print("[PythonElite] UNEQUIPPED")
	end))
end

local function scan()
	local tool = getTool()
	if tool then
		bindTool(tool)
	else
		print("[PythonElite] TOOL NOT FOUND")
	end
end

function Controller.Init()
	print("[PythonElite] INIT")

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
