class RubyCompiler

  def generateFuncCode(parsedToken)
    if parsedToken == [')','func_decl_param'] #symbolizes end of function declation
      @currFunc = @scopeStack.last[:name]
      addIR("LABEL", nil, nil, @currFunc)
      addIR("LINK", nil, nil, "100")
    elsif parsedToken == ['END', 'func_decl_param']
      addIR("UNLNK",nil,nil,nil)
      addIR("RET", nil, nil, nil)
    end
  end

  def generateWhileCode()
    tokenValues = @baseWhileStack.map{|k| k[0]}

    if tokenValues.last =~ Grammar::COMPOP
      @compop = tokenValues.last
      #@compreg1 = generateAnyExpr(tokenValues[2..tokenValues.size-2],@baseWhileStack[2..tokenValues.size-2])
      @compreg1 = generateExpr(tokenValues[2..tokenValues.size-2],@baseWhileStack[2..tokenValues.size-2])
      @usedRegisters[@compreg1][:preserve] = 1

    elsif tokenValues.last == 'DO'
      addLabel
      addIR("LABEL", nil, nil, @labelStack.last)
      resetRegisters

    elsif tokenValues.last == ';'
      expr = tokenValues[tokenValues.index(@compop)+1..tokenValues.size - 3]
      exprWithGrammar = @baseWhileStack[tokenValues.index(@compop)+1..tokenValues.size - 3]
      type=getExprType(expr) == 'INT' ? 'i' : 'r'
      #@compreg2 = generateAnyExpr(expr, exprWithGrammar)
      @compreg2 = generateExpr(expr, exprWithGrammar)
      addIR(getIRComp(@compop)+type, "r#{@compreg1}", "r#{@compreg2}", @labelStack.pop)
      @usedRegisters[@compreg1][:preserve] = 0

    end

  end

  def generateIfCode()
    tokenValues = @baseIfStack.map{|k| k[0]}

    if tokenValues.last() =~ Grammar::COMPOP
       resetRegisters
       @compop = tokenValues.last

       @compreg1 = generateExpr(tokenValues[2..tokenValues.size-2],@baseIfStack[2..tokenValues.size-2])
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
          type=getExprType(expr) == 'INT' ? 'i' : 'r'
          @compreg2 = generateExpr(expr, exprWithGrammar)
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
          type=getExprType(expr) == 'INT' ? 'i' : 'r'
          #@compreg2 = generateAnyExpr(expr, exprWithGrammar, true)
          @compreg2 = generateExpr(expr, exprWithGrammar)

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
    if tokenValues[0] == 'READ' or tokenValues[0] == 'WRITE' or tokenValues[0] == 'RETURN'
      #handle reads, writes, and returns, when this condition is met, the line has been fully added into the stack
      if tokenValues.last(2) == [')',';']
        tokenValues.delete('(')
        tokenValues.delete(';')
        tokenValues.delete(')')
        tokenValues.delete(',')
        operation = tokenValues.shift

        operation += self.getType(tokenValues[0]) == 'INT' ? 'I' : 'r'
        tokenValues.each{|var|
          addIR(operation, nil, nil, var)
        }
      end
    else
      if tokenValues.last == ';'
        type = getType(tokenValues[0])
        resultReg = generateExpr(tokenValues[2..tokenValues.size-2], type)
        checkAndStore(resultReg, tokenValues[0], type)
        #type = self.getType(tokenValues[0])
        #generateExpr(tokenValues[2..tokenValues.size-2])
        #resultReg = generateAnyExpr(tokenValues[2..tokenValues.size-2], @baseExprStack[2..tokenValues.size-2])
        #op = "STORE"
        #op += type  == 'INT' ? 'I' : 'r'
        #reg = chooseRegister(type, tokenValues[2..tokenValues.size-2].join)

        #if (isLiteral?(tokenValues[2]) or getType(tokenValues[2]) != -1) and tokenValues.size == 4
        #  addIR(op, resultReg, nil, reg)
        #  addIR(op, reg, nil, tokenValues[0])
        #else
        #  addIR(op, resultReg, nil, tokenValues[0])
        #end
      end
    end
  end

  def generateExpr(expr, type)
    # handle the case, that the expr only has one thing
    if expr.size == 1
      return loadTok(expr[0], type)
    end

    postfix = generatePostfix(expr)
    exprStack = []
    #printA postfix.map{|i|i[0]}

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

          #puts "------"
          #puts "#{op1}#{tok[0]}#{op2}"
          #puts "------"
          #printRegs
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
          # the first argument must be in the register
          #if opArg1 == -1
          #  opArg1 = loadTok(op1, type)
          #end
          #@usedRegisters[opArg1][:preserve] = 1

          ## if not in register and is a literal, load it
          #reg2 = -1
          #if opArg2 == -1 and isLiteral?(op2)
          #  reg2 = loadTok(op2, type)
          #  opArg2 = "r#{reg2}"
          #  @usedRegisters[reg2][:preserve] = 1
          ## if not in register, but it is a variable we can directly use it for second argument
          #elsif opArg2 == -1 and !isLiteral?(op2)
          #  opArg2 = op2
          #else
          #  reg2 = opArg2
          #  opArg2 = "r#{opArg2}"
          #  @usedRegisters[reg2][:preserve] = 1
          #end


          # always store our result in arg2, because it is a guaranteed register
          addIR(op, "r#{opArg1}", opArg2, "r#{opArg1}")
          #puts "r#{opArg1} #{opArg2} = #{op1}#{tok[0]}#{op2}"
          #printRegs

          setReg(opArg1,"#{op1}#{tok[0]}#{op2}", 0)
          if reg2 != -1
            @usedRegisters[reg2][:preserve] = 0
          end
          exprStack.push("#{op1}#{tok[0]}#{op2}")
        end
      when 'LITERAL', 'VARIABLE'
        exprStack.push tok[0]
      else #FUNCTION
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
          parenEndIdx = getMatchingParenIndex(expr, i+2) - 1
          #result = callFunction(tok, expr[i+2..parenEndIdx])
          i = parenEndIdx + 1

          # need to figure out how to handle generating IR code in the middle of expr to handle this.

          #end state should be ") expr#
          postfix.push [tok, expr[i+2..parenEndIdx]]
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

    opt += type == 'INT' ? 'I' : 'R'
  end

  def generateAnyExpr(expr, exprwithgrammer=nil, force=false)
    exprStack = []
    type=getExprType(expr)
    if expr.size == 1
      if isLiteral?(expr[0])
        return loadLiteral(expr[0])
      else
        if force == true
          return loadSymbol(expr[0], type)
        end
        return expr[0]
      end
    end
    while (expr.size != 0) do
      exprStack.push(expr.shift)
      if exprStack.last == ')'
        resultReg = generateExprSegment(exprStack[exprStack.rindex('(')+1..exprStack.size-2], type)
        exprStack = exprStack.first(exprStack.rindex('('))
        exprStack.push resultReg
      end
    end
    generateExprSegment(exprStack, type)
  end

  def generateExprSegment(segment, type)
    temp = []
    i = 1
    if segment.size == 1
      return segment[0]
    end
    segment.each{|tok|
      if temp.last == '*' or temp.last == '/'
        op = temp.pop == '*' ? 'MUL' : 'DIV'
        op1 = temp.pop
        op2 = tok
        op1r = op1
        op2r = op2

        if isLiteral?(op1)
          op1 = loadLiteral(op1)
        end
        if isLiteral?(op2)
          op2 = loadLiteral(op2)
        end

        op += type == 'INT' ? 'I' : 'r'
        register = chooseRegister(type, "#{op1r}#{op}#{op2r}")

        self.addIR(op, op1, op2, register)

        temp.push(register)
      else
        temp.push(tok)
      end
    }

    while temp.size > 1 do
      op1 = temp.shift
      op = temp.shift
      op2 = temp.shift
      op1r = op1
      op2r = op2

      if isLiteral?(op1)
        op1 = loadLiteral(op1)
      end
      if isLiteral?(op2)
        op2 = loadLiteral(op2)
      end
      op = op == '+' ? 'ADD' : 'SUB'
      op += type == 'INT' ? 'I' : 'r'

      register = chooseRegister(type,"#{op1r}#{op}#{op2r}")
      self.addIR(op, op1, op2, register)
      temp.unshift(register)
    end
    temp.last
  end

  def chooseRegister(hash)
    #puts hash
    #printRegs
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

    # make room for register, choose oldest register
    # store the old register IF the hash is a simple variable
    chosenReg = -1
    (0..@usedRegisters.size-1).each{|i|
      if @usedRegisters[i][:time] == 0
        chosenReg = i
        break
      end
    }
    if chosenReg == -1

      max = @usedRegisters.map{|k| k[:time] }.max
      chosenReg = @usedRegisters.map{|k| k[:time]}.index(max)
      #puts chosenReg
      #chosenReg = @usedRegisters.map{|k| k[:time]}.index(@usedRegisters.map{|k| k[:time] }.max)
      #printRegs
      chosenReg = @usedRegisters.map{|k| k[:preserve] == 1 ? -1 : k[:time]}.each_with_index.max[1]
      #puts chosenReg2
      #if chosenReg2 != chosenReg
      #  #printRegs
      #end
      #puts chosenReg
    end
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
      #puts "#{@usedRegisters[i][:hash]} , #{name}"
      @usedRegisters[i][:dirty] = @usedRegisters[i][:hash].include?(name) ? 1 : 0
    }
  end

  def checkAndStore(reg, name, type)
    # make anything containing the name of the variable in the register cache dead/dirty
    dirtyRegisters!(reg, name)

    op = "STORE"
    op += type  == 'INT' ? 'I' : 'r'

    # store the desired reg into the name
    # keep result in reg with the name as hash
    #puts "r#{reg} --> #{name}"
    addIR(op, "r#{reg}", nil, name)
    @usedRegisters[reg][:hash] = name
    @usedRegisters[reg][:dirty] = 0
    #printRegs
    #puts ''
  end

  def symbolInRegister?(hash)
    (0..@usedRegisters.size-1).each{|i|
      if @usedRegisters[i][:hash] == hash and @usedRegisters[i][:dirty] == 0
        return i
      end
    }
    return -1
  end


  def functionCall(expr)
  end

  def loadTok(symbol, type)
    if isLiteral?(symbol)
      loadLiteral(symbol)
    else
      loadSymbol(symbol, type)
    end
  end

  def loadSymbol(symbol, type)
    #puts symbol
    #printRegs
    reg = symbolInRegister?(symbol)
    if reg != -1
      return reg
    end
    reg = chooseRegister(symbol)
    op = "STORE"
    op += type  == 'INT' ? 'I' : 'R'
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
      nodes.each{|instr|
        printOP(instr,true)
      }
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
        if line[:opcode] =~ /(var|str|LINK|UNLNK|RET)/
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
        end
        printOP(temp)
      }
    }
    puts "end"
  end
end
