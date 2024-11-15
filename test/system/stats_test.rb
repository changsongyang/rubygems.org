require "application_system_test_case"

class StatsTest < ApplicationSystemTestCase
  setup do
    @rubygem = create(:rubygem, number: "0.0.1", downloads: 100)
  end

  test "downloads animation bar" do
    visit stats_path

    assert find(".stats__graph__gem__meter", wait: Capybara.default_max_wait_time)
    assert_text(@rubygem.downloads)
  end
end
