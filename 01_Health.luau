return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library
	local LocalPlayer = game:GetService("Players").LocalPlayer

	local Box = Tab:AddLeftGroupbox("Health")
	Box:AddSlider("AP_HealthAmount", {
		Text = "HP Amount", Min = 1, Max = 100, Default = 50, Rounding = 0, Compact = true,
		Tooltip = "How much HP the Subtract button removes."
	})
	Box:AddButton({
		Text = "Subtract",
		Tooltip = "Subtracts the selected amount of HP.",
		Func = function()
			local Character = LocalPlayer.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
			if Humanoid and Humanoid.Health > 0 then
				Humanoid.Health = math.max(0, Humanoid.Health - Library.Options.AP_HealthAmount.Value)
			end
		end
	})
end
