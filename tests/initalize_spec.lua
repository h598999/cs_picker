describe("cs_picker setup", function()
  local cs_picker = require("cs_picker")

  it("exposes a setup function", function()
    assert.is_function(cs_picker.setup)
  end)

  it("exposes get_state", function()
    assert.is_function(cs_picker.get_state)
    local state = cs_picker.get_state()
    assert.is_table(state)
  end)

  it("initializes without error", function()
    local ok, err = pcall(cs_picker.setup, {})
    assert.is_true(ok, err)
  end)
end)
