require './src/grammar'

class RubyCompiler
  def addToStack(token)
    if token[0] =~ Grammar::DESCRIBERS or token[1] =~ Grammar::SYMBOLPUSH
      lastPushed = @symbolStack.last
      #if ( lastPushed == 'FUNCTION' or lastPushed == 'PROGRAM' ) and token[0] == 'IDENTIFIER'
      #  @symbolStack += [token]
      #else
      #  if shouldInclude(token)
      if !(token[0] == 'IDENTIFIER' and shouldIgnore?(token[1]))
        @symbolStack += [token]
      end
      #  end
      #end
    end
  end
  def shouldIgnore?(token)
    i = @symbolStack.size-1
    while @symbolStack[i][0] == 'IDENTIFIER'
      i-=1
    end
    return !(@symbolStack[i][1] =~ Grammar::ALLOWIDENT)
  end
  def printSymbolStack()
    @symbolStack.each{|tok|
      puts tok[1]
    }
    type = @symbolStack[0][1]
    i = 0
    blocknum = 1
    isFuncDecl = 0
    while i < @symbolStack.size
      if @symbolStack[i][1] == 'PROGRAM'
        i += 1
        puts 'Symbol table GLOBAL'
      else
        if @symbolStack[i][1] =~ /^(INT|STRING|FLOAT|FUNCTION)$/
          type = @symbolStack[i][1]
          isFuncDecl = type=='FUNCTION' ? 1 : isFuncDecl
        elsif @symbolStack[i][0] == 'IDENTIFIER'
          if type != 'FUNCTION'
            if @symbolStack[i+1][0] =~ Grammar::LITERALS
              puts "name #{@symbolStack[i][1]} type #{type} value #{@symbolStack[i+1][1]}"
              i += 1
            else
              puts "name #{@symbolStack[i][1]} type #{type}"
            end
          else
            puts "\nSymbol table #{@symbolStack[i][1]}"
          end
        else
          #begin stuff
          if @symbolStack[i][1] =~ Grammar::NEWBLOCK && isFuncDecl == 0
            puts "\nSymbol table BLOCK #{blocknum}"
            blocknum += 1
          elsif isFuncDecl == 1
            isFuncDecl = 0
          end
        end
      end
      i+=1
    end
  end
end
