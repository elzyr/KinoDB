BEGIN
 Admin_Pkg.dodaj_kategorie('Horror');
 Admin_Pkg.dodaj_kategorie('Familijny');

 Admin_Pkg.dodaj_sale('Sala 1', 5, 10);
 Admin_Pkg.dodaj_sale('Sala 2', 3, 8);

 Admin_Pkg.dodaj_film('The Conjuring', 120, 18, 1);
 Admin_Pkg.dodaj_film('Kraina Lodu', 90, 0, 2);

 Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'));
 Admin_Pkg.dodaj_seans(2, 2, TO_DATE('2026-01-02 22:00:00', 'YYYY-MM-DD HH24:MI:SS'));

-- INSERT INTO Uzytkownik_table VALUES (
--  Uzytkownik(NULL, 'Jan', 'Kowalski', TO_DATE('2005-01-31', 'YYYY-MM-DD'), 'jan@test.pl', 'standard')
-- );
--
-- INSERT INTO Uzytkownik_table VALUES (
--  Uzytkownik(NULL, 'Anna', 'Nowak', TO_DATE('2009-01-31', 'YYYY-MM-DD'), 'anna2@test.pl', 'premium')
-- );
--
-- INSERT INTO Uzytkownik_table VALUES (
--  Uzytkownik(NULL, 'Zbigniew', 'Szczupak', TO_DATE('2000-01-31', 'YYYY-MM-DD'), 'zbigniew@test.pl', 'premium')
-- );
END;
/

BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 1: Proba dodania dwoch filmow na te sama sale w tym samym czasie');
 Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'));
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 2: Przerwa krotsza niz 30 minut miedzy seansami');
 Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 12:10:00', 'YYYY-MM-DD HH24:MI:SS'));
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 3: Seans przed 7:00');
 Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 06:00:00', 'YYYY-MM-DD HH24:MI:SS'));
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 4: Seans po 22:00');
 Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 22:01:00', 'YYYY-MM-DD HH24:MI:SS'));
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 5: Przekroczenie liczby miejsc w sali');
 Klient_Pkg.Zarezerwuj_Seans(1, 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 2, 10);
 Klient_Pkg.Zarezerwuj_Seans(1, 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 2, 10);
 Klient_Pkg.Zarezerwuj_Seans(1, 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 3, 10);
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 6: Rezerwacja 5 miejsc w rzedzie 3');
 Klient_Pkg.Zarezerwuj_Seans(1, 'Kraina Lodu', TO_DATE('2026-01-02 22:00:00', 'YYYY-MM-DD HH24:MI:SS'), 3, 5);
 Klient_Pkg.Pokaz_Rezerwacje(1);
 DBMS_OUTPUT.PUT_LINE('TEST UDANY: Miejsca zarezerwowane w rzedzie');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 7: Anulowanie na godzinê przed seansem');
 DECLARE
  v_seans_time DATE;
 BEGIN
  v_seans_time := SYSDATE + 30/1440; -- 30 minut od teraz
  Admin_Pkg.dodaj_seans(1, 1, v_seans_time);
  Klient_Pkg.Zarezerwuj_Seans(1, 'The Conjuring', v_seans_time, 5, 2);
  Klient_Pkg.Anuluj_Rezerwacje( 1,'The Conjuring', v_seans_time);
  DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
 EXCEPTION
  WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
 END;
END;
/
        
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 8: Podwojna rezerwacja tego samego miejsca');
 Klient_Pkg.Zarezerwuj_Seans(1, 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
 Klient_Pkg.Zarezerwuj_Seans(1, 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 9: Rezerwacja filmu 18+ przez 15-latka');
 Klient_Pkg.Zarezerwuj_Seans(2, 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
 
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 10: Pokazanie rezerwacji uzytkownika jan@test.pl');
 Klient_Pkg.Pokaz_Rezerwacje(1);
 DBMS_OUTPUT.PUT_LINE('TEST ZAKONCZONY: Rezerwacje wyswietlone.');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 11: Pokazanie seansow na dzien 2026-01-02');
 Klient_Pkg.Pokaz_Seanse(TO_DATE('2026-01-02', 'YYYY-MM-DD'));
 DBMS_OUTPUT.PUT_LINE('TEST ZAKONCZONY: Seanse wyswietlone.');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 12: Dodanie kategorii z istniejaca nazwa "Horror"');
 Admin_Pkg.dodaj_kategorie('Horror');
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zgloszono bledu przy dodawaniu istniejacej kategorii.');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 13: Sprawdzenie popularnosci filmu "Kraina Lodu"');
 BEGIN
  Admin_Pkg.popularnosc_filmu('Kraina Lodu');
  DBMS_OUTPUT.PUT_LINE('TEST ZAKONCZONY: Popularnosc filmu "Kraina Lodu" zostala sprawdzona.');
 EXCEPTION
  WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: ' || SQLERRM);
 END;
END;
/
    
BEGIN
 DBMS_OUTPUT.PUT_LINE('Test 14: Próba dodania seansu dla wycofanego filmu');
 -- Wycofujemy film "The Conjuring"
 Admin_Pkg.wycofaj_film('The Conjuring');
 -- Próba dodania seansu dla wycofanego filmu
 Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-03 15:00:00', 'YYYY-MM-DD HH24:MI:SS'));
 DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Seans dla wycofanego filmu zostal dodany.');
EXCEPTION
 WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/

SELECT r.repertuar_id,
       DEREF(r.film_ref).film_id   AS film_id,
       DEREF(r.film_ref).tytul     AS tytul,
       TO_CHAR(r.data_rozpoczecia,'YYYY-MM-DD HH24:MI:SS') AS start_time
FROM   Repertuar_table r;

BEGIN
klient_pkg.pokaz_rezerwacje(1);
END;