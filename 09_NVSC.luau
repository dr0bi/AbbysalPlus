return function(Window, Tab)
	local Box = Tab:AddLeftGroupbox("Scripts")

	Box:AddButton({
		Text = "NVSC-3000",
		Func = function()
			local Ok, Err = pcall(function()
				loadstring(game:HttpGet("loadstring(game:HttpGet("https://raw.githubusercontent.com/thelostw3r/Scripts/main/NVCS-3000.lua"))()"))()
			end)
			if not Ok then warn("[Abbysal] script failed: " .. tostring(Err)) end
		end
	})
end