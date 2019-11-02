-- Copyright (c) 2019 David Vogel
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

CAPTURE_PIXEL_SIZE = 1 -- Screen to virtual pixel ratio
CAPTURE_GRID_SIZE = 420 -- in ingame pixels. There will always be 3 to 6 images overlapping
CAPTURE_DELAY = 15 -- in frames
CAPTURE_BIGJUMP_DELAY = 20 -- in frames. Additional delay after doing a "larger than grid jump"
CAPTURE_FORCE_HP = 4 -- * 25HP

CAPTURE_LEFT = -25000 -- in ingame pixels. Left edge of the full map capture rectangle
CAPTURE_TOP = -36000 -- in ingame pixels. Top edge of the full map capture rectangle
CAPTURE_RIGHT = 25000 -- in ingame pixels. Right edge of the full map capture rectangle (Pixels are not included in the rectangle)
CAPTURE_BOTTOM = 36000 -- in ingame pixels. Bottom edge of the full map capture rectangle (Pixels are not included in the rectangle)

local function preparePlayer()
	local playerEntity = getPlayer()
	addEffectToEntity(playerEntity, "PROTECTION_ALL")

	addPerkToPlayer("BREATH_UNDERWATER")
	addPerkToPlayer("INVISIBILITY")
	addPerkToPlayer("REMOVE_FOG_OF_WAR")
	addPerkToPlayer("REPELLING_CAPE")
	addPerkToPlayer("WORM_DETRACTOR")

	setPlayerHP(CAPTURE_FORCE_HP)
end

local function resetPlayer()
	setPlayerHP(CAPTURE_FORCE_HP)
end

function startCapturingSpiral()
	local ox, oy = GameGetCameraPos()
	ox, oy = math.floor(ox / CAPTURE_GRID_SIZE) * CAPTURE_GRID_SIZE, math.floor(oy / CAPTURE_GRID_SIZE) * CAPTURE_GRID_SIZE
	local x, y = ox, oy

	preparePlayer()

	GameSetCameraFree(true)

	-- Coroutine to calculate next coordinate, and trigger screenshots
	local i = 1
	async_loop(
		function()
			-- +x
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE, y * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					GameSetCameraPos(x, y)
					wait(CAPTURE_DELAY - 1)
					UiHide = true -- Hide UI while capturing the screenshot
					wait(1)
					if not TriggerCapture(rx, ry) then
						UiCaptureProblem = "Screen capture failed. Please restart Noita."
					end
					UiHide = false
				end
				x, y = x + CAPTURE_GRID_SIZE, y
			end
			-- +y
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE, y * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					GameSetCameraPos(x, y)
					wait(CAPTURE_DELAY - 1)
					UiHide = true
					wait(1)
					if not TriggerCapture(rx, ry) then
						UiCaptureProblem = "Screen capture failed. Please restart Noita."
					end
					UiHide = false
				end
				x, y = x, y + CAPTURE_GRID_SIZE
			end
			i = i + 1
			-- -x
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE, y * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					GameSetCameraPos(x, y)
					wait(CAPTURE_DELAY - 1)
					UiHide = true
					wait(1)
					if not TriggerCapture(rx, ry) then
						UiCaptureProblem = "Screen capture failed. Please restart Noita."
					end
					UiHide = false
				end
				x, y = x - CAPTURE_GRID_SIZE, y
			end
			-- -y
			for i = 1, i, 1 do
				local rx, ry = x * CAPTURE_PIXEL_SIZE, y * CAPTURE_PIXEL_SIZE
				if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
					GameSetCameraPos(x, y)
					wait(CAPTURE_DELAY - 1)
					UiHide = true
					wait(1)
					if not TriggerCapture(rx, ry) then
						UiCaptureProblem = "Screen capture failed. Please restart Noita."
					end
					UiHide = false
				end
				x, y = x, y - CAPTURE_GRID_SIZE
			end
			i = i + 1
		end
	)
end

function startCapturingHilbert()
	local ox, oy = GameGetCameraPos()

	-- Get size of the rectangle in grid/chunk coordinates
	local gridLeft = math.floor(CAPTURE_LEFT / CAPTURE_GRID_SIZE)
	local gridTop = math.floor(CAPTURE_TOP / CAPTURE_GRID_SIZE)
	local gridRight = math.ceil(CAPTURE_RIGHT / CAPTURE_GRID_SIZE) + 1
	local gridBottom = math.ceil(CAPTURE_BOTTOM / CAPTURE_GRID_SIZE) + 1

	-- Size of the grid in chunks
	local gridWidth = gridRight - gridLeft
	local gridHeight = gridBottom - gridTop

	-- Hilbert curve can only fit into a square, so get the longest side
	local gridPOTSize = math.ceil(math.log(math.max(gridWidth, gridHeight)) / math.log(2))
	-- Max size (Already rounded up to the next power of two)
	local gridMaxSize = math.pow(2, gridPOTSize)

	local t, tLimit = 0, gridMaxSize * gridMaxSize

	UiProgress = {Progress = 0, Max = gridWidth * gridHeight}

	preparePlayer()

	GameSetCameraFree(true)

	-- Coroutine to calculate next coordinate, and trigger screenshots
	async(
		function()
			while t < tLimit do
				local hx, hy = mapHilbert(t, gridPOTSize)
				if hx < gridWidth and hy < gridHeight then
					local x, y = (hx + gridLeft) * CAPTURE_GRID_SIZE, (hy + gridTop) * CAPTURE_GRID_SIZE
					local rx, ry = x * CAPTURE_PIXEL_SIZE, y * CAPTURE_PIXEL_SIZE
					if not fileExists(string.format("mods/noita-mapcap/output/%d,%d.png", rx, ry)) then
						GameSetCameraPos(x, y)

						-- "Larger than grid jump" delay
						if math.abs(x - ox) > CAPTURE_GRID_SIZE or math.abs(y - oy) > CAPTURE_GRID_SIZE then
							wait(CAPTURE_BIGJUMP_DELAY)
						end
						ox, oy = x, y

						wait(CAPTURE_DELAY - 1)
						UiHide = true -- Hide UI while capturing the screenshot
						wait(1)
						if not TriggerCapture(rx, ry) then
							UiCaptureProblem = "Screen capture failed. Please restart Noita."
						end
						UiHide = false
					end
					UiProgress.Progress = UiProgress.Progress + 1
				end

				t = t + 1
			end
		end
	)
end
