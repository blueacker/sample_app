require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
  end

  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: {  user: { name: "asdfadfsa",
                                          email: "user.invalid@dd.com",
                                          password: "foobar",
                                          password_confirmation: "bar" } }
    end
  end

  test "valid signup information with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: {  name: "Example User",
                                          email: "user1@rails.com",
                                          password: "foobar",
                                          password_confirmation: "foobar" } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user) # ??? what is this
    assert_not user.activated?
    log_in_as(user)
    assert_not is_logged_in?
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not is_logged_in?
    get edit_account_activation_path(user.activation_token, email: "wrong_email@email.com")
    assert_not is_logged_in?
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    assert is_logged_in?
    follow_redirect!
    assert_template 'users/show'
    assert_select ".alert-success", flash[:success]
  end
end
