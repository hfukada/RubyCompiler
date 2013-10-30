class RubyCompiler
  def generateWhileCode()
    if @baseWhileStack.last =~ Grammar::COMPOP
      @compop = @baseWhileStack.last
      @compreg1 = generateAnyExpr(@baseWhileStack[2..@baseWhileStack.size-2])
    elsif @baseWhileStack.last == 'DO'
      addLabel
      addIR("LABEL", nil, nil, @labelStack.last)
    elsif @baseWhileStack.last == ';'
      expr = @baseWhileStack[@baseWhileStack.index(@compop)+1..@baseWhileStack.size - 3]
      type=getExprType(expr) == 'INT' ? 'i' : 'r'
      @compreg2 = generateAnyExpr(expr)
      if (isLiteral?(@compreg2) or getType(@compreg2) != -1)
        @compreg2 = loadLiteral(@compreg2)
      end
      addIR(getIRComp(@compop)+type, @compreg1, @compreg2, @labelStack.pop)
    end
  end
  def generateIfCode()
    if @baseIfStack.last() =~ Grammar::COMPOP
       @compop = @baseIfStack.last
       @compreg1 = generateAnyExpr(@baseIfStack[2..@baseIfStack.size-2])
    # elsif @parseStack[0] == 'condend' or @currline =~ /^(ENDIF)$/
    elsif (@baseIfStack.count('(') === @baseIfStack.count(')') and @baseIfStack.count('(') > 0 ) or @currline =~ /^(ENDIF)$/
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
          expr = @baseIfStack[@baseIfStack.index(@compop)+1..@baseIfStack.size - 2]
          type=getExprType(expr) == 'INT' ? 'i' : 'r'
          @compreg2 = generateAnyExpr(expr)
          if (isLiteral?(@compreg2) or getType(@compreg2) != -1)
            @compreg2 = loadLiteral(@compreg2)
          end
          addIR(flipComp(@compop)+type, @compreg1, @compreg2, @labelStack.last)
        end

      else
        # IF case
        addLabel
        addLabel
        if @currline.include?("TRUE") or @currline.include?("FALSE")
          addIR("JUMP", nil, nil, @labelStack.last) if @currline.include?("FALSE")
        else
          expr = @baseIfStack[@baseIfStack.index(@compop)+1..@baseIfStack.size - 2]
          type=getExprType(expr) == 'INT' ? 'i' : 'r'
          @compreg2 = generateAnyExpr(expr)

          if (isLiteral?(@compreg2) or getType(@compreg2) != -1)
            @compreg2 = loadLiteral(@compreg2)
          end
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
    if @baseExprStack[0] == 'READ' or @baseExprStack[0] == 'WRITE' or @baseExprStack[0] == 'RETURN'
      #handle reads, writes, and returns, when this condition is met, the line has been fully added into the stack
      if @baseExprStack.last(2) == [')',';']
        @baseExprStack.delete('(')
        @baseExprStack.delete(';')
        @baseExprStack.delete(')')
        @baseExprStack.delete(',')
        operation = @baseExprStack.shift

        operation += self.getType(@baseExprStack[0]) == 'INT' ? 'I' : 'r'
        @baseExprStack.each{|x|
          addIR(operation, nil, nil, x)
        }
      end
    else
      if @baseExprStack.last == ';'
        type = self.getType(@baseExprStack[0])
        resultReg = generateAnyExpr(@baseExprStack[2..@baseExprStack.size-2])
        op = "STORE"
        op += type  == 'INT' ? 'I' : 'r'
        reg = chooseRegister(type, @baseExprStack[2..@baseExprStack.size-2].join)

        if (isLiteral?(@baseExprStack[2]) or getType(@baseExprStack[2]) != -1) and @baseExprStack.size == 4
          addIR(op, resultReg, nil, reg)
          addIR(op, reg, nil, @baseExprStack[0])
        else
          addIR(op, resultReg, nil, @baseExprStack[0])
        end
      end
    end
  end
  def generateAnyExpr(expr)
    exprStack = []
    type=getExprType(expr)
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
        # pop off the mult op
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
        #type = self.getType(@baseExprStack[0])
        op += type == 'INT' ? 'I' : 'r'
        register = chooseRegister(type, "#{op1r}#{op}#{op2r}")

        self.addIR(op, op1, op2, register)

        temp.push(register)
      else
        temp.push(tok)
      end
    }
    #printA(temp)
    while temp.size > 1 do
      op1 = temp.shift
      op = temp.shift
      op2 = temp.shift
      op1r = op1
      op2r = op2

      #puts "op :#{op}| op1 :#{op1}| op2 :#{op2}"

      #type = self.getType(@baseExprStack[0])
      if isLiteral?(op1)
        op1 = loadLiteral(op1)
      end
      if isLiteral?(op2)
        op2 = loadLiteral(op2)
      end
      op = op == '+' ? 'ADD' : 'SUB'
      op += type == 'INT' ? 'I' : 'r'

      register = chooseRegister(type,"#{op1r}#{op}#{op2r}")
      self.addIR(op, op1r, op2r, register)
      temp.unshift(register)
    end
    temp.last
  end
  def addIR(op, op1, op2, dest)
    @IRStack.push({:opcode => op, :op1 => op1, :op2 => op2, :result => dest})
  end
  def chooseRegister(type, hash)
    @regindex+=1
    @usedRegisters[hash] = {:type => type , :reg => "r#{@regindex}"}
    "r#{@regindex}"
  end
  def printIRStack()
    @IRStack.each{|instr|
      printOP(instr,true)
    }
  end
  def printOP(instr, comment = false)
    print ';              ' if comment
    if instr[:op1].nil?
      puts "#{instr[:opcode]} #{instr[:result]}"
    elsif instr[:op2].nil?
      puts "#{instr[:opcode]} #{instr[:op1]} #{instr[:result]}"
    else
      puts "#{instr[:opcode]} #{instr[:op1]} #{instr[:op2]} #{instr[:result]}"
    end
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
    code = []
    @IRStack.each{|line|
      if line[:opcode] == 'var' or line[:opcode] == 'str'
        printOP(line)
      elsif line[:opcode].include?('STORE')
        temp = {:opcode => 'move', :op1 => line[:op1].downcase, :result => line[:result]}
        printOP(temp)
      elsif line[:opcode] =~ /WRITE|READ/
        temp = {:opcode => 'sys', :op1 => line[:opcode].downcase, :result => line[:result]}
        printOP(temp)
      elsif line[:opcode] =~ /^(ADD|SUB|MUL|DIV)/
        temp = {:opcode => 'move', :op1 => line[:op1], :result => line[:result]}
        printOP(temp)
        temp = {:opcode => line[:opcode].downcase, :op1 => line[:op2], :result => line[:result]}
        printOP(temp)
      elsif line[:opcode] =~ /^(LT|GT|LE|GE|EQ|NE)/
        temp = {:opcode => "cmp#{line[:opcode][-1]}".downcase, :op1 => line[:op1].downcase, :result => line[:op2]}
        printOP(temp)
        temp = {:opcode => "j#{line[:opcode][0,2]}".downcase, :result => line[:result]}
        printOP(temp)
      elsif line[:opcode] =~ /^(LABEL)/
        temp = {:opcode => line[:opcode].downcase, :result => line[:result]}
        printOP(temp)
      elsif line[:opcode] == 'JUMP'
        temp = {:opcode => 'jmp', :result => line[:result]}
        printOP(temp)
      end
    }
    puts "sys halt"
  end
end
