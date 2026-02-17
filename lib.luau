local getgenv = getgenv or function() return _G end

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TweenService = game:GetService("TweenService"),
	Lighting = game:GetService("Lighting"),
	HttpService = game:GetService("HttpService"),
	StarterGui = game:GetService("StarterGui"),
	LocalizationService = game:GetService("LocalizationService"),
	TextService = game:GetService("TextService"),
	CoreGui = game:GetService("CoreGui")
}
local player = Services.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

dcConnections = dcConnections or {}

local Colors = {
	Black = {
		Pure    = Color3.fromRGB(6, 6, 6),      -- row3 col1 - background principal
		Dark    = Color3.fromRGB(10, 10, 10),    -- row3 col2
		Medium  = Color3.fromRGB(50, 49, 47),    -- row2 col1 - panels
		Light   = Color3.fromRGB(62, 61, 58),    -- row2 col2 - hover
	},
	White = {
		Pure    = Color3.new(1,1,1),
		Bright  = Color3.fromRGB(240, 238, 235), -- row1 col5
		Light   = Color3.fromRGB(210, 208, 204), -- row1 col4
		Medium  = Color3.fromRGB(155, 152, 147), -- row1 col2
	},
	Glow = {White = Color3.new(1,1,1)},
	Green = {Glow = Color3.fromRGB(76,217,100)},
	Main = {
		Separator     = Color3.fromRGB(80, 80, 80),
		LightSeparator = Color3.fromRGB(120, 120, 120),
		DarkSeparator  = Color3.fromRGB(40, 40, 40),
		Shadow         = Color3.new(0, 0, 0)
	}
}

local themes = {
	Background    = Colors.Black.Dark,
	Glow          = Colors.Glow.White,
	Accent        = Colors.Black.Medium,
	LightContrast = Colors.Black.Light,
	DarkContrast  = Colors.Black.Pure,
	TextColor     = Colors.White.Pure,
	CurrentTheme  = "Dark"
}

local themes = {
	Background = Colors.Black.Dark,
	Glow = Colors.Glow.White,
	Accent = Colors.Black.Medium,
	LightContrast = Colors.Black.Light,
	DarkContrast = Colors.Black.Pure,
	TextColor = Colors.White.Pure,
	CurrentTheme = "Dark"
}

local HUB_VERSION = "v2.09"

local function updateTimeDisplay()
	local success, result = pcall(function()
		local currentTime = os.date("*t")
		local timeString = string.format("%02d:%02d", currentTime.hour, currentTime.min)
		return string.format("%s | %s", HUB_VERSION, timeString)
	end)

	return success and result or string.format("%s | Loading...", HUB_VERSION)
end

local function CreateButtonGlow(button, hoverColor, originalColor, glowColor)
	if not button or not button.Parent then return end
	glowColor = glowColor or Colors.Glow.White

	for _, child in pairs(button:GetChildren()) do
		if child.Name == "GlowBorder" then
			child:Destroy()
		end
	end

	local glowBorder = Instance.new("Frame")
	glowBorder.Name = "GlowBorder"
	glowBorder.Size = UDim2.new(1, 12, 1, 12)
	glowBorder.Position = UDim2.new(0, -6, 0, -6)
	glowBorder.BackgroundTransparency = 1
	glowBorder.ZIndex = button.ZIndex - 1
	glowBorder.Visible = false
	glowBorder.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = glowBorder

	local stroke = Instance.new("UIStroke")
	stroke.Color = glowColor
	stroke.Thickness = 2.5
	stroke.Transparency = 0.8
	stroke.Parent = glowBorder

	local gradient = Instance.new("UIGradient")
	local function getBrighterColor(color)
		local h, s, v = Color3.toHSV(color)
		v = math.min(v * 1.2, 1.0)
		return Color3.fromHSV(h, s, v)
	end

	local brighterColor = getBrighterColor(glowColor)
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, glowColor), 
		ColorSequenceKeypoint.new(0.5, brighterColor), 
		ColorSequenceKeypoint.new(1, glowColor)
	}
	gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.8), 
		ColorSequenceKeypoint.new(0.2, 0.2), 
		ColorSequenceKeypoint.new(0.8, 0.2), 
		NumberSequenceKeypoint.new(1, 0.8)
	}
	gradient.Parent = stroke

	local currentTween = nil
	local glowAnimating = false

	button.MouseEnter:Connect(function()
		if glowAnimating then return end
		glowAnimating = true
		glowBorder.Visible = true

		Services.TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = hoverColor}):Play()
		Services.TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.1}):Play()

		if currentTween then 
			currentTween:Cancel() 
			currentTween = nil
		end

		local rotateTween = Services.TweenService:Create(
			gradient, 
			TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), 
			{Rotation = 360}
		)
		currentTween = rotateTween
		rotateTween:Play()

		glowAnimating = false
	end)

	button.MouseLeave:Connect(function()
		glowAnimating = true

		Services.TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = originalColor}):Play()
		Services.TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0.8}):Play()

		if currentTween then 
			currentTween:Cancel() 
			currentTween = nil
			gradient.Rotation = 0 
		end

		task.delay(0.4, function()
			if glowBorder and glowBorder.Parent then 
				glowBorder.Visible = false 
			end
			glowAnimating = false
		end)
	end)

	return {glowBorder, stroke, gradient}
end

local function CreatePageButtonHover(button)
	if not button or not button.Parent then return end
	
	local hoverBgColor = Colors.Black.Light
	
	local hoverOverlay = Instance.new("Frame")
	hoverOverlay.Name = "HoverOverlay"
	hoverOverlay.Size = UDim2.new(1, 0, 1, 0)
	hoverOverlay.Position = UDim2.new(0, 0, 0, 0)
	hoverOverlay.BackgroundColor3 = hoverBgColor
	hoverOverlay.BackgroundTransparency = 1
	hoverOverlay.BorderSizePixel = 0
	hoverOverlay.ZIndex = button.ZIndex + 1
	hoverOverlay.Parent = button
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = hoverOverlay
	
	button.MouseEnter:Connect(function()
		Services.TweenService:Create(hoverOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.7
		}):Play()
		
		local icon = button:FindFirstChild("Icon")
		local title = button:FindFirstChild("Title")
		if icon then
			Services.TweenService:Create(icon, TweenInfo.new(0.2), {
				ImageTransparency = 0.2,
				Size = UDim2.new(0, 20, 0, 20)
			}):Play()
		end
		if title then
			Services.TweenService:Create(title, TweenInfo.new(0.2), {
				TextTransparency = 0.2,
				TextSize = 15
			}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		Services.TweenService:Create(hoverOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		
		local icon = button:FindFirstChild("Icon")
		local title = button:FindFirstChild("Title")
		local isSelected = button:FindFirstChild("Indicator") and button.Indicator.BackgroundTransparency == 0
		
		if icon then
			Services.TweenService:Create(icon, TweenInfo.new(0.2), {
				ImageTransparency = isSelected and 0 or 0.5,
				Size = UDim2.new(0, 18, 0, 18)
			}):Play()
		end
		if title then
			Services.TweenService:Create(title, TweenInfo.new(0.2), {
				TextTransparency = isSelected and 0 or 0.5,
				TextSize = 14
			}):Play()
		end
	end)
	
	return hoverOverlay
end

local utility = {
	objects = {},

	Create = function(self, instance, properties, children)
		local object = Instance.new(instance)
		for i, v in pairs(properties or {}) do 
			object[i] = v
			if typeof(v) == "Color3" then
				local theme = self:Find(themes, v)
				if theme and self.objects then
					self.objects[theme] = self.objects[theme] or {}
					self.objects[theme][i] = self.objects[theme][i] or {}
					table.insert(self.objects[theme][i], object)
				end
			end
		end
		for i, module in pairs(children or {}) do 
			if module then module.Parent = object end
		end
		return object
	end,

	Tween = function(self, instance, properties, duration, ...)
		if instance and instance.Parent then
			Services.TweenService:Create(instance, TweenInfo.new(duration, ...), properties):Play()
		end
	end,

	Pop = function(self, object, shrink)
		if not object or not object.Parent then return end
		local clone = object:Clone()
		clone.AnchorPoint = Vector2.new(0.5, 0.5)
		clone.Size = clone.Size - UDim2.new(0, shrink, 0, shrink)
		clone.Position = UDim2.new(0.5, 0, 0.5, 0)
		clone.Parent = object
		clone:ClearAllChildren()
		object.ImageTransparency = 1

		self:Tween(clone, {Size = object.Size}, 0.2)
		task.delay(0.2, function()
			if object and object.Parent then object.ImageTransparency = 0 end
			if clone and clone.Parent then clone:Destroy() end
		end)
		return clone
	end,

	Find = function(self, table, value)
		for i, v in pairs(table) do if v == value then return i end end
		return nil
	end,

	InitializeKeybind = function(self)
		self.keybinds = {}
		self.ended = {}
		Services.UserInputService.InputBegan:Connect(function(key)
			local binds = self.keybinds[key.KeyCode]
			if binds then for _, bind in pairs(binds) do bind() end end
		end)
		Services.UserInputService.InputEnded:Connect(function(key)
			if key.UserInputType == Enum.UserInputType.MouseButton1 then
				for _, callback in pairs(self.ended) do callback() end
			end
		end)
	end,

	BindToKey = function(self, key, callback)
		self.keybinds[key] = self.keybinds[key] or {}
		table.insert(self.keybinds[key], callback)
		return {
			UnBind = function()
				local binds = self.keybinds[key]
				if binds then
					for i, bind in pairs(binds) do
						if bind == callback then table.remove(binds, i) break end
					end
				end
			end
		}
	end,

	DraggingEnabled = function(self, frame, parent)
		parent = parent or frame
		local dragging = false
		local dragStart, startPos
		local currentTouchId = nil

		local dragInput

		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
				input.UserInputType == Enum.UserInputType.Touch then

				dragging = true
				dragStart = input.Position
				startPos = parent.Position

				if input.UserInputType == Enum.UserInputType.Touch then
					currentTouchId = input.KeyCode
				end

				local connection
				connection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						currentTouchId = nil
						if connection then connection:Disconnect() end
					end
				end)
			end
		end)

		frame.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				dragInput = input
			end
		end)

		Services.UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				parent:TweenPosition(
					UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
						startPos.Y.Scale, startPos.Y.Offset + delta.Y), 
					nil,
					nil,
					0.33333,
					true
				)
			end
		end)

		Services.UserInputService.TouchMoved:Connect(function(input, gameProcessed)
			if dragging and currentTouchId == input.KeyCode then
				local delta = input.Position - dragStart
				parent:TweenPosition(
					UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
						startPos.Y.Scale, startPos.Y.Offset + delta.Y), 
					nil,
					nil,
					0.33333,
					true
				)
			end
		end)

		Services.UserInputService.TouchEnded:Connect(function(input, gameProcessed)
			if currentTouchId == input.KeyCode then
				dragging = false
				currentTouchId = nil
			end
		end)
	end,

	DraggingEnded = function(self, callback) 
		table.insert(self.ended, callback) 
	end,

	KeyPressed = function(self)
		local key = Services.UserInputService.InputBegan:Wait()
		while not key.UserInputType == Enum.UserInputType.Keyboard do
			key = Services.UserInputService.InputBegan:Wait()
		end
		return key
	end,

	Sort = function(self, query, list)
		local results = {}
		for i, value in pairs(list) do
			if string.find(string.lower(value), string.lower(query)) then
				table.insert(results, value)
			end
		end
		return results
	end,
	
	Wait = function()
		return Services.RunService.Heartbeat:Wait()
	end
}

utility:InitializeKeybind()

local library = {}
local page = {}
local section = {}

library.__index = library
page.__index = page
section.__index = section

local Icons = {
	Main = "rbxassetid://102603462805125",
	Fun = "rbxassetid://82754506929523",
	Updates = "rbxassetid://106623431956692",
	Movesets = "rbxassetid://99243871319042",
	Teleport = "rbxassetid://79372497673248",
	Universal = "rbxassetid://73085793411021",
	Settings = "rbxassetid://115075597641040",
	Close = "rbxassetid://91094978625199",
	Fullscreen = "rbxassetid://135813930497865",
	Minimize = "rbxassetid://74828798969877"
}

function library.new(title)
    local container = utility:Create("ScreenGui", {
        Name = "HITTA",
        Parent = Services.CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Enabled = false
    }, {
        utility:Create("Frame", {
            Name = "Main",
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -350, 0.5, -275),
            Size = UDim2.new(0, 700, 0, 550),
            BorderSizePixel = 0,
            ZIndex = 1
        }, {
            utility:Create("ImageLabel", {
                Name = "shadow",
                ImageColor3 = Colors.Main.Shadow,
                ScaleType = Enum.ScaleType.Slice,
                BorderColor3 = Color3.new(0, 0, 0),
                BackgroundColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, 80, 1, 80),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = "rbxassetid://112971167999062",
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                SliceScale = 0.8,
                ZIndex = -100,
                BorderSizePixel = 0,
                SliceCenter = Rect.new(Vector2.new(112, 112), Vector2.new(147, 147))
            }, {
                utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6)
                })
            }),
            
            utility:Create("CanvasGroup", {
                Name = "ContentGroup",
                BackgroundTransparency = 0,
                BackgroundColor3 = themes.Background,
                Size = UDim2.new(1, 0, 1, 0),
                BorderSizePixel = 0,
                GroupTransparency = 0,
                ZIndex = 1
            }, {
                utility:Create("UICorner", {CornerRadius = UDim.new(0, 14)}),
                
                utility:Create("Frame", {
                    Name = "TopBar",
                    BackgroundColor3 = themes.DarkContrast,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    ZIndex = 2
                }, {
                    utility:Create("ImageLabel", {
                        Name = "HittaLogo",
                        Size = UDim2.new(0, 36, 0, 36),
                        Position = UDim2.new(0, 15, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://110745379320861",
                        ImageColor3 = Colors.White.Pure,
                        ImageTransparency = 0,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 3
                    }),
                    
                    utility:Create("TextLabel", {
                        Name = "Title",
                        Size = UDim2.new(0, 160, 0, 0),
                        Position = UDim2.new(0, 60, 0.7, -12),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Text = "HITTA HUB",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 22,
                        Font = Enum.Font.SourceSansBold,
                        ZIndex = 3,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    
                    utility:Create("TextLabel", {
                        Name = "VersionTime",
                        Size = UDim2.new(0, 250, 0, 0),
                        Position = UDim2.new(0, 230, 0.5, -8),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Text = updateTimeDisplay(),
                        TextColor3 = Colors.White.Medium,
                        TextSize = 16,
                        Font = Enum.Font.SourceSans,
                        ZIndex = 3,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }),
                    
                    utility:Create("Frame", {
                        Name = "TopBarSeparator",
                        AnchorPoint = Vector2.new(0, 1),
                        Position = UDim2.new(0, 0, 1, 0),
                        Size = UDim2.new(1, 0, 0, 1),
                        BackgroundColor3 = Colors.Main.Separator,
                        BorderSizePixel = 0,
                        ZIndex = 3
                    })
                }),
                
                utility:Create("Frame", {
                    Name = "SidePanel",
                    BackgroundColor3 = themes.DarkContrast,
                    Position = UDim2.new(0, 0, 0, 50),
                    Size = UDim2.new(0, 200, 1, -50),
                    BorderSizePixel = 0,
                    ZIndex = 2
                }, {
                    utility:Create("Frame", {
                        Name = "SidePanelSeparator",
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, 1, 1, 0),
                        BackgroundColor3 = Colors.Main.DarkSeparator,
                        BorderSizePixel = 0,
                        ZIndex = 3
                    }),
                    
                    utility:Create("ScrollingFrame", {
                        Name = "Pages_Container",
                        Active = true,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 15),
                        Size = UDim2.new(1, -1, 1, -30),
                        CanvasSize = UDim2.new(0, 0, 0, 450),
                        ScrollBarThickness = 0,
                        ZIndex = 3
                    }, {
                        utility:Create("UIListLayout", {
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 8)
                        })
                    })
                }),
                
                utility:Create("ScrollingFrame", {
                    Name = "MainContent",
                    Active = true,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 200, 0, 50),
                    Size = UDim2.new(1, -200, 1, -50),
                    CanvasSize = UDim2.new(0, 0, 0, 650),
                    ScrollBarThickness = 0,
                    ScrollBarImageColor3 = themes.DarkContrast,
                    ZIndex = 2,
                    ClipsDescendants = true
                }, {
                    utility:Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 2),
                        PaddingRight = UDim.new(0, 2),
                        PaddingTop = UDim.new(0, 20)
                    }),
                    utility:Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 10)
                    })
                })
            })
        })
    })

    local mainFrame = container:FindFirstChild("Main")
    local contentGroup = mainFrame:FindFirstChild("ContentGroup")
    
    if contentGroup and contentGroup:FindFirstChild("TopBar") then
        utility.DraggingEnabled(utility, contentGroup.TopBar, mainFrame)
    end

    Services.RunService.Heartbeat:Connect(function()
        if contentGroup and contentGroup.TopBar and contentGroup.TopBar:FindFirstChild("VersionTime") then
            contentGroup.TopBar.VersionTime.Text = updateTimeDisplay()
        end
    end)

    return setmetatable({
        container = container,
        mainFrame = mainFrame,
        contentGroup = contentGroup,
        pagesContainer = contentGroup and contentGroup.SidePanel.Pages_Container,
        contentArea = contentGroup and contentGroup.MainContent,
        pages = {}
    }, library)
end

function page.new(library, title, iconUrl)
	local button = utility:Create("TextButton", {
		Name = title,
		Parent = library.pagesContainer,
		BackgroundColor3 = Colors.Black.Pure,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 40),
		Position = UDim2.new(0, 8, 0, 0),
		ZIndex = 3,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		Text = "",
		TextSize = 14
	}, {
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 8)
		}),
		utility:Create("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(0, 18, 0, 18),
			ZIndex = 4,
			Image = iconUrl or "",
			ImageColor3 = Colors.White.Pure,
			ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Fit
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 38, 0.5, 0),
			Size = UDim2.new(1, -38, 1, 0),
			ZIndex = 4,
			Font = Enum.Font.GothamSemibold,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 14,
			TextTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("Frame", {
			Name = "Indicator",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = Colors.White.Pure,
			BorderSizePixel = 0,
			ZIndex = 5
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 2)
			})
		})
	})

	CreatePageButtonHover(button)

	local container = utility:Create("ScrollingFrame", {
		Name = title,
		Parent = library.contentArea,
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 1, 0),
		Position = UDim2.new(0, 2, 0, 0),
		CanvasSize = UDim2.new(0, 0, 0, 600),
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = themes.DarkContrast,
		Visible = false,
		ClipsDescendants = false
	}, {
		utility:Create("UIPadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 2)
		}),
		utility:Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 14)
		})
	})

	return setmetatable({
		library = library,
		container = container,
		button = button,
		sections = {}
	}, page)
end

function section.new(page, title, hideTitle)
	local container = utility:Create("Frame", {
		Name = title,
		Parent = page.container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 10),
		ClipsDescendants = false,
		BorderSizePixel = 0
	}, {
		utility:Create("Frame", {
			Name = "Container",
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0)
		}, {
			utility:Create("UIPadding", {
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2)
			}),
			utility:Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10)
			})
		})
	})

	return setmetatable({
		page = page,
		container = container.Container,
		colorpickers = {},
		modules = {},
		binds = {},
		lists = {},
		hideTitle = true
	}, section)
end

function library:addPage(title, iconUrl)
	local page = page.new(self, title, iconUrl)
	local button = page.button
	table.insert(self.pages, page)
	button.MouseButton1Click:Connect(function()
		self:SelectPage(page, true)
	end)
	return page
end

function page:addSection(title, hideTitle)
	local section = section.new(self, title, true)
	table.insert(self.sections, section)
	return section
end

function library:toggle()
    if self.toggling then return end
    self.toggling = true
    local mainFrame = self.mainFrame
    
    if self.position then
        utility:Tween(mainFrame, {Size = UDim2.new(0, 650, 0, 500), Position = self.position}, 0.2)
        wait(0.2)
        utility:Tween(mainFrame.Header, {Size = UDim2.new(1, 0, 0, 44)}, 0.2)
        wait(0.2)
        mainFrame.ClipsDescendants = false
        self.position = nil
    else
        self.position = mainFrame.Position
        mainFrame.ClipsDescendants = true
        utility:Tween(mainFrame.Header, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
        wait(0.2)
        utility:Tween(mainFrame, {Size = UDim2.new(0, 650, 0, 0), Position = self.position + UDim2.new(0, 0, 0, 500)}, 0.2)
        wait(0.2)
    end
    self.toggling = false
end

function library:Notify(title, text, callback)
	if self.activeNotification then self.activeNotification = self.activeNotification() end
	local notification = utility:Create("ImageLabel", {
		Name = "Notification",
		Parent = self.container,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 200, 0, 60),
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.Background,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(4, 4, 296, 296),
		ZIndex = 3,
		ClipsDescendants = true
	}, {
		utility:Create("ImageLabel", {Name = "Flash", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "rbxassetid://4641149554", ImageColor3 = Colors.White.Pure, ZIndex = 5}),
		utility:Create("ImageLabel", {Name = "Glow", BackgroundTransparency = 1, Position = UDim2.new(0, -15, 0, -15), Size = UDim2.new(1, 30, 1, 30), ZIndex = 2, Image = "rbxassetid://5028857084", ImageColor3 = themes.Glow, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(24, 24, 276, 276)}),
		utility:Create("TextLabel", {Name = "Title", BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(1, -40, 0, 16), ZIndex = 4, Font = Enum.Font.GothamSemibold, TextColor3 = Colors.White.Pure, TextSize = 14.000, TextXAlignment = Enum.TextXAlignment.Left}),
		utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Position = UDim2.new(0, 10, 1, -24), Size = UDim2.new(1, -40, 0, 16), ZIndex = 4, Font = Enum.Font.Gotham, TextColor3 = Colors.White.Pure, TextSize = 12.000, TextXAlignment = Enum.TextXAlignment.Left}),
		utility:Create("ImageButton", {Name = "Accept", BackgroundTransparency = 1, Position = UDim2.new(1, -26, 0, 8), Size = UDim2.new(0, 16, 0, 16), Image = "rbxassetid://5012538259", ImageColor3 = Colors.White.Pure, ZIndex = 4}),
		utility:Create("ImageButton", {Name = "Decline", BackgroundTransparency = 1, Position = UDim2.new(1, -26, 1, -24), Size = UDim2.new(0, 16, 0, 16), Image = "rbxassetid://5012538583", ImageColor3 = Colors.White.Pure, ZIndex = 4})
	})
	utility.DraggingEnabled(utility, notification)
	title = title or "Notification"
	text = text or ""
	notification.Title.Text = title
	notification.Text.Text = text
	local padding = 10
	local textSize = Services.TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(math.huge, 16))
	notification.Position = library.lastNotification or UDim2.new(0, padding, 1, -(notification.AbsoluteSize.Y + padding))
	notification.Size = UDim2.new(0, 0, 0, 60)
	utility:Tween(notification, {Size = UDim2.new(0, textSize.X + 70, 0, 60)}, 0.2)
	wait(0.2)
	notification.ClipsDescendants = false
	utility:Tween(notification.Flash, {Size = UDim2.new(0, 0, 0, 60), Position = UDim2.new(1, 0, 0, 0)}, 0.2)
	local active = true
	local close = function()
		if not active then return end
		active = false
		notification.ClipsDescendants = true
		library.lastNotification = notification.Position
		notification.Flash.Position = UDim2.new(0, 0, 0, 0)
		utility:Tween(notification.Flash, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
		wait(0.2)
		utility:Tween(notification, {Size = UDim2.new(0, 0, 0, 60), Position = notification.Position + UDim2.new(0, textSize.X + 70, 0, 0)}, 0.2)
		wait(0.2)
		notification:Destroy()
	end
	self.activeNotification = close
	notification.Accept.MouseButton1Click:Connect(function()
		if not active then return end
		if callback then callback(true) end
		close()
	end)
	notification.Decline.MouseButton1Click:Connect(function()
		if not active then return end
		if callback then callback(false) end
		close()
	end)
end

function section:addButton(title, callback)
	local button = utility:Create("TextButton", {
		Name = "Button",
		Parent = self.container,
		BackgroundColor3 = themes.Accent,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 2,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		Text = "",
		TextSize = 14
	}, {
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 10)
		}),
		utility:Create("UIStroke", {
			Color = Colors.Main.Separator,
			Thickness = 1,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = 3,
			Font = Enum.Font.GothamSemibold,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 13,
			TextTransparency = 0.2
		})
	})
	
	table.insert(self.modules, button)
	
	local text = button.Title
	local stroke = button:FindFirstChild("UIStroke")
	local debounce = false
	
	button.MouseEnter:Connect(function()
		Services.TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = themes.LightContrast
		}):Play()
		if stroke then
			Services.TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.2
			}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		Services.TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = themes.DarkContrast
		}):Play()
		if stroke then
			Services.TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.5
			}):Play()
		end
	end)
	
	button.MouseButton1Click:Connect(function()
		if debounce then return end
		debounce = true
		
		if callback then 
			callback(function(newTitle) 
				if newTitle and text then text.Text = newTitle end
			end) 
		end
		
		debounce = false
	end)
	
	return button
end

function section:addToggle(title, default, callback)
	local toggle = utility:Create("Frame", {
		Name = "Toggle",
		Parent = self.container,
		BackgroundColor3 = themes.DarkContrast,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 2
	},{
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 10)
		}),
		utility:Create("UIStroke", {
			Color = Colors.Main.Separator,
			Thickness = 1,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0.5, 0),
			Size = UDim2.new(0.65, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.GothamMedium,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 13,
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("TextButton", {
			Name = "ToggleButton",
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -70, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 50, 0, 24),
			ZIndex = 3,
			AutoButtonColor = false,
			Text = ""
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(1, 0)
			}),
			utility:Create("Frame", {
				Name = "Knob",
				BackgroundColor3 = Color3.fromRGB(220, 220, 220),
				Position = UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				BorderSizePixel = 0,
				ZIndex = 4
			}, {
				utility:Create("UICorner", {
					CornerRadius = UDim.new(1, 0)
				}),
				utility:Create("UIStroke", {
					Color = Color3.fromRGB(100, 100, 100),
					Thickness = 1,
					Transparency = 0.3
				})
			})
		})
	})
	
	table.insert(self.modules, toggle)
	
	local active = default or false
	local toggleButton = toggle.ToggleButton
	local knob = toggleButton.Knob
	local stroke = toggle:FindFirstChild("UIStroke")
	
	-- COULEUR BLANCHE AU LIEU DE VERTE
	local offColor = Color3.fromRGB(60, 60, 60)
	local onColor = Color3.fromRGB(255, 255, 255) -- BLANC
	
	toggle.MouseEnter:Connect(function()
		Services.TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = themes.LightContrast
		}):Play()
		if stroke then
			Services.TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.2
			}):Play()
		end
	end)
	
	toggle.MouseLeave:Connect(function()
		Services.TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = themes.DarkContrast
		}):Play()
		if stroke then
			Services.TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.5
			}):Play()
		end
	end)
	
	local function updateToggleAppearance(state, animate)
		local tweenInfo = TweenInfo.new(animate and 0.3 or 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		
		if state then
			Services.TweenService:Create(toggleButton, tweenInfo, {
				BackgroundColor3 = onColor
			}):Play()
			Services.TweenService:Create(knob, tweenInfo, {
				Position = UDim2.new(1, -21, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Knob foncé quand actif
			}):Play()
		else
			Services.TweenService:Create(toggleButton, tweenInfo, {
				BackgroundColor3 = offColor
			}):Play()
			Services.TweenService:Create(knob, tweenInfo, {
				Position = UDim2.new(0, 3, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(220, 220, 220)
			}):Play()
		end
	end
	
	updateToggleAppearance(active, false)
	
	toggleButton.MouseButton1Click:Connect(function()
		active = not active
		updateToggleAppearance(active, true)
		
		local currentSize = knob.Size
		Services.TweenService:Create(knob, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 20, 0, 20)
		}):Play()
		task.wait(0.1)
		Services.TweenService:Create(knob, TweenInfo.new(0.1), {
			Size = currentSize
		}):Play()
		
		if callback then 
			callback(active, function(newTitle, newValue) 
				if newTitle then toggle.Title.Text = newTitle end
				if newValue ~= nil then 
					active = newValue
					updateToggleAppearance(active, true)
				end
			end) 
		end
	end)
	
	return toggle
end

function section:addTextbox(title, default, callback)
	local textbox = utility:Create("Frame", {
		Name = "Textbox",
		Parent = self.container,
		BackgroundColor3 = themes.DarkContrast,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 2
	}, {
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 10)
		}),
		utility:Create("UIStroke", {
			Color = Colors.Main.Separator,
			Thickness = 1,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0.5, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.GothamMedium,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 13,
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("Frame", {
			Name = "InputFrame",
			BackgroundColor3 = themes.LightContrast,
			Position = UDim2.new(1, -110, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 100, 0, 24),
			BorderSizePixel = 0,
			ZIndex = 3
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 6)
			}),
			utility:Create("TextBox", {
				Name = "Textbox",
				BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				ZIndex = 4,
				Font = Enum.Font.GothamSemibold,
				Text = default or "",
				TextColor3 = Colors.White.Pure,
				TextSize = 11,
				ClearTextOnFocus = false
			})
		})
	})
	
	table.insert(self.modules, textbox)
	
	local input = textbox.InputFrame.Textbox
	local stroke = textbox:FindFirstChild("UIStroke")
	
	input:GetPropertyChangedSignal("Text"):Connect(function()
		if callback then callback(input.Text, nil, function(...) self:updateTextbox(textbox, ...) end) end
	end)
	
	input.FocusLost:Connect(function()
		if callback then callback(input.Text, true, function(...) self:updateTextbox(textbox, ...) end) end
	end)
	
	return textbox
end

function section:addKeybind(title, default, callback, changedCallback)
	local keybind = utility:Create("Frame", {
		Name = "Keybind",
		Parent = self.container,
		BackgroundColor3 = themes.DarkContrast,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 2
	}, {
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 10)
		}),
		utility:Create("UIStroke", {
			Color = Colors.Main.Separator,
			Thickness = 1,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0.5, 0),
			Size = UDim2.new(0.6, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.GothamMedium,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 13,
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("TextButton", {
			Name = "Button",
			BackgroundColor3 = themes.LightContrast,
			Position = UDim2.new(1, -110, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 100, 0, 24),
			BorderSizePixel = 0,
			ZIndex = 3,
			AutoButtonColor = false,
			Font = Enum.Font.GothamSemibold,
			Text = default and default.Name or "None",
			TextColor3 = Colors.White.Pure,
			TextSize = 11
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 6)
			})
		})
	})
	
	table.insert(self.modules, keybind)
	
	local button = keybind.Button
	
	self.binds[keybind] = {callback = function()
		if callback then callback(function(...) self:updateKeybind(keybind, ...) end) end
	end}
	
	if default and callback then self:updateKeybind(keybind, nil, default) end
	
	button.MouseButton1Click:Connect(function()
		if self.binds[keybind] and self.binds[keybind].connection then return self:updateKeybind(keybind) end
		if button.Text == "None" then
			button.Text = "..."
			local key = utility:KeyPressed()
			self:updateKeybind(keybind, nil, key.KeyCode)
			if changedCallback then changedCallback(key, function(...) self:updateKeybind(keybind, ...) end) end
		end
	end)
	
	return keybind
end

function section:addColorPicker(title, default, callback)
	local colorpicker = utility:Create("Frame", {
		Name = "ColorPicker",
		Parent = self.container,
		BackgroundColor3 = themes.DarkContrast,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 2
	}, {
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 10)
		}),
		utility:Create("UIStroke", {
			Color = Colors.Main.Separator,
			Thickness = 1,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0.5, 0),
			Size = UDim2.new(0.6, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.GothamMedium,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 13,
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("TextButton", {
			Name = "Button",
			BackgroundColor3 = default or Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(1, -50, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 40, 0, 24),
			BorderSizePixel = 0,
			ZIndex = 3,
			AutoButtonColor = false,
			Text = ""
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 6)
			}),
			utility:Create("UIStroke", {
				Color = Colors.Main.Separator,
				Thickness = 1,
				Transparency = 0
			})
		})
	})
	
	table.insert(self.modules, colorpicker)
	
	local tab = utility:Create("ImageLabel", {
		Name = "ColorPickerTab",
		Parent = self.page.library.container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.75, 0, 0.4, 0),
		Selectable = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 162, 0, 169),
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.Background,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 298, 298),
		Visible = false,
	}, {
		utility:Create("ImageLabel", {
			Name = "Glow",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -15, 0, -15),
			Size = UDim2.new(1, 30, 1, 30),
			ZIndex = 0,
			Image = "rbxassetid://5028857084",
			ImageColor3 = themes.Glow,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(22, 22, 278, 278)
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 8),
			Size = UDim2.new(1, -40, 0, 16),
			ZIndex = 2,
			Font = Enum.Font.GothamSemibold,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("ImageButton", {
			Name = "Close",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -26, 0, 8),
			Size = UDim2.new(0, 16, 0, 16),
			ZIndex = 2,
			Image = "rbxassetid://5012538583",
			ImageColor3 = Colors.White.Pure
		}),
		utility:Create("Frame", {
			Name = "Container",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 32),
			Size = UDim2.new(1, -18, 1, -40)
		}, {
			utility:Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6)
			}),
			utility:Create("ImageButton", {
				Name = "Canvas",
				BackgroundTransparency = 1,
				BorderColor3 = themes.LightContrast,
				Size = UDim2.new(1, 0, 0, 60),
				AutoButtonColor = false,
				Image = "rbxassetid://5108535320",
				ImageColor3 = Color3.fromRGB(255, 0, 0),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("ImageLabel", {Name = "White_Overlay", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Image = "rbxassetid://5107152351", SliceCenter = Rect.new(2, 2, 298, 298)}),
				utility:Create("ImageLabel", {Name = "Black_Overlay", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Image = "rbxassetid://5107152095", SliceCenter = Rect.new(2, 2, 298, 298)}),
				utility:Create("ImageLabel", {Name = "Cursor", BackgroundColor3 = Colors.White.Pure, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1.000, Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 0, 0, 0), Image = "rbxassetid://5100115962", SliceCenter = Rect.new(2, 2, 298, 298)})
			}),
			utility:Create("ImageButton", {
				Name = "Color",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, 4),
				Selectable = false,
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 2,
				AutoButtonColor = false,
				Image = "rbxassetid://5028857472",
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("Frame", {Name = "Select", BackgroundColor3 = Colors.White.Pure, BorderSizePixel = 1, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 2, 1, 0), ZIndex = 2}),
				utility:Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
						ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
						ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
						ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
						ColorSequenceKeypoint.new(0.82, Color3.fromRGB(255, 0, 255)),
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
					})
				})
			}),
			utility:Create("Frame", {
				Name = "Inputs",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 158),
				Size = UDim2.new(1, 0, 0, 16)
			}, {
				utility:Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6)
				}),
				utility:Create("ImageLabel", {
					Name = "R",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.305, 0, 1, 0),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.4, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "R:",
						TextColor3 = Colors.White.Pure,
						TextSize = 10
					}),
					utility:Create("TextBox", {
						Name = "Textbox",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.3, 0, 0, 0),
						Size = UDim2.new(0.6, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						PlaceholderColor3 = themes.DarkContrast,
						Text = "255",
						TextColor3 = Colors.White.Pure,
						TextSize = 10
					})
				}),
				utility:Create("ImageLabel", {
					Name = "G",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.305, 0, 1, 0),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						ZIndex = 2,
						Size = UDim2.new(0.4, 0, 1, 0),
						Font = Enum.Font.Gotham,
						Text = "G:",
						TextColor3 = Colors.White.Pure,
						TextSize = 10
					}),
					utility:Create("TextBox", {
						Name = "Textbox",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.3, 0, 0, 0),
						Size = UDim2.new(0.6, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "255",
						TextColor3 = Colors.White.Pure,
						TextSize = 10
					})
				}),
				utility:Create("ImageLabel", {
					Name = "B",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.305, 0, 1, 0),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.4, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "B:",
						TextColor3 = Colors.White.Pure,
						TextSize = 10
					}),
					utility:Create("TextBox", {
						Name = "Textbox",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.3, 0, 0, 0),
						Size = UDim2.new(0.6, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "255",
						TextColor3 = Colors.White.Pure,
						TextSize = 10
					})
				}),
			}),
			utility:Create("ImageButton", {
				Name = "Button",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 20),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.DarkContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 3,
					Font = Enum.Font.Gotham,
					Text = "Submit",
					TextColor3 = Colors.White.Pure,
					TextSize = 11
				})
			})
		})
	})
	
	utility.DraggingEnabled(utility, tab)
	
	local allowed = {[""] = true}
	local canvas = tab.Container.Canvas
	local color = tab.Container.Color
	local canvasSize, canvasPosition = canvas.AbsoluteSize, canvas.AbsolutePosition
	local colorSize, colorPosition = color.AbsoluteSize, color.AbsolutePosition
	local draggingColor, draggingCanvas
	local color3 = default or Color3.fromRGB(255, 255, 255)
	local hue, sat, brightness = 0, 0, 1
	local rgb = {r = 255, g = 255, b = 255}
	
	self.colorpickers[colorpicker] = {tab = tab, callback = function(prop, value) rgb[prop] = value hue, sat, brightness = Color3.toHSV(Color3.fromRGB(rgb.r, rgb.g, rgb.b)) end}
	local callbackFunc = function(value) if callback then callback(value, function(...) self:updateColorPicker(colorpicker, ...) end) end end
	utility:DraggingEnded(function() draggingColor, draggingCanvas = false, false end)
	
	if default then
		self:updateColorPicker(colorpicker, nil, default)
		hue, sat, brightness = Color3.toHSV(default)
		default = Color3.fromHSV(hue, sat, brightness)
		for i, prop in pairs({"r", "g", "b"}) do rgb[prop] = default[prop:upper()] * 255 end
	end
	
	for i, container in pairs(tab.Container.Inputs:GetChildren()) do
		if container:IsA("ImageLabel") then
			local textbox = container.Textbox
			local focused
			textbox.Focused:Connect(function() focused = true end)
			textbox.FocusLost:Connect(function()
				focused = false
				if not tonumber(textbox.Text) then textbox.Text = math.floor(rgb[container.Name:lower()]) end
			end)
			textbox:GetPropertyChangedSignal("Text"):Connect(function()
				local text = textbox.Text
				if not allowed[text] and not tonumber(text) then textbox.Text = text:sub(1, #text - 1)
				elseif focused and not allowed[text] then
					rgb[container.Name:lower()] = math.clamp(tonumber(textbox.Text), 0, 255)
					local color3 = Color3.fromRGB(rgb.r, rgb.g, rgb.b)
					hue, sat, brightness = Color3.toHSV(color3)
					self:updateColorPicker(colorpicker, nil, color3)
					callbackFunc(color3)
				end
			end)
		end
	end
	
	canvas.MouseButton1Down:Connect(function()
		draggingCanvas = true
		while draggingCanvas do
			local x, y = mouse.X, mouse.Y
			sat = math.clamp((x - canvasPosition.X) / canvasSize.X, 0, 1)
			brightness = 1 - math.clamp((y - canvasPosition.Y) / canvasSize.Y, 0, 1)
			color3 = Color3.fromHSV(hue, sat, brightness)
			for i, prop in pairs({"r", "g", "b"}) do rgb[prop] = color3[prop:upper()] * 255 end
			self:updateColorPicker(colorpicker, nil, {hue, sat, brightness})
			utility:Tween(canvas.Cursor, {Position = UDim2.new(sat, 0, 1 - brightness, 0)}, 0.1)
			callbackFunc(color3)
			utility:Wait()
		end
	end)
	
	color.MouseButton1Down:Connect(function()
		draggingColor = true
		while draggingColor do
			hue = 1 - math.clamp(1 - ((mouse.X - colorPosition.X) / colorSize.X), 0, 1)
			color3 = Color3.fromHSV(hue, sat, brightness)
			for i, prop in pairs({"r", "g", "b"}) do rgb[prop] = color3[prop:upper()] * 255 end
			local x = hue
			self:updateColorPicker(colorpicker, nil, {hue, sat, brightness})
			utility:Tween(tab.Container.Color.Select, {Position = UDim2.new(x, 0, 0, 0)}, 0.1)
			callbackFunc(color3)
			utility:Wait()
		end
	end)
	
	local button = colorpicker.Button
	local toggle, debounce, animate
	lastColor = Color3.fromHSV(hue, sat, brightness)
	animate = function(visible, overwrite)
		if overwrite then
			if not toggle then return end
			if debounce then while debounce do utility:Wait() end end
		end
		toggle = visible
		debounce = true
		if visible then
			if self.page.library.activePicker and self.page.library.activePicker ~= animate then self.page.library.activePicker(nil, true) end
			self.page.library.activePicker = animate
			lastColor = Color3.fromHSV(hue, sat, brightness)
			local x1, x2 = button.AbsoluteSize.X / 2, 162
			local px, py = button.AbsolutePosition.X, button.AbsolutePosition.Y
			tab.ClipsDescendants = true
			tab.Visible = true
			tab.Size = UDim2.new(0, 0, 0, 0)
			tab.Position = UDim2.new(0, x1 + x2 + px, 0, py)
			utility:Tween(tab, {Size = UDim2.new(0, 162, 0, 169)}, 0.2)
			wait(0.2)
			tab.ClipsDescendants = false
			canvasSize, canvasPosition = canvas.AbsoluteSize, canvas.AbsolutePosition
			colorSize, colorPosition = color.AbsoluteSize, color.AbsolutePosition
		else
			utility:Tween(tab, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
			tab.ClipsDescendants = true
			wait(0.2)
			tab.Visible = false
		end
		debounce = false
	end
	
	local toggleTab = function() animate(not toggle) end
	button.MouseButton1Click:Connect(toggleTab)
	tab.Container.Button.MouseButton1Click:Connect(function() animate() end)
	tab.Close.MouseButton1Click:Connect(function()
		self:updateColorPicker(colorpicker, nil, lastColor)
		animate()
	end)
	
	return colorpicker
end

function section:addSlider(title, default, min, max, callback)
	local slider = utility:Create("Frame", {
		Name = "Slider",
		Parent = self.container,
		BackgroundColor3 = themes.DarkContrast,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 2
	}, {
		utility:Create("UICorner", {
			CornerRadius = UDim.new(0, 10)
		}),
		utility:Create("UIStroke", {
			Color = Colors.Main.Separator,
			Thickness = 1,
			Transparency = 0,
			LineJoinMode = Enum.LineJoinMode.Round
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0, 8),
			Size = UDim2.new(0.6, 0, 0, 16),
			ZIndex = 3,
			Font = Enum.Font.GothamMedium,
			Text = title,
			TextColor3 = Colors.White.Pure,
			TextSize = 13,
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("TextBox", {
			Name = "TextBox",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -40, 0, 8),
			Size = UDim2.new(0, 30, 0, 16),
			ZIndex = 3,
			Font = Enum.Font.GothamSemibold,
			Text = default or min,
			TextColor3 = Colors.White.Pure,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right
		}),
		utility:Create("Frame", {
			Name = "SliderBar",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 15, 0, 30),
			Size = UDim2.new(1, -30, 0, 12),
			ZIndex = 3
		}, {
			utility:Create("Frame", {
				Name = "Bar",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = themes.LightContrast,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 4),
				BorderSizePixel = 0,
				ZIndex = 3
			}, {
				utility:Create("UICorner", {
					CornerRadius = UDim.new(1, 0)
				}),
				utility:Create("Frame", {
					Name = "Fill",
					BackgroundColor3 = Colors.White.Pure,
					Size = UDim2.new(0.5, 0, 1, 0),
					BorderSizePixel = 0,
					ZIndex = 3
				}, {
					utility:Create("UICorner", {
						CornerRadius = UDim.new(1, 0)
					}),
					utility:Create("Frame", {
						Name = "Circle",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Colors.White.Pure,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 0, 0, 0),
						BorderSizePixel = 0,
						ZIndex = 3
					}, {
						utility:Create("UICorner", {
							CornerRadius = UDim.new(1, 0)
						})
					})
				})
			})
		})
	})
	
	table.insert(self.modules, slider)
	
	local allowed = {[""] = true, ["-"] = true}
	local textbox = slider.TextBox
	local bar = slider.SliderBar.Bar
	local fill = bar.Fill
	local circle = fill.Circle
	local value = default or min
	local dragging, last
	local callbackFunc = function(value) if callback then callback(value, function(...) self:updateSlider(slider, ...) end) end end
	local stroke = slider:FindFirstChild("UIStroke")
	
	-- AJOUT DU HOVER EFFECT POUR LES SLIDERS
	slider.MouseEnter:Connect(function()
		Services.TweenService:Create(slider, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = themes.LightContrast
		}):Play()
		if stroke then
			Services.TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.2
			}):Play()
		end
	end)
	
	slider.MouseLeave:Connect(function()
		Services.TweenService:Create(slider, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = themes.DarkContrast
		}):Play()
		if stroke then
			Services.TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0.5
			}):Play()
		end
	end)
	
	self:updateSlider(slider, nil, value, min, max)
	utility:DraggingEnded(function() dragging = false end)
	
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			while dragging do
				utility:Tween(circle, {Size = UDim2.new(0, 10, 0, 10)}, 0.1)
				value = self:updateSlider(slider, nil, nil, min, max, value)
				callbackFunc(value)
				utility:Wait()
			end
			wait(0.3)
			utility:Tween(circle, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
		end
	end)
	
	textbox.FocusLost:Connect(function()
		if not tonumber(textbox.Text) then
			value = self:updateSlider(slider, nil, default or min, min, max)
			callbackFunc(value)
		end
	end)
	
	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = textbox.Text
		if not allowed[text] and not tonumber(text) then textbox.Text = text:sub(1, #text - 1)
		elseif not allowed[text] then
			value = self:updateSlider(slider, nil, tonumber(text) or value, min, max)
			callbackFunc(value)
		end
	end)
	
	return slider
end

function section:addDropdown(title, list, callback)
	local dropdown = utility:Create("Frame", {
		Name = "Dropdown",
		Parent = self.container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		ClipsDescendants = false
	}, {
		utility:Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4)
		}),
		utility:Create("Frame", {
			Name = "Search",
			BackgroundColor3 = themes.DarkContrast,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = 2
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 10)
			}),
			utility:Create("UIStroke", {
				Color = Colors.Main.Separator,
				Thickness = 1,
				Transparency = 0,
				LineJoinMode = Enum.LineJoinMode.Round
			}),
			utility:Create("TextBox", {
				Name = "TextBox",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 15, 0.5, 0),
				Size = UDim2.new(1, -50, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.GothamMedium,
				Text = title,
				TextColor3 = Colors.White.Pure,
				TextSize = 13,
				TextTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageButton", {
				Name = "Button",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -30, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				ZIndex = 3,
				Image = "rbxassetid://5012539403",
				ImageColor3 = Colors.White.Pure
			})
		}),
		utility:Create("Frame", {
			Name = "List",
			BackgroundColor3 = themes.Background,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, -42),
			ZIndex = 2
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 10)
			}),
			utility:Create("ScrollingFrame", {
				Name = "Frame",
				Active = true,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 4, 0, 4),
				Size = UDim2.new(1, -8, 1, -8),
				CanvasPosition = Vector2.new(0, 28),
				CanvasSize = UDim2.new(0, 0, 0, 120),
				ZIndex = 2,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = themes.DarkContrast
			}, {
				utility:Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4)
				})
			})
		})
	})
	
	table.insert(self.modules, dropdown)
	
	local search = dropdown.Search
	local focused
	list = list or {}
	
	search.Button.MouseButton1Click:Connect(function()
		if search.Button.Rotation == 0 then self:updateDropdown(dropdown, nil, list, callback)
		else self:updateDropdown(dropdown, nil, nil, callback) end
	end)
	
	search.TextBox.Focused:Connect(function()
		if search.Button.Rotation == 0 then self:updateDropdown(dropdown, nil, list, callback) end
		focused = true
	end)
	
	search.TextBox.FocusLost:Connect(function() focused = false end)
	
	search.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		if focused then
			local filteredList = utility:Sort(search.TextBox.Text, list)
			filteredList = #filteredList ~= 0 and filteredList
			self:updateDropdown(dropdown, nil, filteredList, callback)
		end
	end)
	
	dropdown:GetPropertyChangedSignal("Size"):Connect(function() self:Resize() end)
	
	return dropdown
end

function library:SelectPage(page, toggle)
	if toggle and self.focusedPage == page then return end
	local button = page.button
	local icon = button:FindFirstChild("Icon")

	if toggle then
		button.Title.TextTransparency = 0
		button.Title.Font = Enum.Font.GothamBold
		if icon then icon.ImageTransparency = 0 end
		utility:Tween(button.Indicator, {BackgroundTransparency = 0}, 0.2)

		local focusedPage = self.focusedPage
		self.focusedPage = page
		if focusedPage then self:SelectPage(focusedPage) end

		local existingSections = focusedPage and #focusedPage.sections or 0
		local sectionsRequired = #page.sections - existingSections
		page:Resize()

		for i, section in pairs(page.sections) do 
			if section and section.container and section.container.Parent then
				section.container.Parent.Visible = true 
			end
		end

		if sectionsRequired < 0 then
			for i = existingSections, #page.sections + 1, -1 do
				if focusedPage and focusedPage.sections[i] and focusedPage.sections[i].container and focusedPage.sections[i].container.Parent then
					local section = focusedPage.sections[i].container.Parent
					section.Visible = false
				end
			end
		end

		wait(0.1)
		page.container.Visible = true
		if focusedPage then focusedPage.container.Visible = false end

		if sectionsRequired > 0 then
			for i = existingSections + 1, #page.sections do
				if page.sections[i] and page.sections[i].container and page.sections[i].container.Parent then
					local section = page.sections[i].container.Parent
					section.Visible = true
				end
			end
		end

		wait(0.05)
		for i, section in pairs(page.sections) do
			if section then
				section:Resize(true)
			end
			wait(0.05)
		end

		wait(0.05)
		page:Resize(true)
	else
		button.Title.Font = Enum.Font.Gotham
		button.Title.TextTransparency = 0.5
		if icon then icon.ImageTransparency = 0.5 end
		utility:Tween(button.Indicator, {BackgroundTransparency = 1}, 0.2)

		for i, section in pairs(page.sections) do    
			if section and section.container and section.container.Parent then
				utility:Tween(section.container.Parent, {Size = UDim2.new(1, 0, 0, 10)}, 0.1)
			end
		end

		wait(0.1)
		page.lastPosition = page.container.CanvasPosition.Y
		page:Resize()
	end
end

function page:Resize(scroll)
	local padding = 10
	local size = 0
	for i, section in pairs(self.sections) do 
		if section and section.container and section.container.Parent then
			size = size + section.container.Parent.AbsoluteSize.Y + padding 
		end
	end
	self.container.CanvasSize = UDim2.new(0, 0, 0, size)
	self.container.ScrollBarImageTransparency = size > self.container.AbsoluteSize.Y and 0 or 1
	if scroll and self.container then 
		utility:Tween(self.container, {CanvasPosition = Vector2.new(0, self.lastPosition or 0)}, 0.2) 
	end
end

function section:Resize(smooth)
	if self.page.library.focusedPage ~= self.page then return end
	
	local padding = 10
	local size = 12
	
	for i, module in pairs(self.modules) do 
		if module and module.Parent then
			size = size + module.AbsoluteSize.Y + padding
		end
	end
	size = size + 2
	
	if smooth and self.container and self.container.Parent then
		utility:Tween(self.container.Parent, {Size = UDim2.new(1, 0, 0, size)}, 0.05)
	elseif self.container and self.container.Parent then 
		self.container.Parent.Size = UDim2.new(1, 0, 0, size) 
		self.page:Resize() 
	end
end

function section:getModule(info)
	if table.find(self.modules, info) then return info end
	for i, module in pairs(self.modules) do
		local title = module:FindFirstChild("Title") or module:FindFirstChild("TextBox", true)
		if title and title.Text == info then return module end
	end
	error("No module found under "..tostring(info))
end

function section:updateButton(button, title) 
	button = self:getModule(button) 
	if button and button.Title then
		button.Title.Text = title 
	end
end

function section:updateToggle(toggle, title, value)
	toggle = self:getModule(toggle)
	if title and toggle and toggle.Title then toggle.Title.Text = title end
	
	local toggleButton = toggle:FindFirstChild("ToggleButton")
	if not toggleButton then return end
	
	local knob = toggleButton:FindFirstChild("Knob")
	if not knob then return end
	
	local offColor = Color3.fromRGB(60, 60, 60)
	local onColor = Color3.fromRGB(255, 255, 255) -- BLANC
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	if value then
		Services.TweenService:Create(toggleButton, tweenInfo, {
			BackgroundColor3 = onColor
		}):Play()
		Services.TweenService:Create(knob, tweenInfo, {
			Position = UDim2.new(1, -21, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Knob foncé quand actif
		}):Play()
	else
		Services.TweenService:Create(toggleButton, tweenInfo, {
			BackgroundColor3 = offColor
		}):Play()
		Services.TweenService:Create(knob, tweenInfo, {
			Position = UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		}):Play()
	end
end

function section:updateTextbox(textbox, title, value)
	textbox = self:getModule(textbox)
	if title and textbox and textbox.Title then textbox.Title.Text = title end
	if value and textbox and textbox.InputFrame and textbox.InputFrame.Textbox then textbox.InputFrame.Textbox.Text = value end
end

function section:updateKeybind(keybind, title, key)
	keybind = self:getModule(keybind)
	local button = keybind.Button
	local bind = self.binds[keybind]
	if title and keybind and keybind.Title then keybind.Title.Text = title end
	if bind and bind.connection then bind.connection = bind.connection:UnBind() end
	if key then 
		self.binds[keybind].connection = utility:BindToKey(key, bind.callback) 
		if button then button.Text = key.Name end
	elseif button then 
		button.Text = "None" 
	end
end

function section:updateColorPicker(colorpicker, title, color)
	colorpicker = self:getModule(colorpicker)
	local picker = self.colorpickers[colorpicker]
	if not picker then return end
	local tab = picker.tab
	local callback = picker.callback
	if title and colorpicker and colorpicker.Title then 
		colorpicker.Title.Text = title 
		if tab and tab.Title then tab.Title.Text = title end
	end
	local color3
	local hue, sat, brightness
	if type(color) == "table" then 
		hue, sat, brightness = unpack(color) 
		color3 = Color3.fromHSV(hue, sat, brightness)
	else 
		color3 = color 
		hue, sat, brightness = Color3.toHSV(color3) 
	end
	utility:Tween(colorpicker.Button, {BackgroundColor3 = color3}, 0.5)
	if tab and tab.Container then
		utility:Tween(tab.Container.Color.Select, {Position = UDim2.new(hue, 0, 0, 0)}, 0.1)
		utility:Tween(tab.Container.Canvas, {ImageColor3 = Color3.fromHSV(hue, 1, 1)}, 0.5)
		utility:Tween(tab.Container.Canvas.Cursor, {Position = UDim2.new(sat, 0, 1 - brightness)}, 0.5)
		for i, container in pairs(tab.Container.Inputs:GetChildren()) do
			if container:IsA("ImageLabel") then
				local value = math.clamp(color3[container.Name], 0, 1) * 255
				container.Textbox.Text = math.floor(value)
			end
		end
	end
end

function section:updateSlider(slider, title, value, min, max, lvalue)
	slider = self:getModule(slider)
	if title and slider and slider.Title then slider.Title.Text = title end
	local bar = slider.SliderBar.Bar
	local percent = (mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
	if value then percent = (value - min) / (max - min) end
	percent = math.clamp(percent, 0, 1)
	value = value or math.floor(min + (max - min) * percent)
	if slider and slider.TextBox then
		slider.TextBox.Text = value
	end
	if bar and bar.Fill then
		utility:Tween(bar.Fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
	end
	return value
end

function section:updateDropdown(dropdown, title, list, callback)
	dropdown = self:getModule(dropdown)
	if title and dropdown and dropdown.Search and dropdown.Search.TextBox then 
		dropdown.Search.TextBox.Text = title 
	end
	local entries = 0
	
	for i, button in pairs(dropdown.List.Frame:GetChildren()) do 
		if button:IsA("Frame") or button:IsA("TextButton") then button:Destroy() end 
	end
	
	for i, value in pairs(list or {}) do
		local button = utility:Create("TextButton", {
			Parent = dropdown.List.Frame,
			BackgroundColor3 = themes.DarkContrast,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = value,
			TextColor3 = Colors.White.Pure,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left
		}, {
			utility:Create("UICorner", {
				CornerRadius = UDim.new(0, 6)
			}),
			utility:Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10)
			})
		})
		
		button.MouseButton1Click:Connect(function()
			if callback then callback(value, function(...) self:updateDropdown(dropdown, ...) end) end    
			self:updateDropdown(dropdown, value, nil, callback)
		end)
		entries = entries + 1
	end
	
	local frame = dropdown.List.Frame
	utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, (entries == 0 and 38) or math.clamp(entries, 0, 3) * 34 + 46)}, 0.3)
	if dropdown.Search and dropdown.Search.Button then
		utility:Tween(dropdown.Search.Button, {Rotation = list and 180 or 0}, 0.3)
	end
	
	if entries > 3 then
		for i, button in pairs(dropdown.List.Frame:GetChildren()) do 
			if button:IsA("TextButton") then button.Size = UDim2.new(1, -6, 0, 30) end 
		end
		frame.CanvasSize = UDim2.new(0, 0, 0, (entries * 34) - 4)
		frame.ScrollBarImageTransparency = 0
	else
		frame.CanvasSize = UDim2.new(0, 0, 0, 0)
		frame.ScrollBarImageTransparency = 1
	end
end


return {
	Services = Services,
	Colors = Colors,
	themes = themes,
	Icons = Icons,
	updateTimeDisplay = updateTimeDisplay,
	CreateButtonGlow = CreateButtonGlow,
	utility = utility,
	library = library
}
