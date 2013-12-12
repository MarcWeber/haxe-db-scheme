package mw.mysql.scheme.diff;
import mw.mysql.scheme.Scheme;
import mw.util.diff.DiffResultArray;

typedef TableDiff = {
  name: String,
  fields: DiffResultArray<Field, {left: Field, right:Field}>,
  ?comment: {left:String, right:String},

  primaryKeyFields: {left: Array<String>, right: Array<String>},
  indexes: DiffResultArray<Array<String>, Array<String>>,
  uniqIndexes: DiffResultArray<Array<String>, Array<String>>,

  table_type: {left: mw.mysql.scheme.TableType, right: mw.mysql.scheme.TableType},
  auto_increment: {left: Null<Int>, right: Null<Int> }  // when set assume primary key is auto_increment
}

typedef SchemeDiff = {
  tables: DiffResultArray<Table, TableDiff>
}
