-- Seed: adiciona email de teste na allow list premium
INSERT INTO premium_allowlist (email, is_active)
VALUES ('barbosa.silveira@gmail.com', true)
ON CONFLICT (email) DO UPDATE SET is_active = true;
