class Site < ActiveRecord::Base
  attr_accessible :url
  has_many :concurs
  validates :url, uniqueness: true


  require 'nokogiri'

  def page

    url = read_attribute(:url)
    result = recursive_iframe(url)
    result[:maybe]
  end

private

  # gathers all pages nested via iframe
  def recursive_iframe(url, urls=[], hits=[])

    response = RestClient.get(url) do |response, request, result, &block|
      
      case response.code
      when 404, 406, 504
        nil
      else
        response.return!(request, result, &block)
      end

    end

    unless response.nil?
      html = Nokogiri.HTML(response)

      # current html searches
      hit = script_search(url, html)
      hits << hit unless hit.nil?

      #puts form_search(url, html)

      # iframe recursion
      html.css('iframe').each do |iframe| 
        src = iframe.attr('src')

        # check for protocol
        unless src =~ /^https?:\/\//i
          uri = URI.parse(url)
          
          if src =~ /^\//
            # absolute path
            src = "#{uri.scheme}://#{uri.host}#{src}"
          else
            # relative path
            src = "#{url}/#{src}"
          end

        end

        next unless valid_url?(src)
        next if urls.include?(src)

        (urls << src).flatten

        recursive_iframe(src, urls, hits) 
      end

    end

    urls.uniq!
    hits.flatten!
    hits.uniq!


    {
      poor: urls,
      maybe: hits
    }

  end

  # raises potential video page by looking for specific scripts
  def script_search(url, html)

    hits = []

    html.css('script').each do |script|
      src = script.attr('src')

      # script search
      if src.nil?
        # load script and parse?
      else
        # check src lib name
        hits << url if src =~ /swfobject.js/i
      end
    end

    hits.uniq!

  end

  # submits form to discover additional pages
  def form_search(url, html)

    forms = []
    html.css('form').each do |form|

      action = form.attr('action')

      action = url if action.nil?

      # prefix relative base url if no protocol
      unless action =~ /^https?:\/\//i
        uri = URI.parse(action)

        if action =~ /^\//
          # absolute path
          src = "#{uri.scheme}://#{uri.host}#{action}"
        else
          # relative path
          src = "#{url}/#{action}"
        end  

      end


      data = { 
        method: (form.attr('method') || 'post').downcase, 
        action: action,
        params: form.css('*[name]').map do |i| 
          { 
            name: i.attr('name'), 
            value: i.attr('value')
           }
        end
      }

      forms << data

      # case data[:method]
      #   when 'get'
      #     puts RestClient.get(form[:action])
      #   when 'post'
      #     puts RestClient.post(form[:action], form[:params])
      #   when 'put'
      #   else 
      #     # do nothing
      #   end

      # end

    end

    forms

  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.kind_of?(URI::HTTP)
  rescue URI::InvalidURIError
    false
  end

end
