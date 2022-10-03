module ViewHelpers
  def set_page_title(title)
    if title.nil? || title.empty?
      "without_rodauth"
    else
      "without_rodauth - #{title}"
    end
  end

  def truncate(str, index)
    str.length <= index ? str : str[0..index] + "..."
  end

  def view_helpers_connected?
    true
  end
end
