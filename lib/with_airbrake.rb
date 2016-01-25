module WithAirbrake
  def self.run(&block)
    if enabled?
      begin
        block.call
      rescue => e
        Airbrake.notify_sync(e)
        raise e
      end
    else
      puts "NO AIRBRAKE"
      block.call
    end
  end

  private

  def self.enabled?
    ensure_configured
    @enabled
  end

  def self.ensure_configured
    if @enabled.nil?
      key = ENV['AIRBRAKE_PROJECT_KEY']
      id = ENV['AIRBRAKE_PROJECT_ID']
      if !key.nil? && !key.empty? && !id.nil? && !id.empty?
        require 'airbrake-ruby'
        Airbrake.configure do |c|
          c.project_key = key
          c.project_id = id
        end
        $stderr.puts "Using Airbrake project ID #{id}"
        @enabled = true
      else
        @enabled = false
      end
    end
  end
end
