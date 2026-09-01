local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)

local player = Players.LocalPlayer
local MovementController = {}

local canDash = true
local isSliding = false
local isDashing = false
local slideStartedAt = 0

local character, humanoid, root

local function updateCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	isSliding = false
	isDashing = false
	canDash = true
	humanoid.WalkSpeed = MovementConfig.WalkSpeed
	humanoid.JumpPower = MovementConfig.JumpPower
end

if player.Character then
	updateCharacter(player.Character)
end
player.CharacterAdded:Connect(updateCharacter)

local function flat(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function getMoveDirection()
	local dir = humanoid.MoveDirection
	if dir.Magnitude >= 0.1 then
		return flat(dir).Unit
	end

	local look = flat(root.CFrame.LookVector)
	if look.Magnitude < 0.1 then
		return Vector3.new(0, 0, -1)
	end
	return look.Unit
end

local function dash()
	if not canDash or isDashing or not root then return end

	canDash = false
	isDashing = true

	local direction = getMoveDirection()
	local velocity = root.AssemblyLinearVelocity
	local horizontal = flat(velocity)

	-- Add a strong burst instead of replacing momentum. This keeps the dash fast and fluid.
	local dashVelocity = direction * MovementConfig.DashSpeed
	if horizontal:Dot(direction) > MovementConfig.DashSpeed then
		dashVelocity += horizontal * 0.35
	end

	root.AssemblyLinearVelocity = Vector3.new(
		dashVelocity.X,
		velocity.Y,
		dashVelocity.Z
	)

	task.delay(MovementConfig.DashDuration, function()
		isDashing = false
	end)

	task.delay(MovementConfig.DashCooldown, function()
		canDash = true
	end)
end

local function startSlide()
	if isSliding or isDashing or not root or humanoid.FloorMaterial == Enum.Material.Air then return end

	local horizontal = flat(root.AssemblyLinearVelocity)
	if horizontal.Magnitude < MovementConfig.MinSpeedToSlide then return end

	isSliding = true
	slideStartedAt = os.clock()
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
end

local function stopSlide()
	if not isSliding then return end

	isSliding = false
	humanoid.WalkSpeed = MovementConfig.WalkSpeed
	humanoid.JumpPower = MovementConfig.JumpPower
end

local function slideJump()
	if not isSliding or not root then return end

	local velocity = root.AssemblyLinearVelocity
	local horizontal = flat(velocity)
	if horizontal.Magnitude > 0 then
		horizontal *= MovementConfig.SlideJumpBoost
	end

	stopSlide()
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = Vector3.new(horizontal.X, MovementConfig.JumpPower, horizontal.Z)
end

function MovementController.Init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.Q then
			dash()
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			startSlide()
		elseif input.KeyCode == Enum.KeyCode.Space then
			slideJump()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftControl then
			stopSlide()
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		if not humanoid or not root or humanoid.Health <= 0 then return end

		if not isSliding then
			if humanoid.WalkSpeed ~= MovementConfig.WalkSpeed then
				humanoid.WalkSpeed = MovementConfig.WalkSpeed
			end
			return
		end

		if humanoid.FloorMaterial == Enum.Material.Air then
			stopSlide()
			return
		end

		if os.clock() - slideStartedAt >= MovementConfig.SlideDuration then
			stopSlide()
			return
		end

		local velocity = root.AssemblyLinearVelocity
		local horizontal = flat(velocity)
		local speed = horizontal.Magnitude

		if speed <= 2 then
			stopSlide()
			return
		end

		local friction = math.max(0, 1 - MovementConfig.SlideFriction * deltaTime)
		horizontal *= friction

		root.AssemblyLinearVelocity = Vector3.new(horizontal.X, velocity.Y, horizontal.Z)
	end)
end

return MovementController
