
--[[
=head1 NAME

applets.ScreenSavers.ScreenSaversApplet - Screensaver manager.

=head1 DESCRIPTION

This applets hooks itself into Jive to provide a screensaver
service, complete with settings.

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. 
ScreenSaversApplet overrides the following methods:

=cut
--]]


-- stuff we use
local ipairs, pairs, tostring = ipairs, pairs, tostring

local oo               = require("loop.simple")

local Applet           = require("jive.Applet")
local AppletManager    = require("jive.AppletManager")
local Timer            = require("jive.ui.Timer")
local Framework        = require("jive.ui.Framework")
local Window           = require("jive.ui.Window")
local RadioGroup       = require("jive.ui.RadioGroup")
local RadioButton      = require("jive.ui.RadioButton")
local Label            = require("jive.ui.Label")
local SimpleMenu       = require("jive.ui.SimpleMenu")
local Textarea         = require("jive.ui.Textarea")
local table            = require("jive.utils.table")

local log              = require("jive.utils.log").logger("applets.screensavers")

local appletManager    = appletManager
local EVENT_KEY_PRESS  = jive.ui.EVENT_KEY_PRESS
local EVENT_SCROLL     = jive.ui.EVENT_SCROLL
local EVENT_CONSUME    = jive.ui.EVENT_CONSUME
local EVENT_ACTION     = jive.ui.EVENT_ACTION
local EVENT_WINDOW_POP = jive.ui.EVENT_WINDOW_POP
local KEY_PLAY         = jive.ui.KEY_PLAY


module(...)
oo.class(_M, Applet)


function init(self, ...)

	self.screensavers = {}
	self.screensaverSettings = {}
	self:addScreenSaver("None", nil, nil)

	local timeout = self:getSettings()["timeout"]
	self.timer = Timer(timeout, function() self:_activate() end, true)
	self.timer:start()

	Framework:addListener(
		EVENT_KEY_PRESS | EVENT_SCROLL,
		function()
			self:_event()
		end
	)

	return self
end


--[[

=head2 applets.ScreenSavers.ScreenSaversApplet:free()

Overridden to return always false, this ensure the applet is
permanently loaded.

=cut
--]]
function free(self)
	-- ScreenSavers cannot be freed
	return false
end


--_event()
--Restart the screensaver timer on a key press or scroll event. Any active screensaver
--will be closed.
function _event(self)
	if self.active then
		self.active:hide()
		self.active = nil
	end

	self.timer:restart()
end


--_activate(the_screensaver)
--Activates the screensaver C<the_screensaver>. If <the_screensaver> is nil then the
--screensaver set for the current mode is activated.
function _activate(self, the_screensaver)
	log:debug("Screensaver activate")

	if the_screensaver == nil then
		local sd = AppletManager:getAppletInstance("SlimDiscovery")
		
		if sd and sd:getCurrentPlayer():getPlayMode() == "play" then
			the_screensaver = self:getSettings()["whenPlaying"]
		else
			the_screensaver = self:getSettings()["whenStopped"]
		end
	end

	local screensaver = self.screensavers[the_screensaver]
	if screensaver == nil or screensaver.applet == nil then
		-- no screensaver, do nothing
		return
	end

	-- activate the screensaver
	self.timer:stop()
	local instance = appletManager:loadApplet(screensaver.applet)
	self.active = instance[screensaver.method](instance)
end


function addScreenSaver(self, displayName, applet, method, settingsName, settings)
	local key = tostring(applet) .. ":" .. tostring(method)
	self.screensavers[key] = {
		applet = applet,
		method = method,
		displayName = displayName,
		settings = settings
	}

	if settings_name then
		self.screensaverSettings[settingsName] = self.screensavers[key]
	end
end


function setScreenSaver(self, mode, key)
	self:getSettings()[mode] = key
end


function setTimeout(self, timeout)
	self:getSettings()["timeout"] = timeout
	self.timer:setInterval(timeout)
end


function screensaverSetting(self, menuItem, mode)
	local menu = SimpleMenu("menu")
        menu:setComparator(menu.itemComparatorAlpha)

	local activeScreensaver = self:getSettings()[mode]

	local group = RadioGroup()
	for key, screensaver in pairs(self.screensavers) do
		local button = RadioButton(
			"radio", 
			group, 
			function()
				self:setScreenSaver(mode, key)
			end,
			key == activeScreensaver
		)

		-- pressing play should play the screensaver, so we need a handler
		button:addListener(EVENT_KEY_PRESS,
			function(evt)
				if evt:getKeycode() == KEY_PLAY then
					self:_activate(key)
					return EVENT_CONSUME
				end
			end
		)

		menu:addItem({
				     text = screensaver.displayName,
				     icon = button
			     })
	end

	local window = Window("screensavers", menuItem.text)
	window:addWidget(Textarea("help", "Press Center to select screensaver or PLAY to preview"))
	window:addWidget(menu)

	window:addListener(EVENT_WINDOW_POP, function() self:storeSettings() end)

	self:tieAndShowWindow(window)
	return window
end


function timeoutSetting(self, menuItem)
	local group = RadioGroup()

	local timeout = self:getSettings()["timeout"]
	
	local window = Window("window", menuItem.text)
	window:addWidget(SimpleMenu("menu",
		{
			{
				text = self:string('DELAY_10_SEC'),
				icon = RadioButton("radio", group, function() self:setTimeout(10000) end, timeout == 10000),
			},
			{
				text = self:string('DELAY_30_SEC'),
				icon = RadioButton("radio", group, function() self:setTimeout(30000) end, timeout == 30000),
			},
			{
				text = self:string('DELAY_1_MIN'),
				icon = RadioButton("radio", group, function() self:setTimeout(60000) end, timeout == 60000),
			},
			{ 
				text = self:string('DELAY_2_MIN'),
				icon = RadioButton("radio", group, function() self:setTimeout(120000) end, timeout == 120000),
			},
			{
				text = self:string('DELAY_5_MIN'),
				icon = RadioButton("radio", group, function() self:setTimeout(300000) end, timeout == 300000),
			},
			{ 
				text = self:string('DELAY_10_MIN'),
				icon = RadioButton("radio", group, function() self:setTimeout(600000) end, timeout == 600000),
			},
		}))

	window:addListener(EVENT_WINDOW_POP, function() self:storeSettings() end)

	self:tieAndShowWindow(window)
	return window
end


function openSettings(self, menuItem)

	local menu = SimpleMenu("menu",
		{
			{ 
				text = self:string('SCREENSAVER_PLAYING'),
				weight = 1,
				callback = function(event, menu_item)
						   self:screensaverSetting(menu_item, "whenPlaying")
					   end
			},
			{
				text = self:string("SCREENSAVER_STOPPED"),
				weight = 1,
				callback = function(event, menu_item)
						   self:screensaverSetting(menu_item, "whenStopped")
					   end
			},
			{
				text = self:string("SCREENSAVER_DELAY"),
				weight = 2,
				callback = function(event, menu_item)
						   self:timeoutSetting(menu_item)
					   end
			},
		})

	menu:setComparator(menu.itemComparatorWeightAlpha)
	for setting_name, screensaver in pairs(self.screensaverSettings) do
		menu:addItem({
				     text = setting_name,
				     weight = 3,
				     callback =
					     function(event, menuItem)
							local instance = appletManager:loadApplet(screensaver.applet)
							instance[screensaver.settings](instance, menuItem)
					     end
			     })
	end

	local window = Window("window", menuItem.text)
	window:addWidget(menu)

	-- Store the applet settings when the window is closed
	window:addListener(EVENT_WINDOW_POP,
		function()
			self:storeSettings()
		end
	)

	self:tieAndShowWindow(window)
	return window
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

