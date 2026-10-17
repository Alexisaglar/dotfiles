-- Freehand mouse drawing in any buffer. <leader>p toggles paint mode.
-- Left drag draws, right drag erases. <leader>t opens the brush/colour picker.
-- :PaintBrush <char> and :PaintColor <name|#rrggbb|none> set either by hand.
-- Colours are highlights, not file content: they are kept in "<file>.colors"
-- next to the file so the file itself stays plain text.
local brush = "█"
local color -- nil = no colour
local last -- last painted cell {row, col}, for joining fast drags
local ns = vim.api.nvim_create_namespace("paint")
local groups = {} -- highlight group name -> colour

local function hl(c)
  local name = "Paint_" .. c:gsub("%W", "")
  if not groups[name] then
    vim.api.nvim_set_hl(0, name, { fg = c })
    groups[name] = c
  end
  return name
end

local function mark(row, s, e, c)
  vim.api.nvim_buf_set_extmark(0, ns, row - 1, s, { end_col = e, hl_group = hl(c), invalidate = true })
end

local function put(row, col, ch)
  if row < 1 or col < 1 then return end
  local erase = ch == " "
  local n = vim.api.nvim_buf_line_count(0)
  if row > n then
    if erase then return end
    local pad = {}
    for _ = 1, row - n do pad[#pad + 1] = "" end
    vim.api.nvim_buf_set_lines(0, n, n, false, pad)
  end
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local len = vim.fn.strchars(line)
  if len < col then
    if erase then return end
    local pad = string.rep(" ", col - len)
    vim.api.nvim_buf_set_text(0, row - 1, #line, row - 1, #line, { pad })
    line = line .. pad
  end
  local s, e = vim.fn.byteidx(line, col - 1), vim.fn.byteidx(line, col)
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, { row - 1, s }, { row - 1, s }, {})) do
    vim.api.nvim_buf_del_extmark(0, ns, m[1])
  end
  vim.api.nvim_buf_set_text(0, row - 1, s, row - 1, e, { ch })
  if erase then
    line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    local t = line:find("%s+$")
    if t then vim.api.nvim_buf_set_text(0, row - 1, t - 1, row - 1, #line, { "" }) end
  elseif color then
    mark(row, s, s + #ch, color)
  end
end

local function cell()
  local m = vim.fn.getmousepos()
  if m.winid ~= vim.api.nvim_get_current_win() then return end
  local view = vim.fn.winsaveview()
  local textoff = vim.fn.getwininfo(m.winid)[1].textoff
  return view.topline + m.winrow - 1, view.leftcol + m.wincol - textoff
end

local function stroke(ch, join)
  local row, col = cell()
  if not row then return end
  if join then pcall(vim.cmd, "undojoin") end -- one undo per stroke
  local r, c = row, col
  if join and last then r, c = last[1], last[2] end
  -- Bresenham from the last cell to this one
  local dr, dc = math.abs(row - r), math.abs(col - c)
  local sr, sc = r < row and 1 or -1, c < col and 1 or -1
  local err = dc - dr
  while true do
    put(r, c, ch)
    if r == row and c == col then break end
    local e2 = 2 * err
    if e2 > -dr then err = err - dr; c = c + sc end
    if e2 < dc then err = err + dc; r = r + sr end
  end
  last = { row, col }
end

local keys = {
  ["<LeftMouse>"] = function() stroke(brush, false) end,
  ["<LeftDrag>"] = function() stroke(brush, true) end,
  ["<RightMouse>"] = function() stroke(" ", false) end,
  ["<RightDrag>"] = function() stroke(" ", true) end,
  ["<LeftRelease>"] = function() end,
  ["<RightRelease>"] = function() end,
}

local function toggle()
  if vim.b.paint_saved then
    for k in pairs(keys) do vim.keymap.del({ "n", "i" }, k, { buffer = true }) end
    vim.wo.wrap, vim.wo.virtualedit = unpack(vim.b.paint_saved)
    vim.b.paint_saved = nil
    print("paint off")
  else
    vim.b.paint_saved = { vim.wo.wrap, vim.wo.virtualedit }
    vim.wo.wrap, vim.wo.virtualedit = false, "all"
    vim.o.mouse = "a"
    for k, f in pairs(keys) do vim.keymap.set({ "n", "i" }, k, f, { buffer = true }) end
    print("paint on")
  end
end

-- Picker: a small float listing brushes and colours. Click an entry, or move
-- the cursor onto it and press <CR>. q or <Esc> closes it.
local brushes = { "█", "▓", "▒", "░", "●", "•", "·", "*", "#", "+", "─", "│", "╱", "╲" }
local colours = { false, "#e06c75", "#e5964b", "#e5c07b", "#98c379", "#56b6c2", "#61afef", "#c678dd", "#ffffff", "#7f848e" }
local label = 9 -- width of the row labels; entries follow, two columns apart
local pick_win, pick_buf

local function render()
  local swatches = {}
  for i, c in ipairs(colours) do swatches[i] = c and "■" or "✕" end
  local lines = {
    " Brush   " .. table.concat(brushes, " "),
    " Colour  " .. table.concat(swatches, " "),
    " Now     " .. string.rep(brush, 4),
  }
  vim.bo[pick_buf].modifiable = true
  vim.api.nvim_buf_set_lines(pick_buf, 0, -1, false, lines)
  vim.bo[pick_buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(pick_buf, ns, 0, -1)
  for i, c in ipairs(colours) do
    if c then
      local s = vim.fn.byteidx(lines[2], label + 2 * (i - 1))
      vim.api.nvim_buf_set_extmark(pick_buf, ns, 1, s, { end_col = s + #"■", hl_group = hl(c) })
    end
  end
  if color then
    vim.api.nvim_buf_set_extmark(pick_buf, ns, 2, label, { end_col = #lines[3], hl_group = hl(color) })
  end
end

local function pick(row, vcol)
  local i = (vcol - label - 1) / 2 + 1
  if i < 1 or i ~= math.floor(i) then return end
  if row == 1 and brushes[i] then
    brush = brushes[i]
  elseif row == 2 and colours[i] ~= nil then
    color = colours[i] or nil
  end
  render()
end

local function close_picker()
  if pick_win and vim.api.nvim_win_is_valid(pick_win) then vim.api.nvim_win_close(pick_win, true) end
  pick_win = nil
end

local function picker()
  if pick_win and vim.api.nvim_win_is_valid(pick_win) then return close_picker() end
  pick_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[pick_buf].bufhidden = "wipe"
  local width = label + 2 * math.max(#brushes, #colours)
  pick_win = vim.api.nvim_open_win(pick_buf, true, {
    relative = "editor", row = 1, col = vim.o.columns - width - 3,
    width = width, height = 3, style = "minimal", border = "rounded", title = " paint ",
  })
  render()
  local function map(k, f) vim.keymap.set("n", k, f, { buffer = pick_buf, nowait = true }) end
  for _, k in ipairs({ "q", "<Esc>", "<leader>t" }) do map(k, close_picker) end
  map("<CR>", function() pick(vim.fn.line("."), vim.fn.virtcol(".")) end)
  map("<LeftMouse>", function()
    local m = vim.fn.getmousepos()
    if m.winid ~= pick_win then return close_picker() end
    -- winrow/wincol count the float's border, so go through the buffer position
    if m.line > 0 then pick(m.line, vim.fn.virtcol({ m.line, m.column })) end
  end)
  for _, k in ipairs({ "<LeftDrag>", "<LeftRelease>" }) do map(k, function() end) end
  vim.api.nvim_create_autocmd("WinLeave", { buffer = pick_buf, once = true, callback = close_picker })
end

-- Colours live in a sidecar file as { colour = { {row, col}, ... } }
local function sidecar() return vim.api.nvim_buf_get_name(0) .. ".colors" end

local function save_colors()
  local out, any = {}, false
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
    local c = groups[m[4].hl_group]
    if c and not m[4].invalid then
      local line = vim.api.nvim_buf_get_lines(0, m[2], m[2] + 1, false)[1]
      out[c] = out[c] or {}
      table.insert(out[c], { m[2] + 1, vim.fn.charidx(line, m[3]) + 1 })
      any = true
    end
  end
  if any then
    vim.fn.writefile({ vim.json.encode(out) }, sidecar())
  elseif vim.uv.fs_stat(sidecar()) then
    vim.fn.delete(sidecar())
  end
end

local function load_colors()
  if not vim.uv.fs_stat(sidecar()) then return end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(sidecar())))
  if not ok then return end
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  for c, cells in pairs(data) do
    for _, rc in ipairs(cells) do
      local line = vim.api.nvim_buf_get_lines(0, rc[1] - 1, rc[1], false)[1]
      if line and vim.fn.strchars(line) >= rc[2] then
        mark(rc[1], vim.fn.byteidx(line, rc[2] - 1), vim.fn.byteidx(line, rc[2]), c)
      end
    end
  end
end

local group = vim.api.nvim_create_augroup("paint", {})
vim.api.nvim_create_autocmd("BufWritePost", { group = group, callback = save_colors })
vim.api.nvim_create_autocmd("BufReadPost", { group = group, callback = load_colors })

vim.keymap.set("n", "<leader>p", toggle, { desc = "Toggle paint mode" })
vim.keymap.set("n", "<leader>t", picker, { desc = "Paint brush/colour picker" })
vim.api.nvim_create_user_command("PaintBrush", function(o) brush = o.args end, { nargs = 1 })
vim.api.nvim_create_user_command("PaintColor", function(o)
  color = o.args ~= "none" and o.args or nil
end, { nargs = 1 })
