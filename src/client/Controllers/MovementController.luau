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

if player.Character then updateCharacter(player.Character) end
player.CharacterAdded:Connect(updateCharacter)

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function getMoveDirection()
	local dir = flat(humanoid.MoveDirection)
	if dir.Magnitude >= 0.1 then return dir.Unit end
	local look = flat(root.CFrame.LookVector)
	return look.Magnitude >= 0.1 and look.Unit or Vector3.new(0, 0, -1)
end

local function dash()
	if not canDash or isDashing or isSliding or not root then return end

	canDash = false
	isDashing = true
	dashStartedAt = os.clock()

	-- Dash follows the camera's full 3D look direction. Looking up/down lets
	-- the player dash vertically instead of flattening the dash to the ground.
	local camera = workspace.CurrentCamera
	if camera then
		dashDirection = camera.CFrame.LookVector.Unit
	else
		dashDirection = getMoveDirection()
	end

	root.AssemblyLinearVelocity = dashDirection * MovementConfig.DashSpeed

	task.delay(MovementConfig.DashCooldown, function()
		canDash = true
	end)
end

local function startSlide()
	if isSliding or not root or humanoid.FloorMaterial == Enum.Material.Air then return end

	local horizontal = flat(root.AssemblyLinearVelocity)
	local speed = horizontal.Magnitude

	-- From rest, start slightly faster than walking. Otherwise preserve all
	-- existing horizontal momentum, including momentum coming from a dash.
	if speed < MovementConfig.SlideStartSpeed then
		slideVelocity = getMoveDirection() * MovementConfig.SlideStartSpeed
	else
		slideVelocity = horizontal
	end

	isSliding = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
end

local function stopSlide()
	if not isSliding then return end

	-- Preserve the final slide momentum when Ctrl is released.
	if root then
		local current = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(slideVelocity.X, current.Y, slideVelocity.Z)
	end

	isSliding = false
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
		if input.KeyCode == Enum.KeyCode.LeftShift then
			dash()
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			startSlide()
		elseif input.KeyCode == Enum.KeyCode.Space then
			slideJump()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftControl then stopSlide() end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		if not humanoid or not root or humanoid.Health <= 0 then return end

		if isDashing then
			if os.clock() - dashStartedAt >= MovementConfig.DashDuration then
				isDashing = false
			else
				-- Keep the full 3D dash vector alive for the duration of the burst.
				root.AssemblyLinearVelocity = dashDirection * MovementConfig.DashSpeed
			end
		end

		if not isSliding then
			if humanoid.WalkSpeed ~= MovementConfig.WalkSpeed then
				humanoid.WalkSpeed = MovementConfig.WalkSpeed
			end
			return
		end

		-- While sliding, Ctrl owns horizontal movement. WASD cannot cancel it.
		local speed = slideVelocity.Magnitude
		if speed > MovementConfig.SlideMinSpeed then
			local newSpeed = math.max(
				MovementConfig.SlideMinSpeed,
				speed * math.max(0, 1 - MovementConfig.SlideFriction * deltaTime)
			)
			slideVelocity = slideVelocity.Unit * newSpeed
		end

		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(slideVelocity.X, velocity.Y, slideVelocity.Z)
	end)
end

return MovementController
