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
local dashStartedAt = 0
local slideStartedAt = 0
local dashDirection = Vector3.zero
local slideVelocity = Vector3.zero

local character, humanoid, root

local function updateCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	isSliding = false
	isDashing = false
	canDash = true
	dashDirection = Vector3.zero
	slideVelocity = Vector3.zero
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
	if not canDash or isDashing or isSliding or not root then return end

	canDash = false
	isDashing = true
	dashStartedAt = os.clock()
	dashDirection = getMoveDirection()

	local velocity = root.AssemblyLinearVelocity
	local horizontal = flat(velocity)
	local forwardSpeed = math.max(0, horizontal:Dot(dashDirection))
	local dashSpeed = MovementConfig.DashSpeed + forwardSpeed * 0.15
	local dashVelocity = dashDirection * dashSpeed

	root.AssemblyLinearVelocity = Vector3.new(dashVelocity.X, velocity.Y, dashVelocity.Z)

	task.delay(MovementConfig.DashCooldown, function()
		canDash = true
	end)
end

local function startSlide()
	if isSliding or isDashing or not root then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	local horizontal = flat(root.AssemblyLinearVelocity)
	local speed = horizontal.Magnitude
	if speed < MovementConfig.MinSpeedToSlide then return end

	-- Preserve exactly the momentum we had when entering the slide.
	slideVelocity = horizontal
	isSliding = true
	slideStartedAt = os.clock()
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
end

local function stopSlide()
	if not isSliding then return end
	isSliding = false
	slideVelocity = Vector3.zero
	humanoid.WalkSpeed = MovementConfig.WalkSpeed
	humanoid.JumpPower = MovementConfig.JumpPower
end

local function slideJump()
	if not isSliding or not root then return end

	local velocity = slideVelocity * MovementConfig.SlideJumpBoost
	stopSlide()
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, MovementConfig.JumpPower, velocity.Z)
end

function MovementController.IsSliding()
	return isSliding
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

		-- During dash, continuously restore the burst velocity. This prevents
		-- the grounded Humanoid controller from immediately braking the player.
		if isDashing then
			if os.clock() - dashStartedAt >= MovementConfig.DashDuration then
				isDashing = false
			else
				local velocity = root.AssemblyLinearVelocity
				local currentForward = flat(velocity):Dot(dashDirection)
				local speed = math.max(MovementConfig.DashSpeed, currentForward)
				root.AssemblyLinearVelocity = Vector3.new(
					dashDirection.X * speed,
					velocity.Y,
					dashDirection.Z * speed
				)
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

		-- Slide is independent of WASD. Releasing W cannot kill momentum.
		-- Friction slowly reduces the captured velocity over time.
		local friction = math.max(0, 1 - MovementConfig.SlideFriction * deltaTime)
		slideVelocity *= friction

		if slideVelocity.Magnitude <= MovementConfig.SlideMinSpeed then
			stopSlide()
			return
		end

		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(
			slideVelocity.X,
			velocity.Y,
			slideVelocity.Z
		)
	end)
end

return MovementController
