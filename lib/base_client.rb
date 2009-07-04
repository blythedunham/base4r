# Base4R is a ruby interface to Google Base
# Copyright 2007, 2008 Dan Dukeson

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require 'net/http'
require 'client_login'

module Base4R

  class BaseException < Exception; end

  class ErrorResponse < BaseException
    attr_reader :response

    def initialize(msg, resp)
      @response = resp
      super msg
    end
  end

  class ItemNotFound < ErrorResponse; end

  # BaseClient handles all communication with the Base API using HTTP
  class BaseClient

    include HTTPLogger
    
    ITEMS_PATH = '/base/feeds/items/'
    SNIPPETS_PATH = '/base/feeds/snippets/'    
    BASE_HOST = 'base.google.com'

    attr_reader   :auth_key #:nodoc:
    attr_reader   :feed_path #:nodoc:
    attr_accessor :dry_run

    # Construct a BaseClient, which will make API requiest for the Base account
    # belonging to _username_, authenticating with _password_ and using _api_key_. 
    # Requests will be made against the public feed if _public_feed_ is true, which is the default.
    # The BaseClient can be used for a number of Base API requests.
    # 
    def initialize(username, password, api_key, public_feed=true, dry_run=false)

      @auth_key = ClientLogin.new.authenticate(username, password)
      @api_key = api_key

      if public_feed then
        @feed_path = SNIPPETS_PATH
      else
        @feed_path = ITEMS_PATH
      end
      @dry_run = dry_run
    end

    # Creates the supplied _item_ as a new Base Item.
    # Throws an Exception if there is a problem creating _item_.
    #
    def create_item(item)
      resp = do_request(item.to_xml.to_s, 'POST')
      raise ErrorResponse.new("Error creating base item: #{resp.body}", resp) unless resp.kind_of? Net::HTTPSuccess
      resp['location'] =~ /(\d+)$/
      item.base_id= $1
    end

    # Update the supplied Base _item_. Returns true on success.
    # Throws an Exception if there is a problem updating _item_.
    #
    def update_item(item)
      base_id = item_base_id item
      raise BaseException.new("base_id is required") if base_id.nil?
      resp = do_request(item.to_xml.to_s, 'PUT', :base_id => base_id)
      raise_response_error "Error updating base item", resp
      true
    end

    # Delete the supplied Base _item_. Returns true on success.
    # Throws an Exception if there is a problem deleting _item_
    def delete_item(item)
      base_id = item_base_id item
      raise BaseException.new("base_id is required") if base_id.nil?
      resp = do_request(nil, 'DELETE', :base_id => base_id)
      raise_response_error "Error deleting base item", resp
      raise BaseException.new("Error deleting base item:"+resp.body) unless resp.kind_of? Net::HTTPOK
      true
    end

    def get_item(base_id)
      resp = do_request '', 'GET', :base_id => nil, :url => "http://www.google.com/base/feeds/items/#{base_id}"
    end

    private

    #raise the appropriate error based on the response
    # +message+ - the error message
    # +response+ - the Net::HTTPResponse object
    def raise_response_error(message, response)
      error_klass = if response.is_a?(Net::HTTPNotFound) && response.body =~ /Cannot find item/
        ItemNotFound
      elsif !response.kind_of?(Net::HTTPOK)
        ErrorResponse
      end

      raise error_klass.new("#{message}: #{response.body}", response) if error_klass
    end

    # Return the base id of the item if it is a Base4r::Item
    # otherwise assume it is the actual base id
    def item_base_id(item)
      item.respond_to?(:base_id) ? item.base_id : item
    end


    def do_request(data, http_method, options={})


      url = options[:url]||"http://#{BASE_HOST}#{@feed_path}"
      url << "#{options[:base_id]}" if options[:base_id]
      url << "?dry-run=true" if dry_run
      url = URI.parse(url)
      
      headers = {'X-Google-Key' => "key=#{@api_key}",
                 'Authorization' => "GoogleLogin auth=#{@auth_key}",
                 'Content-Type' => 'application/atom+xml'}

      result = Net::HTTP.start(url.host, url.port) { |http|
        request = Net::HTTPGenericRequest.new(http_method,(data ? true : false),true, url.path, headers)
        log_request request, :url => url, :method => http_method, :data => data
        http.request request, data
      }

      log_response result
      result
    end

  end

end
