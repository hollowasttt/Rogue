local Players = game:GetService("Players")

local CrosshairController = {}

function CrosshairController.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CrosshairGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.fromOffset(6, 6)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	crosshair.BorderSizePixel = 0
	crosshair.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = crosshair

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.2
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Parent = crosshair
end

return CrosshairController