require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "sign up" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_selector "#flash_notice", text: "A confirmation mail has been sent to your email address."
    assert_event Events::UserEvent::CREATED, { email: "email@person.com" },
      User.find_by(handle: "nick").events.where(tag: Events::UserEvent::CREATED).sole
  end

  test "sign up stores original email casing" do
    visit sign_up_path

    fill_in "Email", with: "Email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_selector "#flash_notice", text: "A confirmation mail has been sent to your email address."

    assert_equal "Email@person.com", User.last.email
  end

  test "sign up with no handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_text "errors prohibited"
  end

  test "sign up with bad handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "thisusernameiswaytoolongseriouslywaytoolong"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_text "error prohibited"
  end

  test "sign up with someone else's handle" do
    create(:user, handle: "nick")
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_text "error prohibited"
  end

  test "sign up when sign up is disabled" do
    Clearance.configure { |config| config.allow_sign_up = false }
    Rails.application.reload_routes!

    visit root_path

    refute_text "Sign up"
    assert_raises(ActionController::RoutingError) do
      visit "/sign_up"
    end
  end

  test "sign up when user param is string" do
    assert_nothing_raised do
      visit "/sign_up?user=JJJ12QQQ"
    end
  end

  test "email confirmation" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Sign up"
    end

    confirmation_link = URI.parse(last_email_link)
    visit confirmation_link.request_uri

    assert_text "Sign in"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"

    fill_in "Email or Username", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert_text "Dashboard"
  end

  teardown do
    Clearance.configure { |config| config.allow_sign_up = true }
    Rails.application.reload_routes!
  end
end
