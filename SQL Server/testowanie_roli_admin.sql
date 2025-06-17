USE KinoDB;
GO
EXEC dbo.Admin_DodajKategorie
    @Nazwa = N'Muzyczne';
GO

SELECT * FROM dbo.statystyki_sprzedazy;
GO


EXEC admin_DodajKategorie N'TestCat';

Select * From dbo.Kategorie

insert into Filmy (Tytul,minimalny_wiek,Czas_trwania,kategoria_id) values ('Fajny film2','18',130,1);

SELECT * FROM dbo.Filmy WHERE tytul = N'Fajny film2';

