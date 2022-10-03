require_relative "../test_helpers"

class With_rodauthTest < HookedTestClass
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

  def test_it_works
    assert true
  end
end
