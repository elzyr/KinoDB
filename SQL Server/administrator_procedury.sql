USE KinoDB;
GO

CREATE OR ALTER PROCEDURE Admin_DodajUzytkownika
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

CREATE OR ALTER PROCEDURE Admin_UsunUzytkownika
 @UzytkownikID INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 BEGIN TRY
  BEGIN TRAN;

  DELETE FROM dbo.Uzytkownicy
  WHERE user_id = @UzytkownikID;

  IF @@ROWCOUNT = 0
  BEGIN
   RAISERROR('Nie znaleziono użytkownika o podanym ID: %d.', 16, 1, @UzytkownikID);
  END

  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Admin_DodajKategorie
 @Nazwa NVARCHAR(100)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 BEGIN TRY
  BEGIN TRAN;

  INSERT INTO dbo.Kategorie (nazwa)
  OUTPUT inserted.kategoria_id AS NowaKategoriaID
  VALUES (@Nazwa);

  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Admin_UsunKategorie
 @KategoriaID INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 BEGIN TRY
  BEGIN TRAN;

  DELETE FROM dbo.Kategorie
  WHERE kategoria_id = @KategoriaID;

  IF @@ROWCOUNT = 0
  BEGIN
   RAISERROR('Nie znaleziono kategorii o podanym ID: %d.', 16, 1, @KategoriaID);
  END

  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Admin_DodajFilm
 @Tytul NVARCHAR(200),
 @MinimalnyWiek INT,
 @CzasTrwania INT,
 @KategoriaID INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 BEGIN TRY
  BEGIN TRAN;

  INSERT INTO dbo.Filmy (Tytul, minimalny_wiek, Czas_trwania, kategoria_id)
  OUTPUT inserted.film_id AS NowyFilmID
  VALUES (@Tytul, @MinimalnyWiek, @CzasTrwania, @KategoriaID);

  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
 END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Admin_UsunFilm
 @FilmID INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 BEGIN TRY
  BEGIN TRAN;

  DELETE FROM dbo.Filmy
  WHERE film_id = @FilmID;

  IF @@ROWCOUNT = 0
  BEGIN
   RAISERROR('Nie znaleziono filmu o podanym ID: %d.', 16, 1, @FilmID);
  END

  COMMIT;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
 END CATCH
END;
GO

CREATE OR ALTER VIEW Admin_PopularnoscFilmow AS
 SELECT *
 FROM OPENQUERY(kinolodz,
  'SELECT
     tytul,
     tyg_start      AS PoczatekTygodnia,
     tyg_koniec     AS KoniecTygodnia,
     proc_zapelnienia AS ProcZapelnienia
   FROM vw_popularnosc_filmow'
 );
GO

CREATE OR ALTER PROCEDURE Admin_ZapiszFilmy
 @Miesiac TINYINT,
 @Rok INT
AS
BEGIN
 SET NOCOUNT ON;

 IF @Miesiac NOT BETWEEN 1 AND 12
  THROW 50010, N'Parametr @Miesiac musi być z zakresu 1–12.', 1;
 IF @Rok < 1900 OR @Rok > 9999
  THROW 50011, N'Parametr @Rok musi być w rozsądnym zakresie (1900–9999).', 1;

 DECLARE @DataOd DATE, @DataDo DATE;
 SET @DataOd = DATEFROMPARTS(@Rok, @Miesiac, 1);
 SET @DataDo = EOMONTH(@DataOd);

 SELECT
  tytul,
  PoczatekTygodnia,
  KoniecTygodnia,
  ProcZapelnienia
 FROM Admin_PopularnoscFilmow
 WHERE KoniecTygodnia >= @DataOd
   AND PoczatekTygodnia <= @DataDo
 ORDER BY tytul, PoczatekTygodnia;
END;
GO
