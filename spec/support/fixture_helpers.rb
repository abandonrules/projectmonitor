class FixtureFile
  def initialize(subdir, filename)
    @content = File.read(File.join(Rails.root, "spec", "fixtures", subdir, filename))
  end

  def read
    @content
  end

  def as_xml
    XML::Parser.string(@content).parse
  end
end

class BuildingStatusExample < FixtureFile
  def initialize(filename)
    super("building_status_examples", filename)
  end
end

class CCRssExample < FixtureFile
  def initialize(filename)
    super("cc_rss_examples", filename)
  end

  def xpath_content(xpath)
    as_xml.find(xpath).first.content
  end
end

class HudsonAtomExample < FixtureFile
  def initialize(filename)
    super("hudson_atom_examples", filename)
  end

  def as_xml
    Nokogiri::XML.parse(read)
  end

  def first_css(selector)
    as_xml.css(selector).first
  end
end

class TeamcityAtomExample < FixtureFile
  def initialize(filename)
    super("teamcity_atom_examples", filename)
  end
end

class TeamcityCradiatorXmlExample < FixtureFile
  def initialize(filename)
    super("teamcity_cradiator_xml_examples", filename)
  end

  def as_xml
    Nokogiri::XML.parse(read)
  end

  def first_css(selector)
    as_xml.css(selector).first
  end
end
