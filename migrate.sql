ALTER TABLE room
  ADD COLUMN IF NOT EXISTS description       TEXT,
  ADD COLUMN IF NOT EXISTS start_date        TIMESTAMP,
  ADD COLUMN IF NOT EXISTS room_type         VARCHAR(20) NOT NULL DEFAULT 'PILIHAN_GANDA',
  ADD COLUMN IF NOT EXISTS shuffle_questions BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS room_code         VARCHAR(20);

ALTER TABLE room DROP CONSTRAINT IF EXISTS room_room_type_check;
ALTER TABLE room ADD CONSTRAINT room_room_type_check
  CHECK (room_type IN ('PRAKTIKUM', 'PILIHAN_GANDA', 'HYBRID'));

CREATE UNIQUE INDEX IF NOT EXISTS room_room_code_key ON room(room_code) WHERE room_code IS NOT NULL;

UPDATE room
  SET room_code = LPAD((FLOOR(RANDOM()*1000))::TEXT, 3, '0') || '-' || LPAD((FLOOR(RANDOM()*1000))::TEXT, 3, '0')
  WHERE room_code IS NULL;

ALTER TABLE pertanyaan
  DROP CONSTRAINT IF EXISTS pertanyaan_type_pertanyaan_check;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='pertanyaan' AND column_name='type_pertanyaan'
  ) THEN
    ALTER TABLE pertanyaan
      ALTER COLUMN type_pertanyaan TYPE VARCHAR(20);
  END IF;
END$$;

SELECT column_name, data_type FROM information_schema.columns
  WHERE table_name = 'room' ORDER BY ordinal_position;

ALTER TABLE pertanyaan
  ADD COLUMN IF NOT EXISTS gambar_url  TEXT,
  ADD COLUMN IF NOT EXISTS created_at  TIMESTAMP NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at  TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_pertanyaan_deleted_at ON pertanyaan(deleted_at);

ALTER TABLE feedbacks
  ADD COLUMN IF NOT EXISTS sender_id INTEGER REFERENCES users(id_users);

ALTER TABLE room_participants
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active';
