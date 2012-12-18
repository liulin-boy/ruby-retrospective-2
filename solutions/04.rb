class PrivacyFilter
  attr_accessor :preserve_phone_country_code, :preserve_email_hostname, :partially_preserve_email_username

  def initialize(text)
    @preserve_phone_country_code = false
    @preserve_email_hostname = false
    @partially_preserve_email_username = false
    @text = text
  end

  def filtered
    result = self.clone
    result.send(:text=, filter_email)
    result.filter_phone
  end

private
  attr_accessor :text
public
  def filter_phone
    if preserve_phone_country_code
      @text.gsub(/(?<country_code>(00|\+)[1-9]\d{,2})(?<phone>([ \(\)-]{,2}\d){6,11})/,'\k<country_code> [FILTERED]').
        gsub(/(?<prefix>0)(?<phone>([ \(\)-]{,2}\d){6,11})/, '[PHONE]')
    else
      @text.gsub(/(?<prefix>(0|(00|\+)[1-9]\d{,2}))(?<phone>([ \(\)-]{,2}\d){6,11})/, '[PHONE]')
    end
  end

  def filter_email
    result = filter_email_partially_preserving_email_username if partially_preserve_email_username
    result ||= filter_email_preserving_hostname if preserve_email_hostname
    result ||= filter_whole_email
  end

  def filter_whole_email
    hostname = /(?<name>([a-zA-Z0-9][a-zA-Z0-9-]{,60}[a-zA-Z0-9]\.)*)(?<tld>[a-zA-z]{2,3}(\.[a-zA-z]{2})?)/
    whole_email = /(?<username>[a-zA-Z0-9][\w+\.-]{,200})@(?<hostname>#{hostname})/
    @text.gsub(whole_email, '[EMAIL]')
  end

  def filter_email_preserving_hostname
    hostname = /(?<name>([a-zA-Z0-9][a-zA-Z0-9-]{,60}[a-zA-Z0-9]\.)*)(?<tld>[a-zA-z]{2,3}(\.[a-zA-z]{2})?)/
    whole_email = /(?<username>[a-zA-Z0-9][\w+\.-]{,200})@(?<hostname>#{hostname})/
    @text.gsub(whole_email, '[FILTERED]@\k<hostname>')
  end

  def filter_email_partially_preserving_email_username
    hostname = /(?<name>([a-zA-Z0-9][a-zA-Z0-9-]{,60}[a-zA-Z0-9]\.)*)(?<tld>[a-zA-z]{2,3}(\.[a-zA-z]{2})?)/
    @text.gsub(/\b(?<short_username>[a-zA-Z0-9][\w+\.-]{,4})@(?<hostname>#{hostname})/, '[FILTERED]@\k<hostname>').
      gsub(/(?<_>[a-zA-Z0-9][\w+\.-]{2})[\w+\.-]{,197}@(?<hostname>#{hostname})/, '\k<_>[FILTERED]@\k<hostname>')
  end
end

class Validations
  def self.email?(value)
    /^(?<username>[a-zA-Z0-9][\w+\.-]{,200})@(?<hostname>.*)$/ =~ value
    self.hostname?(hostname) ? true : false
  end

  def self.hostname?(value)
    /^(?<name>([a-zA-Z0-9][a-zA-Z0-9-]{,60}[a-zA-Z0-9]\.)*)(?<tld>[a-zA-z]{2,3}(\.[a-zA-z]{2})?)$/ =~ value ?
      true : false
  end

  def self.phone?(value)
    /^(?<prefix>(0|(00|\+)[1-9]\d{,2}))(?<phone>([ \(\)-]{,2}\d){6,11})$/ =~ value ? true : false
  end

  def self.ip_address?(value)
    (/^(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/ =~ value and
      ip.split('.').all? { |byte| byte.to_i.between?(0, 255) }) ? true : false
  end

  def self.number?(value)
    /^(?<number>-?(0|[1-9][0-9]*)(\.[0-9]+)?)$/ =~ value ? true : false
  end

  def self.integer?(value)
    /^(?<integer>-?(0|[1-9][0-9]*))$/ =~ value ? true : false
  end

  def self.date?(value)
    (/^(?<year>[0-9]{4})-(?<month>[0-9]{2})-(?<day>[0-9]{2})$/ =~ value and
      month.to_i.to_i.between?(1, 12) and day.to_i.between?(1, 31)) ? true : false
  end

  def self.time?(value)
    (/^(?<hours>[0-9]{2}):(?<minutes>[0-9]{2}):(?<seconds>[0-9]{2})$/ =~ value and
      hours.to_i.between?(0, 23) and minutes.to_i.between?(0, 59) and seconds.to_i.between?(0, 59)) ? true : false
  end

  def self.date_time?(value)
    (/^(?<date>.*)( |T)(?<time>.*)$/ =~ value and self.date?(date) and self.time?(time)) ? true : false
  end
end