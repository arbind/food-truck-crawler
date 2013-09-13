class String
  def to_href
    uri = URI.parse(self)
    uri = URI.parse("http://#{self}") if uri.host.nil?
    uri.to_s
  rescue
    nil
  end
end