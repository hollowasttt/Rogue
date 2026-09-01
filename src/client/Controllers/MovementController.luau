local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local player = Players.LocalPlayer
local MovementController = {}

local canDash, isSliding, isDashing, slideQueued = true, false, false, false
local dashStartedAt = 0
local dashDirection = Vector3.zero
local slideVelocity = Vector3.zero
local airMomentum = Vector3.zero
local character, humanoid, root

local function updateCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	canDash, isSliding, isDashing, slideQueued = true, false, false, false
	dashDirection, slideVelocity, airMomentum = Vector3.zero, Vector3.zero, Vector3.zero
	humanoid.WalkSpeed = MovementConfig.WalkSpeed
	humanoid.JumpPower = MovementConfig.JumpPower
end

if player.Character then updateCharacter(player.Character) end
player.CharacterAdded:Connect(updateCharacter)

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function getMoveDirection()
	local dir = flat(humanoid.MoveDirection)
	if dir.Magnitude >= 0.1 then return dir.Unit end
	local look = flat(root.CFrame.LookVector)
	return look.Magnitude >= 0.1 and look.Unit or Vector3.new(0, 0, -1)
end

local function dash()
	if not canDash or isDashing or isSliding or not root then return end
	canDash, isDashing, dashStartedAt = false, true, os.clock()
	local camera = workspace.CurrentCamera
	dashDirection = camera and camera.CFrame.LookVector.Unit or getMoveDirection()
	root.AssemblyLinearVelocity = dashDirection * MovementConfig.DashSpeed
	task.delay(MovementConfig.DashCooldown, function() canDash = true end)
end

local function startSlide()
	if isSliding or not root then return false end
	if humanoid.FloorMaterial == Enum.Material.Air then
		slideQueued = true
		return false
	end

	local horizontal = flat(root.AssemblyLinearVelocity)
	local speed = horizontal.Magnitude
	if speed < MovementConfig.SlideStartSpeed then
		slideVelocity = getMoveDirection() * MovementConfig.SlideStartSpeed
	else
		slideVelocity = horizontal
	end

	isSliding, slideQueued = true, false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	return true
end

local function stopSlide()
	if not isSliding then return end
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

function MovementController.IsSliding() return isSliding end

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
		if input.KeyCode == Enum.KeyCode.LeftControl then
			slideQueued = false
			stopSlide()
		end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		if not humanoid or not root or humanoid.Health <= 0 then return end

		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

		-- Keep air momentum independent from Humanoid.WalkSpeed. WalkSpeed is only
		-- used for normal ground movement; it must never bleed off a faster jump.
		if not grounded and not isSliding and not isDashing then
			local horizontal = flat(root.AssemblyLinearVelocity)
			if horizontal.Magnitude > MovementConfig.WalkSpeed then
				airMomentum = horizontal
			end

			if airMomentum.Magnitude > MovementConfig.WalkSpeed then
				local inputDirection = flat(humanoid.MoveDirection)
				if inputDirection.Magnitude > 0.1 then
					local airControl = MovementConfig.AirControl or 0.35
					local steer = inputDirection.Unit * airMomentum.Magnitude
					airMomentum = airMomentum:Lerp(steer, math.clamp(airControl * deltaTime, 0, 1))
				end
				local velocity = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(airMomentum.X, velocity.Y, airMomentum.Z)
			end
		elseif grounded and not isSliding and not isDashing then
			airMomentum = Vector3.zero
		end

		if isDashing then
			if os.clock() - dashStartedAt >= MovementConfig.DashDuration then
				isDashing = false
			else
				root.AssemblyLinearVelocity = dashDirection * MovementConfig.DashSpeed
			end
		end

		-- Holding Ctrl in the air buffers the slide until the exact landing frame.
		if slideQueued and not isSliding and grounded then
			startSlide()
		end

		if isSliding then
			local speed = slideVelocity.Magnitude
			if speed > MovementConfig.SlideMinSpeed then
				local newSpeed = math.max(MovementConfig.SlideMinSpeed, speed * math.max(0, 1 - MovementConfig.SlideFriction * deltaTime))
				slideVelocity = slideVelocity.Unit * newSpeed
			end
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(slideVelocity.X, velocity.Y, slideVelocity.Z)
		elseif humanoid.WalkSpeed ~= MovementConfig.WalkSpeed then
			humanoid.WalkSpeed = MovementConfig.WalkSpeed
		end
	end)
end

return MovementController
