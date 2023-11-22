local p = premake
local api = p.api

p.wingc = "wingc"

api.addAllowed("system", p.wingc)
api.addAllowed("architecture", { "Gaming.Desktop.x64" })
api.addAllowed("flags",{ 
		"NoGenerateManifest",
		"NoEmbedManifest"
})

local osoption = p.option.get("os")
if osoption ~= nil then
	table.insert(osoption.allowed, { "wingc",  "Microsoft Gaming Desktop x64" })
end

-- add system tags for wingc
os.systemTags[p.wingc] = { "wingc" }

filter { "system:wingc", "kind:ConsoleApp or WindowedApp" }
	targetextension ".exe"
	
filter { "system:wingc", "kind:SharedLib" }
	targetprefix ""
	targetextension ".dll"
	implibextension ".lib"

filter { "system:wingc", "kind:StaticLib" }
	targetprefix ""
	targetextension ".lib"

api.register {
	name = "targetlayoutdir",
	scope = "config",
	kind = "string",
	tokens = true,
}

return function(cfg)
	return (cfg.system == p.wingc)
end
