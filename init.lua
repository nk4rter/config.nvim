-- Minimal Neovim config: options, LSP (clangd), completion, treesitter,
-- mini.pick for fuzzy finding + ripgrep, oil for file browsing.
-- Plugins are managed by the built-in `vim.pack` (`:help vim.pack`).
--   inspect: :lua vim.pack.update(nil, { offline = true })
--   update:  :lua vim.pack.update()
--   remove:  :lua vim.pack.del { 'name' }

vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- ============================================================
-- OPTIONS
-- ============================================================

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.undofile = true
vim.o.confirm = true -- ask to save instead of failing on :q with changes

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.signcolumn = 'yes'
vim.o.cursorline = true
vim.o.showmode = false -- already in the statusline
vim.o.winborder = 'rounded'
vim.opt.colorcolumn = { 121 }
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.mouse = 'a'
vim.o.whichwrap = '<,>,h,l'

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = 'split' -- live preview of :s

vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Deferred: reading the OS clipboard costs startup time.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- ============================================================
-- BASIC KEYMAPS & AUTOCMDS
-- ============================================================

local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>w', '<cmd>write<CR>', { desc = '[W]rite file' })
map('n', '<leader>1', '<cmd>set relativenumber!<CR>', { desc = 'Toggle relative numbers' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- NOTE: <C-hjkl> window navigation is provided by vim-tmux-navigator below.

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
  -- Show the message when jumping with [d / ]d
  jump = {
    on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
  },
}

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic [Q]uickfix list' })

-- ============================================================
-- PLUGINS
-- ============================================================

local function gh(repo) return 'https://github.com/' .. repo end

-- Build steps that must run after a plugin is installed/updated.
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
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'rluba/jai.vim',
  gh 'folke/which-key.nvim',
  { src = gh 'saghen/blink.cmp',                version = vim.version.range '1.*' },
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },
}

-- [[ Colorscheme ]]
vim.o.background = 'dark'
vim.o.termguicolors = true
vim.cmd.colorscheme 'gruvbox'

-- [[ mini.nvim modules ]]
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
require('mini.surround').setup()           -- saiw) sd' sr)'
require('mini.ai').setup { n_lines = 500 } -- va) ci' yi]
require('mini.pick').setup {
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
require('mini.extra').setup() -- extra pickers, registered into :Pick
vim.ui.select = MiniPick.ui_select

-- Detect a file's indentation on open and override the defaults above.
require('guess-indent').setup {}

-- Git signs in the gutter, plus hunk staging/reset/preview under `<leader>h`.
-- Keymaps are buffer-local so they only exist in files gitsigns actually attached to.
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
    gmap('x', '<leader>hs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'git [s]tage hunk')
    gmap('x', '<leader>hr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'git [r]eset hunk')
    gmap('n', '<leader>hs', gs.stage_hunk, 'git [s]tage hunk')
    gmap('n', '<leader>hr', gs.reset_hunk, 'git [r]eset hunk')
    gmap('n', '<leader>hS', gs.stage_buffer, 'git [S]tage buffer')
    gmap('n', '<leader>hR', gs.reset_buffer, 'git [R]eset buffer')
    gmap('n', '<leader>hp', gs.preview_hunk, 'git [p]review hunk')
    gmap('n', '<leader>hi', gs.preview_hunk_inline, 'git preview hunk [i]nline')
    gmap('n', '<leader>hb', function() gs.blame_line { full = true } end, 'git [b]lame line')
    gmap('n', '<leader>hd', gs.diffthis, 'git [d]iff against index')
    gmap('n', '<leader>hD', function() gs.diffthis '@' end, 'git [D]iff against last commit')
    gmap('n', '<leader>hq', gs.setqflist, 'git hunk [q]uickfix list (this file)')
    gmap('n', '<leader>hQ', function() gs.setqflist 'all' end, 'git hunk [Q]uickfix list (whole repo)')

    -- Toggles
    gmap('n', '<leader>tb', gs.toggle_current_line_blame, '[T]oggle git [b]lame line')
    gmap('n', '<leader>tw', gs.toggle_word_diff, '[T]oggle git intra-line [w]ord diff')

    -- Text object: `ih` = "in hunk", so `dih` discards a hunk, `vih` selects one.
    gmap({ 'o', 'x' }, 'ih', gs.select_hunk, 'git hunk')
  end,
}

require('fidget').setup {} -- LSP progress in the corner

-- Popup listing what can follow a half-typed key sequence. Groups below just give
-- the prefixes a readable label; every other entry comes from the keymap `desc`s.
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
map('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'File [E]xplorer (oil)' })
map('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory (oil)' })

-- ============================================================
-- PICKERS (mini.pick + mini.extra)
-- ============================================================

local pick = MiniPick.builtin
local extra = MiniExtra.pickers

---Text to seed a search with: visual selection in visual mode, else <cword>.
local function search_seed()
  local mode = vim.fn.mode()
  if not mode:match '[vV\22]' then return vim.fn.expand '<cword>' end
  return vim.fn.getregion(vim.fn.getpos '.', vim.fn.getpos 'v', { type = mode })[1]
end

---Paths of listed, on-disk buffers, relative to cwd (used as ripgrep globs).
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
map('n', '<leader><leader>', pick.buffers, { desc = '[ ] Find existing buffers' })
map({ 'n', 'x' }, '<leader>sw', function() pick.grep { pattern = search_seed() } end,
  { desc = '[S]earch current [W]ord' })
map('n', '<leader>s/', function() pick.grep_live { globs = open_file_globs() } end,
  { desc = '[S]earch [/] in open files' })
map('n', '<leader>sk', extra.keymaps, { desc = '[S]earch [K]eymaps' })
map('n', '<leader>sc', extra.commands, { desc = '[S]earch [C]ommands' })
-- `scope = 'current'` limits this to the current buffer; the default 'all' also picks up
-- diagnostics the LSP published for files that were never opened (headers, other TUs).
map('n', '<leader>sd', function() extra.diagnostic { scope = 'current' } end, { desc = '[S]earch [D]iagnostics' })
map('n', '<leader>s.', extra.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
map('n', '<leader>/', function() extra.buf_lines { scope = 'current' } end,
  { desc = '[/] Fuzzily search in current buffer' })
map('n', '<leader>sn', function() pick.files(nil, { source = { cwd = vim.fn.stdpath 'config' } }) end,
  { desc = '[S]earch [N]eovim config files' })

-- Pick a picker (like Telescope's builtin picker).
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

-- ============================================================
-- LSP
-- ============================================================

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
    bmap('gO', function() extra.lsp { scope = 'document_symbol' } end, '[O]pen Document Symbols')

    bmap('gW', function() extra.lsp { scope = 'workspace_symbol_live' } end, 'Workspace Symbols')
    bmap('<leader>f', function() vim.lsp.buf.format { async = true } end, '[F]ormat buffer', { 'n', 'x' })

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Highlight other references to the symbol under the cursor.
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

require('mason').setup {}
require('mason-lspconfig').setup {
  ensure_installed = vim.tbl_keys(servers),
  automatic_enable = false, -- servers are enabled explicitly below
}

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
end
vim.lsp.enable(vim.tbl_keys(servers))

-- ============================================================
-- AUTOCOMPLETE
-- ============================================================

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

-- ============================================================
-- TREESITTER
-- ============================================================

local ts = require 'nvim-treesitter'
ts.install { 'bash', 'c', 'cpp', 'diff', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable treesitter highlighting and indentation',
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang or not vim.treesitter.language.add(lang) then return end
    vim.treesitter.start(args.buf, lang)
    if vim.treesitter.query.get(lang, 'indents') then
      vim.bo[args.buf].indentexpr =
      "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
