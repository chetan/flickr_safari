
if RUBY_PLATFORM =~ /darwin/ then
    # fix for scrapi on Mac OS X
    require "tidy"
    Tidy.path = "/usr/lib/libtidy.dylib"
end

require 'scrapi'
require 'net/http'

module FlickrSafari

    class << self

        def fetchurl(url)
            return Net::HTTP.get_response(URI.parse(URI.escape(url))).body
        end

        def get_all_photos(date = Time.new)
            photos = []
            (1..50).each do |pg|
                photos += get_photos(date, pg)
            end
            photos
        end

        def get_photos(date = Time.new, page = 1)

            # 2011/05/15
            if date.kind_of? String then
                ytd = date
            elsif date.kind_of? Time then
                ytd = date.strftime("%Y/%m/%d")
            end

            url = "http://www.flickr.com/explore/interesting/#{ytd}/page#{page}/"
            p url

            html = fetchurl(url)

            photo_scraper = Scraper.define do
                process "a", :title => "@title"
                process "a", :href => "@href"
                result :title, :href
            end

            photos_scraper = Scraper.define do
                array :photos
                process ".photo_container a", :photos => photo_scraper
                result :photos
            end

            photos = []
            scraped = photos_scraper.scrape(html)
            scraped.each do |ph|
                photos << Photo.new(ph)
            end

            return photos
        end

    end # self

    class Photo
        attr_accessor :title, :href, :user, :photo_id
        def initialize(struct = nil)
            return if struct.nil?

            self.title = struct.title
            self.href = struct.href

            # href = /photos/libbytelford/5722999886/
            self.href =~ %r{/photos/(.*)/(\d+)/}
            self.user = $1
            self.photo_id = $2
        end
    end

end
