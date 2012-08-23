require 'spec_helper'
require 'time'

describe ProjectsController do
  describe "without a logged in user" do
    describe "status" do
      let(:project) { projects(:socialitis) }
      before { get :status, :id => project.id, :tiles_count => 8 }

      it "should render dashboards/_project" do
        response.should render_template("dashboards/_project")
      end
    end
  end

  describe "with a logged in user" do
    before do
      sign_in FactoryGirl.create(:user)
    end

    context "when nested under an aggregate project" do
      it "should scope by aggregate_project_id" do
        Project.should_receive(:with_aggregate_project).with('1')
        get :index, aggregate_project_id: 1
      end
    end

    describe "create" do
      context "when the project was successfully created" do
        subject do
          post :create, :project => {
            :name => 'name',
            :type => JenkinsProject.name,
            :jenkins_base_url => 'http://www.example.com',
            :jenkins_build_name => 'example'
          }
        end

        it "should create a project of the correct type" do
          lambda { subject }.should change(JenkinsProject, :count).by(1)
        end

        it "should set the flash" do
          subject
          flash[:notice].should == 'Project was successfully created.'
        end

        it { should redirect_to edit_configuration_path }
      end

      context "when the project was not successfully created" do
        before { post :create, :project => { :name => nil, :type => JenkinsProject.name} }
        it { should render_template :new }
      end
    end

    describe "update" do
      context "when the project was successfully updated" do
        before { put :update, :id => projects(:jenkins_project), :project => { :name => "new name" } }

        it "should set the flash" do
          flash[:notice].should == 'Project was successfully updated.'
        end

        it { should redirect_to edit_configuration_path }
      end

      context "when the project was not successfully updated" do
        before { put :update, :id => projects(:jenkins_project), :project => { :name => nil } }
        it { should render_template :edit }
      end


      describe "feed password" do

        describe "posting empty feed password" do
          [nil, '', "", []].each do |empty|
            before { put :update, :id => project.id, :project => { :name => "new name", auth_password: empty } }
            subject { response }
            context "when there is already a feed password" do
              let(:project) { FactoryGirl.create(:jenkins_project, auth_password: 'google') }
              it "should preserve the feed password" do
                subject
                project.reload.auth_password.should == 'google'
              end
            end
          end
        end

        describe "posting valid feed password" do
          before { put :update, :id => project.id, :project => { :name => "new name", auth_password: 'google' } }
          let(:project) { FactoryGirl.create(:jenkins_project, auth_password: 'froogle') }
          it "should update the feed password" do
            subject
            project.reload.auth_password.should == 'google'
          end
        end

      end

      describe "changing STI type" do
        subject { put :update, "id"=> project.id, "project" => project_params }
        let!(:project) { FactoryGirl.create(:team_city_project) }

        context "when the parameters are valid" do
          let(:project_params) { {"type"=>"JenkinsProject", name: "foobar", "jenkins_base_url"=>"http://foo", "jenkins_build_name"=>"NAMe"} }
          it "should validate as the new type and save the record" do
            subject
            (Project.find(project.id).is_a? JenkinsProject).should be_true
          end
        end

        context "when the parameters are not valid" do

          let(:project_params) { {"type"=>"JenkinsProject", "jenkins_build_name"=>"NAMe"} }
          it "should validate as the new type and save the record" do
            subject
            (Project.find(project.id).is_a? TeamCityProject).should be_true
          end
        end
      end
    end

    describe "destroy" do
      subject { delete :destroy, :id => projects(:jenkins_project) }

      it "should destroy the project" do
        lambda { subject }.should change(JenkinsProject, :count).by(-1)
      end

      it "should set the flash" do
        subject
        flash[:notice].should == 'Project was successfully destroyed.'
      end

      it { should redirect_to edit_configuration_path }
    end

    describe "#validate_tracker_project" do
      it "should enqueue a job" do
        project = projects(:jenkins_project)
        TrackerProjectValidator.should_receive(:delay) { TrackerProjectValidator }
        TrackerProjectValidator.should_receive :validate
        post :validate_tracker_project, { auth_token: "12354", project_id: "98765", id: project.id }
      end
    end

    describe '#validate_build_info' do
      before(:each) { ProjectUpdater.should_receive(:update).and_return(log_entry) }
      let(:parsed_response) { JSON.parse(post(:validate_build_info, {project: {type: TravisProject}}).body)}

      context 'when the payload is invalid' do

        let(:log_entry) { PayloadLogEntry.new(status: 'failed', error_type: 'MockExceptionClass', error_text: error_text) }
        let(:error_text) { 'Mock error description'}

        context 'should set success flag to true' do
          subject { parsed_response['status'] }
          it { should be_false }
        end

        context 'should set error_class to correct exception' do
          subject { parsed_response['error_type'] }
          it { should == 'MockExceptionClass' }
        end

        context 'should set error_text to correct text' do
          subject { parsed_response['error_text'] }
          context 'with a short description' do
            it { should == 'Mock error description' }
          end

          context 'with a long description' do
            let(:error_text) { 'a'*50000 }
            it { should == 'a'*10000 }
          end
        end
      end

      context 'when the payload is valid' do
        let(:log_entry) { PayloadLogEntry.new(status: 'successful', error_type: nil, error_text: '') }

        context 'should set success flag to false' do
          subject { parsed_response['status'] }
          it { should be_true }
        end

        context 'should set error_class to nil' do
          subject { parsed_response['error_type'] }
          it { should be_nil }
        end

        context 'should set error_text to empty string' do
          subject { parsed_response['error_text'] }
          it { should == '' }
        end
      end

    end

    describe "#update_projects" do
      context "The queue is empty" do
        before do
          Delayed::Job.should_receive(:count) { stub(zero?: true) }
          StatusFetcher.should_receive(:fetch_all)
        end
        it "should fetch statuses" do
          post :update_projects, { auth_token: "12354" }
          response.should be_success
        end
      end
      context "The queue is not empty" do
        before do
          Delayed::Job.should_receive(:count) { stub(zero?: false) }
          StatusFetcher.should_not_receive(:fetch_all)
        end
        it "should fetch statuses" do
          post :update_projects, { auth_token: "12354" }
          response.response_code.should == 409
        end
      end
    end

  end
end
