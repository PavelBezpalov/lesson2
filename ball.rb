require 'yaml'

class Ball
  ANSWERS = YAML.load_file(File.join(__dir__, './answers.yml'))

  def answers_with_color
    answers = []
    answers.push(color_code: 31, messages: ANSWERS[0..4])
    answers.push(color_code: 32, messages: ANSWERS[5..9]) if ANSWERS.size > 5
    answers.push(color_code: 33, messages: ANSWERS[10..14]) if
    ANSWERS.size > 10
    answers.push(color_code: 34, messages: ANSWERS[15..19]) if
    ANSWERS.size > 15
    answers
  end

  def shake
    answer = answers_with_color.sample
    message = answer[:messages].sample
    puts "\e[#{answer[:color_code]}m#{message}\e[0m"
    message
  end
end
