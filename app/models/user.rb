require 'xmlsimple'

require 'openid'
require 'openid/extensions/ax'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  attr_accessible :login, :email, :name, :password, :password_confirmation

  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def self.find_or_create_from_google_access_token(access_token)
    oauth_secret = access_token.secret

    # this really feels like a hack, seems like there should be a better way to get info about the authenticated user
    xml_string = access_token.get("https://www.google.com/m8/feeds/contacts/default/full/").body
    xml = XmlSimple.xml_in(xml_string)
    email = xml["author"].first["email"].first
    email_parts = email.split('@')
    login = email_parts.first
    domain = email_parts.second
    name = xml["author"].first["name"].first

    user = User.find_by_email(email) || User.new(:email => email)
    user.name = name
    user.login = login
    user.password = oauth_secret
    user.password_confirmation = oauth_secret

    # this also feel like a hack...
    if AuthConfig.authorized_domains.include?(domain)
      user.save!
    else
      user.errors.add_to_base('Email not in authorized domains.')
    end
    user
  end

  def self.find_or_create_from_google_openid(fetch_response)

    email = fetch_response.get_single('http://axschema.org/contact/email')
    first_name = fetch_response.get_single('http://axschema.org/namePerson/first')
    last_name = fetch_response.get_single('http://axschema.org/namePerson/last')

    email_parts = email.split('@')
    login = email_parts.first

    user = User.find_by_email(email) || User.new(:email => email)
    user.name = "#{first_name} #{last_name}"
    user.login = login

    # todo - this is a bit of a hack for now...
    user.password = user.password_confirmation = ActiveSupport::SecureRandom.hex(16)

    user.save!
    user
  end

end
