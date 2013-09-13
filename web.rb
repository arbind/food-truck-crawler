class Web
  USER_AGENT = 'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)'

  def self.site(url_string) Web.new(url_string) end

  def initialize(url_string)
    @url = url_string.to_href
  end

  def document
    @document||= Nokogiri::HTML(open @url, 'User-Agent' => USER_AGENT)
  end

  def select_all(css) document.css(css) end

  def select_first(css) select_all(css).first end

  def title
    select_first('title').content
  end

  def links(match=nil, trim=true)
    if match.nil?
      elements = select_all("a[href]")
    else
      elements = select_all("a[href*=#{match}]")
    end
    elements.map do |e|
      href = e[:href]
      href= Web.strip_href href if trim
      href
    end
  end

  def provider_links
    links = {}
    yelp_links              = links 'yelp'
    twitter_links           = links 'twitter'
    facebook_links          = links 'facebook'
    links[:yelp_links]      = yelp_links if yelp_links.any?
    links[:twitter_links]   = twitter_links if twitter_links.any?
    links[:facebook_links]  = facebook_links if facebook_links.any?
    links
  end

  def self.hosts_match?(href1, href2)
    return false unless href1.present? and href2.present?
    url1 = strip_href href1.to_href.downcase
    url2 = strip_href href2.to_href.downcase
    u1 = URI.parse(url1)
    u2 = URI.parse(url2)
    u1.host.eql? u2.host
  end

  def self.strip_href(href)
    url = href.split('?')[0] # strip off query params
    url.split('#')[0] # strip off anchors
  end

  def self.provider_href?(url)
    provider_for_href url
  end

  def self.provider_for_href(url)
    return false if url.nil?
    href = url.downcase.squish.to_href
    return false if href.nil?
    match = href.match /^http(s)?\:\/\/(www.)?(yelp)?(facebook)?(twitter)?\.com/i
    return nil if match.nil?
    return :yelp if match[3]
    return :facebook if match[4]
    return :twitter if match[5]
    nil
  end

  def self.final_location_of_url(url)
    return "" if url.nil? or url.strip.empty?
    final_location = nil
    begin
      open(url.strip,'User-Agent' => 'ruby') {|resp| final_location=resp.base_uri}
    rescue RuntimeError => e
      if e.message.match /redirection forbidden/
        final_location = e.message.split('->').last.strip
        # redirection forbidden: http://abc.com/tacs -> https://abc.com/taco
      end
    rescue OpenURI::HTTPError => e
      # 403 forbidden, 404 not found, etc
    rescue SocketError => e
      # No DNS
    end
    final_location.to_s
  end
end