require File.dirname(__FILE__) + '/../spec_helper'

class SvnSheller
  def retrieve
    File.read('test/fixtures/svn_log_examples/svn.xml')
  end
end

describe CiMonitorController do
  integrate_views

  describe "routes" do
    it "should map /cimontor to #show" do
      params_from(:get, "/cimonitor").should == {:controller => "ci_monitor", :action => "show"}
    end

    it "should map /builds to #show" do
      params_from(:get, "/builds").should == {:controller => "ci_monitor", :action => "show"}
    end

    it "should map #show to /cimonitor by default" do
      route_for(:controller => "ci_monitor", :action => "show").should == "/cimonitor"
    end
  end

  describe "#show" do
    it "should succeed" do
      get :show
      response.should be_success
    end

    it "should filter by tag" do
      nyc_projects = Project.find_tagged_with('NYC')
      nyc_projects.should_not be_empty

      get :show, :size => 'tiny', :tags => 'NYC'
      assigns(:projects).should contain_exactly(nyc_projects)
    end

    it "should sort the projects by name" do
      sorted_projects = Project.find(:all, :conditions => {:enabled => true}).sort_by(&:name)
      get :show
      assigns(:projects).should == sorted_projects
    end

    it "should not store the most recent request location" do
      session[:location] = nil
      get :show
      session[:location].should be_nil
    end

    it "should display a red spinner for red building projects" do
      get :show
      building_projects = Project.find(:all, :conditions => {:enabled => true, :building => true}).reject(&:green?)
      building_projects.should_not be_empty
      building_projects.each do |project|
        response.should have_tag("div.box[project_id='#{project.id}']") do |box|
          box.should have_tag("img", :src => "build-loader-red.gif")
        end
      end
    end

    it "should display a green spinner for green building projects" do
      get :show
      green_building_projects = Project.find(:all, :conditions => {:enabled => true, :building => true}).select(&:green?)
      green_building_projects.should_not be_empty
      green_building_projects.each do |project|
        response.should have_tag("div.box[project_id='#{project.id}']") do |box|
          box.should have_tag("img", :src => "build-loader-green.gif")
        end
      end
    end

    it "should display a checkmark for green projects not building" do
      get :show
      not_building_projects = Project.find_all_by_enabled(true).reject(&:building?)
      not_building_projects.should_not be_empty
      not_building_projects.each do |project|
        response.should have_tag("div.box[project_id='#{project.id}']") do |box|
          box.should have_tag("img", :src => "checkmark.png")
        end
      end
    end
    
    it "should display an exclamation for red projects not building" do
      get :show
      not_building_projects = Project.find_all_by_enabled(true).reject(&:building?)
      not_building_projects.should_not be_empty
      not_building_projects.each do |project|
        response.should have_tag("div.box[project_id='#{project.id}']") do |box|
          box.should have_tag("img", :src => "exclamation.png")
        end
      end
    end

    it "should include an alternate rss link" do
      get :show
      response.should have_tag("head") do
        with_tag('link[href=http://test.host/builds.rss][rel=alternate][title=RSS][type=application/rss+xml]')
      end
    end

    context "when the format is rss" do
      before do
        get :show, :format => :rss
        response.should be_success
      end

      it "should respond with valid rss" do
        response.body.should include('<?xml version="1.0" encoding="UTF-8"?>')
        response.should have_tag('rss[version="2.0"]') do
          with_tag("channel") do
            with_tag("title", "Pivotal Labs CI")
            with_tag("link", "http://test.host/")
            with_tag("description", "Most recent builds and their status")
            with_tag("item")
          end
        end
      end

      describe "items" do
        before do
          @all_projects = Project.find(:all, :conditions => {:enabled => true})
          @all_projects.should_not be_empty
        end

        it "should have a valid item for each project" do
          @all_projects.each do |project|
            response.should have_tag('rss channel item') do
             with_tag("title", project.name)
             with_tag("link", project.status.url)
             with_tag("description")
             with_tag("pubDate", project.status.published_at.to_s)
           end
          end
        end

        context "when the project is green" do
          before do
            @project = @all_projects.find(&:green?)
          end

          it "should include the last built date in the description" do
            response.should have_tag("rss channel item") do
              with_tag("title", @project.name)
              with_tag("description", /Last built/)
            end
          end
        end

        context "when the project is red" do
          before do
            @project = @all_projects.find(&:red?)
          end

          it "should include the last built date and the oldest failure date in the description" do
            response.should have_tag("rss channel item") do
              with_tag("title", @project.name)
              with_tag("description", /Last built/)
              with_tag("description", /Red since/)
            end
          end
        end

        context "when the project is blue" do
          before do
            @project = @all_projects.reject(&:online?).last
          end

          it "should indicate that it's inaccessible in the description" do
            response.should have_tag("rss channel item") do
              with_tag("title", @project.name)
              with_tag("description", 'Could not retrieve status.')
            end
          end
        end
      end
    end
  end
end
