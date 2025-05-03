USE [FinRecover]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CheckOverdueDebts]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Now DATE = CAST(GETDATE() AS DATE);

        UPDATE DBT
        SET DBT.Status = 'Overdue'
        FROM Debts DBT
        WHERE EXISTS (
            SELECT 1
            FROM PaymentSchedules SCH
            WHERE SCH.DebtID = DBT.DebtID
              AND SCH.DueDate < @Now
              
        )
        AND DBT.Status NOT IN ('Overdue', 'Paid');


		UPDATE DBT
		SET DBT.Status = 'Upcoming'
		FROM Debts DBT
		WHERE EXISTS (
			SELECT 1
			FROM PaymentSchedules SCH
			WHERE SCH.DebtID = DBT.DebtID
			  AND @Now BETWEEN DATEADD(DAY, -7, SCH.DueDate) AND SCH.DueDate
			  
		)
		AND DBT.Status NOT IN ('Upcoming', 'Paid');



        INSERT INTO DebtStatusHistory (DebtID, Status, ChangedBy)
        SELECT DBT.DebtID, 'Overdue', 'CheckOverdueDebts'
        FROM Debts DBT
        WHERE EXISTS (
            SELECT 1
            FROM PaymentSchedules SCH
            WHERE SCH.DebtID = DBT.DebtID
              AND SCH.DueDate < @Now
              
        )
        AND DBT.Status = 'Overdue'
        AND NOT EXISTS (
            SELECT 1 FROM DebtStatusHistory HIST
            WHERE HIST.DebtID = DBT.DebtID AND HIST.Status = 'Overdue'
        );

				INSERT INTO DebtStatusHistory (DebtID, Status, ChangedBy)
		SELECT DBT.DebtID, 'Upcoming', 'CheckOverdueDebts'
		FROM Debts DBT
		WHERE EXISTS (
			SELECT 1
			FROM PaymentSchedules SCH
			WHERE SCH.DebtID = DBT.DebtID
			  AND @Now BETWEEN DATEADD(DAY, -7, SCH.DueDate) AND SCH.DueDate
			  
		)
		AND DBT.Status = 'Upcoming'
		AND NOT EXISTS (
			SELECT 1 FROM DebtStatusHistory HIST
			WHERE HIST.DebtID = DBT.DebtID AND HIST.Status = 'Upcoming'
		);


        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


