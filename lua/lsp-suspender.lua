-- Notes:
-- Currently running like this lol:
-- LUA_PATH="./?.lua" v lsp-suspender.lua
-- https://github.com/nvim-neorocks/nvim-best-practices
-- Fetch pid??
-- Use https://github.com/neovim/neovim/issues/14504#issuecomment-833940045 
-- vim.lsp config.before_init callback gets initialized_params, can override process_id?
local M = {}

local augroup = vim.api.nvim_create_augroup("LspSuspender", { clear = true })

local last_updated = 0;
local timer;

local config = {
  poll_interval = 1000 * 5, -- 5 seconds,
  suspend_after = 1000 * 10, -- 10 seconds 
  --suspend_after = 1000 * 60 * 1, -- 1 minute
}

local function time()
  return vim.fn.localtime()
end

local function main()
  print("Hello from our plugin")
end

local function update()
  local now = time()
  if now - last_updated > config.suspend_after then
    M.suspend_lsp()
  end
end

local function requested(args)
  last_updated = time()
end

function M.status()
  print(vim.inspect({
    last_updated = last_updated,
    last_updated_str = (time() - last_updated) .. " seconds ago",
    config = config,
  }))
end

function M.suspend_lsp()
  print("Suspend LSP")
end

function M.stop()
  if timer then
    timer:close()
  end
  timer = nil;
end

function M.start()
  last_updated = time()

  if timer then
    print('timer already runing, closing first')
    M.stop()
  end

  -- Create a timer handle (implementation detail: uv_timer_t).
  timer = vim.uv.new_timer()

  local i = 0
  timer:start(0, config.poll_interval, vim.schedule_wrap(function()
    print('timer invoked! i='..tostring(i))

    update()

    i = i + 1
  end))

  return timer
end


function M.setup()
  vim.api.nvim_create_autocmd("LspAttach",
    { group = augroup, desc = "Monitor LSP usage to suspend and resume processes", once = true, callback = main })

  vim.api.nvim_create_autocmd("LspNotify", { group = augroup, callback = requested })
end

return M;