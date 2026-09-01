local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementConfig = require(game:GetService("ReplicatedStorage").Shared.Config.MovementConfig)
local MovementController = require(script.Parent.MovementController)

local player = Players.LocalPlayer
local CameraController = {}

local humanoid
local root
local currentOffset = Vector3.zero
local currentFov = 70
local baseFov = 70
local dashKick = 0
local lastSpeed = 0

local function updateCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	currentOffset = Vector3.zero
	humanoid.CameraOffset = currentOffset
end

if player.Character then updateCharacter(player.Character) end
player.CharacterAdded:Connect(updateCharacter)

function CameraController.Init()
	RunService.RenderStepped:Connect(function(deltaTime)
		local camera = workspace.CurrentCamera
		if not camera or not humanoid or not root then return end

		if baseFov == 70 then
			baseFov = camera.FieldOfView
			currentFov = baseFov
		end

		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local sliding = MovementController.IsSliding()
		local horizontalSpeed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
		local speedDelta = horizontalSpeed - lastSpeed
		lastSpeed = horizontalSpeed

		-- Slide camera lowers smoothly and stays independent of WASD input.
		local targetOffset = sliding and MovementConfig.SlideCameraOffset or Vector3.zero
		local offsetAlpha = 1 - math.exp(-MovementConfig.SlideCameraSmoothness * deltaTime)
		currentOffset = currentOffset:Lerp(targetOffset, offsetAlpha)
		humanoid.CameraOffset = currentOffset

		-- Dynamic FOV scales with actual momentum. There is no speed cap here.
		local speedFov = math.clamp(horizontalSpeed * 0.055, 0, 14)
		local slideExtra = sliding and 4 or 0
		local targetFov = baseFov + speedFov + slideExtra

		-- A quick acceleration kick makes dash/landing feel more impactful.
		if speedDelta > 35 then
			dashKick = math.min(dashKick + math.clamp(speedDelta * 0.04, 0, 4), 6)
		else
			dashKick = math.max(dashKick - deltaTime * 22, 0)
		end

		if not grounded and horizontalSpeed > MovementConfig.DashSpeed * 0.85 then
			dashKick = math.min(dashKick + deltaTime * 8, 6)
		end

		targetFov += dashKick
		currentFov += (targetFov - currentFov) * math.clamp(deltaTime * 12, 0, 1)
		camera.FieldOfView = currentFov
	end)
end

return CameraController
