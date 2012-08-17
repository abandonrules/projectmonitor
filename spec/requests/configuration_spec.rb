require 'spec_helper'

feature 'configuration export' do
  let(:archived_project_name) { Faker::Name.name }

  before do
    FactoryGirl.create(:aggregate_project)
    FactoryGirl.create(:jenkins_project, name: archived_project_name)

    log_in
  end

  scenario 'obtain a configuration export' do
    visit configuration_path(format: 'txt')

    configuration = YAML.load page.source
    configuration.should have_key('aggregate_projects')
    configuration.should have_key('projects')
    project_names = configuration['projects'].map {|project| project['name']}
    project_names.should include(archived_project_name)
  end

end
