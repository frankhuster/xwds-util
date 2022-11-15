#!/usr/bin/env ruby

# frozen_string_literal: true

require 'google/cloud/firestore'

def firestore
  @firestore ||= Google::Cloud::Firestore.new project_id: 'xwds-368015'
end

def player_exists?(name)
  players_ref = firestore.col('players')
  query = players_ref.where 'name', '=', name
  query.get do |_player|
    return true
  end
  false
end

if ARGV.size == 1 && ARGV[0].match(/^[a-z]+$/)
  puts player_exists?(ARGV[0]) ? 'true' : 'false'
else
  puts 'gimme a lowercase name'
end
