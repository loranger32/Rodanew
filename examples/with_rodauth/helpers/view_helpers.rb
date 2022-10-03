module ViewHelpers
  def set_page_title(title)
    if title.nil? || title.empty?
      "with_rodauth"
    else
      "with_rodauth - #{title}"
    end
  end

  def format_auth_log_action(action)
    case action
    when "login" then "bg-success"
    when "logout" then "bg-warning"
    when "login_failure" then "bg-danger"
    else
      "bg-secondary"
    end
  end

  def truncate(str, index)
    str.length <= index ? str : str[0..index] + "..."
  end

  def view_helpers_connected?
    true
  end
end
