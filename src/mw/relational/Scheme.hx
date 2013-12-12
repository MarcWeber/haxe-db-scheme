package mw.relational;
import haxe.macro.Expr;
import haxe.macro.Context;

// database agnostic table/fields definition also supporting relations

// like field, but allows nullable fields
typedef LazyField = {
  name:String,
  type_: mw.relational.FieldType,
  ?nullable: Bool, // assume false
  ?comment: String, // assume ""

  ?validation: Void -> Expr,

  ?references: { table:String, field:String },

#if MYSQL_SUPPORT
  ?mysql_on_update_current_timestamp: Bool // defaults to false
#end
}

typedef LazyTable = {
  name: String,
  fields: Array<LazyField>,
  ?comment: String,

  ?primaryKeyFields: Array<String>, // if null assume you want a primary key to be set automatically, otherwise use []
  ?indexes: Array<Array<String>>, // assume []
  ?uniqIndexes: Array<Array<String>>, // assume []

  ?validation: Void -> ExprOf<Dynamic -> Array<String>>, // input is {value1: .. value 2: , value 3: ..} returns code returning validation errors: (Array<String>()

  // will add a field referincing parent table
  ?parents: Array<{
    table:String,
    ?fieldNames:Array<String>, // matches primary keys of table
    ?forceParent: Bool, // assume true
  }>,

#if MYSQL_SUPPORT
  ?mysql_auto_increment: Int,
#end
}

typedef Scheme = {

  tables: Array<LazyTable>,

  mToN_relations: Array<
  { 
    tableName:String,

    m:String,
    ?m_fields: Array<String>, // defaults to key names of parent table (TODO)

    n:String,
    ?n_fields: Array<String>, // defaults to key names of parent table

    fields: Array<LazyField>, // additional fields to add to this relation table

    ?unique: Bool // assume true
  }>,
}
