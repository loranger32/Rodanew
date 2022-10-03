require_relative "../test_helpers"

class With_rodauthIntegrationTest < CapybaraTestCase
  def before_all
    super
    clean_test_db!
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
  end

  def test_can_access_home_page
    visit "/"
    assert_current_path "/"
    assert_content "with_rodauth"
  end
end
