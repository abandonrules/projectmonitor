require 'spec_helper'

describe ProjectDecorator do
  describe "#css_id" do
    let(:id) { "123" }
    subject { ProjectDecorator.new(project).css_id }

    before { project.stub(:id => id)}

    context "when Project" do
      let(:project) { CruiseControlProject.new }

      it { should == "project_#{id}"}
    end

    context "when AggregateProject" do
      let(:project) { AggregateProject.new }

      it { should == "aggregate_project_#{id}"}
    end

  end

  describe "#css_class" do
    subject { ProjectDecorator.new(project).css_class }
    let(:project) { double :project, red?: red, green?: green }
    let(:red) { false }
    let(:green) { false }

    context "project is red" do
      let(:red) { true }
      it { should == "project failure"}
    end

    context "project is green" do
      let(:green) { true }
      it { should == "project success"}
    end

    context "project is neither red nor green" do
      let(:project) { double :project, red?: false, green?: false }
      it { should == "project offline"}
    end

    context "project is aggregate" do
      before do
        project.stub :projects
      end

      it { should include "aggregate"}
    end
  end

  describe "#time_since_last_build" do
    let(:project_decorator) { ProjectDecorator.new project }
    let(:project) { Project.new }

    subject { project_decorator.time_since_last_build }

    context "project has no latest status" do
      it { should be_nil }
    end

    context "project has a latest status" do
      let(:published_at_time) { Time.now }
      before do
        project.stub(:latest_status).and_return(
          double(:latest_status, published_at: published_at_time)
        )
      end

      let(:time_distance) { [1,2].sample }

      context "< 60 seconds ago" do
        let(:published_at_time) { time_distance.second.ago }

        it { should == "#{time_distance}s"}
      end

      context "< 60 minutes ago" do
        let(:published_at_time) { time_distance.minute.ago }

        it { should == "#{time_distance}m"}
      end
      context "< 1 day ago" do
        let(:published_at_time) { time_distance.hour.ago }

        it { should == "#{time_distance}h"}
      end

      context ">= 1 day ago" do
        let(:published_at_time) { time_distance.days.ago }

        it { should == "#{time_distance}d"}
      end
    end
  end
end
