--[[
* MIT License
* 
* Copyright (c) 2023 tirem [github.com/tirem]
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
]]--
---------------------------------------------------------------------------
-- Credit to Atom0s, Thorny, and Heals for being a huge help on Discord! --
---------------------------------------------------------------------------

addon.name      = 'playerinfo';
addon.author    = 'Tirem';
addon.version   = '1.0';
addon.desc      = 'Displays information bars about the player.';
addon.link      = 'https://github.com/tirem/playerinfo'

require('common');
local imgui = require('imgui');
local fonts = require('fonts');
local settings = require('settings');

local hpText;
local mpText;
local tpText;

local default_settings =
T{
	barWidth = 600;
	barSpacing = 10;
	barHeight = 25;
	textYOffset = -3;
	font_settings = 
	T{
		visible = true,
		locked = true,
		font_family = 'Consolas',
		font_height = 16,
		color = 0xFFFFFFFF,
		bold = true,
		color_outline = 0xFF000000,
		draw_flags = 0x10,
		background = 
		T{
			visible = false,
		},
		right_justified = true;
	};
}
local config = settings.load(default_settings);

local function update_settings(s)
    if (s ~= nil) then
        configs = s;
    end

    settings.save();
end

settings.register('settings', 'settings_update', update_settings);

local function GetIsMob(targetEntity)
    -- Obtain the entity spawn flags..
    local flag = targetEntity.SpawnFlags;
    -- Determine the entity type
	local isMob;
    if (bit.band(flag, 0x0001) == 0x0001 or bit.band(flag, 0x0002) == 0x0002) then --players and npcs
        isMob = false;
    else --mob
		isMob = true;
    end
	return isMob;
end

local function UpdateTextVisibility(visible)
	hpText:SetVisible(visible);
	mpText:SetVisible(visible);
	tpText:SetVisible(visible);
end

--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    -- Obtain the player entity..
    local party     = AshitaCore:GetMemoryManager():GetParty();
    local player    = AshitaCore:GetMemoryManager():GetPlayer();
	
	if (party == nil or player == nil) then
		UpdateTextVisibility(false);
		return;
	end
	local currJob = player:GetMainJob();
    if (player.isZoning or currJob == 0) then
		UpdateTextVisibility(false);	
        return;
	end

	-- Draw the player window
    imgui.SetNextWindowSize({ config.barWidth + config.barSpacing * 2, -1, }, ImGuiCond_Always);
		
    if (imgui.Begin('PlayerInfo', true, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav, ImGuiWindowFlags_NoBackground))) then

		local SelfHP = party:GetMemberHP(0);
		local SelfHPMax = player:GetHPMax();
		local SelfHPPercent = SelfHP / SelfHPMax;
		local SelfMP = party:GetMemberMP(0);
		local SelfMPMax = player:GetMPMax();
		local SelfTP = party:GetMemberTP(0);

		-- Draw the bars for the players info and save the locations
		-- TODO: Make the colors configurable
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, {1, .4, .4, 1});
		imgui.ProgressBar(SelfHPPercent, { config.barWidth / 3 - config.barSpacing, config.barHeight }, '');
		imgui.PopStyleColor(1);
		imgui.SameLine();
		local hpLocX, hpLocY = imgui.GetCursorScreenPos();
		imgui.SetCursorPosX(imgui.GetCursorPosX() + config.barSpacing);
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, {.8, 1, .4, 1});
		imgui.ProgressBar(SelfMP / SelfMPMax, { config.barWidth / 3 - config.barSpacing, config.barHeight }, '');
		imgui.PopStyleColor(1);
		imgui.SameLine();
		local mpLocX, mpLocY  = imgui.GetCursorScreenPos()
		imgui.SetCursorPosX(imgui.GetCursorPosX() + config.barSpacing);
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, {.4, .4, 1, 1});
		imgui.ProgressBar(SelfTP / 3000, { config.barWidth / 3 - config.barSpacing, config.barHeight }, '');
		imgui.PopStyleColor(1);
		imgui.SameLine();
		local tpLocX, tpLocY  = imgui.GetCursorScreenPos();
		
		-- Update our HP Text
		hpText:SetPositionX(hpLocX - config.barSpacing);
		hpText:SetPositionY(hpLocY + config.barHeight + config.textYOffset);
		hpText:SetText(tostring(SelfHP));	
		if (SelfHPPercent < .25) then 
			hpText:SetColor(0xFFFF0000);
	    elseif (SelfHPPercent < .50) then;
			hpText:SetColor(0xFFFFA500);
	    elseif (SelfHPPercent < .75) then
			hpText:SetColor(0xFFFFFF00);
		else
			hpText:SetColor(0xFFFFFFFF);
	    end
		
		-- Update our MP Text
		mpText:SetPositionX(mpLocX - config.barSpacing);
		mpText:SetPositionY(mpLocY + config.barHeight + config.textYOffset);
		mpText:SetText(tostring(SelfMP));
		if (SelfMP == SelfMPMax) then 
			mpText:SetColor(0xFFCFFBCF);
		else
			mpText:SetColor(0xFFFFFFFF);
	    end
		
		-- Update our TP Text
		tpText:SetPositionX(tpLocX - config.barSpacing);
		tpText:SetPositionY(tpLocY + config.barHeight + config.textYOffset);
		tpText:SetText(tostring(SelfTP));
		if (SelfTP > 1000) then 
			tpText:SetColor(0xFF3C89D0);
		else
			tpText:SetColor(0xFFD1EDF2);
	    end	

		UpdateTextVisibility(true);	
	
    end
	imgui.End();
end);

ashita.events.register('load', 'load_cb', function ()
    hpText = fonts.new(config.font_settings);
	mpText = fonts.new(config.font_settings);
	tpText = fonts.new(config.font_settings);
end);
