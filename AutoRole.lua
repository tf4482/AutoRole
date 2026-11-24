-- AutoRole: sets the player's group role on joining a group or switching spec, per dual spec

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

-- format of the per-character data, for migration
local CHAR_VERSION = 1

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
    ns.Debug("not in a group, role unchanged")
    return
  end
  local spec = ActiveSpec()
  local role = ns.Get("spec" .. spec)
  -- unknown spec index or bad saved value: leave the role alone
  if not LABELS[role] or role == "NONE" or UnitGroupRolesAssigned("player") == role then
    ns.Debug("spec " .. spec .. ": role " .. tostring(role) .. " not applied")
    return
  end
  UnitSetRole("player", role)
  ns.Print("role set to " .. ns.Color("value", LABELS[role]) .. " (spec " .. spec .. ")")
end

-- one status line per spec, with hints
local function Status()
  local active, learned = ActiveSpec(), NumSpecs()
  for spec = 1, 2 do
    local role = ns.Get("spec" .. spec)
    local hint = ""
    if spec > learned then
      hint = ns.Color("warning", " (dual spec not learned)")
    elseif spec == active then
      hint = ns.Color("success", " (active)")
    end
    ns.Status("spec " .. spec, (LABELS[role] or tostring(role)) .. hint)
  end
  if not IsInGroup() then
    ns.Detail(ns.Color("muted", "not in a group: the role is set on the next join"))
  end
  ns.Status("per character", ns.OnOff(ns.char.perCharacter))
end

-- set the role now, or right after combat
local function Refresh()
  ns.AfterCombat(Apply)
end

-- switch per-character settings and report the new state
local function PerCharacter(enabled)
  ns.Set("perCharacter", enabled)
  Status()
end

-- set the role of the active spec once now, for checking it in game
local function Test()
  ns.Print("test: role of spec " .. ActiveSpec())
  if not IsInGroup() then
    ns.Warn("not in a group: role unchanged")
  elseif InCombatLockdown() then
    ns.Warn("in combat: role set after combat")
  end
  Refresh()
end

-- event handlers by event name
local events = {}

-- joined a group: set the role
function events.GROUP_JOINED()
  ns.Debug("GROUP_JOINED fired")
  Refresh()
end

-- switched spec: set the role of the new spec (Apply skips when not grouped)
function events.ACTIVE_TALENT_GROUP_CHANGED()
  ns.Debug("ACTIVE_TALENT_GROUP_CHANGED fired")
  Refresh()
end

-- one frame dispatching all events above
local frame = CreateFrame("Frame")
for event in pairs(events) do
  -- skip events this client does not know; pcall when it cannot tell
  if not (C_EventUtils and C_EventUtils.IsEventValid) then
    pcall(frame.RegisterEvent, frame, event)
  elseif C_EventUtils.IsEventValid(event) then
    frame:RegisterEvent(event)
  end
end
frame:SetScript("OnEvent", function(_, event, ...)
  events[event](...)
end)

-- spec roles are per character by nature; one-time copy of the roles 0.1.x kept in the
-- per-character AutoRoleDB; _version 0 marks unmigrated data
ns.Store("AutoRoleCharDB", { _version = 0, spec1 = "NONE", spec2 = "NONE" }, function(char)
  if char._version > CHAR_VERSION then
    ns.Warn("saved data is newer than this version; update AutoRole")
  elseif char._version < CHAR_VERSION then
    for spec = 1, 2 do
      local old = ns.db["spec" .. spec]
      if LABELS[old] then
        char["spec" .. spec] = old
      end
    end
    char._version = CHAR_VERSION
  end
end, "char")

-- saved state; settings page once loaded
ns.Store("AutoRoleDB", {}, function()
  ns.Settings()
  ns.Dropdown("spec1", "Role for spec 1", ROLES,
    "Role set on joining a group while spec 1 is active; your only spec without dual spec", Refresh)
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
ns.Command({
  name = "character",
  help = "use settings for this character only, or the account's",
  args = { { name = "state", choices = { "on", "off" } } },
  run = function(args) PerCharacter(args.state == "on") end,
})
ns.Command({ name = "test", help = "set the role of the active spec once now", run = Test })
ns.Command({
  name = "reset",
  help = "reset the active profile's settings to defaults",
  run = function()
    ns.ResetSettings()
    ns.Success("settings reset to defaults")
    Status()
  end,
})
ns.Command({
  name = "debug",
  help = "show what the addon does in chat, until /reload",
  args = { { name = "state", choices = { "on", "off" } } },
  run = function(args)
    ns.debug = args.state == "on"
    ns.Status("debug", ns.OnOff(ns.debug))
  end,
})
ns.Command({ name = "config", help = "open the settings page", run = ns.OpenSettings })
ns.Slash({ "/autorole", "/ar" }, Status)
