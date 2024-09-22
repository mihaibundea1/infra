-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS Exercises;
USE Exercises;

-- Create the exercise_groups table
CREATE TABLE IF NOT EXISTS exercise_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255)
);

-- Create the exercises table with backticks around column names
CREATE TABLE IF NOT EXISTS exercises (
    `id` VARCHAR(255) PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `force` VARCHAR(50),
    `level` VARCHAR(50),
    `mechanic` VARCHAR(50),
    `equipment` VARCHAR(255),
    `category` VARCHAR(50),
    `primary_muscles` JSON,
    `secondary_muscles` JSON,
    `instructions` JSON,
    `images` JSON
);

-- Create a new table for the many-to-many relationship
CREATE TABLE IF NOT EXISTS exercise_primary_muscles (
    exercise_id VARCHAR(255),
    muscle_group_id INT,
    PRIMARY KEY (exercise_id, muscle_group_id),
    FOREIGN KEY (exercise_id) REFERENCES exercises(id),
    FOREIGN KEY (muscle_group_id) REFERENCES exercise_groups(id)
);

-- Insert all muscle groups into the exercise_groups table with updated S3 URLs and manual IDs
INSERT INTO exercise_groups (id, name, image_url) VALUES
    (1, 'Abdominals', 's3://proveit-exercises-directories/muscle_groups/abdominals.png'),
    (2, 'Abductors', 's3://proveit-exercises-directories/muscle_groups/abductors.png'),
    (3, 'Adductors', 's3://proveit-exercises-directories/muscle_groups/adductors.png'),
    (4, 'Biceps', 's3://proveit-exercises-directories/muscle_groups/biceps.png'),
    (5, 'Calves', 's3://proveit-exercises-directories/muscle_groups/calves.png'),
    (6, 'Chest', 's3://proveit-exercises-directories/muscle_groups/chest.png'),
    (7, 'Forearms', 's3://proveit-exercises-directories/muscle_groups/forearms.png'),
    (8, 'Glutes', 's3://proveit-exercises-directories/muscle_groups/glutes.png'),
    (9, 'Hamstrings', 's3://proveit-exercises-directories/muscle_groups/hamstrings.png'),
    (10, 'Lats', 's3://proveit-exercises-directories/muscle_groups/lats.png'),
    (11, 'Lower Back', 's3://proveit-exercises-directories/muscle_groups/lower_back.png'),
    (12, 'Middle Back', 's3://proveit-exercises-directories/muscle_groups/middle_back.png'),
    (13, 'Neck', 's3://proveit-exercises-directories/muscle_groups/neck.png'),
    (14, 'Quadriceps', 's3://proveit-exercises-directories/muscle_groups/quadriceps.png'),
    (15, 'Shoulders', 's3://proveit-exercises-directories/muscle_groups/shoulders.png'),
    (16, 'Traps', 's3://proveit-exercises-directories/muscle_groups/traps.png'),
    (17, 'Triceps', 's3://proveit-exercises-directories/muscle_groups/triceps.png');

-- Import JSON data into exercises table
SET @json_data = LOAD_FILE('/docker-entrypoint-initdb.d/exercises.json');

INSERT INTO exercises (
    `id`,
    `name`,
    `force`,
    `level`,
    `mechanic`,
    `equipment`,
    `category`,
    `primary_muscles`,
    `secondary_muscles`,
    `instructions`,
    `images`
)
SELECT 
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.id')),
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.name')),
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.force')),
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.level')),
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.mechanic')),
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.equipment')),
    JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.category')),
    JSON_EXTRACT(exercise, '$.primaryMuscles'),
    JSON_EXTRACT(exercise, '$.secondaryMuscles'),
    JSON_EXTRACT(exercise, '$.instructions'),
    JSON_EXTRACT(exercise, '$.images')
FROM JSON_TABLE(
    @json_data,
    '$[*]' COLUMNS (
        exercise JSON PATH '$'
    )
) AS exercises_json;

-- Create and populate the exercise_primary_muscles table
INSERT INTO exercise_primary_muscles (exercise_id, muscle_group_id)
SELECT 
    e.id,
    eg.id
FROM 
    exercises e
    CROSS JOIN JSON_TABLE(e.primary_muscles, '$[*]' COLUMNS (muscle_name VARCHAR(100) PATH '$')) as jt
    JOIN exercise_groups eg ON LOWER(jt.muscle_name) = LOWER(eg.name);

-- Verify data insertion
SELECT COUNT(*) FROM exercises;
SELECT COUNT(*) FROM exercise_primary_muscles;