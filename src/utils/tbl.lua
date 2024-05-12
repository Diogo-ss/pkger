local M = {}

function M.is_empty(tbl)
  return rawequal(next(tbl), nil)
end

function M.map(tbl, func)
  local new_tbl = {}

  for key, value in pairs(tbl) do
    new_tbl[key] = func(value)
  end

  return new_tbl
end

function M.keys(tbl)
  -- assert(type(tbl) == "table", "The argument must be a table.")

  local keys = {}
  for key, _ in pairs(tbl) do
    table.insert(keys, key)
  end

  return keys
end

function M.extend(...)
  local args = { ... }
  local merged_table = {}

  for _, tbl in ipairs(args) do
    for k, v in pairs(tbl) do
      merged_table[k] = v
    end
  end

  return merged_table
end

function M.deep_extend(...)
  local args = { ... }
  local merged_table = {}

  for _, tbl in ipairs(args) do
    for k, v in pairs(tbl) do
      if type(v) == "table" and type(merged_table[k]) == "table" then
        merged_table[k] = M.deep_extend(merged_table[k], v)
      else
        merged_table[k] = v
      end
    end
  end

  return merged_table
end

function M.diff(tbl1, tbl2)
  local diff = {}

  for key, value in pairs(tbl1) do
    if not tbl2[key] then
      diff[key] = value
    end
  end

  for key, value in pairs(tbl2) do
    if not tbl1[key] then
      diff[key] = value
    end
  end

  return diff
end

function M.contains(tbl, value)
  for _, v in pairs(tbl) do
    if v == value then
      return true
    end
  end

  return false
end

return M
