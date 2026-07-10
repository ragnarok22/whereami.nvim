local stub = require('luassert.stub')
local whereami = require('whereami')
local curl = require('plenary.curl')

-- debug.getupvalue returns the upvalue name and value. We only want the value
local _, get_flag = debug.getupvalue(whereami.country, 2)

describe('whereami', function()
  it('returns proper flag emoji', function()
    assert.is_function(get_flag)
    assert.are.equal('🇺🇸', get_flag('US'))
  end)

  it('uses fallback icon when get_flag returns empty string', function()
    local curl_stub = stub(curl, 'get', function()
      return { body = '{"country":"US"}' }
    end)
    local notify_stub = stub(vim, 'notify')

    -- replace get_flag upvalue with stub that returns empty string
    local original = get_flag
    debug.setupvalue(whereami.country, 2, function()
      return ''
    end)

    whereami.country()

    assert.stub(vim.notify).was_called_with(
      'You are in 🌎US',
      vim.log.levels.INFO,
      { title = 'Where am I?', icon = '🌎' }
    )

    -- revert
    debug.setupvalue(whereami.country, 2, original)
    curl_stub:revert()
    notify_stub:revert()
  end)



  it('masks IP addresses when privacy mask_ip is enabled', function()
    local curl_stub = stub(curl, 'get', function()
      return { body = '{"ip":"203.0.113.42"}' }
    end)
    local notify_stub = stub(vim, 'notify')

    whereami.setup({ privacy = { mask_ip = true, hide_city = false, hide_isp = false } })
    whereami.ip()

    assert.stub(vim.notify).was_called_with(
      'You IP is 203.0.xxx.xxx',
      vim.log.levels.INFO,
      { title = 'Where am I?', icon = '❔' }
    )

    whereami.setup({ privacy = { mask_ip = false, hide_city = false, hide_isp = false } })
    curl_stub:revert()
    notify_stub:revert()
  end)

  it('hides city and ISP values when privacy options are enabled', function()
    local curl_stub = stub(curl, 'get', function()
      return { body = '{"city":"Springfield","org":"Example ISP"}' }
    end)
    local notify_stub = stub(vim, 'notify')

    whereami.setup({ privacy = { mask_ip = false, hide_city = true, hide_isp = true } })
    whereami.city()
    whereami.isp()

    assert.stub(vim.notify).was_called_with(
      'You are in hidden',
      vim.log.levels.INFO,
      { title = 'Where am I?', icon = '❔' }
    )
    assert.stub(vim.notify).was_called_with(
      'You ISP is hidden',
      vim.log.levels.INFO,
      { title = 'Where am I?', icon = '❔' }
    )

    whereami.setup({ privacy = { mask_ip = false, hide_city = false, hide_isp = false } })
    curl_stub:revert()
    notify_stub:revert()
  end)
end)
