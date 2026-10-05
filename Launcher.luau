-- Abbysal Plus launcher (GitHub version)
-- Runs the ORIGINAL Main.luau from the Abysall repo (untouched) and loads every addon
-- listed in addons.txt from YOUR repo into a new "Abbysal Plus" tab.
--
-- 1) Put your GitHub name and repo name below.
-- 2) Everyone runs:  loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/Launcher.luau"))()

local BaseUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/"
local MainUrl = "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/Games/Doors/Main.luau"

if BaseUrl:find("YOUR_", 1, true) then
	error("[Abbysal] Open Launcher.luau and set BaseUrl to your GitHub repo first.", 0)
end

getgenv().AbbysalLoadAddons = function(Window)
	local Ok, List = pcall(function() return game:HttpGet(BaseUrl .. "addons.txt") end)
	if not Ok then
		warn("[Abbysal] could not download addons.txt: " .. tostring(List))
		return
	end

	local Tab = Window:AddTab("Abbysal Plus", "star")
	for Name in List:gmatch("[^\r\n]+") do
		Name = Name:match("^%s*(.-)%s*$")
		if Name ~= "" and not Name:match("^%-%-") then
			local Success, Err = pcall(function()
				local Addon = loadstring(game:HttpGet(BaseUrl .. Name), "@" .. Name)()
				Addon(Window, Tab)
			end)
			if not Success then
				warn("[Abbysal] addon failed: " .. Name .. " -> " .. tostring(Err))
			end
		end
	end
end

local Source = game:HttpGet(MainUrl)
-- Main calls ApplySettingsTab(Window) as its very last step; load the addons right before it
local Needle = "Abysall.Interface.ApplySettingsTab(Window)"
local Start = string.find(Source, Needle, 1, true)
if Start then
	Source = Source:sub(1, Start - 1)
		.. "if getgenv().AbbysalLoadAddons then getgenv().AbbysalLoadAddons(Window) end\n"
		.. Source:sub(Start)
else
	warn("[Abbysal] hook line not found in Main.luau, running it without addons")
end

loadstring(Source)()
