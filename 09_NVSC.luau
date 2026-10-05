return function(Window, Tab)
	local Library = getgenv().Abysall.Interface.Library

	-- reuse the existing "Scripts" box (the one with Infinite Yield) in the Info tab
	local Box
	local InfoTab = Library.Tabs and Library.Tabs["Info"]
	if InfoTab and InfoTab.Groupboxes then
		Box = InfoTab.Groupboxes["Scripts"]
	end
	-- fallback: if it can't be found, make a "Scripts" box in our own tab
	Box = Box or Tab:AddLeftGroupbox("Scripts")

	Box:AddButton({
		Text = "NVCS-3000",
		Tooltip = "Runs NVCS-3000.",
		Func = function()
			local Ok, Err = pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/thelostw3r/Scripts/main/NVCS-3000.lua"))()
			end)
			if not Ok then warn("[Abbysal] script failed: " .. tostring(Err)) end
		end
	})
end