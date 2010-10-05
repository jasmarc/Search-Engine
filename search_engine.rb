class SearchEngine
  def initialize(dir_glob, stoplist)
    @word_list = Hash.new # This is our main wordlist
    @documents = Hash.new # Let's keep track of each docs' sizes
    @stop_list = File.read(stoplist).split # Words that don't count
    Dir[dir_glob].each do |document|
      # Let's read that document and get the words
      words_in_document = File.read(document).split_with_index(' ')
      # We want to remember this document's size. We'll need it later.
      @documents[document] = words_in_document.size
      # For every word in this document
      words_in_document.each do |word, location|
        word.stem! # we do some basic stemming
        # Let's add it to our "word list" 
        # along with what document it came from
        # and where in the document we saw it
        add(word, document, location) unless word_does_not_belong(word)
      end
    end
  end
  
  # This method exists solely for the benefit of the grader who
  # might want to peek into my "word list" datastructure.
  # This will print the first n items in my word list.
  def print_word_list(n)
    puts "Count: #{@word_list.size}"
    @word_list.sort.first(n).each do |item|
      pp item
    end
  end
  
  # If the query is a single term which is in the word list, the program
  # should display a list of the postings that contain the term. For each posting it
  # should write three lines of output:
  # 1. The term weightings, tf, idf and tf.idf (as defined in Lecture 4)
  #    for that posting, separated by commas.
  # 2. The ID of the document and the location within the document for that
  #    posting, separated by commas.
  # 3. About ten words from the document that include the term in its context
  #    within the document.
  def query(word)
    # Grab the entry for that word
    word_entry = @word_list[word]
    # If there was a valid entry
    if !word_entry.nil?
      # Let's print the idf score
      puts "idf = %.3f" % idf(word)
      # Then for each document
      word_entry.sort.each do |document, instances|
        # Let's print some stats for the word in that document
        puts "Appeared in #{document} #{tf(word, document)} times at these location(s): #{instances.join(', ')}"
        puts "tf = #{tf(word, document)}, tf.idf = %.3f" % tfidf(word, document)
        # Then let's open that document
        contents = File.read(document)
        # And print the word in context
        instances.each do |instance|
          puts get_word_in_context(contents, instance)
        end
        puts "\n"
      end
    else
      puts "Query returned to results."
    end
  end
  
  # the program should display a list of the documents that contain all of the terms
  # one per line together with the sum of the tf.idf scores for the input terms in that document. 
  # The list should be ordered in descending order of total tf.idf scores.
  def query_multiple_words(words)
    words.map { |word| word.stem! } # stem all the words
    words.reject! { |word| word_does_not_belong(word) } # remove the ones that don't count
    words.reject! { |word| @word_list[word].nil? } # remove search terms not in word list
    # Get all the documents that all the words are in (intersection)
    documents = find_documents_with_all_words(words) unless words.nil? || words.empty?
    unless documents.nil? || documents.empty?
      # For each word
      words.each do |word|
        # We look at each document that word appears in
        @word_list[word].each_key do |document|
          # And if its in the intersected document list
          if !documents[document].nil?
            # We add the tfidf to the current value
            documents[document] += tfidf(word, document)
          end
        end
      end
      # Now we order the documents in descending order by tf.idf score
      documents.sort {|a,b| b[1]<=>a[1]}.each do |document, tfidf|
        # and print both the document name and the tfidf score
        puts "#{document} %.3f" % tfidf
      end
    else
      puts "Query returned no results." 
    end
  end

private
  # When we add an entry to a wordlist, we want to know
  # 1. The word itself
  # 2. What document it came from
  # 3. Where in that document is the word located
  def add(word, document, location)
    @word_list[word] = Hash.new if @word_list[word].nil?
    @word_list[word][document] = Array.new if @word_list[word][document].nil?
    @word_list[word][document] << location
  end
  
  # Let's not include empty, null, or words in the stop list
  def word_does_not_belong(word)
    word.nil? || word.empty? || @stop_list.index(word)
  end
  
  # document frequency: the number of documents in the collection in which the term occurs
  def df(t)
    @word_list[t].size
  end
  
  # inverse document frequency: idf is a measure of the informativeness of the term.
  # We use [log(N/dft)] instead of [N/dft] to “dampen” the
  # effect of idf.
  def idf(t)
    Math.log10(@documents.size.to_f/df(t).to_f)
  end
  
  # term frequency: number of times that t occurs in d
  def tf(t, d)
    @word_list[t][d].size
  end
  
  # log frequency weight: The log frequency weight of term t in d
  def w(t, d)
    tf(t, d) > 0 ? 1 + Math.log10(tf(t, d)) : 0
  end
  
  # The tf.idf weight of a term is the product of its 
  # tf weight and its idf weight.
  def tfidf(t, d)
    w(t, d) * idf(t)
  end
  
  # given a document and a location, give me some 
  # characters before and after that location
  def get_word_in_context(d, loc)
    before = 20
    after = 20
    "\t... #{d[(loc-before < 0 ? 0 : loc-before)..(loc+after > d.size ? d.size : loc+after)]} ..."
  end
  
  # given a set of words, we find all documents that have all these words
  def find_documents_with_all_words(words)
    # Just get the names of all possible documents
    documents = @documents.keys
    # Now for each word passed in
    words.each do |word|
      # We do a repeated setwise intersection
      documents = documents & @word_list[word].keys unless @word_list[word].nil? || @word_list[word].empty?
    end
    # Now we have all the documents that all the words are in.
    # And we transform that into a Hashtable where the keys are the
    # names of those documents and the values are initialized to zero.
    documents.inject(Hash.new) {|a,b| a.merge({b,0})}
  end
end

class String
  # Here we're adding a special new method to the String
  # class that allows us to split on a separator, giving us
  # tokens, but we also get the index of that token in the form
  # [token, index]
  def split_with_index(sep)
    ret = Array.new
    current = ["", 0]
    index = 0
    while index < self.size
      if self[index].chr == sep
        ret << current
        current = ["", index + 1]
      else
        current[0] << self[index]
      end
      index += 1
    end
    ret << current
    ret
  end
  
  def stem!
    self.gsub!(/[\W]+/, '') # strip garbage
    self.downcase! unless self.nil? # downcase if there's anything left
  end
end