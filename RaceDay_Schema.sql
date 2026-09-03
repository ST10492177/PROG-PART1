/* ============================================================
   RaceDay - Database Schema
   Target: Microsoft SQL Server (SSMS)
   Description: Creates and seeds the RaceDay event management
   database. Run this script on a clean SQL Server instance.
   ============================================================ */

IF DB_ID('RaceDayDB') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

/* ---------------------------------------------------------
   Table: Organiser
   --------------------------------------------------------- */
CREATE TABLE Organiser (
    OrganiserId     INT IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(255)   NOT NULL,
    DateRegistered  DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

/* ---------------------------------------------------------
   Table: Participant
   --------------------------------------------------------- */
CREATE TABLE Participant (
    ParticipantId   INT IDENTITY(1,1) PRIMARY KEY,
    FullName        NVARCHAR(100)   NOT NULL,
    Email           NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(255)   NOT NULL,
    DateRegistered  DATETIME        NOT NULL DEFAULT GETDATE()
);
GO

/* ---------------------------------------------------------
   Table: Event
   Created by an Organiser.
   --------------------------------------------------------- */
CREATE TABLE Event (
    EventId         INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId     INT             NOT NULL,
    EventName       NVARCHAR(150)   NOT NULL,
    EventDate       DATE            NOT NULL,
    Location        NVARCHAR(150)   NOT NULL,
    Description     NVARCHAR(MAX)   NULL,
    EventType       NVARCHAR(20)    NOT NULL
                        CONSTRAINT CK_Event_Type CHECK (EventType IN ('Run','Walk','Cycle')),
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserId) REFERENCES Organiser(OrganiserId)
);
GO

/* ---------------------------------------------------------
   Table: Category
   Belongs to one Event (e.g. 5km, 10km, 21km).
   --------------------------------------------------------- */
CREATE TABLE Category (
    CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
    EventId         INT             NOT NULL,
    CategoryName    NVARCHAR(50)    NOT NULL,
    DistanceKm      DECIMAL(5,2)    NOT NULL,
    EntryFee        DECIMAL(8,2)    NOT NULL DEFAULT 0,
    MaxParticipants INT             NOT NULL DEFAULT 500,
    CONSTRAINT FK_Category_Event FOREIGN KEY (EventId) REFERENCES Event(EventId)
);
GO

/* ---------------------------------------------------------
   Table: Route
   One-to-one with Event: route/weather info.
   --------------------------------------------------------- */
CREATE TABLE Route (
    RouteId           INT IDENTITY(1,1) PRIMARY KEY,
    EventId           INT             NOT NULL UNIQUE,
    RouteDescription  NVARCHAR(MAX)   NULL,
    ElevationGainM    INT             NULL,
    MapUrl            NVARCHAR(255)   NULL,
    WeatherNotes      NVARCHAR(255)   NULL,
    CONSTRAINT FK_Route_Event FOREIGN KEY (EventId) REFERENCES Event(EventId)
);
GO

/* ---------------------------------------------------------
   Table: Enrolment
   Links a Participant to a Category.
   --------------------------------------------------------- */
CREATE TABLE Enrolment (
    EnrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT             NOT NULL,
    CategoryId      INT             NOT NULL,
    EnrolmentDate   DATETIME        NOT NULL DEFAULT GETDATE(),
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Confirmed'
                        CONSTRAINT CK_Enrolment_Status CHECK (Status IN ('Confirmed','Cancelled')),
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantId) REFERENCES Participant(ParticipantId),
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (CategoryId) REFERENCES Category(CategoryId),
    CONSTRAINT UQ_Enrolment_ParticipantCategory UNIQUE (ParticipantId, CategoryId)
);
GO

/* ---------------------------------------------------------
   Table: Result
   One-to-one with Enrolment. Captured by an Organiser.
   --------------------------------------------------------- */
CREATE TABLE Result (
    ResultId          INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId       INT             NOT NULL UNIQUE,
    FinishTime        TIME            NULL,
    OverallPosition   INT             NULL,
    CategoryPosition  INT             NULL,
    CapturedBy        INT             NOT NULL,
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentId) REFERENCES Enrolment(EnrolmentId),
    CONSTRAINT FK_Result_CapturedBy FOREIGN KEY (CapturedBy) REFERENCES Organiser(OrganiserId)
);
GO

/* ============================================================
   SEED DATA
   ============================================================ */

-- Organisers (2)
INSERT INTO Organiser (FullName, Email, PasswordHash) VALUES
('Thandiwe Mokoena', 'thandiwe.mokoena@raceday.co.za', 'HASHED_PW_1'),
('Johan van der Merwe', 'johan.vdm@raceday.co.za', 'HASHED_PW_2');
GO

-- Participants (2)
INSERT INTO Participant (FullName, Email, PasswordHash) VALUES
('Sipho Ndlovu', 'sipho.ndlovu@example.com', 'HASHED_PW_3'),
('Emma Peters', 'emma.peters@example.com', 'HASHED_PW_4');
GO

-- Events (3)
INSERT INTO Event (OrganiserId, EventName, EventDate, Location, Description, EventType) VALUES
(1, 'Pretoria Park Run Challenge', '2026-10-10', 'Pretoria, Gauteng', 'A community park run through the Pretoria botanical gardens.', 'Run'),
(1, 'Tshwane Charity Walk', '2026-11-01', 'Centurion, Gauteng', 'A family-friendly charity walk raising funds for local schools.', 'Walk'),
(2, 'Cape Winelands Cycle Tour', '2026-11-22', 'Stellenbosch, Western Cape', 'A scenic cycling tour through the Cape Winelands.', 'Cycle');
GO

-- Categories (at least one per event)
INSERT INTO Category (EventId, CategoryName, DistanceKm, EntryFee, MaxParticipants) VALUES
(1, '5km', 5.0, 80.00, 300),
(1, '10km', 10.0, 120.00, 300),
(2, '5km Walk', 5.0, 60.00, 500),
(3, '50km', 50.0, 350.00, 200),
(3, '100km', 100.0, 450.00, 150);
GO

-- Route info (per event)
INSERT INTO Route (EventId, RouteDescription, ElevationGainM, MapUrl, WeatherNotes) VALUES
(1, 'Loop through the Pretoria National Botanical Garden, mostly flat with one short hill.', 45, 'https://maps.example.com/pretoria-parkrun', 'Check for summer thunderstorms in the afternoon.'),
(2, 'Flat route through Centurion suburbs, finishing at the Centurion Lake.', 20, 'https://maps.example.com/tshwane-walk', 'Mild mornings, bring sunscreen.'),
(3, 'Rolling hills through vineyards from Stellenbosch to Franschhoek and back.', 620, 'https://maps.example.com/winelands-cycle', 'Windy in the afternoon; start early.');
GO

-- Enrolments
INSERT INTO Enrolment (ParticipantId, CategoryId, Status) VALUES
(1, 1, 'Confirmed'),
(1, 4, 'Confirmed'),
(2, 2, 'Confirmed'),
(2, 3, 'Confirmed');
GO

-- Results (captured by the owning Organiser)
INSERT INTO Result (EnrolmentId, FinishTime, OverallPosition, CategoryPosition, CapturedBy) VALUES
(1, '00:24:15', 12, 5, 1),
(3, '00:52:40', 30, 10, 1);
GO
