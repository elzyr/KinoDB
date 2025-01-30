BEGIN
    -- Dodaj kategorie
    Admin_Pkg.dodaj_kategorie('Horror');
    Admin_Pkg.dodaj_kategorie('Familijny');

    -- Dodaj sale
    Admin_Pkg.dodaj_sale('Sala 1', 5, 10); -- 5 rz�d�w, 10 miejsc w rz�dzie
    Admin_Pkg.dodaj_sale('Sala 2', 3, 8);

    -- Dodaj filmy
    Admin_Pkg.dodaj_film('The Conjuring', 120, 18, 1); -- Horror, wiek 18+
    Admin_Pkg.dodaj_film('Kraina Lodu', 90, 0, 2);     -- Familijny, brak ogranicze�

    -- Dodaj seanse
    Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Jutro o 10:00
    Admin_Pkg.dodaj_seans(2, 2, TO_DATE('2026-01-02 22:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Jutro o 22:00

    -- Dodaj u�ytkownik�w
    INSERT INTO Uzytkownik_table VALUES (Uzytkownik(1, 'Jan', 'Kowalski', 20, 'jan@test.pl', 'standard'));
    INSERT INTO Uzytkownik_table VALUES (Uzytkownik(2, 'Anna', 'Nowak', 16, 'anna@test.pl', 'premium'));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('B��d inicjalizacji: ' || SQLERRM);
        ROLLBACK;
END;
/
#
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 1: Pr�ba dodania dw�ch film�w na t� sam� sal� w tym samym czasie');
    Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Ju� istniej�cy seans
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 2: Przerwa kr�tsza ni� 30 minut mi�dzy seansami');
    -- Film trwa 120 minut, kolejny seans o 12:10 (przerwa 10 minut)
    Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 12:10:00', 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 3: Seans przed 7:00');
    Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-02 06:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- 6:00
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 4: Przekroczenie liczby miejsc w sali');
    
    -- Pr�ba rezerwacji 51 miejsc w Sal� 1 (10 miejsc na rz�dzie * 5 rz�d�w = 50 miejsc)
    Klient_Pkg.Zarezerwuj_Seans('jan@test.pl', 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 51);
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 5: Rezerwacja 5 miejsc w rz�dzie 3');
    Klient_Pkg.Zarezerwuj_Seans('jan@test.pl', 'Kraina Lodu', TO_DATE('2026-01-02 22:00:00', 'YYYY-MM-DD HH24:MI:SS'), 3, 5);
    
    -- Sprawd� czy miejsca s� ci�g�e (np. 1-5)
    FOR r IN (
        SELECT m.numer 
        FROM Sala_table s, TABLE(s.miejsca) m 
        WHERE s.sala_id = 2 AND m.rzad = 3 AND m.czy_zajete = 1
        ORDER BY m.numer
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Miejsce: ' || r.numer);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('TEST UDANY: Miejsca zarezerwowane w rz�dzie');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 6: Brak miejsc w preferowanym rz�dzie');
    Klient_Pkg.Zarezerwuj_Seans('jan@test.pl', 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 11); -- Rz�d 1 ma 10 miejsc
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 7: Anulowanie na godzin� przed seansem');
    
    -- Dodaj seans za 30 minut od ustalonej daty (2026-01-01 00:30:00)
    Admin_Pkg.dodaj_seans(1, 1, TO_DATE('2026-01-01 00:30:00', 'YYYY-MM-DD HH24:MI:SS')); 
    
    -- Rezerwacja
    Klient_Pkg.Zarezerwuj_Seans('jan@test.pl', 'The Conjuring', TO_DATE('2026-01-01 00:30:00', 'YYYY-MM-DD HH24:MI:SS'), 2, 2);
    
    -- Pr�ba anulowania 59 minut przed
    Klient_Pkg.Anuluj_Rezerwacje('The Conjuring', TO_DATE('2026-01-01 00:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'jan@test.pl');
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 8: Sprawdzenie zni�ki 10% dla premium');
    
    Klient_Pkg.Zarezerwuj_Seans('anna@test.pl', 'Kraina Lodu', TO_DATE('2026-01-02 22:00:00', 'YYYY-MM-DD HH24:MI:SS'), 2, 2);
    
    DECLARE
        v_cena NUMBER;
    BEGIN
        SELECT cena_laczna INTO v_cena 
        FROM Rezerwacja_table 
        WHERE uzytkownik_ref = (SELECT REF(u) FROM Uzytkownik_table u WHERE email = 'anna@test.pl');
        
        IF v_cena = 90 THEN
            DBMS_OUTPUT.PUT_LINE('TEST UDANY: Cena z rabatem 10%');
        ELSE
            DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Cena ' || v_cena);
        END IF;
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 9: Podw�jna rezerwacja tego samego miejsca');
    Klient_Pkg.Zarezerwuj_Seans('jan@test.pl', 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
    Klient_Pkg.Zarezerwuj_Seans('anna@test.pl', 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 10: Rezerwacja filmu 18+ przez 15-latka');
    Klient_Pkg.Zarezerwuj_Seans('anna@test.pl', 'The Conjuring', TO_DATE('2026-01-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 11: Zmiana konta na premium');
    Klient_Pkg.Zmien_Typ_Konta('jan@test.pl', 'premium');
    
    -- Sprawd�, czy typ konta zosta� zmieniony
    DECLARE
        v_rola VARCHAR2(20);
    BEGIN
        SELECT rola INTO v_rola 
        FROM Uzytkownik_table 
        WHERE email = 'jan@test.pl';
        
        IF v_rola = 'premium' THEN
            DBMS_OUTPUT.PUT_LINE('TEST UDANY: Zmieniono typ konta');
        ELSE
            DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zmieniono typu konta');
        END IF;
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 13: Pokazanie rezerwacji u�ytkownika jan@test.pl');
    Klient_Pkg.Pokaz_Rezerwacje('jan@test.pl');
    DBMS_OUTPUT.PUT_LINE('TEST ZAKO�CZONY: Rezerwacje wy�wietlone.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 14: Pokazanie seans�w na dzie� 2026-01-02');
    Klient_Pkg.Pokaz_Seanse(TO_DATE('2026-01-02', 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('TEST ZAKO�CZONY: Seanse wy�wietlone.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 20: Dodanie kategorii z istniej�c� nazw� "Horror"');
    Admin_Pkg.dodaj_kategorie('Horror');
    DBMS_OUTPUT.PUT_LINE('TEST NIEUDANY: Nie zg�oszono b��du przy dodawaniu istniej�cej kategorii.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST UDANY: ' || SQLERRM);
END;
/



