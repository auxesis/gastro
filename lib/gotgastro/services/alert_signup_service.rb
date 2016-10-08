class AlertSignupService
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :user

  attribute :email, String
  attribute :location, String
  attribute :distance, Float
  attribute :alert, Alert
  attribute :mail, Mail

  validates :email, presence: { :message => 'Bummer! We need an email address to create an alert for you.' }
  validates :location, presence: {}
  validates :distance, presence: {}

  def initialize(opts)
    @host = opts[:host] || 'https://gotgastroagain.com'
    @alert = opts[:alert] if opts[:alert]
    super(opts)
  end

  def distance
    return @alert.distance if @alert
    super
  end

  def location
    return @alert.location if @alert
    super
  end

  def persisted?
    false
  end

  def save
    if valid?
      persist!
      notify!
      true
    else
      false
    end
  end

  def self.find(confirmation_id)
    alert = Alert.first(:confirmation_id => confirmation_id)
    if alert
      self.new(:alert => alert)
    else
      nil
    end
  end

  def confirm!
    @alert.confirmed_at = Time.now
    @alert.save
  end

private

  def persist!
    attrs = {
      :email    => email,
      :location => location,
      :distance => distance,
      :confirmation_id => Digest::MD5.new.hexdigest("#{rand(Time.now.to_i).to_s}-#{email}")
    }
    @alert = Alert.create(attrs)
  end

  def notify!
    @mail = Mail.new
    @mail.from    = 'alerts-confirm@gotgastroagain.com'
    @mail.to      = email
    @mail.subject = 'Please confirm your Got Gastro alert'
    @mail.body    = <<-BODY.gsub(/^ {6}/, '')
      Hello!
      Please confirm your signup for a Got Gastro alert by following this link:

      #{@host}/alert/#{@alert.confirmation_id}/confirm

      If you don't know what this means, feel free to ignore this email.

      Thanks,
      Got Gastro
    BODY
    @mail.deliver
  end
end
