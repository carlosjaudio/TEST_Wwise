--[[----------------------------------------------------------------------------
The content of this file includes portions of the AUDIOKINETIC Wwise Technology
released in source code form as part of the SDK installer package.

Commercial License Usage

Licensees holding valid commercial licenses to the AUDIOKINETIC Wwise Technology
may use this file in accordance with the end user license agreement provided
with the software or, alternatively, in accordance with the terms contained in a
written agreement between you and Audiokinetic Inc.

  Copyright (c) 2023 Audiokinetic Inc.
------------------------------------------------------------------------------]]


if not AK then AK = {} end
if not AK.Platforms then AK.Platforms = {} end

require "wingc/wingc"

AK.Platforms.WinGC =
{
	name = "WinGC",
	directories = {
		src = {
			__default__ = "WinGC",
			AkMemoryMgr = "Win32",
			AkMusicEngine = "Win32",
			GameSimulator = "Win32",
			AkSink = "Win32",
			AkVorbisDecoder = "Win32",
			AkSoundEngineDLL = "Win32",
			AkStreamMgr = "Win32",
			IntegrationDemo = "Windows",
		},
		simd = "SIMD",
		project = "WinGC",
		lualib = "Win32",
		lowlevelio = "Win32",
		luasln = "GameSimulator/source/",
	},
	kinds = {
		GameSimulator = "ConsoleApp",
		IntegrationDemo = "WindowedApp"
	},
	suffix = {
		__default__ = "WinGC",
		IntegrationDemoSln = "",
		IntegrationDemo = ""
	},

	platforms = {"Gaming.Desktop.x64" },
	features = { "Motion", "iZotope", "IntegrationDemo" },
	configurations =
	{
		"Debug",
		"Debug_NoIteratorDebugging",
		"Profile",
		"Profile_EnableAsserts",
		"Release",
	},
	avx2archs = { "Gaming.Desktop.x64" },
	avxarchs = { "Gaming.Desktop.x64" },
	validActions = {"vs2017", "vs2019", "vs2022" },
	
	AdditionalSoundEngineProjects = function()
		return {}
	end,
	AddActionSuffixToDllProjects = true,

	-- API
	---------------------------------
	ImportAdditionalWwiseSDKProjects = function()
		local actionsuffix = GetSuffixFromCurrentAction()
		local shortactionsuffix = string.sub(actionsuffix, -3)
		--importproject("SampleFramework" .. shortactionsuffix)
		--importproject("DirectXTex")
	end,

	-- Project factory. Creates "StaticLib" target by default. Static libs (only) are added to the global list of targets.
	-- Other target types supported by premake are "WindowedApp", "ConsoleApp" and "SharedLib".
	-- Upon returning from this method, the current scope is the newly created project.
	CreateProject = function(in_fileName, in_targetName, in_projectLocation, in_suffix, pathPCH, in_targetType)
		verbosef("        Creating project: %s", in_targetName)

		-- Make sure that directory exist
		os.mkdir(AkMakeAbsolute(in_projectLocation))

		-- Create project
		local prj = project(in_targetName)			
			platforms {"Gaming.Desktop.x64"}
			
			system(premake.WinGC)

			location(AkRelativeToCwd(in_projectLocation))
			targetname(in_targetName)
			--targetlayoutdir("$(OutDir)..\\Layout")
			syslibdirs { "$(Console_SdkLibPath)" }
			sysincludedirs { "$(Console_SdkIncludeRoot)" }
			--bindirs { "$(Console_SdkRoot)bin;$(VCInstallDir)bin\\x86_amd64;$(VCInstallDir)bin;$(WindowsSDK_ExecutablePath_x86);$(VSInstallDir)Common7\\Tools\\bin;$(VSInstallDir)Common7\\tools;$(VSInstallDir)Common7\\ide;$(MSBuildToolsPath32);$(FxCopDir);$(PATH);" 	}
						
			if in_targetType == nil or in_targetType == "StaticLib" then
				kind("StaticLib")
				targetprefix("")
				targetextension(".lib")
				-- Add to global table
				_AK_TARGETS[in_targetName] = in_fileName
			else
				kind(in_targetType)
				targetprefix("")
				targetextension(".dll")
				libdirs{"$(OutDir)../lib",}				
				--links{"combase", "kernelx", "uuid"}
			end
			language("C++")
			uuid(GenerateUuid(in_fileName))
			filename(in_fileName)
			symbols "on"
			symbolspath "$(OutDir)$(TargetName).pdb"
			flags {
				-- Treat all warnings as errors
				"FatalWarnings",
				-- We never want .user files, we always want .filters files.
				"OmitUserFiles",
				"ForceFiltersFiles",
				-- Enable multiprocess compilation wherever possible
				"MultiProcessorCompile",
			}

			-- Common flags.
			linksparent "Always"
						
			characterset "Unicode"
			buildoptions { "/utf-8" }
			-- Precompiled headers.			
			if pathPCH ~= nil then
				files
				{
					AkRelativeToCwd(pathPCH) .. "stdafx.cpp",
					AkRelativeToCwd(pathPCH) .. "stdafx.h",
				}				
				pchheader "stdafx.h"
				pchsource ( AkRelativeToCwd(pathPCH) .. "stdafx.cpp" )
			end
			
			defines {  "WINAPI_FAMILY=WINAPI_FAMILY_GAMES","_CRT_SECURE_NO_WARNINGS", "__WRL_NO_DEFAULT_LIB__" }

			-- Standard configuration settings.
			filter "*Debug*"
				defines "_DEBUG"

			filter "Profile*"
				defines "NDEBUG"
				optimize "Speed"

			filter "*Release*"
				defines "NDEBUG"
				optimize "Speed"
			filter {}

			-- For customer convenience, targeted Windows SDK depends on what is available in the Visual Studio installer
			filter "action:vs2019"
				systemversion "10.0.20348.0" -- Max version available in VS 2019 installer

			filter "action:vs2022"
				systemversion "10.0.22621.0"

			filter {}

			if not _AK_BUILD_AUTHORING then
				filter "Release*"
					defines ("AK_OPTIMIZED")
			end

			filter "Debug_NoIteratorDebugging"
				defines "_HAS_ITERATOR_DEBUGGING=0"

			filter "*EnableAsserts"
				defines "AK_ENABLE_ASSERTS"

			-- Style sheets.
			local ssext = ".props"
			if in_targetType == nil or in_targetType == "StaticLib" then
				filter "*Debug*"
					vs_propsheet(AkRelativeToCwd(_AK_ROOT_DIR) .. "PropertySheets/Win32/Debug" .. in_suffix .. ssext)
				filter "Profile* or *Release*"
					vs_propsheet(AkRelativeToCwd(_AK_ROOT_DIR) .. "PropertySheets/Win32/NDebug" .. in_suffix .. ssext)
				DisablePropSheetElements()
			end
			filter {}
				removeelements {
					"TargetExt"
				}
	
				-- disable editAndContinue due to incremental link being disabled
			filter {}
				editandcontinue "Off"

			-- Set the scope back to current project
			project(in_targetName)

		ApplyPlatformExceptions(prj.name, prj)

		return prj
	end,

	-- Plugin factory.
	-- Upon returning from this method, the current scope is the newly created plugin project.
	CreatePlugin = function(in_fileName, in_targetName, in_projectLocation, in_suffix, pathPCH, in_targetType)
		local prj = AK.Platforms.WinGC.CreateProject(in_fileName, in_targetName, in_projectLocation, in_suffix, pathPCH, in_targetType)
		return prj
	end,

	Exceptions = {
		AkMemoryMgr = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs { 				
				prjLoc .. "/../../AkAudiolib/Win32",
			}
		end,		
		AkSoundEngine = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			if not _AK_BUILD_AUTHORING then
				filter { "files:" .. prjLoc .. "/../../SoundEngineProxy/**.cpp", "Release*" }
					flags { "ExcludeFromBuild" }
				filter {}
			end
			filter "Debug*"
				links "DbgHelp"
			filter "Profile*"
				links "DbgHelp"
			filter {}
			
			includedirs {
				prjLoc .. "/../Win32"
			}
			files {
				prjLoc .. "/../Win32/*.cpp",
				prjLoc .. "/../*.h",					
			}
		end,
		AkSoundEngineDLL = function(prj)
			links {"MMDevApi", "d3d11_x", "dxguid", "ws2_32", "xaudio2"}
		end,
		AkOpusDecoder = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs { 	
				prjLoc .. "/../../../AkAudiolib/Win32",
			}
		end,
		AkMotionSink = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			filter "*"
				optimize "Full"
			filter {}
			includedirs {
				prjLoc .. "/../Win32",
				-- folder for PS5 SDK 8.00+
				"%SCE_ROOT_DIR%/Common/External Tools/libScePad for PC Games(DualSense and DUALSHOCK4)/PadForPCGames/include/",
				-- folder for PS5 SDK 8.00- (remove when no longer needed)
				"%SCE_ROOT_DIR%/Common/External Tools/libScePad for PC Games(DualSense and DUALSHOCK4)/include/",
			}
			files {
				prjLoc .. "/../Win32/*.h",
				prjLoc .. "/../Win32/*.cpp",
			}
			g_PluginDLL["AkMotion"].extralibs = {
				"dinput8"
			}
		end,
		AkSink = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs {
				prjLoc .. "/../../../../AkAudiolib/Win32"
			}
		end,
		AkSpatialAudio = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs { 
				prjLoc .. "/../Win32",
				prjLoc .. "/../../SoundEngine/AkAudiolib/Win32",
			}
			files {
				prjLoc .. "/../Win32/*.cpp",
				prjLoc .. "/../Win32/*.h",
			}
		end,
		AkStreamMgr = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)			
			includedirs {
				prjLoc .. "/../WinGC",
				prjLoc .. "/../Win32",
			}
			files {
				prjLoc .. "/../WinGC/*.cpp",
				prjLoc .. "/../WinGC/*.h",
			}
		end,
		AkVorbisDecoder = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs { 
				prjLoc .. "/../../../AkAudiolib/Win32" 
			}
		end,
		CommunicationCentral = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs { 
				prjLoc .. "/../Win32",
				prjLoc .. "/../../../AkAudiolib/Win32",
			}
			files {
				prjLoc .. "/../PC/*.cpp",
				prjLoc .. "/../PC/*.h",
			}

		end,
		PluginFactory = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			includedirs {
				prjLoc .. "/../../../../AkAudiolib/Win32",
			}
		end,
		iZTrashBoxModelerFX = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			files {
				prjLoc .. "/../../../../iZBaseConsole/src/iZBase/Util/CriticalSection.*",
			}
		end,
		LuaLib = function (prj)
			defines{"WIN64"}
		end,
		GameSimulator = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			local integrationDemoLocation = prjLoc .. "/../../../../SDK/samples/IntegrationDemo"
			local autoGenLoc = '%{cfg.objdir}/AutoGen/'
			
			includedirs {
				integrationDemoLocation .. "/Windows",
				autoGenLoc,
			}
			
			files {				
				prjLoc .. "/*.png",
				prjLoc .. "/*.cpp",
				prjLoc .. "/*.h",
				prjLoc .. "/../../src/libraries/Win32/*.cpp",
				prjLoc .. "/Package.appxmanifest",
				prjLoc .. "../../GameSimulatorPC/platform.cpp",
				integrationDemoLocation .. "/Windows/InputMgr.*",
				integrationDemoLocation .. "/MenuSystem/UniversalInput.*",
				integrationDemoLocation .. "/Common/Helpers.cpp",
				integrationDemoLocation .. "/../SoundEngine/Win32/AkPlatformProfilerHooks.cpp",
			}

			links {
				"iZHybridReverbFX",
				"iZTrashBoxModelerFX",
				"iZTrashDelayFX",
				"iZTrashDistortionFX",
				"iZTrashDynamicsFX",
				"iZTrashFiltersFX", 
				"iZTrashMultibandDistortionFX",
				"LuaLib",
				"ToLuaLib",
				"dinput8",
				"ws2_32",
				"d3d12",
				"dxguid",
			}

			-- For feature selection until we support Motion and microphone input
			defines { "AK_WINGC" }

			vs_propsheet(prjLoc .. "/../../../../SDK/samples/IntegrationDemo/WinGC/Samples.props")
			
			linksparent "Always"
			
			flags {
				"NoEmbedManifest",
				"NoGenerateManifest",
			}
			
			local suffix = GetSuffixFromCurrentAction()

			filter "Debug*"
				libdirs {prjLoc .. "/../../../../SDK/WinGC" .. suffix .. "/Debug/lib"}
			filter "Profile*"
				libdirs {prjLoc .. "/../../../../SDK/WinGC" .. suffix .. "/Profile/lib"}
			filter "Release*"
				libdirs {prjLoc .. "/../../../../SDK/WinGC" .. suffix .. "/Release/lib"}
			filter {}
		end,
		IntegrationDemo = function(prj)
			local prjLoc = AkRelativeToCwd(prj.location)
			local autoGenLoc = '%{cfg.objdir}/AutoGen/'

			includedirs {
				prjLoc .. "/../../../samples/SoundEngine/Win32",
				prjLoc .. "/../Windows/",
				autoGenLoc,
				-- folder for PS5 SDK 8.00+
				"%SCE_ROOT_DIR%/Common/External Tools/libScePad for PC Games(DualSense and DUALSHOCK4)/PadForPCGames/include/",
				-- folder for PS5 SDK 8.00- (remove when no longer needed)
				"%SCE_ROOT_DIR%/Common/External Tools/libScePad for PC Games(DualSense and DUALSHOCK4)/include/",
			}
			files {
				prjLoc .. "/../../SoundEngine/Common/AkDefaultLowLevelIODispatcher.*",
				prjLoc .. "/../../SoundEngine/Common/AkFilePackageLowLevelIO.*",
				prjLoc .. "/../../SoundEngine/Win32/AkDefaultIOHookBlocking.*",
				prjLoc .. "/../../SoundEngine/Win32/AkFileHelpers.h",
				prjLoc .. "/../Windows/*.h",
				prjLoc .. "/../Windows/*.cpp",
				prjLoc .. "/../Windows/D3D12/*",
				prjLoc .. "/Package.appxmanifest",
			}
			
			links {
				"ws2_32",
				"dinput8",
				"d3d12",
				"dxgi",
				"dxguid",
			}
			
			-- For feature selection until we support Motion and microphone input
			defines { "AK_WINGC" }

			defines { "INTDEMO_RENDER_D3D12" }

			filter "Debug*"
				links "CommunicationCentral"
			filter "Profile*"
				links "CommunicationCentral"
			filter {}
			
			flags {
				"NoEmbedManifest",
				"NoGenerateManifest",
			}
			linksparent "Always"

			vs_propsheet(prjLoc .. "/Samples.props")

			-- Custom build step to compile HLSL into header files
			files { prjLoc .. "/../Windows/Shaders/*.hlsl" }
			shaderobjectfileoutput ""
			shadermodel "6.0"
			
			filter 'files:**.hlsl'
				flags "ExcludeFromBuild"
			filter 'files:**Vs.hlsl'
				removeflags "ExcludeFromBuild"
				shadertype "Vertex"
				shaderentry "VsMain"
				shaderheaderfileoutput ("" .. autoGenLoc .. "%{file.basename}.h")
			filter 'files:**Ps.hlsl'
				removeflags "ExcludeFromBuild"
				shadertype "Pixel"
				shaderentry "PsMain"
				shaderheaderfileoutput ("" .. autoGenLoc .. "%{file.basename}.h")
			filter{}	
			prebuildcommands("if not exist \"" .. autoGenLoc .. "\" mkdir \"" .. autoGenLoc .. "\"")

			local actionsuffix = GetSuffixFromCurrentAction()

			libdirs {
				prjLoc .. "/../../../WinGC" .. actionsuffix .. "/$(Configuration)/lib",
				-- folder for PS5 SDK 8.00+
				"%SCE_ROOT_DIR%/Common/External Tools/libScePad for PC Games(DualSense and DUALSHOCK4)/PadForPCGames/lib/",
				-- folder for PS5 SDK 8.00- (remove when no longer needed)
				"%SCE_ROOT_DIR%/Common/External Tools/libScePad for PC Games(DualSense and DUALSHOCK4)/lib/",
			}
			
			local shortactionsuffix = string.sub(actionsuffix, -3)
			local baselocation = AkRelativeToCwd(_AK_ROOT_DIR .. "../../samples/IntegrationDemo/WinGC/")		
				
			project(prj.name)		
		end,
	},

	Exclusions = {
		AkMemoryMgr = function(prjLoc)
			excludes { 
				prjLoc .. "/../Win32/stdafx.*",
			}
		end,
		AkSpatialAudio = function(prjLoc)
			excludes { 
				prjLoc .. "/../Win32/stdafx.*",
			}
		end,
		AkStreamMgr = function(prjLoc)
			excludes { 
				prjLoc .. "/../Win32/stdafx.*",
			}
		end,
		CommunicationCentral = function(prjLoc)
			excludes { 
				prjLoc .. "/../PC/stdafx.*",
			}
		end,	
		GameSimulator = function(prjLoc)
			excludes {
				prjLoc .. "/../../src/libraries/Common/UniversalScrollBuffer.*"
			}
		end,		
		IntegrationDemo = function(prjLoc)
			excludes {
				prjLoc .. "/../DemoPages/DemoMicrophone.*",
				prjLoc .. "/../Common/SoundInputMgrBase.*",				
				prjLoc .. "/../Windows/SoundInput.*",
				prjLoc .. "/../Windows/SoundInputMgr.*",
				prjLoc .. "/../Windows/stdafx.*",
			}
		end
	}
}
return AK.Platforms.WinGC
