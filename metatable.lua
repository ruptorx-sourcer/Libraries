local metatable = {}

local routes = {}
local originalMetamethods = {}

-- Cache
local getgenv = getgenv or function() return _G end
local getnamecallmethod = getnamecallmethod
local hookmetamethod = hookmetamethod
local newcclosure = newcclosure or function(f) return f end
local checkcaller = checkcaller or function() return false end

-- Route __index (property reads)
function metatable.routeIndex(functionName)
	if not originalMetamethods["__index"] then
		originalMetamethods["__index"] = hookmetamethod(game, "__index", newcclosure(function(self, key)
			-- Call routed function if it exists
			if _G[functionName] then
				local result = _G[functionName](self, key)
				-- If function returns a value, use it
				if result ~= nil then
					return result
				end
			end
			
			-- Otherwise call original
			return originalMetamethods["__index"](self, key)
		end))
	end
end

-- Route __newindex (property writes)
function metatable.routeNewIndex(functionName)
	if not originalMetamethods["__newindex"] then
		originalMetamethods["__newindex"] = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
			-- Call routed function if it exists
			if _G[functionName] then
				local result = _G[functionName](self, key, value)
				-- If function returns false, BLOCK the write
				if result == false then
					return
				end
			end
			
			-- Otherwise allow the write
			return originalMetamethods["__newindex"](self, key, value)
		end))
	end
end

-- Route __namecall (method calls)
function metatable.routeNamecall(functionName)
	if not originalMetamethods["__namecall"] then
		originalMetamethods["__namecall"] = hookmetamethod(game, "__namecall", newcclosure(function(...)
			local args = {...}
			local method = getnamecallmethod()
			
			-- Call routed function if it exists
			if _G[functionName] then
				local result = _G[functionName](method, ...)
				if result ~= nil then
					return result
				end
			end
			
			return originalMetamethods["__namecall"](...)
		end))
	end
end

-- Hook
function metatable.hookFunc(targetFunction, functionName)
	local originalFunc = hookfunction(targetFunction, newcclosure(function(...)
		if _G[functionName] then
			local result = _G[functionName](...)
			if result ~= nil then
				return result
			end
		end
		return originalFunc(...)
	end))
end

return metatable
