local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)

local player = Players.LocalPlayer
local CameraController = {}

local character, humanoid, root
local baseFov = 70
local currentFov = 70
local dashKick = 0

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

function CameraController.Init()
	local camera = workspace.CurrentCamera
	if camera then
		baseFov = camera.FieldOfView
		currentFov = baseFov
	end

	RunService.RenderStepped:Connect(function(deltaTime)
		camera = workspace.CurrentCamera
		if not camera or not humanoid or not root then return end

		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local horizontalSpeed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude

		-- Speed-based FOV: fast movement feels faster without changing the actual physics.
		local speedFov = math.clamp(horizontalSpeed * 0.055, 0, 12)
		local targetFov = baseFov + speedFov

		-- Short dash FOV kick.
		if not grounded and horizontalSpeed >= MovementConfig.DashSpeed * 0.85 then
			dashKick = math.min(dashKick + deltaTime * 35, 5)
		else
			dashKick = math.max(dashKick - deltaTime * 25, 0)
		end

		-- Slide gets a little more FOV than normal high-speed movement.
		local slideExtra = 0
		if humanoid.WalkSpeed == 0 and grounded then
			slideExtra = 4
		end

		targetFov += slideExtra + dashKick
		currentFov += (targetFov - currentFov) * math.clamp(deltaTime * 12, 0, 1)
		camera.FieldOfView = currentFov
	end)
end

return CameraController
