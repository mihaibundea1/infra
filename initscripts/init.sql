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

-- Insert all muscle groups into the exercise_groups table with updated S3 URLs and manual IDs
INSERT INTO exercise_groups (id, name, image_url) VALUES
    (1, 'Pecs', 's3://proveit-exercises-directories/muscle_groups/pecs.png'),
    (2, 'Biceps', 's3://proveit-exercises-directories/muscle_groups/biceps.png'),
    (3, 'Triceps', 's3://proveit-exercises-directories/muscle_groups/triceps.png');
    (4, 'Shoulders', 's3://proveit-exercises-directories/muscle_groups/shoulders.png'),
    (5, 'Forearm', 's3://proveit-exercises-directories/muscle_groups/forearm.png'),
    (6, 'Abs', 's3://proveit-exercises-directories/muscle_groups/abs.png'),
    (7, 'Lateral Abs', 's3://proveit-exercises-directories/muscle_groups/lateralabs.png'),
    (8, 'Hamstrings', 's3://proveit-exercises-directories/muscle_groups/hamstrings.png'),
    (9, 'Buttocks', 's3://proveit-exercises-directories/muscle_groups/buttocks.png'),
    (10, 'Calves', 's3://proveit-exercises-directories/muscle_groups/calves.png'),
    (11, 'Quadriceps', 's3://proveit-exercises-directories/muscle_groups/quad.png'),
    (12, 'Neck', 's3://proveit-exercises-directories/muscle_groups/neck.png'),


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