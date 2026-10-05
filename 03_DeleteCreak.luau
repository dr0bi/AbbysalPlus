return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library

	local Box = Tab:AddRightGroupbox("Entities")
	Box:AddButton({
		Text = "Delete Creak",
		Tooltip = "Deletes the Creak entity model on your client.",
		Func = function()
			local Count = 0
			for _, Object in workspace:GetDescendants() do
				if Object.Name == "Creak" and Object:IsA("Model") then
					pcall(function() Object:Destroy() end)
					Count += 1
				end
			end
			Library:Notify({
				Title = "Delete Creak",
				Description = Count > 0 and ("Deleted " .. Count .. " Creak entity(ies).") or "No Creak found."
			})
		end
	})
end
