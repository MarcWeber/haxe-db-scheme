package mw.mysql.scheme;
import mw.mysql.FieldType;
import mw.mysql.scheme.Scheme;
using mw.ArrayExtensions;
using mw.StringExtensions;
using StringTools;
using mw.NullExtensions;

class FieldExtensions {
  static public function sql(
      f:mw.mysql.scheme.Field,
      o: {
        include_references:Bool,
        ?auto_increment: Bool, // defaults to null
        ?primary_key: Bool, // defaults to false
      }
    ) {
    var pk = o.primary_key;
    if (o.auto_increment && !pk) throw "auto_increment requires primary key to be set!";

    var i_s = function(type_, len:Int, signed, zerofill:Bool = null){
      var r = '${type_}(${len})';
      if (signed != null && !signed) r += " UNSIGNED";
      if (zerofill != null && zerofill) r += " ZEROFILL";
      if (o.auto_increment != null)
        r +=" auto_increment primary key ";
      else if (o.primary_key.ifNull(false)){
        r +=" primary key ";
      }
      return r;
    };
    var t = switch(f.type_) {
      case varchar(length): 'varchar(${length})';
      case char(length): 'char(${length})';
      // case bool: "enum(\"Y\",\"N\")";
      case enum_(i):
        var items = i.map_A(function(_) return '"${_}"').join(",");
        'enum(${items})';
      case decimal(m, d): 'decimal(${m}, ${d})';
      case tinyint(len, signed): i_s("tinyint", len, signed);
      case smallint(len, signed): i_s("tinyint", len, signed);
      case mediumint(length, signed): i_s("mediumint", length, signed);
      case bigint(length, signed): i_s("bigint", length, signed);
      case int(length, signed, zerofill): i_s("int", length, signed, zerofill);

      // // smallint
      // // mediumint
      // case i_s( length, signed, zerofill): 
      //             "i_s("+length+") "
      //                    +(signed != true ? "UNSIGNED " : "")
      //                    +(zerofill == true ? " ZEROFILL" : "")
      //                    +(cast(table, Table<Dynamic>).auto_inc_fieldname == name ? " auto_increment primary key " : "SIGNED ");
      // // TINYINT[(length)] [UNSIGNED] [ZEROFILL]
      // // SMALLINT[(length)] [UNSIGNED] [ZEROFILL]
      // // MEDIUMINT[(length)] [UNSIGNED] [ZEROFILL]
      // // INT[(length)] [UNSIGNED] [ZEROFILL]
      // // INTEGER[(length)] [UNSIGNED] [ZEROFILL]
      // // BIGINT[(length)] [UNSIGNED] [ZEROFILL]

      case datetime: "datetime";
      case date: "date";
      case time: "time";
      case timestamp: "timestamp";

      case tinytext: "tinytext"; // text field. arbitrary length. Maybe no indexing and slow searching
      case text: "text";
      case mediumtext: "mediumtext";
      case longtext: "longtext";

      case tinyblob: "tinyblob";
      case blob: "blob";
      case mediumblob: "mediumblob";
      case longblob: "longblob";
    }
    var field_extra = "";
    if (f.on_update_current_timestamp)
      field_extra = "ON UPDATE CURRENT_TIMESTAMP";
    return
        f.name
      + " "
      + t
      +(f.nullable ? " NULL " : " NOT NULL ")
      +field_extra
      +(f.comment == null ? "" : " COMMENT \""+f.comment.escapeChars("\\").replace("\"","\\\"")+"\"")
      +(f.default_ == null ? "" : " default "+f.default_)+" "
      +((f.references == null || !o.include_references)
        ? ""
        : " REFERENCES "+f.references.table+"("+f.references.field+")"
       );
  }
}
