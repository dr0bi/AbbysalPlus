return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Toggles, Options = Library.Toggles, Library.Options
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local GameData = ReplicatedStorage:WaitForChild("GameData", 5)
	local LatestRoom = GameData and GameData:WaitForChild("LatestRoom", 5)
	local CurrentRooms = workspace:WaitForChild("CurrentRooms", 5)
	if not LatestRoom or not CurrentRooms then
		warn("[Abbysal] Rooms optimization: GameData / CurrentRooms not found, addon skipped")
		return
	end

	local Box = Tab:AddLeftGroupbox("Optimization: Rooms")
	Box:AddToggle("AP_LimitRooms", {
		Text = "Leave Only Rooms", Default = false,
		Tooltip = "Deletes old rooms behind you on your client and keeps only the chosen number of latest rooms."
	})
	Box:AddSlider("AP_KeepRooms", {
		Text = "Rooms To Keep", Min = 1, Max = 10, Default = 3, Rounding = 0, Compact = true,
		Tooltip = "How many of the latest rooms (including the current one) stay loaded."
	})
	Box:AddToggle("AP_NoDecals", {
		Text = "Remove Decals & Textures", Default = false,
		Tooltip = "Deletes decals and textures in rooms (cannot be undone for rooms already processed)."
	})
	Box:AddToggle("AP_NoPartShadows", {
		Text = "Disable Part Shadows", Default = false,
		Tooltip = "Turns off shadow casting on parts in rooms."
	})

	local function GetRoot()
		local Character = LocalPlayer.Character
		return Character and Character:FindFirstChild("HumanoidRootPart")
	end

	local function TrimRooms()
		if not Toggles.AP_LimitRooms.Value then return end
		local Keep = Options.AP_KeepRooms.Value
		local Latest = LatestRoom.Value
		local Root = GetRoot()
		for _, Room in CurrentRooms:GetChildren() do
			local Number = tonumber(Room.Name)
			if Number and Number <= Latest - Keep then
				-- never delete a room you are standing in
				local Inside = false
				if Root then
					local Ok, CF, Size = pcall(function() return Room:GetBoundingBox() end)
					if Ok and Size then
						local Local = CF:PointToObjectSpace(Root.Position)
						Inside = math.abs(Local.X) < Size.X / 2 + 5
							and math.abs(Local.Y) < Size.Y / 2 + 5
							and math.abs(Local.Z) < Size.Z / 2 + 5
					end
				end
				if not Inside then pcall(function() Room:Destroy() end) end
			end
		end
	end

	local function ProcessRoom(Room)
		local NoDecals = Toggles.AP_NoDecals.Value
		local NoShadows = Toggles.AP_NoPartShadows.Value
		if not NoDecals and not NoShadows then return end
		for _, Object in Room:GetDescendants() do
			if NoDecals and (Object:IsA("Decal") or Object:IsA("Texture")) then
				pcall(function() Object:Destroy() end)
			elseif NoShadows and Object:IsA("BasePart") and Object.CastShadow then
				Object.CastShadow = false
			end
		end
	end

	local function ProcessAll()
		for _, Room in CurrentRooms:GetChildren() do
			task.spawn(ProcessRoom, Room)
		end
	end

	Toggles.AP_NoDecals:OnChanged(ProcessAll)
	Toggles.AP_NoPartShadows:OnChanged(ProcessAll)
	Toggles.AP_LimitRooms:OnChanged(TrimRooms)
	Options.AP_KeepRooms:OnChanged(TrimRooms)

	local Added = CurrentRooms.ChildAdded:Connect(function(Room)
		task.wait(0.5) -- let the room finish loading
		if Room.Parent then ProcessRoom(Room) end
		TrimRooms()
	end)
	local Changed = LatestRoom.Changed:Connect(function()
		task.defer(TrimRooms)
	end)
	Library:OnUnload(function()
		Added:Disconnect()
		Changed:Disconnect()
	end)
end
