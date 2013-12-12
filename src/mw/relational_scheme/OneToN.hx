package mw.relational_scheme;
import haxe.macro.Expr;
import haxe.macro.Context;
import mw.mysql.FieldType;

import mw.relational_scheme.Field;
import mw.relational_scheme.Relationship;

using mw.Assertions;
class OneToN implements Relationship {
  public var scheme: Scheme;
  public var o:{
    one:String,
    n:String,
    ?oneField:String,
    forceParent: Bool,
  };
  public function new(scheme:Scheme, o) {
    this.scheme = scheme;
    this.o = o;
  }
  inline static public function create(m, o) {
    return new OneToN(m, o);
  }
  public function finalise(){
    var t_one = scheme.tables.get(o.one);
    var t_n: Table = scheme.tableByName(o.one);

    var p = t_n.o.primaryKeyFields[0].assert_nn();
    // TODO
    // t_n.createField(p, t_one.fieldByName(p).type, {references: {table:  o.one, field: p}});
  }
}

