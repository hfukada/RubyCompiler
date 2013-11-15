require './src/grammar'

class RubyCompiler
    def symStack(token, contextToken, doDecls)
    if token[0] =~ Grammar::DESCRIBERS or token[1] =~ Grammar::SYMBOLPUSH
      if token[0] == 'IDENTIFIER'
        if doDecls == 1 and includeVar?(token[1])
          if @currMode[:type] == 'FUNCTION'
          # new function here
            if @currFunc  == "GLOBAL"
              # print globals
              @usableVariablesStack.each{|var|
                type = var[:type] == "s" ? 'str' : 'var'
                if !var[:value].nil?
                  #puts "#{type} #{var[:name]} #{var[:value]}"
                  addIR(type, var[:name], nil, var[:value])
                  #@IRStack.push({:opcode => type , :op1 => var[:name], :result => var[:value]})
                else
                  #@IRStack.push({:opcode => type , :op1 => var[:name]})
                  addIR(type, nil, nil, var[:name])
                  #puts "#{type} #{var[:name]}"
                end
              }
            end
            @scopeStack.push({ :name => token[1], :begin => @usableVariablesStack.size, :returnType => @currMode[:returnType]})
            @currMode= {}
          else
            # new variable Decl
            if contextToken[1] == 'param_decl'
              @usableVariablesStack.push({ :name => token[1], :type => @currMode[:type], :paramDecl => 1})
            else
              @usableVariablesStack.push({ :name => token[1], :type => @currMode[:type], :paramDecl => 0})
            end
          end
        elsif doDecls == 1 and !includeVar?(token[1])
          return 1
        end
      elsif token[0] =~ Grammar::LITERALS 
        if doDecls == 1
          @usableVariablesStack.last[:value] = token[1]
        end
      elsif token[1] =~ /^(INT|STRING|FLOAT)$/
        if @currMode[:type] == 'FUNCTION'
          @currMode[:returnType] = token[1]
        else
          @currMode[:type] = token[1] == 'FLOAT' ? 'r' : token[1][0].downcase
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
        
        @sillyPrintStack.push(scope)
        @scopeVars[scope[:name]] = []
        variables.each{|var|
          @scopeVars[scope[:name]].push(var)
        }
      end
    end
  end
  def printSillyPrintStack()
    printA @sillyPrintStack
    printA @scopeVars
    scope = @sillyPrintStack.pop
    puts scope
    @scopeVars[scope[:name]].each{|var|
      puts var
    }
    while ( @sillyPrintStack.size != 0 )do
      scope = @sillyPrintStack.shift
      puts scope
      @scopeVars[scope[:name]].each{|var|
        puts var
      }
    end
  end

  def getVariablesByScope(scope=@currFunc)
    return @scopeVars[scope]
  end

  def getParamsByScope(scope=@currFunc)
    return getVariablesByScope(scope).map{|p| p[:paramDecl] == 1 ? p : nil }.compact
  end

  def getTempVarsByScope(scope=@currFunc)
    return getVariablesByScope(scope).map{|p| p[:paramDecl] == 0 ? p : nil }.compact
  end

  def includeVar?(token)
    return !(@usableVariablesStack.map{|h| h['name']}.flatten.include?(token))
  end
  
  def getReturnType(name)
    idx = @scopeStack.map{|k| k[:name]}.index(name)
    if !idx.nil?
      return @scopeStack[idx][:returnType]
    end
    return -1
  end

  def getTokenType(name)
    idx = !@sillyPrintStack.map{|k| k[:name]}.index(name).nil? || !@scopeStack.map{|k| k[:name]}.index(name).nil?
    if idx
      return 'FUNCTION'
    end
    i = @usableVariablesStack.size - 1
    while i >= 0 do 
      if name == @usableVariablesStack[i][:name]
        return 'VARIABLE'
      end
      i -= 1
    end
    return name =~ /(-|\+|\/|\*)/ ? 'OPERATION' : 'LITERAL'
  end

  def getType(name)
    i = @usableVariablesStack.size - 1
    while i >= 0 do 
      if name == @usableVariablesStack[i][:name]
        return @usableVariablesStack[i][:type]
      end
      i -= 1
    end
    vars = @scopeStack.map{|k| k[1]}
    if !vars.index(name).nil?
      return @scopeStack[idx][:returnType]
    end
    return name.include?('.')? 'r' : 'i'
  end

  def isLiteral?(name)
    i = @usableVariablesStack.size - 1
    while i >= 0 do 
      if name == @usableVariablesStack[i][:name]
        return false
      end
      i -= 1
    end
    idx = @scopeStack.map{|k| k[1]}.index(name)
    if !idx.nil?
      return false
    end
    return true
  end
end
