package mw.mysql;

enum FieldType {
  varchar( length: Int ); // assuming String is UTF-8
  char( length: Int ); // assuming String is UTF-8
  // bool_as_tiny_int;
  // bool(true_:String, false_:String, type_: FieldType); // eg bool(true_: "Y", false_: "N", type_: enum(["Y","N"]))
  enum_(i:Array<String>); // enum(i1, i2, i3)
  decimal(m:Int, d:Int);
  tinyint(len:Int, ?signed: Bool);
  smallint(length: Int, ?signed:Bool);
  mediumint(length: Int, ?signed:Bool);
  bigint(length: Int, ?signed:Bool);
  int( length: Int, ?signed: Bool, ?zerofill: Bool);
  
  // db_enum( valid_items: Array<String> );
  datetime;
  date;
  time;
  timestamp;

  // text field. arbitrary length. Maybe no indexing and slow searching
  tinytext; // text field. arbitrary length. Maybe no indexing and slow searching
  text;
  mediumtext;
  longtext;

  // binary
  tinyblob;
  blob;
  mediumblob;
  longblob;
}
