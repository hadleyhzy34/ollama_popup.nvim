# ollama_popup.nvim

a lua plugin to connect to local ollama api using neovim, this plugin can be customized as language learning tool to help u with grammar, vocabulary by chatting with local ollama large language model.

## Installation

add below code to `lazy.lua`:

```lua
-- Add the ollama_popup plugin from GitHub
{
  "hadleyhzy34/ollama_popup.nvim",
  config = function()
    require("ollama_popup")
  end,
},
```

## key setup

```lua
-- Map <leader>o to call the OllamaPopup command
vim.api.nvim_set_keymap('v', '<leader>o', ':OllamaPopup<CR>', { noremap = true, silent = true })
```

## config

currently all configurations can be directly recoded through `lua/ollama_popup/init.lua`

1. local api address
2. port number
3. ollama model name
