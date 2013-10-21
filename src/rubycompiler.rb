require './src/parser'
require './src/tokenizer'
require './src/symtable'
require './src/grammar'
require './src/codegen'

class RubyCompiler
  @parseStack
  @parseTable
  @indexedGrammar

  @currType
  @blockIndex
  @infile
  @currline
  @baseExprStack

  @usableVariablesStack
  @scopeStack
  @currMode
  @sillyPrintStack

  @IRStack
  @regindex
  @usedRegisters


  def initialize(file)
    @parseStack = Grammar::DEFINITIONS["program"].split 
    @parseTable = {}
    @indexedGrammar = []

    @currType = ''
    @infile = File.new(file, "r")
    @currline = ''
    @baseExprStack = nil

    @usableVariablesStack = []
    @scopeStack = [{ :name => 'GLOBAL', :begin => @usableVariablesStack.size}]
    @currMode = {}
    @sillyPrintStack = []

    @IRStack = []

    @regindex = -1
    @usedRegisters = []
    createParseTable()
  end
  def compile()
    begin
      lastImportant = ''
      @infile.each_line {|line|
        ignoreLine = 1
        doDecls = 1
        @currline= (line.include?('--')? line[0,line.index('--')] : line)
        @currline.lstrip!

        tokens = self.tokenizeLine()

        if !tokens.empty? and tokens[0][1] =~ /^(FUNCTION|INT|FLOAT|STRING|IF|ELSIF|ENDIF|DO|WHILE|END)$/
          ignoreLine = 0
          if tokens[0][1] =~ /^(IF|ELSIF|ENDIF|DO|WHILE|END)$/
            doDecls = 0
          end
        end

        tokens.each{|tok|
          declError = 0
          token = tok[1] =~ Grammar::TERMINALS ? tok[1] : tok[0]
          error,reply = self.processSingleToken(token.strip, tok[1].strip)

          if ignoreLine == 0
            declError = self.symStack(tok, doDecls)
          end
          if error == 1
            puts "Not Accepted"
            exit
          end
          if declError == 1
            print "DECLARATION ERROR #{tok[1]}\r\n"
            exit
          end

          if !@baseExprStack.nil?
            self.generateCode
          end
        }
        @baseExprStack = nil
      }
      #self.sillyPrintStack
      self.printIRStack
      self.IRtoASM
    rescue => e
      puts e.message
      puts e.backtrace.inspect
    ensure
      @infile.close unless @infile.nil?
    end
  end

end
