require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # invalid email
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # valid email
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url

    # 什么时候用 这个user, 而不是 @user
    user = assigns(:user)
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url

    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)

    # right email, wrong reset token
    get edit_password_reset_path('wrong token',   email: user.email)
    assert_redirected_to root_url

    # right email, right reset token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email

    # unmatched password confirmation, strange failed
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password: "asffads",
                            password_confirmation: "baasdf" } }
    assert_select 'div.error_explanation'

    # empty password and empty password_confirmation, strange failed
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password: "",
                            password_confirmation: "" } }
    assert_select 'div.error_explanation'

    # right password and right password_confirmation
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password: "asffads",
                            password_confirmation: "asffads" } }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    user.reload
    assert_nil user.reset_digest
    assert_nil user.reset_send_at
  end

  test "expired token" do
    get new_password_reset_path
    post password_resets_path, params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    @user.update_attribute(:reset_send_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
          params: { email: @user.email,
                    user: { password: "foobar",
                            password_confirmation: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_match /Password reset has expired./i, response.body
  end
end
