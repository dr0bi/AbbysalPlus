return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Toggles, Options = Library.Toggles, Library.Options
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local PathfindingService = game:GetService("PathfindingService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local GameData = ReplicatedStorage:WaitForChild("GameData", 5)
	local LatestRoom = GameData and GameData:WaitForChild("LatestRoom", 5)
	local CurrentRooms = workspace:WaitForChild("CurrentRooms", 5)
	if not LatestRoom or not CurrentRooms then
		warn("[Abbysal] Auto Doors: GameData / CurrentRooms not found, addon skipped")
		return
	end

	local Box = Tab:AddLeftGroupbox("Auto Doors")
	Box:AddToggle("AP_AutoDoors", {
		Text = "Auto Doors", Default = false,
		Tooltip = "Pathfinds to each door and opens it. When stuck it marks the spot to path around it, and teleports to the door after several retries."
	})
	Box:AddSlider("AP_AutoDoorsTimeout", { Text = "Pathfind Timeout", Min = 0.5, Max = 3, Default = 1, Rounding = 1 })
	Box:AddSlider("AP_AutoDoorsRetries", {
		Text = "Stuck Retries", Min = 0, Max = 5, Default = 2, Rounding = 0,
		Tooltip = "Re-paths around a stuck spot this many times before teleporting to the door. 0 = teleport immediately."
	})

	local MarkerFolder = Instance.new("Folder")
	MarkerFolder.Name = "AbbysalStuckMarkers"
	MarkerFolder.Parent = workspace

	local Busy = false
	local StuckRoom, StuckCount = nil, 0

	local function Tick()
		if not Toggles.AP_AutoDoors.Value or Busy then return end
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		local Root = Character and Character:FindFirstChild("HumanoidRootPart")
		if not Humanoid or not Root or Humanoid.Health <= 0 then return end

		local RoomNumber = LatestRoom.Value
		local Room = CurrentRooms:FindFirstChild(tostring(RoomNumber))
		local DoorModel = Room and Room:FindFirstChild("Door")
		local DoorPart = DoorModel and (DoorModel:FindFirstChild("Door") or DoorModel.PrimaryPart)
		if not DoorPart then return end

		Busy = true
		task.spawn(function()
			pcall(function()
				DoorPart.CanCollide = false
				local Path = PathfindingService:CreatePath({
					AgentCanJump = true, AgentCanClimb = false, WaypointSpacing = 4,
					AgentRadius = 1.5, AgentHeight = 1.5, Costs = { StuckPart = 8 }
				})
				local Computed = pcall(function() Path:ComputeAsync(Root.Position, DoorPart.Position) end)
				local Waypoints = Computed and Path:GetWaypoints() or {}

				local Stuck = #Waypoints == 0
				for _, Waypoint in Waypoints do
					if Stuck or not Toggles.AP_AutoDoors.Value or Humanoid.Health <= 0 then break end
					if Waypoint.Action == Enum.PathWaypointAction.Jump then Humanoid.Jump = true end
					Humanoid:MoveTo(Waypoint.Position)

					local Start = tick()
					while Toggles.AP_AutoDoors.Value do
						local Flat = Vector3.new(Waypoint.Position.X - Root.Position.X, 0, Waypoint.Position.Z - Root.Position.Z)
						if Flat.Magnitude <= 4 then break end
						if (Root.Position - DoorPart.Position).Magnitude < 40 then
							pcall(function() DoorModel.ClientOpen:FireServer() end)
						end
						if tick() - Start > Options.AP_AutoDoorsTimeout.Value then
							Stuck = true
							break
						end
						task.wait()
					end
				end
				Humanoid:MoveTo(Root.Position)

				if Stuck and Toggles.AP_AutoDoors.Value then
					if StuckRoom ~= RoomNumber then
						StuckRoom, StuckCount = RoomNumber, 0
					end
					StuckCount += 1

					-- mark the stuck spot so the next path goes around it
					local Block = Instance.new("Part")
					Block.Transparency = 1
					Block.Size = Vector3.one
					Block.Shape = Enum.PartType.Ball
					Block.CFrame = Root.CFrame
					Block.CanCollide = false
					Block.Anchored = true
					Block.Name = "StuckPart"
					local Modifier = Instance.new("PathfindingModifier")
					Modifier.Label = "StuckPart"
					Modifier.Parent = Block
					Block.Parent = MarkerFolder

					if StuckCount > Options.AP_AutoDoorsRetries.Value then
						StuckCount = 0
						Character:PivotTo(CFrame.new(DoorPart.Position + Vector3.new(0, 3, 0)))
						task.wait(0.2)
					else
						return -- try again with a new path around the marker
					end
				end

				if Toggles.AP_AutoDoors.Value then
					for _ = 1, 10 do
						pcall(function() DoorModel.ClientOpen:FireServer() end)
						task.wait(0.1)
					end
					local Start = tick()
					while Toggles.AP_AutoDoors.Value and LatestRoom.Value == RoomNumber and tick() - Start < 5 do
						task.wait()
					end
				end
			end)
			Busy = false
		end)
	end

	local Beat = RunService.Heartbeat:Connect(function() pcall(Tick) end)
	local Added = CurrentRooms.ChildAdded:Connect(function()
		MarkerFolder:ClearAllChildren()
	end)
	Library:OnUnload(function()
		Beat:Disconnect()
		Added:Disconnect()
		MarkerFolder:Destroy()
	end)
end
