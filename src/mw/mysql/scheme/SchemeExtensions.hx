package mw.mysql.scheme;
import mw.mysql.scheme.LazyScheme;
import mw.mysql.scheme.Scheme;
import mw.mysql.scheme.diff.SchemeDiff;
using mw.NullExtensions;
using mw.ArrayExtensions;
using StringTools;

class SchemeExtensions {

  static public function diff(s1:Scheme, s2:Scheme):mw.mysql.scheme.diff.SchemeDiff {
    var diffIndexes = function(a:Array<Array<String>>, b:Array<Array<String>>){
      return mw.util.diff.DiffExtensions.diffArrays(a, b,
        function(a,b) return a.join(",") == b.join(","),
        function(a,b) return a
      );
    };
    return {
      tables: mw.util.diff.DiffExtensions.diffArrays(s1.tables, s2.tables,
        function(a,b) return a.name == b.name,
        function(a,b){
          var r: TableDiff = {
            name: a.name,
            auto_increment: {left: a.auto_increment, right: b.auto_increment},
            fields: mw.util.diff.DiffExtensions.diffArrays(a.fields, b.fields,
              function(a,b){ return a.name == b.name; },
              function(a,b){ return {left: a, right: b}; }
            ),
            comment: {left:a.comment, right: b.comment},

            primaryKeyFields: {left: a.primaryKeyFields, right: b.primaryKeyFields },
            indexes: diffIndexes( a.indexes, b.indexes ),
            uniqIndexes: diffIndexes(a.uniqIndexes, b.uniqIndexes),
            table_type: {left: a.table_type, right: b.table_type }
        };
        return r;
      })
    };
  }

  static public function tableByName(s:Scheme, name:String){
    for (t in s.tables){
      if (t.name == name) return t;
    }
    return null;
  }

  static public function fieldByName(t:Table, name:String){
    for (f in t.fields){
      if (f.name == name) return f;
    }
    return null;
  }

  static public function check(s: mw.mysql.scheme.Scheme) {
    var names = s.tables.map(function(x){ return x.name; }).duplicates();
    if (names.length > 0)
      throw names;
  }

  public static function migrate_to_sql(from: mw.mysql.scheme.Scheme, to: mw.mysql.scheme.Scheme):Array<String> {
    check(from);
    check(to);

    var sd = SchemeExtensions.diff(from, to);

    // most important changes should be implemented - some minor details could still be missing
    var r = [];

    var new_fields = [];

    // DROPPING TABLES
    for (table in sd.tables.left) r.push("DROP TABLE "+ table.name);

    var add_index = function(table_name:String, uniq:Bool, field_names:Array<String>){
        r.push("ALTER TABLE "+table_name+" ADD "+(uniq ? "UNIQUE " : "")+" INDEX "+table_name+"_"+field_names.join("_")+"("+field_names.join(",")+")");
    };
    // CREATING NEW TABLES, without REFERENCES first, use ALTER TABLE later to
    // break circular dependencies
    for (table in sd.tables.right){
      var sql = "CREATE TABLE "+ table.name+ "(\n";
      sql += table.fields.map_A(function(_){
        var pk = table.primaryKeyFields.length == 1 && table.primaryKeyFields[0] == _.name;
        return mw.mysql.scheme.FieldExtensions.sql(_, {
          include_references: false,
          primary_key: pk,
          auto_increment: table.auto_increment != null && pk,
      });
      }).join(",\n")+"\n";
      new_fields.push({tn: table.name, fields: table.fields});

      var tt = switch (table.table_type) {
        case InnoDB: "engine = innodb default character set = utf8 collate = utf8_general_ci";
        case MyIsam: "engine = MyIsam";
      }
      sql += ")  "+tt;
      r.push(sql);


      for (ui in table.uniqIndexes) add_index(table.name, true, ui);
      for (i in table.indexes) add_index(table.name, false, i);
    }


    // ALTERING TABLES
    for (td in sd.tables.both){
      if (td.table_type.left != td.table_type.right)
        throw 'changing table type not supported yet';

      // haxe can't compare array contents, so turn into strings
      var to_s: Array<Array<String>> ->Array<String> = function(a){ return a.map_A(function(_) return _.join(",")); };

      var old_pk_s = td.primaryKeyFields.left.join(",");
      var new_pk_s = td.primaryKeyFields.right.join(",");

      // ignore if primary key == auto_inc, because primary key will be created by field line
      if (null != td.primaryKeyFields.left) old_pk_s = "";
      if (null != td.primaryKeyFields.right) new_pk_s = "";

      // drop indexes
      if (old_pk_s != new_pk_s && old_pk_s != "")
        r.push("ALTER TABLE "+td.name+" DROP PRIMARY KEY");
      for (drop in td.indexes.left )
        r.push("ALTER TABLE "+td.name+" DROP INDEX "+td.name+"_"+drop.join("_"));
      for (drop in td.uniqIndexes.left)
        r.push("ALTER TABLE "+td.name+" DROP INDEX "+td.name+"_"+drop.join("_"));

      // drop fields
      for (drop in td.fields.left)
        r.push("ALTER TABLE "+td.name+" DROP "+drop);

      // don't care about order for now
      // add fields
      for (new_ in td.fields.right){
        var pk = td.primaryKeyFields.right.length == 1 && td.primaryKeyFields.right[0] == new_.name;
        r.push("ALTER TABLE "+td.name+" ADD "+ mw.mysql.scheme.FieldExtensions.sql(new_, {
          include_references: false,
          primary_key: pk,
          auto_increment: td.auto_increment.right != null && pk,
        }));
      }
      new_fields.push({tn: td.name, fields: td.fields.right });

      // change fields
      for (c in td.fields.both){
        if (haxe.Serializer.run(c.left) != haxe.Serializer.run(c.right)){
          var pk = td.primaryKeyFields.right.length == 1 && td.primaryKeyFields.right[0] == c.right.name;
          r.push("ALTER TABLE "+td.name+" CHANGE "+c+ " "+ mw.mysql.scheme.FieldExtensions.sql(c.right, {
            include_references: true,
            primary_key: pk,
            auto_increment: td.auto_increment.right != null && pk,
          }));
        }
      }

      // create new indexes
      if (old_pk_s != new_pk_s && new_pk_s != "")
        r.push("ALTER TABLE "+td.name+" ADD PRIMARY KEY("+new_pk_s+")");

      // indexes and uniqIndexes
      for (i in td.indexes.right) add_index(td.name, false, i);
      for (i in td.uniqIndexes.right) add_index(td.name, true, i);
    }

    return r;
  }
}
