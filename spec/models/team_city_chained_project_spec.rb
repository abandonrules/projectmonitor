require 'spec_helper'

describe TeamCityChainedProject do
  let(:feed_url) { "http://localhost:8111/app/rest/builds?locator=running:all,buildType:(id:#{build_id})" }
  let(:build_id) { "bt1" }
  let(:project) {
    TeamCityChainedProject.new(
      :name => 'TeamCityproject',
      :feed_url => feed_url,
      :auth_username => "john",
      :auth_password => "secret"
    )
  }

  describe "#process_status_update" do
    before do
      project.save!
    end

    def process_status_update
      project.process_status_update
      project.reload
    end

    context "project status can not be retrieved from remote source" do
      let(:project_status) { double('project status') }
      before do
        UrlRetriever.stub(:retrieve_content_at).and_raise Net::HTTPError.new("can't do it", 500)
        project.stub(:status).and_return project_status
        project.stub(:statuses).and_return(double('statuses'))
      end

      context "a status does not exist with the error that is returned" do
        before do
          project_status.stub(:error).and_return "another error"
        end

        it "creates a status with the error message" do
          project.statuses.should_receive(:create)
          process_status_update
        end
      end

      context "a status exists with the error that is returned" do
        before do
          project_status.stub(:error).and_return "HTTP Error retrieving status for project '##{project.id}': can't do it"
        end

        it "does not create a duplicate status" do
          project.statuses.should_not_receive(:create)
          process_status_update
        end
      end
    end

    context "project status can be retrieved" do
      before do
        UrlRetriever.stub(:retrieve_content_at).and_return(xml_text)
      end

      let(:now) { Time.current }

      before do
        Clock.stub(:now).and_return(now)
      end

      let(:start_time) { 1.hour.ago }
      let(:xml_text) {
        <<-XML.strip_heredoc
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <builds count="1">
            <build id="1" number="1" status="#{build_status}" webUrl="/123" startDate="#{start_time.iso8601}" />
          </builds>
        XML
      }

      context "when the build is failing" do
        let(:build_status) { 'FAILURE' }

        it "creates a failing status" do
          process_status_update
          project.latest_status.should_not be_success
        end

        it "gives the status the project's last build time" do
          process_status_update
          project.latest_status.published_at.to_i.should == start_time.to_i
        end
      end

      context "when the build is passing, but one of its child builds is failing" do
        let(:build_status) { 'SUCCESS' }

        before do
          TeamCityChildBuilder.stub(:parse).with(project, anything).and_return([
            double('project child', red?: false, last_build_time: start_time + 1.hour),
            double('project child', red?: true, last_build_time: start_time)
          ])
        end

        it "creates a failing status" do
          process_status_update
          project.latest_status.should_not be_success
        end

        it "gives the status the most recent build time" do
          process_status_update
          project.latest_status.published_at.to_i.should == (start_time + 1.hour).to_i
        end
      end

      context "when the most recent build status is UNKNOWN" do
        let(:xml_text) {
          <<-XML.strip_heredoc
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <builds count="2">
            <build id="2" number="2" status="UNKNOWN" webUrl="/456" />
            <build id="1" number="1" status="#{build_status}" webUrl="/123" />
          </builds>
          XML
        }

        context "and the previous build is red" do
          let(:build_status) { 'FAILURE' }

          it "should not be successful" do
            process_status_update
            project.reload.latest_status.should_not be_success
          end
        end

        context "and the previous build is green" do
          let(:build_status) { 'SUCCESS' }

          it "should be successful" do
            process_status_update
            project.reload.latest_status.should be_success
          end
        end
      end

      describe "when no builds have happened since the last status was created" do
        before do
          project.statuses.create!(online: true, success: false, url: '/456', published_at: last_build_time)
          project.reload
          TeamCityChildBuilder.stub(:parse).with(project, anything).and_return(children)
        end

        let(:last_build_time) { 5.minutes.ago }
        let(:xml_text) {
          <<-XML.strip_heredoc
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <builds count="2">
            <build id="2" number="2" status="SUCCESS" webUrl="/456" startDate="#{last_build_time.iso8601}" />
            <build id="1" number="1" status="FAILURE" webUrl="/123" startDate="#{(last_build_time - 5.minutes).iso8601}" />
          </builds>
          XML
        }
        let(:children) {[
          double('project child', red?: false, last_build_time: last_build_time - 1.minute),
          double('project child', red?: true, last_build_time: last_build_time - 2.minutes)
        ]}

        it "should not create a new status" do
          expect { process_status_update }.to_not change(project.statuses, :count)
        end

      end
    end
  end

  describe "#build_id" do
    it "should use the build id in the feed_url" do
      project.build_id.should == build_id
    end
  end
end
