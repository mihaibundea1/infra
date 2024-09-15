-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS Exercises;
USE Exercises;

-- Create the exercise_groups table
CREATE TABLE IF NOT EXISTS exercise_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255)
);

-- Create the exercises table with a foreign key to the exercise_groups table
CREATE TABLE IF NOT EXISTS exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    group_id INT,
    video_url VARCHAR(255),
    image_url VARCHAR(255),
    access_count INT DEFAULT 0,  -- Track how many times the exercise is accessed
    FOREIGN KEY (group_id) REFERENCES exercise_groups(id)
);

-- Insert all muscle groups into the exercise_groups table
INSERT INTO exercise_groups (name, image_url) VALUES
    ('Abductors', 'https://example.com/images/abductors.jpg'),
    ('Abs', 'https://example.com/images/abs.jpg'),
    ('Adductors', 'https://example.com/images/adductors.jpg'),
    ('Biceps', 'https://example.com/images/biceps.jpg'),
    ('Calves', 'https://example.com/images/calves.jpg'),
    ('Chest', 'https://example.com/images/chest.jpg'),
    ('Forearms', 'https://example.com/images/forearms.jpg'),
    ('Glutes', 'https://example.com/images/glutes.jpg'),
    ('Hamstrings', 'https://example.com/images/hamstrings.jpg'),
    ('Hip Flexors', 'https://example.com/images/hipflexors.jpg'),
    ('IT Band', 'https://example.com/images/itband.jpg'),
    ('Lats', 'https://example.com/images/lats.jpg'),
    ('Lower Back', 'https://example.com/images/lowerback.jpg'),
    ('Upper Back', 'https://example.com/images/upperback.jpg'),
    ('Neck', 'https://example.com/images/neck.jpg'),
    ('Obliques', 'https://example.com/images/obliques.jpg'),
    ('Palmar Fascia', 'https://example.com/images/palmarfascia.jpg'),
    ('Plantar Fascia', 'https://example.com/images/plantarfascia.jpg'),
    ('Quads', 'https://example.com/images/quads.jpg'),
    ('Shoulders', 'https://example.com/images/shoulders.jpg'),
    ('Traps', 'https://example.com/images/traps.jpg'),
    ('Triceps', 'https://example.com/images/triceps.jpg');

-- Insert exercises with group_id
INSERT INTO exercises (name, group_id, video_url, image_url, access_count) VALUES
    ('Push-ups', (SELECT id FROM exercise_groups WHERE name = 'Chest'), 'https://example.com/videos/pushups.mp4', 'https://example.com/images/pushups.jpg', 0),
    ('Squats', (SELECT id FROM exercise_groups WHERE name = 'Quads'), 'https://example.com/videos/squats.mp4', 'https://example.com/images/squats.jpg', 0),
    ('Lunges', (SELECT id FROM exercise_groups WHERE name = 'Quads'), 'https://example.com/videos/lunges.mp4', 'https://example.com/images/lunges.jpg', 0),
    ('Plank', (SELECT id FROM exercise_groups WHERE name = 'Abs'), 'https://example.com/videos/plank.mp4', 'https://example.com/images/plank.jpg', 0),
    ('Burpees', (SELECT id FROM exercise_groups WHERE name = 'Chest'), 'https://example.com/videos/burpees.mp4', 'https://example.com/images/burpees.jpg', 0),
    ('Mountain Climbers', (SELECT id FROM exercise_groups WHERE name = 'Abs'), 'https://example.com/videos/mountain_climbers.mp4', 'https://example.com/images/mountain_climbers.jpg', 0),
    ('Jumping Jacks', (SELECT id FROM exercise_groups WHERE name = 'Shoulders'), 'https://example.com/videos/jumping_jacks.mp4', 'https://example.com/images/jumping_jacks.jpg', 0),
    ('Sit-ups', (SELECT id FROM exercise_groups WHERE name = 'Abs'), 'https://example.com/videos/situps.mp4', 'https://example.com/images/situps.jpg', 0),
    ('Bicycle Crunches', (SELECT id FROM exercise_groups WHERE name = 'Abs'), 'https://example.com/videos/bicycle_crunches.mp4', 'https://example.com/images/bicycle_crunches.jpg', 0),
    ('Russian Twists', (SELECT id FROM exercise_groups WHERE name = 'Obliques'), 'https://example.com/videos/russian_twists.mp4', 'https://example.com/images/russian_twists.jpg', 0);