package mw.mysql.scheme;

enum TableType {
  InnoDB;
  MyIsam;
}

/* direct mysql database representation */

typedef References = {
  table:String, field:String
}

// like field, but allows nullable fields

typedef Field = {
  name:String,
  type_: mw.mysql.FieldType,
  nullable: Bool,
  ?comment: String,
  ?references: {table:String, field:String},
  ?default_: String,
  on_update_current_timestamp: Bool
}


typedef Table = {
  name: String,
  fields: Array<Field>,
  ?comment: String,

  primaryKeyFields: Array<String>,
  indexes: Array<Array<String>>,
  uniqIndexes: Array<Array<String>>,
  ?auto_increment: Int, // when set assume primary key is auto_increment
  table_type: TableType
}

typedef Scheme = {
  tables: Array<Table>
  // TODO triggers and the like
}
