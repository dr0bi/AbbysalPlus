return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Toggles = Library.Toggles
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local PathfindingService = game:GetService("PathfindingService")

	local Box = Tab:AddLeftGroupbox("AnchorBase Guide")
	Box:AddToggle("AP_AnchorGuide", {
		Text = "Show Path to AnchorBase", Default = false,
		Tooltip = "Shows the walkable route (Pathfinding) to the nearest unused AnchorBase. It only shows the way, you walk yourself."
	})
	local Info = Box:AddLabel("AnchorBase: -")

	local Folder = Instance.new("Folder")
	Folder.Name = "AbbysalAnchorGuide"
	Folder.Parent = workspace

	-- invisible part that the dot adornments attach to (dots stay visible through walls)
	local DotAnchor = Instance.new("Part")
	DotAnchor.Anchored = true
	DotAnchor.CanCollide = false
	DotAnchor.CanQuery = false
	DotAnchor.CanTouch = false
	DotAnchor.Transparency = 1
	DotAnchor.Size = Vector3.one
	DotAnchor.CFrame = CFrame.new()
	DotAnchor.Parent = Folder

	local AgentParams = { AgentRadius = 1.5, AgentHeight = 4, AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 4 }

	local Target
	local GoodGoal -- the reachable point near the target that worked last time
	local LastScan = 0
	local Busy = false

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	local function PositionOf(Object)
		if Object:IsA("Model") then
			return Object:GetPivot().Position
		elseif Object:IsA("BasePart") then
			return Object.Position
		end
	end

	-- an anchor counts as used once its MinesAnchor model has Activated = true
	local function IsActivated(Object)
		local Anchor = Object:FindFirstAncestor("MinesAnchor")
		return Anchor ~= nil and Anchor:GetAttribute("Activated") == true
	end

	local function FindNearest(From)
		local Best, BestDistance
		for _, Object in workspace:GetDescendants() do
			if Object.Name == "AnchorBase" and (Object:IsA("Model") or Object:IsA("BasePart")) and not IsActivated(Object) then
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

	-- puts a point on the floor below it, so the path ends on walkable ground instead of inside the object
	local function SnapToGround(Position)
		local Character = LocalPlayer.Character
		RayParams.FilterDescendantsInstances = { Character, Folder }
		local Hit = workspace:Raycast(Position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), RayParams)
		return Hit and (Hit.Position + Vector3.new(0, 1, 0)) or Position
	end

	local function Compute(From, Goal)
		local Path = PathfindingService:CreatePath(AgentParams)
		local Ok = pcall(function() Path:ComputeAsync(From, Goal) end)
		if Ok and Path.Status == Enum.PathStatus.Success then
			return Path:GetWaypoints()
		end
	end

	-- tries the target itself, then points on rings around it, until one has a real walkable route
	local function FindRoute(From, TargetPosition)
		if GoodGoal then
			local Waypoints = Compute(From, GoodGoal)
			if Waypoints then return Waypoints, GoodGoal end
		end
		local Candidates = { SnapToGround(TargetPosition) }
		for _, Radius in { 4, 8, 14 } do
			for Step = 0, 7 do
				local Angle = Step * math.pi / 4
				local Offset = Vector3.new(math.cos(Angle) * Radius, 0, math.sin(Angle) * Radius)
				table.insert(Candidates, SnapToGround(TargetPosition + Offset))
			end
		end
		for _, Goal in Candidates do
			local Waypoints = Compute(From, Goal)
			if Waypoints then
				GoodGoal = Goal
				return Waypoints, Goal
			end
		end
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
		Part.Transparency = 0.35
		Part.Size = Vector3.new(0.15, 0.15, Length)
		Part.CFrame = CFrame.lookAt((A + B) / 2, B)
		Part.Parent = Folder
	end

	local function DrawDot(Position, Radius, Color)
		local Dot = Instance.new("SphereHandleAdornment")
		Dot.Adornee = DotAnchor
		Dot.CFrame = CFrame.new(Position)
		Dot.Radius = Radius
		Dot.Color3 = Color
		Dot.Transparency = 0.15
		Dot.AlwaysOnTop = true
		Dot.ZIndex = 1
		Dot.Parent = Folder
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

		if not Target or not Target.Parent or IsActivated(Target) or os.clock() - LastScan > 3 then
			local Found = FindNearest(Root.Position)
			if Found ~= Target then GoodGoal = nil end
			Target = Found
			LastScan = os.clock()
		end
		if not Target then
			Folder:ClearAllChildren()
			DotAnchor.Parent = Folder
			Info:SetText("AnchorBase: none left (or not found)")
			return
		end

		local TargetPosition = PositionOf(Target)
		local Waypoints = FindRoute(Root.Position, TargetPosition)
		if not Toggles.AP_AnchorGuide.Value then return end

		-- redraw (keep the dot anchor part)
		for _, Child in Folder:GetChildren() do
			if Child ~= DotAnchor then Child:Destroy() end
		end

		local Lift = Vector3.new(0, 0.6, 0)
		if Waypoints then
			local CyanColor = Color3.fromRGB(0, 200, 255)
			local NextMarked = false
			for Index = 1, #Waypoints do
				local Waypoint = Waypoints[Index]
				local Position = Waypoint.Position + Lift
				if Index < #Waypoints then
					DrawLine(Position, Waypoints[Index + 1].Position + Lift, CyanColor)
				end
				if Waypoint.Action == Enum.PathWaypointAction.Jump then
					DrawDot(Position, 0.55, Color3.fromRGB(255, 220, 0)) -- jump here
				elseif not NextMarked and (Waypoint.Position - Root.Position).Magnitude > 3 then
					NextMarked = true
					DrawDot(Position, 0.7, Color3.fromRGB(255, 255, 255)) -- go here next
				else
					DrawDot(Position, 0.3, CyanColor)
				end
			end
		else
			-- no walkable route found anywhere near the target: straight red line as a fallback
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
		if Elapsed < 0.75 or Busy then return end
		Elapsed = 0
		Busy = true
		task.spawn(function()
			pcall(Update)
			Busy = false
		end)
	end)

	Toggles.AP_AnchorGuide:OnChanged(function(Value)
		if not Value then
			for _, Child in Folder:GetChildren() do
				if Child ~= DotAnchor then Child:Destroy() end
			end
			Info:SetText("AnchorBase: -")
			Target, GoodGoal = nil, nil
		end
	end)

	Library:OnUnload(function()
		Beat:Disconnect()
		Folder:Destroy()
	end)
end
