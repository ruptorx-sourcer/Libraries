local metatable = {}

-- Use specific instance metatables instead of hooking game globally
local instanceMetatables = {}
local originalMetamethods = {}

-- Cache functions
local getrawmetatable = getrawmetatable
local setreadonly = setreadonly
local newcclosure = newcclosure or function(f) return f end
local checkcaller = checkcaller or function() return false end

-- Hook specific instance type metatable (stealth)
local function hookInstanceMetatable(instanceType, metamethod, handler)
	local success, sample = pcall(function()
		return game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass(instanceType)
	end)
	
	if not success then
		-- Create a dummy instance to get its metatable
		local dummyMap = {
			Humanoid = function() 
				return game:GetService("Players").LocalPlayer.Character:WaitForChild("Humanoid")
			end
		}
		
		if dummyMap[instanceType] then
			sample = dummyMap[instanceType]()
		end
	end
	
	if sample then
		local mt = getrawmetatable(sample)
		setreadonly(mt, false)
		
		if not originalMetamethods[instanceType] then
			originalMetamethods[instanceType] = {}
		end
		
		if not originalMetamethods[instanceType][metamethod] then
			originalMetamethods[instanceType][metamethod] = mt[metamethod]
		end
		
		mt[metamethod] = newcclosure(handler)
		setreadonly(mt, true)
		
		instanceMetatables[instanceType] = mt
		return true
	end
	
	return false
end

-- Route __index for specific instance type
function metatable.routeIndexFor(instanceType, functionName)
	return hookInstanceMetatable(instanceType, "__index", function(self, key)
		if _G[functionName] then
			local result = _G[functionName](self, key)
			if result ~= nil then
				return result
			end
		end
		return originalMetamethods[instanceType]["__index"](self, key)
	end)
end

-- Route __newindex for specific instance type
function metatable.routeNewIndexFor(instanceType, functionName)
	return hookInstanceMetatable(instanceType, "__newindex", function(self, key, value)
		if _G[functionName] then
			local result = _G[functionName](self, key, value)
			if result == false then
				return -- Block write
			end
		end
		return originalMetamethods[instanceType]["__newindex"](self, key, value)
	end)
end

-- Get original method (for direct calls)
function metatable.getOriginal(instanceType, metamethod)
	if originalMetamethods[instanceType] and originalMetamethods[instanceType][metamethod] then
		return originalMetamethods[instanceType][metamethod]
	end
	return nil
end

return metatable
