-- V1__create_users.sql

CREATE TABLE users (
    id    INT AUTO_INCREMENT PRIMARY KEY,
    name  VARCHAR(50),
    email VARCHAR(50)
);

INSERT INTO users (name, email) VALUES
('Hritick', 'hritick@test.com'),
('Amit',    'amit@test.com'),
('Priya',   'priya@test.com');
