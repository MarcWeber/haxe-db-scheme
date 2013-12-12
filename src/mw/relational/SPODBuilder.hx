package mw.relational;
import app.schemes.AppScheme;

import haxe.macro.Expr;
import haxe.macro.Context;

using mw.StringExtensions;
using mw.ArrayExtensions;
using Lambda;

class SPODBuilder {

  static public function fieldTypeToPublicVar(ft: mw.relational.FieldType, target, pos, nullable) {
     function str(length:Int){
       return FVar(TPath({ name: "SString", pack: [], params: [TPExpr({ expr: EConst(CInt(length+"")), pos: pos })] }),null);
     };
     // TODO: take care about nullable
     return switch (ft) {
      case text(length): str(length);
      case int: FVar(TPath({ name: "SInt", pack: []}),null);
      case blob: throw "TODO";
      case bool: throw "TODO";
      case enum_(x): str(x.map_A(function(x){ return x.length; }).maxInt());
      case haxe_enum(enumType, size): str(size);
      case date: FVar(TPath({ name: "SDate", pack: [], params: [] }),null);
      case datetime: FVar(TPath({ name: "SDateTime", pack: [], params: [] }),null);
      case currency:  FVar(TPath({ name: "SFloat", pack: [], params: [] }),null);
     };
  }

  // target MySQL
  macro public static function build(scheme:String, target: String) : Array<Field> {
        if (!["MySQL"].has(target))
          throw 'unkown database target ${target}';

        var classType = haxe.macro.Context.getLocalClass().get();
        var name = classType.name.toLowerCase().makePlural();

        // write migration files
        mw.macro.Eval.expr = Context.parse(scheme, Context.currentPos());
        var scheme: mw.relational.Scheme = cast(mw.macro.Eval.eval());
        var table = mw.relational.SchemeExtensions.tableByName(scheme, name);
        if (null == table)
          throw 'table ${name} not found';

        var pos = haxe.macro.Context.currentPos();
        var fields = haxe.macro.Context.getBuildFields();

        if (table.primaryKeyFields.length != 1)
          throw "unsupported";

        for (f in table.fields){
          if (f.name == table.primaryKeyFields[0]){
            // public var id : SId;
            fields.push({
              kind: FVar(TPath({ name: "SId", pack: []}),null),
              meta: [],
              name: f.name,
              doc: null,
              pos: pos,
              access: [APublic]
            });
          } else {
            fields.push({
              kind: fieldTypeToPublicVar(f.type_, target, pos, f.nullable),
              meta: [],
              name: f.name,
              doc: null,
              pos: pos,
              access: [APublic]
            });
          }
        }
        return fields;
  }

}
