module StatusFetcher
  class Job < Struct.new(:project)
    def perform
      retrieve_status
      retrieve_building_status
      retrieve_tracker_status

      project.set_next_poll!
    end

    private

    def retrieve_status
      StatusFetcher.retrieve_status_for(project)
    end

    def retrieve_building_status
      StatusFetcher.retrieve_building_status_for(project)
    end

    def retrieve_tracker_status
      StatusFetcher.retrieve_tracker_status_for(project)
    end
  end

  class << self
    def fetch_all
      projects = Project.all.select(&:needs_poll?)
      projects.each do |project|
        Delayed::Job.enqueue StatusFetcher::Job.new(project)
      end
    end

    def retrieve_status_for(project)
      project.process_status_update
    end

    def retrieve_building_status_for(project)
      content = UrlRetriever.retrieve_content_at(project.build_status_url, project.auth_username, project.auth_password)
      status = project.parse_building_status(content)
      project.update_attribute(:building, status.building?)
    rescue Net::HTTPError => e
      project.update_attribute(:building, false)
    end

    def retrieve_tracker_status_for(project)
      return unless project.tracker_project?

      tracker = TrackerApi.new(project.tracker_auth_token)
      project.tracker_num_unaccepted_stories = tracker.delivered_story_count(project.tracker_project_id)
    end
  end
end

