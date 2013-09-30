#!/usr/bin/ruby

class Regexp
    def +(r)
        source+source.r
    end
end

class Grammar 
    KEYWORD = /^(PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSIF|ENDIF|DO|WHILE|CONTINUE|BREAK|RETURN|INT|VOID|STRING|FLOAT|TRUE|FALSE)$/
    OPERATOR = /^(:=|\+|-|\*|\/|=|!=|<|>|\(|\)|;|,|<=|>=)$/
    STRINGLITERAL = /^(".*")$/
    INTLITERAL = /^([0-9]+)$/
    FLOATLITERAL = /^([0-9]*\.[0-9]+)$/
    SINGLEOP = /^(:|\+|-|\*|\/|!|<|>|\(|\)|;|,|\n|'|"| |=)$/
    TERMINALS = /^(PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSIF|ENDIF|DO|WHILE|CONTINUE|BREAK|RETURN|INT|VOID|STRING|FLOAT|TRUE|FALSE|:=|\+|-|\*|\/|=|!=|<|>|\(|\)|;|,|<=|>=)$/
    DESCRIBERS = /^(INTLITERAL|FLOATLITERAL|STRINGLITERAL|IDENTIFIER)$/
    LITERALS = /^(FLOATLITERAL|STRINGLITERAL|IDENTIFIER)$/
    SYMBOLPUSH = /^(FUNCTION|FLOAT|INT|STRING|BEGIN|END|DO|WHILE|IF|ELSIF|ENDIF)$/
    ALLOWIDENT = /^(FUNCTION|FLOAT|INT|STRING)$/
    NEWBLOCK = /^(DO|IF|ELSIF|BEGIN)$/
    ENDBLOCK = /^(END|WHILE|ENDIF)$/

    DEFINITIONS = {
    "program"          => "PROGRAM id BEGIN pgm_body END",
    "id"               => "IDENTIFIER",
    "pgm_body"         => "decl func_declarations|empty",

    "decl"             => "string_decl_list decl|var_decl_list decl|empty",

    "string_decl_list" => "string_decl string_decl_tail",
    "string_decl_tail" => "string_decl string_decl_tail|empty",
    "string_decl"      => "STRING id := STRINGLITERAL ;|empty",

    "var_decl_list"    => "var_decl var_decl_tail",
    "var_decl_tail"    => "var_decl var_decl_tail|var_decl var_decl_tail|empty",
    "var_decl"         => "FLOAT id_list ;|INT id_list ;|empty",
    "id_list"          => "id id_tail",
    "id_tail"          => ", id id_tail|empty",
    "any_type"         => "FLOAT|INT|VOID",

    "param_decl_list"  => "param_decl param_decl_tail",
    "param_decl_tail"  => ", param_decl param_decl_tail|empty", # or empty
    "param_decl"       => "FLOAT id|INT id",

    "func_declarations"=> "func_decl func_decl_tail|empty",
    "func_decl_tail"   => "func_decl func_decl_tail|empty",
    "func_decl"        => "FUNCTION any_type id ( func_decl_param",
    "func_decl_param"  => "param_decl_list ) BEGIN func_body END|) BEGIN func_body END",
    "func_body"        => "decl stmt_list",

    "stmt_list"        => "stmt stmt_list|empty",
    "stmt"             => "base_stmt|if_stmt|do_while_stmt",
    "base_stmt"        => "assign_stmt|read_stmt|write_stmt|return_stmt",

    "assign_stmt"      => "assign_expr ;",
    "assign_expr"      => "id := expr",
    "read_stmt"        => "READ ( id_list ) ;",
    "write_stmt"       => "WRITE ( id_list ) ;",
    "return_stmt"      => "RETURN expr ;",

    "expr"             => "factor expr_tail",
    "expr_tail"        => "addop factor expr_tail|empty",
    "expr_list"        => "expr expr_list_tail",
    "expr_list_tail"   => ", expr expr_list_tail|empty",

    "factor"           => "postfix_expr factor_tail",
    "factor_tail"      => "mulop postfix_expr factor_tail|empty",

    "postfix_expr"     => "id call_expr|( expr )|INTLITERAL|FLOATLITERAL",
    "call_expr"        => "( call_expr_tail )|empty",
    "call_expr_tail"   => "expr_list|empty",


    "addop"            => "+|-",
    "mulop"            => "*|/",

    "if_stmt"          => "IF ( cond ) decl stmt_list else_part",
    "else_part"        => "ELSIF ( cond ) decl stmt_list else_part | ENDIF",
    "cond"             => "expr compop expr|TRUE|FALSE",
    "compop"           => "<|>|=|!=|<=|>=",

    "do_while_stmt"    => "DO decl stmt_list WHILE ( cond ) ;" }

    TERMINAL_LIST = ["PROGRAM","BEGIN","END","FUNCTION","READ","WRITE","IF","ELSIF","ENDIF","DO","WHILE","CONTINUE","BREAK","RETURN","INT","VOID","STRING","FLOAT","TRUE","FALSE",":=","+","-","*","/","=","!=","<",">","(",")",";",",","<=",">=","INTLITERAL","STRINGLITERAL","FLOATLITERAL","IDENTIFIER"]

end
