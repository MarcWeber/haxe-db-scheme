package mw.relational_scheme;
import haxe.macro.Expr;
import haxe.macro.Context;
import mw.relational_scheme.FieldType;

import mw.relational_scheme.Table;

using mw.Assertions;

/* attempt of Mysql Scheme without common base class
   Is this simpler?
*/

using mw.macro.StructureHelpers;

class Field {
  
  public var table: Table;

  public var name(get,null): String;
  function get_name(){ return o.name; }

  public var type(get,null): FieldType;
  function get_type(){ return o.fieldType; }

  public var o: {
    name: String,
    fieldType: FieldType,
    nullable: Bool,
    comment: String,
    ?references: {table:String, field:String}
  };

  public function new(table, o) {
    this.table = table;
    this.o = o;
  }

  macro static public function create(table: ExprOf<Table>, name: ExprOf<String>, fieldType: ExprOf<FieldType>, o:Expr):ExprOf<Field> {
    return macro {
      new Field(${table},
        mw.macro.StructureHelpers.sh_merge_override(
        {nullable: false, comment: "", references: null},
        {name: ${name}, fieldType: ${fieldType}},
        ${o} ));
    }
  }

  public function check() {
  }

}
