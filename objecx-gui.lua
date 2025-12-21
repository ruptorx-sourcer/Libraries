local gui = {}
gui.add = {}
gui.remove = {}
gui.update = {}
gui.get = {}

local windows = {}
local notifications = {}
local notificationYOffset = 10
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
		return 1  -- Changed from 0.9 to 1
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

-- Notification type colors
local notificationColors = {
	failure = Color3.fromRGB(200, 50, 50),
	warning = Color3.fromRGB(220, 180, 50),
	success = Color3.fromRGB(50, 200, 80),
	idle = Color3.fromRGB(100, 100, 100),
	error = Color3.fromRGB(220, 40, 40),
	crash = Color3.fromRGB(150, 0, 0),
	hang = Color3.fromRGB(180, 140, 0),
	working = Color3.fromRGB(80, 150, 220),
	critical = Color3.fromRGB(255, 0, 0),
	done = Color3.fromRGB(60, 180, 100),
	normal = Color3.fromRGB(80, 80, 80)
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
	
	local extraSpace = 8 * scale
	
	-- Add extra space if last element is a dropdown
	if lastElement and lastElement.type == "dropdown" then
		local dropdownOptionsHeight = (#lastElement.options * 22 * scale) + (3 * scale)
		extraSpace = extraSpace + dropdownOptionsHeight + (20 * scale)
	end
	
	-- Add extra space if last element is a label (text element)
	if lastElement and lastElement.type == "label" then
		extraSpace = extraSpace + (13 * scale)
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

-- Create notification
function gui.add.notification(notificationName, properties)
	initScreenGui()
	
	if notifications[notificationName] then
		warn("Notification '" .. notificationName .. "' already exists")
		return
	end
	
	local scale = getScale()
	local deviceType = getDeviceType()
	
	local notifWidth = 300 * scale
	local notifHeight = properties.imageLabel and properties.imageLabel ~= "" and properties.imageLabel ~= "0" and (80 * scale) or (60 * scale)
	
	local notifFrame = Instance.new("Frame")
	notifFrame.Name = notificationName
	notifFrame.Size = UDim2.new(0, notifWidth, 0, notifHeight)
	
	if deviceType == "mobile" then
		notifFrame.Position = UDim2.new(0.5, -(notifWidth / 2), 0, -notifHeight - 20)
	else
		notifFrame.Position = UDim2.new(1, notifWidth + 20, 0, notificationYOffset)
	end
	
	notifFrame.BackgroundColor3 = palette.windowBg
	notifFrame.BackgroundTransparency = 0.25
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = screenGui
	
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 6 * scale)
	notifCorner.Parent = notifFrame
	
	-- Time left bar
	local timeBar = Instance.new("Frame")
	timeBar.Name = "TimeBar"
	timeBar.Size = UDim2.new(1, 0, 0, 3 * scale)
	timeBar.Position = UDim2.new(0, 0, 1, -(3 * scale))
	timeBar.BackgroundColor3 = notificationColors[properties.notificationType] or notificationColors.normal
	timeBar.BackgroundTransparency = 0
	timeBar.BorderSizePixel = 0
	timeBar.Parent = notifFrame
	
	local timeBarCorner = Instance.new("UICorner")
	timeBarCorner.CornerRadius = UDim.new(0, 6 * scale)
	timeBarCorner.Parent = timeBar
	
	-- Image label (if provided)
	local contentXOffset = 10 * scale
	if properties.imageLabel and properties.imageLabel ~= "" and properties.imageLabel ~= "0" then
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "Icon"
		imageLabel.Size = UDim2.new(0, 50 * scale, 0, 50 * scale)
		imageLabel.Position = UDim2.new(0, 10 * scale, 0, 10 * scale)
		imageLabel.BackgroundTransparency = 1
		imageLabel.Image = properties.imageLabel
		imageLabel.Parent = notifFrame
		
		local imageCorner = Instance.new("UICorner")
		imageCorner.CornerRadius = UDim.new(0, 4 * scale)
		imageCorner.Parent = imageLabel
		
		contentXOffset = 70 * scale
	end
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -(contentXOffset + (properties.closeable and 30 * scale or 10 * scale)), 0, 20 * scale)
	title.Position = UDim2.new(0, contentXOffset, 0, 8 * scale)
	title.BackgroundTransparency = 1
	title.Text = properties.title or "Notification"
	title.TextColor3 = properties.titleColor or palette.text
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 15 * scale
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = notifFrame
	
	-- Description
	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Size = UDim2.new(1, -(contentXOffset + (properties.closeable and 30 * scale or 10 * scale)), 0, notifHeight - 35 * scale)
	desc.Position = UDim2.new(0, contentXOffset, 0, 28 * scale)
	desc.BackgroundTransparency = 1
	desc.Text = properties.desc or ""
	desc.TextColor3 = properties.descColor or Color3.fromRGB(200, 200, 200)
	desc.Font = Enum.Font.SourceSans
	desc.TextSize = 13 * scale
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Parent = notifFrame
	
	-- Close button (if closeable)
	if properties.closeable then
		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseButton"
		closeBtn.Size = UDim2.new(0, 20 * scale, 0, 20 * scale)
		closeBtn.Position = UDim2.new(1, -(25 * scale), 0, 5 * scale)
		closeBtn.BackgroundColor3 = palette.closeButton
		closeBtn.BackgroundTransparency = 0.3
		closeBtn.BorderSizePixel = 0
		closeBtn.Text = "×"
		closeBtn.TextColor3 = palette.text
		closeBtn.Font = Enum.Font.SourceSansBold
		closeBtn.TextSize = 16 * scale
		closeBtn.Parent = notifFrame
		
		local closeBtnCorner = Instance.new("UICorner")
		closeBtnCorner.CornerRadius = UDim.new(0.5, 0)
		closeBtnCorner.Parent = closeBtn
		
		closeBtn.MouseEnter:Connect(function()
			closeBtn.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
			closeBtn.BackgroundTransparency = 0
		end)
		
		closeBtn.MouseLeave:Connect(function()
			closeBtn.BackgroundColor3 = palette.closeButton
			closeBtn.BackgroundTransparency = 0.3
		end)
		
		closeBtn.MouseButton1Click:Connect(function()
			if properties.onClose then
				executeCallback(properties.onClose)
			else
				gui.closeNotif(notificationName)
			end
		end)
	end
	
	-- Clickable
	if properties.clickable and properties.onClick then
		local clickBtn = Instance.new("TextButton")
		clickBtn.Name = "ClickArea"
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.Parent = notifFrame
		
		clickBtn.MouseButton1Click:Connect(function()
			executeCallback(properties.onClick)
		end)
		
		clickBtn.MouseEnter:Connect(function()
			notifFrame.BackgroundTransparency = 0.15
		end)
		
		clickBtn.MouseLeave:Connect(function()
			notifFrame.BackgroundTransparency = 0.25
		end)
	end
	
	-- Store notification
	notifications[notificationName] = {
		frame = notifFrame,
		timeBar = timeBar,
		timeout = properties.timeout or 5,
		startTime = tick(),
		deviceType = deviceType
	}
	
	-- Slide in animation
	local targetPos
	if deviceType == "mobile" then
		targetPos = UDim2.new(0.5, -(notifWidth / 2), 0, notificationYOffset)
	else
		targetPos = UDim2.new(1, -(notifWidth + 10), 0, notificationYOffset)
	end
	
	notifFrame:TweenPosition(targetPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
	
	-- Update notification Y offset for next notification
	notificationYOffset = notificationYOffset + notifHeight + (10 * scale)
	
	-- Auto-close timeout
	if properties.timeout and properties.timeout > 0 then
		task.spawn(function()
			local startTime = tick()
			local duration = properties.timeout
			
			while tick() - startTime < duration do
				if not notifications[notificationName] then break end
				
				local elapsed = tick() - startTime
				local progress = 1 - (elapsed / duration)
				timeBar.Size = UDim2.new(progress, 0, 0, 3 * scale)
				
				task.wait(0.03)
			end
			
			if notifications[notificationName] then
				gui.closeNotif(notificationName)
			end
		end)
	else
		timeBar.Visible = false
	end
	
	return notifFrame
end

-- Close notification
function gui.closeNotif(notificationName)
	local notif = notifications[notificationName]
	if not notif then return end
	
	local scale = getScale()
	local notifWidth = notif.frame.Size.X.Offset
	local deviceType = notif.deviceType
	
	-- Slide out animation
	local slideOutPos
	if deviceType == "mobile" then
		slideOutPos = UDim2.new(0.5, -(notifWidth / 2), 0, -notif.frame.Size.Y.Offset - 20)
	else
		slideOutPos = UDim2.new(1, notifWidth + 20, 0, notif.frame.Position.Y.Offset)
	end
	
	notif.frame:TweenPosition(
		slideOutPos,
		Enum.EasingDirection.In,
		Enum.EasingStyle.Quad,
		0.3,
		true,
		function()
			notif.frame:Destroy()
		end
	)
	
	-- Shift remaining notifications up
	local closedHeight = notif.frame.Size.Y.Offset + (10 * scale)
	local closedYPos = notif.frame.Position.Y.Offset
	
	for name, data in pairs(notifications) do
		if data.frame.Position.Y.Offset > closedYPos then
			local newYPos = data.frame.Position.Y.Offset - closedHeight
			local newPos
			
			if data.deviceType == "mobile" then
				newPos = UDim2.new(0.5, -(notifWidth / 2), 0, newYPos)
			else
				newPos = UDim2.new(
					data.frame.Position.X.Scale,
					data.frame.Position.X.Offset,
					0,
					newYPos
				)
			end
			
			data.frame:TweenPosition(newPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
		end
	end
	
	notifications[notificationName] = nil
	notificationYOffset = notificationYOffset - closedHeight
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

return gui
