local _, FC = ...
function FC:ClassicCharacterName(unit)
    local name, realm = (UnitFullName or UnitName)(unit)
    if type(name) ~= "string" or name == "" then return end
    realm = realm or (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName()
    if type(realm) ~= "string" or realm == "" then return name end
    return name .. "-" .. realm:gsub("%s+", "")
end
