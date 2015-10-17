require 'yaml'

class Ball
  ANSWERS = YAML.load_file(File.join(__dir__, './answers.yml'))
  ANSWERS_PER_COLOR = 5
  COLORS = [31, 32, 33, 34]

  def color(answer)
    COLORS[ANSWERS.index(answer) / ANSWERS_PER_COLOR]
  end

  def shake
    answer = ANSWERS.sample
    puts "\e[#{color(answer)}m#{answer}\e[0m"
    answer
  end
end
