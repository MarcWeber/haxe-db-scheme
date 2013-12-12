package mw.mysql.scheme;
import mw.mysql.scheme.Scheme;

// same as scheme, but allow more "null" values

/* direct mysql database representation */

// like field, but allows nullable fields
typedef LazyField = {
  name:String,
  type_: mw.mysql.FieldType,
  ?nullable: Bool, // assume false
  ?comment: String, // assume ""
  ?references: mw.mysql.scheme.References,

  ?default_: String,
  ?on_update_current_timestamp: Bool // defaults to false
}


typedef LazyTable = {
  name: String,
  fields: Array<LazyField>,
  ?comment: String,

  ?primaryKeyFields: Array<String>, // assume []
  ?indexes: Array<Array<String>>, // assume []
  ?uniqIndexes: Array<Array<String>>, // assume []
  ?auto_increment: Int, // when set assume primary key is auto_increment
  ?table_type: mw.mysql.scheme.TableType, // assume InnoDB
}

typedef LazyScheme = {
  tables: Array<LazyTable>
  // TODO triggers and the like
}
