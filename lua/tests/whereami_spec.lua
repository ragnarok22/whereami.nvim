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

  it('returns raw data without notifying', function()
    local curl_stub = stub(curl, 'get', function()
      return { body = '{"ip":"127.0.0.1","city":"Localhost","country":"US","org":"Test ISP"}' }
    end)
    local notify_stub = stub(vim, 'notify')

    local data = whereami.get()

    assert.are.equal('127.0.0.1', data.ip)
    assert.are.equal('Localhost', data.city)
    assert.are.equal('US', data.country)
    assert.are.equal('Test ISP', data.org)
    assert.stub(vim.notify).was_not_called()

    curl_stub:revert()
    notify_stub:revert()
  end)
end)


