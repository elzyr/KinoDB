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




CREATE OR ALTER PROCEDURE Admin_Statystyki_do_pliku
    @Miesiac INT,
    @Rok     INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @plik NVARCHAR(200) = 'C:\Temp\statystyki.xlsx';

    SET @sql = '
    INSERT INTO OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0 Xml;HDR=YES;Database=' + @plik + ''',
        ''SELECT tytul, LiczbaRezerwacji, ProcZapelnienia FROM [Arkusz1$]'')
    SELECT
        tytul,
        COUNT(*) AS LiczbaRezerwacji,
        CAST(AVG(ProcZapelnienia) AS DECIMAL(5,2)) AS ProcZapelnienia
    FROM Admin_PopularnoscFilmow
    WHERE MONTH(PoczatekTygodnia) = ' + CAST(@Miesiac AS NVARCHAR) + '
      AND YEAR(PoczatekTygodnia) = ' + CAST(@Rok AS NVARCHAR) + '
    GROUP BY tytul;
    ';

    EXEC sp_executesql @sql;
END;
GO



CREATE OR ALTER PROCEDURE Admin_AktualizujStatystykiSprzedazy
    @Tytul NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @Srednia DECIMAL(5,2),
        @Ocena NVARCHAR(50);

    SELECT @Srednia = AVG(ProcZapelnienia)
    FROM Admin_PopularnoscFilmow
    WHERE tytul = @Tytul;

    IF @Srednia IS NULL
    BEGIN
        RAISERROR('Brak danych popularności dla filmu: %s', 16, 1, @Tytul);
        RETURN;
    END

    SET @Ocena = CASE 
        WHEN @Srednia < 20 THEN 'Słaba sprzedaż'
        WHEN @Srednia < 50 THEN 'Umiarkowana sprzedaż'
        WHEN @Srednia < 80 THEN 'Dobra sprzedaż'
        ELSE 'Bardzo dobra sprzedaż'
    END;

    IF EXISTS (SELECT 1 FROM statystyki_sprzedazy WHERE tytul = @Tytul)
    BEGIN
        UPDATE statystyki_sprzedazy
        SET
            srednia_popularnosc = @Srednia,
            poziom_oceny = @Ocena,
            ostatnia_aktualizacja = GETDATE()
        WHERE tytul = @Tytul;
    END
    ELSE
    BEGIN
        INSERT INTO statystyki_sprzedazy (tytul, srednia_popularnosc, poziom_oceny)
        VALUES (@Tytul, @Srednia, @Ocena);
    END
END;
GO
