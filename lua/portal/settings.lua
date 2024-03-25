---@class Portal.Settings
local Settings = {}
Settings.__index = function(tbl, key)
    return Settings[key] or tbl.inner[key]
end

---@class Portal.Settings
local DEFAULT_SETTINGS = {
    ---An ordered list of keys for labelling portals. Labels will applied in
    ---order, according to their index.
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Select the first portal when there is only one result
    ---@type boolean
    select_first = false,

    ---@alias Portal.Slots integer | Portal.Predicate | Portal.Predicate[]

    -- TODO: Explain slots
    ---The maximum number of results for any search.
    ---
    ---@type Portal.Slots
    slots = nil,

    ---The base filter applied to every search.
    ---@type Portal.Predicate | nil
    filter = nil,

    lookback = 100,

    ---The raw window options used for the portal window
    ---@type vim.api.keyset.win_config
    win_opts = {
        width = 80,
        height = 3,

        relative = "cursor",
        col = 2,

        focusable = false,
        border = "single",
        style = "minimal",
        noautocmd = true,

        ---@type string | fun(c: Portal.Content): string | nil
        title = nil,
        title_pos = "center",
    },
}

local function termcode_for(key)
    return vim.api.nvim_replace_termcodes(key, true, false, true)
end

--- @param keys table
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

---@return Portal.Settings
function Settings.new()
    return setmetatable({
        inner = vim.deepcopy(DEFAULT_SETTINGS),
    }, Settings)
end

-- Update settings in-place
---@param opts? Portal.Settings
function Settings:update(opts)
    self.inner = vim.tbl_deep_extend("force", self.inner, opts or {})
    self.inner.labels = replace_termcodes(self.inner.labels)
end

---A global instance of the Portal settings
---@type Portal.Settings
local settings

---A wrapper around Settings to enable directly indexing the global instance
local SettingsMod = {}

---@return Portal.Settings
function SettingsMod.new()
    return Settings.new()
end

setmetatable(SettingsMod, {
    __index = function(_, key)
        if not settings then
            settings = Settings.new()
        end
        return settings[key]
    end,
})

return SettingsMod
