BEGIN
    -- Dodawanie kategorii
    admin_seanse.add_kategoria('Komedia');
    admin_seanse.add_kategoria('Horror');
    admin_seanse.add_kategoria('Dramat');
    admin_seanse.add_kategoria('Sci-Fi');
    admin_seanse.add_kategoria('Fantasy');

    DBMS_OUTPUT.PUT_LINE('Kategorie zosta�y dodane.');
END;
/

BEGIN
    -- Dodawanie film�w
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
        p_tytul => 'Historia Mi�o�ci',
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

    DBMS_OUTPUT.PUT_LINE('Filmy zosta�y dodane.');
END;
/


-- Poprawne przypadki
BEGIN
    -- Dodaj sal�
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
        p_kategoria_id => 1 -- Zak�adaj�c, �e istnieje kategoria o ID 1
    );

    -- Dodaj seans
    admin_seanse.add_seans(
        p_film_id => 1, -- Zak�adaj�c, �e ID filmu to 1
        p_sala_id => 1, -- Zak�adaj�c, �e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-25 15:00', 'YYYY-MM-DD HH24:MI')
    );

    DBMS_OUTPUT.PUT_LINE('Poprawne seanse dodane.');
END;
/

-- Przypadki testuj�ce b��dy
BEGIN
    -- Przypadek: Seans zaczyna si� przed godzin� 07:00
    admin_seanse.add_seans(
        p_film_id => 1, -- Zak�adaj�c, �e ID filmu to 1
        p_sala_id => 1, -- Zak�adaj�c, �e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-25 06:00', 'YYYY-MM-DD HH24:MI')
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('B��d: ' || SQLERRM);
END;
/

BEGIN
    -- Przypadek: Seans koliduje z istniej�cym seansem
    admin_seanse.add_seans(
        p_film_id => 1, -- Zak�adaj�c, �e ID filmu to 1
        p_sala_id => 1, -- Zak�adaj�c, �e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-25 16:30', 'YYYY-MM-DD HH24:MI') -- Kolizja z poprzednim seansem
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('B��d: ' || SQLERRM);
END;
/

BEGIN
    -- Przypadek: Pr�ba dodania seansu do nieistniej�cej sali
    admin_seanse.add_seans(
        p_film_id => 1, -- Zak�adaj�c, �e ID filmu to 1
        p_sala_id => 999, -- Nieistniej�ce ID sali
        p_data_rozpoczecia => TO_DATE('2025-01-25 18:00', 'YYYY-MM-DD HH24:MI')
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('B��d: ' || SQLERRM);
END;
/

BEGIN
    -- Przypadek: Pr�ba dodania seansu z nieistniej�cym filmem
    admin_seanse.add_seans(
        p_film_id => 999, -- Nieistniej�ce ID filmu
        p_sala_id => 1, -- Zak�adaj�c, �e ID sali to 1
        p_data_rozpoczecia => TO_DATE('2025-01-25 20:00', 'YYYY-MM-DD HH24:MI')
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('B��d: ' || SQLERRM);
END;
/
