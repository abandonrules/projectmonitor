class TeamCityRestProject < Project
  include TeamCityBuildStatusParsing

  URL_FORMAT = /http:\/\/.*\/app\/rest\/builds\?locator=running:all,buildType:\(id:bt\d*\)(,user:(\w+))?(,personal:(true|false|any))?$/
  URL_MESSAGE = "should look like ('[...]' is optional): http://*/app/rest/builds?locator=running:all,buildType:(id:bt*)[,user:*][,personal:true|false|any]"

  validates_format_of :feed_url, :with => URL_FORMAT, :message => URL_MESSAGE

  def build_status_url
    feed_url
  end

  def parse_building_status(content)
    status = super(content)

    document = Nokogiri::XML.parse(content)
    p_element = document.css("build").first

    if p_element.present? && p_element.attribute('running').present?
      status.building = true
    end

    status
  end

  def parse_project_status(content)
    raise NotImplementedError, "TeamCityRestProject#parse_project_status is no longer used"
  end

  def process_status_update
    build_live_statuses.each do |parsed_status|
      parsed_status.save! unless statuses.find_by_url(parsed_status.url)
    end
  rescue Net::HTTPError => e
    error = "HTTP Error retrieving status for project '##{id}': #{e.message}"
    statuses.create(:error => error) unless status.error == error
  end

  def build_id
    feed_url.match(/id:([^)]*)/)[1]
  end

  protected

  def build_live_statuses
    live_status_hashes.map { |status_hash|
      ProjectStatus.new(
        :project => self,
        :online => true,
        :success => status_hash[:status] == 'SUCCESS',
        :url => status_hash[:url],
        :published_at => status_hash[:published_at],
      )
    }
  end
end
