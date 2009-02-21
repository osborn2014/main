require 'mspec/expectations/expectations'
require 'mspec/runner/actions/timer'
require 'mspec/runner/actions/tally'

class DottedFormatter
  attr_reader :exceptions, :timer, :tally

  def initialize(out=nil)
    @exception = @failure = false
    @exceptions = []
    @count = 0
    if out.nil?
      @out = $stdout
    else
      @out = File.open out, "w"
    end
  end

  # Creates the +TimerAction+ and +TallyAction+ instances and
  # registers them. Registers +self+ for the +:exception+,
  # +:before+, +:after+, and +:finish+ actions.
  def register
    (@timer = TimerAction.new).register
    (@tally = TallyAction.new).register
    @counter = @tally.counter

    MSpec.register :exception, self
    MSpec.register :before,    self
    MSpec.register :after,     self
    MSpec.register :finish,    self
  end

  # Returns true if any exception is raised while running
  # an example. This flag is reset before each example
  # is evaluated.
  def exception?
    @exception
  end

  # Returns true if all exceptions during the evaluation
  # of an example are failures rather than errors. See
  # <tt>ExceptionState#failure</tt>. This flag is reset
  # before each example is evaluated.
  def failure?
    @failure
  end

  # Callback for the MSpec :before event. Resets the
  # +#exception?+ and +#failure+ flags.
  def before(state = nil)
    @failure = @exception = false
  end

  # Callback for the MSpec :exception event. Stores the
  # +ExceptionState+ object to generate the list of backtraces
  # after all the specs are run. Also updates the internal
  # +#exception?+ and +#failure?+ flags.
  def exception(exception)
    @count += 1
    @failure = @exception ? @failure && exception.failure? : exception.failure?
    @exception = true
    @exceptions << exception
  end

  # Callback for the MSpec :after event. Prints an indicator
  # for the result of evaluating this example as follows:
  #   . = No failure or error
  #   F = An ExpectationNotMetError was raised
  #   E = Any exception other than ExpectationNotMetError
  def after(state = nil)
    unless exception?
      print "."
    else
      print failure? ? "F" : "E"
    end
  end

  # Callback for the MSpec :finish event. Prints a description
  # and backtrace for every exception that occurred while
  # evaluating the examples.
  def finish
    print "\n"
    count = 0
    @exceptions.each do |exc|
      outcome = exc.failure? ? "FAILED" : "ERROR"
      print "\n#{count += 1})\n#{exc.description} #{outcome}\n"
      print exc.message, "\n"
      print exc.backtrace, "\n"
    end
    print "\n#{@timer.format}\n\n#{@tally.format}\n"
  end

  # A convenience method to allow printing to different outputs.
  def print(*args)
    @out.print(*args)
    @out.flush rescue nil #IronRuby throws a .NET exception on IO.flush
  end
end