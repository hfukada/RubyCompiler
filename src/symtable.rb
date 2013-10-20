require './src/grammar'

class RubyCompiler
    def symStack(token, doDecls)
    if token[0] =~ Grammar::DESCRIBERS or token[1] =~ Grammar::SYMBOLPUSH
      if token[0] == 'IDENTIFIER'
        if doDecls == 1 and includeVar?(token[1])
          if @currMode[:type] == 'FUNCTION'
          # new function here
            @scopeStack.push({ :name => token[1], :begin => @usableVariablesStack.size})
            @currMode= {}
          else
          # new variable Decl
            @usableVariablesStack.push({ :name => token[1], :type => @currMode[:type] })
          end
        elsif doDecls == 1 and !includeVar?(token[1])
          return 1
        end
      elsif token[0] =~ Grammar::LITERALS 
        if doDecls == 1
          @usableVariablesStack.last[:val] = token[1]
        end
      elsif token[1] =~ /^(INT|STRING|FLOAT)$/
        if @currMode[:type] == 'FUNCTION'
          @currMode[:returnType] = token[1]
        else
          @currMode[:type] = token[1]
        end
      elsif token[1] == 'FUNCTION'
        @currMode= {:type => 'FUNCTION'}
      elsif token[1] =~ Grammar::NEWBLOCK
        @scopeStack.push({:name => "BLOCK #{@blockIndex}", :begin => @usableVariablesStack.size})
        @blockIndex += 1
      end
      if token[1] =~ Grammar::ENDBLOCK
        scope = @scopeStack.pop
        variables = @usableVariablesStack.pop(@usableVariablesStack.size - scope[:begin])
        print = "#{scope[:name]}\n"
        variables.each{|var|
          print += "#{var[:name]} : #{var[:type]}\n"
        }
        @sillyPrintStack.push(print)
      end
    end
  end
  def sillyPrintStack()
    while ( @sillyPrintStack.size != 0 )do
      puts @sillyPrintStack.pop
    end
  end
  def includeVar?(token)
    return !(@usableVariablesStack.map{|h| h['name']}.flatten.include?(token))
  end
end
