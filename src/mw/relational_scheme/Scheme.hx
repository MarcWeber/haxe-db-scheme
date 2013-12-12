package mw.relational_scheme;
import haxe.macro.Expr;
import haxe.macro.Context;
import mw.mysql.FieldType;
import mw.relational_scheme.Field;
import mw.relational_scheme.Table;
import mw.relational_scheme.OneToN;
import mw.relational_scheme.MToN;
import mw.relational_scheme.Relationship;

using mw.Assertions;

/* attempt of Mysql Scheme without common base class
   Is this simpler?
*/

using mw.macro.StructureHelpers;

class Scheme {

  public var tables: Map<String, Table>;
  public var relationships: Array<Relationship>;

  public function addTable(t:Table) {
    var n:String = t.name;
    if (tables.exists(n))
      throw 'cannot add table ${n} twice';
    tables.set(n, t);
  }

  inline public function tableByName(s:String):Table {
    return this.tables.get(s);
  }

  public function addRelationship(r:Relationship) {
    this.relationships.push(r);
  }
  public function oneToN(opts) { addRelationship(new OneToN(this, opts)); }
  public function mToN(opts, addFields)   { addRelationship(new MToN(this, opts, addFields)); }

  public function new(){
    this.tables = new Map();
  }

  #if !macro
  public function finalise() {
    for (r in relationships)
      r.finalise();
    check();
  }
  #end

  public function check() {
    for(t in tables) t.check();
  }

  macro public function createTable(scheme:ExprOf<Scheme>, name: ExprOf<String>, o:Expr):Expr {
    return macro {
      var t:Table = mw.relational_scheme.Table.create(${scheme}, ${name}, ${o});
      ${scheme}.addTable(t);
      t;
    }
  }

}
