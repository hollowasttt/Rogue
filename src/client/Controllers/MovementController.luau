local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)

local player = Players.LocalPlayer

local MovementController = {}

local canDash = true
local canSlide = true
local isSliding = false
local isDashing = false

local character, humanoid, root

local function updateCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	isSliding = false
	isDashing = false
	canDash = true
	canSlide = true
end

if player.Character then
	updateCharacter(player.Character)
end
player.CharacterAdded:Connect(updateCharacter)

local function getMoveDirection()
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.1 then
		local look = root.CFrame.LookVector
		return Vector3.new(look.X, 0, look.Z).Unit
	end
	return dir
end

local function dash()
	if not canDash or isDashing or isSliding then return end
	if not root or humanoid.FloorMaterial == Enum.Material.Air then return end

	canDash = false
	isDashing = true

	local direction = getMoveDirection()
	root.AssemblyLinearVelocity = Vector3.new(
		direction.X * MovementConfig.DashSpeed,
		root.AssemblyLinearVelocity.Y,
		direction.Z * MovementConfig.DashSpeed
	)

	task.delay(MovementConfig.DashDuration, function()
		isDashing = false
	end)

	task.delay(MovementConfig.DashCooldown, function()
		canDash = true
	end)
end

local function startSlide()
	if not canSlide or isSliding or isDashing then return end
	if not root or humanoid.FloorMaterial == Enum.Material.Air then return end
	if root.AssemblyLinearVelocity.Magnitude < MovementConfig.MinSpeedToSlide then return end

	canSlide = false
	isSliding = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	local direction = getMoveDirection()
	root.AssemblyLinearVelocity = Vector3.new(
		direction.X * MovementConfig.SlideSpeed,
		root.AssemblyLinearVelocity.Y,
		direction.Z * MovementConfig.SlideSpeed
	)

	task.delay(MovementConfig.SlideDuration, function()
		if isSliding then
			isSliding = false
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		end
	end)

	task.delay(MovementConfig.SlideCooldown, function()
		canSlide = true
	end)
end

local function stopSlide()
	if not isSliding then return end
	isSliding = false
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
end

function MovementController.Init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.Q then
			dash()
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			startSlide()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftControl then
			stopSlide()
		end
	end)
end

return MovementController