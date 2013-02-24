require 'spec_helper'

describe "projects/new" do

  before do
    @project = Project.new
  end

  it "should include the server time" do
    Time.stub(:now).and_return(Time.parse("Wed Oct 26 17:02:10 -0700 2011"))
    render
    rendered.should include("Server time is #{Time.now.to_s}")
  end

  it 'should render all the project specific fields as hidden' do
    render
    rendered.should have_css('fieldset#CruiseControlProject.hide')
    rendered.should have_css('fieldset#JenkinsProject.hide')
    rendered.should have_css('fieldset#TeamCityRestProject.hide')
    rendered.should have_css('fieldset#TeamCityProject.hide')
    rendered.should have_css('fieldset#TravisProject.hide')

    rendered.should have_css('fieldset#build_setup #branch_name.hide')
  end

end
