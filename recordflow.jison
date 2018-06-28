//* description: Parses RecordFlow Statements. */

/* manipulation functions */
%{
const warehouse = require('./warehouse');
const filter = require('./filter');
const {record, record_item} = require('./record');
%}

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
[a-zA-Z]([a-zA-Z0-9])*    return 'IDENTIFIER'
[0-9]+("."[0-9]+)?        return 'NUMBER'
\'([a-zA-Z0-9])*\'          return 'STRING'
"->"                        return 'RARROW'
"<-"                        return 'LARROW'
":"                         return ':'
"{"                         return '{'
"}"                         return '}'
","                         return ','
"="                         return '='
">"                         return '>'
"<"                         return '<'
<<EOF>>                     return 'EOF'

/lex

/* operator associations and precedence */

%left RARROW
%left LARROW

%start input

%% /* language grammar */

input
    : exps EOF
    ;

exps
    : exp
    | exps exp
    ;

exp
    : exp_insert
    | exp_query
    | exp_update
    ;

exp_insert
    : collection_entity LARROW record_entity
        {warehouse.collection($1).append($3);}
    ;

exp_query
    : collection_entity
        {console.log(warehouse.collection($1).toString());}
    | record_map
        {console.log($1.toString());}
    ;

exp_update
    : record_map LARROW record_entity
        {console.log('one update action');}
    ;

record_entity
    : '{' record_items '}'
        {{
            let rec = new record();
            rec.appendItems($2);
            $$ = rec;
        }}
    ;

record_items
    : record_item
        {{
            if (Array.isArray($$)) {
                $$.push($1);
            } else {
                $$ = [$1];
            }
        }}
    | record_items ',' record_item
        {{
            if (Array.isArray($$)) {
                $$.push($3);
            } else {
                $$ = [$3];
            }
        }}
    ;

record_item
    : record_item_name ':' record_item_value_string
        {$$ = new record_item($1, $3.substr(1,$3.length-2));}
    | record_item_name ':' record_item_value_number
        {$$ = new record_item($1, Number($3));}
    ;

record_item_name
    : IDENTIFIER
    ;

record_item_value
    : record_item_value_string
    | record_item_value_number
    ;

record_item_value_string
    : STRING
    ;

record_item_value_number
    : NUMBER
    ;

record_map
    : collection_entity RARROW record_filter_entity
        {$$ = warehouse.collection($1).record($3);}
    ;

record_filter_entity
    : '{' record_filter '}'
        {$$ = $2;}
    ;

record_filter
    : record_filter_function
    | record_filter_comparison
    ;

record_filter_function
    : ':' record_filter_function_name
        {$$ = filter[$2]();}
    ;

record_filter_function_name
    : IDENTIFIER
    ;

record_filter_comparison
    : record_filter_comparison_equal
    | record_filter_comparison_gt
    | record_filter_comparison_lt
    ;

record_filter_comparison_equal
    : record_item_name '=' record_item_value
        {$$ = filter['equal']($1, $3);}
    ;

record_filter_comparison_gt
    : record_item_name '>' record_item_value_number
        {$$ = filter['gt']($1, $3);}
    ;

record_filter_comparison_lt
    : record_item_name '<' record_item_value_number
        {$$ = filter['lt']($1, $3);}
    ;

collection_entity
    : IDENTIFIER
    ;

