local tbl = require "src.utils.tbl"
local M = {}

function M.unique(list)
  local clean_list = {}

  for _, value in pairs(list) do
    if not tbl.contains(clean_list, value) then
      table.insert(clean_list, value)
    end
  end

  return clean_list
end

function M.extend(...)
  local merged_list = {}

  for _, list in pairs { ... } do
    for k, v in pairs(list) do
      table.insert(merged_list, v)
    end
  end

  return merged_list
end

return M
