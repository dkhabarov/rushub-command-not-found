-- ***************************************************************************
-- command-not-found - This is a script for RusHub for handle unknown commands 
-- in main chat.
-- Copyright (c) 2014 Denis 'Saymon21' Khabarov (saymon@hub21.ru)

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License version 3
-- as published by the Free Software Foundation.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- ***************************************************************************
-- Configuration
def_config = {
	allow_prefix= {["!"] = true, ["+"] = true},
	report_profiles = {0},
	max_commands = 10,
}
-- ***************************************************************************
_TRACEBACK = debug.traceback 
cmds_regex = {}
commands = {}

function cmds_regexp_builder()
	--[[ 
	Example, for command test. 
	["test"] = {
		[1] = "[a-z]?est",
		[2] = "t[a-z]?st",
		[3] = "te[a-z]?t",
		[4] = "tes[a-z]?",
	},
	For get more information about regexp's, see http://mydc.ru/topic266.html
	]]
	local _, err_msg = pcall(dofile,"scripts/commandlist.t")
	if err_msg then
		error('Unable to load file \'commandlist.lua\': '..err_msg)
	end
	for command in pairs(commands) do
		if commands[command].enable then
			local str = tostring(command)
			local len = #str
			cmds_regex[str] = {}
			for char_count = 1, len do
				cmds_regex[str][char_count] = (char_count > 1 and str:sub(1, char_count - 1) or "").."[a-z]?"..(char_count < len and str:sub(char_count + 1, -1) or "")
			end
		end
	end
end

function OnStartup()
	lang = dofile(Config.sLangPath.."scripts/"..Config.sLang.."/command-not-found.lang")
	cmds_regexp_builder()
end

function get_cmd_description(cmd)
	if cmd and commands[cmd] then
		local len = #commands[cmd].description
		if len and len > 0 then
			return '('..commands[cmd].description..')'
		end
	end
end

function check_acl(UID, cmd)
	if cmd then
		local uprofile=UID.iProfile
		if commands[cmd] and commands[cmd].profiles and commands[cmd].profiles[uprofile] then
			return true
		end
	end
end

function OnChat(UID,sData)
	local this_prefix,this_command = sData:match("^%b<>%s(%p)([a-zA-Z].*)$")
	if this_prefix and def_config.allow_prefix[this_prefix] and this_command then
		this_command = this_command:lower()	
		local mbuse, append, append_cnt = "", {}, 0
		for usecmd,regex in pairs(cmds_regex) do
			for _, s_regex in pairs(regex) do
				if string.find(this_command,s_regex) then
					if not append[usecmd] then
						if check_acl(UID, usecmd) then
							if append_cnt <= def_config.max_commands then
								append[usecmd] = true
								append_cnt = append_cnt + 1
								mbuse = mbuse .."!"..usecmd.." "..(get_cmd_description(usecmd) or "").."\r\n"
							end
						end
					end
				end
			end
		end
		append, append_cnt = nil, 0
		if #mbuse > 0 then
			Core.SendToUser(UID, lang[1]:format(this_prefix..this_command,mbuse), Config.sHubBot)
			if def_config['report_profiles'] then
				report(lang[3]:format(UID.sNick, UID.sIP, UID.iProfile, this_prefix..this_command))
			end
		else
			Core.SendToUser(UID, lang[2]:format(this_prefix..this_command),Config.sHubBot)
			if def_config['report_profiles'] then
				report(lang[3]:format(UID.sNick, UID.sIP, UID.iProfile, this_prefix..this_command))
			end
		end
		return 1
	end
end

function report(msg)
	Core.SendToProfile(def_config.report_profiles, msg, Config.sHubBot, Config.sHubBot)
end

function OnError(s)
	Core.SendToProfile(0, s, Config.sHubBot)
end