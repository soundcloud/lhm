# Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

module Lhm
  class Error < StandardError
  end

  module Command
    def run(&block)
      validate

      if(block_given?)
        before
        block.call(self)
        after
      else
        execute
      end
    rescue
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
