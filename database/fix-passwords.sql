-- Update admin password (admin123)
UPDATE users
SET password_hash = '$2a$12$MMbkxZQfQePt3aApd8bCsuSv0U7pT54rR708XyXXNq9gcnfjrsTBy'
WHERE username = 'admin';

-- Update test users (password123)
UPDATE users
SET password_hash = '$2a$12$9qf4aU3aQ.iXkYJYAea3deFQODQxKIwpV63Vz7p6CuCya.s696RXG'
WHERE username IN ('jsmith', 'mwilson', 'tjohnson');

-- Verify the updates
SELECT username, email, role, substring(password_hash, 1, 30) as hash_prefix
FROM users
ORDER BY username;
