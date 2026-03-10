-- Campos opcionais de professor na grade horária
ALTER TABLE class_schedule_slots ADD COLUMN IF NOT EXISTS professor_name TEXT;
ALTER TABLE class_schedule_slots ADD COLUMN IF NOT EXISTS professor_email TEXT;
ALTER TABLE class_schedule_slots ADD COLUMN IF NOT EXISTS professor_phone TEXT;
