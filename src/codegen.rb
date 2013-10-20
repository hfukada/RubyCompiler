
class RubyCompiler
  def generateCode()
    if @baseExprStack.last == ')'
      # grab the top of the stack, from the last '(' to the last ')'
      generateSegment(@baseExprStack[@baseExprStack.rlast('('),@baseExprStack.size-1])
    end
  end
  def generateSegment(segment)
    temp = []
    segment.each{|tok|
      if temp.last == '*'
        # pop off the mult op
        temp.pop
        op1 = temp.pop
        op2 = tok
        register = chooseRegister

        puts "move #{op1}, #{register}\nmuli #{op2} #{register}"
        temp.push(register)
      else
        temp.push(tok.pop)
      end
    }
    while (temp.size > 1) do
      op = temp.pop
      temp.pop
    end
  end
  def chooseRegister()
    3
  end
end
