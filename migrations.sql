-- database creation
CREATE DATABASE HotelManagement;
USE HotelManagement;

-- Create Room Types Table
CREATE TABLE RoomTypes (
    RoomTypeID INT AUTO_INCREMENT PRIMARY KEY,
    RoomType VARCHAR(50),
    Description TEXT,
    BasePrice DECIMAL(10, 2) CHECK (BasePrice >= 0)
);

-- Create room table
CREATE TABLE Rooms (
    RoomNumber INT PRIMARY KEY,
    RoomTypeID INT,
    AdditionalPrice DECIMAL(10, 2) DEFAULT 0 CHECK (AdditionalPrice >= 0),
    FOREIGN KEY (RoomTypeID) REFERENCES RoomTypes(RoomTypeID)
);

-- Create Guests table
CREATE TABLE Guests ( 
    GuestID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(15) UNIQUE,
    Address TEXT
);

-- Create reservations table (Reservations)
CREATE TABLE Reservations (
    ReservationID INT AUTO_INCREMENT PRIMARY KEY,
    GuestID INT,
    CheckInDate DATE,
    CheckOutDate DATE,
    RoomNumber INT,
    FOREIGN KEY (GuestID) REFERENCES Guests(GuestID),
    FOREIGN KEY (RoomNumber) REFERENCES Rooms(RoomNumber),
    CHECK (CheckOutDate > CheckInDate)
);

-- Create services table (Services)
CREATE TABLE Services (
    ServiceID INT AUTO_INCREMENT PRIMARY KEY,
    ServiceName VARCHAR(100),
    Price DECIMAL(10, 2)
);

-- Create many-to-many relationship table (ReservationServices)
CREATE TABLE ReservationServices (
    ReservationID INT,
    ServiceID INT,
    PRIMARY KEY (ReservationID, ServiceID),
    FOREIGN KEY (ReservationID) REFERENCES Reservations(ReservationID),
    FOREIGN KEY (ServiceID) REFERENCES Services(ServiceID)
);

-- INDEXIERING
CREATE INDEX idx_guest_email ON Guests (Email);
CREATE INDEX idx_room_type ON RoomTypes (RoomType);
CREATE INDEX idx_guest_id ON Reservations (GuestID);
CREATE INDEX idx_check_in_date ON Reservations (CheckInDate);
CREATE INDEX idx_service_name ON Services (ServiceName);


-- INSERT MOCK DATA
INSERT INTO RoomTypes (RoomType, Description, BasePrice) 
VALUES 
('Single', 'Room for one person with a single bed.', 50.00),
('Double', 'Room for two people with double bed.', 75.00),
('Suite', 'Luxury room with multiple services.', 150.00);

-- Insert rooms
INSERT INTO Rooms (RoomNumber, RoomTypeID, AdditionalPrice) 
VALUES 
(101, 1, 5.00),
(102, 2, 0.00),
(103, 3, 20.00),
(104, 1, 10.00),
(105, 2, 5.00);

-- Insert guests
INSERT INTO Guests (FullName, Email, PhoneNumber, Address) 
VALUES 
('Juan Pérez', 'juan.perez@example.com', '555-1234', 'Calle Falsa 123'),
('Ana López', 'ana.lopez@example.com', '555-5678', 'Av. Siempreviva 742'),
('Carlos García', 'carlos.garcia@example.com', '555-8765', 'Paseo de la Reforma 100'),
('María Fernández', 'maria.fernandez@example.com', '555-4321', 'Calle Principal 55'),
('Luis Martínez', 'luis.martinez@example.com', '555-6789', 'Boulevard Central 10');

-- Insert reservations
INSERT INTO Reservations (GuestID, CheckInDate, CheckOutDate, RoomNumber) 
VALUES 
(1, '2024-12-01', '2024-12-05', 101),
(2, '2024-12-02', '2024-12-06', 102),
(3, '2024-12-03', '2024-12-07', 103),
(4, '2024-12-04', '2024-12-08', 104),
(5, '2024-12-05', '2024-12-09', 105);

-- Insert services
INSERT INTO Services (ServiceName, Price) 
VALUES 
('Desayuno', 10.00),
('Spa', 25.00),
('Transporte', 15.00),
('Cena Gourmet', 30.00),
('Lavandería', 8.00);

-- Relate reservations with services
INSERT INTO ReservationServices (ReservationID, ServiceID) 
VALUES 
(1, 1), -- Breakfast for reservation 1
(1, 2), -- Spa for reservation 1
(2, 3), -- Transportation for reservation 2
(3, 4), -- Gourmet Dinner for reservation 3
(4, 5), -- Laundry for reservation 4
(2, 1), -- Breakfast for reservation 2
(5, 2); -- Spa for reservation 5


-- Speciel users
CREATE USER 'hotel_user'@'localhost' IDENTIFIED BY 'p';

GRANT SELECT, INSERT, UPDATE, DELETE ON HotelManagement.Guests TO 'hotel_user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON HotelManagement.Reservations TO 'hotel_user'@'localhost';
FLUSH PRIVILEGES;

-- Stored Procedure
-- Database Stored Procedures for Hotel Reservation System
-- This script includes all stored procedures for managing guests and reservations.

DELIMITER //

-- ================================
-- Procedure: spAddGuest
-- Description: Add a new guest to the system.
-- ================================
CREATE PROCEDURE spAddGuest(
    IN p_FullName VARCHAR(100),
    IN p_Email VARCHAR(100),
    IN p_PhoneNumber VARCHAR(15),
    IN p_Address TEXT
)
BEGIN
    DECLARE v_GuestID INT;

    -- Start transaction
    START TRANSACTION;

    -- Check if email already exists
    SELECT GuestID INTO v_GuestID FROM Guests WHERE Email = p_Email;

    IF v_GuestID IS NOT NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email is already registered.';
    ELSE
        -- Insert new guest
        INSERT INTO Guests (FullName, Email, PhoneNumber, Address)
        VALUES (p_FullName, p_Email, p_PhoneNumber, p_Address);

        -- Commit transaction
        COMMIT;
        
        -- Return GuestID
        SELECT LAST_INSERT_ID() AS GuestID, 'Guest added successfully.' AS Message;
    END IF;
END //

-- ================================
-- Procedure: spGetGuest
-- Description: Retrieve guest information by GuestID.
-- ================================
CREATE PROCEDURE spGetGuest(
    IN p_GuestID INT
)
BEGIN
    START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM Guests WHERE GuestID = p_GuestID) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest not found.';
    END IF;

    SELECT GuestID, FullName, Email, PhoneNumber, Address
    FROM Guests
    WHERE GuestID = p_GuestID;
END //

-- ================================
-- Procedure: spUpdateGuest
-- Description: Update existing guest information.
-- ================================
CREATE PROCEDURE spUpdateGuest(
    IN p_GuestID INT,
    IN p_FullName VARCHAR(100),
    IN p_Email VARCHAR(100),
    IN p_PhoneNumber VARCHAR(15),
    IN p_Address TEXT
)
BEGIN
    DECLARE v_OtherGuestID INT;

    -- Start transaction
    START TRANSACTION;

    -- Check if guest exists
    IF NOT EXISTS (SELECT 1 FROM Guests WHERE GuestID = p_GuestID) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest not found.';
    END IF;

    -- Check if the new email is already used by another guest
    SELECT GuestID INTO v_OtherGuestID FROM Guests WHERE Email = p_Email AND GuestID != p_GuestID;

    IF v_OtherGuestID IS NOT NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email is already used by another guest.';
    END IF;

    -- Validations
    IF p_Email IS NULL THEN
        SET p_Email = SELECT Email FROM Guests WHERE GuestID = p_GuestID;
    END IF;

    IF p_FullName IS NULL THEN
        SET p_FullName = SELECT FullName FROM Guests WHERE GuestID = p_GuestID;
    END IF;

    IF p_PhoneNumber IS NULL THEN
        SET p_PhoneNumber = SELECT PhoneNumber FROM Guests WHERE GuestID = p_GuestID;
    END IF;

    IF p_Address IS NULL THEN
        SET p_Address = SELECT Address FROM Guests WHERE GuestID = p_GuestID;
    END IF;


    -- Update guest information
    UPDATE Guests
    SET FullName = p_FullName,
        Email = p_Email,
        PhoneNumber = p_PhoneNumber,
        Address = p_Address
    WHERE GuestID = p_GuestID;

    -- Commit transaction
    COMMIT;

    SELECT 'Guest updated successfully.' AS Message;
END //

-- ================================
-- Procedure: spDeleteGuest
-- Description: Delete a guest if they have no reservations.
-- ================================
CREATE PROCEDURE spDeleteGuest(
    IN p_GuestID INT
)
BEGIN
    DECLARE v_Count INT;

    -- Start transaction
    START TRANSACTION;

    -- Check if guest exists
    IF NOT EXISTS (SELECT 1 FROM Guests WHERE GuestID = p_GuestID) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest not found.';
    END IF;

    -- Check if guest has any reservations
    SELECT COUNT(*) INTO v_Count
    FROM Reservations
    WHERE GuestID = p_GuestID;

    IF v_Count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete guest with existing reservations.';
    ELSE
        -- Delete guest
        DELETE FROM Guests WHERE GuestID = p_GuestID;

        -- Commit transaction
        COMMIT;

        SELECT 'Guest deleted successfully.' AS Message;
    END IF;
END //

-- ================================
-- Procedure: spGetReservation
-- Description: Retrieve reservation information by ReservationID.
-- ================================
CREATE PROCEDURE spGetReservation(
    IN p_ReservationID INT
)
BEGIN
    SELECT ReservationID, GuestID, RoomNumber, CheckInDate, CheckOutDate
    FROM Reservations
    WHERE ReservationID = p_ReservationID;
END //

-- ================================
-- Procedure: spUpdateReservation
-- Description: Update reservation dates, ensuring no conflicts.
-- ================================
CREATE PROCEDURE spUpdateReservation(
    IN p_ReservationID INT,
    IN p_NewCheckInDate DATE,
    IN p_NewCheckOutDate DATE
)
BEGIN
    DECLARE v_RoomNumber INT;
    DECLARE v_Count INT;

    -- Start transaction
    START TRANSACTION;

    -- Validate dates
    IF p_NewCheckInDate >= p_NewCheckOutDate THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in date must be before check-out date.';
    END IF;

     IF p_NewCheckInDate < CURDATE() THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in date cannot be in the past.';
    END IF;

    -- Get the room number associated with the reservation
    SELECT RoomNumber INTO v_RoomNumber
    FROM Reservations
    WHERE ReservationID = p_ReservationID
    FOR UPDATE;

    IF v_RoomNumber IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation not found.';
    END IF;

    -- Check for overlapping reservations
    SELECT COUNT(*) INTO v_Count
    FROM Reservations
    WHERE RoomNumber = v_RoomNumber
      AND ReservationID != p_ReservationID
      AND ((p_NewCheckInDate < CheckOutDate) AND (p_NewCheckOutDate > CheckInDate))
    FOR UPDATE;

    IF v_Count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for the new dates.';
    ELSE
        -- Update reservation
        UPDATE Reservations
        SET CheckInDate = p_NewCheckInDate, CheckOutDate = p_NewCheckOutDate
        WHERE ReservationID = p_ReservationID;

        -- Commit transaction
        COMMIT;

        SELECT 'Reservation updated successfully.' AS Message;
    END IF;
END //

-- ================================
-- Procedure: spDeleteReservation
-- Description: Delete a reservation.
-- ================================
CREATE PROCEDURE spDeleteReservation(
    IN p_ReservationID INT
)
BEGIN
    -- Start transaction
    START TRANSACTION;

    -- Check if reservation exists
    IF NOT EXISTS (SELECT 1 FROM Reservations WHERE ReservationID = p_ReservationID) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation not found.';
    END IF;

    -- Delete reservation
    DELETE FROM Reservations WHERE ReservationID = p_ReservationID;

    -- Commit transaction
    COMMIT;

    SELECT 'Reservation deleted successfully.' AS Message;
END //

-- ================================
-- Procedure: spCreateReservation
-- Description: Create a reservation for an existing guest using GuestID.
-- ================================
CREATE PROCEDURE spCreateReservation(
    IN p_GuestID INT,
    IN p_RoomNumber INT,
    IN p_CheckInDate DATE,
    IN p_CheckOutDate DATE
)
BEGIN
    DECLARE v_Count INT;

    -- Start transaction
    START TRANSACTION;

    -- Validate dates
    IF p_CheckInDate >= p_CheckOutDate THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in date must be before check-out date.';
    END IF;

    IF p_CheckInDate < CURDATE() THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in date cannot be in the past.';
    END IF;

    -- Check if guest exists
    IF NOT EXISTS (SELECT 1 FROM Guests WHERE GuestID = p_GuestID) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest not found.';
    END IF;

    -- Verify that the room exists
    IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomNumber = p_RoomNumber) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room does not exist.';
    END IF;

    -- Check for overlapping reservations
    SELECT COUNT(*) INTO v_Count
    FROM Reservations
    WHERE RoomNumber = p_RoomNumber
      AND ((p_CheckInDate < CheckOutDate) AND (p_CheckOutDate > CheckInDate))
    FOR UPDATE;

    IF v_Count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for the selected dates.';
    ELSE
        -- Insert the reservation
        INSERT INTO Reservations (GuestID, RoomNumber, CheckInDate, CheckOutDate)
        VALUES (p_GuestID, p_RoomNumber, p_CheckInDate, p_CheckOutDate);

        -- Commit transaction
        COMMIT;

        -- Return confirmation
        SELECT LAST_INSERT_ID() AS ReservationID, 'Reservation created successfully.' AS Message;
    END IF;
END //

-- ================================
-- Procedure: spMakeNoGuestReservation
-- Description: Register a new guest and make a reservation.
-- ================================
CREATE PROCEDURE spMakeNoGuestReservation(
    IN p_FullName VARCHAR(100),
    IN p_Email VARCHAR(100),
    IN p_PhoneNumber VARCHAR(15),
    IN p_Address TEXT,
    IN p_RoomNumber INT,
    IN p_CheckInDate DATE,
    IN p_CheckOutDate DATE
)
BEGIN
    DECLARE v_GuestID INT;
    DECLARE v_Count INT;

    -- Start transaction
    START TRANSACTION;

    -- Validate dates
    IF p_CheckInDate >= p_CheckOutDate THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in date must be before check-out date.';
    END IF;

    IF p_CheckInDate < CURDATE() THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check-in date cannot be in the past.';
    END IF;

    -- Check if guest already exists
    SELECT GuestID INTO v_GuestID FROM Guests WHERE Email = p_Email;

    IF v_GuestID IS NULL THEN
        -- Insert new guest
        INSERT INTO Guests (FullName, Email, PhoneNumber, Address)
        VALUES (p_FullName, p_Email, p_PhoneNumber, p_Address);
        SET v_GuestID = LAST_INSERT_ID();
    END IF;

    -- Verify that the room exists
    IF NOT EXISTS (SELECT 1 FROM Rooms WHERE RoomNumber = p_RoomNumber) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room does not exist.';
    END IF;

    -- Check for overlapping reservations
    SELECT COUNT(*) INTO v_Count
    FROM Reservations
    WHERE RoomNumber = p_RoomNumber
      AND ((p_CheckInDate < CheckOutDate) AND (p_CheckOutDate > CheckInDate))
    FOR UPDATE;

    IF v_Count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for the selected dates.';
    ELSE
        -- Insert the reservation
        INSERT INTO Reservations (GuestID, RoomNumber, CheckInDate, CheckOutDate)
        VALUES (v_GuestID, p_RoomNumber, p_CheckInDate, p_CheckOutDate);

        -- Commit transaction
        COMMIT;

        -- Return confirmation
        SELECT LAST_INSERT_ID() AS ReservationID, 'Reservation created successfully.' AS Message;
    END IF;

END //

DELIMITER ;


