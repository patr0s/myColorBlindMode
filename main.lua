-- Colorblind mode is activated to show item quality and PC/NPC reaction strings
-- Problem: when colorblind mode is set in blizzard options, money icons are replaced by letters
-- which is undone by this module

------------------------------------------------------------------------------------------------
-- LOCAL DEFINITIONS
------------------------------------------------------------------------------------------------
local goldString	= "(%d+)" .. GOLD_AMOUNT_SYMBOL
local silverString 	= "(%d+)" .. SILVER_AMOUNT_SYMBOL
local copperString 	= "(%d+)" .. COPPER_AMOUNT_SYMBOL

local GetIconsFromMoneyString = function(text)
	-- Converting a money amount to its icons counterpart in a string (i.e.: '12g 17s 54c' to '12 [goldCoinIcon] 17 [silverCoinIcon] 54 [copperCoinIcon]')
	text = tostring(text)

	local _, gold, silver, copper
	_, _, gold = text:find(goldString)
	_, _, silver = text:find(silverString)
	_, _, copper = text:find(copperString)

	while (gold or silver or copper) do
		if gold then text = text:gsub(goldString, GOLD_AMOUNT_TEXTURE:format(gold, 0, 0), 1) end
		if silver then text = text:gsub(silverString, SILVER_AMOUNT_TEXTURE:format(silver, 0, 0), 1) end
		if copper then text = text:gsub(copperString, COPPER_AMOUNT_TEXTURE:format(copper, 0, 0), 1) end

		_, _, gold = text:find(goldString)
		_, _, silver = text:find(silverString)
		_, _, copper = text:find(copperString)
	end

	return text
end

------------------------------------------------------------------------------------------------
-- REPLACEMENT FUNCTIONS
------------------------------------------------------------------------------------------------
local savedMoneyInputFrame_OnShow = MoneyInputFrame_OnShow
function MoneyInputFrame_OnShow(moneyFrame)
	ENABLE_COLORBLIND_MODE = 0
	savedMoneyInputFrame_OnShow(moneyFrame)
	ENABLE_COLORBLIND_MODE = 1
end

-- GameTooltip was tainted when updating MoneyFrame while in combat, still true?
local MoneyFrame_Update_Hooked
hooksecurefunc("MoneyFrame_Update", function(frameName, money)
	if MoneyFrame_Update_Hooked then
		MoneyFrame_Update_Hooked = nil
		ENABLE_COLORBLIND_MODE = 1
	else
		MoneyFrame_Update_Hooked = true
		ENABLE_COLORBLIND_MODE = 0
		MoneyFrame_Update(frameName, money)
	end
end)

local savedGetMoneyString = GetMoneyString
function GetMoneyString(money)
	ENABLE_COLORBLIND_MODE = 0
	local value =  savedGetMoneyString(money)
	ENABLE_COLORBLIND_MODE = 1
	return value
end

local savedSendMailFrame_CanSend = SendMailFrame_CanSend
function SendMailFrame_CanSend()
	ENABLE_COLORBLIND_MODE = 0
	savedSendMailFrame_CanSend()
	ENABLE_COLORBLIND_MODE = 1
end

local savedFriendsFrame_SetButton = FriendsFrame_SetButton
function FriendsFrame_SetButton(button, index, firstButton)
	ENABLE_COLORBLIND_MODE = 0
	local value = savedFriendsFrame_SetButton(button, index, firstButton)
	ENABLE_COLORBLIND_MODE = 1
	return value
end

local savedOpenCoinPickupFrame = OpenCoinPickupFrame
function OpenCoinPickupFrame(multiplier, maxMoney, parent)
	ENABLE_COLORBLIND_MODE = 0
	savedOpenCoinPickupFrame(multiplier, maxMoney, parent)
	ENABLE_COLORBLIND_MODE = 1
end

local savedTradeSkillFrame_Update = TradeSkillFrame_Update
function TradeSkillFrame_Update()
	ENABLE_COLORBLIND_MODE = 0
	savedTradeSkillFrame_Update()
	ENABLE_COLORBLIND_MODE = 1
end

local savedItemSocketingFrame_Update = ItemSocketingFrame_Update
function ItemSocketingFrame_Update()
	ENABLE_COLORBLIND_MODE = 0
	savedItemSocketingFrame_Update()
	ENABLE_COLORBLIND_MODE = 1
end

local savedPetBattleUnitFrame_UpdateDisplay = PetBattleUnitFrame_UpdateDisplay
function PetBattleUnitFrame_UpdateDisplay(self)
	ENABLE_COLORBLIND_MODE = 0
	savedPetBattleUnitFrame_UpdateDisplay(self)
	ENABLE_COLORBLIND_MODE = 1
end

local updater = CreateFrame("frame")
updater:RegisterEvent("ADDON_LOADED")
updater:SetScript("OnEvent", function(self, event, name)
	if event ~= "ADDON_LOADED" then return end
	if name == "Blizzard_AchievementUI" or IsAddOnLoaded("Blizzard_AchievementUI") then
		self:UnregisterEvent(event)

		local savedAchievementButton_GetProgressBar = AchievementButton_GetProgressBar
		function AchievementButton_GetProgressBar(index, renderOffScreen)
			local frame = savedAchievementButton_GetProgressBar(index, renderOffScreen)
			if not frame.hooked then
				frame.hooked = true
				frame.text:SetOutlinedFont(nil, 12)
				hooksecurefunc(frame.text, "SetText", function(self, text)
					if self.doNotHook then
						self.doNotHook = nil
						return
					end

					local newText = getIconsFromMoneyString(text)
					if newText ~= text then
						self.doNotHook = true
						self:SetText(newText)
					end
				end)
			end

			return frame
		end

		hooksecurefunc("AchievementFrameStats_SetStat", function(button, category, index, colorIndex, isSummary)
			local value = button.value:GetText()
			local newValue = getIconsFromMoneyString(value)
			if newValue ~= value then
				button.value:SetText(newValue)
			end
		end)
	end
end)