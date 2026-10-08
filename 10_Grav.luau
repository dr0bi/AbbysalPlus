return function(Window, Tab)
	local Box = Tab:AddLeftGroupbox("Stairwell")

	Box:AddButton({
		Text = "Give GravityGun",
		Func = function()
			local Ok, Err = pcall(function()
				local Players = game:GetService("Players")
				local player = Players.LocalPlayer

				local Part = game:GetObjects("rbxassetid://8025924073")[1]

				if not Part then
					error("Studded Part не загрузился")
				end

				-- Если это уже Tool — просто выдаём его
				if Part:IsA("Tool") then
					Part.Parent = player.Backpack
					return
				end

				-- Если загружен обычный Part/Model,
				-- превращаем его в Tool
				local Tool = Instance.new("Tool")
				Tool.Name = "GravityGun"
				Tool.RequiresHandle = true
				Tool.CanBeDropped = true

				local Handle

				if Part:IsA("BasePart") then
					Handle = Part
				elseif Part:IsA("Model") then
					Handle = Part:FindFirstChildWhichIsA("BasePart", true)

					if not Handle then
						error("В модели нет BasePart")
					end

					for _, obj in ipairs(Part:GetDescendants()) do
						if obj:IsA("BasePart") then
							obj.Anchored = false
							obj.CanCollide = false
							if obj ~= Handle then
								local Weld = Instance.new("WeldConstraint")
								Weld.Part0 = Handle
								Weld.Part1 = obj
								Weld.Parent = Handle
							end
						end
					end
				end

				Handle.Name = "Handle"
				Handle.Anchored = false
				Handle.CanCollide = false
				Handle.Massless = true
				Handle.Parent = Tool

				Part.Parent = Tool

				Tool.Parent = player.Backpack
			end)

			if not Ok then
				warn("[Abbysal] GravityGun failed: " .. tostring(Err))
			end
		end
	})
end