#!/^(usr/bin/ruby

class Grammar 
    KEYWORD = /^(PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSIF|ENDIF|DO|WHILE|CONTINUE|BREAK|RETURN|INT|VOID|STRING|FLOAT|TRUE|FALSE)$/
    OPERATOR = /^(:=|\+|-|\*|\/|=|!=|<|>|\(|\)|;|,|<=|>=)$/
    STRINGLITERAL = /^(".*")$/
    INTLITERAL = /^([0-9]+)$/
    FLOATLITERAL = /^([0-9]*\.[0-9]+)$/
    SINGLEOP = /^(:|\+|-|\*|\/|!|<|>|\(|\)|;|,|\n|'|"| |=)$/

end
