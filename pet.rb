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

module Interface
  include EventText

  DummyObject = Object.new

  private

  def stat_with_color(value)
    if value[1] <= 2
      color = :red
    elsif value[1] <= 5
      color = :yellow
    else
      color = :green
    end
    value[0].to_s.upcase.colorize(color)
  end

  def sleep_state(cond)
    if cond
      'SLEEP'.colorize(:light_blue)
    else
      'ACTIVE'.colorize(:light_green)
    end
  end

  def stats_text(params)
    stats_str = params.to_a.each_with_object([]) do |item, stats|
      if item[0] != :sleep
        stats.push(stat_with_color(item))
      else
        stats.unshift(sleep_state(item[1]))
      end
      stats
    end
    stats_str.join(' | ')
  end

  def alerts_text(alerts)
    alerts_str = alerts.to_a.each_with_object([]) do |item, arr|
      arr.push(item[0].to_s.capitalize) if item[1]
      arr
    end
    alerts_str.join(' | ').colorize(:light_red)
  end

  def text(name, type, params, alerts)
    ["#{name} - the #{type}".colorize(:light_cyan),
     stats_text(params),
     alerts_text(alerts),
     @event_message].each do |item|
      puts item
      puts '-' * 40
    end
    print 'enter command: '
  end

  def valid_command?(command)
    self.respond_to?(command) && !DummyObject.respond_to?(command)
  end

  def prompt
    @prompt_thread ||= Thread.new do
      loop do
        input = gets.chomp
        exit if input == 'exit'
        valid_command?(input) ? send(input) : global_message(:command_err)
        @redraw = true
      end
    end
    @prompt_thread.run
  end

  def clear_screen
    print `(clear)`
  end

  def interface(name, type, params, alerts)
    @redraw = false
    clear_screen
    text(name, type, params, alerts)
    prompt
  end
end

module GameTime
  MINUTES_PER_TIME = 3

  private

  def can_ill?
    @alerts[:dirty] || @alerts[:doody] || @alerts[:sad] || @alerts[:hungry] ||
      @alerts[:tired]
  end

  def time_passed?
    @tracktime ||= Time.new
    (Time.new - @tracktime) / 60.0 > MINUTES_PER_TIME
  end

  def change_values!
    change_param!(:fun, :down)
    change_param!(:food, :down)
    change_param!(:health, :down) if can_ill?
    change_param!(:energy, :up) if @params[:sleep]
  end

  def time_passed!
    change_values!
    wake_up! if @params[:energy] == 10
    doody!
    leave if @params[:health] == 0
    @redraw = true
  end

  def time
    born
    loop do
      interface(@name, @pet[:type], @params, @alerts) if @redraw
      next unless time_passed?
      time_passed!
      @tracktime = Time.new
    end
  end

  def born
    global_message(:born_succ, @name)
    @redraw ||= false
    interface(@name, @pet[:type], @params, @alerts)
  end

  def leave
    clear_screen
    pet_spec_message(:leave_err, @name)
    puts @event_message
    exit
  end
end

class Pet
  include Interface
  include GameTime

  def initialize(name)
    @name = name
    @pet = PETS.sample
    @params = { food: 0, health: 10, fun: 10, energy: 10, sleep: false }
    @alerts = { doody: false, dirty: false, hungry: true, ill: false,
                sad: false, tired: false }
    time
  end

  def feed
    wake_up!
    if @params[:food] < 10
      change_param!(:food, :up)
      global_message(:feed_succ, @name)
      doody!
    else
      global_message(:feed_fail, @name)
    end
  end

  def clean
    if @alerts[:doody] || @alerts[:dirty]
      global_message(:clean_succ, @name)
    else
      global_message(:clean_fail, @name)
    end
    @alerts[:doody], @alerts[:dirty] = false
  end

  def help
    commands = methods - DummyObject.methods
    global_message(:help_succ, commands.sort.join(', '))
  end

  def tobed
    if @params[:energy] < 10
      @params[:sleep] = true
      global_message(:tobed_succ, @name)
    else
      global_message(:tobed_fail, @name)
    end
  end

  def play
    wake_up!
    if @params[:energy] > 0
      global_message(:play_succ, @name)
      change_param!(:fun, :up)
      change_param!(:energy, :down)
      dirty!
    else
      global_message(:play_fail, @name)
    end
  end

  def watch
    wake_up!
    pet_spec_message(:watch_succ, @name)
    change_param!(:fun, :up)
    change_param!(:energy, :down)
    dirty!
  end

  private

  def change_param!(value, how)
    if how == :up
      @params[:health] += rand(3)
      @params[value] += rand(1..3)
    elsif how == :down
      @params[value] -= rand(3)
    end
    normalize_params!
    set_alerts!
  end

  def normalize_params!
    @params.each do |key, value|
      next if key == :sleep
      if value > 10
        @params[key] = 10
      elsif value < 0
        @params[key] = 0
      end
    end
  end

  def set_alerts!
    @alerts[:hungry] = @params[:food] <= 2 ? true : false
    @alerts[:tired] = @params[:energy] == 0 ? true : false
    @alerts[:sad] = @params[:fun] == 0 ? true : false
    @alerts[:ill] = @params[:health] <= 2 ? true : false
  end

  def doody!
    return unless !@alerts[:doody] && @params[:food] >= 1
    @alerts[:doody] = true if rand(10).odd?
    dirty!
  end

  def dirty!
    @alerts[:dirty] = true if rand(10).odd?
  end

  def wake_up!
    return unless @params[:sleep]
    @params[:sleep] = false
    global_message(:wakeup_succ, @name)
  end
end

puts 'What would you like to name your pet?'
name = gets.chomp
Pet.new name
