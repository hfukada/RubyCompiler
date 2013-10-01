require './src/parser'
require './src/tokenizer'
require './src/symtable'
require './src/grammar'

class RubyCompiler
  @parseStack
  @parseTable
  @indexedGrammar
  @symbolTree
  @blockPointer
  @currType
  @blockIndex

  def initialize
    @parseStack = Grammar::DEFINITIONS["program"].split 
    @parseTable = {}
    @indexedGrammar = []
    @symbolTree= { 'vars' => [], 'funcs' => [] }
    @blockPointer= [@symbolTree]
    @currentBlock= @blockPointer.last
    @currentVariables = []

    @currType = ''
    @blockIndex = 1
  end

end
