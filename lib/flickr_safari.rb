
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
            html = fetchurl(url)

            photo_scraper = Scraper.define do
                process ".photo_container a",     :title     => "@title"
                process ".photo_container a",     :href      => "@href"
                process ".photo_container a img", :thumb_url => "@src"
                process ".photo_container a img", :thumb_w   => "@width"
                process ".photo_container a img", :thumb_h   => "@height"

                process "td.PicDesc p.PicFrom b a", :user_name => :text

                result :title, :href, :thumb_url, :thumb_w, :thumb_h, :user_name
            end

            photos_scraper = Scraper.define do
                array :photos
                process "table.DayView tr", :photos => photo_scraper
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

        attr_reader :title, :href, :user_id, :user_name, :photo_id, :thumb_url, :thumb_w, :thumb_h

        def initialize(struct = nil)
            return if struct.nil?

            @title = struct.title
            @href = struct.href
            @user_name = struct.user_name
            @thumb_url = struct.thumb_url
            @thumb_w = struct.thumb_w
            @thumb_h = struct.thumb_h

            # href = "/photos/libbytelford/5722999886/"
            @href =~ %r{/photos/(.*)/(\d+)/}
            @user = $1
            @photo_id = $2
        end

        def photo_url
            "http://www.flickr.com#{href}"
        end

        def user_url
            "http://www.flickr.com/photos/#{user}/"
        end
    end

end
