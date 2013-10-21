class RubyCompiler
  def generateCode()
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
      if @baseExprStack.last == ')'
        # grab the top of the stack, from the last '(' to the last ')'
        resultReg = generateSegment(@baseExprStack[@baseExprStack.rindex('(')+1..@baseExprStack.size-2])
        @baseExprStack = @baseExprStack.first(@baseExprStack.rindex('('))
        @baseExprStack.push resultReg
      elsif @baseExprStack.last == ';'
        resultReg = generateSegment(@baseExprStack[2..@baseExprStack.size-2])
        if isLiteral?(@baseExprStack[2])
          op = "STORE"
          op += self.getType(@baseExprStack[0]) == 'INT' ? 'I' : 'r'
          reg = chooseRegister
          addIR(op, resultReg, nil, reg)
          addIR(op, reg, nil, @baseExprStack[0])
        else
          op = "STORE"
          op += self.getType(@baseExprStack[0]) == 'INT' ? 'I' : 'r'
          reg = chooseRegister
          addIR(op, resultReg, nil, @baseExprStack[0])
        end
      end
    end
  end
  def generateSegment(segment)
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

        if isLiteral?(op1)
          op1 = loadLiteral(op1)
        end
        if isLiteral?(op2)
          op2 = loadLiteral(op2)
        end
        register = chooseRegister
        op += self.getType(@baseExprStack[0]) == 'INT' ? 'I' : 'r'

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

      #puts "op :#{op}| op1 :#{op1}| op2 :#{op2}"

      if isLiteral?(op1)
        op1 = loadLiteral(op1)
      end
      if isLiteral?(op2)
        op2 = loadLiteral(op2)
      end
      register = chooseRegister
      op = op == '+' ? 'ADD' : 'SUB'

      op += self.getType(@baseExprStack[0]) == 'INT' ? 'I' : 'r'
      self.addIR(op, op1, op2, register)
      temp.unshift(register)
    end
    temp.last
  end
  def addIR(op, op1, op2, dest)
    @IRStack.push({:opcode => op, :op1 => op1, :op2 => op2, :result => dest})
  end
  def chooseRegister()
    @regindex+=1
    @usedRegisters.push("r#{@regindex}")
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
  def printA(arr)
    arr.each{|a|
      print "#{a}|"
    }
    print "\n"
  end
  def loadLiteral(lit)
    #puts "#{lit} is a literal yo"
    register = chooseRegister
    if lit.include?('.')
      addIR("STOREF",lit, nil, register) 
    else
      addIR("STOREI", lit, nil, register)
    end
    register
  end
  def isLiteral?(tok)
    #puts tok
    #printA(@usedRegisters)
    self.getType(tok) == -1 and !@usedRegisters.include?(tok)
  end
  def IRtoASM()
    code = []
    @IRStack.each{|line|
      printOP(line, true)
      if line[:opcode] == 'var' or line[:opcode] == 'str'
        printOP(line)
      elsif line[:opcode].include?('STORE')
        line[:opcode] = 'move'
        printOP(line)
      elsif line[:opcode] =~ /WRITE|READ/
        temp = {:opcode => 'sys', :op1 => line[:opcode].downcase, :result => line[:result]}
        printOP(temp)
      elsif line[:opcode] =~ /^(ADD|SUB|MUL|DIV)/
        temp = {:opcode => 'move', :op1 => line[:op1], :result => line[:result]}
        printOP(temp)
        temp = {:opcode => line[:opcode].downcase, :op1 => line[:op2], :result => line[:result]}
        printOP(temp)
      end
    }
    puts "sys halt"
  end
end
