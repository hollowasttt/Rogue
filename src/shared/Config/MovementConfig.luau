return {
	WalkSpeed = 20,
	Acceleration = 90,
	AirAcceleration = 55,
	GroundFriction = 8,
	AirFriction = 0.5,

	-- Fast, short burst. The dash keeps the player's momentum instead of
	-- letting Humanoid movement immediately cancel it.
	DashSpeed = 135,
	DashDuration = 0.12,
	DashCooldown = 0.35,
	DashAirControl = 0.35,

	SlideSpeed = 72,
	SlideDuration = 0.85,
	SlideCooldown = 0.15,
	MinSpeedToSlide = 8,
	SlideFriction = 2.5,
	SlideJumpBoost = 1.12,

	JumpPower = 50,
}
