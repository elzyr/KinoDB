USE KinoDB;
GO

CREATE OR ALTER PROCEDURE Admin_UsunUzytkownika
	@Email NVARCHAR(100)
AS
BEGIN
	DELETE FROM dbo.Uzytkownicy
	WHERE Email = @Email;

	IF @@ROWCOUNT = 0
	BEGIN
	RAISERROR('Nie znaleziono użytkownika o podanym adresie e-mail: %s.', 16, 1, @Email);
	END
END;
GO

CREATE OR ALTER PROCEDURE Admin_DodajKategorie
	@Nazwa NVARCHAR(100)
AS
BEGIN
	INSERT INTO dbo.Kategorie (nazwa)
	VALUES (@Nazwa);
END;
GO

CREATE OR ALTER PROCEDURE Admin_UsunKategorie
	@KategoriaID INT
AS
BEGIN
	DELETE FROM dbo.Kategorie
	WHERE kategoria_id = @KategoriaID;
END;
GO

CREATE OR ALTER PROCEDURE Admin_DodajFilm
	@Tytul NVARCHAR(200),
	@MinimalnyWiek INT,
	@CzasTrwania INT,
	@KategoriaID INT
AS
BEGIN
	INSERT INTO dbo.Filmy (Tytul, minimalny_wiek, Czas_trwania, kategoria_id)
	OUTPUT inserted.film_id AS NowyFilmID
	VALUES (@Tytul, @MinimalnyWiek, @CzasTrwania, @KategoriaID);
END;
GO

CREATE OR ALTER PROCEDURE Admin_UsunFilm
	@FilmID INT
AS
BEGIN
	DELETE FROM dbo.Filmy
	WHERE film_id = @FilmID;
END;
GO

CREATE OR ALTER VIEW Admin_PopularnoscFilmow AS
	SELECT *
	FROM OPENQUERY(kinolodz,
	'SELECT tytul,
	tyg_start AS PoczatekTygodnia,
	tyg_koniec AS KoniecTygodnia,
	proc_zapelnienia AS ProcZapelnienia
	FROM vw_popularnosc_filmow'
	);
GO

CREATE OR ALTER PROCEDURE Admin_AktualizujStatystykiSprzedazy
	@Tytul NVARCHAR(200)
AS
BEGIN
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

CREATE OR ALTER PROCEDURE admin_DodajKategorie
    @Nazwa NVARCHAR(100)
AS
BEGIN
	BEGIN TRAN;

	INSERT INTO dbo.Kategorie(nazwa)
	VALUES (@Nazwa);
	EXEC (
		N'BEGIN
			SCOTT.Admin_Pkg.dodaj_kategorie(?);
		END;',
		@Nazwa
	) AT kinolodz;

	COMMIT;
END;
GO



USE KinoDB;
GO
CREATE OR ALTER PROCEDURE admin_DodajFilm
    @Tytul NVARCHAR(200),
    @CzasTrwania    INT,
    @MinimalnyWiek  INT,
    @IdKategorii    INT
AS
BEGIN
	BEGIN TRAN;
	INSERT INTO dbo.Filmy
			(tytul, czas_trwania, minimalny_wiek, kategoria_id, czy_wycofany)
	VALUES(@Tytul, @CzasTrwania, @MinimalnyWiek, @IdKategorii, 0);
	EXEC (
		N'BEGIN
			SCOTT.Admin_Pkg.dodaj_film(?,?,?,?);
		END;',
		@Tytul,
		@CzasTrwania,
		@MinimalnyWiek,
		@IdKategorii
	) AT kinolodz;

	COMMIT;
END;
GO

CREATE OR ALTER VIEW Admin_PopularnoscFilmow AS
 SELECT *
 FROM OPENQUERY(kinolodz,
  'SELECT
	film_id,
     tytul,
     tyg_start      AS PoczatekTygodnia,
     tyg_koniec     AS KoniecTygodnia,
     proc_zapelnienia AS ProcZapelnienia
   FROM vw_popularnosc_filmow'
 );
GO




CREATE OR ALTER PROCEDURE Admin_Statystyki_do_pliku
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @plik NVARCHAR(200) = 'C:\Temp\statystyki.xlsx';

    SET @sql = '
    INSERT INTO OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0 Xml;HDR=YES;Database=' + @plik + ''',
        ''SELECT film_id, tytul, srednia_popularnosc, poziom_oceny, ostatnia_aktualizacja FROM [Arkusz1$]'')
    SELECT
        film_id,
        tytul,
        srednia_popularnosc,
        poziom_oceny,
        ostatnia_aktualizacja
    FROM statystyki_sprzedazy;
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
        @Ocena NVARCHAR(50),
        @FilmID INT;

    SELECT 
        @FilmID = film_id,
        @Srednia = AVG(ProcZapelnienia)
    FROM Admin_PopularnoscFilmow
    WHERE tytul = @Tytul
    GROUP BY film_id;

    IF @Srednia IS NULL OR @FilmID IS NULL
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

    IF EXISTS (SELECT 1 FROM statystyki_sprzedazy WHERE film_id = @FilmID)
    BEGIN
        UPDATE statystyki_sprzedazy
        SET
            srednia_popularnosc = @Srednia,
            poziom_oceny = @Ocena,
            ostatnia_aktualizacja = GETDATE()
        WHERE film_id = @FilmID;
    END
    ELSE
    BEGIN
        INSERT INTO statystyki_sprzedazy (film_id, tytul, srednia_popularnosc, poziom_oceny)
        VALUES (@FilmID, @Tytul, @Srednia, @Ocena);
    END
END;
GO


