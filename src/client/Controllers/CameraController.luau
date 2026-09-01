local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementConfig = require(game:GetService("ReplicatedStorage").Shared.Config.MovementConfig)
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

-- Weapon recoil is handled here so it is applied after Roblox's camera update.
local recoilPitch = 0
local recoilYaw = 0
local targetRecoilPitch = 0
targetRecoilPitch = 0
local targetRecoilYaw = 0

function CameraController.AddRecoil(pitch, yaw)
	targetRecoilPitch += pitch
	targetRecoilYaw += yaw
end

local function updateCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	currentOffset = Vector3.zero
	recoilPitch = 0
	recoilYaw = 0
	targetRecoilPitch = 0
	targetRecoilYaw = 0
	humanoid.CameraOffset = currentOffset
end

if player.Character then updateCharacter(player.Character) end
player.CharacterAdded:Connect(updateCharacter)

function CameraController.Init()
	RunService:BindToRenderStep("RogueCameraController", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
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

		-- Fast kick, then smooth recovery. We apply only the frame-to-frame delta,
		-- so the recoil never compounds into an uncontrollable camera rotation.
		local kickAlpha = 1 - math.exp(-55 * deltaTime)
		local recoveryAlpha = 1 - math.exp(-10 * deltaTime)

		local newPitch = recoilPitch + (targetRecoilPitch - recoilPitch) * kickAlpha
		local newYaw = recoilYaw + (targetRecoilYaw - recoilYaw) * kickAlpha

		targetRecoilPitch += (0 - targetRecoilPitch) * recoveryAlpha
		targetRecoilYaw += (0 - targetRecoilYaw) * recoveryAlpha

		local pitchDelta = newPitch - recoilPitch
		local yawDelta = newYaw - recoilYaw
		recoilPitch = newPitch
		recoilYaw = newYaw

		if math.abs(pitchDelta) > 0.0001 or math.abs(yawDelta) > 0.0001 then
			camera.CFrame *= CFrame.Angles(math.rad(-pitchDelta), math.rad(yawDelta), 0)
		end
	end)
end

return CameraController
