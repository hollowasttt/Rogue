local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)

local player = Players.LocalPlayer
local MovementController = {}

local canDash = true
local canSlide = true
local isSliding = false
local isDashing = false
local dashStartedAt = 0
local slideStartedAt = 0
local dashDirection = Vector3.zero

local character, humanoid, root

local function updateCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	isSliding = false
	isDashing = false
	canDash = true
	canSlide = true
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
	local dir = flat(humanoid.MoveDirection)
	if dir.Magnitude >= 0.1 then
		return dir.Unit
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
	dashStartedAt = os.clock()
	dashDirection = getMoveDirection()

	local velocity = root.AssemblyLinearVelocity
	local horizontal = flat(velocity)

	-- Add the dash to existing momentum instead of replacing it.
	-- This prevents a normal run from feeling like it suddenly hits a wall.
	local forwardSpeed = math.max(0, horizontal:Dot(dashDirection))
	local targetSpeed = MovementConfig.DashSpeed + forwardSpeed * 0.15
	local dashVelocity = dashDirection * targetSpeed

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
	if not canSlide or isSliding or isDashing or not root then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	local direction = getMoveDirection()
	local horizontal = flat(root.AssemblyLinearVelocity)
	local speed = horizontal.Magnitude

	-- Walking should be enough to start a slide; don't require a sprint system yet.
	if speed < MovementConfig.MinSpeedToSlide then
		speed = MovementConfig.WalkSpeed
	end

	isSliding = true
	canSlide = false
	slideStartedAt = os.clock()
	humanoid.WalkSpeed = 0

	local slideSpeed = math.max(speed, MovementConfig.SlideSpeed)
	root.AssemblyLinearVelocity = Vector3.new(
		direction.X * slideSpeed,
		root.AssemblyLinearVelocity.Y,
		direction.Z * slideSpeed
	)

	task.delay(MovementConfig.SlideCooldown, function()
		canSlide = true
	end)
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
	local horizontal = flat(velocity) * MovementConfig.SlideJumpBoost

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

		-- Keep the dash velocity alive for its short duration. Roblox's Humanoid
		-- controller can otherwise overwrite AssemblyLinearVelocity immediately.
		if isDashing then
			if os.clock() - dashStartedAt >= MovementConfig.DashDuration then
				isDashing = false
			else
				local velocity = root.AssemblyLinearVelocity
				local current = flat(velocity)
				local speed = math.max(MovementConfig.DashSpeed, current:Dot(dashDirection))
				local target = dashDirection * speed
				root.AssemblyLinearVelocity = Vector3.new(target.X, velocity.Y, target.Z)
			end
		end

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
