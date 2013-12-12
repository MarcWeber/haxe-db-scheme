package mw.mysql.scheme;
import mw.mysql.scheme.Scheme;
import mw.mysql.scheme.LazyScheme;
using mw.ArrayExtensions;
using mw.NullExtensions;

class LazySchemeExtensions {

  static public function finalizeField(f:LazyField):Field {
    return {
      name: f.name,
      type_: f.type_,
      nullable: f.nullable.ifNull(false),
      comment: f.comment,
      references: f.references,
      on_update_current_timestamp: f.on_update_current_timestamp.ifNull(false),
      default_: f.default_
    };
  }

  static public function finalize(s:LazyScheme):Scheme {
    return {
      tables: s.tables.map_A(function(t) return {
        name: t.name,
        fields: mw.ArrayExtensions.map_A(t.fields, finalizeField),
        comment: t.comment,
        primaryKeyFields: t.primaryKeyFields.ifNull([]),
        indexes: t.indexes.ifNull([]),
        uniqIndexes: t.uniqIndexes.ifNull([]),
        auto_increment: t.auto_increment,
        table_type: t.table_type.ifNull(MyIsam)
      })
    }
  }

}
