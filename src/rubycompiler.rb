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
  @currFunc

  @baseExprStack
  @baseIfStack
  @baseWhileStack
  @baseFunctionStack

  @usableVariablesStack
  @scopeStack
  @currMode
  @sillyPrintStack
  @scopeVars
  @regCount

  @IRStack
  @regindex
  @labelindex
  @usedRegisters

  def initialize(file, regNum=4)
    @parseStack = Grammar::DEFINITIONS["program"].split.zip(['program']*(Grammar::DEFINITIONS["program"].split).size)
    @parseTable = {}
    @indexedGrammar = []

    @currType = ''
    @infile = File.new(file, "r")
    @currline = ''
    @baseExprStack = nil
    @baseIfStack = nil
    @baseWhileStack = nil

    @usableVariablesStack = []
    @scopeStack = [{ :name => 'GLOBAL', :begin => @usableVariablesStack.size}]
    @currMode = {}
    @currFunc = "GLOBAL"
    @sillyPrintStack = []
    @scopeVars = {}

    @IRStack = {}

    @regindex = -1
    @labelindex = 0
    @regCount = regNum
    @usedRegisters=[]

    resetRegisters
    

    @labelStack = []
    @blockIndex = 1
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
          parsed_tok = self.processSingleToken(token.strip, tok[1].strip)

          if ignoreLine == 0
            declError = self.symStack(tok, parsed_tok, doDecls)
          end
          if parsed_tok == "error"
            puts "Not Accepted"
            exit
          end
          if declError == 1
            print "DECLARATION ERROR #{tok[1]}\r\n"
            exit
          end


          if !@baseExprStack.nil?
            self.generateBaseExprCode
          end
          if !@baseIfStack.nil?
            self.generateIfCode
          end
          if !@baseWhileStack.nil?
            self.generateWhileCode
          end
          self.generateFuncCode(parsed_tok)

        }
        @baseIfStack= nil
        @baseExprStack = nil
        @baseWhileStack = nil
      }
      #self.sillyPrintStack

      doFunctionIRAdjustments

      #self.printIRStack
      #self.IRtoASM
    rescue => e
      puts e.message
      puts e.backtrace.inspect
    ensure
      @infile.close unless @infile.nil?
    end
  end

end
