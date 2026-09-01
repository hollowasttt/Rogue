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

-- Recoil is stored as a temporary camera rotation and ALWAYS decays back to zero.
local recoilPitch = 0
local recoilYaw = 0
local recoilPitchVelocity = 0
local recoilYawVelocity = 0

function CameraController.AddRecoil(pitch, yaw)
	-- Instant kick, followed by a damped return to the exact original aim.
	recoilPitchVelocity += pitch * 55
	recoilYawVelocity += yaw * 55
end

local function updateCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	currentOffset = Vector3.zero
	recoilPitch = 0
	recoilYaw = 0
	recoilPitchVelocity = 0
	recoilYawVelocity = 0
	humanoid.CameraOffset = currentOffset
end

if player.Character then updateCharacter(player.Character) end
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

		-- Apply recoil as a velocity impulse. The spring is critically damped,
		-- so both pitch and yaw return all the way to exactly zero.
		local stiffness = 170
		local damping = 25

		recoilPitchVelocity += -recoilPitch * stiffness * deltaTime
		recoilYawVelocity += -recoilYaw * stiffness * deltaTime

		local dampingFactor = math.exp(-damping * deltaTime)
		recoilPitchVelocity *= dampingFactor
		recoilYawVelocity *= dampingFactor

		recoilPitch += recoilPitchVelocity * deltaTime
		recoilYaw += recoilYawVelocity * deltaTime

		-- Prevent tiny floating-point remnants from keeping the camera offset.
		if math.abs(recoilPitch) < 0.001 and math.abs(recoilPitchVelocity) < 0.01 then
			recoilPitch = 0
			recoilPitchVelocity = 0
		end
		if math.abs(recoilYaw) < 0.001 and math.abs(recoilYawVelocity) < 0.01 then
			recoilYaw = 0
			recoilYawVelocity = 0
		end

		camera.CFrame *= CFrame.Angles(math.rad(recoilPitch), math.rad(recoilYaw), 0)
	end)
end

return CameraController
