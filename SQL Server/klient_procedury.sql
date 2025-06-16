USE KinoDB;
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
  THROW 50000, N'Nieprawid�owy adres e-mail u�ytkownika.', 1;
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
  THROW 50000, N'Nieprawid�owy adres e-mail u�ytkownika.', 1;
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

 EXEC Admin_AktualizujStatystykiSprzedazy @TytulFilmu;
END;
GO


CREATE OR ALTER VIEW klient_PokazSeanse AS
 SELECT
  tytul,
  data_rozpoczecia,
  wolne_miejsca
 FROM OPENQUERY(
  kinolodz,
  'SELECT tytul, data_rozpoczecia, wolne_miejsca
   FROM SCOTT.vw_seanse'
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
