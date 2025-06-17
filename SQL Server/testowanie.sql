USE KinoDB;
GO

insert into Kategorie (nazwa) values ('Horror');

insert into Filmy (Tytul,minimalny_wiek,Czas_trwania,kategoria_id) values ('Fajny film','18',120,1);

SELECT * FROM klient_PokazSeanse;
GO

BEGIN DISTRIBUTED TRANSACTION

	INSERT INTO Uzytkownicy
	 (imie, nazwisko, data_urodzenia, email, rola)
	VALUES
	 (N'Jan', N'Kowalski', '2000-05-22', N'jan.k@example.com', N'premium');


	EXEC klient_ZarezerwujSeans
	@UserId = 1,
	@Email = N'jan.k@example.com',
	@TytulFilmu = N'The Conjuring',
	@DataSeansu = '2026-01-02 10:00',
	@PreferencjaRzad = 3,
	@IloscMiejsc = 10;

	SELECT * FROM klient_PokazRezerwacje;


	EXEC klient_AnulujRezerwacje
	@Email = N'jan.k@example.com',
	@TytulFilmu = N'The Conjuring',
	@DataSeansu = '2026-01-02 10:00';

	SELECT * FROM klient_PokazRezerwacje;

	EXEC Admin_UsunUzytkownika @Email = N'jan.k@example.com';

COMMIT TRANSACTION;

SELECT *
FROM Admin_PopularnoscFilmow
WHERE tytul = N'The Conjuring';
GO

WITH ostatni_tydzien AS (
  SELECT MAX(PoczatekTygodnia) AS tydzien
  FROM Admin_PopularnoscFilmow
)
SELECT
 tytul,
 ProcZapelnienia
FROM Admin_PopularnoscFilmow v
 JOIN ostatni_tydzien o
   ON v.PoczatekTygodnia = o.tydzien
ORDER BY ProcZapelnienia DESC;
GO

go
EXEC Admin_Statystyki_do_pliku 
@Miesiac = 12, 
@Rok = 2025;


EXEC Admin_AktualizujStatystykiSprzedazy @Tytul = N'The Conjuring';


select * from statystyki_sprzedazy;



USE KinoDB;
GO

EXEC dbo.Admin_DodajFilmRozproszony
    @Tytul = N'Incepcja',
    @MinimalnyWiek = 14,
    @CzasTrwania = 148,
    @NazwaKategorii = N'Sci-Fi';
GO
