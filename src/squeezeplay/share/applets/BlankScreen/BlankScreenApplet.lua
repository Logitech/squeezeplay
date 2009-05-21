
--[[
=head1 NAME

applets.BlankScreen.BlankScreenApplet - A screensaver displaying a BlankScreen photo stream.

=head1 DESCRIPTION

This screensaver applet blanks the screen

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. 
BlankScreenApplet overrides the following methods:

=cut
--]]


-- stuff we use
local oo               = require("loop.simple")

--local jiveBSP          = require("jiveBSP")
local Framework        = require("jive.ui.Framework")
local Window           = require("jive.ui.Window")
local Timer            = require("jive.ui.Timer")
local Surface          = require("jive.ui.Surface")
local Icon             = require("jive.ui.Icon")
local debug            = require("jive.utils.debug")

local jnt              = jnt
local appletManager    = appletManager

module(..., Framework.constants)
oo.class(_M, Applet)

function init(self)

	self.sw, self.sh = Framework:getScreenSize()

	-- create window and icon
	self.window = Window("text_list")
	self.bg  = Surface:newRGBA(self.sw, self.sh)
	self.bg:filledRectangle(0, 0, self.sw, self.sh, 0x000000FF)

	self.bgicon = Icon("icon", self.bg)
	self.window:addWidget(self.bgicon)

	self.window:addListener(EVENT_WINDOW_ACTIVE | EVENT_HIDE,
		function(event)
			local type = event:getType()
			if type == EVENT_WINDOW_ACTIVE then
				if not self.brightness then
					self.brightness = self:_getBrightness()
				end
				self:_setBrightness(0)
			else
				self:_setBrightness(self.brightness)
				self.brightness = nil
			end
			return EVENT_UNUSED
		end,
		true
	)

	self.window:addListener(EVENT_MOTION,
		function()
			self.window:hide()
			return EVENT_CONSUME
		end)

	-- register window as a screensaver
	local manager = appletManager:getAppletInstance("ScreenSavers")
	manager:screensaverWindow(self.window)

end

function closeScreensaver(self)
	-- nothing to do here, brightness is refreshed via window event handler in init()
end

function openScreensaver(self, menuItem)
	self.window:show(Window.transitionFadeIn)
end

function _getBrightness(self)
	-- store existing brightness levels in self
	return appletManager:callService("getBrightness")
end

function _setBrightness(self, brightness)
	appletManager:callService("setBrightness", brightness)
end

--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

