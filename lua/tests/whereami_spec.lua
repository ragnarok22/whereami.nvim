local stub = require('luassert.stub')
local whereami = require('whereami')
local flag = require('whereami.flag')
local curl = require('plenary.curl')

describe('whereami', function()
  it('returns proper flag emoji', function()
    assert.are.equal('🇺🇸', flag.get_flag('US'))
  end)

  it('uppercases country codes before generating flags', function()
    assert.are.equal('🇺🇸', flag.get_flag('us'))
  end)

  it('uses fallback icon for missing country codes', function()
    assert.are.equal('🌎', flag.get_flag(nil))
  end)

  it('uses fallback icon for empty country codes', function()
    assert.are.equal('🌎', flag.get_flag(''))
  end)

  it('uses fallback icon for invalid country codes', function()
    assert.are.equal('🌎', flag.get_flag('USA'))
    assert.are.equal('🌎', flag.get_flag('U1'))
  end)

  it('uses fallback icon when provider omits country', function()
    local curl_stub = stub(curl, 'get', function()
      return { body = '{}' }
    end)
    local notify_stub = stub(vim, 'notify')

    whereami.country()

    assert.stub(vim.notify).was_called_with(
      'You are in 🌎unknown',
      vim.log.levels.INFO,
      { title = 'Where am I?', icon = '🌎' }
    )

    curl_stub:revert()
    notify_stub:revert()
  end)
end)
