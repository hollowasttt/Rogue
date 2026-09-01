return {
	WalkSpeed = 20,
	Acceleration = 90,
	AirAcceleration = 55,
	GroundFriction = 8,
	AirFriction = 0.5,

	-- Fast burst. Ground friction is disabled during dash so walking does not cancel it.
	DashSpeed = 125,
	DashDuration = 0.14,
	DashCooldown = 0.35,
	DashAirControl = 0.35,
	DashGroundFriction = 0,

	-- Slide preserves the exact speed you enter with and gradually loses momentum.
	SlideDuration = 1.2,
	MinSpeedToSlide = 8,
	SlideFriction = 1.15,
	SlideMinSpeed = 3,
	SlideJumpBoost = 1.12,

	JumpPower = 50,
}
