import xx.ContinuationM;
import sys.db.Types;

#if !macro @:autoBuild(mw.relational.SPODBuilder.build("app.schemes.AppScheme.mysqlScheme(\"\")", "MySQL")) #end interface SPODBuilder {
}

class Teachers extends sys.db.Object implements SPODBuilder  {
}

class Test {

  static function main() {
    // simple diff test

    var s = app.schemes.AppScheme.mysqlScheme("");

    for (table in s.tables){
      trace('table ${table.name}');

      for (f in table.fields)
        trace('  field: ${f.name}');
    }

    // write schemes at compile time test:
    Cfg.setup();

    mw.migrate.Migrate.migrateMySQLCont(Cfg.connection_interface, "test-neko/cont_migrations", "cont_migrations", "cont_version", "app.schemes.AppScheme.mysqlScheme(\"cont_\")")(function(v){
        trace("mysql version is "+v());
    });

    var v = mw.migrate.Migrate.migrateMySQL(Cfg.sys_db, "test-neko/migrations", "migrations", "version", "app.schemes.AppScheme.mysqlScheme(\"\")");
    trace('mysql version is ${v}');
  }
}
