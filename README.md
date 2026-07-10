# Whereami.nvim

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ragnarok22/whereami.nvim)

An easy way to test your VPN by getting your current location without leaving Neovim.

## Features

- Country flag notification
- City and IP information
- ISP lookup
- Works with [nvim-notify](https://github.com/rcarriga/nvim-notify)

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

Install [nvim-notify](https://github.com/rcarriga/nvim-notify) and set it as the default notifier:

```lua
vim.notify = require("notify")
```

Here is an example of installation using lazy:

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

Run `:Whereami` to display the country you are in.

You can also provide an argument:

- `:Whereami country`: Show the country location where you request was originated from.
- `:Whereami city`: Show the city location where you request was originated from.
- `:Whereami ip`: Show the IP address where your request originated from.
- `:Whereami isp`: Show your current internet service provider.

### API

You can also use the methods, for example for key bindings

```lua
local whereami = require("whereami")
whereami.country() -- show the country
whereami.city() -- show the city
whereami.ip() -- show the IP
whereami.isp() -- show the ISP

-- set keymaps
vim.keymap.set("n", "<leader>l", whereami.country, { desc = "Show the country" })
vim.keymap.set("n", "<leader>e", whereami.city, { desc = "Show the city" })
vim.keymap.set("n", "<leader>i", whereami.ip, { desc = "Show the ip" })
vim.keymap.set("n", "<leader>s", whereami.isp, { desc = "Show the ISP" })
```


## Privacy and provider

Whereami.nvim contacts a third-party IP geolocation provider each time you run
`:Whereami` or call one of the Lua API methods (`country()`, `city()`, `ip()`,
or `isp()`).

- **Provider:** the plugin currently sends requests to `ipinfo.io`.
- **Data sent:** the request is made from your current network connection, so the
  provider receives the source IP address for that request and normal HTTP
  request metadata such as headers added by Neovim/plenary/curl and network
  routing information. Whereami.nvim does not send your Neovim buffers, files,
  editor configuration, or any extra location data.
- **Provider configuration:** the provider URL is not currently configurable; it
  is hard-coded to `ipinfo.io` in the plugin implementation.
- **Local caching:** results are not cached by Whereami.nvim. Each command or API
  call makes a fresh provider request.

Review the provider's own privacy policy and terms before using the plugin if
you have specific privacy or compliance requirements.

## Testing

The plugin uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for
its test suite. You can run the tests from the project root with:

```bash
nvim --headless -c "PlenaryBustedDirectory lua/tests {minimal_init = 'tests/minimal_init.lua'}" +qa
```

The command requires Neovim and plenary.nvim to be installed.

See [SECURITY.md](SECURITY.md) for details on our security policy.

## License

[GNU GPLv3](LICENSE)
