local gui = {}
gui.add = {}
gui.remove = {}
gui.update = {}
gui.get = {}

local windows = {}
local screenGui
local callbackFunctions = {}
local windowZIndex = 1

-- Device detection and scaling
local function getDeviceType()
	local userInputService = game:GetService("UserInputService")
	if userInputService.TouchEnabled and not userInputService.KeyboardEnabled then
		return "mobile"
	else
		return "desktop"
	end
end

local function getScale()
	local device = getDeviceType()
	if device == "mobile" then
		return 0.9
	else
		return 0.75
	end
end

-- Color palette (darker theme)
local palette = {
	windowBg = Color3.fromRGB(12, 12, 12),
	windowTitle = Color3.fromRGB(8, 8, 8),
	elementBg = Color3.fromRGB(18, 18, 18),
	elementHover = Color3.fromRGB(28, 28, 28),
	text = Color3.fromRGB(230, 230, 230),
	border = Color3.fromRGB(35, 35, 35),
	toggleOn = Color3.fromRGB(0, 180, 0),
	toggleOff = Color3.fromRGB(80, 80, 80),
	sliderFill = Color3.fromRGB(50, 130, 210),
	closeButton = Color3.fromRGB(200, 20, 20),
	tabActive = Color3.fromRGB(50, 130, 210),
	tabInactive = Color3.fromRGB(25, 25, 25)
}

-- Initialize ScreenGui
local function initScreenGui()
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ModularGui"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

-- Register callback function
function gui.registerCallback(name, func)
	callbackFunctions[name] = func
end

-- Execute callback
local function executeCallback(name, ...)
	if callbackFunctions[name] then
		callbackFunctions[name](...)
	end
end

-- Bring window to front
local function bringToFront(windowFrame)
	windowZIndex = windowZIndex + 1
	windowFrame.ZIndex = windowZIndex
	for _, child in ipairs(windowFrame:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.ZIndex = windowZIndex
		end
	end
end

-- Calculate window height based on elements
local function calculateWindowHeight(elements, scale)
	if not elements or #elements == 0 then
		return 50 * scale
	end
	
	local maxY = 0
	local lastElement = elements[#elements]
	
	for i, elementData in ipairs(elements) do
		local posY = elementData.position.Y.Offset
		local sizeY = 0
		
		if elementData.type == "button" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (26 * scale)
		elseif elementData.type == "label" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (20 * scale)
		elseif elementData.type == "textbox" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (26 * scale)
		elseif elementData.type == "toggle" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (20 * scale)
		elseif elementData.type == "slider" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (22 * scale)
		elseif elementData.type == "dropdown" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (24 * scale)
		elseif elementData.type == "checkbox" then
			sizeY = (elementData.size and elementData.size.Y.Offset) or (20 * scale)
		end
		
		local elementBottom = posY + sizeY
		if elementBottom > maxY then
			maxY = elementBottom
		end
	end
	
	local extraSpace = 13 * scale
	
	if lastElement and lastElement.type == "dropdown" then
		local dropdownOptionsHeight = (#lastElement.options * 22 * scale) + (3 * scale)
		extraSpace = extraSpace + dropdownOptionsHeight + (20 * scale)
	end
	
	return maxY + extraSpace
end

-- Create window
function gui.add.window(name, properties)
	initScreenGui()
	
	if windows[name] then
		warn("Window '" .. name .. "' already exists")
		return
	end
	
	local scale = getScale()
	
	local hasTabs = properties.tabs and #properties.tabs > 0
	local tabBarHeight = hasTabs and (28 * scale) or 0
	
	local calculatedHeight = properties.elements and calculateWindowHeight(properties.elements, scale) or (50 * scale)
	
	if hasTabs then
		local maxTabHeight = 0
		for _, tabData in ipairs(properties.tabs) do
			if tabData.elements then
				local tabHeight = calculateWindowHeight(tabData.elements, scale)
				if tabHeight > maxTabHeight then
					maxTabHeight = tabHeight
				end
			end
		end
		calculatedHeight = maxTabHeight > 0 and maxTabHeight or (50 * scale)
	end
	
	local windowHeight = properties.size and properties.size.Y.Offset or calculatedHeight
	
	local window = Instance.new("Frame")
	window.Name = name
	window.Size = UDim2.new(0, (properties.size and properties.size.X.Offset) or (400 * scale), 0, windowHeight + tabBarHeight)
	window.Position = properties.position or UDim2.new(0.5, -((properties.size and properties.size.X.Offset or 400 * scale) / 2), 0.5, -((windowHeight + tabBarHeight) / 2))
	window.BackgroundColor3 = properties.colors and properties.colors.bg or palette.windowBg
	window.BackgroundTransparency = 0.15
	window.BorderSizePixel = 0
	window.Visible = properties.visible ~= false
	window.Parent = screenGui
	
	bringToFront(window)
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 24 * scale)
	titleBar.BackgroundColor3 = properties.colors and properties.colors.title or palette.windowTitle
	titleBar.BackgroundTransparency = 0
	titleBar.BorderSizePixel = 0
	titleBar.Parent = window
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, properties.closeable and -(24 * scale) or 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = properties.title or name
	titleLabel.TextColor3 = properties.colors and properties.colors.text or palette.text
	titleLabel.Font = Enum.Font.SourceSans
	titleLabel.TextSize = 14.7 * scale
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = titleBar
	
	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingLeft = UDim.new(0, 8 * scale)
	titlePadding.Parent = titleLabel
	
	-- Close button
	if properties.closeable then
		local closeButtonSize = 17.1 * scale
		local closeButton = Instance.new("TextButton")
		closeButton.Name = "CloseButton"
		closeButton.Size = UDim2.new(0, closeButtonSize, 0, closeButtonSize)
		closeButton.Position = UDim2.new(1, -(closeButtonSize + 3 * scale), 0, (24 * scale - closeButtonSize) / 2)
		closeButton.BackgroundColor3 = palette.closeButton
		closeButton.BackgroundTransparency = 0
		closeButton.BorderSizePixel = 0
		closeButton.Text = "×"
		closeButton.TextColor3 = palette.text
		closeButton.Font = Enum.Font.SourceSans
		closeButton.TextSize = 20 * scale
		closeButton.Parent = titleBar
		
		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0.5, 0)
		closeCorner.Parent = closeButton
		
		closeButton.MouseEnter:Connect(function()
			closeButton.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
		end)
		
		closeButton.MouseLeave:Connect(function()
			closeButton.BackgroundColor3 = palette.closeButton
		end)
		
		closeButton.MouseButton1Click:Connect(function()
			closeWindow(name)
		end)
	end
	
	-- Dragging
	if properties.draggable then
		local dragging = false
		local dragInput, mousePos, framePos
		
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				bringToFront(window)
				dragging = true
				mousePos = input.Position
				framePos = window.Position
				
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		
		titleBar.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		
		game:GetService("UserInputService").InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				window.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
			end
		end)
	end
	
	window.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			bringToFront(window)
		end
	end)
	
	-- Tab bar
	local tabBar, tabButtons, tabContainers
	if hasTabs then
		tabBar = Instance.new("Frame")
		tabBar.Name = "TabBar"
		tabBar.Size = UDim2.new(1, 0, 0, 28 * scale)
		tabBar.Position = UDim2.new(0, 0, 0, 24 * scale)
		tabBar.BackgroundColor3 = palette.windowTitle
		tabBar.BackgroundTransparency = 0
		tabBar.BorderSizePixel = 0
		tabBar.Parent = window
		
		tabButtons = {}
		tabContainers = {}
		
		local tabWidth = 1 / #properties.tabs
		
		for i, tabData in ipairs(properties.tabs) do
			local tabButton = Instance.new("TextButton")
			tabButton.Name = "Tab_" .. tabData.name
			tabButton.Size = UDim2.new(tabWidth, -2 * scale, 1, -4 * scale)
			tabButton.Position = UDim2.new(tabWidth * (i - 1), 1 * scale, 0, 2 * scale)
			tabButton.BackgroundColor3 = i == 1 and palette.tabActive or palette.tabInactive
			tabButton.BackgroundTransparency = 0.15
			tabButton.BorderSizePixel = 0
			tabButton.Text = tabData.name
			tabButton.TextColor3 = palette.text
			tabButton.Font = Enum.Font.SourceSans
			tabButton.TextSize = 13.65 * scale
			tabButton.Parent = tabBar
			
			local tabCorner = Instance.new("UICorner")
			tabCorner.CornerRadius = UDim.new(0, 3 * scale)
			tabCorner.Parent = tabButton
			
			local tabContainer = Instance.new("Frame")
			tabContainer.Name = "TabContainer_" .. tabData.name
			tabContainer.Size = UDim2.new(1, 0, 1, -(24 * scale + 28 * scale))
			tabContainer.Position = UDim2.new(0, 0, 0, 24 * scale + 28 * scale)
			tabContainer.BackgroundTransparency = 1
			tabContainer.ClipsDescendants = false
			tabContainer.Visible = i == 1
			tabContainer.Parent = window
			
			tabButtons[tabData.name] = tabButton
			tabContainers[tabData.name] = tabContainer
			
			tabButton.MouseButton1Click:Connect(function()
				for tabName, btn in pairs(tabButtons) do
					btn.BackgroundColor3 = palette.tabInactive
					tabContainers[tabName].Visible = false
				end
				
				tabButton.BackgroundColor3 = palette.tabActive
				tabContainer.Visible = true
				
				if tabData.onSwitch then
					executeCallback(tabData.onSwitch, tabData.name)
				end
			end)
			
			tabButton.MouseEnter:Connect(function()
				if tabButton.BackgroundColor3 ~= palette.tabActive then
					tabButton.BackgroundColor3 = palette.elementHover
				end
			end)
			
			tabButton.MouseLeave:Connect(function()
				if tabButton.BackgroundColor3 ~= palette.tabActive then
					tabButton.BackgroundColor3 = palette.tabInactive
				end
			end)
		end
	end
	
	-- Container for elements (or use first tab container if tabs exist)
	local container
	if hasTabs then
		container = tabContainers[properties.tabs[1].name]
	else
		container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.new(1, 0, 1, -(24 * scale))
		container.Position = UDim2.new(0, 0, 0, 24 * scale)
		container.BackgroundTransparency = 1
		container.ClipsDescendants = false
		container.Parent = window
	end
	
	-- Store window data
	windows[name] = {
		frame = window,
		container = container,
		elements = {},
		scale = scale,
		tabs = hasTabs and {
			buttons = tabButtons,
			containers = tabContainers
		} or nil
	}
	
	-- Create elements (in appropriate tab containers if tabs exist)
	if properties.elements then
		for i, elementData in ipairs(properties.elements) do
			local targetContainer = container
			if hasTabs and elementData.tab then
				targetContainer = tabContainers[elementData.tab]
			end
			createElement(name, elementData, i, targetContainer)
		end
	end
	
	-- Create tab-specific elements
	if hasTabs then
		for _, tabData in ipairs(properties.tabs) do
			if tabData.elements then
				for i, elementData in ipairs(tabData.elements) do
					createElement(name, elementData, i, tabContainers[tabData.name])
				end
			end
		end
	end
	
	return window
end

-- Create element
function createElement(windowName, elementData, index, targetContainer)
	local windowData = windows[windowName]
	if not windowData then return end
	
	local scale = windowData.scale
	local element
	local container = targetContainer or windowData.container
	
	if elementData.type == "button" then
		element = Instance.new("TextButton")
		element.Size = elementData.size or UDim2.new(0, 150 * scale, 0, 26 * scale)
		element.Position = elementData.position
		element.BackgroundColor3 = elementData.colors and elementData.colors.bg or palette.elementBg
		element.BackgroundTransparency = 0.15
		element.BorderSizePixel = 0
		element.Text = elementData.text
		element.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		element.Font = Enum.Font.SourceSans
		element.TextSize = 13.65 * scale
		element.Parent = container
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3 * scale)
		corner.Parent = element
		
		element.MouseEnter:Connect(function()
			element.BackgroundColor3 = elementData.colors and elementData.colors.hover or palette.elementHover
		end)
		
		element.MouseLeave:Connect(function()
			element.BackgroundColor3 = elementData.colors and elementData.colors.bg or palette.elementBg
		end)
		
		if elementData.onClick then
			element.MouseButton1Click:Connect(function()
				executeCallback(elementData.onClick)
			end)
		end
		
	elseif elementData.type == "label" then
		element = Instance.new("TextLabel")
		element.Size = elementData.size or UDim2.new(0, 200 * scale, 0, 20 * scale)
		element.Position = elementData.position
		element.BackgroundTransparency = 1
		element.Text = elementData.text
		element.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		element.Font = Enum.Font.SourceSans
		element.TextSize = 13.65 * scale
		element.TextXAlignment = Enum.TextXAlignment.Left
		element.Parent = container
		
	elseif elementData.type == "textbox" then
		element = Instance.new("TextBox")
		element.Size = elementData.size or UDim2.new(0, 200 * scale, 0, 26 * scale)
		element.Position = elementData.position
		element.BackgroundColor3 = elementData.colors and elementData.colors.bg or palette.elementBg
		element.BackgroundTransparency = 0.15
		element.BorderSizePixel = 1
		element.BorderColor3 = elementData.colors and elementData.colors.border or palette.border
		element.PlaceholderText = elementData.placeholder or ""
		element.Text = ""
		element.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		element.Font = Enum.Font.SourceSans
		element.TextSize = 13.65 * scale
		element.ClearTextOnFocus = false
		element.Parent = container
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3 * scale)
		corner.Parent = element
		
		if elementData.onChange then
			element.FocusLost:Connect(function()
				executeCallback(elementData.onChange, element.Text)
			end)
		end
		
	elseif elementData.type == "toggle" then
		local toggleContainer = Instance.new("Frame")
		toggleContainer.Size = elementData.size or UDim2.new(0, 200 * scale, 0, 20 * scale)
		toggleContainer.Position = elementData.position
		toggleContainer.BackgroundTransparency = 1
		toggleContainer.Parent = container
		
		local toggleFrame = Instance.new("Frame")
		toggleFrame.Size = UDim2.new(0, 40 * scale, 0, 20 * scale)
		toggleFrame.Position = UDim2.new(0, 0, 0, 0)
		toggleFrame.BackgroundColor3 = elementData.colors and elementData.colors.disabled or palette.toggleOff
		toggleFrame.BackgroundTransparency = 0.15
		toggleFrame.BorderSizePixel = 0
		toggleFrame.Parent = toggleContainer
		
		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(1, 0)
		toggleCorner.Parent = toggleFrame
		
		local toggleHandle = Instance.new("Frame")
		toggleHandle.Size = UDim2.new(0, 16 * scale, 0, 16 * scale)
		toggleHandle.Position = UDim2.new(0, 2 * scale, 0.5, -(8 * scale))
		toggleHandle.BackgroundColor3 = palette.text
		toggleHandle.BackgroundTransparency = 0
		toggleHandle.BorderSizePixel = 0
		toggleHandle.Parent = toggleFrame
		
		local handleCorner = Instance.new("UICorner")
		handleCorner.CornerRadius = UDim.new(1, 0)
		handleCorner.Parent = toggleHandle
		
		local toggleLabel = Instance.new("TextLabel")
		toggleLabel.Size = UDim2.new(1, -(48 * scale), 1, 0)
		toggleLabel.Position = UDim2.new(0, 48 * scale, 0, 0)
		toggleLabel.BackgroundTransparency = 1
		toggleLabel.Text = elementData.text or ""
		toggleLabel.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		toggleLabel.Font = Enum.Font.SourceSans
		toggleLabel.TextSize = 13.65 * scale
		toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
		toggleLabel.Parent = toggleContainer
		
		local state = elementData.defaultState or false
		
		local function updateToggle(newState)
			state = newState
			if state then
				toggleFrame.BackgroundColor3 = elementData.colors and elementData.colors.enabled or palette.toggleOn
				game:GetService("TweenService"):Create(toggleHandle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -(18 * scale), 0.5, -(8 * scale))}):Play()
			else
				toggleFrame.BackgroundColor3 = elementData.colors and elementData.colors.disabled or palette.toggleOff
				game:GetService("TweenService"):Create(toggleHandle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 2 * scale, 0.5, -(8 * scale))}):Play()
			end
			
			if elementData.onToggle then
				executeCallback(elementData.onToggle, state)
			end
		end
		
		updateToggle(state)
		
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.Parent = toggleContainer
		
		button.MouseButton1Click:Connect(function()
			updateToggle(not state)
		end)
		
		element = toggleContainer
		
	elseif elementData.type == "slider" then
		local sliderContainer = Instance.new("Frame")
		sliderContainer.Size = elementData.size or UDim2.new(0, 200 * scale, 0, 22 * scale)
		sliderContainer.Position = elementData.position
		sliderContainer.BackgroundTransparency = 1
		sliderContainer.Parent = container
		
		local min = elementData.min or 0
		local max = elementData.max or 100
		local value = elementData.default or min
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 12 * scale)
		label.BackgroundTransparency = 1
		label.Text = (elementData.text or "") .. " (" .. tostring(math.floor(value)) .. ")"
		label.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		label.Font = Enum.Font.SourceSans
		label.TextSize = 11.55 * scale
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = sliderContainer
		
		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(1, 0, 0, 4 * scale)
		sliderBg.Position = UDim2.new(0, 0, 0, 16 * scale)
		sliderBg.BackgroundColor3 = elementData.colors and elementData.colors.bg or palette.elementBg
		sliderBg.BackgroundTransparency = 0.15
		sliderBg.BorderSizePixel = 0
		sliderBg.Parent = sliderContainer
		
		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(1, 0)
		sliderCorner.Parent = sliderBg
		
		local sliderFill = Instance.new("Frame")
		local initialPercent = (value - min) / (max - min)
		sliderFill.Size = UDim2.new(initialPercent, 0, 1, 0)
		sliderFill.BackgroundColor3 = elementData.colors and elementData.colors.fill or palette.sliderFill
		sliderFill.BackgroundTransparency = 0
		sliderFill.BorderSizePixel = 0
		sliderFill.Parent = sliderBg
		
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = sliderFill
		
		local sliderHandle = Instance.new("Frame")
		sliderHandle.Size = UDim2.new(0, 12 * scale, 0, 12 * scale)
		sliderHandle.Position = UDim2.new(1, -(6 * scale), 0.5, -(6 * scale))
		sliderHandle.BackgroundColor3 = palette.text
		sliderHandle.BackgroundTransparency = 0
		sliderHandle.BorderSizePixel = 0
		sliderHandle.Parent = sliderFill
		
		local handleCorner = Instance.new("UICorner")
		handleCorner.CornerRadius = UDim.new(1, 0)
		handleCorner.Parent = sliderHandle
		
		local dragging = false
		
		local function updateSlider(newValue)
			value = math.clamp(newValue, min, max)
			local percent = (value - min) / (max - min)
			sliderFill.Size = UDim2.new(percent, 0, 1, 0)
			label.Text = (elementData.text or "") .. " (" .. tostring(math.floor(value)) .. ")"
			
			if elementData.onSlide then
				executeCallback(elementData.onSlide, value)
			end
		end
		
		sliderBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
				local percent = relativeX / sliderBg.AbsoluteSize.X
				updateSlider(min + (max - min) * percent)
			end
		end)
		
		sliderBg.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		
		sliderBg.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
				local percent = relativeX / sliderBg.AbsoluteSize.X
				updateSlider(min + (max - min) * percent)
			end
		end)
		
		element = sliderContainer
		
	elseif elementData.type == "dropdown" then
		local dropdownContainer = Instance.new("Frame")
		dropdownContainer.Size = elementData.size or UDim2.new(0, 200 * scale, 0, 24 * scale)
		dropdownContainer.Position = elementData.position
		dropdownContainer.BackgroundTransparency = 1
		dropdownContainer.ClipsDescendants = false
		dropdownContainer.Parent = container
		
		local dropdownButton = Instance.new("TextButton")
		dropdownButton.Size = UDim2.new(1, 0, 1, 0)
		dropdownButton.BackgroundColor3 = elementData.colors and elementData.colors.bg or palette.elementBg
		dropdownButton.BackgroundTransparency = 0.15
		dropdownButton.BorderSizePixel = 0
		dropdownButton.Text = elementData.default or elementData.options[1] or ""
		dropdownButton.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		dropdownButton.Font = Enum.Font.SourceSans
		dropdownButton.TextSize = 13.65 * scale
		dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
		dropdownButton.Parent = dropdownContainer
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 3 * scale)
		buttonCorner.Parent = dropdownButton
		
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 6 * scale)
		padding.Parent = dropdownButton
		
		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 18 * scale, 1, 0)
		arrow.Position = UDim2.new(1, -(18 * scale), 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = palette.text
		arrow.Font = Enum.Font.SourceSans
		arrow.TextSize = 10.5 * scale
		arrow.Parent = dropdownButton
		
		local optionsFrame = Instance.new("Frame")
		optionsFrame.Size = UDim2.new(1, 0, 0, #elementData.options * 22 * scale)
		optionsFrame.Position = UDim2.new(0, 0, 1, 3 * scale)
		optionsFrame.BackgroundColor3 = palette.elementBg
		optionsFrame.BackgroundTransparency = 0.1
		optionsFrame.BorderSizePixel = 0
		optionsFrame.Visible = false
		optionsFrame.ZIndex = 1000
		optionsFrame.Parent = dropdownContainer
		
		local optionsCorner = Instance.new("UICorner")
		optionsCorner.CornerRadius = UDim.new(0, 3 * scale)
		optionsCorner.Parent = optionsFrame
		
		for i, option in ipairs(elementData.options) do
			local optionButton = Instance.new("TextButton")
			optionButton.Size = UDim2.new(1, 0, 0, 22 * scale)
			optionButton.Position = UDim2.new(0, 0, 0, (i - 1) * 22 * scale)
			optionButton.BackgroundColor3 = palette.elementBg
			optionButton.BackgroundTransparency = 1
			optionButton.BorderSizePixel = 0
			optionButton.Text = option
			optionButton.TextColor3 = palette.text
			optionButton.Font = Enum.Font.SourceSans
			optionButton.TextSize = 13.65 * scale
			optionButton.TextXAlignment = Enum.TextXAlignment.Left
			optionButton.ZIndex = 1001
			optionButton.Parent = optionsFrame
			
			local optionPadding = Instance.new("UIPadding")
			optionPadding.PaddingLeft = UDim.new(0, 6 * scale)
			optionPadding.Parent = optionButton
			
			optionButton.MouseEnter:Connect(function()
				optionButton.BackgroundTransparency = 0.5
			end)
			
			optionButton.MouseLeave:Connect(function()
				optionButton.BackgroundTransparency = 1
			end)
			
			optionButton.MouseButton1Click:Connect(function()
				dropdownButton.Text = option
				optionsFrame.Visible = false
				if elementData.onSelect then
					executeCallback(elementData.onSelect, option)
				end
			end)
		end
		
		dropdownButton.MouseButton1Click:Connect(function()
			optionsFrame.Visible = not optionsFrame.Visible
		end)
		
		element = dropdownContainer
		
	elseif elementData.type == "checkbox" then
		local checkboxContainer = Instance.new("Frame")
		checkboxContainer.Size = elementData.size or UDim2.new(0, 200 * scale, 0, 20 * scale)
		checkboxContainer.Position = elementData.position
		checkboxContainer.BackgroundTransparency = 1
		checkboxContainer.Parent = container
		
		local checkboxFrame = Instance.new("Frame")
		checkboxFrame.Size = UDim2.new(0, 18 * scale, 0, 18 * scale)
		checkboxFrame.Position = UDim2.new(0, 0, 0, 1 * scale)
		checkboxFrame.BackgroundColor3 = palette.elementBg
		checkboxFrame.BackgroundTransparency = 0.15
		checkboxFrame.BorderSizePixel = 1
		checkboxFrame.BorderColor3 = palette.border
		checkboxFrame.Parent = checkboxContainer
		
		local checkboxCorner = Instance.new("UICorner")
		checkboxCorner.CornerRadius = UDim.new(0, 3 * scale)
		checkboxCorner.Parent = checkboxFrame
		
		local checkMark = Instance.new("TextLabel")
		checkMark.Size = UDim2.new(1, 0, 1, 0)
		checkMark.BackgroundTransparency = 1
		checkMark.Text = ""
		checkMark.TextColor3 = palette.text
		checkMark.Font = Enum.Font.SourceSans
		checkMark.TextSize = 14.7 * scale
		checkMark.Parent = checkboxFrame
		
		local checkboxLabel = Instance.new("TextLabel")
		checkboxLabel.Size = UDim2.new(1, -(26 * scale), 1, 0)
		checkboxLabel.Position = UDim2.new(0, 26 * scale, 0, 0)
		checkboxLabel.BackgroundTransparency = 1
		checkboxLabel.Text = elementData.text
		checkboxLabel.TextColor3 = elementData.colors and elementData.colors.text or palette.text
		checkboxLabel.Font = Enum.Font.SourceSans
		checkboxLabel.TextSize = 13.65 * scale
		checkboxLabel.TextXAlignment = Enum.TextXAlignment.Left
		checkboxLabel.Parent = checkboxContainer
		
		local state = elementData.defaultState or false
		
		local function updateCheckbox(newState)
			state = newState
			checkMark.Text = state and "✓" or ""
			
			if elementData.onChange then
				executeCallback(elementData.onChange, state)
			end
		end
		
		updateCheckbox(state)
		
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.Parent = checkboxContainer
		
		button.MouseButton1Click:Connect(function()
			updateCheckbox(not state)
		end)
		
		element = checkboxContainer
	end
	
	windowData.elements[index] = {
		instance = element,
		data = elementData
	}
end

-- Remove window
function gui.remove.window(name)
	if windows[name] then
		windows[name].frame:Destroy()
		windows[name] = nil
	end
end

-- Update element
function gui.update.element(windowName, elementIndex, property, value)
	local windowData = windows[windowName]
	if not windowData or not windowData.elements[elementIndex] then return end
	
	local element = windowData.elements[elementIndex]
	element.data[property] = value
	
	element.instance:Destroy()
	createElement(windowName, element.data, elementIndex)
end

-- Get element value
function gui.get.elementValue(windowName, elementIndex)
	local windowData = windows[windowName]
	if not windowData or not windowData.elements[elementIndex] then return nil end
	
	local element = windowData.elements[elementIndex]
	local elementType = element.data.type
	
	if elementType == "textbox" then
		return element.instance.Text
	elseif elementType == "toggle" or elementType == "checkbox" then
		return element.data.currentState
	elseif elementType == "slider" then
		return element.data.currentValue
	elseif elementType == "dropdown" then
		return element.instance:FindFirstChild("TextButton").Text
	end
	
	return nil
end

-- Switch to a specific tab
function gui.switchTab(windowName, tabName)
	local windowData = windows[windowName]
	if not windowData or not windowData.tabs then return end
	
	for name, btn in pairs(windowData.tabs.buttons) do
		btn.BackgroundColor3 = palette.tabInactive
		windowData.tabs.containers[name].Visible = false
	end
	
	if windowData.tabs.buttons[tabName] then
		windowData.tabs.buttons[tabName].BackgroundColor3 = palette.tabActive
		windowData.tabs.containers[tabName].Visible = true
	end
end

-- Close window (external function)
function closeWindow(name)
	gui.remove.window(name)
end

-- TEST CODE
print("Working on it boss!")
task.wait(2)

gui.registerCallback("testButton", function()
	print("Button clicked!")
end)

gui.registerCallback("testToggle", function(state)
	print("Toggle state:", state)
end)

gui.registerCallback("testSlider", function(value)
	print("Slider value:", value)
end)

gui.registerCallback("testDropdown", function(option)
	print("Selected option:", option)
end)

gui.registerCallback("testCheckbox", function(state)
	print("Checkbox state:", state)
end)

gui.registerCallback("testTextbox", function(text)
	print("Text entered:", text)
end)

gui.registerCallback("onTabSwitch", function(tabName)
	print("Switched to tab:", tabName)
end)

gui.add.window("TestWindow", {
	title = "GUI Test Window",
	closeable = true,
	draggable = true,
	tabs = {
		{
			name = "Main",
			onSwitch = "onTabSwitch",
			elements = {
				{
					type = "label",
					text = "Main Tab Content",
					position = UDim2.new(0, 10, 0, 8),
					size = UDim2.new(1, -20, 0, 20)
				},
				{
					type = "button",
					text = "Click Me",
					position = UDim2.new(0, 10, 0, 32),
					size = UDim2.new(1, -20, 0, 26),
					onClick = "testButton"
				},
				{
					type = "toggle",
					text = "Enable Feature",
					position = UDim2.new(0, 10, 0, 62),
					size = UDim2.new(1, -20, 0, 20),
					defaultState = false,
					onToggle = "testToggle"
				},
				{
					type = "dropdown",
					position = UDim2.new(0, 10, 0, 86),
					size = UDim2.new(1, -20, 0, 24),
					options = {"Option 1", "Option 2", "Option 3", "Option 4"},
					default = "Option 1",
					onSelect = "testDropdown"
				}
			}
		},
		{
			name = "Settings",
			onSwitch = "onTabSwitch",
			elements = {
				{
					type = "label",
					text = "Settings Tab Content",
					position = UDim2.new(0, 10, 0, 8),
					size = UDim2.new(1, -20, 0, 20)
				},
				{
					type = "slider",
					text = "Volume",
					position = UDim2.new(0, 10, 0, 32),
					size = UDim2.new(1, -20, 0, 22),
					min = 0,
					max = 100,
					default = 50,
					onSlide = "testSlider"
				},
				{
					type = "checkbox",
					text = "Accept Terms",
					position = UDim2.new(0, 10, 0, 58),
					size = UDim2.new(1, -20, 0, 20),
					defaultState = false,
					onChange = "testCheckbox"
				}
			}
		},
		{
			name = "Info",
			onSwitch = "onTabSwitch",
			elements = {
				{
					type = "label",
					text = "Info Tab Content",
					position = UDim2.new(0, 10, 0, 8),
					size = UDim2.new(1, -20, 0, 20)
				},
				{
					type = "textbox",
					placeholder = "Enter text here...",
					position = UDim2.new(0, 10, 0, 32),
					size = UDim2.new(1, -20, 0, 26),
					onChange = "testTextbox"
				}
			}
		}
	}
})

return gui
