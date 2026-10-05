return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local Toggles, Options = Library.Toggles, Library.Options
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ContextActionService = game:GetService("ContextActionService")
	local LocalPlayer = game:GetService("Players").LocalPlayer

	local Box = Tab:AddRightGroupbox("Free Cam")
	Box:AddToggle("AP_FreeCam", {
		Text = "Free Cam", Default = false,
		Tooltip = "Fly the camera around while your character stays in place. WASD move, E/Q up/down, Shift = faster."
	})
	Toggles.AP_FreeCam:AddKeyPicker("AP_FreeCamKey", { Text = "Free Cam", Default = "P", Mode = "Toggle", SyncToggleState = true })
	Box:AddSlider("AP_FreeCamSpeed", { Text = "Speed", Min = 5, Max = 200, Default = 40, Rounding = 0, Compact = true })

	local Running = false
	local Pos, Pitch, Yaw

	local function Sink() return Enum.ContextActionResult.Sink end

	local function Stop()
		if not Running then return end
		Running = false
		pcall(function() RunService:UnbindFromRenderStep("AbbysalFreeCam") end)
		pcall(function() ContextActionService:UnbindAction("AbbysalFreeCamSink") end)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		local Camera = workspace.CurrentCamera
		if Camera then
			Camera.CameraType = Enum.CameraType.Custom
			local Character = LocalPlayer.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
			if Humanoid then Camera.CameraSubject = Humanoid end
		end
	end

	local function Start()
		local Camera = workspace.CurrentCamera
		if Running or not Camera then return end
		Running = true
		Pos = Camera.CFrame.Position
		Pitch, Yaw = Camera.CFrame:ToOrientation()
		Camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		ContextActionService:BindActionAtPriority("AbbysalFreeCamSink", Sink, false, 3000,
			Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
			Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Space, Enum.KeyCode.LeftShift)
		RunService:BindToRenderStep("AbbysalFreeCam", Enum.RenderPriority.Camera.Value + 1, function(Delta)
			local Cam = workspace.CurrentCamera
			if not Cam then return end
			if Cam.CameraType ~= Enum.CameraType.Scriptable then Cam.CameraType = Enum.CameraType.Scriptable end
			local MouseDelta = UserInputService:GetMouseDelta()
			Yaw = Yaw - MouseDelta.X * 0.0025
			Pitch = math.clamp(Pitch - MouseDelta.Y * 0.0025, -1.55, 1.55)
			local Rotation = CFrame.fromOrientation(Pitch, Yaw, 0)
			local function Key(Code) return UserInputService:IsKeyDown(Code) and 1 or 0 end
			local Forward = Key(Enum.KeyCode.S) - Key(Enum.KeyCode.W)
			local Side = Key(Enum.KeyCode.D) - Key(Enum.KeyCode.A)
			local Up = Key(Enum.KeyCode.E) - Key(Enum.KeyCode.Q)
			local Speed = Options.AP_FreeCamSpeed.Value * (Key(Enum.KeyCode.LeftShift) == 1 and 3 or 1)
			local Move = Rotation:VectorToWorldSpace(Vector3.new(Side, 0, Forward)) + Vector3.new(0, Up, 0)
			Pos = Pos + Move * Speed * Delta
			Cam.CFrame = CFrame.new(Pos) * Rotation
		end)
	end

	Toggles.AP_FreeCam:OnChanged(function(Value)
		if Value then Start() else Stop() end
	end)
	Library:OnUnload(Stop)
end
