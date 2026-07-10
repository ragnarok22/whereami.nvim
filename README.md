# Whereami.nvim

[![CI](https://github.com/ragnarok22/whereami.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/ragnarok22/whereami.nvim/actions/workflows/test.yml)
[![Neovim 0.9+](https://img.shields.io/badge/Neovim-0.9%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![License](https://img.shields.io/github/license/ragnarok22/whereami.nvim)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/ragnarok22/whereami.nvim?logo=github)](https://github.com/ragnarok22/whereami.nvim)
[![Last commit](https://img.shields.io/github/last-commit/ragnarok22/whereami.nvim?logo=github)](https://github.com/ragnarok22/whereami.nvim/commits/main)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ragnarok22/whereami.nvim)

Check the approximate location of your current public IP without leaving Neovim. Whereami.nvim is useful for confirming that a VPN is connected to the expected country, city, and network.

> [!NOTE]
> IP geolocation is approximate. It identifies the location associated with your public or VPN exit IP, not your exact physical location.

## Features

- Country code and flag notifications
- City, public IP, and network organization details
- Automatic fallback between location providers
- In-memory response caching and manual refreshes
- Optional display masking for private location fields
- Support for Neovim's built-in notifications and [nvim-notify](https://github.com/rcarriga/nvim-notify)

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Privacy and Network Behavior](#privacy-and-network-behavior)
- [Health Checks](#health-checks)
- [Development](#development)
- [Contributing and Security](#contributing-and-security)
- [License](#license)

## Installation

### Requirements

- Neovim 0.9 or newer
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Network access to the configured location providers
- An emoji-capable terminal and font for country flags (optional)

### lazy.nvim

```lua
{
  "ragnarok22/whereami.nvim",
  cmd = "Whereami",
  dependencies = { "nvim-lua/plenary.nvim" },
}
```

Whereami.nvim works with its defaults, so calling `setup()` is optional. To configure it with [lazy.nvim](https://github.com/folke/lazy.nvim), add an `opts` table:

```lua
{
  "ragnarok22/whereami.nvim",
  cmd = "Whereami",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    default_command = "all",
  },
}
```

### pckr.nvim

```lua
local cmd = require("pckr.loader.cmd")

require("pckr").add({
  {
    "ragnarok22/whereami.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    cond = cmd("Whereami"),
  },
})
```

### packer.nvim (legacy)

[packer.nvim](https://github.com/wbthomason/packer.nvim) is deprecated, but existing configurations can install Whereami.nvim with:

```lua
use({
  "ragnarok22/whereami.nvim",
  cmd = "Whereami",
  requires = { "nvim-lua/plenary.nvim" },
})
```

## Configuration

Call `setup()` to override any defaults. Each call resets unspecified options to their defaults and clears cached location data.

```lua
require("whereami").setup({
  default_command = "all",
  cache_ttl = 300000,
  privacy = {
    mask_ip = true,
    hide_city = false,
    hide_isp = false,
  },
})
```

### Options

| Option | Default | Description |
| --- | --- | --- |
| `provider_url` | `nil` | Use one provider URL instead of the default provider list. |
| `providers` | `nil` | A provider string, provider table, or ordered list of providers. |
| `timeout` | `5000` | Request timeout per provider, in milliseconds. |
| `default_command` | `"country"` | Notification shown by `:Whereami` and `whereami.whereami()`. Use `country`, `city`, `ip`, `isp`, or `all`. |
| `cache_ttl` | `300000` | Cache duration in milliseconds. Set to `0` to disable caching. |
| `notification.title` | `"Where am I?"` | Title passed to `vim.notify`. |
| `notification.icons.country_fallback` | `"🌎"` | Icon used when a country code is unavailable or invalid. |
| `notification.icons.default` | `"❔"` | Icon used for non-country notifications. |
| `privacy.mask_ip` | `false` | Mask part of the IP address in notifications. |
| `privacy.hide_city` | `false` | Display `hidden` instead of the city in notifications. |
| `privacy.hide_isp` | `false` | Display `hidden` instead of the network organization in notifications. |
| `hooks.before_request` | `nil` | Function called before a fresh provider request cycle. |
| `hooks.after_request` | `nil` | Function called after fresh location data is successfully accepted. |

### Notifications

Whereami.nvim uses `vim.notify`, so it works with Neovim's default notifications. To use [nvim-notify](https://github.com/rcarriga/nvim-notify) with lazy.nvim:

```lua
{
  "ragnarok22/whereami.nvim",
  cmd = "Whereami",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "rcarriga/nvim-notify",
      config = function()
        require("notify").setup({})
        vim.notify = require("notify")
      end,
    },
  },
}
```

### Providers

By default, Whereami.nvim tries [ipinfo.io](https://ipinfo.io/) and falls back to [ipapi.co](https://ipapi.co/) if the first provider fails or returns no usable location fields.

Use `provider_url` for one endpoint that returns at least one supported field: `ip`, `city`, `country`, or `org`.

```lua
require("whereami").setup({
  provider_url = "https://ipinfo.io/json",
})
```

For custom response formats, define an ordered provider list and normalize each response:

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

Each provider must define either:

- `url`: The JSON endpoint requested with `plenary.curl`.
- `fetch(config)`: A custom request function used instead of `url`.

Providers can also define `normalize(data)` to map their response to `ip`, `city`, `country`, and `org`. `provider_url` takes precedence over `providers`. Accepted data must contain at least one supported location field; without a normalizer, additional provider-specific fields are preserved.

### Request Hooks

Hooks run only for fresh requests, not cache hits:

```lua
require("whereami").setup({
  hooks = {
    before_request = function(config)
      vim.notify("Checking location with a " .. config.timeout .. " ms timeout")
    end,
    after_request = function(data, config)
      vim.notify("Location response received for " .. (data.ip or "unknown IP"))
    end,
  },
})
```

`before_request` runs once before the provider fallback cycle. `after_request` runs only after a provider returns accepted location data.

## Usage

Run `:Whereami` to show the configured default notification. The default is the country associated with your current public IP.

For a complete VPN check:

```vim
:Whereami all
```

To bypass cached data after connecting to a different VPN server:

```vim
:Whereami refresh
```

### Commands

| Command | Behavior |
| --- | --- |
| `:Whereami` | Run the configured `default_command`. |
| `:Whereami country` | Show the country code and flag. |
| `:Whereami city` | Show the approximate city. |
| `:Whereami ip` | Show the public IP address. |
| `:Whereami isp` | Show the network organization or ISP. |
| `:Whereami all` | Show country, city, IP address, and network organization. |
| `:Whereami json` | Print unmasked location data as JSON. |
| `:Whereami refresh` | Clear the cache, fetch fresh data, and show the country. |

### Lua API

```lua
local whereami = require("whereami")

whereami.whereami()   -- show the configured default notification
whereami.country()    -- show the country
whereami.city()       -- show the city
whereami.ip()         -- show the public IP
whereami.isp()        -- show the network organization
whereami.all()        -- show all location fields
whereami.clear_cache()

local data, err = whereami.get()
local fresh_data, refresh_err = whereami.refresh()
```

`get()` returns location data or `nil, error`. The default providers return the fields `ip`, `city`, `country`, and `org`; custom providers may preserve additional fields. `refresh()` clears the cache and returns freshly fetched data without displaying a success notification. Use `:Whereami refresh` when you want both a fresh request and visible output.

### Keymaps

```lua
local whereami = require("whereami")

vim.keymap.set("n", "<leader>vc", whereami.country, {
  desc = "Check VPN country",
})

vim.keymap.set("n", "<leader>va", whereami.all, {
  desc = "Check VPN location details",
})

vim.keymap.set("n", "<leader>vr", "<cmd>Whereami refresh<cr>", {
  desc = "Refresh VPN location",
})
```

## Privacy and Network Behavior

Whereami.nvim contacts a third-party IP geolocation provider when it needs fresh data.

- The provider receives your current public IP address and normal HTTP request metadata.
- Built-in requests do not send Neovim buffers, files, or editor configuration.
- IP geolocation is approximate and may report the provider's nearest known network location.
- Privacy options change notification output only. `whereami.get()` and `:Whereami json` return unmasked location data.
- Successful responses are cached in memory for five minutes by default and are never persisted between Neovim sessions.
- Provider requests are synchronous and use the configured timeout for each attempted provider.

Review the privacy policy and terms of every provider you configure. Use `cache_ttl = 0` to disable caching, `clear_cache()` to remove cached data, or `:Whereami refresh` to force a new request.

## Health Checks

Run the built-in health check when installation or requests are not working:

```vim
:checkhealth whereami
```

It verifies that `plenary.curl` is available, checks JSON decoding, reports information about `vim.notify`, and tests connectivity to `https://ipinfo.io/json`. The reachability check always uses ipinfo.io, even when a custom provider is configured.

If your plugin manager loads Whereami.nvim only for the `:Whereami` command, load the plugin first by running `:Whereami` or your manager's explicit load command.

## Development

### Setup

Clone [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) into the recommended repository-local dependency directory:

```bash
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim .deps/plenary.nvim
```

Alternatively, set `PLENARY_NVIM_PATH` to an existing checkout. The test bootstrap also recognizes `deps/plenary.nvim`, `tests/deps/plenary.nvim`, and standard lazy.nvim or native package locations.

### Checks

Run formatting and lint checks from the repository root:

```bash
stylua --check .
selene .
```

Run the Plenary test suite with the test bootstrap as Neovim's startup file:

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory lua/tests {minimal_init = 'tests/minimal_init.lua'}" +qa
```

Check README links with:

```bash
lychee --verbose --no-progress README.md
```

GitHub Actions runs these checks for pushes to `main` and for pull requests.

## Contributing and Security

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
- Follow the project [Code of Conduct](CODE_OF_CONDUCT.md).
- Report vulnerabilities according to [SECURITY.md](SECURITY.md).

## License

[GNU GPLv3](LICENSE)
