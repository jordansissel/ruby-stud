module Stud
  def self.trap(signal, &block)
    @traps ||= Hash.new { |h,k| h[k] = [] }
    @traps[signal] << block

    if !@trapped
      previous_trap = Signal::trap(signal) { simulate_signal(signal) }
      # If there was a previous trap (via Kernel#trap) set, make sure we remember it.
      if previous_trap.is_a?(Proc)
        @traps[signal] << previous_trap
      end

      @trapped = true
    end
  end

  def self.simulate_signal(signal)
    @traps[signal].each(&:call)
  end
end

# Monkey-patch the main 'trap' stuff? This could be useful.
#module Signal
  #def trap(signal, value=nil, &block)
    #if value.nil?
      #Stud.trap(signal, &block)
    #else
      ## do nothing?
    #end
  #end # def trap
#end
#
#module Kernel
  #def trap(signal, value=nil, &block)
    #Signal.trap(signal, value, &block)
  #end
#end

