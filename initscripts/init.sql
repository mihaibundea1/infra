-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS exercises;
USE exercises;

-- Create the exercise_groups table with thumbnail
CREATE TABLE IF NOT EXISTS exercise_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255),
    thumbnail MEDIUMBLOB    -- Added thumbnail column
);

-- Create the exercises table with thumbnails
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
    `images` JSON,
    `thumbnail` MEDIUMBLOB  -- Added thumbnail column
);

-- Create the many-to-many relationship table with thumbnail
CREATE TABLE IF NOT EXISTS exercise_primary_muscles (
    exercise_id VARCHAR(255),
    muscle_group_id INT,
    exercise_name VARCHAR(255),
    image_path VARCHAR(255),
    thumbnail MEDIUMBLOB,    -- Added thumbnail column
    PRIMARY KEY (exercise_id, muscle_group_id),
    FOREIGN KEY (exercise_id) REFERENCES exercises(id),
    FOREIGN KEY (muscle_group_id) REFERENCES exercise_groups(id)
);

-- Insert muscle groups
INSERT INTO exercise_groups (id, name, image_url) VALUES
    (1, 'chest', ''),
    (2, 'shoulders', ''),
    (3, 'triceps', ''),
    (4, 'biceps', ''),
    (5, 'forearms', ''),
    (6, 'lats', ''),
    (7, 'middle back', ''),
    (8, 'lower back', ''),
    (9, 'abdominals', ''),
    (10, 'quadriceps', ''),
    (11, 'hamstrings', ''),
    (12, 'glutes', ''),
    (13, 'calves', ''),
    (14, 'traps', ''),
    (15, 'neck', ''),
    (16, 'adductors', ''),
    (17, 'abductors', '');

-- Create function for images path
DELIMITER //
CREATE FUNCTION get_image_path(exercise_id VARCHAR(255), image_number INT) 
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  RETURN CONCAT('s3://proveit-exercises-directories/exercises/', exercise_id, '/', image_number, '.jpg');
END //
DELIMITER ;

-- Import JSON data into exercises table with thumbnails
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
    `images`,
    `thumbnail`
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
        get_image_path(JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.id')), 1)
    ),
    LOAD_FILE(CONCAT('/docker-entrypoint-initdb.d/processed_exercises_128x128/', 
              JSON_UNQUOTE(JSON_EXTRACT(exercise, '$.id')), '/0.jpg'))
FROM JSON_TABLE(
    @json_data,
    '$[*]' COLUMNS (
        exercise JSON PATH '$'
    )
) AS exercises_json;

-- Create and populate the exercise_primary_muscles table with thumbnails
INSERT INTO exercise_primary_muscles (exercise_id, muscle_group_id, exercise_name, image_path, thumbnail)
SELECT 
    e.id,
    eg.id,
    e.name,
    JSON_UNQUOTE(JSON_EXTRACT(e.images, '$[0]')),
    e.thumbnail  -- Use the thumbnail from exercises table
FROM 
    exercises e
    JOIN JSON_TABLE(e.primary_muscles, '$[*]' COLUMNS (muscle_name VARCHAR(100) PATH '$')) AS jt
    JOIN exercise_groups eg ON LOWER(jt.muscle_name COLLATE utf8mb4_general_ci) = LOWER(eg.name COLLATE utf8mb4_general_ci);

-- Update exercise_groups with the first image found and its thumbnail
UPDATE exercise_groups eg
JOIN (
    SELECT 
        muscle_group_id, 
        MIN(image_path) AS first_image,
        MIN(thumbnail) AS first_thumbnail
    FROM exercise_primary_muscles
    GROUP BY muscle_group_id
) AS first_images ON eg.id = first_images.muscle_group_id
SET eg.image_url = first_images.first_image,
    eg.thumbnail = first_images.first_thumbnail;

-- Clean-up
DROP FUNCTION IF EXISTS get_image_path;
