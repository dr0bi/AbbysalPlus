return function(Window, Tab)
	local StairwellBox = Tab:AddLeftGroupbox("Stairwell")

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local LocalPlayer = Players.LocalPlayer
	local Connections = {}

	StairwellBox:AddToggle("AntiNoise", {
		Text = "AntiNoise",
		Default = false,
	})

	Toggles.AntiNoise:OnChanged(function(value)
		-- Отключаем старое соединение
		if Connections.AntiNoise then
			Connections.AntiNoise:Disconnect()
			Connections.AntiNoise = nil
		end

		if not value then
			return
		end

		-- Запускаем AntiNoise
		Connections.AntiNoise = RunService.PreSimulation:Connect(function(dt)
			if not LocalPlayer:GetAttribute("Alive") then
				return
			end

			local character = LocalPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local camera = workspace.CurrentCamera

			if not rootPart or not humanoid or not camera then
				return
			end

			local inputVector = humanoid.MoveDirection

			local cameraForward = Vector3.new(
				camera.CFrame.LookVector.X,
				0,
				camera.CFrame.LookVector.Z
			)

			local cameraRight = Vector3.new(
				camera.CFrame.RightVector.X,
				0,
				camera.CFrame.RightVector.Z
			)

			if cameraForward.Magnitude > 0 then
				cameraForward = cameraForward.Unit
			end

			if cameraRight.Magnitude > 0 then
				cameraRight = cameraRight.Unit
			end

			local worldDirection =
				(cameraRight * inputVector.X) +
				(cameraForward * -inputVector.Z)

			local inputMagnitude = worldDirection.Magnitude

			if inputMagnitude > 0 then
				worldDirection = worldDirection.Unit
			end

			local finalSpeed =
				humanoid.WalkSpeed *
				math.clamp(inputMagnitude, 0, 1)

			local clampedDt = math.min(dt, 0.1)

			rootPart.AssemblyLinearVelocity = Vector3.zero

			rootPart.CFrame =
				rootPart.CFrame +
				(worldDirection * finalSpeed * clampedDt)
		end)
	end)
end