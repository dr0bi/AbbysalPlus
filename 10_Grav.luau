return function(Window, Tab)
	local StairwellBox = Tab:AddLeftGroupbox("Stairwell")

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	local Player = Players.LocalPlayer

	local Dashing = false
	local LastDash = 0

	local DashSpeed = 100
	local DashDuration = 0.25
	local DashCooldown = 1

	local function Dash()
		if Dashing then
			return
		end

		if tick() - LastDash < DashCooldown then
			return
		end

		local Character = Player.Character
		if not Character then
			return
		end

		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		local Root = Character:FindFirstChild("HumanoidRootPart")

		if not Humanoid or not Root or Humanoid.Health <= 0 then
			return
		end

		Dashing = true
		LastDash = tick()

		local OldCollision = {}

		-- Включаем noclip
		for _, Object in ipairs(Character:GetDescendants()) do
			if Object:IsA("BasePart") then
				OldCollision[Object] = Object.CanCollide
				Object.CanCollide = false
			end
		end

		local Direction = Root.CFrame.LookVector
		local StartTime = tick()

		while tick() - StartTime < DashDuration do
			if not Root.Parent then
				break
			end

			Root.AssemblyLinearVelocity =
				Direction * DashSpeed +
				Vector3.new(0, Root.AssemblyLinearVelocity.Y, 0)

			RunService.Heartbeat:Wait()
		end

		-- Возвращаем столкновения
		for Object, CanCollide in pairs(OldCollision) do
			if Object and Object.Parent then
				Object.CanCollide = CanCollide
			end
		end

		Dashing = false
	end

	-- Кнопка в интерфейсе
	StairwellBox:AddButton({
		Text = "Dash + Noclip",
		Func = function()
			Dash()
		end
	})

	-- Keybind через Obsidian
	StairwellBox:AddKeybind("DashKeybind", {
		Text = "Dash + Noclip Keybind",
		Default = Enum.KeyCode.Q,
	})

	-- Запуск через Keybind
	Toggles.DashKeybind:OnClick(function()
		Dash()
	end)
end