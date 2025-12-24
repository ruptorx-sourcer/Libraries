-- ObjecX Core Framework v1.0.0
-- Type: LocalScript | Parent: StarterPlayer.StarterPlayerScripts

-- Old C functions backup
local oldIsFolder = isfolder
local oldIsFile = isfile
local oldMakeFolder = makefolder
local oldReadFile = readfile
local oldWriteFile = writefile
local oldDelFile = delfile
local oldDelFolder = delfolder

-- Environment Variables
local CVersion = 100
local DefGcomptable = {100}
local SelfScript = ""
local CACHE_MISS = 0
local HARD_SHUTDOWN = 0
local CRASH_DETECTED = 0

-- GitHub Repository Configuration
local GITHUB_REPO = "https://raw.githubusercontent.com/ruptorx-sourcer/Libraries/main/"

-- Helper Functions
local function getfile(url, timeout)
	timeout = timeout or 10
	local success, result = pcall(function()
		local startTime = tick()
		local data
		local thread = coroutine.create(function()
			data = game:HttpGet(url)
		end)
		coroutine.resume(thread)
		while coroutine.status(thread) ~= "dead" and (tick() - startTime) < timeout do
			task.wait(0.1)
		end
		if coroutine.status(thread) ~= "dead" then
			return nil
		end
		return data
	end)
	if success and result then
		return result
	else
		return nil
	end
end

local function logError(errorMsg)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local logEntry = timestamp .. ": " .. tostring(errorMsg) .. "\n"
	local existingLog = ""
	if oldIsFile("ObjecX/crash.log") then
		existingLog = oldReadFile("ObjecX/crash.log")
	end
	oldWriteFile("ObjecX/crash.log", existingLog .. logEntry)
end

local function isGameFrozen()
	local stats = game:GetService("Stats")
	local fps = stats.FrameRateManager.RenderAverage
	return fps < 5
end

local function shutdown()
	if oldIsFile("ObjecX/increment.lock") then
		oldWriteFile("ObjecX/increment.lock", "0")
	end
	while true do
		task.wait(1)
	end
end

local function restart()
	if oldIsFile("ObjecX/increment.lock") then
		oldWriteFile("ObjecX/increment.lock", "0")
	end
	task.wait(0.5)
	if oldIsFile("ObjecX/mainscript.luau") then
		local scriptContent = oldReadFile("ObjecX/mainscript.luau")
		loadstring(scriptContent)()
	end
	while true do
		task.wait(1)
	end
end

-- Primary FileSystem Wizard
if not oldIsFolder("ObjecX") then
	oldMakeFolder("ObjecX")
end

if not oldIsFile("ObjecX/mainscript.luau") then
	oldWriteFile("ObjecX/mainscript.luau", SelfScript)
end

if not oldIsFolder("ObjecX/versions") then
	oldMakeFolder("ObjecX/versions")
end

if not oldIsFile("ObjecX/versions/" .. tostring(CVersion) .. ".lua") then
	oldWriteFile("ObjecX/versions/" .. tostring(CVersion) .. ".lua", SelfScript)
end

if not oldIsFolder("ObjecX/libraries") then
	oldMakeFolder("ObjecX/libraries")
	CACHE_MISS = 1
end

-- Crash counter check
local crashCount = 0
if oldIsFile("ObjecX/.crashcount") then
	crashCount = tonumber(oldReadFile("ObjecX/.crashcount")) or 0
	crashCount = crashCount + 1
	if crashCount >= 3 then
		logError("CRITICAL: Too many crashes detected (" .. tostring(crashCount) .. "), giving up")
		oldWriteFile("ObjecX/CRITICAL_FAILURE.txt", "System failed after " .. tostring(crashCount) .. " crash attempts")
		oldDelFile("ObjecX/.crashcount")
		shutdown()
		return
	end
	oldWriteFile("ObjecX/.crashcount", tostring(crashCount))
else
	oldWriteFile("ObjecX/.crashcount", "1")
end

-- Secondary FileSystem Wizard
local guiModule
if CACHE_MISS == 1 then
	local guiVersionData = getfile(GITHUB_REPO .. "gui.version", 10)
	local guiListData = getfile(GITHUB_REPO .. "gui.list", 10)
	
	if guiVersionData and guiListData then
		local HttpService = game:GetService("HttpService")
		local guiVersion = tonumber(guiVersionData)
		local guiList = HttpService:JSONDecode(guiListData)
		
		local compatibleVersions = {}
		for _, entry in ipairs(guiList.compatibility) do
			if entry.core == CVersion then
				table.insert(compatibleVersions, entry.gui)
			end
		end
		
		table.sort(compatibleVersions, function(a, b) return a > b end)
		local newgui = compatibleVersions[1] or 100
		
		local guiScriptData = getfile(GITHUB_REPO .. tostring(newgui) .. "-oil.luau", 15)
		if guiScriptData then
			oldWriteFile("ObjecX/libraries/" .. tostring(newgui) .. "-oil.luau", guiScriptData)
			guiModule = loadstring(guiScriptData)()
		else
			logError("Failed to fetch GUI script from GitHub")
		end
	else
		logError("Failed to fetch gui.version or gui.list from GitHub")
	end
else
	local shouldCheckUpdate = false
	local currentTime = os.time()
	
	if oldIsFile("ObjecX/.lastchecked") then
		local lastChecked = tonumber(oldReadFile("ObjecX/.lastchecked")) or 0
		if (currentTime - lastChecked) > 600 then
			shouldCheckUpdate = true
		end
	else
		shouldCheckUpdate = true
	end
	
	if shouldCheckUpdate then
		local guiVersionData = getfile(GITHUB_REPO .. "gui.version", 10)
		if guiVersionData then
			oldWriteFile("ObjecX/.lastchecked", tostring(currentTime))
			local HttpService = game:GetService("HttpService")
			local latestGuiVersion = tonumber(guiVersionData)
			
			local currentGuiFile
			for _, file in ipairs(listfiles("ObjecX/libraries")) do
				if string.match(file, "(%d+)%-oil%.luau$") then
					currentGuiFile = file
					break
				end
			end
			
			if currentGuiFile then
				local currentVersion = tonumber(string.match(currentGuiFile, "(%d+)%-oil%.luau$"))
				if latestGuiVersion and currentVersion and latestGuiVersion > currentVersion then
					local newGuiData = getfile(GITHUB_REPO .. tostring(latestGuiVersion) .. "-oil.luau", 15)
					if newGuiData then
						oldWriteFile("ObjecX/libraries/" .. tostring(latestGuiVersion) .. "-oil.luau", newGuiData)
						if oldIsFile(currentGuiFile) then
							oldDelFile(currentGuiFile)
						end
						guiModule = loadstring(newGuiData)()
					end
				else
					guiModule = loadstring(oldReadFile(currentGuiFile))()
				end
			end
		end
	else
		local guiFile
		for _, file in ipairs(listfiles("ObjecX/libraries")) do
			if string.match(file, "(%d+)%-oil%.luau$") then
				guiFile = file
				break
			end
		end
		if guiFile and oldIsFile(guiFile) then
			guiModule = loadstring(oldReadFile(guiFile))()
		end
	end
end

-- Logon check
if oldIsFile("ObjecX/increment.lock") then
	local lockValue = oldReadFile("ObjecX/increment.lock")
	if lockValue ~= "0" then
		oldWriteFile("ObjecX/increment.lock", "0")
		HARD_SHUTDOWN = 1
	end
else
	oldWriteFile("ObjecX/increment.lock", "0")
end

-- Check for .STOP file
if oldIsFile("ObjecX/.STOP") then
	if HARD_SHUTDOWN == 1 then
		oldDelFile("ObjecX/.STOP")
	else
		shutdown()
		return
	end
end

-- Check for .UNINSTALL file
if oldIsFile("ObjecX/.UNINSTALL") then
	if oldIsFolder("ObjecX") then
		oldDelFolder("ObjecX")
	end
	return
end

-- Update check
local shouldCheckCoreUpdate = false
local currentTime = os.time()

if oldIsFile("ObjecX/.lastchecked") then
	local lastChecked = tonumber(oldReadFile("ObjecX/.lastchecked")) or 0
	if (currentTime - lastChecked) > 600 then
		shouldCheckCoreUpdate = true
	end
else
	shouldCheckCoreUpdate = true
end

if shouldCheckCoreUpdate then
	local cversionData = getfile(GITHUB_REPO .. "cversion.txt", 10)
	if cversionData then
		oldWriteFile("ObjecX/.lastchecked", tostring(currentTime))
		local latestCVersion = tonumber(cversionData)
		if latestCVersion and latestCVersion > CVersion then
			local newCoreData = getfile(GITHUB_REPO .. "core-" .. tostring(latestCVersion) .. ".luau", 15)
			if newCoreData then
				oldWriteFile("ObjecX/mainscript.luau", newCoreData)
				restart()
				return
			end
		end
	end
end

-- Logon system (increment.lock updater)
task.spawn(function()
	local counter = 0
	while true do
		if oldIsFile("ObjecX/.STOP") then
			shutdown()
			break
		end
		counter = counter + 1
		oldWriteFile("ObjecX/increment.lock", tostring(counter))
		task.wait(0.1)
	end
end)

-- Auxiliary Failsafe Watchdog
task.spawn(function()
	task.wait(2)
	if not oldIsFile("ObjecX/increment.lock") then
		return
	end
	
	local lastValue = tonumber(oldReadFile("ObjecX/increment.lock")) or 0
	local failCount = 0
	local checkStartTime = tick()
	
	while true do
		task.wait(1)
		
		if not oldIsFile("ObjecX/increment.lock") then
			return
		end
		
		local currentValue = tonumber(oldReadFile("ObjecX/increment.lock")) or 0
		
		if isGameFrozen() then
			lastValue = currentValue
			failCount = 0
			checkStartTime = tick()
		elseif currentValue == lastValue then
			failCount = failCount + 1
			if failCount >= 3 and (tick() - checkStartTime) < 15 then
				oldWriteFile("ObjecX/.STOP", "Watchdog triggered")
				task.wait(5)
				if oldIsFile("ObjecX/mainscript.luau") then
					local scriptContent = oldReadFile("ObjecX/mainscript.luau")
					loadstring(scriptContent)()
				end
				return
			end
		else
			lastValue = currentValue
			failCount = 0
			checkStartTime = tick()
		end
	end
end)

-- Shutdown monitor
task.spawn(function()
	while true do
		task.wait(0.3)
		if oldIsFile("ObjecX/.STOP") then
			shutdown()
			break
		end
	end
end)

-- Successful startup - clear crash counter
if oldIsFile("ObjecX/.crashcount") then
	oldDelFile("ObjecX/.crashcount")
end

-- Main execution
local success, err = pcall(function()
	if guiModule then
		print("ObjecX Core v" .. tostring(CVersion) .. " loaded successfully")
	else
		warn("ObjecX Core loaded but GUI module failed to load")
	end
end)

if not success then
	logError("Main execution error: " .. tostring(err))
end
