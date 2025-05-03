USE [FinRecover]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddNewClient]
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Email NVARCHAR(255),
    @PhoneNumber NVARCHAR(20),
    @Pesel CHAR(11)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NextNumber INT;

        SELECT @NextNumber = ISNULL(MAX(CAST(SUBSTRING(ClientNumber, 5, LEN(ClientNumber)) AS INT)), 0) + 1
        FROM (
            SELECT ClientNumber FROM Clients
            UNION ALL
            SELECT ClientNumber FROM Stg_Clients
        ) AS AllClients;

        DECLARE @ClientNumber NVARCHAR(20);
        SET @ClientNumber = 'CUST' + RIGHT('00000' + CAST(@NextNumber AS NVARCHAR(5)), 5);

        INSERT INTO Stg_Clients (FirstName, LastName, Email, PhoneNumber, Pesel, ClientNumber)
        VALUES (@FirstName, @LastName, @Email, @PhoneNumber, @Pesel, @ClientNumber);

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO


