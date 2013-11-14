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
      @compreg1 = generateAnyExpr(tokenValues[2..tokenValues.size-2],@baseWhileStack[2..tokenValues.size-2])

    elsif tokenValues.last == 'DO'
      addLabel
      addIR("LABEL", nil, nil, @labelStack.last)

    elsif tokenValues.last == ';'
      expr = tokenValues[tokenValues.index(@compop)+1..tokenValues.size - 3]
      exprWithGrammar = @baseWhileStack[tokenValues.index(@compop)+1..tokenValues.size - 3]
      type=getExprType(expr) == 'INT' ? 'i' : 'r'
      @compreg2 = generateAnyExpr(expr, exprWithGrammar)
      addIR(getIRComp(@compop)+type, @compreg1, @compreg2, @labelStack.pop)

    end

  end

  def generateIfCode()
    tokenValues = @baseIfStack.map{|k| k[0]}

    if tokenValues.last() =~ Grammar::COMPOP
       @compop = tokenValues.last
       @compreg1 = generateAnyExpr(tokenValues[2..tokenValues.size-2],@baseIfStack[2..tokenValues.size-2])

    elsif @baseIfStack.last == [')','condend'] or @currline =~ /(ENDIF)/
      if @currline.include?("ENDIF")
        # end if label
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
          @compreg2 = generateAnyExpr(expr, exprWithGrammar, true)
          addIR(flipComp(@compop)+type, @compreg1, @compreg2, @labelStack.last)

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
          @compreg2 = generateAnyExpr(expr, exprWithGrammar, true)

          addIR(flipComp(@compop)+type, @compreg1, @compreg2, @labelStack.last)
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
        tokenValues.each{|x|
          addIR(operation, nil, nil, x)
        }
      end
    else
      if tokenValues.last == ';'
        type = self.getType(tokenValues[0])
        generateExpr(tokenValues[2..tokenValues.size-2])
        resultReg = generateAnyExpr(tokenValues[2..tokenValues.size-2], @baseExprStack[2..tokenValues.size-2])
        op = "STORE"
        op += type  == 'INT' ? 'I' : 'r'
        reg = chooseRegister(type, tokenValues[2..tokenValues.size-2].join)

        if (isLiteral?(tokenValues[2]) or getType(tokenValues[2]) != -1) and tokenValues.size == 4
          addIR(op, resultReg, nil, reg)
          addIR(op, reg, nil, tokenValues[0])
        else
          addIR(op, resultReg, nil, tokenValues[0])
        end
      end
    end
  end

  def generateExpr(expr)
    postfix = generatePostfix(expr)

    while !postfix.empty?
      tok = postfix.shift
      case tok[1]
      when 'OPERATION'
      when 'LITERAL'
      when 'VARIABLE'
      else #FUNCTION
      end
    end
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
          opStack.push tok
        else
          while !opStack.empty? and opOrder(opStack.last) > opOrder(tok) do
            postfix.push [opStack.pop, 'OPERATION']
          end
          opStack.push tok
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
          postfix.push [tok, expr[i+2..parenEndIdx]
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

  def addIR(op, op1, op2, dest)
    if @IRStack[@currFunc].nil?
      @IRStack[@currFunc] = [{:opcode => op, :op1 => op1, :op2 => op2, :result => dest}]
    else
      @IRStack[@currFunc].push({:opcode => op, :op1 => op1, :op2 => op2, :result => dest})
    end
  end

  def chooseRegister(type, hash)
    @regindex+=1
    @usedRegisters[hash] = {:type => type , :reg => "r#{@regindex}"}
    "r#{@regindex}"
  end
  def printIRStack()
    @IRStack.each{|func, nodes|
      puts ";     #{func}"
      nodes.each{|instr|
        printOP(instr,true)
      }
    }
  end
  def printOP(instr, comment = false)
    print ';              ' if comment
    instr.delete_if{|k,v| v.nil?}
    puts instr.values.join(' ')
  end
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

  def printA(arr)
    arr.each{|a|
      print "#{a}|"
    }
    print "\n"
  end

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

  def functionCall(expr)

  end

  def loadSymbol(symbol, type)
    reg = chooseRegister(type, symbol)
    op = "STORE"
    op += type  == 'INT' ? 'I' : 'r'
    addIR(op, symbol, nil, reg)
    return reg
  end

  def loadLiteral(lit)
    #puts "#{lit} is a literal yo"
    register = chooseRegister(lit.include?('.')? 'FLOAT' : 'INT', "#{lit}")
    if lit.include?('.')
      addIR("STOREF",lit, nil, register)
    else
      addIR("STOREI", lit, nil, register)
    end
    register
  end

  def isInRegister(hash)
    return @usedRegisters[hash]
  end

  def getExprType(expr)
    if expr[0] == '('
      getExprType(expr[1..expr.size])
    else
      getType(expr[0])
    end
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
          temp = {:opcode => 'move', :op1 => line[:op1], :result => line[:result]}
          printOP(temp)
          temp = {:opcode => line[:opcode].downcase, :op1 => line[:op2], :result => line[:result]}
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
