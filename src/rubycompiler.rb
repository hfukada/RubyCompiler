require './src/parser'
require './src/tokenizer'
require './src/symtable'
require './src/grammar'

class RubyCompiler
  @parseStack
  @parseTable
  @indexedGrammar
  @symbolStack
  @symbolTree
  @blockIndex
  @functionIndex
  @globals

  def initialize
    @parseStack = Grammar::DEFINITIONS["program"].split 
    @parseTable = {}
    @indexedGrammar = []
    @symbolStack =[['KEYWORD', 'PROGRAM']]
    @symbolTree = []
    @blockIndex = 0
    @functionIndex = 0
  end

end
