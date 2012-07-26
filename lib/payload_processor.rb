class PayloadProcessor
  attr_accessor :project, :payload

  def initialize(project, payload)
    self.project = project
    self.payload = payload
  end

  def process
    create_statuses
    update_building_status
  end

  private

  def create_statuses
    if payload.status_is_processable?
      project.online!
      create_statuses_from_payload
    else
      project.offline!
    end
  end

  def update_building_status
    if payload.build_status_is_processable?
      project.update_attributes!(building: payload.building?)
    else
      project.not_building!
    end
  end

  def create_statuses_from_payload
    payload.each_status do |status|
      if status.valid? && !project.has_status?(status)
        project.statuses << status
      end
    end
    project.save
  end
end
