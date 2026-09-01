local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local VFX = {}

local character, root, humanoid
local lastVelocity = Vector3.zero
local wasSliding = false
local lastDashTime = 0

local function setup(char)
	character = char
	root = char:WaitForChild("HumanoidRootPart")
	humanoid = char:WaitForChild("Humanoid")
	lastVelocity = Vector3.zero
	wasSliding = false
end

if player.Character then setup(player.Character) end
player.CharacterAdded:Connect(setup)

local function makeAttachment(position)
	local attachment = Instance.new("Attachment")
	attachment.Position = position
	attachment.Parent = root
	Debris:AddItem(attachment, 0.35)
	return attachment
end

local function dashBurst()
	if not root then return end

	local velocity = root.AssemblyLinearVelocity
	if velocity.Magnitude < 40 then return end

	local direction = velocity.Unit
	local attachment = makeAttachment(Vector3.zero)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "DashBurst"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.08, 0.16)
	emitter.Speed = NumberRange.new(18, 35)
	emitter.Drag = 5
	emitter.SpreadAngle = Vector2.new(18, 18)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.25, 0.18),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.EmissionDirection = Enum.NormalId.Back
	emitter.Parent = attachment
	emitter:Emit(18)
	Debris:AddItem(emitter, 0.3)

	-- A thin neon streak trailing behind the dash.
	local streak = Instance.new("Part")
	streak.Name = "DashStreak"
	streak.Anchored = true
	streak.CanCollide = false
	streak.CanQuery = false
	streak.CanTouch = false
	streak.Material = Enum.Material.Neon
	streak.Transparency = 0.25
	streak.Size = Vector3.new(0.08, 0.08, math.clamp(velocity.Magnitude * 0.09, 2, 7))
	streak.CFrame = CFrame.lookAt(root.Position - direction * 1.5, root.Position - direction * 10)
	streak.Parent = workspace
	Debris:AddItem(streak, 0.09)
end

local function slideDust()
	if not root then return end

	local attachment = makeAttachment(Vector3.new(0, -2.4, 0))
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SlideDust"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.18, 0.35)
	emitter.Speed = NumberRange.new(5, 12)
	emitter.Drag = 8
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.35, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.7, 0.65),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment
	emitter:Emit(5)
	Debris:AddItem(emitter, 0.45)
end

function VFX.Init()
	RunService.Heartbeat:Connect(function()
		if not root or not humanoid then return end

		local velocity = root.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local sliding = humanoid.WalkSpeed == 0 and humanoid.FloorMaterial ~= Enum.Material.Air

		-- Detect a sudden high-speed acceleration as a dash trigger.
		if velocity.Magnitude > 80 and (velocity - lastVelocity).Magnitude > 45 then
			local now = os.clock()
			if now - lastDashTime > 0.12 then
				dashBurst()
				lastDashTime = now
			end
		end

		-- Dust begins when a slide starts and then lightly continues at speed.
		if sliding and not wasSliding then
			slideDust()
		elseif sliding and horizontalSpeed > 35 and math.random() < 0.18 then
			slideDust()
		end

		wasSliding = sliding
		lastVelocity = velocity
	end)
end

return VFX
