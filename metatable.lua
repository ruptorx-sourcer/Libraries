local metatable = {}

local routes = {}
local originalMetamethods = {}
local originalFunctions = {}

-- Cache
local getgenv = getgenv or function() return _G end
local getnamecallmethod = getnamecallmethod
local hookmetamethod = hookmetamethod
local hookfunction = hookfunction
local newcclosure = newcclosure or function(f) return f end
local checkcaller = checkcaller or function() return false end

-- Route a metatable method to a function
function metatable.route(metamethodName, functionName)
	if not routes[metamethodName] then
		routes[metamethodName] = {}
	end
	
	table.insert(routes[metamethodName], functionName)
	
	-- Hook the metamethod if not already hooked
	if not originalMetamethods[metamethodName] then
		if metamethodName == "__namecall" then
			originalMetamethods[metamethodName] = hookmetamethod(game, metamethodName, newcclosure(function(...)
				local args = {...}
				local method = getnamecallmethod()
				
				-- Check if this method has routes
				if routes[metamethodName] then
					for _, funcName in ipairs(routes[metamethodName]) do
						if _G[funcName] then
							local result = _G[funcName](method, ...)
							if result ~= nil then
								return result
							end
						end
					end
				end
				
				return originalMetamethods[metamethodName](...)
			end))
		elseif metamethodName == "__index" then
			originalMetamethods[metamethodName] = hookmetamethod(game, metamethodName, newcclosure(function(...)
				local self, key = ...
				
				-- Check if this method has routes
				if routes[metamethodName] then
					for _, funcName in ipairs(routes[metamethodName]) do
						if _G[funcName] then
							local result = _G[funcName](self, key)
							if result ~= nil then
								return result
							end
						end
					end
				end
				
				return originalMetamethods[metamethodName](...)
			end))
		elseif metamethodName == "__newindex" then
			originalMetamethods[metamethodName] = hookmetamethod(game, metamethodName, newcclosure(function(...)
				local self, key, value = ...
				
				-- Check if this method has routes
				if routes[metamethodName] then
					for _, funcName in ipairs(routes[metamethodName]) do
						if _G[funcName] then
							local result = _G[funcName](self, key, value)
							if result ~= nil then
								return result
							end
						end
					end
				end
				
				return originalMetamethods[metamethodName](...)
			end))
		end
	end
end

-- Hook a specific function
function metatable.hookFunction(targetFunction, functionName)
	if not originalFunctions[targetFunction] then
		originalFunctions[targetFunction] = hookfunction(targetFunction, newcclosure(function(...)
			if _G[functionName] then
				local result = _G[functionName](...)
				if result ~= nil then
					return result
				end
			end
			
			return originalFunctions[targetFunction](...)
		end))
	end
end

return metatable
