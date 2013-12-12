package mw.relational;

enum FieldType {
  text(length:Int);
  int();
  blob();
  bool();
  enum_(x:Array<String>);
  haxe_enum(enumType:String, size:Int);
  date();
  datetime();
  currency();
}

