require 'colorize'
require 'yaml'

class Pet
  DummyObject = Object.new

  DATA = YAML.load_file('./data.yml')
  MESSAGES = DATA[:messages]
  PETS = DATA[:pets]
  MINUTES_PER_TIME = 3

  def initialize(name)
    @name = name
    @pet = PETS.sample
    @fun = 10
    @food = 0
    @health = 10
    @energy = 10
    time
  end

  def feed
    wake_up
    if @food < 10
      @food = change_value(@food, :up)
      @event_message = "You feed #{@name}.".colorize(:light_green)
      doody!
    else
      @event_message = "#{@name} dont want to eat.".colorize(:light_yellow)
    end
  end

  def clean
    if doody? || dirty?
      @event_message = "#{@name} is clean now!".colorize(:light_green)
    else
      @event_message = "#{@name} is cleaner now!".colorize(:light_yellow)
    end
    @doody, @dirty = false
  end

  def help
    commands = methods - DummyObject.methods
    @event_message = "Available commands:\n#{commands.sort.join(', ')}" \
                     ', exit.'.colorize(:light_green)
  end

  def tobed
    if @energy < 10
      @asleep = true
      @event_message = "#{@name} is sleeping.".colorize(:light_green)
    else
      @event_message = "#{@name} dont want to sleep.".colorize(:light_yellow)
    end
  end

  def play
    wake_up
    if @energy > 0
      @event_message = "You threw the ball and #{@name} brought it back."
                       .colorize(:light_green)
      @fun = change_value(@fun, :up)
      @energy = change_value(@energy, :down)
      dirty!
    else
      @event_message = 'No time to play ball.'.colorize(:light_yellow)
    end
  end

  def watch
    wake_up
    @event_message = "#{@name} #{@pet[:watch].sample}".colorize(:light_green)
    @fun = change_value(@fun, :up)
    @energy = change_value(@energy, :down)
    dirty!
  end

  private

  def change_value(value, how)
    if how == :up
      @health += rand(3)
      value += rand(1..3)
    elsif how == :down
      value -= rand(3)
    end
    @health = 10 if @health > 10
    return 10 if value > 10
    return 0 if value < 0
    value
  end

  def hungry?
    @food <= 2
  end

  def tired?
    @energy == 0
  end

  def sad?
    @fun == 0
  end

  def ill?
    @health <= 2
  end

  def doody?
    @doody ||= false
  end

  def doody!
    return unless !doody? && @food >= 1
    @doody = true if rand(10).odd?
    dirty!
  end

  def dirty?
    @dirty ||= false
  end

  def dirty!
    @dirty = true if rand(10).odd?
  end

  def can_ill?
    @dirty || @doody || sad? || hungry? || tired?
  end

  def wake_up
    return unless @asleep
    @asleep = false
    @event_message = "#{@name} wakes up!".colorize(:light_green)
  end

  def time_passed?
    (Time.new - @tracktime) / 60.0 > MINUTES_PER_TIME
  end

  def change_values
    @fun = change_value(@fun, :down)
    @food = change_value(@food, :down)
    @health = change_value(@health, :down) if can_ill?
    @energy = change_value(@energy, :up) if @asleep
  end

  def time_passed!
    change_values
    wake_up if @energy == 10
    doody!
    leave if @health == 0
    @redraw = true
  end

  def time
    born
    loop do
      if time_passed?
        time_passed!
        @tracktime = Time.new
      end
      interface if @redraw
      next
    end
  end

  def born
    @event_message = "#{@name} is born!".colorize(:light_green)
    @tracktime ||= Time.new
    @redraw ||= false
    interface
  end

  def leave
    clear_screen
    puts "#{@name} #{@pet[:leave]}".colorize(:light_red)
    exit
  end

  def stats_color(value)
    if value <= 2
      :red
    elsif value <= 5
      :yellow
    else
      :green
    end
  end

  def stats
    if @asleep
      status = "#{'SLEEP'.colorize(:light_blue)} | " \
    else
      status = "#{'ACTIVE'.colorize(:light_green)} | " \
    end
    "#{status}#{'FOOD'.colorize(stats_color(@food))} | " \
    "#{'HEALTH'.colorize(stats_color(@health))} | " \
    "#{'FUN'.colorize(stats_color(@fun))} | " \
    "#{'ENERGY'.colorize(stats_color(@energy))}"
  end

  def clear_screen
    print `(clear)`
  end

  def special_events
    message = []
    message.push('Doody') if doody?
    message.push('Dirty') if dirty?
    message.push('Hungry') if hungry?
    message.push('Tired') if tired?
    message.push('Sad') if sad?
    message.push('Ill') if ill?
    message
  end

  def text
    puts "#{@name} - the #{@pet[:type]}".colorize(:light_cyan)
    puts '-' * 40
    puts stats
    puts '-' * 40
    puts special_events.join(' | ').colorize(:light_red) unless
    special_events.empty?
    puts '-' * 40
    puts @event_message
    puts '-' * 40
    print 'enter command: '
  end

  def valid_command?(command)
    self.respond_to?(command) && !DummyObject.respond_to?(command)
  end

  def prompt
    @prompt_tread = Thread.new do
      input = gets.chomp
      exit if input == 'exit'
      if valid_command?(input)
        send input
      else
        @event_message = MESSAGES[:invalid_command]
      end
      @redraw = true
      Thread.exit
    end
  end

  def kill_prompt_thread
    @prompt_tread.kill if @prompt_tread.is_a?(Thread)
  end

  def interface
    @redraw = false
    kill_prompt_thread
    clear_screen
    text
    prompt
  end
end

puts 'What would you like to name your pet?'
name = gets.chomp
Pet.new name
