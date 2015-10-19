module Interface
  MESSAGES = { invalid_command: 'Huh? Please type one of the commands.' }
  COLORS = { red: 31, green: 32, yellow: 33, blue: 34, magenta: 35,
             cyan: 36, white: 37 }
  OBJ = Object.new

  private

  def stats_color(value)
    if value <= 2
      COLORS[:red]
    elsif value <= 5
      COLORS[:yellow]
    else
      COLORS[:green]
    end
  end

  def stats
    "\e[#{stats_color(@food)}mFOOD #{@food}\e[0m | " \
      "\e[#{stats_color(@health)}mHEALTH #{@health}\e[0m | " \
      "\e[#{stats_color(@fun)}mFUN #{@fun}\e[0m | " \
      "\e[#{stats_color(@energy)}mENERGY #{@energy}\e[0m"
  end

  def clear_screen
    print `(clear)`
  end

  def text
    puts "#{@name}:#{@pet[:type]} #{stats}"
    puts 'special events'
    puts @event_message
    print 'enter command: '
  end

  def clean_threads
    thread_list = Thread.list
    Thread.kill(thread_list[2]) if thread_list.size == 3
  end

  def valid_command?(command)
    self.respond_to?(command) && !OBJ.respond_to?(command)
  end

  def prompt
    clean_threads
    Thread.new do
      input = gets.chomp
      exit if input == 'exit'
      if valid_command?(input)
        send input
      else
        trigger_event(MESSAGES[:invalid_command])
      end
    end
  end

  def interface
    clear_screen
    text
    prompt
  end
end

module GameTime
  MINUTES_PER_TIME = 5

  private

  def time_passed?
    (Time.new - @tracktime) / 60.0 > MINUTES_PER_TIME
  end

  def time_passed!
    @fun = change_value(@fun, :down)
    @food = change_value(@food, :down)
    @health = change_value(@health, :down) if @dirty || @doody
    @energy = change_value(@energy, :down)
  end

  def time
    @tracktime ||= Time.new
    born
    loop do
      if time_passed?
        time_passed!
        interface
        @tracktime = Time.new
      end
      next
    end
  end
end

class Pet
  include GameTime
  include Interface

  PETS = [{ type: 'firebug' },
          { type: 'space chicken' },
          { type: 'chocolate puppy' },
          { type: 'sugarbelly' },
          { type: 'vile hamster' }
         ]

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
    if @food < 10
      @food = change_value(@food, :up)
      feed_succ = "You feed #{@name}."
      trigger_event(feed_succ)
    else
      feed_fail = "#{@name} dont want to eat."
      trigger_event(feed_fail)
    end
  end

  def walk
    puts "You walk #{@name}."
    @fun = change_value(@fun, :up)
  end

  def tobed
    puts "You put #{@name} to bed."
    if @energy < 10
      @asleep = true
      puts @name + ' is sleeping.'
    else
      puts "#{@name} dont want to sleep."
    end
  end

  def toss
    puts "You toss #{@name} up into the air."
    puts 'He giggles, which singes your eyebrows.'
    time
  end

  def rock
    puts "You rock #{@name} gently."
    @asleep = true
    puts 'He briefly dozes off...'
    time
    return unless @asleep
    @asleep = false
    puts '...but wakes when you stop.'
  end

  private

  def change_value(value, how)
    if how == :up
      @health += rand(1)
      value += rand(1..3)
    elsif how == :down
      value -= rand(3)
    end
    @health = 10 if @health > 10
    value > 10 ? 10 : value
  end

  def hungry?
    @food <= 2
  end

  def poopy?
    @food >= 5
  end

  def wake_up_suddenly
    return unless @asleep
    @asleep = false
    puts 'He wakes up suddenly!'
  end

  def poop_or_alert
    if @food >= 10
      @food = 0
      puts "Whoops! #{@name} had an accident..."
    elsif hungry?
      wake_up_suddenly
      puts "#{@name}'s stomach grumbles..."
    elsif poopy?
      wake_up_suddenly
      puts "#{@name} does the potty dance..."
    end
  end

  def born
    interface
  end

  def trigger_event(message)
    @event_message = message
    interface
  end
end

puts 'What would you like to name your pet?'
name = gets.chomp
Pet.new name
