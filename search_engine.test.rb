require "test/unit"
require "pp"
require "search_engine.rb"

class TestSearchEngine < Test::Unit::TestCase
  def test_query
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    search_engine.query('bin')
  end
  
  def test_query_multiple
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    search_engine.query_multiple_words(['look', 'four'])
  end
  
  def test_print_word_list
    search_engine = SearchEngine.new('./test/file*','stoplist.txt')
    search_engine.print_word_list(5000)
  end
  
  def test_split_with_index
    assert_equal([["hello", 0], ["", 6], ["there", 7]], "hello  there".split_with_index(' '))
  end
  
  def test_stop_list
    stop_list = File.read('stoplist.txt').split
    assert(stop_list.index("and"), "stop list should contain 'and'")
    assert(!stop_list.index("foo"), "stop list should not contain 'foo'")
  end
  
  def test_log
    assert_equal(2, Math.log10(100))
  end
  
  def test_strip_non_word_chars
    assert_equal("helloworld", "Hello ^^^$$$#12313123World".stem!)
    assert_equal(nil, "!@#^&*234234".stem!)
  end
  
  def test_float_to_s
    assert_equal("3.14", "%.2f" % 3.14159)
  end
end
