require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: {
                                  user: {
                                    name: "asdfadfsa",
                                    email: "user.invalid@dd.com",
                                    password: "foobar",
                                    password_confirmation: "bar"
                                  }
                                }
    end
  end

  test "valid signup information" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: {
                                  user: {
                                    name: "user1",
                                    email: "user1@rails.com",
                                    password: "foobar",
                                    password_confirmation: "foobar"
                                  }
                                }
    end
    follow_redirect!
    assert_template 'users/show'
    assert_select ".alert-success", flash[:success]
  end
end
