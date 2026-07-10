/// SQLite schema for the Bay Tracker database.
///
/// truck_id (not hs_number) is the real foreign key on stage_history,
/// substep_progress, and tag_request — hs_number is a unique human-facing
/// lookup field on truck, not a relational key. This is what lets
/// `ON DELETE CASCADE` actually clean up child rows when a truck is deleted.
library;

const int schemaVersion = 2;

const String createTruckTable = '''
CREATE TABLE truck (
  id                        INTEGER PRIMARY KEY AUTOINCREMENT,
  hs_number                 TEXT NOT NULL UNIQUE,
  truck_name                TEXT NOT NULL,
  customer                  TEXT,
  bay_number                INTEGER NOT NULL CHECK (bay_number BETWEEN 1 AND 8),
  current_stage             TEXT NOT NULL DEFAULT 'Proofing',
  date_entered_stage        TEXT NOT NULL,
  dealer_supplied_graphics  INTEGER NOT NULL DEFAULT 0,
  schedule_status           TEXT NOT NULL DEFAULT 'In Bay',
  due_date                  TEXT,
  notes                     TEXT,
  proof_final_path_1        TEXT,
  proof_final_path_2        TEXT,
  created_at                TEXT NOT NULL,
  is_active                 INTEGER NOT NULL DEFAULT 1,
  stripe_color              TEXT,
  stripe_color_custom       TEXT,
  chevron_color             TEXT,
  chevron_color_custom      TEXT,
  stripe_feature            TEXT,
  stripe_feature_custom     TEXT,
  stripe_on_stainless       INTEGER NOT NULL DEFAULT 0
)
''';

/// Migration from schema v1 -> v2: adds the stripe/chevron graphics-spec
/// columns to an existing truck table without touching existing rows.
const List<String> migrateV1ToV2 = [
  'ALTER TABLE truck ADD COLUMN stripe_color TEXT',
  'ALTER TABLE truck ADD COLUMN stripe_color_custom TEXT',
  'ALTER TABLE truck ADD COLUMN chevron_color TEXT',
  'ALTER TABLE truck ADD COLUMN chevron_color_custom TEXT',
  'ALTER TABLE truck ADD COLUMN stripe_feature TEXT',
  'ALTER TABLE truck ADD COLUMN stripe_feature_custom TEXT',
  "ALTER TABLE truck ADD COLUMN stripe_on_stainless INTEGER NOT NULL DEFAULT 0",
];

const String createTruckBayActiveIndex = '''
CREATE UNIQUE INDEX idx_truck_bay_active ON truck(bay_number) WHERE is_active = 1
''';

const String createStageHistoryTable = '''
CREATE TABLE stage_history (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  truck_id    INTEGER NOT NULL REFERENCES truck(id) ON DELETE CASCADE,
  stage       TEXT NOT NULL,
  entered_at  TEXT NOT NULL
)
''';

const String createStageHistoryTruckIndex = '''
CREATE INDEX idx_stage_history_truck ON stage_history(truck_id)
''';

const String createSubstepProgressTable = '''
CREATE TABLE substep_progress (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  truck_id       INTEGER NOT NULL REFERENCES truck(id) ON DELETE CASCADE,
  substep_name   TEXT NOT NULL,
  sort_order     INTEGER NOT NULL,
  is_custom      INTEGER NOT NULL DEFAULT 0,
  is_complete    INTEGER NOT NULL DEFAULT 0,
  completed_at   TEXT
)
''';

const String createSubstepProgressTruckIndex = '''
CREATE INDEX idx_substep_truck ON substep_progress(truck_id)
''';

const String createTagRequestTable = '''
CREATE TABLE tag_request (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  date_requested    TEXT NOT NULL,
  bay_requested_by  INTEGER NOT NULL CHECK (bay_requested_by BETWEEN 1 AND 8),
  truck_id          INTEGER NOT NULL REFERENCES truck(id) ON DELETE CASCADE,
  tag_type          TEXT NOT NULL,
  tag_text          TEXT NOT NULL,
  date_made         TEXT,
  status            TEXT NOT NULL DEFAULT 'Needed'
)
''';

const String createTagRequestTruckIndex = '''
CREATE INDEX idx_tag_request_truck ON tag_request(truck_id)
''';

const String createTagRequestStatusIndex = '''
CREATE INDEX idx_tag_request_status ON tag_request(status)
''';

const List<String> createStatements = [
  createTruckTable,
  createTruckBayActiveIndex,
  createStageHistoryTable,
  createStageHistoryTruckIndex,
  createSubstepProgressTable,
  createSubstepProgressTruckIndex,
  createTagRequestTable,
  createTagRequestTruckIndex,
  createTagRequestStatusIndex,
];
