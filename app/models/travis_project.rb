class TravisProject < Project

  attr_accessible :travis_github_account, :travis_repository, :build_branch
  validates_presence_of :travis_github_account, :travis_repository, unless: ->(project) { project.webhooks_enabled }

  BASE_API_URL = "https://api.travis-ci.org"
  BASE_WEB_URL = "https://travis-ci.org"

  def feed_url
    "#{base_url}/builds.json"
  end

  def build_status_url
    feed_url
  end

  def current_build_url
    "#{BASE_WEB_URL}/#{slug}"
  end

  def project_name
    travis_github_account
  end

  def fetch_payload
    TravisJsonPayload.new_with_slug(slug)
  end

  def webhook_payload
    TravisJsonPayload.new_with_slug(slug)
  end

  private

  def base_url
    "#{BASE_API_URL}/repositories/#{slug}"
  end

  def slug
    "#{travis_github_account}/#{travis_repository}"
  end
end
