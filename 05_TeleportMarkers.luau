return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Options = Library.Options
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local UserInputService = game:GetService("UserInputService")

	local Box = Tab:AddRightGroupbox("Teleport Markers")
	local Marker, MarkerCFrame

	local function SetMarker(Where)
		if Marker then Marker:Destroy() end
		MarkerCFrame = Where
		local Part = Instance.new("Part")
		Part.Name = "TeleportMarker"
		Part.Shape = Enum.PartType.Ball
		Part.Size = Vector3.new(1, 1, 1)
		Part.Color = Color3.fromRGB(0, 255, 0)
		Part.Material = Enum.Material.Neon
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.CastShadow = false
		Part.CFrame = Where * CFrame.new(0, 1.5, 0) -- head level
		local Gui = Instance.new("BillboardGui")
		Gui.Size = UDim2.fromOffset(14, 14)
		Gui.AlwaysOnTop = true
		Gui.Parent = Part
		local Dot = Instance.new("Frame")
		Dot.Size = UDim2.fromScale(1, 1)
		Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		Dot.BorderSizePixel = 0
		Dot.Parent = Gui
		Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
		Part.Parent = workspace
		Marker = Part
	end

	local function RemoveMarker()
		if Marker then Marker:Destroy() end
		Marker, MarkerCFrame = nil, nil
	end

	local function GetRoot()
		local Character = LocalPlayer.Character
		return Character, Character and Character:FindFirstChild("HumanoidRootPart")
	end

	local function CreateMarker()
		local _, Root = GetRoot()
		if not Root then
			Library:Notify({ Title = "Teleport Markers", Description = "Make sure your character is loaded." })
			return
		end
		SetMarker(Root.CFrame)
	end

	local function TeleportToMarker()
		local Character, Root = GetRoot()
		if not Root then
			Library:Notify({ Title = "Teleport Markers", Description = "Make sure your character is loaded." })
			return
		end
		if not MarkerCFrame then
			Library:Notify({ Title = "Teleport Markers", Description = "Create a marker first." })
			return
		end
		Character:PivotTo(MarkerCFrame)
		Root.AssemblyLinearVelocity = Vector3.zero
		if getgenv().AbbysalAntiVoidReset then getgenv().AbbysalAntiVoidReset(MarkerCFrame) end
	end

	Box:AddButton({ Text = "Create Marker", Tooltip = "Places a green marker where you stand.", Func = CreateMarker })
	Box:AddButton({ Text = "Teleport to Marker", Tooltip = "Teleports you to the marker. The marker stays where it is.", Func = TeleportToMarker })
	Box:AddButton({ Text = "Remove Marker", Func = RemoveMarker })
	Box:AddLabel("Create Marker key"):AddKeyPicker("AP_CreateMarkerKey", { Default = "J", Mode = "Press", NoUI = true, Text = "Create Marker" })
	Box:AddLabel("Teleport key"):AddKeyPicker("AP_TeleportMarkerKey", { Default = "K", Mode = "Press", NoUI = true, Text = "Teleport to Marker" })

	-- fires once per real key press (not while typing in chat or rebinding the key)
	local InputConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
		if Processed or Input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if Options.AP_CreateMarkerKey.Picking or Options.AP_TeleportMarkerKey.Picking then return end
		local KeyName = Input.KeyCode.Name
		if KeyName == Options.AP_CreateMarkerKey.Value then
			CreateMarker()
		elseif KeyName == Options.AP_TeleportMarkerKey.Value then
			TeleportToMarker()
		end
	end)

	Library:OnUnload(function()
		InputConnection:Disconnect()
		RemoveMarker()
	end)
end
