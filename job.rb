# frozen_string_literal: true

require "open3"

module PubsubWorker
  class Job
    attr_reader :subscriber_channel, :payload

    def initialize(subscriber_channel, payload)
      @subscriber_channel, @payload = subscriber_channel, payload
    end

    def process!
      return false unless script_exists?

      exit_status = nil
      Open3.popen2(script_path.to_s, chdir: PubsubWorker.scripts_dir) do |input, output, wait|
        input.print payload.to_json
        input.close

        PubsubWorker.debug output.gets

        exit_status = wait.value
      end
      exit_status
    end

    def description
      "#{channel} - #{payload['type']}"
    end

    def channel
      payload['channel']
    end

    def script_exists?
      script_path.exist?
    end

    def script_path
      Pathname.new(PubsubWorker.scripts_dir).join(script_name)
    end

    def script_name
      channel.gsub(".", "-")
    end
  end
end
