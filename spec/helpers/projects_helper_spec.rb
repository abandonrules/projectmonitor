require 'spec_helper'

describe ProjectsHelper do

  describe '#project_types' do
    subject { helper.project_types }
    it do
      should == [['', ''],
                 ['Cruise Control Project', 'CruiseControlProject'],
                 ['Jenkins Project', 'JenkinsProject'],
                 ['Semaphore Project', 'SemaphoreProject'],
                 ['Team City Project', 'TeamCityRestProject'],
                 ['Team City Project (version <= 6)', 'TeamCityProject'],
                 ['Travis Project', 'TravisProject']]
    end
  end

  describe "#project_webhooks_url" do
    subject { helper.project_webhooks_url(project) }

    context "when the project has a guid" do
      let(:project) { FactoryGirl.build(:project) }
      before { project.save }
      it { should include project.guid }
    end

    context "when the project lacks a guid" do
      let!(:project) { FactoryGirl.create(:project) }
      before { project.tap {|p| p.guid = nil}.save! }

      it "should display a message and generate a guid" do
        project.should_receive :generate_guid
        project.should_receive :save!
        subject.should == "not yet configured"
      end
    end
  end

  describe '#project_status_link' do
    context 'the status_url is not blank' do
      let(:code) { double }
      let(:url) { double }
      let(:project) { double(:project, status_url: url, code: code)}

      it 'renders a link to the status_url using the link helper' do
        helper.should_receive(:link_to).with(code, url)
        helper.project_status_link(project)
      end
    end

    context 'the status_url is blank' do
      let(:project) { double(:project, status_url: '', code: 'AOG') }

      it 'returns the project code' do
        helper.project_status_link(project).should == 'AOG'
      end
    end
  end

end
