-- Rogue procedural open-world map generator
-- Generates a large alien wilderness using Roblox Terrain.

local Terrain = workspace.Terrain

local MAP_SIZE = 1536
local CELL_SIZE = 24
local MAX_HEIGHT = 180
local SEED = 84721

local rng = Random.new(SEED)

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

local function fbm(x: number, z: number): number
	local value = 0
	local amplitude = 1
	local frequency = 1
	local totalAmplitude = 0

	for _ = 1, 5 do
		value += math.noise(x * frequency, z * frequency, SEED) * amplitude
		totalAmplitude += amplitude
		amplitude *= 0.5
		frequency *= 2
	end

	return value / totalAmplitude
end

local function getHeight(x: number, z: number): number
	local nx = x / MAP_SIZE
	local nz = z / MAP_SIZE

	-- Broad continental terrain.
	local broad = fbm(nx * 2.2, nz * 2.2)
	local detail = fbm(nx * 7, nz * 7) * 0.22

	-- Several elevated mountain bands.
	local ridgeA = math.max(0, math.noise(nx * 2.8 + 20, nz * 2.8 + 20, SEED + 11))
	local ridgeB = math.max(0, math.noise(nx * 4.2 - 30, nz * 4.2 + 15, SEED + 29))
	local mountains = (ridgeA ^ 2.2) * 95 + (ridgeB ^ 3) * 55

	local height = 45 + broad * 55 + detail * 30 + mountains
	return math.clamp(height, 8, MAX_HEIGHT)
end

local function biomeAt(x: number, z: number, height: number): string
	local moisture = fbm(x / MAP_SIZE * 5 + 100, z / MAP_SIZE * 5 - 100)
	local rock = math.abs(math.noise(x / 180, z / 180, SEED + 100))

	if height > 135 then
		return "Mountain"
	elseif height > 105 and rock > 0.35 then
		return "Rock"
	elseif moisture > 0.05 then
		return "Forest"
	elseif rock > 0.38 then
		return "Rock"
	else
		return "Valley"
	end
end

local function fillColumn(x: number, z: number, height: number, biome: string)
	local material = Enum.Material.Grass

	if biome == "Rock" or biome == "Mountain" then
		material = Enum.Material.Rock
	elseif biome == "Forest" then
		material = Enum.Material.Grass
	elseif biome == "Valley" then
		material = Enum.Material.Ground
	end

	Terrain:FillBlock(
		CFrame.new(x, height / 2 - 15, z),
		Vector3.new(CELL_SIZE + 1, height + 30, CELL_SIZE + 1),
		material
	)

	-- Thin top layer makes transitions less artificial.
	if biome == "Rock" or biome == "Mountain" then
		Terrain:FillBlock(
			CFrame.new(x, height + 1, z),
			Vector3.new(CELL_SIZE + 1, 4, CELL_SIZE + 1),
			Enum.Material.Rock
		)
	else
		Terrain:FillBlock(
			CFrame.new(x, height + 1, z),
			Vector3.new(CELL_SIZE + 1, 4, CELL_SIZE + 1),
			Enum.Material.Grass
		)
	end
end

local function createRock(position: Vector3, size: number)
	local rock = Instance.new("Part")
	rock.Name = "AlienRock"
	rock.Anchored = true
	rock.Material = Enum.Material.Rock
	rock.Shape = Enum.PartType.Ball
	rock.Size = Vector3.new(size, size * rng:NextNumber(0.7, 1.4), size * rng:NextNumber(0.8, 1.5))
	rock.CFrame = CFrame.new(position) * CFrame.Angles(
		rng:NextNumber(-0.3, 0.3),
		rng:NextNumber(0, math.pi),
		rng:NextNumber(-0.3, 0.3)
	)
	rock.Parent = workspace
end

local function createTree(position: Vector3, scale: number)
	local model = Instance.new("Model")
	model.Name = "AlienTree"

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Anchored = true
	trunk.Material = Enum.Material.Wood
	trunk.Size = Vector3.new(4 * scale, 30 * scale, 4 * scale)
	trunk.Position = position + Vector3.new(0, 15 * scale, 0)
	trunk.Parent = model

	for i = 1, 4 do
		local crown = Instance.new("Part")
		crown.Name = "Foliage"
		crown.Anchored = true
		crown.Shape = Enum.PartType.Ball
		crown.Material = Enum.Material.Grass
		local s = rng:NextNumber(12, 22) * scale
		crown.Size = Vector3.new(s, s, s)
		crown.Position = position + Vector3.new(
			rng:NextNumber(-10, 10) * scale,
			30 * scale + rng:NextNumber(-4, 12) * scale,
			rng:NextNumber(-10, 10) * scale
		)
		crown.Parent = model
	end

	model.Parent = workspace
end

local function generateVegetationAndRocks()
	for x = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE * 3 do
		for z = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE * 3 do
			local height = getHeight(x, z)
			local biome = biomeAt(x, z, height)

			if biome == "Forest" and rng:NextNumber() < 0.34 then
				createTree(Vector3.new(x, height + 2, z), rng:NextNumber(0.8, 1.5))
			elseif (biome == "Rock" or biome == "Mountain") and rng:NextNumber() < 0.22 then
				createRock(Vector3.new(x, height + 4, z), rng:NextNumber(10, 32))
			end
		end
	end
end

local function createLandmarks()
	local folder = Instance.new("Folder")
	folder.Name = "MapLandmarks"
	folder.Parent = workspace

	local points = {
		{Vector3.new(-520, 0, -460), "NorthForest"},
		{Vector3.new(500, 0, -420), "MountainRidge"},
		{Vector3.new(470, 0, 480), "RockyWastes"},
		{Vector3.new(-500, 0, 500), "HighPlateau"},
		{Vector3.new(0, 0, 0), "CentralValley"},
	}

	for _, data in points do
		local marker = Instance.new("Part")
		marker.Name = data[2]
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 1
		marker.Size = Vector3.new(8, 8, 8)
		local p = data[1]
		marker.Position = Vector3.new(p.X, getHeight(p.X, p.Z) + 8, p.Z)
		marker.Parent = folder
	end
end

-- Clear generated terrain before regeneration during Studio testing.
Terrain:Clear()

for x = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE do
	for z = -MAP_SIZE / 2, MAP_SIZE / 2, CELL_SIZE do
		local height = getHeight(x, z)
		local biome = biomeAt(x, z, height)
		fillColumn(x, z, height, biome)
	end
end

generateVegetationAndRocks()
createLandmarks()

print("Rogue map generated successfully.")
