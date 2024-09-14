-- Create the exercises database
CREATE DATABASE IF NOT EXISTS Exercises;
USE exercises;

-- Create the exercises table
CREATE TABLE IF NOT EXISTS exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    video_url VARCHAR(255),
    image_url VARCHAR(255)
);

-- Insert 10 predefined exercises
INSERT INTO exercises (name, video_url, image_url) VALUES
    ('Push-ups', 'https://example.com/videos/pushups.mp4', 'https://example.com/images/pushups.jpg'),
    ('Squats', 'https://example.com/videos/squats.mp4', 'https://example.com/images/squats.jpg'),
    ('Lunges', 'https://example.com/videos/lunges.mp4', 'https://example.com/images/lunges.jpg'),
    ('Plank', 'https://example.com/videos/plank.mp4', 'https://example.com/images/plank.jpg'),
    ('Burpees', 'https://example.com/videos/burpees.mp4', 'https://example.com/images/burpees.jpg'),
    ('Mountain Climbers', 'https://example.com/videos/mountain_climbers.mp4', 'https://example.com/images/mountain_climbers.jpg'),
    ('Jumping Jacks', 'https://example.com/videos/jumping_jacks.mp4', 'https://example.com/images/jumping_jacks.jpg'),
    ('Sit-ups', 'https://example.com/videos/situps.mp4', 'https://example.com/images/situps.jpg'),
    ('Bicycle Crunches', 'https://example.com/videos/bicycle_crunches.mp4', 'https://example.com/images/bicycle_crunches.jpg'),
    ('Russian Twists', 'https://example.com/videos/russian_twists.mp4', 'https://example.com/images/russian_twists.jpg');