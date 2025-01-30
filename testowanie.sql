BEGIN
    -- Dodawanie kategorii
    admin_seanse.add_kategoria('Komedia');
    admin_seanse.add_kategoria('Horror');
    admin_seanse.add_kategoria('Dramat');
    admin_seanse.add_kategoria('Sci-Fi');
    admin_seanse.add_kategoria('Fantasy');

    DBMS_OUTPUT.PUT_LINE('Kategorie zosta³y dodane.');
END;
/

BEGIN
    -- Dodawanie filmów
    admin_seanse.add_film(
        p_tytul => 'Wielka Przygoda',
        p_czas_trwania => 120,
        p_minimalny_wiek => 7,
        p_kategoria_id => 1 -- ID kategorii 'Komedia'
    );

    admin_seanse.add_film(
        p_tytul => 'Strach w Nocy',
        p_czas_trwania => 90,
        p_minimalny_wiek => 16,
        p_kategoria_id => 2 -- ID kategorii 'Horror'
    );

    admin_seanse.add_film(
        p_tytul => 'Historia Mi³oœci',
        p_czas_trwania => 130,
        p_minimalny_wiek => 12,
        p_kategoria_id => 3 -- ID kategorii 'Dramat'
    );

    admin_seanse.add_film(
        p_tytul => 'Kosmiczna Odyseja',
        p_czas_trwania => 150,
        p_minimalny_wiek => 10,
        p_kategoria_id => 4 -- ID kategorii 'Sci-Fi'
    );

    admin_seanse.add_film(
        p_tytul => 'Magiczna Kraina',
        p_czas_trwania => 110,
        p_minimalny_wiek => 6,
        p_kategoria_id => 5 -- ID kategorii 'Fantasy'
    );

    DBMS_OUTPUT.PUT_LINE('Filmy zosta³y dodane.');
END;
/


-- Poprawne przypadki
BEGIN
    -- Dodaj salê
    admin_seanse.add_sala(
        p_nazwa => 'Sala 1',
        p_ilosc_rzedow => 5,
        p_miejsca_w_rzedzie => 10
    );

    -- Dodaj film
    admin_seanse.add_film(
        p_tytul => 'Film A',
        p_czas_trwania => 120,
        p_minimalny_wiek => 12,
        p_kategoria_id => 1 -- Zak³adaj¹c, ¿e istnieje kategoria o ID 1
    );

    -- Dodaj seans
    admin_seanse.add_seans(
        p_film_id => 1, -- Zak³adaj¹c, ¿e ID filmu to 1
        p_sala_id => 1, -- Zak³adaj¹c, ¿e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-30 12:00', 'YYYY-MM-DD HH24:MI')
    );

    DBMS_OUTPUT.PUT_LINE('Poprawne seanse dodane.');
END;
/

BEGIN
    -- Dodaj salê
    admin_seanse.add_sala(
        p_nazwa => 'Sala 2',
        p_ilosc_rzedow => 5,
        p_miejsca_w_rzedzie => 10
    );

    -- Dodaj film
    admin_seanse.add_film(
        p_tytul => 'Film A',
        p_czas_trwania => 120,
        p_minimalny_wiek => 15,
        p_kategoria_id => 1 -- Zak³adaj¹c, ¿e istnieje kategoria o ID 1
    );

    -- Dodaj seans
    admin_seanse.add_seans(
        p_film_id => 2, -- Zak³adaj¹c, ¿e ID filmu to 1
        p_sala_id => 2, -- Zak³adaj¹c, ¿e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-30 19:00', 'YYYY-MM-DD HH24:MI')
    );
    
    DBMS_OUTPUT.PUT_LINE('Poprawne seanse dodane.');
END;
/


BEGIN
    -- Dodaj salê
    admin_seanse.add_sala(
        p_nazwa => 'Sala 3',
        p_ilosc_rzedow => 5,
        p_miejsca_w_rzedzie => 10
    );

    -- Dodaj film
    admin_seanse.add_film(
        p_tytul => 'Film A',
        p_czas_trwania => 120,
        p_minimalny_wiek => 15,
        p_kategoria_id => 1 -- Zak³adaj¹c, ¿e istnieje kategoria o ID 1
    );

    -- Dodaj seans
    admin_seanse.add_seans(
        p_film_id => 3, -- Zak³adaj¹c, ¿e ID filmu to 1
        p_sala_id => 3, -- Zak³adaj¹c, ¿e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-30 18:00', 'YYYY-MM-DD HH24:MI')
    );
    
    DBMS_OUTPUT.PUT_LINE('Poprawne seanse dodane.');
END;
/









-- dodawnie kleinta

BEGIN
    INSERT INTO Uzytkownik_table VALUES (
        Uzytkownik(NULL, 'Jan', 'Kowalski', 30, 'jan.kowalski@example.com', 'standard')
    );
    
    INSERT INTO Uzytkownik_table VALUES (
        Uzytkownik(NULL, 'Anna', 'Nowak', 25, 'anna.nowak@example.com', 'premium')
    );
    
    COMMIT;
END;
/

BEGIN
    INSERT INTO Uzytkownik_table VALUES (
        Uzytkownik(
            NULL, -- user_id zostanie automatycznie ustawiony przez wyzwalacz
            'Piotr',
            'Zieliñski',
            40,
            'piotr.zielinski@example.com',
            'standard'
        )
    );
    
    COMMIT;
END;
/
select * from Uzytkownik_table


-- rezerwacje


BEGIN
    Rezerwacja_Pkg.PokazSeanse(
        p_data_seansu => TO_DATE('2025-01-30', 'YYYY-MM-DD')
    );
END;
/





SET SERVEROUTPUT ON;

-- TEST 1: Rezerwacja seansu
DECLARE
    v_test_email VARCHAR2(100) := 'piotr.zielinski@example.com';
    v_test_tytul VARCHAR2(200) := 'Strach w Nocy';
    v_test_rzad NUMBER := 3;
    v_test_ilosc_miejsc NUMBER := 5;
    v_test_data_seansu DATE := TO_DATE('2025-01-30 19:00', 'YYYY-MM-DD HH24:MI');
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 1: Rezerwacja seansu ---');
    Rezerwacja_Pkg.ZarezerwujSeans(
        p_email => v_test_email,
        p_tytul => v_test_tytul,
        p_data_seansu => v_test_data_seansu,
        p_rzad => v_test_rzad,
        p_ilosc_miejsc => v_test_ilosc_miejsc
    );
END;
/

    
-- TEST 2: Wyœwietlenie rezerwacji u¿ytkownika
DECLARE
    v_test_email VARCHAR2(100) := 'piotr.zielinski@example.com';
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 2: Wyœwietlenie rezerwacji u¿ytkownika ---');
    Rezerwacja_Pkg.PokazRezerwacje(
        p_email => v_test_email
    );
END;
/

-- TEST 3: Wyœwietlenie seansów na podan¹ datê
DECLARE
    v_test_data_seansu DATE := TO_DATE('2025-01-30', 'YYYY-MM-DD');
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 3: Wyœwietlenie seansów na podan¹ datê ---');
    Rezerwacja_Pkg.PokazSeanse(
        p_data_seansu => v_test_data_seansu
    );
END;
/

-- TEST 4: Anulowanie rezerwacji
DECLARE
    v_test_email VARCHAR2(100) := 'piotr.zielinski@example.com';
    v_test_tytul VARCHAR2(200) := 'Strach w Nocy';
    v_test_data_seansu DATE := TO_DATE('2025-01-30 19:00', 'YYYY-MM-DD HH24:MI');
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 4: Anulowanie rezerwacji ---');
    Rezerwacja_Pkg.AnulujRezerwacje(
        p_tytul => v_test_tytul,
        p_data_seansu => v_test_data_seansu,
        p_email => v_test_email
    );
END;
/

-- TEST 5: Wyœwietlenie rezerwacji po anulowaniu
DECLARE
    v_test_email VARCHAR2(100) := 'piotr.zielinski@example.com';
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 5: Wyœwietlenie rezerwacji po anulowaniu ---');
    Rezerwacja_Pkg.PokazRezerwacje(
        p_email => v_test_email
    );
END;
/

-- TEST 6: Sprawdzenie dostêpnoœci miejsc po anulowaniu
DECLARE
    v_test_data_seansu DATE := TO_DATE('2025-01-30 19:00', 'YYYY-MM-DD HH24:MI');
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 6: Sprawdzenie dostêpnoœci miejsc po anulowaniu ---');
    Rezerwacja_Pkg.PokazSeanse(
        p_data_seansu => v_test_data_seansu
    );
END;
/

