class RubyCompiler

  def generateFuncCode(parsedToken)
    if parsedToken == [')','func_decl_param'] #symbolizes end of function declation
      @currFunc = @scopeStack.last[:name]
      addIR("LABEL", nil, nil, @currFunc)
      addIR("LINK", nil, nil, "100")
      resetRegisters
    end
  end

  def generateWhileCode()
    tokenValues = @baseWhileStack.map{|k| k[0]}

    if tokenValues.last =~ Grammar::COMPOP
      @compop = tokenValues.last
      expr = tokenValues[2..tokenValues.size-2] 
      type=getExprType(expr)
      @compreg1 = generateExpr( expr, type )
      @usedRegisters[@compreg1][:preserve] = 1

    elsif tokenValues.last == 'DO'
      addLabel
      addIR("LABEL", nil, nil, @labelStack.last)
      resetRegisters

    elsif tokenValues.last == ';'
      expr = tokenValues[tokenValues.index(@compop)+1..tokenValues.size - 3]
      exprWithGrammar = @baseWhileStack[tokenValues.index(@compop)+1..tokenValues.size - 3]
      type=getExprType(expr)
      @compreg2 = generateExpr(expr, type)
      addIR(getIRComp(@compop)+type, "r#{@compreg1}", "r#{@compreg2}", @labelStack.pop)
      @usedRegisters[@compreg1][:preserve] = 0

    end

  end

  def generateIfCode()
    tokenValues = @baseIfStack.map{|k| k[0]}

    if tokenValues.last() =~ Grammar::COMPOP
      resetRegisters
      @compop = tokenValues.last

      expr= tokenValues[2..tokenValues.size-2]
      getExprType(expr)
      type=getExprType(expr)
      @compreg1 = generateExpr(expr, type)
      @usedRegisters[@compreg1][:preserve] = 1

    elsif @baseIfStack.last == [')','condend'] or @currline =~ /(ENDIF)/
      if @currline.include?("ENDIF")
        # end if label
        resetRegisters
        addIR("LABEL", nil, nil, @labelStack.pop)
        addIR("LABEL", nil, nil, @labelStack.pop)

      elsif @currline.include?("ELSIF")
        # ELSIF case
        currlabel = @labelStack.pop
        endlabel = @labelStack.last
        addLabel

        addIR("JUMP", nil, nil, endlabel)
        addIR("LABEL", nil, nil, currlabel)

        if @currline.include?("TRUE") or @currline.include?("FALSE")
          addIR("JUMP", nil, nil, @labelStack.last) if @currline.include?("FALSE")

        else
          expr = tokenValues[tokenValues.index(@compop)+1..tokenValues.size - 2]
          exprWithGrammar = @baseIfStack[tokenValues.index(@compop)+1..tokenValues.size - 2]
          type=getExprType(expr)
          @compreg2 = generateExpr(expr, type)
          addIR(flipComp(@compop)+type, "r#{@compreg1}", "r#{@compreg2}", @labelStack.last)

          @usedRegisters[@compreg1][:preserve] = 0

        end
      else
        # IF case
        addLabel
        addLabel

        if @currline.include?("TRUE") or @currline.include?("FALSE")
          addIR("JUMP", nil, nil, @labelStack.last) if @currline.include?("FALSE")

        else
          expr = tokenValues[tokenValues.index(@compop)+1..tokenValues.size - 2]
          exprWithGrammar = @baseIfStack[tokenValues.index(@compop)+1..tokenValues.size - 2]
          type=getExprType(expr)
          @compreg2 = generateExpr(expr, type)

          addIR(flipComp(@compop)+type, "r#{@compreg1}", "r#{@compreg2}", @labelStack.last)
        end
      end
    end
  end

  def addLabel()
    @labelStack.push "label#{@labelindex}"
    @labelindex += 1
  end

  def generateBaseExprCode()
    tokenValues = @baseExprStack.map{|k| k[0]}
    if tokenValues[0] == 'READ' or tokenValues[0] == 'WRITE'
      #handle reads, writes, and returns, when this condition is met, the line has been fully added into the stack
      if tokenValues.last(2) == [')',';']
        tokenValues.delete('(')
        tokenValues.delete(';')
        tokenValues.delete(')')
        tokenValues.delete(',')
        operation = tokenValues.shift

        tokenValues.each{|var|
          t = self.getType(var)
          addIR("#{operation}#{t}", nil, nil, var)
        }
      end
    elsif tokenValues[0] == 'RETURN' and tokenValues.last == ';'
      type = getExprType(tokenValues[1..tokenValues.size-2])
      resultReg = generateExpr(tokenValues[1..tokenValues.size-2], type)
      addIR("STORE#{type}", "r#{resultReg}", nil, '$R')
      addIR("RETURN", nil, nil, nil)
    else
      if tokenValues.last == ';'
        type = getType(tokenValues[0])
        resultReg = generateExpr(tokenValues[2..tokenValues.size-2], type)
        checkAndStore(resultReg, tokenValues[0], type)
      end
    end
  end

  def generateExpr(expr, type)
    postfix = generatePostfix(expr)
    exprStack = []

    # handle the case, that the expr only has one thing
    if postfix.size == 1
      if postfix[0][1]== 'LITERAL' or postfix[0][1] == 'VARIABLE'
        return loadTok(postfix[0][0], type)
      else
        return functionCall(postfix[0], type)
      end
    end

    while !postfix.empty?
      tok = postfix.shift

      case tok[1]
      when 'OPERATION'
        op2 = exprStack.pop
        op1 = exprStack.pop
        op = getOpText(tok[0], type)

        # check if op1 op op2 exist in the registers already (the full shabangdang)
        fullExprReg = symbolInRegister? "#{op1}#{tok[0]}#{op2}"
        if fullExprReg != -1
          # we are in luck that this expression exists!
          # push the hash for this register on, and that's it!

          exprStack.push("#{op1}#{tok[0]}#{op2}")
        else
          # check if ops exist in the registers
          opArg1 = symbolInRegister? op1
          opArg2 = symbolInRegister? op2

          reg2 = -1
          if opArg1 >= 0 and opArg2 >= 0
            @usedRegisters[opArg1][:preserve] = 1
            @usedRegisters[opArg2][:preserve] = 1
            reg2 = opArg2
            opArg2 = "r#{opArg2}"

          elsif opArg1 < 0 and opArg2 >= 0
            @usedRegisters[opArg2][:preserve] = 1
            opArg1 = loadTok(op1, type)
            @usedRegisters[opArg1][:preserve] = 1
            reg2 = opArg2
            opArg2 = "r#{opArg2}"

          elsif opArg1 >=0 and opArg2 < 0
            @usedRegisters[opArg1][:preserve] = 1
            if isLiteral?(op2)
              reg2 = loadTok(op2, type)
              @usedRegisters[reg2][:preserve] = 1
              opArg2 = "r#{reg2}"

            else
              opArg2 = op2
            end

          else
            opArg1 = loadTok(op1, type)
            @usedRegisters[opArg1][:preserve] = 1
            opArg2 = loadTok(op2, type)
            @usedRegisters[opArg2][:preserve] = 1
            reg2 = opArg2
            opArg2 = "r#{opArg2}"

          end

          # always store our result in arg2, because it is a guaranteed register
          addIR(op, "r#{opArg1}", opArg2, "r#{opArg1}")

          setReg(opArg1,"#{op1}#{tok[0]}#{op2}", 0)
          if reg2 != -1
            @usedRegisters[reg2][:preserve] = 0
          end
          exprStack.push("#{op1}#{tok[0]}#{op2}")
        end
      when 'LITERAL', 'VARIABLE'
        exprStack.push tok[0]
      else #FUNCTION
        puts "; calling Function"
        result = functionCall(tok, type)
        exprStack.push result
      end
    end
    return opArg1
  end

  def generatePostfix(expr, strtIdx = 0, endIdx = expr.size)
    i = strtIdx
    opStack = []
    postfix = []
    while i < endIdx do
      tok = expr[i]
      tokType = getTokenType(tok)
      if tok == '('
        parenEndIdx = getMatchingParenIndex(expr,i)
        postfix += generatePostfix(expr, i+1, parenEndIdx)
        i = parenEndIdx + 1

      elsif tokType == 'OPERATION'
        if opStack.empty?
          opStack.push [tok,'OPERATION']
        else
          while !opStack.empty? and opOrder(opStack.last) > opOrder(tok) do
            postfix.push opStack.pop
          end
          opStack.push [tok, 'OPERATION']
        end
        i += 1
      else
        case tokType
        when 'LITERAL','VARIABLE'
          postfix.push [tok, tokType]
        when 'FUNCTION'
          # expr[0] => function name
          # expr[1] => (
          # expr[2] => arg 1 begin
          parenEndIdx = getMatchingParenIndex(expr, i+1)
          postfix.push [tok, expr[i+2..parenEndIdx-1]]
          i = parenEndIdx

          # do calling of function inside the IR generation
          #end state should be ") expr#
        end
        i += 1
      end
    end
    while !opStack.empty? do
      postfix.push opStack.pop
    end
    postfix
  end

  def opOrder(op)
    case op
    when '-', '+'
      0
    else
      1
    end
  end

  def getOpText(op, type)
    case op
    when '-'
      opt = 'SUB'
    when '+'
      opt = 'ADD'
    when '*'
      opt = 'MUL'
    else '/'
      opt = 'DIV'
    end

    opt += type
  end

  def chooseRegister(hash)
    (0..@usedRegisters.size-1).each{|i|
      if @usedRegisters[i][:hash] != ""
        @usedRegisters[i][:time] += 1
      end
    }

    # check for clean register with same value
    reg = symbolInRegister?(hash)
    return reg if reg != -1

    # check for clean registers
    (0..@usedRegisters.size-1).each{|i|
      if @usedRegisters[i][:hash] == ""
        setReg(i, hash)
        return i
      end
    }

    #chosenReg = @usedRegisters.size
    #@usedRegisters += []
    chosenReg = @usedRegisters.map{|k| k[:preserve] == 1 ? -1 : k[:time]}.each_with_index.max[1]
    setReg(chosenReg, hash, 1)
  end

  def setReg(regNum, hash="", preserve=0)
    @usedRegisters[regNum] = {:hash=>hash, :dirty=>0, :time=>0, :preserve=>preserve }
    return regNum
  end

  def resetRegisters()
    @usedRegisters = []
    (1..@regCount).each{|u|
      @usedRegisters += [{:hash => "", :dirty => 0, :time => 0, :preserve => 0}]
    }
  end

  def printRegs()
    @usedRegisters.each{|r|
      puts r
    }
  end

  def dirtyRegisters!(idx, name)
    (0..@usedRegisters.size-1).each{|i|
      @usedRegisters[i][:dirty] = @usedRegisters[i][:hash].include?(name) ? 1 : 0
    }
  end

  def checkAndStore(reg, name, type)
    # make anything containing the name of the variable in the register cache dead/dirty
    dirtyRegisters!(reg, name)

    op = "STORE"
    op += type

    # store the desired reg into the name
    # keep result in reg with the name as hash
    addIR(op, "r#{reg}", nil, name)
    @usedRegisters[reg][:hash] = name
    @usedRegisters[reg][:dirty] = 0
  end

  def symbolInRegister?(hash)
    (0..@usedRegisters.size-1).each{|i|
      if @usedRegisters[i][:hash] == hash and @usedRegisters[i][:dirty] == 0
        return i
      end
    }
    return -1
  end

  def functionCall(func, type)
    funcName = func[0]
    args = func[1].chunk{|i| i == ',' }.map{|j,k| k == [','] ? nil : k}.compact

    # push return value space
    # push paraneters onto stack
    exprRegs=[]
    args.each{|expr|
      exprRegs += [generateExpr(expr,type)]
    }

    addIR("PUSH", nil, nil, nil)

    #push expr param
    exprRegs.each{|reg|
      addIR("PUSH", nil, nil, "r#{reg}")
    }

    (0..@regCount-1).each{|k|
      addIR("PUSH", nil, nil, "r#{k}")
    }

    addIR("JSR", nil, nil, funcName)

    # pop registers
    (0..@regCount-1).each{|k|
      addIR("POP", nil, nil, "r#{3-k}")
    }

    # pop parameters
    args.each{|expr|
      addIR("POP", nil, nil, nil)
    }

    resultReg = chooseRegister(func.flatten.join)
    addIR("POP", nil, nil, "r#{resultReg}")
    resultReg
  end

  def loadTok(symbol, type)
    if isLiteral?(symbol)
      loadLiteral(symbol)
    else
      loadSymbol(symbol, type)
    end
  end

  def loadSymbol(symbol, type)
    reg = symbolInRegister?(symbol)
    if reg != -1
      return reg
    end
    reg = chooseRegister(symbol)
    op = "STORE"
    op += type
    addIR(op, symbol, nil, "r#{reg}")
    return reg
  end

  # loading literal values
  def loadLiteral(lit)
    reg = symbolInRegister?(lit)
    if reg != -1
      return reg
    end
    register = chooseRegister(lit)
    if lit.include?('.')
      addIR("STOREF", lit, nil, "r#{register}")
    else
      addIR("STOREI", lit, nil, "r#{register}")
    end
    register
  end

  # fixed to allow for identifying function return types
  def getExprType(expr)
    if getTokenType(expr[0]) == 'FUNCTION'
      return getReturnType expr[0]
    end
    if expr[0] == '('
      getExprType(expr[1..expr.size])
    else
      getType(expr[0])
    end
  end

  # helpers for debugging
  def printA(arr)
    print ";   "
    arr.each{|a|
      print "#{a}|"
    }
    print "\n"
  end

  # easier ident. of where blocks begin and end in a single line
  def getMatchingParenIndex(expr, firstIdx)
    p = 0

    (firstIdx..expr.size-1).each{|i|
      tok = expr[i]
      if tok == '('
        p+=1
      elsif tok == ')'
        p-=1
      end
      return i if p == 0
    }
  end

  # function that mainly have to do with printing actual IR/ASM code
  def getIRComp(op)
    case op
    when '<'
      'LT'
    when '>'
      'GT'
    when '<='
      'LE'
    when '>='
      'GE'
    when '='
      'EQ'
    else
      'NE'
    end
  end
  def flipComp(op)
    case op
    when '<'
      'GE'
    when '>'
      'LE'
    when '<='
      'GT'
    when '>='
      'LT'
    when '='
      'NE'
    else
      'EQ'
    end
  end
  def printOP(instr, comment = false)
    print ';              ' if comment
    instr.delete_if{|k,v| v.nil?}
    puts instr.values.join(' ')
  end

  def addIR(op, op1, op2, dest)
    if @IRStack[@currFunc].nil?
      @IRStack[@currFunc] = [{:opcode => op, :op1 => op1, :op2 => op2, :result => dest}]
    else
      @IRStack[@currFunc].push({:opcode => op, :op1 => op1, :op2 => op2, :result => dest})
    end
  end

  def printIRStack()
    @IRStack.each{|func, nodes|
      puts ";     #{func}"
      #printA getVariablesByScope(func)
      nodes.each{|instr|
        printOP(instr,true)
      }
    }
  end

  # this function modifies the IR nodes to use variables on the stack, and not use names
  def doFunctionIRAdjustments()
    @IRStack.each{|func, nodes|
      if func != 'GLOBAL'
        #puts "; #{func} params: "
        params = {}
        paramlist = getParamsByScope(func)
        stackParamIdx = paramlist.size + 6 - 1
        paramlist.each{|v|
          params[v[:name]] = {:type => v[:type], :stackid => stackParamIdx }
          stackParamIdx -= 1
        }

        temps = {}
        templist = getTempVarsByScope(func)
        stackTempIdx = -1
        templist.each{|v|
          temps[v[:name]] = {:type => v[:type], :stackid => stackTempIdx }
          stackTempIdx -= 1
        }
        returnPtr = paramlist.size + 6
        nodes.map{|line|
          if line[:opcode] == 'LINK'
            line[:result] = temps.size
          else
            if !temps[line[:op1]].nil?
              line[:op1] = "$#{temps[line[:op1]][:stackid]}"
            elsif !params[line[:op1]].nil?
              line[:op1] = "$#{params[line[:op1]][:stackid]}"
            end
            if !temps[line[:op2]].nil?
              line[:op2] = "$#{temps[line[:op2]][:stackid]}"
            elsif !params[line[:op2]].nil?
              line[:op2] = "$#{params[line[:op2]][:stackid]}"
            end
            if !temps[line[:result]].nil?
              line[:result] = "$#{temps[line[:result]][:stackid]}"
            elsif !params[line[:result]].nil?
              line[:result] = "$#{params[line[:result]][:stackid]}"
            end
            if line[:result] == '$R'
              line[:result] = "$#{returnPtr}"
            end
          end
        }
      end
    }
  end

  def IRtoASM()
    mainlink = 0
    @IRStack.each{|func, nodes|
      if !@IRStack.keys.index('main').nil? and func != "GLOBAL" and mainlink == 0
        printOP({:opcode => 'push'})
        printOP({:opcode => 'push', :result => 'r0'})
        printOP({:opcode => 'push', :result => 'r1'})
        printOP({:opcode => 'push', :result => 'r2'})
        printOP({:opcode => 'push', :result => 'r3'})
        printOP({:opcode => 'jsr', :result => 'main'})
        printOP({:opcode => 'sys', :result => 'halt'})
        mainlink = 1
      end
      nodes.each{|line|
        if line[:opcode] =~ /(var|str|LINK|UNLNK)/
          temp = line
          temp[:opcode].downcase!
        elsif line[:opcode].include?('STORE')
          temp = {:opcode => 'move', :op1 => line[:op1].downcase, :result => line[:result]}
        elsif line[:opcode] =~ /WRITE|READ/
          temp = {:opcode => 'sys', :op1 => line[:opcode].downcase, :result => line[:result]}
        elsif line[:opcode] =~ /^(ADD|SUB|MUL|DIV)/
          #temp = {:opcode => 'move', :op1 => line[:op1], :result => line[:result]}
          #printOP(temp)
          #temp = {:opcode => line[:opcode].downcase, :op1 => line[:op2], :result => line[:result]}
          temp = {:opcode => line[:opcode].downcase, :op1 => line[:op2], :result => line[:op1]}
        elsif line[:opcode] =~ /^(LT|GT|LE|GE|EQ|NE)/
          temp = {:opcode => "cmp#{line[:opcode][-1]}".downcase, :op1 => line[:op1].downcase, :result => line[:op2]}
          printOP(temp)
          temp = {:opcode => "j#{line[:opcode][0,2]}".downcase, :result => line[:result]}
        elsif line[:opcode] =~ /^(LABEL)/
          temp = {:opcode => line[:opcode].downcase, :result => line[:result]}
        elsif line[:opcode] == 'JUMP'
          temp = {:opcode => 'jmp', :result => line[:result]}
        elsif line[:opcode] == 'JSR'
          temp = {:opcode => 'jsr', :result => line[:result]}
        elsif line[:opcode] == 'POP' or line[:opcode] == 'PUSH'
          temp = {:opcode => line[:opcode].downcase, :result => line[:result]}
        elsif line[:opcode] == 'RETURN'
          temp = {:opcode => 'unlnk'}
          printOP(temp)
          temp = {:opcode => 'ret'}
        end
        printOP(temp)
      }
    }
    puts "end"
  end
end
