local p = premake

if not p.modules.wingc then

	include ( "_preload.lua" )

	require ("vstudio")
	p.modules.wingc = {}

	include("wingc_vcxproj.lua")	
end

return p.modules.wingc
