require './src/parser'
require './src/tokenizer'
require './src/symtable'
require './src/grammar'

class RubyCompiler
  @parseStack
  @parseTable
  @indexedGrammar

  def initialize
    @parseStack = Grammar::DEFINITIONS["program"].split 
    @parseTable = {}
    @indexedGrammar = []
  end

end
