package mw.migrate;
using mw.StringExtensions;
using mw.NullExtensions;

import haxe.macro.Expr;
import haxe.macro.Context;
import mw.mysql.scheme.Scheme;

import app.schemes.AppScheme; // used by mw.macro.Eval.eval

class Migrate {

#if macro
  static public function migrationFile(dir, nr:Int, ext):String {
    return dir+"/Migration"+nr+"."+ext;
  }

  static public function versionByMigrationDir(dir: String):Int {
    var nr = 0;
    while (sys.FileSystem.exists(migrationFile(dir, nr+1, "dump"))) nr++;
    return nr;
  }

  // compare current scheme against latest known scheme at the end of all
  // migrations. If they differ create a new migration
  static public function updateMigrationFiles<S>(
      targetScheme: S,
      emptyScheme: Void -> S,
      schemesEqual: S -> S -> Bool,
      migrationSQL: S ->S ->Array<String>,
      dir:String,
      package_:String,
      style:String // "use-continuation" or "default"
    ) {
    var nr = versionByMigrationDir(dir);
    var f = function(nr, ext){ return migrationFile(dir, nr, ext); };

    var new_serialized: String = haxe.Serializer.run(targetScheme);

    var old_serialized = (nr == 0)
      ? ""
      : sys.io.File.getContent(f(nr,"dump"));

    if (new_serialized == old_serialized) return;

    var last: S =
     (nr == 0)
     ? emptyScheme()
     : cast(haxe.Unserializer.run(old_serialized));

    var migration_sql:Array<String> = migrationSQL(last, targetScheme);
    // save dump
    Sys.println("writing "+f(nr+1,"dump"));
    if (!sys.FileSystem.exists(dir))
      sys.FileSystem.createDirectory(dir);
    sys.io.File.saveContent(f(nr+1,"dump"), new_serialized);
    // save sql
    Sys.println("writing "+f(nr+1,"sql"));
    sys.io.File.saveContent(f(nr+1,"sql"), "-- generated file\n\n" + migrationSQL(emptyScheme(), targetScheme).join(";\n\n"));

    // save migration
    var migration = [];
    migration.push('package $package_;');

    if (style == "use-continuation"){
      migration.push("import xx.ContinuationM;");
    }

    migration.push("class Migration"+(nr+1)+"{");
    migration.push("  review, then remove this line");

    if (style == "use-continuation"){
      migration.push("  static public function up(f: String -> xx.Cont<xx.CVoid> ){");


      migration.push("return xx.ContinuationM.dO({");

      var nr = 1;
      for (x in migration_sql){
        var v = 'v${nr}'; nr += 1;
        migration.push(v+" <=  f(\""+ StringTools.replace(x.escapeChars("\\"), "\"","\\\"") +"\");");
      }

      migration.push('return v${nr-1};');
      migration.push("});");

      migration.push("  }");

    } else {
      migration.push("  static public function up(f: String -> Void){");
      for (x in migration_sql)
        migration.push("  f(\""+ StringTools.replace(x.escapeChars("\\"), "\"","\\\"") +"\");");
      migration.push("  }");
    }
    migration.push("}");


    var hxFile = f(nr+1,"hx");
    Sys.println("writing "+hxFile);
    sys.io.File.saveContent(hxFile, "// generated file \n"+ migration.join("\n\n"));

    // we want the user to review the file, so output something which looks
    // like an error string IDEs can parse
    Sys.println(hxFile+":8: edit");
  }

  // returns a function making the database up to date
  // the input is based on the migrations stored in the files generated by
  // updateMigrationFiles
  static public function migrationFunctionText(migrationPackage:String, migrationFileDir: String):String {
    var nr = versionByMigrationDir(migrationFileDir);

    var s = "function migrate(o:{get_version: Void -> Int, set_version: Int -> Void, run_sql: String -> Void}):Int{\n";
    s += "  var v = o.get_version();\n";

    for (i in 1...(nr+1)){

    s += "  if (v < "+i+"){\n";
    s += '    ${migrationPackage}.Migration${i}.up(o.run_sql);\n';
    s += "    v++;\n";
    s += "    o.set_version(v);\n";
    s += "  }\n";
    }
    s += "  return v;\n";
    s += "}\n";
    return s;
  }

  static public function migrationFunctionTextCont(migrationPackage:String, migrationFileDir: String):String {
    var nr = versionByMigrationDir(migrationFileDir);

    var s = "function(o:{get_version_cont: Void -> xx.Cont<Int>, set_version_cont: Int -> xx.Cont<xx.CVoid>, run_sql_cont: String -> xx.Cont<xx.CVoid> }):xx.Cont<Int>{\n";
    s += "    return xx.ContinuationM.dO({\n";
    s += "        v <= o.get_version_cont();\n";

    for (i in 1...(nr+1)){
    s += "        v <= ((v < "+i+")\n";
    s += "            ? (xx.ContinuationM.dO({\n";
    s += "                dummy <= "+migrationPackage+".Migration1.up(o.run_sql_cont);\n";
    s += "                return "+i+";\n";
    s += "              }))\n";
    s += "            : xx.ContinuationM.ret(v));\n";
    s += "        d <= o.set_version_cont(v);\n";
    }

    s += "        return v;\n";
    s += "    });\n";
    s += "  }\n";

    return s;
  }

  static public function migrationFunction(
        text:String,
        migrationPackage: String,
        migrationFileDir: String
      ):ExprOf<Void -> Void>{

      var pos = Context.currentPos();
      return Context.parseInlineString(text, pos);
  }


  static public function migrateCont(e_ci:ExprOf<xx.db.ConnectionInterface>, migrationFileDir:String, migrationPackage:String, version_table:String) {
    // return migration code running the migrations
    var mf = migrationFunction(
        migrationFunctionTextCont(migrationPackage, migrationFileDir),
        migrationPackage,
        migrationFileDir);
    var r = macro $mf({
      get_version_cont: function(): xx.Cont<Int>{
         return xx.ContinuationM.dO({
           r <= xx.ContUtil.onException(
                $e_ci.queryValue("SELECT max(version) FROM "+$v{version_table}),
                function(){ return 0; }
               );
           return mw.NullExtensions.ifNull(r, 0);
        });
      },
      set_version_cont: function(i:Int): xx.Cont<xx.CVoid>{
        return $e_ci.request('INSERT INTO '+$v{version_table}+' SET version = '+i);
      },
      run_sql_cont: function(s:String): xx.Cont<xx.CVoid>{
        return $e_ci.request(s);
      }
    });

    return r;
  }

  static public function migrate(con:Expr, migrationFileDir:String, migrationPackage:String, version_table:String) {
    // return migration code running the migrations
    var mf = migrationFunction(
        migrationFunctionText(migrationPackage, migrationFileDir),
        migrationPackage,
        migrationFileDir);
    var r = macro $mf({
      get_version: function(){
        try{
          var res: sys.db.ResultSet = $con.request("SELECT max(version) FROM version");
          return mw.NullExtensions.ifNull(res.getIntResult(0),0);
        }catch(e:Dynamic){
          return 0;
        }
        },
        set_version: function(i){
          $con.request('INSERT INTO version SET version = '+i);
        },
        run_sql: function(s:String){
          $con.request(s);
        }
      });
      return r;
  }
#end


#if MYSQL_SUPPORT

  // style is either "use-continuation" or "default"
  // use-continuation is not implemented yet
  macro static public function migrateMySQL(e_con: ExprOf<sys.db.Connection>, migrationFileDir:String, migrationPackage:String, version_table:String, code_providing_scheme: String) {

    #if UPDATE_MIGRATIONS
      // write migration files
      var haxe_str:String = code_providing_scheme;
      mw.macro.Eval.expr = Context.parse(haxe_str, Context.currentPos());
      var scheme: mw.mysql.scheme.Scheme = cast(mw.macro.Eval.eval());

      updateMigrationFiles(
          scheme,
          function() return { tables: [] },
          function(a, b){ return haxe.Serializer.run(a) == haxe.Serializer.run(b); },
          function(s1, s2){ return mw.mysql.scheme.SchemeExtensions.migrate_to_sql(s1, s2); },
          migrationFileDir,
          migrationPackage,
          "default"
      );
    #end

    var r = migrate(e_con, migrationFileDir, migrationPackage, version_table);
    // neko.Lib.print(r);
    return r;
  }

  macro static public function migrateMySQLCont(e_ci: ExprOf<xx.db.ConnectionInterface>, migrationFileDir:String, migrationPackage:String, version_table:String, code_providing_scheme: String) {

    #if UPDATE_MIGRATIONS
      // write migration files
      var haxe_str:String = code_providing_scheme;
      mw.macro.Eval.expr = Context.parse(haxe_str, Context.currentPos());
      var scheme: mw.mysql.scheme.Scheme = cast(mw.macro.Eval.eval());

      updateMigrationFiles(
          scheme,
          function() return { tables: [] },
          function(a, b){ return haxe.Serializer.run(a) == haxe.Serializer.run(b); },
          function(s1, s2){ return mw.mysql.scheme.SchemeExtensions.migrate_to_sql(s1, s2); },
          migrationFileDir,
          migrationPackage,
          "use-continuation"
      );
    #end

    var r = migrateCont(e_ci, migrationFileDir, migrationPackage, version_table);
    // tink.macro.tools.Printer.print(r);
    return r;
  }

#end

}
