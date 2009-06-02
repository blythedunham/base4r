module Base4R
  module HTTPLogger

    def self.included(base)
      base.extend self
    end

    def verbose?; false; end

    def log(message)
      return unless verbose?
      STDOUT.puts message
    end

    def log_request(request, options={})
      log "-------#{request.to_s}----------"
      log "URL:    #{options[:url]}" if options[:url]
      log "METHOD: #{options[:method]}" if options[:method]
      
      request.each_capitalized {|k, v| log "#{k}: #{v}" } if request.respond_to? :each_capitalized
      
      log options[:data] ? options[:data] : request.body

      log "-------#{request.to_s}----------"
    end

    def log_response(response)
      log_request(response)
    end

  end
end
