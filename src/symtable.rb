require './src/grammar'

class RubyCompiler
  def addToStack(token)
    if token[0] == 'IDENTIFIER' or token[1] =~ Grammar::SYMBOLPUSH
      lastPushed = @symbolStack.last
      if ( lastPushed == 'FUNCTION' or lastPushed == 'PROGRAM' ) and token[0] == 'IDENTIFIER'
        @symbolStack += [token]
      else
        if shouldInclude(token)
          @symbolStack += [token]
        end
      end
    end
  end
  def shouldInclude(token)
    i = @symbolStack.size-1
    while @symbolStack[i][0] != 'IDENTIFIER'
      i--
    end
    return !(symbolStack[i][0] == 'FLOAT' or symbolStack[i][0] == 'STRING' or symbolStack[i][0] == 'INT')
  end
  def printSymbolStack()
    @symbolStack.each{|tok|
      puts tok[1]
    }
  end
end
