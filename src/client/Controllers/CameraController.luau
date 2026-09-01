local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementConfig = require(game:GetService("ReplicatedStorage").Shared.Config.MovementConfig)
local MovementController = require(script.Parent.MovementController)

local player = Players.LocalPlayer
local CameraController = {}

local humanoid
local currentOffset = Vector3.zero

local function updateCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	currentOffset = Vector3.zero
	humanoid.CameraOffset = currentOffset
end

if player.Character then
	updateCharacter(player.Character)
end
player.CharacterAdded:Connect(updateCharacter)

function CameraController.Init()
	RunService.RenderStepped:Connect(function(deltaTime)
		if not humanoid then return end

		local targetOffset = MovementController.IsSliding() and MovementConfig.SlideCameraOffset or Vector3.zero
		local alpha = 1 - math.exp(-MovementConfig.SlideCameraSmoothness * deltaTime)
		currentOffset = currentOffset:Lerp(targetOffset, alpha)
		humanoid.CameraOffset = currentOffset
	end)
end

return CameraController
