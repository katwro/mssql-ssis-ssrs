USE [FinRecover]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[AddNewDebt]
    @Pesel CHAR(11),
    @Amount MONEY,
    @DebtDate DATE,
    @Description NVARCHAR(255),
    @Installments INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @DebtDate > CAST(GETDATE() AS DATE)
    BEGIN
        RAISERROR('Start date cannot be in the future.', 16, 1);
        RETURN;
    END

    DECLARE @ClientID INT, @ClientNumber NVARCHAR(20);

    SELECT 
        @ClientID = ClientID, 
        @ClientNumber = ClientNumber 
    FROM Clients 
    WHERE Pesel = @Pesel;

    IF @ClientID IS NULL
    BEGIN
        RAISERROR('Client not found for given PESEL.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DebtSequence INT;
        SELECT @DebtSequence = ISNULL(MAX(CAST(RIGHT(DebtNumber, 4) AS INT)), 0) + 1
        FROM Debts
        WHERE ClientID = @ClientID;

        DECLARE @DebtNumber NVARCHAR(50);
        SET @DebtNumber = @ClientNumber + '-' 
                        + RIGHT('0000' + CAST(@DebtSequence AS NVARCHAR(4)), 4);

        INSERT INTO Debts (ClientID, Amount, DebtDate, Description, DebtNumber)
        VALUES (@ClientID, @Amount, @DebtDate, @Description, @DebtNumber);




        DECLARE @NewDebtID INT = SCOPE_IDENTITY();
        DECLARE @StandardInstallmentAmount MONEY = ROUND(@Amount / @Installments, 2);
        DECLARE @TotalAssignedAmount MONEY = 0.0;
        DECLARE @i INT = 1;

        WHILE @i <= @Installments
        BEGIN
            DECLARE @InstallmentAmount MONEY;

            IF @i = @Installments
                SET @InstallmentAmount = @Amount - @TotalAssignedAmount;
            ELSE
                SET @InstallmentAmount = @StandardInstallmentAmount;

            SET @TotalAssignedAmount += @InstallmentAmount;

            INSERT INTO PaymentSchedules (DebtID, DueDate, AmountDue)
            VALUES (@NewDebtID, DATEADD(MONTH, @i, @DebtDate), @InstallmentAmount);

            SET @i += 1;
        END

        INSERT INTO DebtStatusHistory (DebtID, Status, ChangedBy)
        VALUES (@NewDebtID, 'Scheduled', 'AddNewDebt');

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


