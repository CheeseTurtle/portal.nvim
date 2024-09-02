---@type Portal.Settings
local Settings = {}

---@class Portal.Settings
local DEFAULT_SETTINGS = {
  ---@type "debug" | "info" | "warn" | "error"
  log_level = "warn",

  ---The base filter applied to every search.
  ---@type Portal.SearchPredicate | nil
  filter = nil,

  ---The maximum number of results for any search.
  ---@type integer | nil
  max_results = nil,

  ---The maximum number of items that can be searched.
  ---@type integer
  lookback = 100,

  ---An ordered list of keys for labelling portals.
  ---Labels will be applied in order, or to match slotted results.
  ---@type string[]
  labels = { "j", "k", "h", "l" },

  ---Select the first portal when there is only one result.
  select_first = false,

  ---Keys used for exiting portal selection. Disable with [{key}] = false
  ---to `false`.
  ---@type table<string, boolean>
  escape = {
    ["<esc>"] = true,
  },

  ---Keys that Portal will pass to Vim so that you can configure your own mappings for them
  ---so that they will still be in effect when there are portal windows open, or `false` to disable.
  ---@type false|table<string, boolean|integer|"'first'"|"'last'">
  passthru = false,

  ---The raw window options used for the portal window
  ---@type vim.api.keyset.win_config
  window_options = {
    relative = "cursor",
    width = 80,
    height = 3,
    col = 2,
    focusable = false,
    border = "single",
    noautocmd = true,
  },

  ---@type Portal.WindowExtraOptions
  window_extra_opts = vim.empty_dict(),
}

local function termcode_for(key) return vim.api.nvim_replace_termcodes(key, true, false, true) end

--- @param keys table
--- @return string[]
local function replace_termcodes(keys)
  local resolved_keys = {}

  for key_or_index, key_or_flag in pairs(keys) do
    -- Table style: { "a", "b", "c" }. In this case, key_or_flag is the key
    if type(key_or_index) == "number" then
      table.insert(resolved_keys, termcode_for(key_or_flag))
      goto continue
    end

    -- Table style: { ["<esc>"] = true }. In this case, key_or_index is the key
    if type(key_or_index) == "string" and key_or_flag == true then
      table.insert(resolved_keys, termcode_for(key_or_index))
      goto continue
    end

    ::continue::
  end

  return resolved_keys
end

--- @param keys table
--- @return table<string,any>
local function replace_termcodes_val(keys, discard_false)
  local resolved_keys = {}

  for key_or_index, key_or_flag in pairs(keys) do
    -- Table style: { "a", "b", "c" }. In this case, key_or_flag is the key
    if type(key_or_index) == "number" then
      resolved_keys[termcode_for(key_or_flag)] = true
      goto continue
    end

    -- Table style: { ["<esc>"] = true }. In this case, key_or_index is the key
    if type(key_or_index) == "string" and (not discard_false or key_or_flag) then
      resolved_keys[termcode_for(key_or_index)] = key_or_flag
      goto continue
    end

    ::continue::
  end

  return resolved_keys
end

--- @type Portal.Settings
local _settings = DEFAULT_SETTINGS
_settings.escape = replace_termcodes(_settings.escape)
_settings.labels = replace_termcodes(_settings.labels)
_settings.passthru = _settings.passthru and replace_termcodes_val(_settings.passthru) or {}

---@param overrides? Portal.Settings
function Settings.update(overrides)
  _settings = vim.tbl_deep_extend("force", DEFAULT_SETTINGS, overrides or {})
  _settings.escape = replace_termcodes(_settings.escape)
  _settings.labels = replace_termcodes(_settings.labels)
  _settings.passthru = _settings.passthru and replace_termcodes_val(_settings.passthru) or {}
end

--- @return Portal.Settings
function Settings.as_table() return vim.tbl_deep_extend("keep", _settings, {}) end

setmetatable(Settings, {
  __index = function(_, index) return _settings[index] end,
})

return Settings
