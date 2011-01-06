class DashboardsController < ApplicationController
  def show
    if params[:tags]
      aggregate_projects = AggregateProject.find_tagged_with(params[:tags], :conditions => {:enabled => true})
      projects = Project.find_tagged_with(params[:tags], :conditions => {:enabled => true}, :include => :statuses)
      @projects = (projects.reject {|project| aggregate_projects.include?(project.aggregate_project)} + aggregate_projects).sort{|project_a, project_b| project_a.name <=> project_b.name}
    else
      @projects = Project.standalone
      @projects += AggregateProject.with_projects.flatten
      @projects = @projects.sort{|project_a, project_b| project_a.name <=> project_b.name}
    end

    @messages = Message.all
  end
end
