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

	-- Sliding always has enough momentum to move, even when started from rest.
	-- Fast entries keep their speed and gradually decay toward SlideMinSpeed.
	SlideDuration = 999999,
	MinSpeedToSlide = 0,
	SlideFriction = 0.65,
	SlideMinSpeed = 24,
	SlideStartSpeed = 24,
	SlideJumpBoost = 1.12,
	SlideCameraOffset = Vector3.new(0, -1.8, 0),
	SlideCameraSmoothness = 12,

	JumpPower = 50,
}
