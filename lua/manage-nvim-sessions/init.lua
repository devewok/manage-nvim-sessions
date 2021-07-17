local api = vim.api
local buf, win
local position = 0
local sessions_path=vim.g.sessions_path or os.getenv("VIMRC").. "\\sessions\\"
local namespace

local function check_sessions_directory()
  if api.nvim_call_function('isdirectory',{sessions_path}) == 0 then
    print("Path "..sessions_path.." to search sessions was not found")
    return false
  else
    return true
  end
end

local function clean_str(str)
  str=str:gsub("%s+","")
  str=string.gsub(str,"%s+","")
  return str
end

local function update_session()
  if check_sessions_directory() then
    namespace=vim.env.namespace
    local session_namespace=sessions_path..namespace
    api.nvim_command("mksession! "..session_namespace) 
    print("Updating session :",namespace)
  end
end

local function make_session()
  if check_sessions_directory() then
    if vim.env.namespace == nil then
      namespace=api.nvim_call_function('input',{"Session name: "})
      namespace=clean_str(namespace)
      vim.env.namespace=namespace
      local session_namespace=sessions_path..namespace
      api.nvim_command("mksession "..session_namespace) 
      print("Session created :",namespace)
    else
      update_session()
    end
  end
end

local function delete_session()
  namespace=vim.env.namespace
  local session_namespace
  if namespace == nil then
    namespace=api.nvim_call_function('input',{"Session name: "})
  end
  session_namespace=sessions_path..namespace
  if api.nvim_call_function('findfile',{namespace,sessions_path}) ~= "" then
    api.nvim_call_function('delete',{session_namespace})
    vim.env.namespace=nil
    print("Session deleted")
  else
    print("Session not found")
  end 
end

local function current_session()
  namespace=vim.env.namespace or "Not session loaded"
  print("Session loaded :",namespace)
end

local function get_sessions()
  local files = api.nvim_call_function('readdir',{sessions_path})
  local sessions={}
  for k,file in pairs(files) do
    if string.match(file,".vim") then
      table.insert(sessions,file)
    end
  end
  return sessions
end

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function create_sessions_window()
  buf = api.nvim_create_buf(false, true)
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'filetype', 'whid')

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  api.nvim_win_set_option(border_win,'winhl','Normal:SessionsWindow')

  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it
  api.nvim_win_set_option(win,'foldmethod','manual')
  api.nvim_win_set_option(win,'winhl','Normal:SessionsWindow')

  -- we can add title already here, because first line will never change
  api.nvim_buf_set_lines(buf, 0, -1, false, { center('Sessions founded'), '', ''})
end

local function update_sessions_window(direction)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction
  if position < 0 then position = 0 end

  local result=get_sessions()
  if #result == 0 then table.insert(result, '') end -- add  an empty line to preserve layout if there is no results
  for k,v in pairs(result) do
    result[k] = '  '..result[k]
  end

  api.nvim_buf_set_lines(buf, 1, 2, false, {center('Fuck ready')})
  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_sessions_window()
  api.nvim_win_close(win, true)
end

local function load_session()
  local selected= api.nvim_get_current_line()
  close_sessions_window()
  api.nvim_command("bwipeout")
  namespace=clean_str(selected)
  vim.env.namespace=namespace
  local session_namespace=sessions_path..namespace
  api.nvim_command("source "..session_namespace)
end

local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function set_mappings()
  local mappings = {
    ['['] = 'update_sessions_window(-1)',
    [']'] = 'update_sessions_window(1)',
    ['<cr>'] = 'load_session()',
    h = 'update_sessions_window(-1)',
    l = 'update_sessions_window(1)',
    q = 'close_sessions_window()',
    ['<ESC>'] = 'close_sessions_window()',
    k = 'move_cursor()'
  }

  for k,v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"manage-nvim-sessions".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

local function manage_nvim_sessions()
  if check_sessions_directory() then
    position = 0
    create_sessions_window()
    set_mappings()
    update_sessions_window(0)
    api.nvim_win_set_cursor(win, {4, 0})
  end
end

return {
  mns = manage_nvim_sessions,
  ms=make_session,
  us=update_session,
  ds=delete_session,
  cs=current_session,
  update_sessions_window= update_sessions_window,
  load_session = load_session,
  move_cursor = move_cursor,
  close_sessions_window = close_sessions_window
}
