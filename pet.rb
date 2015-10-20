require 'colorize'
require 'yaml'

module EventText
  DATA = YAML.load_file('./data.yml')
  MESSAGES = DATA[:messages]
  PETS = DATA[:pets]

  private

  def message_colors(key)
    return :light_red if key.to_s.end_with?('err')
    return :light_green if key.to_s.end_with?('succ')
    :light_yellow if key.to_s.end_with?('fail')
  end

  def global_message(key, var = nil)
    @event_message = MESSAGES[key] % var
    @event_message = @event_message.colorize(message_colors(key))
  end

  def pet_spec_message(key, var)
    message = @pet[key].sample if @pet[key].is_a?(Array)
    message = @pet[key] if @pet[key].is_a?(String)
    @event_message = ('%s ' + message) % var
    @event_message = @event_message.colorize(message_colors(key))
  end
end

class Pet
  include EventText

  DummyObject = Object.new

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
      global_message(:feed_succ, @name)
      doody!
    else
      global_message(:feed_fail, @name)
    end
  end

  def clean
    if doody? || dirty?
      global_message(:clean_succ, @name)
    else
      global_message(:clean_fail, @name)
    end
    @doody, @dirty = false
  end

  def help
    commands = methods - DummyObject.methods
    global_message(:help_succ, commands.sort.join(', '))
  end

  def tobed
    if @energy < 10
      @asleep = true
      global_message(:tobed_succ, @name)
    else
      global_message(:tobed_fail, @name)
    end
  end

  def play
    wake_up
    if @energy > 0
      global_message(:play_succ, @name)
      @fun = change_value(@fun, :up)
      @energy = change_value(@energy, :down)
      dirty!
    else
      global_message(:play_fail, @name)
    end
  end

  def watch
    wake_up
    pet_spec_message(:watch_succ, @name)
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
    global_message(:wakeup_succ, @name)
  end

  def time_passed?
    @tracktime ||= Time.new
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
    global_message(:born_succ, @name)
    @redraw ||= false
    interface
  end

  def leave
    clear_screen
    pet_spec_message(:leave_err, @name)
    puts @event_message
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
        global_message(:command_err)
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
