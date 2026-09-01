local MovementController = require(script.Controllers.MovementController)
local CrosshairController = require(script.Controllers.CrosshairController)
local CameraController = require(script.Controllers.CameraController)

MovementController.Init()
CrosshairController.Init()
CameraController.Init()

print("[Client] Movement + Crosshair + Camera yüklendi")
