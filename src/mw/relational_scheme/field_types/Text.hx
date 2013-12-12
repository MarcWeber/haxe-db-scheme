package mw.relational_scheme.field_types;

import mw.relational_scheme.FieldType;

class Text implements FieldType {
  public var length: Int;
  public function new(length) {
    this.length = length;
  }
}
