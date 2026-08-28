-- Rogue vertical open-world map generator
-- 1024x1024 terrain with aggressive elevation changes for fast traversal.

local Terrain = workspace.Terrain
local Workspace = game:GetService("Workspace")

local MAP_SIZE = 1024
local CELL_SIZE = 16
local MIN_HEIGHT = 8
local MAX_HEIGHT = 230
local SEED = 84721

local rng = Random.new(SEED)

local generated = Workspace:FindFirstChild("RogueGenerated")
if generated then
	generated:Destroy()
end

generated = Instance.new("Folder")
generated.Name = "RogueGenerated"
generated.Parent = Workspace

local function fbm(x: number, z: number, seedOffset: number?): number
	local value = 0
	local amplitude = 1
	local frequency = 1
	local total = 0
	local offset = seedOffset or 0

	for _ = 1, 5 do
		value += math.noise(x * frequency, z * frequency, SEED + offset) * amplitude
		total += amplitude
		amplitude *= 0.5
		frequency *= 2
	end

	return value / total
end

local function getHeight(x: number, z: number): number
	local nx = x / MAP_SIZE
	local nz = z / MAP_SIZE
	local continent = fbm(nx * 2.5, nz * 2.5, 0)
	local detail = fbm(nx * 10, nz * 10, 30) * 10

	local chain1 = math.abs(math.noise(nx * 2.7 + 4, nz * 1.3 - 8, SEED + 50))
	local chain2 = math.abs(math.noise(nx * 1.5 - 14, nz * 3.4 + 11, SEED + 80))
	local ridge = math.max(chain1, chain2)
	local mountains = math.max(0, ridge - 0.30) ^ 1.7 * 260

	local centralDistance = math.sqrt(nx * nx + nz * nz)
	local valley = math.max(0, 1 - centralDistance * 3.0) * 38

	local height = 48 + continent * 38 + detail + mountains - valley
	return math.clamp(height, MIN_HEIGHT, MAX_HEIGHT)
end

local function biomeAt(x: number, z: number, height: number): string
	local moisture = fbm(x / MAP_SIZE * 5 + 100, z / MAP_SIZE * 5 - 100, 120)
	local rockNoise = math.abs(math.noise(x / 115, z / 115, SEED + 140))

	if height >= 155 then
		return "Mountain"
	elseif height >= 105 then
		return rockNoise > 0.25 and "Rock" or "Forest"
	elseif moisture > -0.05 then
		return "Forest"
	elseif rockNoise > 0.40 then
		return "Rock"
	end

	return "Valley"
end

local function fillColumn(x: number, z: number, height: number, biome: string)
	local material = Enum.Material.Ground
	if biome == "Forest" then
		material = Enum.Material.Grass
	elseif biome == "Rock" or biome == "Mountain" then
		material = Enum.Material.Rock
	end

	Terrain:FillBlock(
		CFrame.new(x, (height - 20) / 2, z),
		Vector3.new(CELL_SIZE + 1, height + 20, CELL_SIZE + 1),
		material
	)
end

local function createRock(position: Vector3, size: number, tall: boolean?)
	local rock = Instance.new("Part")
	rock.Name = "CliffRock"
	rock.Anchored = true
	rock.Material = Enum.Material.Rock
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.new(
		size,
		size * rng:NextNumber(tall and 1.2 or 0.6, tall and 2.4 or 1.2),
		size * rng:NextNumber(0.7, 1.4)
	)
	rock.CFrame = CFrame.new(position) * CFrame.Angles(
		rng:NextNumber(-0.25, 0.25),
		rng:NextNumber(0, math.pi),
		rng:NextNumber(-0.25, 0.25)
	)
	rock.Parent = generated
end

local function createJumpLandmark(position: Vector3, name: string)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(10, 10, 10)
	part.Position = position
	part.Parent = generated
end

Terrain:Clear()

-- Main terrain pass.
for x = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE do
	for z = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE do
		local height = getHeight(x, z)
		fillColumn(x, z, height, biomeAt(x, z, height))
	end
end

-- Rocks only for now. Forest vegetation will use proper assets later.
for x = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE * 2 do
	for z = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE * 2 do
		local height = getHeight(x, z)
		local biome = biomeAt(x, z, height)

		if biome == "Rock" and rng:NextNumber() < 0.18 then
			createRock(Vector3.new(x, height + 5, z), rng:NextNumber(8, 25), false)
		elseif biome == "Mountain" and rng:NextNumber() < 0.25 then
			createRock(Vector3.new(x, height + 8, z), rng:NextNumber(12, 34), true)
		end
	end
end

local landmarkPositions = {
	{Vector3.new(-390, 0, -330), "ForestOverlook"},
	{Vector3.new(330, 0, -350), "MountainRidge"},
	{Vector3.new(410, 0, 250), "RockSpine"},
	{Vector3.new(-350, 0, 350), "HighPlateau"},
	{Vector3.new(0, 0, -40), "CentralArena"},
}

for _, data in landmarkPositions do
	local p = data[1]
	local y = getHeight(p.X, p.Z)
	createJumpLandmark(Vector3.new(p.X, y + 6, p.Z), data[2])
end

print("Rogue vertical map generated: 1024x1024")
