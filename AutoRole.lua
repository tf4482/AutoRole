-- AutoRole: sets the player's group role on joining a group, per dual spec

local _, ns = ...

-- role values as the game uses them, with labels
local ROLES = {
  { "NONE", "Do not change" },
  { "TANK", "Tank" },
  { "HEALER", "Healer" },
  { "DAMAGER", "Damage" },
}

-- role label by value
local LABELS = {}
for _, role in ipairs(ROLES) do
  LABELS[role[1]] = role[2]
end

-- dual spec API differs between game versions
local GetNumGroups = GetNumSpecGroups or GetNumTalentGroups
local GetActiveGroup = GetActiveSpecGroup or GetActiveTalentGroup

-- number of learned specs (2 with dual spec)
local function NumSpecs()
  return GetNumGroups and GetNumGroups() or 1
end

-- index of the active spec
local function ActiveSpec()
  return GetActiveGroup and GetActiveGroup() or 1
end

-- set the configured role of the active spec; only called out of combat
local function Apply()
  if not IsInGroup() then
    return
  end
  local spec = ActiveSpec()
  local role = ns.db["spec" .. spec]
  if role == "NONE" or UnitGroupRolesAssigned("player") == role then
    return
  end
  UnitSetRole("player", role)
  ns.Print("role set to " .. ns.Color("value", LABELS[role]) .. " (spec " .. spec .. ")")
end

-- one status line per spec, with hints
local function Status()
  local active, learned = ActiveSpec(), NumSpecs()
  for spec = 1, 2 do
    local hint = ""
    if spec > learned then
      hint = ns.Color("warning", " (dual spec not learned)")
    elseif spec == active then
      hint = ns.Color("success", " (active)")
    end
    ns.Status("spec " .. spec, LABELS[ns.db["spec" .. spec]] .. hint)
  end
end

-- set the role now, or right after combat
local function Refresh()
  ns.AfterCombat(Apply)
end

-- event handlers by event name
local events = {}

-- joined a group: set the role
events.GROUP_JOINED = Refresh

-- one frame dispatching all events above
local frame = CreateFrame("Frame")
for event in pairs(events) do
  frame:RegisterEvent(event)
end
frame:SetScript("OnEvent", function(_, event, ...)
  events[event](...)
end)

-- saved state per character; settings page once loaded
ns.Store("AutoRoleDB", { spec1 = "NONE", spec2 = "NONE" }, function()
  ns.Settings()
  ns.Dropdown("spec1", "Role for spec 1", ROLES, "Role set on joining a group while spec 1 is active; your only spec without dual spec", Refresh)
  ns.Dropdown("spec2", "Role for spec 2", ROLES,
    "Role set on joining a group while spec 2 is active; needs dual spec", Refresh)
end)

-- chat command per spec: set its role and report it
for spec = 1, 2 do
  ns.Command({
    name = "spec" .. spec,
    help = "set the role for spec " .. spec,
    args = { { name = "role", choices = { "none", "tank", "healer", "damager" } } },
    run = function(args)
      ns.Set("spec" .. spec, args.role:upper())
      Status()
    end,
  })
end
ns.Command({ name = "config", help = "open the settings page", run = ns.OpenSettings })
ns.Slash({ "/autorole", "/ar" }, Status)
