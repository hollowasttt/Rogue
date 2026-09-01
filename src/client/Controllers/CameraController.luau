local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
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
local dashFlash = 0

-- Recoil is a purely visual camera-space offset.
-- We apply only the CHANGE since the previous frame, so the camera
-- never accumulates the recoil forever.
local recoilPitch = 0
local recoilYaw = 0
local recoilTargetPitch = 0
local recoilTargetYaw = 0

function CameraController.AddRecoil(pitch, yaw)
	recoilTargetPitch += pitch
	recoilTargetYaw += yaw
end

local function updateCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	currentOffset = Vector3.zero
	recoilPitch = 0
	recoilYaw = 0
	recoilTargetPitch = 0
	recoilTargetYaw = 0
	humanoid.CameraOffset = currentOffset
end

if player.Character then
	updateCharacter(player.Character)
end
player.CharacterAdded:Connect(updateCharacter)

function CameraController.Init()
	RunService:BindToRenderStep("RogueCameraController", Enum.RenderPriority.Last.Value, function(deltaTime)
		local camera = workspace.CurrentCamera
		if not camera or not humanoid or not root then return end

		if baseFov == 70 then
			baseFov = camera.FieldOfView
			currentFov = baseFov
		end

		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		local sliding = MovementController.IsSliding()
		local horizontalVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
		local horizontalSpeed = horizontalVelocity.Magnitude
		local speedDelta = horizontalSpeed - lastSpeed
		lastSpeed = horizontalSpeed

		local targetOffset = sliding and MovementConfig.SlideCameraOffset or Vector3.zero
		local offsetAlpha = 1 - math.exp(-MovementConfig.SlideCameraSmoothness * deltaTime)
		currentOffset = currentOffset:Lerp(targetOffset, offsetAlpha)
		humanoid.CameraOffset = currentOffset

		local speedFov = math.clamp(horizontalSpeed * 0.055, 0, 14)
		local slideExtra = sliding and 5 or 0
		local targetFov = baseFov + speedFov + slideExtra

		if speedDelta > 35 then
			dashKick = math.min(dashKick + math.clamp(speedDelta * 0.045, 0, 7), 8)
			dashFlash = math.min(dashFlash + 1, 1)
		else
			dashKick = math.max(dashKick - deltaTime * 22, 0)
		end

		if not grounded and horizontalSpeed > MovementConfig.DashSpeed * 0.85 then
			dashKick = math.min(dashKick + deltaTime * 6, 8)
		end

		dashFlash = math.max(dashFlash - deltaTime * 8, 0)
		targetFov += dashKick
		currentFov += (targetFov - currentFov) * math.clamp(deltaTime * 12, 0, 1)
		camera.FieldOfView = currentFov

		local roll = 0
		if horizontalSpeed > MovementConfig.WalkSpeed then
			local localVelocity = root.CFrame:VectorToObjectSpace(horizontalVelocity)
			roll = math.clamp(-localVelocity.X / 650, -0.035, 0.035)
		end

		if dashFlash > 0 then
			local shake = dashFlash * 0.7
			camera.CFrame *= CFrame.Angles(
				math.rad((math.random() - 0.5) * shake),
				math.rad((math.random() - 0.5) * shake),
				roll
			)
		else
			camera.CFrame *= CFrame.Angles(0, 0, roll)
		end

		-- Move the visual recoil target back to zero.
		-- Lower value = slower recoil recovery.
		local recovery = 1 - math.exp(-10 * deltaTime)
		recoilTargetPitch += -recoilTargetPitch * recovery
		recoilTargetYaw += -recoilTargetYaw * recovery

		-- Smoothly follow the target recoil.
		local follow = 1 - math.exp(-40 * deltaTime)
		local previousPitch = recoilPitch
		local previousYaw = recoilYaw
		recoilPitch += (recoilTargetPitch - recoilPitch) * follow
		recoilYaw += (recoilTargetYaw - recoilYaw) * follow

		-- Apply ONLY this frame's delta. This is the key difference:
		-- the camera is never permanently rotated by recoil.
		local pitchDelta = recoilPitch - previousPitch
		local yawDelta = recoilYaw - previousYaw
		camera.CFrame *= CFrame.Angles(math.rad(pitchDelta), math.rad(yawDelta), 0)

		if math.abs(recoilTargetPitch) < 0.0001 and math.abs(recoilPitch) < 0.0001 then
			recoilTargetPitch = 0
			recoilPitch = 0
		end
		if math.abs(recoilTargetYaw) < 0.0001 and math.abs(recoilYaw) < 0.0001 then
			recoilTargetYaw = 0
			recoilYaw = 0
		end
	end)
end

return CameraController