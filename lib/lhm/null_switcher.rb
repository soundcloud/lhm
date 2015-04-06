# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require 'lhm/command'

module Lhm
  # Doesn't perform any switching
  #
  class NullSwitcher
    include Command

    private

    def execute
      # noop
    end

  end
end
