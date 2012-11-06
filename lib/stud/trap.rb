module Stud
  def self.trap(signal, &block)
    @traps ||= Hash.new { |h,k| h[k] = [] }

    if !@traps.include?(signal)
      # First trap call for this signal, tell ruby to invoke us.
      previous_trap = Signal::trap(signal) { simulate_signal(signal) }
      # If there was a previous trap (via Kernel#trap) set, make sure we remember it.
      if previous_trap.is_a?(Proc)
        # MRI's default traps are "DEFAULT" string
        # JRuby's default traps are Procs with a source_location of "(internal")
        if RUBY_ENGINE != "jruby" || previous_trap.source_location.first != "(internal)"
          @traps[signal] << previous_trap
        end
      end
    end

    @traps[signal] << block
  end

  def self.simulate_signal(signal)
    puts "Simulate: #{signal}"
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

