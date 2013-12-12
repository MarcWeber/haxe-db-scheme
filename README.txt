Haxe MySQL & migration generation
=================================

sample migration files generated based on scheme defined in test-neko/app/schemes/AppScheme.hx


  test-neko/migrations/Migration1.hx:
  ====================================

  // generated file 
  package migrations;

  class Migration1{

    static public function up(f: String -> Void){

    f("CREATE TABLE teachers(
  email varchar(200) NOT NULL  ,
  username varchar(200) NOT NULL  ,
  teacher_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    f("CREATE TABLE rooms(
  name varchar(200) NOT NULL  ,
  room_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    f("CREATE TABLE classes(
  name varchar(200) NOT NULL  ,
  classe_id int(10) auto_increment primary key  NOT NULL  ,
  room_id int(10) auto_increment primary key  NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    f("CREATE TABLE pupils(
  name varchar(200) NOT NULL  ,
  pupil_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    f("CREATE TABLE version(
  version int(10) auto_increment primary key  NOT NULL  ,
  version_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    f("CREATE TABLE classes_rooms(
  classe_id int(10) auto_increment primary key  NOT NULL  ,
  room_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    f("CREATE TABLE pupils_friendships(
  pupil_id int(10) auto_increment primary key  NOT NULL  ,
  pupil_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

    }

  }


  test-neko/cont_migrations/Migration1.hx
  ====================================
  // generated file 
  package cont_migrations;

  import xx.ContinuationM;

  class Migration1{

    static public function up(f: String -> xx.Cont<xx.CVoid> ){

  return xx.ContinuationM.dO({

  v1 <=  f("CREATE TABLE cont_teachers(
  email varchar(200) NOT NULL  ,
  username varchar(200) NOT NULL  ,
  cont_teacher_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  v2 <=  f("CREATE TABLE cont_rooms(
  name varchar(200) NOT NULL  ,
  cont_room_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  v3 <=  f("CREATE TABLE cont_classes(
  name varchar(200) NOT NULL  ,
  cont_classe_id int(10) auto_increment primary key  NOT NULL  ,
  cont_room_id int(10) auto_increment primary key  NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  v4 <=  f("CREATE TABLE cont_pupils(
  name varchar(200) NOT NULL  ,
  cont_pupil_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  v5 <=  f("CREATE TABLE cont_version(
  version int(10) auto_increment primary key  NOT NULL  ,
  cont_version_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  v6 <=  f("CREATE TABLE cont_classes_rooms(
  cont_classe_id int(10) auto_increment primary key  NOT NULL  ,
  cont_room_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  v7 <=  f("CREATE TABLE cont_pupils_friendships(
  cont_pupil_id int(10) auto_increment primary key  NOT NULL  ,
  cont_pupil_id int(10) auto_increment primary key  NOT NULL  
  )  engine = innodb default character set = utf8 collate = utf8_general_ci");

  return v7;

  });

    }

  }
