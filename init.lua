-- inspect: :lua vim.pack.update(nil, { offline = true })
-- update:  :lua vim.pack.update()
-- delete:  :lua vim.pack.del { 'name' }

vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

----- Options

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.undofile = true
vim.o.confirm = true

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.signcolumn = 'yes'
vim.o.cursorline = true
vim.o.showmode = false
vim.o.winborder = 'rounded'
vim.opt.colorcolumn = { 121 }
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.mouse = 'a'
vim.o.whichwrap = '<,>,h,l'

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = 'nosplit'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

----- Basic

local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>w', '<cmd>write<CR>', { desc = '[W]rite file' })
map('n', '<leader>1', '<cmd>set relativenumber!<CR>', { desc = 'Toggle relative numbers' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.diagnostic.config {
  severity_sort = true,
  update_in_insert = false,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.HINT] = '',
      [vim.diagnostic.severity.INFO] = '',
    },
  } or true,
  jump = {
    on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
  },
}

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic [Q]uickfix list' })

----- Plugins

local function gh(repo) return 'https://github.com/' .. repo end

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end
    if ev.data.spec.name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      vim.cmd 'TSUpdate'
    end
  end,
})

vim.pack.add {
  gh 'ellisonleao/gruvbox.nvim',
  gh 'NMAC427/guess-indent.nvim',
  gh 'nvim-mini/mini.nvim',
  gh 'stevearc/oil.nvim',
  gh 'lewis6991/gitsigns.nvim',
  gh 'nvim-lualine/lualine.nvim',
  gh 'christoomey/vim-tmux-navigator',
  gh 'j-hui/fidget.nvim',
  gh 'folke/which-key.nvim',
  gh 'folke/todo-comments.nvim',
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'nvim-treesitter/nvim-treesitter',
  { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' },
}

vim.o.background = 'dark'
vim.o.termguicolors = true
vim.cmd.colorscheme 'gruvbox'

local MiniIcons = require 'mini.icons'

MiniIcons.setup()
MiniIcons.mock_nvim_web_devicons()

-- saiw) sd' sr)'
require('mini.surround').setup()

-- va) ci' yi]
-- `aa`/`ii` instead of the default `an`/`in`
-- See `:help treesitter-incremental-selection`.
require('mini.ai').setup { mappings = { around_next = 'aa', inside_next = 'ii' }, n_lines = 500 }

local MiniPick = require 'mini.pick'
MiniPick.setup {
  window = {
    config = function()
      local SCALE = 0.75
      local height, width = math.floor(SCALE * vim.o.lines), math.floor(SCALE * vim.o.columns)
      return {
        anchor = 'NW',
        height = height,
        width = width,
        row = math.floor(0.5 * (vim.o.lines - height)),
        col = math.floor(0.5 * (vim.o.columns - width)),
      }
    end,
  },
}

local MiniExtra = require 'mini.extra'
MiniExtra.setup()

vim.ui.select = MiniPick.ui_select

require('guess-indent').setup()

require('gitsigns').setup {
  on_attach = function(bufnr)
    local gs = require 'gitsigns'
    local function gmap(mode, lhs, rhs, desc) map(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end

    -- Navigation: fall back to the builtin diff-mode ]c/[c when in a diff.
    gmap('n', ']c', function()
      if vim.wo.diff then vim.cmd.normal { ']c', bang = true } else gs.nav_hunk 'next' end
    end, 'Jump to next git [c]hange')
    gmap('n', '[c', function()
      if vim.wo.diff then vim.cmd.normal { '[c', bang = true } else gs.nav_hunk 'prev' end
    end, 'Jump to previous git [c]hange')

    -- Actions
    gmap('x', '<leader>hs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'git [S]tage hunk')
    gmap('x', '<leader>hr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'git [R]eset hunk')
    gmap('n', '<leader>hs', gs.stage_hunk, 'git [S]tage hunk')
    gmap('n', '<leader>hr', gs.reset_hunk, 'git [R]eset hunk')
    gmap('n', '<leader>hS', gs.stage_buffer, 'git [S]tage buffer')
    gmap('n', '<leader>hR', gs.reset_buffer, 'git [R]eset buffer')
    gmap('n', '<leader>hp', gs.preview_hunk, 'git [P]review hunk')
    gmap('n', '<leader>hi', gs.preview_hunk_inline, 'git preview hunk [I]nline')
    gmap('n', '<leader>hb', function() gs.blame_line { full = true } end, 'git [B]lame line')
    gmap('n', '<leader>hd', gs.diffthis, 'git [D]iff against index')
    gmap('n', '<leader>hD', function() gs.diffthis '@' end, 'git [D]iff against last commit')
    gmap('n', '<leader>hq', gs.setqflist, 'git hunk [Q]uickfix list (this file)')
    gmap('n', '<leader>hQ', function() gs.setqflist 'all' end, 'git hunk [Q]uickfix list (whole repo)')

    -- Toggles
    gmap('n', '<leader>tb', gs.toggle_current_line_blame, '[T]oggle git [B]lame line')
    gmap('n', '<leader>tw', gs.toggle_word_diff, '[T]oggle git intra-line [W]ord diff')

    -- Text object: `ih` = "in hunk", so `dih` discards a hunk, `vih` selects one.
    gmap({ 'o', 'x' }, 'ih', gs.select_hunk, 'git hunk')
  end,
}

require('fidget').setup()

require('todo-comments').setup { signs = false }

require('which-key').setup {
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>s', group = '[S]earch',   mode = { 'n', 'x' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'x' } },
    { 'gr',        group = 'LSP Actions' },
  },
}

require('lualine').setup { options = { theme = 'powerline' } }

require('oil').setup {
  view_options = { show_hidden = true },
}
map('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'File [E]xplorer' })
map('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })

----- Pickers

local pick = MiniPick.builtin
local extra = MiniExtra.pickers

local VISUAL_MODES = { v = true, V = true, ['\22'] = true }

local function search_seed()
  local mode = vim.fn.mode()
  if not VISUAL_MODES[mode] then return vim.fn.expand '<cword>' end
  return vim.fn.getregion(vim.fn.getpos '.', vim.fn.getpos 'v', { type = mode })[1]
end

local function open_file_globs()
  local globs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buflisted and name ~= '' and vim.uv.fs_stat(name) then
      table.insert(globs,
        vim.fn.fnamemodify(name, ':.'))
    end
  end
  return globs
end

map('n', '<C-p>', pick.files, { desc = 'Search Files' })
map('n', '<leader>sf', pick.files, { desc = '[S]earch [F]iles' })
map('n', '<leader>sg', pick.grep_live, { desc = '[S]earch by [G]rep' })
map('n', '<leader>sh', pick.help, { desc = '[S]earch [H]elp' })
map('n', '<leader>sr', pick.resume, { desc = '[S]earch [R]esume' })
map('n', '<leader><leader>', pick.buffers, { desc = '[ ] Find Existing Buffers' })
map({ 'n', 'x' }, '<leader>sw', function() pick.grep { pattern = search_seed(), method = 'plain' } end,
  { desc = '[S]earch current [W]ord' })
map('n', '<leader>s/', function() pick.grep_live { globs = open_file_globs() } end,
  { desc = '[S]earch [/] in open files' })
map('n', '<leader>sk', extra.keymaps, { desc = '[S]earch [K]eymaps' })
map('n', '<leader>sc', extra.commands, { desc = '[S]earch [C]ommands' })
map('n', '<leader>sd', function() extra.diagnostic { scope = 'current' } end, { desc = '[S]earch [D]iagnostics' })
map('n', '<leader>s.', extra.oldfiles, { desc = '[S]earch recent files ("." for repeat)' })
map('n', '<leader>/', function() extra.buf_lines { scope = 'current' } end,
  { desc = '[/] Fuzzily search in current buffer' })
map('n', '<leader>sn', function() pick.files(nil, { source = { cwd = vim.fn.stdpath 'config' } }) end,
  { desc = '[S]earch [N]eovim config files' })

map('n', '<leader>ss', function()
  local names = vim.tbl_keys(MiniPick.registry)
  table.sort(names)
  MiniPick.start {
    source = {
      items = names,
      name = 'Pickers',
      choose = function(name) vim.schedule(function() MiniPick.registry[name]() end) end,
    },
  }
end, { desc = '[S]earch [S]elect picker' })

----- LSP

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local function bmap(keys, func, desc, mode)
      map(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    bmap('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    bmap('gra', vim.lsp.buf.code_action, 'Code [A]ction', { 'n', 'x' })
    bmap('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    bmap('grd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    bmap('grr', function() extra.lsp { scope = 'references' } end, '[G]oto [R]eferences')
    bmap('gri', function() extra.lsp { scope = 'implementation' } end, '[G]oto [I]mplementation')
    bmap('grt', vim.lsp.buf.type_definition, '[G]oto [T]ype Definition')
    bmap('gO', function() extra.lsp { scope = 'document_symbol' } end, '[O]pen document symbols')
    bmap('gW', function() extra.lsp { scope = 'workspace_symbol_live' } end, '[W]orkspace symbols')
    bmap('<leader>f', function() vim.lsp.buf.format { async = true } end, '[F]ormat buffer', { 'n', 'x' })

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end

    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      bmap('<leader>th',
        function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end,
        '[T]oggle Inlay [H]ints')
    end
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event.buf }
  end,
})

---@type table<string, vim.lsp.Config>
local servers = {
  clangd = {},
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME, '${3rd}/luv/library' },
        },
      },
    },
  },
}

require('mason').setup()
require('mason-lspconfig').setup {
  ensure_installed = vim.tbl_keys(servers),
  automatic_enable = false,
}

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
end
vim.lsp.enable(vim.tbl_keys(servers))

----- Completion

require('blink.cmp').setup {
  -- <c-y> accept, <c-n>/<c-p> select, <c-space> menu/docs, <c-e> hide, <c-k> signature.
  -- See `:help ins-completion` and `:help blink-cmp-config-keymap`.
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = false } },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
  signature = { enabled = true },
}

----- Treesitter

local ts = require 'nvim-treesitter'

local ts_available = ts.get_available()

local function ts_attach(buf, lang)
  if not vim.treesitter.language.add(lang) then return end
  vim.treesitter.start(buf, lang)
  if vim.treesitter.query.get(lang, 'indents') then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable treesitter highlighting and indentation, installing the parser on demand',
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then return end
    if not vim.tbl_contains(ts.get_installed 'parsers', lang) and vim.tbl_contains(ts_available, lang) then
      return ts.install(lang):await(function() ts_attach(args.buf, lang) end)
    end
    ts_attach(args.buf, lang)
  end,
})

-- vim: ts=2 sts=2 sw=2 et
