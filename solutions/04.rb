module Patterns
  TLD           = /\b[a-z]{2,3}(\.[a-z]{2})?\b/i
  HOSTNAME_PART = /\b[0-9a-z]([0-9a-z\-]{,61}[0-9a-z])?\b/i
  DOMAIN        = /\b#{HOSTNAME_PART}\.#{TLD}\b/i
  HOSTNAME      = /\b(#{HOSTNAME_PART}\.)+#{TLD}\b/i
  EMAIL         = /\b(?<username>[a-z0-9][\w_\-+\.]{,200})@(?<hostname>#{HOSTNAME})\b/i
  COUNTRY_CODE  = /[1-9]\d{,2}/
  PHONE_PREFIX  = /((\b|(?<![\+\w]))0(?!0)|(?<country_code>\b00#{COUNTRY_CODE}|\+#{COUNTRY_CODE}))/
  PHONE         = /(?<prefix>#{PHONE_PREFIX})(?<number>[ \-\(\)]{,2}(\d[ \-\(\)]{,2}){6,10}\d)\b/
  IP_ADDRESS    = /(\d+)\.(\d+)\.(\d+)\.(\d+)/
  INTEGER       = /-?(0|[1-9]\d*)/
  NUMBER        = /#{INTEGER}(\.[0-9]+)?/
  ISO_DATE      = /(?<year>\d{4})-(?<month>\d\d)-(?<day>\d\d)/
  ISO_TIME      = /(?<hour>\d\d):(?<minute>\d\d):(?<second>\d\d)/
  DATE_TIME     = /(?<date>#{ISO_DATE})[ T](?<time>#{ISO_TIME})/
end

class PrivacyFilter
  include Patterns

  attr_accessor :preserve_email_hostname
  attr_accessor :partially_preserve_email_username
  attr_accessor :preserve_phone_country_code

  def initialize(text)
    @text = text
  end

  def filtered
    filter_phone_numbers_in(filter_emails_in(@text))
  end

  private

  def filter_emails_in(text)
    text.gsub EMAIL do
      filtered_email $~[:username], $~[:hostname]
    end
  end

  def filtered_email(username, hostname)
    if preserve_email_hostname or partially_preserve_email_username
      "#{filtered_email_username(username)}@#{hostname}"
    else
      '[EMAIL]'
    end
  end

  def filtered_email_username(username)
    if partially_preserve_email_username and username.length >= 6
      username[0...3] + '[FILTERED]'
    else
      '[FILTERED]'
    end
  end

  def filter_phone_numbers_in(text)
    text.gsub PHONE do
      filtered_phone_number $~[:country_code]
    end
  end

  def filtered_phone_number(country_code)
    if preserve_phone_country_code and country_code.to_s != ''
      "#{country_code} [FILTERED]"
    else
      '[PHONE]'
    end
  end
end

class Validations
  class << self
    include Patterns

    def email?(text)
      /\A#{EMAIL}\z/ === text
    end

    def phone?(text)
      /\A#{PHONE}\z/ === text
    end

    def hostname?(text)
      /\A#{HOSTNAME}\z/ === text
    end

    def ip_address?(text)
      /\A#{IP_ADDRESS}\z/ === text and
        $~.captures.all? { |byte| byte.to_i.between?(0, 255) }
    end

    def number?(text)
      /\A#{NUMBER}\z/ === text
    end

    def integer?(text)
      /\A#{INTEGER}\z/ === text
    end

    def date?(text)
      /\A#{ISO_DATE}\z/ === text and
        $~[:month].to_i.between?(1, 12) and $~[:day].to_i.between?(1, 31)
    end

    def time?(text)
      /\A#{ISO_TIME}\z/ === text and
        $~[:hour].to_i.between?(0, 23) and
        $~[:minute].to_i.between?(0, 59) and
        $~[:second].to_i.between?(0, 59)
    end

    def date_time?(text)
      /\A#{DATE_TIME}\z/ === text and
        date?($~[:date]) and time?($~[:time])
    end
  end
end

