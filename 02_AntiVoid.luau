return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Toggles, Options = Library.Toggles, Library.Options
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")

	local Box = Tab:AddLeftGroupbox("Anti-Void")
	Box:AddToggle("AP_AntiVoid", {
		Text = "Anti-Void", Default = false,
		Tooltip = "Reverts sudden teleports and pushes, and rescues you from falling into the void. Your own walking still works."
	})
	Box:AddToggle("AP_AntiVoidLock", {
		Text = "Lock Position", Default = false,
		Tooltip = "Freezes you completely in place until you turn this off."
	})
	Box:AddSlider("AP_AntiVoidStep", {
		Text = "Max Step", Min = 2, Max = 50, Default = 8, Rounding = 0, Compact = true,
		Tooltip = "Any move larger than this many studs in one frame is treated as a teleport and undone."
	})

	local LastRoot, Last, Safe, LockCF

	local function Step()
		local Lock = Toggles.AP_AntiVoidLock.Value
		if not Lock and not Toggles.AP_AntiVoid.Value then
			if LastRoot then LastRoot, Last, Safe, LockCF = nil, nil, nil, nil end
			return
		end
		local Character = LocalPlayer.Character
		local Root = Character and Character:FindFirstChild("HumanoidRootPart")
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if not Root or not Humanoid then LastRoot = nil return end
		if Root ~= LastRoot then
			LastRoot, Last, Safe, LockCF = Root, nil, nil, nil
		end

		if Lock then
			LockCF = LockCF or Root.CFrame
			if (Root.Position - LockCF.Position).Magnitude > 0.05 then
				Root.CFrame = LockCF
				Root.AssemblyLinearVelocity = Vector3.zero
				Root.AssemblyAngularVelocity = Vector3.zero
			end
			Last = LockCF
			return
		end
		LockCF = nil

		if Last and (Root.Position - Last.Position).Magnitude > Options.AP_AntiVoidStep.Value then
			Root.CFrame = Last
			Root.AssemblyLinearVelocity = Vector3.zero
		else
			Last = Root.CFrame
		end
		if Humanoid.FloorMaterial ~= Enum.Material.Air then
			Safe = Root.CFrame
		end
		if Safe and Root.Position.Y < Safe.Position.Y - 60 then
			Root.CFrame = Safe + Vector3.new(0, 3, 0)
			Root.AssemblyLinearVelocity = Vector3.zero
			Last = Root.CFrame
		end
	end

	-- other addons (Teleport Markers) call this after teleporting so Anti-Void doesn't undo it
	getgenv().AbbysalAntiVoidReset = function(NewCFrame)
		Last = nil
		if LockCF then LockCF = NewCFrame end
	end

	local Render = RunService.RenderStepped:Connect(Step)
	local Beat = RunService.Heartbeat:Connect(Step)
	Library:OnUnload(function()
		Render:Disconnect()
		Beat:Disconnect()
		getgenv().AbbysalAntiVoidReset = nil
	end)
end
