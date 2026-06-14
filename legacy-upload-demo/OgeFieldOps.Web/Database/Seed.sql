-- OGE Field Operations & Outage Portal - seed data
-- Demo credentials (username / password):
--   admin      / Admin@2014     (Admin)
--   dispatcher / Dispatch@2014  (Dispatcher)
--   ftech      / Field@2014     (FieldTech)
-- Password storage = SHA-256(salt + password) hex (period-typical, not modern KDF).

SET NOCOUNT ON;
GO

DELETE FROM dbo.OutageDocuments;
DELETE FROM dbo.Outages;
DELETE FROM dbo.Users;
GO

SET IDENTITY_INSERT dbo.Users ON;
INSERT INTO dbo.Users (Id, Username, DisplayName, Role, PasswordSalt, PasswordHash, IsActive) VALUES
 (1, 'admin',      'System Administrator', 'Admin',      'S1A9adminSalt', '6b373fb70d75461b25c7a7b02469b535b0a8a415b7fdde8afdd29e6ac3b2e6f8', 1),
 (2, 'dispatcher', 'Dana Dispatch',        'Dispatcher', 'D7K2dispSalt',  '9500962d9eb0fbefc9f5614d3fcd71b4b267d851214f0dc31aed3d04b23a3243', 1),
 (3, 'ftech',      'Frank Technician',     'FieldTech',  'F3M8techSalt',  'f6203fca652214a8d1d0c7fe118218fc7d675dec1cce62736233f96d3ef0d6c5', 1);
SET IDENTITY_INSERT dbo.Users OFF;
GO

INSERT INTO dbo.Outages (TicketNumber, Region, Cause, Status, CustomersAffected, ReportedAt, RestoredAt, ReportedBy) VALUES
 ('OUT-2014-1001', 'Oklahoma City', 'Storm - downed line',     'Restored',    1240, '2014-05-12 14:32:00', '2014-05-12 18:10:00', 'dispatcher'),
 ('OUT-2014-1002', 'Tulsa',         'Equipment failure',       'Restored',     310, '2014-05-13 09:05:00', '2014-05-13 11:40:00', 'dispatcher'),
 ('OUT-2014-1003', 'Norman',        'Vehicle vs pole',         'In Progress',  85,  '2014-05-14 07:48:00', NULL,                  'ftech'),
 ('OUT-2014-1004', 'Edmond',        'Tree contact',            'In Progress',  402, '2014-05-14 16:20:00', NULL,                  'dispatcher'),
 ('OUT-2014-1005', 'Lawton',        'Transformer fault',       'Reported',     1530,'2014-05-15 03:11:00', NULL,                  'dispatcher'),
 ('OUT-2014-1006', 'Muskogee',      'Animal contact',          'Restored',     12,  '2014-05-15 12:00:00', '2014-05-15 12:55:00', 'ftech'),
 ('OUT-2014-1007', 'Enid',          'Planned maintenance',     'Restored',     220, '2014-05-16 01:00:00', '2014-05-16 04:30:00', 'admin'),
 ('OUT-2014-1008', 'Stillwater',    'Lightning',               'Reported',     640, '2014-05-16 20:42:00', NULL,                  'dispatcher'),
 ('OUT-2014-1009', 'Shawnee',       'Underground cable fault', 'In Progress',  74,  '2014-05-17 10:15:00', NULL,                  'ftech'),
 ('OUT-2014-1010', 'Ardmore',       'Storm - high winds',      'Restored',     980, '2014-05-17 22:05:00', '2014-05-18 02:20:00', 'dispatcher'),
 ('OUT-2014-1011', 'Ponca City',    'Substation breaker trip', 'Reported',     1110,'2014-05-18 06:30:00', NULL,                  'dispatcher'),
 ('OUT-2014-1012', 'Bartlesville',  'Tree contact',            'Restored',     150, '2014-05-18 15:25:00', '2014-05-18 17:00:00', 'ftech');
GO
