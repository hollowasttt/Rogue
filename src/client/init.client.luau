local MovementController = require(script.Controllers.MovementController)
local CrosshairController = require(script.Controllers.CrosshairController)
local CameraController = require(script.Controllers.CameraController)
local MovementVFXController = require(script.Controllers.MovementVFXController)
local PythonEliteController = require(script.Controllers.PythonEliteController)

MovementController.Init()
CrosshairController.Init()
CameraController.Init()
MovementVFXController.Init()
PythonEliteController.Init()

print("[Client] Movement + Crosshair + Camera + VFX + PythonElite yüklendi")
