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
  it('defaults to country when no command argument is provided', function()
    local country_stub = stub(whereami, 'country')

    vim.cmd('Whereami')

    assert.stub(whereami.country).was_called(1)
    country_stub:revert()
  end)

  it('notifies when an unknown command argument is provided', function()
    local notify_stub = stub(vim, 'notify')
    local country_stub = stub(whereami, 'country')

    vim.cmd('Whereami foo')

    assert.stub(vim.notify).was_called_with(
      'Unknown option: foo\nAvailable options: country, city, ip, isp',
      vim.log.levels.WARN,
      { title = 'Where am I?' }
    )
    assert.stub(whereami.country).was_not_called()

    country_stub:revert()
    notify_stub:revert()
  end)
  it('notifies when trailing command arguments are provided after a known option', function()
    local notify_stub = stub(vim, 'notify')
    local country_stub = stub(whereami, 'country')

    vim.cmd('Whereami country foo')

    assert.stub(vim.notify).was_called_with(
      'Unknown option: foo\nAvailable options: country, city, ip, isp',
      vim.log.levels.WARN,
      { title = 'Where am I?' }
    )
    assert.stub(whereami.country).was_not_called()

    country_stub:revert()
    notify_stub:revert()
  end)

end)


