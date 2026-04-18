--[[
	© CloudSixteen.com do not share, re-distribute or modify
	without permission of its author (kurozael@gmail.com).

	Clockwork was created by Conna Wiles (also known as kurozael.)
	http://cloudsixteen.com/license/clockwork.html
--]]

local startTime = os.clock();

if (Clockwork and Clockwork.kernel) then
	MsgC(Color(0, 255, 100, 255), "[Clockwork] Change has been detected! Auto-refreshing...\n");
else
	MsgC(Color(0, 255, 100, 255), "[Clockwork] The framework is initializing...\n");
end;

local caxVersion = file.Read("cax.txt", "DATA");
local requireName = "cloudauthx";

if (caxVersion != "" and tonumber(caxVersion)) then
	local fileName = caxVersion;
 
	if (system.IsLinux()) then
		fileName = "gmsv_cloudauthx_"..fileName.."_linux.dll";
	else
		fileName = "gmsv_cloudauthx_"..fileName.."_win32.dll";
	end;
 
	if (file.Exists("lua/bin/"..fileName, "GAME")) then
		requireName = "cloudauthx_"..caxVersion;
	end;
end;

local cloudAuthLoaded = pcall(require, requireName);

if (!cloudAuthLoaded) then
	MsgC(Color(255, 170, 0, 255), "[Clockwork] CloudAuthX binary was not found. Some framework features may be unavailable.\n");

	CloudAuthX = CloudAuthX or {};
	CloudAuthX.kernel = CloudAuthX.kernel or {};

	CloudAuthX.GetVersion = CloudAuthX.GetVersion or function()
		return 0;
	end;

	CloudAuthX.Authenticate = CloudAuthX.Authenticate or function() end;
	CloudAuthX.Initialize = CloudAuthX.Initialize or function() end;
	CloudAuthX.External = CloudAuthX.External or function() end;

	CloudAuthX.Base64Encode = CloudAuthX.Base64Encode or function(value)
		return value;
	end;

	CloudAuthX.Base64Decode = CloudAuthX.Base64Decode or function(value)
		return value;
	end;
end;

local mysqlLoaded = false;

if (system.IsLinux()) then
	mysqlLoaded = pcall(require, "mysqloo");
else
	mysqlLoaded = pcall(require, "tmysql4");
end;

if (!mysqlLoaded) then
	MsgC(Color(255, 170, 0, 255), "[Clockwork] MySQL module was not found. Falling back to SQLite mode.\n");
end;

AddCSLuaFile("external/utf8.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("external/von.lua");

--[[ Include Vercas's serialization library and the Clockwork kernel. --]]
include("external/utf8.lua");
include("external/von.lua");
include("clockwork/framework/sv_kernel.lua");

if (Clockwork and cwBootComplete) then
	MsgC(Color(0, 255, 100, 255), "[Clockwork] Auto-refresh handled server-side in "..math.Round(os.clock() - startTime, 3).. " second(s)!\n");
else
	local version = Clockwork.kernel:GetVersionBuild();
	
	MsgC(Color(0, 255, 100, 255), "[Clockwork] Successfully loaded Clockwork version "..version.." in "..math.Round(os.clock() - startTime, 3).. " second(s).\n");
end;

cwBootComplete = true;
