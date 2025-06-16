USE KinoDB;
GO

CREATE OR ALTER PROCEDURE klient_DodajUzytkownika
 @Imie NVARCHAR(50),
 @Nazwisko NVARCHAR(50),
 @DataUrodzenia DATE,
 @Email NVARCHAR(100),
 @Rola NVARCHAR(20)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 BEGIN TRY
  BEGIN TRAN;

  INSERT INTO dbo.Uzytkownicy (Imie, Nazwisko, data_urodzenia, Email, rola)
  OUTPUT inserted.user_id AS NowyUzytkownikID
  VALUES (@Imie, @Nazwisko, @DataUrodzenia, @Email, @Rola);

  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE klient_ZarezerwujSeans
 @Email NVARCHAR(100),
 @TytulFilmu NVARCHAR(200),
 @DataSeansu DATETIME,
 @PreferencjaRzad INT,
 @IloscMiejsc INT
AS
BEGIN
 SET NOCOUNT ON;

 DECLARE @UserId INT;
 DECLARE @rabat DECIMAL(3,2);

 SELECT 
   @UserId = user_id,
   @rabat = CASE WHEN rola = N'premium' THEN 0.9 ELSE 1.0 END
 FROM dbo.Uzytkownicy
 WHERE email = @Email;

 IF @UserId IS NULL
 BEGIN
  THROW 50000, N'Nieprawidlowy adres e-mail uzytkownika.', 1;
  RETURN;
 END

 EXEC (
  N'BEGIN
    Klient_Pkg.Zarezerwuj_Seans(?,?,?,?,?,?);
  END;',
  @UserId,
  @TytulFilmu,
  @DataSeansu,
  @PreferencjaRzad,
  @IloscMiejsc,
  @rabat
 ) AT kinolodz;

 EXEC Admin_AktualizujStatystykiSprzedazy @TytulFilmu;
END;
GO

CREATE OR ALTER PROCEDURE klient_AnulujRezerwacje
 @Email NVARCHAR(100),
 @TytulFilmu NVARCHAR(200),
 @DataSeansu DATETIME
AS
BEGIN
 SET NOCOUNT ON;

 DECLARE @UserId INT;

 SELECT @UserId = user_id
 FROM dbo.Uzytkownicy
 WHERE email = @Email;

 IF @UserId IS NULL
 BEGIN
  THROW 50000, N'Nieprawidlowy adres e-mail uzytkownika.', 1;
  RETURN;
 END

 EXEC (
  N'BEGIN
    Klient_Pkg.Anuluj_Rezerwacje(?,?,?);
  END;',
  @UserId,
  @TytulFilmu,
  @DataSeansu
 ) AT kinolodz;
END;
GO


CREATE OR ALTER VIEW klient_PokazSeanse AS
SELECT
    tytul,
    data_rozpoczecia,
    wolne_miejsca
FROM OPENROWSET(
    'OraOLEDB.Oracle',
    'Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=pd19c)));User ID=SCOTT;Password=12345;',
    'SELECT tytul, data_rozpoczecia, wolne_miejsca FROM SCOTT.vw_seanse'
);
GO

CREATE OR ALTER VIEW klient_PokazRezerwacje AS
 SELECT *
 FROM OPENQUERY(
  kinolodz,
  'SELECT 
     rezerwacja_id,
     tytul,
     data_seansu,
     rzad,
     miejsce,
     cena_laczna,
     uzytkownik
   FROM SCOTT.v_rezerwacje'
 );
GO
