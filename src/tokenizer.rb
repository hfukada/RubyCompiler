class RubyCompiler
  # method to tokenize a line
  def tokenizeLine()
    currFront,i = 0,0
    found=false
    tokens = []
    while i < @currline.length
      found = false
      if !(@currline[i] =~ (Grammar::SINGLEOP)).nil?
        basetok = @currline[currFront..i-1]

        if !(basetok =~ /^;/).nil?
          tokens << [ "OPERATOR", ";" ]
          break
        end
        if (@currline[i] =~ /"|'/).nil?
          if !(basetok.strip =~ (Grammar::KEYWORD)).nil?
            tokens << [ "KEYWORD", "#{basetok.strip}" ]
            found = true
          elsif (basetok.strip =~ (Grammar::OPERATOR)).nil?
            if !(basetok.strip =~ (Grammar::INTLITERAL)).nil?
              tokens << [ "INTLITERAL", "#{basetok.strip}" ]
            elsif !(basetok.strip =~ (Grammar::FLOATLITERAL)).nil?
              tokens << [ "FLOATLITERAL", "#{basetok.strip}" ]
            else
              tokens << [ "IDENTIFIER", "#{basetok.strip}" ] if basetok.strip.length > 0

            end
            found = true
          end
          if @currline[i] != ' '
            if !(@currline[i..i+1] =~ (Grammar::OPERATOR)).nil?
              tokens << ["OPERATOR" , "#{@currline[i..i+1]}"]
              i += 1
            elsif !(@currline[i] =~ (Grammar::OPERATOR)).nil? 
              tokens << ["OPERATOR", "#{@currline[i]}"]
            end
            found = true
          end
        else
          endQuo = @currline.index(/'|"/,i+1)
          tokens << [ "STRINGLITERAL", "#{@currline[i..endQuo]}"]
          i = endQuo
          found = true
        end
      end
      i += 1 
      if found
        currFront = i
      end
    end
    tokens
  end
end

