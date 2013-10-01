require './src/grammar'

class RubyCompiler
  def addToStack(token, doDecls)
    if token[0] =~ Grammar::DESCRIBERS or token[1] =~ Grammar::SYMBOLPUSH
      if token[0] == 'IDENTIFIER'
        if doDecls == 1 and includeVariable?(token[1])
          if @currType.class == {}.class
            @currType[:name] = token[1]
            @currType['vars'] = []
            @currType['blocks'] = []
            @symbolTree['funcs'] += [@currType]
            @currType = ''
            @blockPointer += [@symbolTree['funcs'].last]
            @currentBlock = @symbolTree['funcs'].last
          else
            @currentBlock['vars'] += [{:name => token[1], :type => @currType, :val => nil }]
          end
        elsif doDecls == 1 and !includeVariable?(token[1])
          return 1
        end
      elsif token[0] =~ Grammar::LITERALS 
        if doDecls == 1
          @currentBlock['vars'].last[:val] = token[1]
        end
      elsif token[1] =~ /^(INT|STRING|FLOAT)$/
        if @currType.class == {}.class
          @currType[:returnType] = token[1]
        else
          @currType = token[1]
        end
      elsif token[1] == 'FUNCTION'
        @currType = {:name => '', :returnType =>''}
      elsif token[1] =~ Grammar::NEWBLOCK
        @currentBlock['blocks'] += [{:name => "BLOCK #{@blockIndex}", 'vars' => [], 'blocks' => []}]
        @blockIndex += 1
        @blockPointer += [@currentBlock['blocks'].last]
        @currentBlock = @blockPointer.last
      end
      if token[1] =~ Grammar::ENDBLOCK
        @blockPointer.pop
        @currentBlock = @blockPointer.last
      end
    end
    0
  end
  def ignoreGlobals?()
    if @symbolTree['funcs'].include?(@currentBlock)
      return 1
    end
    return 0
  end
  def includeVariable?(token)
    ignoreGlobals = ignoreGlobals?
    if ignoreGlobals == 0
      if @symbolTree['vars'].empty?
        return true
      end
      @symbolTree['vars'].each{|global|
        if global[:name].nil?
          return true
        end
        if global[:name] == token
          return false
        end
      }
    end
    if @currentBlock['vars'].empty?
      return true
    else
      @currentBlock['vars'].each{|varhash|
        if varhash[:name] == token
          return false
        end
      }
    end
    true
  end

  def printSymbolTable(level = @symbolTree, label = 'GLOBAL', indent = 0)
    if level.nil?
      return
    end
    spacing = ' ' * indent
    spacing = ''
    print "Symbol table #{label}\r\n"

    if !level['vars'].nil?
      level['vars'].each{|var|
        if var[:val].nil?
          print "name #{var[:name]} type #{var[:type]}\r\n"
        else
          print "name #{var[:name]} type #{var[:type]} value #{var[:val]}\r\n"
        end
      }
    end
    if !level['blocks'].nil?
      level['blocks'].each{|block|
        puts ''
        printSymbolTable(block, block[:name], indent+1)
      }
    end
    if level == @symbolTree and !@symbolTree['funcs'].nil?
      @symbolTree['funcs'].each{|funcs|
        puts ''
        printSymbolTable(funcs, funcs[:name], indent+1)
      }
    end
  end
end
