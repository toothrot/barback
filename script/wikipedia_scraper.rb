require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

class WikipediaScraper
  class << self
    def scrape
      cocktails = fetch_cocktails( load_list )
      puts cocktails.to_json
    end

    def load_list
      iba_list = open("https://en.wikipedia.org/wiki/List_of_IBA_official_cocktails")
      doc = Nokogiri::HTML(iba_list)
      paths = doc.css('.navbox-list a:not(.new)').
        map(&:attributes).
        map { |attributes| attributes['href'].value }
      paths.map do |path|
        URI.join('https://en.wikipedia.org', path)
      end
    end

    def fetch_cocktails(cocktail_paths)
      cocktail_paths.map do |path|
        sleep 0.5
        parse_cocktails(Nokogiri::HTML(open(path), &:noblanks))
      end.flatten
    end

    def parse_cocktails(cocktail_page)
      recipies = cocktail_page.css('.infobox.hrecipe')
      recipies.map do |recipe|
        STDERR.puts "Parsing #{recipe.css('caption').text}"
        all_keys = recipe.css('tr th').
          map { |head| head.parent.css('th, td').map(&:text) }.
          select {|arrays| arrays.size == 2}.
          to_h
        {
          title: recipe.css('caption').text,
          ingredients: recipe.css('.ingredient li').map(&:text),
          body: recipe.to_s
        }.merge(
          all_keys
        )
      end
    end
  end
end

WikipediaScraper.scrape
