local stub = require('luassert.stub')
local whereami = require('whereami')
local curl = require('plenary.curl')

-- get reference to the local get_flag function via debug upvalue
local get_flag = debug.getupvalue(whereami.country, 2)

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
end)


