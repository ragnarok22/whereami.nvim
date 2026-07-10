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


## Configuration

`whereami.nvim` works without configuration, but you can call `setup(opts)` to
override provider fallback behavior, request timeout, notification metadata, default
command behavior, cache TTL, or request hooks.

```lua
require("whereami").setup({
  -- Use one provider URL, or omit this to keep the default ipinfo/ipapi fallback list.
  provider_url = "https://ipinfo.io/json",
})
```

Or define a custom provider or ordered provider list. Each provider can expose
`url`, `fetch(config)`, and `normalize(data)`.

```lua
require("whereami").setup({
  providers = {
    { url = "https://ipinfo.io/json" },
    {
      url = "https://ipapi.co/json/",
      normalize = function(data)
        return {
          ip = data.ip,
          city = data.city,
          country = data.country_code,
          org = data.org or data.asn,
        }
      end,
    },
  },
})
```

Other options can be combined with either provider style:

```lua
require("whereami").setup({
  -- Request timeout passed to plenary.curl, in milliseconds.
  timeout = 5000,

  notification = {
    title = "Where am I?",
    icons = {
      country_fallback = "🌎",
      default = "❔",
    },
  },

  -- Used by `:Whereami` with no argument and by `require("whereami").whereami()`.
  default_command = "country",

  -- Cache provider responses for this many milliseconds. Set to 0 to disable.
  cache_ttl = 300000,

  privacy = {
    mask_ip = false,
    hide_city = false,
    hide_isp = false,
  },

  hooks = {
    before_request = function(config)
      -- Runs before a provider request.
    end,
    after_request = function(data, config)
      -- Runs after a fresh provider response is decoded.
    end,
  },
})
```

### Privacy mode

The privacy options affect notification output from `:Whereami ip`,
`:Whereami city`, `:Whereami isp`, and `:Whereami all`. With `mask_ip`
enabled, an IPv4 address such as `203.0.113.42` is displayed as
`203.0.xxx.xxx`; IPv6 addresses retain only their first two groups. Set
`hide_city` or `hide_isp` to `true` to display `hidden` instead.

`whereami.get()` and `:Whereami json` continue to return raw normalized data
for scripting, even when notification privacy options are enabled.

## Usage

You can use the command or the API

### Command

Run `:Whereami` to display the country you are in.

You can also provide an argument:

- `:Whereami country`: Show the country location where your request originated from.
- `:Whereami all`: Show a summary with country, city, IP address, and ISP.
- `:Whereami city`: Show the city location where your request originated from.
- `:Whereami ip`: Show the IP address where your request originated from.
- `:Whereami isp`: Show your current internet service provider.
- `:Whereami json`: Print the raw location data as JSON.
- `:Whereami refresh`: Clear cached location data, fetch fresh data, then show the country.

### Health checks

Run `:checkhealth whereami` to verify that `plenary.curl` is available, JSON
decoding works, `vim.notify` customization is detected, and the default location
provider can be reached.

### API

You can also use the methods, for example for key bindings

```lua
local whereami = require("whereami")
whereami.country() -- show the country
whereami.all() -- show country, city, IP, and ISP
whereami.city() -- show the city
whereami.ip() -- show the IP
whereami.isp() -- show the ISP
whereami.clear_cache() -- clear cached provider data
whereami.refresh() -- fetch fresh provider data

local data = whereami.get() -- return raw structured location data without notifying

-- set keymaps
vim.keymap.set("n", "<leader>l", whereami.country, { desc = "Show the country" })
vim.keymap.set("n", "<leader>e", whereami.city, { desc = "Show the city" })
vim.keymap.set("n", "<leader>i", whereami.ip, { desc = "Show the ip" })
vim.keymap.set("n", "<leader>s", whereami.isp, { desc = "Show the ISP" })
```


## Privacy and providers

Whereami.nvim contacts a third-party IP geolocation provider when it needs fresh
location data. By default, it tries `ipinfo.io` first and falls back to
`ipapi.co` if the first provider fails or returns unusable data.

- **Data sent:** each HTTP request originates from your current network
  connection, so the contacted provider receives the source IP address and
  normal HTTP request metadata. Whereami.nvim does not send your Neovim buffers,
  files, editor configuration, or any extra location data.
- **Provider configuration:** you can replace the defaults with `provider_url`
  or an ordered `providers` list. Review the privacy policy and terms of every
  provider you configure if you have specific privacy or compliance requirements.
- **Local caching:** successful responses are cached in memory for five minutes
  by default. Use `cache_ttl` to change the duration or set it to `0` to disable
  caching. `clear_cache()` removes cached data, while `refresh()` forces a fresh
  provider request. Cached data is not persisted between Neovim sessions.

## Testing

The plugin uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for
its test suite. The test bootstrap in `tests/minimal_init.lua` adds this plugin
and common plenary checkout locations to Neovim's runtimepath.

For local development, install Neovim and make plenary available in one of these
ways:

- Set `PLENARY_NVIM_PATH` to a plenary.nvim checkout. This is the recommended
  option for CI because the dependency path is explicit.
- Clone plenary.nvim into `.deps/plenary.nvim`, `deps/plenary.nvim`, or
  `tests/deps/plenary.nvim` under this repository.
- Install plenary.nvim with a package manager that checks it out to a standard
  location such as `stdpath("data") .. "/lazy/plenary.nvim"` or
  `stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"`.

Example local setup with a repository-local checkout:

```bash
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim .deps/plenary.nvim
```

Run the tests from the project root with:

```bash
nvim --headless -c "PlenaryBustedDirectory lua/tests {minimal_init = 'tests/minimal_init.lua'}" +qa
```

The command requires Neovim and plenary.nvim to be installed. If plenary is not
in one of the default locations above, pass it explicitly:

```bash
PLENARY_NVIM_PATH=/path/to/plenary.nvim nvim --headless -c "PlenaryBustedDirectory lua/tests {minimal_init = 'tests/minimal_init.lua'}" +qa
```

See [SECURITY.md](SECURITY.md) for details on our security policy.

## License

[GNU GPLv3](LICENSE)
