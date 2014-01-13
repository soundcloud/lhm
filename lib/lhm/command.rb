# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

module Lhm
  class Error < StandardError
  end

  module Command
    def run(&block)
      Lhm.logger.info "Starting run of class=#{self.class}"
      validate

      if(block_given?)
        before
        block.call(self)
        after
      else
        execute
      end
    rescue => e
      Lhm.logger.error "Error in class=#{self.class}, reverting. exception=#{e.class} message=#{e.message}"
      revert
      raise
    end

  private

    def validate
    end

    def revert
    end

    def execute
      raise NotImplementedError.new(self.class.name)
    end

    def before
    end

    def after
    end

    def error(msg)
      raise Error.new(msg)
    end
  end
end
