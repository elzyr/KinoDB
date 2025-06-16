USE KinoDB;
GO

insert into Kategorie (nazwa) values ('Horror');

insert into Filmy (Tytul,minimalny_wiek,Czas_trwania,kategoria_id) values ('Fajny film','18',120,1);

INSERT INTO Uzytkownicy
 (imie, nazwisko, data_urodzenia, email, rola)
VALUES
 (N'Jan', N'Kowalski', '2000-05-22', N'jan.k@example.com', N'premium');
GO

SELECT * FROM klient_PokazSeanse;
GO

EXEC klient_ZarezerwujSeans
 @UserId          = 1,
 @TytulFilmu      = N'The Conjuring',
 @DataSeansu      = '2026-01-02 10:00',
 @PreferencjaRzad = 3,
 @IloscMiejsc     = 10;
GO

SELECT * FROM klient_PokazRezerwacje;
GO

EXEC klient_AnulujRezerwacje
 @UserId     = 1,
 @TytulFilmu = N'The Conjuring',
 @DataSeansu = '2026-01-02 10:00';
GO

SELECT * FROM klient_PokazRezerwacje;
GO

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