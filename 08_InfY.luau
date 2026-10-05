return function(Window, Tab)
	local Box = Tab:AddLeftGroupbox("Scripts")

	Box:AddButton({
		Text = "Infinite Yield",
		Func = function()
			local Ok, Err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
			end)
			if not Ok then warn("[Abbysal] script failed: " .. tostring(Err)) end
		end
	})
end