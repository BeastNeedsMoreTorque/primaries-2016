module WithAirbrake
  # Runs the given block. If it crashes, notifies Airbrake and raises the error
  def self.run(&block)
    ensure_configured

    # When we require airbrake (as in `ensure_configured`), it adds an at_exit
    # handler. This is the worst thing in my tiny world right now, because I
    # didn't ask for it and I can't turn it off, so AARGH. But whatever. Let's
    # hope the caller doesn't expect this method to do the right thing.
    #
    # Here's what can happen when the block throws an unhandled exception:
    #
    # 1. Airbrake isn't configured. Calls the block.
    # 2. Airbrake is configured, and there's no exception handler around `run`:
    #    calls the block, and calls Airbrake.notify_sync with the exception.
    # 3. Airbrake is configured, and there *is* an exception handler around
    #    `run`: calls the block and does *not* call Airbrake.notify_sync with
    #    the exception. Instead, calls Airbrake.notify_sync on some future
    #    error that we didn't ask for.
    block.call
  end

  private

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
