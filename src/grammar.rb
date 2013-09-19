#!/^(usr/bin/ruby

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
    TERMINAL = /^(PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSIF|ENDIF|DO|WHILE|CONTINUE|BREAK|RETURN|INT|VOID|STRING|FLOAT|TRUE|FALSE|:=|\+|-|\*|\/|=|!=|<|>|\(|\)|;|,|<=|>=)$/
    DESCRIBERS = /^(INTLITERAL|FLOATLITERAL|STRINGLITERAL|IDENTIFIER)$/

    DEFINITIONS = {
    "program"          => "PROGRAM id BEGIN pgm_body END",
    "id"               => "IDENTIFIER",
    "pgm_body"         => "decl func_declarations",

    "decl"             => "STRING string_decl_list decl_tail|INT var_decl_list decl_tail|FLOAT var_decl_list decl_tail|empty",
    "decl_tail"        => "decl|empty",

    "string_decl_list" => "string_decl string_decl_tail",
    "string_decl_tail" => "STRING string_decl string_decl_tail|empty",
    "string_decl"      => "id :=> STRINGLITERAL ;|empty",

    "var_decl_list"    => "var_decl var_decl_tail",
    "var_decl_tail"    => "FLOAT var_decl var_decl_tail|INT var_decl var_decl_tail|empty",
    "var_decl"         => "id_list ;|empty", # or empty
    "id_list"          => "id id_tail", #id id_tail
    "id_tail"          => ", id id_tail|empty", #, id id_tail | empty
    "var_type"         => "FLOAT|INT",
    "any_type"         => "FLOAT|INT|VOID", #

    "param_decl_list"  => "param_decl param_decl_tail",
    "param_decl_tail"  => ", param_decl param_decl_tail|empty", # or empty
    "param_decl"       => "FLOAT id|INT id",  # var_type id

    "func_declarations"=> "func_decl func_decl_tail",
    "func_decl"        => "FUNCTION any_type id ( parameter_decl_list ) BEGIN func_body END|FUNCTION any_type id ( ) BEGIN func_body END|empty",
    "func_decl_tail"   => "func_decl func_decl_tail|empty",
    "func_body"        => "decl stmt_list",

    "stmt_list"        => "stmt stmt_list|empty",
    "stmt"             => "base_stmt|if_stmt|do_while_stmt",
    "base_stmt"        => "assign_stmt|read_stmt|write_stmt|return_stmt",

    "assign_stmt"      => "assign_expr ;",
    "assign_expr"      => "id :=> expr",
    "read_stmt"        => "READ ( id_list ) ;",
    "write_stmt"       => "WRITE ( id_list ) ;",
    "return_stmt"      => "RETURN expr ;",

    "expr"             => "factor expr_tail",
    "expr_tail"        => "addop factor expr_tail|empty",

    "factor"           => "postfix_expr factor_tail",
    "factor_tail"      => "mulop postfix_expr factor_tail|empty",

    "postfix_expr"     => "primary|call_expr",
    "call_expr"        => "id ( expr_list )|id ( )",
    "expr_list"        => "expr expr_list_tail",
    "expr_list_tail"   => ", expr expr_list_tail|empty",
    "primary"          => "( expr )|id|INTLITERAL|FLOATLITERAL",
    "addop"            => "+|-",
    "mulop"            => "*|/",

    "if_stmt"          => "IF ( cond ) decl stmt_list else_part",
    "else_part"        => "ELSIF ( cond ) decl stmt_list else_part | ENDIF",
    "cond"             => "expr compop expr|TRUE|FALSE",
    "compop"           => "<|>|=|!=|<=|>=",

    "do_while_stmt"    => "DO decl stmt_list WHILE ( cond ) ;" }

    TERMINAL_LIST = ["PROGRAM","BEGIN","END","FUNCTION","READ","WRITE","IF","ELSIF","ENDIF","DO","WHILE","CONTINUE","BREAK","RETURN","INT","VOID","STRING","FLOAT","TRUE","FALSE",":=","+","-","*","/","=","!=","<",">","(",")",";",",","<=",">=","INTLITERAL","STRINGLITERAL","FLOATLITERAL","IDENTIFIER"]

end
