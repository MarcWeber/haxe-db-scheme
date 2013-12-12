package app.schemes;

class AppScheme {

  static public function scheme(prefix:String): mw.relational.Scheme {
    var s: mw.relational.Scheme = {

      mToN_relations: [

        // attandee_transactions
        {
          tableName: '${prefix}classes_rooms', m: '${prefix}classes', n: '${prefix}rooms',
          fields: []
        },

        // friendships pupils
        {
          tableName: '${prefix}pupils_friendships', m: '${prefix}pupils', n: '${prefix}pupils',
          m_fields: ["pupil_1"],
          n_fields: ["pupil_2"],
          fields: []
        }

      ],
          // transactions
      tables: [

        {
          name: '${prefix}teachers',
          fields: [
            ({name: "email", type_: text(200) }),
            ({name: "username", type_: text(200) }),
          ]
        },

        {
          name: '${prefix}rooms',
          fields: [
            ({name: "name", type_: text(200) }),
          ]
        },

        {
          name: '${prefix}classes',
          parents: [
            {table: '${prefix}rooms'}
          ],
          fields: [
            ({name: "name", type_: text(200) }),
          ]
        },

        {
          name: '${prefix}pupils',
          fields: [
            ({name: "name", type_: text(200) }),
          ]
        },
      ]
    };

    mw.relational.SchemeExtensions.addVersionTable(s, '${prefix}version');

    mw.relational.SchemeExtensions.implementRelations(s);

    return s;
  }

  static public function mysqlScheme(prefix:String) {
    return mw.relational.SchemeExtensions.toMySQLScheme(scheme(prefix));
  }

}
