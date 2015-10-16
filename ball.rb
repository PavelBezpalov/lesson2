require 'yaml'

class Ball
  ANSWERS = YAML.load_file(File.join(__dir__, './answers.yml'))

  def color(answer)
    [4, 9, 14, 19].inject(35) do |color, value|
      color - ((0..value).cover?(ANSWERS.index(answer)) ? 1 : 0)
    end
  end

  def shake
    answer = ANSWERS.sample
    puts "\e[#{color(answer)}m#{answer}\e[0m"
    answer
  end
end
