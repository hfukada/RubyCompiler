require './src/parser'
require './src/tokenizer'
require './src/symtable'
require './src/grammar'
require './src/codegen'

class RubyCompiler
  @parseStack
  @parseTable
  @indexedGrammar
  @symbolTree
  @blockPointer
  @currType
  @blockIndex

  def initialize(file)
    @parseStack = Grammar::DEFINITIONS["program"].split 
    @parseTable = {}
    @indexedGrammar = []
    @symbolTree= { 'vars' => [], 'funcs' => [] }
    @blockPointer= [@symbolTree]
    @currentBlock= @blockPointer.last
    @currentVariables = []

    @currType = ''
    @blockIndex = 1
    @infile = File.new(file, "r")
    @currline = ''
    createParseTable()
  end
  def compile()
    begin
      lastImportant = ''
      @infile.each_line {|line|
        @currline = line
        ignoreLine = 1
        doDecls = 1
        cleanline = (line.include?('--')? line[0,line.index('--')] : line)
        cleanline.lstrip! 

        tokens = self.tokenizeLine(cleanline)

        if !tokens.empty? and tokens[0][1] =~ /^(FUNCTION|INT|FLOAT|STRING|IF|ELSIF|ENDIF|DO|WHILE|END)$/
          ignoreLine = 0
          if tokens[0][1] =~ /^(IF|ELSIF|ENDIF|DO|WHILE|END)$/
            doDecls = 0
          end
        end

        tokens.each{|tok|
          declError = 0
          token = tok[1] =~ Grammar::TERMINALS ? tok[1] : tok[0]
          error,reply = self.processSingleToken(token.strip)
          if ignoreLine == 0
            declError = self.addToStack(tok, doDecls)
          end
          if error == 1
            puts "Not Accepted"
            exit
          end
          if declError == 1
            print "DECLARATION ERROR #{tok[1]}\r\n"
            exit
          end
        }
      }
    rescue => e
      puts e.message
      puts e.backtrace.inspect
    ensure
      @infile.close unless @infile.nil?
    end
  end

end
