local metatable = {}

-- Cache functions
local getrawmetatable = getrawmetatable or getmetatable
local setreadonly = setreadonly or make_writeable or function() end
local make_readonly = make_readonly or setreadonly or function() end
local newcclosure = newcclosure or function(f) return f end

-- Storage for original methods
local originalGameMT = nil
local originalIndex = nil
local originalNewIndex = nil

-- Integrity data
metatable.integrity = {
	hooked = false,
	detectable = false,
	gameMTModified = false,
	indexChanged = false,
	newindexChanged = false
}

-- Initialize game metatable hook
function metatable.init()
	if metatable.integrity.hooked then
		return false, "Already hooked"
	end
	
	local success, err = pcall(function()
		-- Get game metatable
		originalGameMT = getrawmetatable(game)
		
		-- Store originals
		originalIndex = originalGameMT.__index
		originalNewIndex = originalGameMT.__newindex
		
		-- Make writable
		setreadonly(originalGameMT, false)
		
		-- Mark as hooked
		metatable.integrity.hooked = true
		metatable.integrity.gameMTModified = true
	end)
	
	return success, err
end

-- Hook __index (reads)
function metatable.hookIndex(handler)
	if not metatable.integrity.hooked then
		return false, "Not initialized - call metatable.init() first"
	end
	
	local success, err = pcall(function()
		originalGameMT.__index = newcclosure(function(self, key)
			-- Call user handler
			if handler then
				local result = handler(self, key)
				if result ~= nil then
					return result
				end
			end
			
			-- Call original
			return originalIndex(self, key)
		end)
		
		metatable.integrity.indexChanged = true
	end)
	
	return success, err
end

-- Hook __newindex (writes)
function metatable.hookNewIndex(handler)
	if not metatable.integrity.hooked then
		return false, "Not initialized - call metatable.init() first"
	end
	
	local success, err = pcall(function()
		originalGameMT.__newindex = newcclosure(function(self, key, value)
			-- Call user handler
			if handler then
				local block = handler(self, key, value)
				if block == false then
					return -- Block the write
				end
			end
			
			-- Call original
			return originalNewIndex(self, key, value)
		end)
		
		metatable.integrity.newindexChanged = true
	end)
	
	return success, err
end

-- Finalize (make readonly again)
function metatable.finalize()
	if not metatable.integrity.hooked then
		return false, "Not initialized"
	end
	
	pcall(function()
		make_readonly(originalGameMT, true)
	end)
	
	return true
end

-- Get original methods for internal use
function metatable.getOriginalIndex()
	return originalIndex
end

function metatable.getOriginalNewIndex()
	return originalNewIndex
end

-- Integrity scanner
function metatable.scanIntegrity()
	local report = {
		hooked = metatable.integrity.hooked,
		detectable = false,
		details = {}
	}
	
	if not metatable.integrity.hooked then
		report.details.status = "Not hooked"
		return report
	end
	
	-- Test 1: Check if metatable was actually modified
	local currentMT = getrawmetatable(game)
	if currentMT.__index ~= originalIndex then
		report.details.indexModified = true
		report.detectable = true
	end
	
	if currentMT.__newindex ~= originalNewIndex then
		report.details.newindexModified = true
		report.detectable = true
	end
	
	-- Test 2: Check if functions are Lua closures (detectable)
	if islclosure and islclosure(currentMT.__index) then
		report.details.indexIsLuaClosure = true
		report.detectable = true
	end
	
	if islclosure and islclosure(currentMT.__newindex) then
		report.details.newindexIsLuaClosure = true
		report.detectable = true
	end
	
	-- Test 3: Check if newcclosure worked
	if newcclosure then
		report.details.newcclosureAvailable = true
	else
		report.details.newcclosureAvailable = false
		report.detectable = true
	end
	
	-- Test 4: Try to detect metamethod comparison
	local testFunc = function() end
	local wrapped = newcclosure(testFunc)
	if testFunc == wrapped then
		report.details.newcclosureNotWorking = true
		report.detectable = true
	end
	
	metatable.integrity.detectable = report.detectable
	
	return report
end

return metatable
