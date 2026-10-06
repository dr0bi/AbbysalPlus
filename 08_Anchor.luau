return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Toggles = Library.Toggles
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local PathfindingService = game:GetService("PathfindingService")

	local Box = Tab:AddLeftGroupbox("AnchorBase Guide")
	Box:AddToggle("AP_AnchorGuide", {
		Text = "Show Path to AnchorBase", Default = false,
		Tooltip = "Draws a path to the nearest AnchorBase. It only shows the way, you walk yourself."
	})
	local Info = Box:AddLabel("AnchorBase: -")

	local Folder = Instance.new("Folder")
	Folder.Name = "AbbysalAnchorGuide"
	Folder.Parent = workspace

	local Target
	local LastScan = 0
	local Busy = false

	local function PositionOf(Object)
		if Object:IsA("Model") then
			return Object:GetPivot().Position
		elseif Object:IsA("BasePart") then
			return Object.Position
		end
	end

	local function FindNearest(From)
		local Best, BestDistance
		for _, Object in workspace:GetDescendants() do
			if Object.Name == "AnchorBase" and (Object:IsA("Model") or Object:IsA("BasePart")) then
				local Position = PositionOf(Object)
				if Position then
					local Distance = (Position - From).Magnitude
					if not BestDistance or Distance < BestDistance then
						Best, BestDistance = Object, Distance
					end
				end
			end
		end
		return Best
	end

	local function DrawLine(A, B, Color)
		local Length = (B - A).Magnitude
		if Length < 0.05 then return end
		local Part = Instance.new("Part")
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.CastShadow = false
		Part.Material = Enum.Material.Neon
		Part.Color = Color
		Part.Transparency = 0.2
		Part.Size = Vector3.new(0.2, 0.2, Length)
		Part.CFrame = CFrame.lookAt((A + B) / 2, B)
		Part.Parent = Folder
	end

	local function DrawTarget(Position)
		local Part = Instance.new("Part")
		Part.Shape = Enum.PartType.Ball
		Part.Size = Vector3.new(1.2, 1.2, 1.2)
		Part.Material = Enum.Material.Neon
		Part.Color = Color3.fromRGB(0, 255, 120)
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.CastShadow = false
		Part.Position = Position + Vector3.new(0, 1.5, 0)
		local Gui = Instance.new("BillboardGui")
		Gui.Size = UDim2.fromOffset(110, 24)
		Gui.StudsOffset = Vector3.new(0, 2, 0)
		Gui.AlwaysOnTop = true
		Gui.Parent = Part
		local Text = Instance.new("TextLabel")
		Text.Size = UDim2.fromScale(1, 1)
		Text.BackgroundTransparency = 1
		Text.Text = "AnchorBase"
		Text.TextColor3 = Color3.fromRGB(0, 255, 120)
		Text.TextStrokeTransparency = 0.5
		Text.TextScaled = true
		Text.Parent = Gui
		Part.Parent = Folder
	end

	local function Update()
		local Character = LocalPlayer.Character
		local Root = Character and Character:FindFirstChild("HumanoidRootPart")
		if not Root then return end

		if not Target or not Target.Parent or os.clock() - LastScan > 3 then
			Target = FindNearest(Root.Position)
			LastScan = os.clock()
		end
		if not Target then
			Folder:ClearAllChildren()
			Info:SetText("AnchorBase: not found")
			return
		end

		local TargetPosition = PositionOf(Target)
		local Path = PathfindingService:CreatePath({ AgentRadius = 1.5, AgentHeight = 1.5, AgentCanJump = true })
		local Ok = pcall(function() Path:ComputeAsync(Root.Position, TargetPosition) end)
		local Waypoints = (Ok and Path.Status == Enum.PathStatus.Success) and Path:GetWaypoints() or nil

		if not Toggles.AP_AnchorGuide.Value then return end
		Folder:ClearAllChildren()

		local Lift = Vector3.new(0, 0.5, 0)
		if Waypoints then
			local Color = Color3.fromRGB(0, 200, 255)
			for Index = 1, #Waypoints - 1 do
				DrawLine(Waypoints[Index].Position + Lift, Waypoints[Index + 1].Position + Lift, Color)
			end
		else
			-- no walkable path: show a straight red line instead
			DrawLine(Root.Position, TargetPosition, Color3.fromRGB(255, 80, 80))
		end
		DrawTarget(TargetPosition)

		Info:SetText(string.format("AnchorBase: %d studs%s",
			math.floor((TargetPosition - Root.Position).Magnitude),
			Waypoints and "" or " (no path)"))
	end

	local Elapsed = 0
	local Beat = RunService.Heartbeat:Connect(function(Delta)
		if not Toggles.AP_AnchorGuide.Value then return end
		Elapsed += Delta
		if Elapsed < 0.5 or Busy then return end
		Elapsed = 0
		Busy = true
		task.spawn(function()
			pcall(Update)
			Busy = false
		end)
	end)

	Toggles.AP_AnchorGuide:OnChanged(function(Value)
		if not Value then
			Folder:ClearAllChildren()
			Info:SetText("AnchorBase: -")
			Target = nil
		end
	end)

	Library:OnUnload(function()
		Beat:Disconnect()
		Folder:Destroy()
	end)
end