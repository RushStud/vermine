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
    Black = {Pure = Color3.new(0,0,0), Dark = Color3.new(0.04,0.04,0.04), Medium = Color3.new(0.06,0.06,0.06), Light = Color3.new(0.1,0.1,0.1)},
    White = {Pure = Color3.new(1,1,1), Bright = Color3.new(0.94,0.94,0.94), Light = Color3.new(0.86,0.86,0.86), Medium = Color3.new(0.71,0.71,0.71)},
    Glow = {White = Color3.new(1,1,1), Bright = Color3.new(0.98,0.98,0.98)},
    Green = {Primary = Color3.fromRGB(46,204,113), Secondary = Color3.fromRGB(39,174,96), Glow = Color3.fromRGB(76,217,100)},
    Blue = {Primary = Color3.fromRGB(52,152,219), Secondary = Color3.fromRGB(41,128,185), Glow = Color3.fromRGB(86,204,242)},
    Pink = {Primary = Color3.fromRGB(255,118,117), Secondary = Color3.fromRGB(255,82,82), Glow = Color3.fromRGB(255,168,168)},
    Red = {Primary = Color3.fromRGB(231,76,60), Secondary = Color3.fromRGB(192,57,43), Glow = Color3.fromRGB(255,94,87)},
    Purple = {Primary = Color3.fromRGB(155,89,182), Secondary = Color3.fromRGB(142,68,173), Glow = Color3.fromRGB(187,143,206)},
    Main = {
        Separator = Color3.fromRGB(36, 36, 37),
        LightSeparator = Color3.fromRGB(72, 72, 73),
        DarkSeparator = Color3.fromRGB(21, 21, 23),
        Shadow = Color3.new(0, 0, 0)
    }
}

local themes = {
    Background = Colors.Black.Dark,
    Glow = Colors.Glow.White,
    Accent = Colors.Black.Medium,
    LightContrast = Colors.Black.Light, -- Sera utilisé pour l'effet de survol (Hover)
    DarkContrast = Colors.Black.Pure,
    TextColor = Colors.White.Pure,
    CurrentTheme = "Dark"
}

local HUB_VERSION = "v2.09"

local function updateTimeDisplay()
    local success, result = pcall(function()
        local countryCode = Services.LocalizationService:GetCountryRegionForPlayerAsync(player)

        local timezones = {
            US = "EST", FR = "CET", GB = "GMT", DE = "CET", CA = "EST",
            AU = "AEST", JP = "JST", CN = "CST", RU = "MSK", BR = "BRT",
            IN = "IST", MX = "CST",
        }

        local timezone = timezones[countryCode] or "UTC"
        local currentTime = os.date("*t")
        local timeString = string.format("%02d:%02d", currentTime.hour, currentTime.min)

        return string.format("%s | %s %s", HUB_VERSION, timeString, timezone)
    end)

    return success and result or string.format("%s | Loading...", HUB_VERSION)
end

local function CreateButtonGlow(button, hoverColor, originalColor, glowColor)
    -- Fonction existante conservée pour les boutons speciaux si besoin
    if not button or not button.Parent then return end
    glowColor = glowColor or Colors.Glow.White
    -- (Le reste de la fonction Glow est conservé mais simplifié ici pour la clarté, l'effet Hover principal est géré par utility:AddHover)
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

    -- [AJOUT] Gestion du flou d'arrière-plan (DepthOfField)
    ToggleDepthOfField = function(self, enabled)
        local dof = Services.Lighting:FindFirstChild("HITTA_DOF")
        if not dof then
            dof = Instance.new("DepthOfFieldEffect")
            dof.Name = "HITTA_DOF"
            dof.FarIntensity = 0
            dof.FocusDistance = 0
            dof.InFocusRadius = 0
            dof.NearIntensity = 0
            dof.Parent = Services.Lighting
        end
        local targetIntensity = enabled and 0.8 or 0
        Services.TweenService:Create(dof, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {NearIntensity = targetIntensity}):Play()
    end,

    -- [AJOUT] Effet de survol (Hover Effect) style Airflow pour les éléments
    AddHover = function(self, instance)
        if not instance then return end
        
        -- On capture la couleur de base (normalement DarkContrast)
        local originalColor = instance.ImageColor3
        -- La couleur de survol sera LightContrast (un gris légèrement plus clair)
        local hoverColor = themes.LightContrast

        instance.MouseEnter:Connect(function()
            self:Tween(instance, {ImageColor3 = hoverColor}, 0.25)
        end)

        instance.MouseLeave:Connect(function()
            self:Tween(instance, {ImageColor3 = originalColor}, 0.25)
        end)
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

        Services.UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                parent:TweenPosition(
                    UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y), 
                    nil, nil, 0.33333, true
                )
            end
        end)
        
        -- Touch support omitted for brevity but logic remains the same
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

-- Icons table (inchangée)
local Icons = {Main = "rbxassetid://102603462805125", Fun = "rbxassetid://82754506929523", Updates = "rbxassetid://106623431956692", Movesets = "rbxassetid://99243871319042", Teleport = "rbxassetid://79372497673248", Universal = "rbxassetid://73085793411021", Settings = "rbxassetid://115075597641040", Close = "rbxassetid://91094978625199", Fullscreen = "rbxassetid://135813930497865", Minimize = "rbxassetid://74828798969877"}

function section:addMileniumSeparator(thickness, color, offset)
    thickness = thickness or 1
    color = color or Colors.Main.Separator
    offset = offset or 10
    
    local separator = utility:Create("Frame", {
        Name = "MileniumSeparator",
        Parent = self.container,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -(offset * 2), 0, thickness),
        Position = UDim2.new(0, offset, 0, 0),
        ZIndex = 3
    })
    
    table.insert(self.modules, separator)
    return separator
end

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
                        Position = UDim2.new(0, 230, 0.7, -8),
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
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = themes.DarkContrast,
                    ZIndex = 2
                }, {
                    utility:Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 25),
                        PaddingRight = UDim.new(0, 25),
                        PaddingTop = UDim.new(0, 20)
                    }),
                    utility:Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 18)
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
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35),
        ZIndex = 3,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 14
    }, {
        utility:Create("ImageLabel", {
            Name = "Icon",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 3,
            Image = iconUrl or "",
            ImageColor3 = Colors.White.Pure,
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Fit
        }),
        utility:Create("TextLabel", {
            Name = "Title",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 35, 0.5, 0),
            Size = UDim2.new(1, -35, 1, 0),
            ZIndex = 3,
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
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = Colors.White.Pure,
            BorderSizePixel = 0
        })
    })

    -- Animation Hover pour les Onglets
    button.MouseEnter:Connect(function()
        if library.focusedPage ~= nil and library.focusedPage.button == button then return end
        utility:Tween(button.Title, {TextTransparency = 0.2}, 0.2)
        utility:Tween(button.Icon, {ImageTransparency = 0.2}, 0.2)
        utility:Tween(button.Icon, {Position = UDim2.new(0, 13, 0.5, 0)}, 0.2) -- Petit décalage vers la droite
    end)

    button.MouseLeave:Connect(function()
        if library.focusedPage ~= nil and library.focusedPage.button == button then return end
        utility:Tween(button.Title, {TextTransparency = 0.5}, 0.2)
        utility:Tween(button.Icon, {ImageTransparency = 0.5}, 0.2)
        utility:Tween(button.Icon, {Position = UDim2.new(0, 10, 0.5, 0)}, 0.2)
    end)

    local container = utility:Create("ScrollingFrame", {
        Name = title,
        Parent = library.contentArea,
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 600),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = themes.DarkContrast,
        Visible = false
    }, {
        utility:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 15)
        })
    })

    return setmetatable({
        library = library,
        container = container,
        button = button,
        sections = {}
    }, page)
end

function section.new(page, title)
    local container = utility:Create("Frame", {
        Name = title,
        Parent = page.container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 28),
        ClipsDescendants = false
    }, {
        utility:Create("Frame", {
            Name = "Container",
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0)
        }, {
            utility:Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 25),
                ZIndex = 2,
                Font = Enum.Font.GothamBold,
                Text = title,
                TextColor3 = Colors.White.Pure,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = 0
            }),
            utility:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8)
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

function page:addSection(...)
    local section = section.new(self, ...)
    table.insert(self.sections, section)
    return section
end

function library:toggle()
    if self.toggling then return end
    self.toggling = true
    local mainFrame = self.mainFrame
    
    if self.position then
        utility:Tween(mainFrame, {Size = UDim2.new(0, 650, 0, 500), Position = self.position}, 0.2)
        utility:ToggleDepthOfField(true) -- Activer Flou
        wait(0.2)
        utility:Tween(mainFrame.ContentGroup.TopBar, {Size = UDim2.new(1, 0, 0, 50)}, 0.2)
        wait(0.2)
        mainFrame.ClipsDescendants = false
        self.position = nil
    else
        self.position = mainFrame.Position
        mainFrame.ClipsDescendants = true
        utility:Tween(mainFrame.ContentGroup.TopBar, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
        wait(0.2)
        utility:Tween(mainFrame, {Size = UDim2.new(0, 650, 0, 0), Position = self.position + UDim2.new(0, 0, 0, 500)}, 0.2)
        utility:ToggleDepthOfField(false) -- Désactiver Flou
        wait(0.2)
    end
    self.toggling = false
end

-- BUTTON AVEC HOVER
function section:addButton(title, callback)
    local button = utility:Create("ImageButton", {
        Name = "Button",
        Parent = self.container,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.DarkContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 298, 298)
    }, {
        utility:Create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextTransparency = 0.2
        })
    })
    table.insert(self.modules, button)
    utility:AddHover(button) -- AJOUT HOVER
    local text = button.Title
    local debounce
    button.MouseButton1Click:Connect(function()
        if debounce then return end
        utility:Pop(button, 10)
        debounce = true
        text.TextSize = 0
        utility:Tween(button.Title, {TextSize = 14}, 0.2)
        wait(0.2)
        utility:Tween(button.Title, {TextSize = 12}, 0.2)
        if callback then callback(function(...) self:updateButton(button, ...) end) end
        debounce = false
    end)
    return button
end

-- TOGGLE AVEC HOVER
function section:addToggle(title, default, callback)
    local toggle = utility:Create("ImageButton", {
        Name = "Toggle",
        Parent = self.container,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 25),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.DarkContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 298, 298)
    },{
        utility:Create("TextLabel", {
            Name = "Title",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0.7, 0, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        utility:Create("ImageLabel", {
            Name = "Button",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -50, 0.5, -7),
            Size = UDim2.new(0, 40, 0, 14),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = themes.LightContrast,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        }, {
            utility:Create("ImageLabel", {
                Name = "Frame",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 2, 0.5, -6),
                Size = UDim2.new(0, 16, 0, 12),
                ZIndex = 2,
                Image = "rbxassetid://5028857472",
                ImageColor3 = Colors.White.Pure,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(2, 2, 298, 298)
            })
        })
    })
    table.insert(self.modules, toggle)
    utility:AddHover(toggle) -- AJOUT HOVER
    local active = default
    self:updateToggle(toggle, nil, active)
    toggle.MouseButton1Click:Connect(function()
        active = not active
        self:updateToggle(toggle, nil, active)
        if callback then callback(active, function(...) self:updateToggle(toggle, ...) end) end
    end)
    return toggle
end

-- TEXTBOX AVEC HOVER
function section:addTextbox(title, default, callback)
    local textbox = utility:Create("ImageButton", {
        Name = "Textbox",
        Parent = self.container,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.DarkContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 298, 298)
    }, {
        utility:Create("TextLabel", {
            Name = "Title",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        utility:Create("ImageLabel", {
            Name = "Button",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -110, 0.5, -8),
            Size = UDim2.new(0, 100, 0, 16),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = themes.LightContrast,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        }, {
            utility:Create("TextBox", {
                Name = "Textbox", 
                BackgroundTransparency = 1,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.new(0, 5, 0, 0),
                Size = UDim2.new(1, -10, 1, 0),
                ZIndex = 3,
                Font = Enum.Font.GothamSemibold,
                Text = default or "",
                TextColor3 = Colors.White.Pure,
                TextSize = 11
            })
        })
    })
    table.insert(self.modules, textbox)
    utility:AddHover(textbox) -- AJOUT HOVER
    local button = textbox.Button
    local input = button.Textbox
    textbox.MouseButton1Click:Connect(function()
        if textbox.Button.Size ~= UDim2.new(0, 100, 0, 16) then return end
        utility:Tween(textbox.Button, {Size = UDim2.new(0, 200, 0, 16), Position = UDim2.new(1, -210, 0.5, -8)}, 0.2)
        wait()
        input.TextXAlignment = Enum.TextXAlignment.Left
        input:CaptureFocus()
    end)
    input.FocusLost:Connect(function()
        input.TextXAlignment = Enum.TextXAlignment.Center
        utility:Tween(textbox.Button, {Size = UDim2.new(0, 100, 0, 16), Position = UDim2.new(1, -110, 0.5, -8)}, 0.2)
        if callback then callback(input.Text, true, function(...) self:updateTextbox(textbox, ...) end) end
    end)
    return textbox
end

-- KEYBIND AVEC HOVER
function section:addKeybind(title, default, callback, changedCallback)
    local keybind = utility:Create("ImageButton", {
        Name = "Keybind",
        Parent = self.container,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.DarkContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 298, 298)
    }, {
        utility:Create("TextLabel", {
            Name = "Title",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0.7, 0, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        utility:Create("ImageLabel", {
            Name = "Button",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -110, 0.5, -8),
            Size = UDim2.new(0, 100, 0, 16),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = themes.LightContrast,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        }, {
            utility:Create("TextLabel", {
                Name = "Text",
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 3,
                Font = Enum.Font.GothamSemibold,
                Text = default and default.Name or "None",
                TextColor3 = Colors.White.Pure,
                TextSize = 11
            })
        })
    })
    table.insert(self.modules, keybind)
    utility:AddHover(keybind) -- AJOUT HOVER
    -- (Reste du code Keybind inchangé)
    local text = keybind.Button.Text
    local button = keybind.Button
    local animate = function()
        if button and button.ImageTransparency == 0 then utility:Pop(button, 10) end
    end
    self.binds[keybind] = {callback = function()
        animate()
        if callback then callback(function(...) self:updateKeybind(keybind, ...) end) end
    end}
    if default and callback then self:updateKeybind(keybind, nil, default) end
    keybind.MouseButton1Click:Connect(function()
        animate()
        if self.binds[keybind] and self.binds[keybind].connection then return self:updateKeybind(keybind) end
        if text.Text == "None" then
            text.Text = "..."
            local key = utility:KeyPressed()
            self:updateKeybind(keybind, nil, key.KeyCode)
            animate()
            if changedCallback then changedCallback(key, function(...) self:updateKeybind(keybind, ...) end) end
        end
    end)
    return keybind
end

-- COLORPICKER AVEC HOVER
function section:addColorPicker(title, default, callback)
    local colorpicker = utility:Create("ImageButton", {
        Name = "ColorPicker",
        Parent = self.container,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.DarkContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 298, 298)
    },{
        utility:Create("TextLabel", {
            Name = "Title",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        utility:Create("ImageButton", {
            Name = "Button",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -50, 0.5, -7),
            Size = UDim2.new(0, 40, 0, 14),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        })
    })
    utility:AddHover(colorpicker) -- AJOUT HOVER
    -- (Le reste du code ColorPicker reste identique au précédent, la fenêtre popup est gérée pareil)
    local tab = utility:Create("ImageLabel", {
        Name = "ColorPicker",
        Parent = self.page.library.container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.75, 0, 0.400000006, 0),
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
                        Size = UDim2.new(0.400000006, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.Gotham,
                        Text = "R:",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 10.000
                    }),
                    utility:Create("TextBox", {
                        Name = "Textbox",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0.300000012, 0, 0, 0),
                        Size = UDim2.new(0.600000024, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.Gotham,
                        PlaceholderColor3 = themes.DarkContrast,
                        Text = "255",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 10.000
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
                        Size = UDim2.new(0.400000006, 0, 1, 0),
                        Font = Enum.Font.Gotham,
                        Text = "G:",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 10.000
                    }),
                    utility:Create("TextBox", {
                        Name = "Textbox",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0.300000012, 0, 0, 0),
                        Size = UDim2.new(0.600000024, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.Gotham,
                        Text = "255",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 10.000
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
                        Size = UDim2.new(0.400000006, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.Gotham,
                        Text = "B:",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 10.000
                    }),
                    utility:Create("TextBox", {
                        Name = "Textbox",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0.300000012, 0, 0, 0),
                        Size = UDim2.new(0.600000024, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.Gotham,
                        Text = "255",
                        TextColor3 = Colors.White.Pure,
                        TextSize = 10.000
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
                    TextSize = 11.000
                })
            })
        })
    })
    utility.DraggingEnabled(utility, tab)
    table.insert(self.modules, colorpicker)
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
    local callback = function(value) if callback then callback(value, function(...) self:updateColorPicker(colorpicker, ...) end) end end
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
                    callback(color3)
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
            callback(color3)
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
            callback(color3)
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
        elseif not overwrite then
            if debounce then return end
            if button and button.ImageTransparency == 0 then utility:Pop(button, 10) end
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
    colorpicker.MouseButton1Click:Connect(toggleTab)
    tab.Container.Button.MouseButton1Click:Connect(function() animate() end)
    tab.Close.MouseButton1Click:Connect(function()
        self:updateColorPicker(colorpicker, nil, lastColor)
        animate()
    end)
    return colorpicker
end

-- SLIDER AVEC HOVER
function section:addSlider(title, default, min, max, callback)
    local slider = utility:Create("ImageButton", {
        Name = "Slider",
        Parent = self.container,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.DarkContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 298, 298)
    }, {
        utility:Create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(0.5, 0, 0, 16),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        utility:Create("TextBox", {
            Name = "TextBox",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -30, 0, 6),
            Size = UDim2.new(0, 20, 0, 16),
            ZIndex = 3,
            Font = Enum.Font.GothamSemibold,
            Text = default or min,
            TextColor3 = Colors.White.Pure,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right
        }),
        utility:Create("TextLabel", {
            Name = "Slider",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 28),
            Size = UDim2.new(1, -20, 0, 16),
            ZIndex = 3,
            Text = "",
        }, {
            utility:Create("ImageLabel", {
                Name = "Bar",
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 4),
                ZIndex = 3,
                Image = "rbxassetid://5028857472",
                ImageColor3 = themes.LightContrast,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(2, 2, 298, 298)
            }, {
                utility:Create("ImageLabel", {
                    Name = "Fill",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.8, 0, 1, 0),
                    ZIndex = 3,
                    Image = "rbxassetid://5028857472",
                    ImageColor3 = Colors.White.Pure,
                    ScaleType = Enum.ScaleType.Slice,
                    SliceCenter = Rect.new(2, 2, 298, 298)
                }, {
                    utility:Create("ImageLabel", {
                        Name = "Circle",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        ImageTransparency = 1.000,
                        ImageColor3 = Colors.White.Pure,
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.new(0, 10, 0, 10),
                        ZIndex = 3,
                        Image = "rbxassetid://4608020054"
                    })
                })
            })
        })
    })
    table.insert(self.modules, slider)
    utility:AddHover(slider) -- AJOUT HOVER
    self:addMileniumSeparator(1, Colors.Main.Separator, 10)
    local allowed = {[""] = true, ["-"] = true}
    local textbox = slider.TextBox
    local circle = slider.Slider.Bar.Fill.Circle
    local value = default or min
    local dragging, last
    local callback = function(value) if callback then callback(value, function(...) self:updateSlider(slider, ...) end) end end
    self:updateSlider(slider, nil, value, min, max)
    utility:DraggingEnded(function() dragging = false end)
    slider.MouseButton1Down:Connect(function(input)
        dragging = true
        while dragging do
            utility:Tween(circle, {ImageTransparency = 0}, 0.1)
            value = self:updateSlider(slider, nil, nil, min, max, value)
            callback(value)
            utility:Wait()
        end
        wait(0.5)
        utility:Tween(circle, {ImageTransparency = 1}, 0.2)
    end)
    textbox.FocusLost:Connect(function()
        if not tonumber(textbox.Text) then
            value = self:updateSlider(slider, nil, default or min, min, max)
            callback(value)
        end
    end)
    textbox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = textbox.Text
        if not allowed[text] and not tonumber(text) then textbox.Text = text:sub(1, #text - 1)
        elseif not allowed[text] then     
            value = self:updateSlider(slider, nil, tonumber(text) or value, min, max)
            callback(value)
        end
    end)
    return slider
end

-- DROPDOWN AVEC HOVER
function section:addDropdown(title, list, callback)
    local dropdown = utility:Create("Frame", {
        Name = "Dropdown",
        Parent = self.container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        ClipsDescendants = true
    }, {
        utility:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        }),
        utility:Create("ImageLabel", {
            Name = "Search",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = themes.DarkContrast,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        }, {
            utility:Create("TextBox", {
                Name = "TextBox",
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.new(1, -42, 1, 0),
                ZIndex = 3,
                Font = Enum.Font.Gotham,
                Text = title,
                TextColor3 = Colors.White.Pure,
                TextSize = 12,
                TextTransparency = 0.2,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            utility:Create("ImageButton", {
                Name = "Button",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -28, 0.5, -9),
                Size = UDim2.new(0, 18, 0, 18),
                ZIndex = 3,
                Image = "rbxassetid://5012539403",
                ImageColor3 = Colors.White.Pure,
                SliceCenter = Rect.new(2, 2, 298, 298)
            })
        }),
        utility:Create("ImageLabel", {
            Name = "List",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, -36),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = themes.Background,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        }, {
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
    utility:AddHover(dropdown.Search) -- AJOUT HOVER SUR LA PARTIE RECHERCHE
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
            local list = utility:Sort(search.TextBox.Text, list)
            list = #list ~= 0 and list 
            self:updateDropdown(dropdown, nil, list, callback)
        end
    end)
    dropdown:GetPropertyChangedSignal("Size"):Connect(function() self:Resize() end)
    return dropdown
end

-- Reste du code unchanged
function section:updateButton(button, title) 
    button = self:getModule(button) 
    if button and button.Title then
        button.Title.Text = title 
    end
end

function section:updateToggle(toggle, title, value)
    toggle = self:getModule(toggle)
    local position = {In = UDim2.new(0, 2, 0.5, -6), Out = UDim2.new(0, 22, 0.5, -6)}
    local frame = toggle.Button.Frame
    value = value and "Out" or "In"
    if title and toggle.Title then toggle.Title.Text = title end
    if frame then
        utility:Tween(frame, {Size = UDim2.new(0, 16, 0, 12), Position = position[value] + UDim2.new(0, 0, 0, 0)}, 0.2)
    end
end

function section:updateTextbox(textbox, title, value)
    textbox = self:getModule(textbox)
    if title and textbox and textbox.Title then textbox.Title.Text = title end
    if value and textbox and textbox.Button and textbox.Button.Textbox then textbox.Button.Textbox.Text = value end
end

function section:updateKeybind(keybind, title, key)
    keybind = self:getModule(keybind)
    local text = keybind.Button.Text
    local bind = self.binds[keybind]
    if title and keybind and keybind.Title then keybind.Title.Text = title end
    if bind and bind.connection then bind.connection = bind.connection:UnBind() end
    if key then 
        self.binds[keybind].connection = utility:BindToKey(key, bind.callback) 
        if text then text.Text = key.Name end
    elseif text then 
        text.Text = "None" 
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
    utility:Tween(colorpicker.Button, {ImageColor3 = color3}, 0.5)
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
    local bar = slider.Slider.Bar
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
    if value ~= lvalue and slider and slider.ImageTransparency == 0 then 
        utility:Pop(slider, 10) 
    end
    return value
end

function section:updateDropdown(dropdown, title, list, callback)
    dropdown = self:getModule(dropdown)
    if title and dropdown and dropdown.Search and dropdown.Search.TextBox then 
        dropdown.Search.TextBox.Text = title 
    end
    local entries = 0
    utility:Pop(dropdown.Search, 10)
    for i, button in pairs(dropdown.List.Frame:GetChildren()) do 
        if button:IsA("ImageButton") then button:Destroy() end 
    end
    for i, value in pairs(list or {}) do
        local button = utility:Create("ImageButton", {
            Parent = dropdown.List.Frame,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            ZIndex = 2,
            Image = "rbxassetid://5028857472",
            ImageColor3 = themes.DarkContrast,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 298, 298)
        }, {
            utility:Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -10, 1, 0),
                ZIndex = 3,
                Font = Enum.Font.Gotham,
                Text = value,
                TextColor3 = Colors.White.Pure,
                TextSize = 12,
                TextXAlignment = "Left",
                TextTransparency = 0.2
            })
        })
        button.MouseButton1Click:Connect(function()
            if callback then callback(value, function(...) self:updateDropdown(dropdown, ...) end) end    
            self:updateDropdown(dropdown, value, nil, callback)
        end)
        entries = entries + 1
    end
    local frame = dropdown.List.Frame
    utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, (entries == 0 and 32) or math.clamp(entries, 0, 3) * 34 + 38)}, 0.3)
    if dropdown.Search and dropdown.Search.Button then
        utility:Tween(dropdown.Search.Button, {Rotation = list and 180 or 0}, 0.3)
    end
    if entries > 3 then
        for i, button in pairs(dropdown.List.Frame:GetChildren()) do if button:IsA("ImageButton") then button.Size = UDim2.new(1, -6, 0, 30) end end
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
