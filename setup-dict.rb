#!/usr/bin/env ruby

require 'bundler/setup'
require 'fileutils'
require 'google/cloud/firestore'
require 'tzinfo'

# Assuming a ./words/ directory with files containing at most {bulk transaction size}
# lines - which, for Google Firestore, is 500
# Assuming any file in the ./words/added/ directory was successfully added

DAILY_IMPORT_LIMIT = 18_000

def added_dir(today)
  "words/added/#{today}"
end

def dir_word_count(dir)
  word_count = 0
  if Dir.exist?(dir)
    Dir.glob("#{dir}/*").each do |path|
      word_count += File.readlines(path).length
    end
  end
  word_count
end

def add_line(b, line)
  word_length = line.index(' ')
  word = line[0, word_length]
  desc = line[(word_length + 1)..]
  b.set("dictionary/#{word}", { word:, description: desc })
end

def add_todays_words(db, today)
  todays_dir = added_dir(today)
  words_added_today = dir_word_count(todays_dir)
  while words_added_today < DAILY_IMPORT_LIMIT
    FileUtils.mkdir_p(todays_dir)
    path = Dir.glob('words/*').select { |f| File.file?(f) }.sort.first
    lines = File.readlines(path)
    db.batch do |b|
      lines.each do |line|
        add_line(b, line)
        words_added_today += 1
      end
    end
    puts "#{path}: #{lines.length}"
    FileUtils.mv(path, todays_dir)
  end
end

db = Google::Cloud::Firestore.new project_id: 'xwds-368015'
today = TZInfo::Timezone.get('US/Pacific').now.strftime('%Y%0m%0d')
add_todays_words(db, today)
