require 'search_engine.rb'

search_engine = SearchEngine.new('./test/file*','stoplist.txt')
ARGF.each do |line|
  words = line.split
  if(words.size == 1)
    exit if words[0] == "ZZZ"
    search_engine.query(words[0])
  elsif(words.size > 1)
    search_engine.query_multiple_words(words)
  else
    puts "Enter a query or type 'ZZZ' to end."
  end
end