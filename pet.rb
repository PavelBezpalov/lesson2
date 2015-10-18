class Pet
  def initialize(name)
    @name = name
    @type = :dragon
    @asleep = false
    @happiness = 10
    @stuff_in_intestine = 0
    @food = 0
    @health = 10
    @energy = 10
    @fun = 8
    puts "#{@name} is born."
  end

  def feed
    puts "You feed #{@name}."
    @happiness = 10
    passage_of_time
  end

  def walk
    puts "You walk #{@name}."
    @stuff_in_intestine = 0
    passage_of_time
  end

  def sleep
    puts "You put #{@name} to bed."
    @asleep = true
    3.times do
      passage_of_time if @asleep
      puts @name + ' snores, filling the room with smoke.' if @asleep
    end
    return unless @asleep
    @asleep = false
    puts "#{@name} wakes up slowly."
  end

  def toss
    puts "You toss #{@name} up into the air."
    puts 'He giggles, which singes your eyebrows.'
    passage_of_time
  end

  def rock
    puts "You rock #{@name} gently."
    @asleep = true
    puts 'He briefly dozes off...'
    passage_of_time
    return unless @asleep
    @asleep = false
    puts '...but wakes when you stop.'
  end

  private

  def hungry?
    @happiness <= 2
  end

  def poopy?
    @stuff_in_intestine >= 8
  end

  def wake_up_suddenly
    return unless @asleep
    @asleep = false
    puts 'He wakes up suddenly!'
  end

  def poop_or_alert
    if @stuff_in_intestine >= 10
      @stuff_in_intestine = 0
      puts "Whoops! #{@name} had an accident..."
    elsif hungry?
      wake_up_suddenly
      puts "#{@name}'s stomach grumbles..."
    elsif poopy?
      wake_up_suddenly
      puts "#{@name} does the potty dance..."
    end
  end

  def passage_of_time
    if @happiness > 0
      @happiness -= 1
      @stuff_in_intestine += 1
    else
      wake_up_suddenly
      puts "#{@name} is starving! In desperation, he ate YOU!"
      exit
    end
    poop_or_alert
  end
end

puts 'What would you like to name your baby dragon?'
name = gets.chomp
pet = Pet.new name
obj = Object.new

loop do
  puts
  puts 'commands: feed, toss, walk, rock, sleep, exit'
  command = gets.chomp
  if command == 'exit'
    exit
  elsif pet.respond_to?(command) && !obj.respond_to?(command)
    pet.send command
  else
    puts 'Huh? Please type one of the commands.'
  end
end
