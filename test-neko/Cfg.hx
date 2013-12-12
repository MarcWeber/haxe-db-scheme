import app.schemes.AppScheme;

typedef AppConfig = {
  mysql_connection: {
       user : String,
       socket : String,
       port : Int,
       pass : String,
       host : String,
       database : String 
    }
  };

class Cfg {

  public static var app_config: AppConfig;
  public static var sys_db: sys.db.Connection;
  public static var connection_interface: xx.db.ConnectionInterface;

  // cannot use __init__, mysql fails to connect
  public static function setup() : Void {
    var config_file = "test-mysql-scheme-app-config.json";
    app_config = haxe.Json.parse(sys.io.File.getContent(config_file));

    #if !macro
    sys_db = sys.db.Mysql.connect(app_config.mysql_connection);
    connection_interface = new xx.db.StdConnection(sys_db);
    #end
  }

#if macro
  static public var update_migrations = true;
#end
}
