package mw.relational;
import mw.mysql.scheme.Scheme;
import mw.relational.Scheme;

using mw.ArrayExtensions;
using mw.StringExtensions;
using mw.Assertions;
using mw.NullExtensions;

class SchemeExtensions {

  static public function tableByName(s:Scheme, name:String){
    for (t in s.tables){
      if (t.name == name) return t;
    }
    return null;
  }

  static public function fieldByName(t:LazyTable, name:String){
    for (f in t.fields){
      if (f.name == name) return f;
    }
    return null;
  }

  static public function fixPrimaryKey(table: mw.relational.LazyTable) {
    if (table.primaryKeyFields == null){
      table.primaryKeyFields = [ mw.StringExtensions.makeSingular(table.name)+"_id" ];
    }
    if (table.primaryKeyFields.length == 1){
      var pk = table.primaryKeyFields[0];
      if (null == mw.relational.SchemeExtensions.fieldByName(table, pk)){
        table.fields.push({
          name: pk,
          type_: int,
        });
      }
      #if MYSQL_SUPPORT
      if (table.mysql_auto_increment == null)
        table.mysql_auto_increment = 1;
      #end
    }
  }

  static public function defaults(scheme: mw.relational.Scheme) {
    for (t in scheme.tables) {
      t.indexes = t.indexes.ifNull([]);
      t.uniqIndexes = t.uniqIndexes.ifNull([]);
    }
  }

  static public function implementRelations(scheme: mw.relational.Scheme){
    defaults(scheme);

    // add additional fields tables determined by mToN_relations and table.parents field

    // must know about primary keys
    for(t in scheme.tables) fixPrimaryKey(t);

    // m - to - n
    for(mToN in scheme.mToN_relations){
      var tableName = mToN.tableName;
      if (null != mw.relational.SchemeExtensions.tableByName(scheme, tableName))
        throw "unexpected, relation table already exists!";

      var m_table = mw.relational.SchemeExtensions.tableByName(scheme, mToN.m).assert_nn('table ${mToN.m} not found, referenced by relation');
      var n_table = mw.relational.SchemeExtensions.tableByName(scheme, mToN.n).assert_nn('table ${mToN.n} not found, referenced by relation');

      function fields(user_setting:Null<Array<String>>, primaries:Array<String>){
        if (user_setting != null){
          if (user_setting.length != primaries.length)
            throw "name count missmatch";
          return user_setting;
        }
        return primaries;
      };


      function fields(m_or_n:String, parent_table:String, names:Array<String>){
        var pt = mw.relational.SchemeExtensions.tableByName(scheme, parent_table).assert_nn('${parent_table} unkown of mToN.${m_or_n} relation ${mToN.tableName}');
        return pt.primaryKeyFields.map_Ai(function(pk, i){
          var f = mw.relational.SchemeExtensions.fieldByName(pt, pk).assert_nn('${parent_table} does not have field ${pk} mToN.${m_or_n} relation ${mToN.tableName}');
          var n = names == null ? pk : names[i];
          var r: mw.relational.LazyField = {name: n, type_: f.type_, references: {table: parent_table, field: pk} };
          return r;
        });
      };

      var m_fields_ref = fields("m", mToN.m, mToN.m_fields);
      var n_fields_ref = fields("n", mToN.n, mToN.n_fields);

      var refs = m_fields_ref.concat(n_fields_ref);

      scheme.tables.push({
        name: tableName,
        fields: refs,
        comment: 'n to m relation ${mToN.m} - ${mToN.n}',
        primaryKeyFields: mToN.unique.ifNull(true) ? refs.map_A(function(x) return x.name) : [],
      });
    }

    // parents .. (one - to - n), add fields referencing parent table
    for (t in scheme.tables){
      for (p in t.parents.ifNull([])){
        var parent = mw.relational.SchemeExtensions.tableByName(scheme, p.table);
        var pks = parent.primaryKeyFields;
        var field_names = p.fieldNames.ifNull(pks);
        if (pks.length != field_names.length) throw 'primary key fields of ${p.table} must match referencing names in ${t.name}';

        for(i in 0...pks.length){
          var f = mw.relational.SchemeExtensions.fieldByName(parent, pks[i]);
          t.fields.push({
            name: field_names[i],
            type_: f.type_,
            nullable: ! p.forceParent,
            references: { table: p.table, field: pks[i] }
          });
        }
      }
    }
  }


#if MYSQL_SUPPORT

  static public function fieldType_to_MySQLFieldType(t: mw.relational.FieldType):mw.mysql.FieldType {
    return switch (t) {
      case text(length):
        if (length > 255)
          blob
        else varchar(length);
      case int: int(10);
      case blob: blob;
      case bool: enum_(["Y","N"]);
      case haxe_enum(v, size): varchar(255);
      case date: date;
      case datetime: datetime;
      case currency: decimal(10,2);
      default:
      throw "unexpected";
    }
  }

  static public function toMySQLScheme(scheme: mw.relational.Scheme): mw.mysql.scheme.Scheme {

    var tables:Array<Table> = [];

    for (t in scheme.tables){
      var tnew: mw.mysql.scheme.Table = {
      name: t.name,
      fields: t.fields.map_A(function(f):mw.mysql.scheme.Field return {
        name: f.name,
        type_: mw.relational.SchemeExtensions.fieldType_to_MySQLFieldType(f.type_),
        nullable: f.nullable,
        comment: f.comment,
        references: null,
        on_update_current_timestamp: f.mysql_on_update_current_timestamp.ifNull(false)
      }),
      comment: t.comment,
      primaryKeyFields: t.primaryKeyFields.ifNull([]),
      indexes: t.indexes.ifNull([]),
      uniqIndexes: t.uniqIndexes.ifNull([]),
      table_type: InnoDB
      };

      tables.push(tnew);
    }

    return {
      tables: tables
    }
  }
#end

  static public function addVersionTable(s:mw.relational.Scheme, name:String = "version") {
    s.tables.push({
      name: name,
      fields: [
        {name: "version", type_: int },
      ]
    });
  }

}
