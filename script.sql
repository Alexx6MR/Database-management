
--DEL 1
    -- Simple Select
    SELECT * FROM Reservations;
    SELECT * FROM Guests;

    -- Order The Data
    SELECT * FROM Rooms ORDER BY PricePerNight ASC;

    -- Get the reservation of the user
    SELECT Fullname, Email, RoomID FROM Reservations INNER JOIN Guests ON Reservations.GuestID=Guests.GuestID WHERE Guests.GuestID = 2;

    -- BETWEEN a Range
    SELECT * FROM Rooms WHERE PricePerNight BETWEEN 150 AND 300;

    -- Get the reservation of the user
    SELECT CONCAT("Name: ", FullName, " ", " Room: ", RoomID, " Check In: ", CheckInDate, " Check Out: ", CheckOutDate) AS Reservation  FROM Reservations INNER JOIN Guests ON Reservations.GuestID=Guests.GuestID;

-- DEL 2
DELIMITER //
 --* COMMENT
CREATE PROCEDURE GetGuestReservations(IN guestEmail VARCHAR(100))
BEGIN
    SELECT 
        G.FullName,
        R.ReservationID,
        R.CheckInDate,
        R.CheckOutDate,
        Ro.RoomNumber,
        RT.RoomType,
        (RT.BasePrice + Ro.AdditionalPrice) AS RoomPrice
    FROM 
        Guests G
    INNER JOIN 
        Reservations R ON G.GuestID = R.GuestID
    INNER JOIN 
        Rooms Ro ON R.RoomNumber = Ro.RoomNumber
    INNER JOIN 
        RoomTypes RT ON Ro.RoomTypeID = RT.RoomTypeID
    WHERE 
        G.Email = guestEmail;
END //
 --* COMMENT
CREATE PROCEDURE MakeReservation(
    IN p_GuestEmail VARCHAR(100),
    IN p_RoomNumber INT,
    IN p_CheckInDate DATE,
    IN p_CheckOutDate DATE
)
BEGIN
DECLARE v_Gu estID INT;
    DECLARE v_Count INT;

    -- Retrieve GuestID
    SELECT GuestID INTO v_GuestID FROM Guests WHERE Email = p_GuestEmail;

    IF v_GuestID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest not found.';
    END IF;

    -- Check for overlapping reservations
    SELECT COUNT(*) INTO v_Count
    FROM Reservations
    WHERE RoomNumber = p_RoomNumber
      AND ( (p_CheckInDate < CheckOutDate) AND (p_CheckOutDate > CheckInDate) );

    IF v_Count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for the selected dates.';
    ELSE
        INSERT INTO Reservations (GuestID, RoomNumber, CheckInDate, CheckOutDate)
        VALUES (v_GuestID, p_RoomNumber, p_CheckInDate, p_CheckOutDate);
    END IF;
END //

--* COMMENT
-- Add new User
CREATE PROCEDURE AddGuest(
    IN p_FullName VARCHAR(100),
    IN p_Email VARCHAR(100),
    IN p_PhoneNumber VARCHAR(15),
    IN p_Address TEXT
)
BEGIN
    IF EXISTS (SELECT 1 FROM Guests WHERE Email = p_Email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email already exists.';
    ELSE
        INSERT INTO Guests (FullName, Email, PhoneNumber, Address)
        VALUES (p_FullName, p_Email, p_PhoneNumber, p_Address);
    END IF;
END //


--* COMMENT
CREATE PROCEDURE UpdateReservationDates(
    IN p_ReservationID INT,
    IN p_NewCheckInDate DATE,
    IN p_NewCheckOutDate DATE
)
BEGIN
    DECLARE v_RoomNumber INT;
    DECLARE v_Count INT;

    -- Get the room number associated with the reservation
    SELECT RoomNumber INTO v_RoomNumber FROM Reservations WHERE ReservationID = p_ReservationID;

    IF v_RoomNumber IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation not found.';
    END IF;

    -- Check for overlapping reservations
    SELECT COUNT(*) INTO v_Count
    FROM Reservations
    WHERE RoomNumber = v_RoomNumber
      AND ReservationID != p_ReservationID
      AND ( (p_NewCheckInDate < CheckOutDate) AND (p_NewCheckOutDate > CheckInDate) );

    IF v_Count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available for the new dates.';
    ELSE
        UPDATE Reservations
        SET CheckInDate = p_NewCheckInDate, CheckOutDate = p_NewCheckOutDate
        WHERE ReservationID = p_ReservationID;
    END IF;
END //

--* COMMENT


CREATE PROCEDURE GetAvailableRooms(
    IN p_CheckInDate DATE,
    IN p_CheckOutDate DATE
)
BEGIN
    SELECT 
        Ro.RoomNumber,
        RT.RoomType,
        (RT.BasePrice + Ro.AdditionalPrice) AS RoomPrice
    FROM 
        Rooms Ro
    INNER JOIN 
        RoomTypes RT ON Ro.RoomTypeID = RT.RoomTypeID
    WHERE 
        Ro.RoomNumber NOT IN (
            SELECT RoomNumber
            FROM Reservations
            WHERE (p_CheckInDate < CheckOutDate) AND (p_CheckOutDate > CheckInDate)
        );
END //

DELIMITER ;

-- DEL 3
    -- Prestandaanalys
    EXPLAIN SELECT CONCAT("|Name: ", FullName, " ", "| Room: ", RoomID, "| Check In: ", CheckInDate, " Check Out: ", CheckOutDate) 
    AS Reservation
    FROM Reservations 
    INNER JOIN Guests 
    ON Reservations.GuestID=Guests.GuestID;

    -- help improving the tables
    ANALYZE TABLE Reservations, Guests;

    --Implementera en förbättring baserad på din analys
    CREATE INDEX idx_GuestID ON Reservations (GuestID);
    CREATE INDEX idx_GuestID ON Guests (GuestID);
    CREATE INDEX idx_RoomID ON Reservations (RoomID);
    CREATE INDEX idx_RoomID ON Rooms (RoomID);


-- DEL 4
    -- Create new user and Grant Privilege
    CREATE USER 'limited_user'@'localhost' IDENTIFIED BY 'secure_password';
    GRANT SELECT ON your_database.Guests TO 'limited_user'@'localhost';
    GRANT SELECT ON your_database.Reservations TO 'limited_user'@'localhost';
    
    -- DB Backup
    BACKUP DATABASE databasename TO DISK = 'C:\Users\alexx\Desktop\d-ingupg-d4-Alexx6MR\backup.sql';

    -- Failure simulation and database restoration.
    DROP DATABASE your_database;
    CREATE DATABASE your_database;
    mysql -u root -p your_database < backup.sql