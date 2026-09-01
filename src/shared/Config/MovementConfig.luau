return {
	WalkSpeed = 20,
	Acceleration = 90,
	AirAcceleration = 55,
	GroundFriction = 8,
	AirFriction = 0.5,

	DashSpeed = 125,
	DashDuration = 0.14,
	DashCooldown = 0.35,
	DashAirControl = 0.35,

	-- Sliding never times out. It continues while Ctrl is held.
	-- A stationary slide starts slightly faster than walking.
	SlideDuration = 999999,
	MinSpeedToSlide = 0,
	SlideFriction = 0.65,
	SlideMinSpeed = 30,
	SlideStartSpeed = 30,
	SlideJumpBoost = 1.12,
	SlideCameraOffset = Vector3.new(0, -2.0, 0),
	SlideCameraSmoothness = 12,

	JumpPower = 50,
}
