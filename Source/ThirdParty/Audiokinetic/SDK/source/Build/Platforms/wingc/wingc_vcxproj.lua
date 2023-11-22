local p = premake

local wingc = p.modules.wingc
local vc200x = p.vstudio.vc200x
local vc2010 = p.vstudio.vc2010
local vstudio = p.vstudio
local project = p.project
local config = p.config

if vstudio.vs2010_architectures ~= nil then
	vstudio.vs2010_architectures.wingc = "Gaming.Desktop.x64"	
end

premake.override(vc2010.elements, "project", function(oldfn, prj)
	local elements = oldfn(prj)
	if prj.system == p.wingc then
		elements = table.join(elements, {
			wingc.wingcPaths,
			wingc.wingcAssemblies,
		})
	end
	return elements
end)

premake.override(vc2010.elements, "globals", function(oldfn, prj)
	local elements = oldfn(prj)
	if prj.system == p.wingc then
		elements = table.join(elements, {
			wingc.wingcGlobals,
		})
	end
	return elements
end)

premake.override(vc2010.elements, "configurationProperties", function(oldfn, cfg)
	local elements = oldfn(cfg)
	if cfg.kind ~= p.UTILITY and cfg.system == p.wingc then
		elements = table.join(elements, {
			wingc.noEmbedManifest,
			wingc.noGenerateManifest,
		})
	end
	return elements
end)

premake.override(vc2010, "outDir", function(oldfn, cfg)
	oldfn(cfg)
	if ( cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp" ) then
		if (cfg.targetlayoutdir ~= nil and cfg.targetlayoutdir ~= '') then
			vc2010.element(cfg, "LayoutDir", nil, "%s\\", premake.esc(cfg.targetlayoutdir))
		end
	end
end)

premake.override(vc2010, "keyword", function(oldfn, prj)
	if prj.system == p.wingc then
		vc2010.element(prj, "Keyword", nil, "Win32Proj")
		vc2010.element(prj, "RootNamespace", nil, "%s", prj.name)
	else
		oldfn(prj)
	end
end)

function wingc.wingcPaths(prj)
	for cfg in project.eachconfig(prj) do
		local prjcfg = vstudio.projectConfig(cfg, arch)
		local name = cfg.name
		--TODO
		p.push('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'%s\'">', premake.esc(name))
		p.w('<ReferencePath>$(Console_SdkLibPath);$(Console_SdkWindowsMetadataPath)</ReferencePath>')
		p.w('<LibraryWPath>$(Console_SdkLibPath);$(Console_SdkWindowsMetadataPath)</LibraryWPath>')
		p.pop('</PropertyGroup>')
	end
end

function wingc.wingcAssemblies(prj)
	local cfg = project.getfirstconfig(prj)
	if cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp" then
	--TODO		
	end
end

function wingc.wingcGlobals(prj)
	vc2010.element(prj, "ApplicationEnvironment", nil, "%s", "title")
	vc2010.element(prj, "PlatformToolset", nil, "%s", "v140")
	vc2010.element(prj, "MinimumVisualStudioVersion", nil, "%s", "14.0")
	vc2010.element(prj, "TargetRuntime", nil, "%s", "Native")
end

function wingc.noEmbedManifest(cfg)
	if cfg.flags.NoEmbedManifest then
		vc2010.element(cfg, "EmbedManifest", nil, 'false')
	end
end

function wingc.noGenerateManifest(cfg)
	if cfg.flags.NoGenerateManifest then
		vc2010.element(cfg, "GenerateManifest", nil, 'false')
	end
end
