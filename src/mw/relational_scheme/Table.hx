package mw.relational_scheme;
import haxe.macro.Expr;
import haxe.macro.Context;
import mw.mysql.FieldType;

import mw.relational_scheme.Field;

using mw.Assertions;

class Table {

  public var scheme: Scheme;
  public var o: {
    name: String,
    fields: Map<String, Field>,
    primaryKeyFields: Array<String>,
    indexes: Array<Array<String>>,
    uniqIndexes: Array<Array<String>>,
    comment: String
  };

  public var name(get,null): String;
  function get_name(){ return o.name; }

  public function new(scheme, o) {
    this.scheme = scheme;
    this.o = o;
  }

  inline public function fieldByName(s:String) {
    return this.o.fields.get(s);
  }

  public function addField(f:Field) {
    var n:String = f.name;
    if (o.fields.exists(n))
      throw 'cannot add table ${n} twice';
    this.o.fields.set(n, f);
    return this;
  }

  macro public function createField(table:Expr, name: ExprOf<String>, fieldType:ExprOf<FieldType>, o:Expr):Expr {
    return macro
     ${table}.addField(Field.create(${table}, ${name}, ${fieldType}, ${o}));
  }

  macro static public function create(scheme: ExprOf<Scheme>, name:ExprOf<String>, o:Expr ):ExprOf<Table> {
    return macro new Table(${scheme},
        mw.macro.StructureHelpers.sh_merge_override(
        {primaryKeyFields: [], indexes: [], uniqIndexes: [], comment: "", fields: new Map<String, Field>()},
        {name: ${name}},
        ${o}));
  }

  public function check() {
    HashExtensions.eachKeyValue(o.fields, function(k,f){
      if (k != f.name) throw "name missmatch";
      f.check();
    });
  }
}

