module AppHelpers
  def format_flash_error(model)
    if model.errors.length >= 2
      model.errors.full_messages.map { |msg| "- #{msg}" }.join("\n")
    else
      model.errors.full_messages[0]
    end
  end

  def app_helpers_connected?
    true
  end
end
