-- ObjecX Core Framework v1.0.0 (FINAL)
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

-- Cached network data to avoid duplicate calls
local cachedGuiVersion = nil
local cachedGuiList = nil

-- StarterGui for Roblox notifications
local StarterGui = game:GetService("StarterGui")

-- Helper Functions
local function sendRobloxNotification(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 5
		})
	end)
end

local function logError(errorMsg)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local logEntry = timestamp .. ": " .. tostring(errorMsg) .. "\n"
	local existingLog = ""
	if oldIsFile("ObjecX/crash.log") then
		existingLog = oldReadFile("ObjecX/crash.log")
	end
	oldWriteFile("ObjecX/crash.log", existingLog .. logEntry)
	warn(errorMsg)
end

local function traceback(functionName, reason)
	local traceMsg = "[TRACEBACK] Function: " .. functionName .. " | Reason: " .. reason
	logError(traceMsg)
	return traceMsg
end

local function getfile(url, timeout)
	timeout = timeout or 15
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
			traceback("getfile", "Timeout after " .. tostring(timeout) .. "s for URL: " .. url)
			return nil
		end
		return data
	end)
	if success and result then
		return result
	else
		traceback("getfile", "HTTP request failed for URL: " .. url .. " | Error: " .. tostring(result))
		return nil
	end
end

local function isGameFrozen()
	local success, fps = pcall(function()
		local stats = game:GetService("Stats")
		return stats.FrameRateManager:GetRenderAverage()
	end)
	if not success then
		return false
	end
	return fps < 5
end

local function shutdown()
	if oldIsFile("ObjecX/.loggedin") then
		oldDelFile("ObjecX/.loggedin")
	end
	if oldIsFile("ObjecX/increment.lock") then
		oldWriteFile("ObjecX/increment.lock", "0")
	end
	while true do
		task.wait(1)
	end
end

local function restart()
	if oldIsFile("ObjecX/.loggedin") then
		oldDelFile("ObjecX/.loggedin")
	end
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

local function getCompatibleGuiVersion()
	if cachedGuiVersion and cachedGuiList then
		print("[ObjecX] Using cached network data")
	else
		local guiVersionData = getfile(GITHUB_REPO .. "gui.version", 15)
		local guiListData = getfile(GITHUB_REPO .. "gui.list", 15)
		
		if not guiVersionData or not guiListData then
			traceback("getCompatibleGuiVersion", "Failed to fetch gui.version or gui.list")
			return nil
		end
		
		cachedGuiVersion = guiVersionData
		cachedGuiList = guiListData
	end
	
	local HttpService = game:GetService("HttpService")
	local success, guiList = pcall(function()
		return HttpService:JSONDecode(cachedGuiList)
	end)
	
	if not success then
		traceback("getCompatibleGuiVersion", "Failed to decode gui.list JSON. Error: " .. tostring(guiList))
		return nil
	end
	
	local compatibleVersions = {}
	for _, entry in ipairs(guiList.compatibility) do
		if entry.core == CVersion then
			table.insert(compatibleVersions, entry.gui)
		end
	end
	
	if #compatibleVersions == 0 then
		traceback("getCompatibleGuiVersion", "No compatible GUI versions found for CVersion " .. tostring(CVersion))
		for _, version in ipairs(DefGcomptable) do
			table.insert(compatibleVersions, version)
		end
		print("[ObjecX] Using fallback compatibility table")
	end
	
	table.sort(compatibleVersions, function(a, b) return a > b end)
	return compatibleVersions[1]
end

local function checkCacheIntegrity()
	if not oldIsFolder("ObjecX/libraries") then
		traceback("checkCacheIntegrity", "Libraries folder missing")
		return false
	end
	
	local requiredGuiVersion = getCompatibleGuiVersion()
	if not requiredGuiVersion then
		traceback("checkCacheIntegrity", "Could not determine required GUI version")
		return false
	end
	
	local requiredFile = "ObjecX/libraries/" .. tostring(requiredGuiVersion) .. "-oil.luau"
	if not oldIsFile(requiredFile) then
		traceback("checkCacheIntegrity", "Required GUI file missing: " .. requiredFile)
		return false
	end
	
	local fileContent = oldReadFile(requiredFile)
	if not fileContent or #fileContent < 10 then
		traceback("checkCacheIntegrity", "Required GUI file is empty or corrupted: " .. requiredFile)
		oldDelFile(requiredFile)
		return false
	end
	
	print("[ObjecX] Cache integrity verified")
	return true
end

local function cleanOldGuiFiles(keepVersion)
	local files = listfiles("ObjecX/libraries")
	for _, file in ipairs(files) do
		local version = string.match(file, "(%d+)%-oil%.luau$")
		if version and tonumber(version) ~= keepVersion then
			print("[ObjecX] Removing old GUI file: " .. file)
			pcall(function()
				oldDelFile(file)
			end)
		end
	end
end

local function loadGuiFromCache()
	local guiFile
	for _, file in ipairs(listfiles("ObjecX/libraries")) do
		if string.match(file, "(%d+)%-oil%.luau$") then
			guiFile = file
			break
		end
	end
	
	if not guiFile or not oldIsFile(guiFile) then
		traceback("loadGuiFromCache", "No GUI file found in cache")
		return nil
	end
	
	local fileContent = oldReadFile(guiFile)
	if not fileContent or #fileContent < 10 then
		traceback("loadGuiFromCache", "Cached GUI file is empty or corrupted")
		pcall(function()
			oldDelFile(guiFile)
		end)
		return nil
	end
	
	local loadFunc = loadstring(fileContent)
	if not loadFunc then
		traceback("loadGuiFromCache", "loadstring returned nil for cached GUI")
		return nil
	end
	
	local loadSuccess, loadResult = pcall(loadFunc)
	if loadSuccess and loadResult then
		print("[ObjecX] Cached GUI module loaded successfully")
		return loadResult
	else
		traceback("loadGuiFromCache", "Failed to execute cached GUI. Error: " .. tostring(loadResult))
		return nil
	end
end

local function fetchAndLoadGui()
	local newgui = getCompatibleGuiVersion()
	if not newgui then
		traceback("fetchAndLoadGui", "Cannot fetch GUI without compatible version")
		return nil
	end
	
	print("[ObjecX] Fetching GUI version: " .. tostring(newgui))
	
	local guiScriptData = getfile(GITHUB_REPO .. tostring(newgui) .. "-oil.luau", 20)
	if not guiScriptData or #guiScriptData < 10 then
		traceback("fetchAndLoadGui", "Failed to fetch GUI script or script is too small")
		return nil
	end
	
	local savePath = "ObjecX/libraries/" .. tostring(newgui) .. "-oil.luau"
	local saveSuccess = pcall(function()
		oldWriteFile(savePath, guiScriptData)
	end)
	
	if not saveSuccess then
		traceback("fetchAndLoadGui", "Failed to save GUI script to filesystem")
	else
		print("[ObjecX] GUI script saved to filesystem")
		cleanOldGuiFiles(newgui)
	end
	
	local loadFunc = loadstring(guiScriptData)
	if not loadFunc then
		traceback("fetchAndLoadGui", "loadstring returned nil for fetched GUI")
		return nil
	end
	
	local loadSuccess, loadResult = pcall(loadFunc)
	if loadSuccess and loadResult then
		print("[ObjecX] Fetched GUI module loaded successfully")
		return loadResult
	else
		traceback("fetchAndLoadGui", "Failed to execute fetched GUI. Error: " .. tostring(loadResult))
		return nil
	end
end

local function getCurrentGuiVersion()
	local guiFile
	for _, file in ipairs(listfiles("ObjecX/libraries")) do
		local version = string.match(file, "(%d+)%-oil%.luau$")
		if version then
			return tonumber(version)
		end
	end
	return nil
end

local function installCoreUpdate(newVersion)
	print("[ObjecX] Installing core update v" .. tostring(newVersion))
	local newCoreData = getfile(GITHUB_REPO .. "core-" .. tostring(newVersion) .. ".luau", 20)
	if newCoreData then
		oldWriteFile("ObjecX/mainscript.luau", newCoreData)
		print("[ObjecX] Core update installed successfully")
		return true
	else
		traceback("installCoreUpdate", "Failed to fetch core update v" .. tostring(newVersion))
		return false
	end
end

local function installGuiUpdate(newVersion)
	print("[ObjecX] Installing GUI update v" .. tostring(newVersion))
	local guiScriptData = getfile(GITHUB_REPO .. tostring(newVersion) .. "-oil.luau", 20)
	if guiScriptData and #guiScriptData > 10 then
		local savePath = "ObjecX/libraries/" .. tostring(newVersion) .. "-oil.luau"
		local saveSuccess = pcall(function()
			oldWriteFile(savePath, guiScriptData)
		end)
		if saveSuccess then
			cleanOldGuiFiles(newVersion)
			print("[ObjecX] GUI update installed successfully")
			return true
		end
	end
	traceback("installGuiUpdate", "Failed to install GUI update v" .. tostring(newVersion))
	return false
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
	print("[ObjecX] Libraries folder created, setting CACHE_MISS")
else
	if not checkCacheIntegrity() then
		CACHE_MISS = 1
		print("[ObjecX] Cache integrity check failed, setting CACHE_MISS")
	end
end

-- Login check for hard crash detection
if oldIsFile("ObjecX/.loggedin") then
	if oldIsFile("ObjecX/increment.lock") then
		local lockValue = tonumber(oldReadFile("ObjecX/increment.lock")) or 0
		task.wait(1.5)
		local newLockValue = tonumber(oldReadFile("ObjecX/increment.lock")) or 0
		
		if newLockValue > lockValue then
			traceback("LoginCheck", "Another instance is already running, stopping")
			return
		else
			traceback("LoginCheck", "Hard crash detected, continuing with recovery")
			HARD_SHUTDOWN = 1
		end
	else
		traceback("LoginCheck", "Hard crash detected (no increment.lock), continuing with recovery")
		HARD_SHUTDOWN = 1
	end
end

oldWriteFile("ObjecX/.loggedin", tostring(os.time()))

-- Crash counter check
local crashCount = 0
if oldIsFile("ObjecX/.crashcount") then
	local crashData = oldReadFile("ObjecX/.crashcount")
	local crashTime = tonumber(string.match(crashData, "time:(%d+)")) or 0
	crashCount = tonumber(string.match(crashData, "count:(%d+)")) or 0
	
	local timeSinceLastCrash = os.time() - crashTime
	if timeSinceLastCrash > 300 then
		print("[ObjecX] Last crash was " .. tostring(timeSinceLastCrash) .. "s ago, resetting counter")
		crashCount = 0
	end
	
	crashCount = crashCount + 1
	if crashCount >= 3 then
		logError("CRITICAL: Too many crashes detected (" .. tostring(crashCount) .. "), giving up")
		oldWriteFile("ObjecX/CRITICAL_FAILURE.txt", "System failed after " .. tostring(crashCount) .. " crash attempts")
		oldDelFile("ObjecX/.crashcount")
		shutdown()
		return
	end
	oldWriteFile("ObjecX/.crashcount", "count:" .. tostring(crashCount) .. " time:" .. tostring(os.time()))
else
	oldWriteFile("ObjecX/.crashcount", "count:1 time:" .. tostring(os.time()))
end

-- GUI Loading Logic
local guiModule

if CACHE_MISS == 1 then
	print("[ObjecX] CACHE_MISS mode: attempting network fetch")
	guiModule = fetchAndLoadGui()
else
	print("[ObjecX] Cache mode: attempting to load from cache")
	guiModule = loadGuiFromCache()
	
	if not guiModule then
		print("[ObjecX] Cache load failed, attempting network fetch")
		guiModule = fetchAndLoadGui()
	end
end

if not guiModule then
	traceback("GUILoader", "All GUI loading attempts failed, trying cache as last resort")
	guiModule = loadGuiFromCache()
end

-- If GUI still failed to load, send Roblox notification
if not guiModule then
	sendRobloxNotification("ObjecX Critical Error", "GUI failed to load. Check crash.log for details.", 10)
	traceback("GUILoader", "GUI module is completely unavailable")
end

-- Logon check
if oldIsFile("ObjecX/increment.lock") then
	local lockValue = oldReadFile("ObjecX/increment.lock")
	if lockValue ~= "0" and HARD_SHUTDOWN == 0 then
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
	local timeDiff = currentTime - lastChecked
	if timeDiff > 600 and timeDiff < 31536000 then
		shouldCheckCoreUpdate = true
	end
else
	shouldCheckCoreUpdate = true
end

if shouldCheckCoreUpdate then
	local cversionData = getfile(GITHUB_REPO .. "cversion.txt", 15)
	if cversionData then
		oldWriteFile("ObjecX/.lastchecked", tostring(currentTime))
		local latestCVersion = tonumber(cversionData)
		if latestCVersion and latestCVersion > CVersion then
			print("[ObjecX] Core update available: v" .. tostring(CVersion) .. " -> v" .. tostring(latestCVersion))
			local newCoreData = getfile(GITHUB_REPO .. "core-" .. tostring(latestCVersion) .. ".luau", 20)
			if newCoreData then
				oldWriteFile("ObjecX/mainscript.luau", newCoreData)
				print("[ObjecX] Core updated, restarting...")
				restart()
				return
			end
		else
			print("[ObjecX] Core is up to date")
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
		pcall(function()
			oldWriteFile("ObjecX/increment.lock", tostring(counter))
		end)
		task.wait(0.1)
	end
end)

-- Background Update Checker (every 20 minutes)
task.spawn(function()
	task.wait(30)
	
	while true do
		print("[ObjecX] Background update check started")
		
		local coreUpdateAvailable = false
		local guiUpdateAvailable = false
		local newCoreVersion = nil
		local newGuiVersion = nil
		
		local cversionData = getfile(GITHUB_REPO .. "cversion.txt", 15)
		if cversionData then
			local latestCVersion = tonumber(cversionData)
			if latestCVersion and latestCVersion > CVersion then
				coreUpdateAvailable = true
				newCoreVersion = latestCVersion
				print("[ObjecX] Background check: Core update available v" .. tostring(CVersion) .. " -> v" .. tostring(latestCVersion))
			else
				print("[ObjecX] Background check: Core is up to date")
			end
		else
			print("[ObjecX] Background check: Failed to fetch core version")
		end
		
		cachedGuiVersion = nil
		cachedGuiList = nil
		local latestGuiVersion = getCompatibleGuiVersion()
		local currentGuiVersion = getCurrentGuiVersion()
		
		if latestGuiVersion and currentGuiVersion and latestGuiVersion > currentGuiVersion then
			guiUpdateAvailable = true
			newGuiVersion = latestGuiVersion
			print("[ObjecX] Background check: GUI update available v" .. tostring(currentGuiVersion) .. " -> v" .. tostring(latestGuiVersion))
		else
			print("[ObjecX] Background check: GUI is up to date")
		end
		
		if coreUpdateAvailable or guiUpdateAvailable then
			local notifTitle = ""
			local notifDesc = ""
			local notifType = "working"
			local useRobloxNotif = false
			
			if coreUpdateAvailable and guiUpdateAvailable then
				notifTitle = "Systemic Update Available"
				notifDesc = "Core v" .. tostring(newCoreVersion) .. " and GUI v" .. tostring(newGuiVersion) .. " are available. Click to install."
			elseif coreUpdateAvailable then
				notifTitle = "Core Update Available"
				notifDesc = "Version " .. tostring(newCoreVersion) .. " is available. Click to install and restart."
			elseif guiUpdateAvailable then
				notifTitle = "GUI Update Available"
				notifDesc = "Version " .. tostring(newGuiVersion) .. " is available. Click to install and restart."
				if not guiModule then
					useRobloxNotif = true
				end
			end
			
			if guiModule and not useRobloxNotif then
				local success = pcall(function()
					guiModule.registerCallback("objecx_update_install", function()
						print("[ObjecX] User initiated update installation")
						
						local installSuccess = true
						
						if coreUpdateAvailable then
							if not installCoreUpdate(newCoreVersion) then
								installSuccess = false
							end
						end
						
						if guiUpdateAvailable then
							if not installGuiUpdate(newGuiVersion) then
								installSuccess = false
							end
						end
						
						if installSuccess then
							print("[ObjecX] Updates installed successfully, restarting...")
							pcall(function()
								guiModule.closeNotif("objecx_update_notif")
							end)
							task.wait(1)
							restart()
						else
							traceback("UpdateInstaller", "Update installation failed")
							pcall(function()
								guiModule.closeNotif("objecx_update_notif")
								guiModule.add.notification("objecx_update_failed", {
									title = "Update Failed",
									desc = "Failed to install updates. Check crash.log for details.",
									timeout = 5,
									notificationType = "error",
									closeable = true
								})
							end)
						end
					end)
					
					guiModule.add.notification("objecx_update_notif", {
						title = notifTitle,
						desc = notifDesc,
						timeout = 0,
						notificationType = notifType,
						closeable = true,
						clickable = true,
						onClick = "objecx_update_install"
					})
				end)
				
				if not success then
					print("[ObjecX] Failed to create GUI notification, falling back to Roblox notification")
					useRobloxNotif = true
				end
			else
				useRobloxNotif = true
			end
			
			if useRobloxNotif then
				if guiUpdateAvailable then
					sendRobloxNotification("ObjecX Update", "GUI v" .. tostring(newGuiVersion) .. " available. Reinstall script to update.", 10)
					print("[ObjecX] GUI update notification sent via Roblox (GUI unavailable)")
				end
				if coreUpdateAvailable then
					sendRobloxNotification("ObjecX Update", "Core v" .. tostring(newCoreVersion) .. " available. Reinstall script to update.", 10)
					print("[ObjecX] Core update notification sent via Roblox (GUI unavailable)")
				end
			end
		end
		
		print("[ObjecX] Background update check completed")
		task.wait(1200)
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
				traceback("Watchdog", "Script freeze detected, triggering restart")
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

-- Successful startup - clear crash counter after delay
task.spawn(function()
	task.wait(10)
	if oldIsFile("ObjecX/.crashcount") then
		oldDelFile("ObjecX/.crashcount")
		print("[ObjecX] Crash counter cleared after successful 10s uptime")
	end
end)

-- Main execution
local success, err = pcall(function()
	if guiModule then
		print("ObjecX Core v" .. tostring(CVersion) .. " loaded successfully")
	else
		traceback("MainExecution", "GUI module is nil, couldn't load GUI")
		warn("ObjecX Core loaded but GUI module failed to load")
	end
end)

if not success then
	traceback("MainExecution", "Main execution error: " .. tostring(err))
	logError("Main execution error: " .. tostring(err))
end
