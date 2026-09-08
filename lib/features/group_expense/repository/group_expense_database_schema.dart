import 'package:sqflite/sqflite.dart';

/// SQLite development schema for Group Expense Management.
///
/// `travellers` and `trips` are replaceable mirrors of data owned by other
/// GoBuddy modules. All other tables are owned by this feature.
class GroupExpenseDatabaseSchema {
  GroupExpenseDatabaseSchema._();

  static const createStatements = <String>[
    '''CREATE TABLE IF NOT EXISTS travellers (
      user_id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT,
      profile_photo TEXT,
      initials TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS trips (
      trip_id INTEGER PRIMARY KEY,
      trip_name TEXT NOT NULL,
      destination TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS trip_budgets (
      budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL UNIQUE,
      budget_name TEXT NOT NULL,
      budget_amount REAL NOT NULL CHECK (budget_amount > 0),
      base_currency TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE
    )''',
    '''CREATE TABLE IF NOT EXISTS expense_categories (
      category_id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      icon_name TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS expenses (
      expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL,
      paid_by_user_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      original_amount REAL NOT NULL CHECK (original_amount > 0),
      currency_code TEXT NOT NULL,
      exchange_rate REAL NOT NULL CHECK (exchange_rate > 0),
      base_amount REAL NOT NULL CHECK (base_amount > 0),
      expense_date TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
      FOREIGN KEY (paid_by_user_id) REFERENCES travellers(user_id),
      FOREIGN KEY (category_id) REFERENCES expense_categories(category_id)
    )''',
    '''CREATE TABLE IF NOT EXISTS expense_participants (
      expense_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      share_amount REAL NOT NULL CHECK (share_amount >= 0),
      share_percentage REAL,
      PRIMARY KEY (expense_id, user_id),
      FOREIGN KEY (expense_id) REFERENCES expenses(expense_id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES travellers(user_id)
    )''',
    '''CREATE TABLE IF NOT EXISTS expense_receipts (
      receipt_id INTEGER PRIMARY KEY AUTOINCREMENT,
      expense_id INTEGER NOT NULL UNIQUE,
      image_path TEXT NOT NULL,
      uploaded_at TEXT NOT NULL,
      FOREIGN KEY (expense_id) REFERENCES expenses(expense_id) ON DELETE CASCADE
    )''',
    '''CREATE TABLE IF NOT EXISTS settlements (
      settlement_id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL,
      payer_id INTEGER NOT NULL,
      payee_id INTEGER NOT NULL,
      amount REAL NOT NULL CHECK (amount > 0),
      payment_method TEXT NOT NULL,
      settlement_date TEXT NOT NULL,
      status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'rejected')),
      notes TEXT,
      created_at TEXT NOT NULL,
      CHECK (payer_id != payee_id),
      FOREIGN KEY (trip_id) REFERENCES trips(trip_id) ON DELETE CASCADE,
      FOREIGN KEY (payer_id) REFERENCES travellers(user_id),
      FOREIGN KEY (payee_id) REFERENCES travellers(user_id)
    )''',
    '''CREATE TABLE IF NOT EXISTS settlement_receipts (
      receipt_id INTEGER PRIMARY KEY AUTOINCREMENT,
      settlement_id INTEGER NOT NULL UNIQUE,
      image_path TEXT NOT NULL,
      uploaded_at TEXT NOT NULL,
      FOREIGN KEY (settlement_id) REFERENCES settlements(settlement_id) ON DELETE CASCADE
    )''',
    'CREATE INDEX IF NOT EXISTS idx_expenses_trip_date ON expenses(trip_id, expense_date)',
    'CREATE INDEX IF NOT EXISTS idx_expense_participants_user ON expense_participants(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_settlements_trip_status ON settlements(trip_id, status)',
    'CREATE INDEX IF NOT EXISTS idx_settlements_payer ON settlements(payer_id)',
    'CREATE INDEX IF NOT EXISTS idx_settlements_payee ON settlements(payee_id)',
  ];

  static Future<void> createAndSeed(Database db) async {
    final schemaBatch = db.batch();
    for (final statement in createStatements) {
      schemaBatch.execute(statement);
    }
    await schemaBatch.commit(noResult: true);
    await _seed(db);
  }

  static Future<void> _seed(Database db) async {
    final batch = db.batch();
    const conflict = ConflictAlgorithm.ignore;
    const travellers = [
      {'user_id': 1, 'name': 'Ahmad Faiz', 'initials': 'AF'},
      {'user_id': 2, 'name': 'Sarah Lim', 'initials': 'SL'},
      {'user_id': 3, 'name': 'Ravi Kumar', 'initials': 'RK'},
      {'user_id': 4, 'name': 'Nurul Ain', 'initials': 'NA'},
    ];
    for (final traveller in travellers) {
      batch.insert('travellers', traveller, conflictAlgorithm: conflict);
    }
    batch.insert(
      'trips',
      const {
        'trip_id': 1,
        'trip_name': 'Kuala Lumpur MY',
        'destination': 'Kuala Lumpur, Malaysia',
        'start_date': '2025-07-19T00:00:00.000',
        'end_date': '2025-07-24T00:00:00.000',
      },
      conflictAlgorithm: conflict,
    );
    const categories = [
      (1, 'Hotel', 'hotel'),
      (2, 'Flight', 'flight'),
      (3, 'Food', 'food'),
      (4, 'Restaurant', 'restaurant'),
      (5, 'Transportation', 'transportation'),
      (6, 'Fuel', 'fuel'),
      (7, 'Parking', 'parking'),
      (8, 'Shopping', 'shopping'),
      (9, 'Entertainment', 'entertainment'),
      (10, 'Attraction', 'attraction'),
      (11, 'Others', 'others'),
    ];
    for (final category in categories) {
      batch.insert(
        'expense_categories',
        {
          'category_id': category.$1,
          'name': category.$2,
          'icon_name': category.$3
        },
        conflictAlgorithm: conflict,
      );
    }
    batch.insert(
      'trip_budgets',
      const {
        'budget_id': 1,
        'trip_id': 1,
        'budget_name': 'KL Trip 2025',
        'budget_amount': 3000.0,
        'base_currency': 'MYR',
        'notes': 'Group trip to KL, Malaysia.',
        'created_at': '2025-07-01T09:00:00.000',
        'updated_at': '2025-07-01T09:00:00.000',
      },
      conflictAlgorithm: conflict,
    );

    // "Airport snacks" is the additional RM34 expense requested by the brief.
    const expenses = [
      (1, 8, 'Shopping (KLCC)', 250.0, 2),
      (2, 10, 'Museum Entry', 45.0, 3),
      (3, 1, 'Hotel Stay', 580.0, 1),
      (4, 2, 'Flight', 760.0, 1),
      (5, 9, 'Entertainment', 180.0, 3),
      (6, 6, 'Fuel', 120.0, 2),
      (7, 4, 'Restaurant', 86.0, 3),
      (8, 3, 'Airport snacks', 34.0, 3),
    ];
    for (final expense in expenses) {
      batch.insert(
        'expenses',
        {
          'expense_id': expense.$1,
          'trip_id': 1,
          'paid_by_user_id': expense.$5,
          'category_id': expense.$2,
          'title': expense.$3,
          'original_amount': expense.$4,
          'currency_code': 'MYR',
          'exchange_rate': 1.0,
          'base_amount': expense.$4,
          'expense_date': '2025-07-${18 + expense.$1}T12:00:00.000',
          'created_at': '2025-07-${18 + expense.$1}T12:00:00.000',
          'updated_at': '2025-07-${18 + expense.$1}T12:00:00.000',
        },
        conflictAlgorithm: conflict,
      );
      final cents = (expense.$4 * 100).round();
      final baseShare = cents ~/ 4;
      var assigned = 0;
      for (var userId = 1; userId <= 4; userId++) {
        final shareCents = userId == 4 ? cents - assigned : baseShare;
        assigned += shareCents;
        batch.insert(
          'expense_participants',
          {
            'expense_id': expense.$1,
            'user_id': userId,
            'share_amount': shareCents / 100,
            'share_percentage': 25.0,
          },
          conflictAlgorithm: conflict,
        );
      }
    }
    const settlements = [
      (1, 4, 1, 513.75),
      (2, 3, 1, 25.50),
      (3, 2, 1, 0.50),
    ];
    for (final settlement in settlements) {
      batch.insert(
        'settlements',
        {
          'settlement_id': settlement.$1,
          'trip_id': 1,
          'payer_id': settlement.$2,
          'payee_id': settlement.$3,
          'amount': settlement.$4,
          'payment_method': 'DuitNow',
          'settlement_date': '2025-07-26T10:00:00.000',
          'status': 'completed',
          'notes': 'Development balance seed',
          'created_at': '2025-07-26T10:00:00.000',
        },
        conflictAlgorithm: conflict,
      );
    }
    await batch.commit(noResult: true);
  }
}
