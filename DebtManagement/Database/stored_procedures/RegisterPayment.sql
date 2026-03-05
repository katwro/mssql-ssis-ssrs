USE [FinRecover]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[RegisterPayment]
    @DebtID INT,
    @PaymentDate DATE,
    @AmountPaid MONEY,
    @Notes NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Payments (DebtID, PaymentDate, AmountPaid, Notes)
        VALUES (@DebtID, @PaymentDate, @AmountPaid, @Notes);

        
        DECLARE @UnassignedPaymentAmount MONEY = @AmountPaid;


        WHILE @UnassignedPaymentAmount > 0
        BEGIN
            DECLARE @ScheduleID INT, @AmountDue MONEY, @AmountPaidSoFar MONEY;

            SELECT TOP 1
                @ScheduleID = ScheduleID,
                @AmountDue = AmountDue,
                @AmountPaidSoFar = AmountPaid
            FROM PaymentSchedules
            WHERE DebtID = @DebtID AND AmountPaid < AmountDue
            ORDER BY DueDate;

            IF @ScheduleID IS NULL
                BREAK;

            DECLARE @InstallmentPayment MONEY = 
                CASE 
                    WHEN @UnassignedPaymentAmount >= (@AmountDue - @AmountPaidSoFar) 
                        THEN (@AmountDue - @AmountPaidSoFar)
                    ELSE @UnassignedPaymentAmount
                END;

            UPDATE PaymentSchedules
            SET AmountPaid = 
                CASE 
                    WHEN (AmountPaid + @InstallmentPayment) > AmountDue 
                    THEN AmountDue 
                    ELSE AmountPaid + @InstallmentPayment 
                END
            WHERE ScheduleID = @ScheduleID;

            INSERT INTO InstallmentPayments (ScheduleID, PaymentDate, Amount)
            VALUES (@ScheduleID, @PaymentDate, @InstallmentPayment);

            SET @UnassignedPaymentAmount -= @InstallmentPayment;
        END;


        IF NOT EXISTS (
            SELECT 1
            FROM PaymentSchedules
            WHERE DebtID = @DebtID AND AmountPaid < AmountDue
        )
        BEGIN
            UPDATE Debts
            SET Status = 'Paid'
            WHERE DebtID = @DebtID;

            INSERT INTO DebtStatusHistory (DebtID, Status, ChangedBy)
            VALUES (@DebtID, 'Paid', 'RegisterPayment');
        END
        ELSE
        BEGIN
            DECLARE @CurrentStatus NVARCHAR(50);
            SELECT @CurrentStatus = Status FROM Debts WHERE DebtID = @DebtID;

            IF @CurrentStatus IN ('Overdue', 'Upcoming')
            BEGIN
                UPDATE Debts
                SET Status = 'Scheduled'
                WHERE DebtID = @DebtID;

                INSERT INTO DebtStatusHistory (DebtID, Status, ChangedBy)
                VALUES (@DebtID, 'Scheduled', 'RegisterPayment');
            END
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW 
    END CATCH
END;
GO


