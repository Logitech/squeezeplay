
--[[
=head1 NAME

applets.SetupSoundEffects.SetupSoundEffectsMeta - SetupSoundEffects meta-info

=head1 DESCRIPTION

See L<applets.SetupSoundEffects.SetupSoundEffectsApplet>.

=head1 FUNCTIONS

See L<jive.AppletMeta> for a description of standard applet meta functions.

=cut
--]]

local pairs = pairs

local oo            = require("loop.simple")

local AppletMeta    = require("jive.AppletMeta")
local Framework     = require("jive.ui.Framework")
local Sample        = require("squeezeplay.sample")

local appletManager = appletManager
local jiveMain      = jiveMain

module(...)
oo.class(_M, AppletMeta)


function jiveVersion(meta)
	return 1, 1
end


function defaultSettings(meta)
	-- Don't modify this default effects volume, instead add a per
	-- platform attenuation in the Squeezebox<Platform>Meta files.
	return {
		_VOLUME = (Sample.MAXVOLUME / 4) * 3
	}
end

function registerApplet(meta)

	-- set volume
	local settings = meta:getSettings()
	Sample:setEffectVolume(settings["_VOLUME"])

	-- load sounds
	meta:registerService("loadSounds")

	-- add a menu to load us
	jiveMain:addItem(meta:menuItem('appletSetupSoundEffects', 'settingsAudio', "SOUND_EFFECTS", function(applet, ...) applet:settingsShow(...) end))

	-- The startup sound needs to be played with the minimum
	-- delay, load and play it first
	appletManager:callService("loadSounds", "STARTUP")
	Framework:playSound("STARTUP")

	-- Load all other sounds
	appletManager:callService("loadSounds", nil) -- nil is default from settingsend
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

