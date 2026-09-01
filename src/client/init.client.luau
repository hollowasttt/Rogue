local MovementController = require(script.Controllers.MovementController)
local CrosshairController = require(script.Controllers.CrosshairController)
local CameraController = require(script.Controllers.CameraController)
local MovementVFXController = require(script.Controllers.MovementVFXController)

MovementController.Init()
CrosshairController.Init()
CameraController.Init()
MovementVFXController.Init()

print("[Client] Movement + Crosshair + Camera + VFX yüklendi")
