local M = {}

local Job = require("plenary.job")

-- Helper to get selected text in visual mode
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

  if #lines == 0 then
    return nil
  end

  lines[1] = string.sub(lines[1], start_col)
  lines[#lines] = string.sub(lines[#lines], 1, end_col)

  return table.concat(lines, "\n")
end

-- Query the Ollama API
local function query_ollama_api(selected_code, callback)
  local json = vim.fn.json_encode({
    model = "qwen2.5:14b",
    messages = {
      {
        role = "user",
        content = "Please provide language tutorial on this selected sentence, provide explanation for words that are at n4 level in this sentence using format like this example eat::食べる(たべる)\n" .. selected_code,
      },
    },
  })

  Job:new({
    command = "curl",
    args = {
      "-s",  -- Add the silent flag to suppress progress output
      "-X",
      "POST",
      "http://127.0.0.1:11434/api/chat",
      "-H",
      "Content-Type: application/json",
      "-d",
      json,
    },
    on_stdout = function(_, line)
      local success, decoded = pcall(vim.json.decode, line)
      if success and decoded and decoded.message and decoded.message.content then
        vim.schedule(function()
          callback(decoded.message.content)
        end)
      end
    end,
    on_stderr = function(_, line)
      if not line:match("^%s*$") then  -- Ignore empty lines
        vim.schedule(function()
          vim.notify("Error querying Ollama API: " .. line, vim.log.levels.ERROR)
        end)
      end
    end,
    on_exit = function(_, return_val)
      if return_val ~= 0 then
        vim.schedule(function()
          vim.notify("Failed to query Ollama API", vim.log.levels.ERROR)
        end)
      end
    end,
  }):start()
end

-- Create a floating window
local function create_floating_window()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local opts = {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    col = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.8)) / 2),
    row = math.floor((vim.o.lines - math.floor(vim.o.lines * 0.8)) / 2),
    style = "minimal",
    border = "rounded",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  return buf, win
end

-- Main function to execute the plugin
function M.ollama_popup()
  local selected_code = get_visual_selection()
  if not selected_code or selected_code == "" then
    vim.notify("No code selected!", vim.log.levels.ERROR)
    return
  end

  local buf, win = create_floating_window()

  -- Initialize the buffer with the selected code and two empty lines
  local initial_content = vim.split(selected_code, "\n")
  table.insert(initial_content, "")
  table.insert(initial_content, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_content)

  query_ollama_api(selected_code, function(new_line)
    local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local new_lines = vim.split(new_line, "\n")

    -- Append new lines correctly
    for _, line in ipairs(new_lines) do
      if line == "" then
        table.insert(current_lines, "")
      else
        current_lines[#current_lines] = (current_lines[#current_lines] or "") .. line
      end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
  end)
end

vim.api.nvim_create_user_command("OllamaPopup", M.ollama_popup, { 
  range = true,
  desc = "Explain the selected code using the Ollama API"
})

return M