package mw.relational_scheme;

import haxe.macro.Expr;
import haxe.macro.Context;
import mw.relational_scheme.SchemeInterface;
import mw.relational_scheme.Relationship;
import mw.relational_scheme.Field;

import mw.mysql.FieldType;

using mw.Assertions;

class MToN implements Relationship {
  public var addFields: Table -> Void;
  public var scheme: Scheme;
  public var o:{
    table:String,
    m:String,
    n:String,
  };
  public function new(scheme:Scheme, o, addFields) {
    this.scheme = scheme;
    this.o = o;
    this.addFields = addFields;
  }
  macro static public function create(scheme: ExprOf<Scheme>, o:Expr):ExprOf<Table> {
    return macro new OneToMany(${scheme},
        mw.macro.StructureHelpers.sh_merge_override(
        {table: 'rel_{$o.m}_{$o.n}'},
        ${o}));
  }
  #if !macro
  public function finalise(){
    var t_m = scheme.tableByName(o.m);
    var t_m_pfs = t_m.o.primaryKeyFields;
    var t_n = scheme.tableByName(o.n);
    var t_n_pfs = t_n.o.primaryKeyFields;

    var t:Table = scheme.createTable(o.table, {indexes: [t_n_pfs.concat(t_m_pfs)]});
    if (null != this.addFields)
      this.addFields(t);

    for (f_name in t_m_pfs)
      t.createField(f_name, t_m.fieldByName(f_name).type, {references: {table:  o.m, field: f_name}});
    for (f_name in t_n_pfs)
      t.createField(f_name, t_n.fieldByName(f_name).type, {references: {table:  o.n, field: f_name}});
  }
  #end
}
