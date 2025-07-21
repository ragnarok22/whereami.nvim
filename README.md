# Whereami.nvim

An easy way to test your VPN by getting your current location without leaving Neovim.

## Installation

[lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "ragnarok22/whereami.nvim",
    cmd = "Whereami"
}
```

[pckr](https://github.com/lewis6991/pckr.nvim):

```lua
{
    'ragnarok22/whereami.nvim',
    -- Lazy loading on specific command
    cond = {
        cmd {'Whereami'}
    }
}
```

[packer](https://github.com/wbthomason/packer.nvim) (deprecated):

```lua
use 'ragnarok22/whereami.nvim'
```

and then execute `:PackerUpdate`.

### Usage with [nvim-notify](https://github.com/rcarriga/nvim-notify)

You only need to install
[nvim-notify](https://github.com/rcarriga/nvim-notify) and set the notify:

```lua
vim.notify = require("notify")
```

Here an example of installation using lazy:

```lua
{
  "ragnarok22/whereami.nvim",
  cmd = "Whereami",
  dependencies = {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
    end
  }
}
```

## Usage

You can use the command or the API

### Command

Just type the command `:Whereami` and you will see the country you are.

You can also provide and argument:

- `:Whereami country`: Show the country location where you request was originated from.
- `:Whereami city`: Show the city location where you request was originated from.
- `:Whereami ip`: Show the ip location where you request was originated from.

### API

You can also use the methods, for example for key bindings

```lua
local whereami = require("whereami")
whereami.country() -- show the country
whereami.city() -- show the city
whereami.ip() -- show the IP

-- set keymaps
vim.keymap.set("n", "<leader>l", whereami.country, { desc = "Show the country" })
vim.keymap.set("n", "<leader>e", whereami.city, { desc = "Show the city" })
vim.keymap.set("n", "<leader>i", whereami.ip, { desc = "Show the ip" })
```

## Testing

The plugin uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for
its test suite. You can run the tests from the project root with:

```bash
nvim --headless -c "PlenaryBustedDirectory lua/tests {minimal_init = 'tests/minimal_init.lua'}" +qa
```

The command requires Neovim and plenary.nvim to be installed.

## License

[GNU GPLv3](LICENSE)
