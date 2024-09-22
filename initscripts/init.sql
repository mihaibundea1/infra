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
    (1, 'abdominals', 's3://proveit-exercises-directories/muscle_groups/abdominals.png'),
    (2, 'abductors', 's3://proveit-exercises-directories/muscle_groups/abductors.png'),
    (3, 'adductors', 's3://proveit-exercises-directories/muscle_groups/adductors.png'),
    (4, 'biceps', 's3://proveit-exercises-directories/muscle_groups/biceps.png'),
    (5, 'calves', 's3://proveit-exercises-directories/muscle_groups/calves.png'),
    (6, 'chest', 's3://proveit-exercises-directories/muscle_groups/chest.png'),
    (7, 'forearms', 's3://proveit-exercises-directories/muscle_groups/forearms.png'),
    (8, 'glutes', 's3://proveit-exercises-directories/muscle_groups/glutes.png'),
    (9, 'hamstrings', 's3://proveit-exercises-directories/muscle_groups/hamstrings.png'),
    (10, 'lats', 's3://proveit-exercises-directories/muscle_groups/lats.png'),
    (11, 'lower back', 's3://proveit-exercises-directories/muscle_groups/lower_back.png'),
    (12, 'middle back', 's3://proveit-exercises-directories/muscle_groups/middle_back.png'),
    (13, 'neck', 's3://proveit-exercises-directories/muscle_groups/neck.png'),
    (14, 'quadriceps', 's3://proveit-exercises-directories/muscle_groups/quadriceps.png'),
    (15, 'shoulders', 's3://proveit-exercises-directories/muscle_groups/shoulders.png'),
    (16, 'traps', 's3://proveit-exercises-directories/muscle_groups/traps.png'),
    (17, 'triceps', 's3://proveit-exercises-directories/muscle_groups/triceps.png');

-- Create function for images path
DELIMITER //
CREATE FUNCTION get_image_path(exercise_id VARCHAR(255), image_number INT) 
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  RETURN CONCAT('/var/lib/mysql-files/exercises/', exercise_id, '/', image_number, '.jpg');
END //
DELIMITER ;

-- Checks if the file exists
DELIMITER //
CREATE FUNCTION file_exists(file_path VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE result INT;
  SET result = (SELECT COUNT(*) FROM information_schema.files WHERE file_name = file_path);
  RETURN result > 0;
END //
DELIMITER ;

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
    JSON_ARRAY(
        get_image_path(JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.id')), 0),
        CASE WHEN file_exists(get_image_path(JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.id')), 1))
             THEN get_image_path(JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.id')), 1)
             ELSE NULL
        END
    )
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
    -- Extragem corect numele muschilor din JSON
    JOIN JSON_TABLE(e.primary_muscles, '$[*]' COLUMNS (muscle_name VARCHAR(100) PATH '$')) AS jt
    -- Facem legătura între numele muschilor și grupurile de mușchi din exercise_groups
    JOIN exercise_groups eg ON LOWER(jt.muscle_name COLLATE utf8mb4_general_ci) = LOWER(eg.name COLLATE utf8mb4_general_ci);

-- Clean-up
DROP FUNCTION IF EXISTS get_image_path;
DROP FUNCTION IF EXISTS file_exists;