USE KinoDB;
GO
EXEC dbo.Admin_DodajKategorie
    @Nazwa = N'Muzyczne';
GO

DECLARE @KategoriaID INT;
SELECT @KategoriaID = kategoria_id FROM dbo.Kategorie WHERE nazwa = N'Muzyczne';

EXEC dbo.Admin_DodajFilm
    @Tytul = N'Bohemian Rhapsody',
    @MinimalnyWiek = 12,
    @CzasTrwania = 134,
    @KategoriaID = @KategoriaID;
GO

EXEC dbo.Admin_AktualizujStatystykiSprzedazy
    @Tytul = N'Bohemian Rhapsody';
GO

SELECT * FROM dbo.Admin_PopularnoscFilmow;
GO
revert

SELECT ORIGINAL_LOGIN() AS OriginalLogin, SYSTEM_USER AS SystemUser;



EXEC dbo.Admin_AktualizujStatystykiSprzedazy @Tytul = N'The Conjuring';
EXEC dbo.Admin_AktualizujStatystykiSprzedazy @Tytul = N'Kraina Lodu';
GO

SELECT * FROM dbo.statystyki_sprzedazy;
GO

EXEC dbo.Admin_Statystyki_do_pliku ;
GO
