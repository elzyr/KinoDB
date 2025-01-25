-- -------------------------------
-- Sekcja: Tworzenie pakiet�w
-- -------------------------------

-- Pakiet do obs�ugi rezerwacji
CREATE OR REPLACE PACKAGE Rezerwacja_Pkg AS
    PROCEDURE SprawdzWiekUzytkownika (v_uzytkownik REF Uzytkownik, v_film REF Film);
    PROCEDURE SprawdzUzytkownika (p_email VARCHAR2, v_uzytkownik OUT REF Uzytkownik);
    PROCEDURE SprawdzFilm (p_film_tytul VARCHAR2, v_film OUT REF Film);
    FUNCTION SprawdzDostepneMiejsca (
        p_repertuar REF Repertuar,
        p_preferencja_rzad NUMBER DEFAULT NULL,
        p_ilosc NUMBER,
        v_miejsca OUT SYS_REFCURSOR
    ) RETURN BOOLEAN;
    PROCEDURE UtworzRezerwacje (
        p_email VARCHAR2,
        p_film_tytul VARCHAR2,
        p_ilosc NUMBER,
        p_preferencja_rzad NUMBER DEFAULT NULL
    );
END Rezerwacja_Pkg;
/


        
CREATE OR REPLACE PACKAGE BODY Rezerwacja_Pkg AS

    -- Procedura sprawdzaj�ca istnienie u�ytkownika
    PROCEDURE SprawdzUzytkownika (p_email VARCHAR2, v_uzytkownik OUT REF Uzytkownik) IS
    BEGIN
        SELECT REF(u)
        INTO v_uzytkownik
        FROM Uzytkownik_table u
        WHERE u.email = p_email;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'U�ytkownik o podanym e-mailu nie istnieje.');
    END SprawdzUzytkownika;

    -- Procedura sprawdzaj�ca istnienie filmu
    PROCEDURE SprawdzFilm (p_film_tytul VARCHAR2, v_film OUT REF Film) IS
    BEGIN
        SELECT REF(f)
        INTO v_film
        FROM Film_table f
        WHERE f.tytul = p_film_tytul;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Film o podanym tytule nie istnieje.');
    END SprawdzFilm;

    -- Procedura sprawdzaj�ca wiek u�ytkownika wzgl�dem wymaga� filmu
    PROCEDURE SprawdzWiekUzytkownika (
        v_uzytkownik REF Uzytkownik,
        v_film REF Film
    ) IS
        v_wiek NUMBER;
        v_minimalny_wiek NUMBER;
    BEGIN
        -- Pobierz wiek u�ytkownika
        SELECT u.wiek INTO v_wiek
        FROM Uzytkownik_table u
        WHERE REF(u) = v_uzytkownik;

        -- Pobierz minimalny wiek dla filmu
        SELECT f.minimalny_wiek INTO v_minimalny_wiek
        FROM Film_table f
        WHERE REF(f) = v_film;

        -- Sprawd�, czy u�ytkownik spe�nia minimalny wiek
        IF v_wiek < v_minimalny_wiek THEN
            RAISE_APPLICATION_ERROR(-20007, 'U�ytkownik nie spe�nia wymaga� wiekowych dla wybranego filmu.');
        END IF;
    END SprawdzWiekUzytkownika;

    -- Funkcja sprawdzaj�ca dost�pno�� miejsc
    FUNCTION SprawdzDostepneMiejsca (
        p_repertuar REF Repertuar,
        p_preferencja_rzad NUMBER DEFAULT NULL,
        p_ilosc NUMBER,
        v_miejsca OUT SYS_REFCURSOR
    ) RETURN BOOLEAN IS
        v_sala_id NUMBER;
        v_prev_numer NUMBER := NULL;
        v_prev_rzad NUMBER := NULL;
        v_count_sequential NUMBER := 0;
        v_rzad NUMBER;
        v_numer NUMBER;
    BEGIN
        -- Pobierz sala_id z powi�zanego repertuaru
        SELECT r.sala_ref.sala_id
          INTO v_sala_id
          FROM Repertuar_table r
         WHERE REF(r) = p_repertuar;
    
        -- Otw�rz kursor z dost�pnymi miejscami
        OPEN v_miejsca FOR
            SELECT m.rzad, m.numer
            FROM TABLE(
                SELECT s.miejsca
                FROM Sala_table s
                WHERE s.sala_id = v_sala_id
            ) m
            WHERE m.czy_zajete = 0 -- Sprawdzamy tylko wolne miejsca
              AND (p_preferencja_rzad IS NULL OR m.rzad = p_preferencja_rzad) -- Uwzgl�dniamy preferencj� rz�du
            ORDER BY m.rzad, m.numer;
    
        -- Sprawd�, czy s� wystarczaj�ce miejsca obok siebie
        LOOP
            FETCH v_miejsca INTO v_rzad, v_numer;
            EXIT WHEN v_miejsca%NOTFOUND;
    
            -- Sprawd�, czy miejsca s� w tym samym rz�dzie
            IF v_prev_rzad IS NULL THEN
                v_prev_rzad := v_rzad; -- Ustaw pierwszy rz�d
            ELSIF v_prev_rzad != v_rzad THEN
                v_count_sequential := 1; -- Resetuj licznik, je�li zmieni� si� rz�d
                v_prev_rzad := v_rzad;
            END IF;
    
            -- Sprawd� ci�g�o�� miejsc
            IF v_prev_numer IS NULL THEN
                v_count_sequential := 1; -- Rozpocznij odliczanie
            ELSIF v_numer = v_prev_numer + 1 THEN
                v_count_sequential := v_count_sequential + 1; -- Zwi�ksz licznik ci�g�ych miejsc
            ELSE
                v_count_sequential := 1; -- Reset licznika, je�li brak ci�g�o�ci
            END IF;
    
            -- Je�li znaleziono wystarczaj�c� liczb� miejsc
            IF v_count_sequential = p_ilosc THEN
                RETURN TRUE;
            END IF;
    
            -- Zapisz poprzednie warto�ci
            v_prev_numer := v_numer;
        END LOOP;
    
        -- Je�li nie znaleziono wystarczaj�cych miejsc
        RETURN FALSE;
    END SprawdzDostepneMiejsca;


    -- Procedura tworz�ca rezerwacj�
    PROCEDURE UtworzRezerwacje (
    p_email VARCHAR2,
    p_film_tytul VARCHAR2,
    p_ilosc NUMBER,
    p_preferencja_rzad NUMBER DEFAULT NULL
) IS
    v_uzytkownik REF Uzytkownik;
    v_film REF Film;
    v_repertuar REF Repertuar;
    v_rezerwacja_id NUMBER;
    v_rezerwacja_ref REF Rezerwacja;
    v_cena NUMBER := 50;
    v_znizka NUMBER := 1;
    v_cena_laczna NUMBER;
BEGIN
    -- Sprawd� u�ytkownika
    SprawdzUzytkownika(p_email, v_uzytkownik);

    -- Sprawd� film
    SprawdzFilm(p_film_tytul, v_film);

    -- Pobierz zni�k� dla u�ytkownika
    SELECT CASE WHEN u.rola = 'premium' THEN 0.9 ELSE 1 END
    INTO v_znizka
    FROM Uzytkownik_table u 
    WHERE REF(u) = v_uzytkownik;

    -- Znajd� repertuar (tu powinien by� wywo�any odpowiedni blok logiczny)

    -- Oblicz cen� ca�kowit�
    v_cena_laczna := v_cena * p_ilosc * v_znizka;

    -- Utw�rz rezerwacj�
    SELECT NVL(MAX(rezerwacja_id), 0) + 1 INTO v_rezerwacja_id FROM Rezerwacja_table;

    INSERT INTO Rezerwacja_table
    VALUES (
        Rezerwacja(
            v_rezerwacja_id, 
            SYSDATE, 
            v_cena_laczna, -- Cena ca�kowita
            0, 
            v_repertuar, 
            v_uzytkownik, 
            Bilety_Typ()
        )
    );

    COMMIT;
END UtworzRezerwacje;


END Rezerwacja_Pkg;
/



CREATE OR REPLACE PACKAGE AnulujRezerwacje_Pkg AS
    PROCEDURE AnulujRezerwacje (p_rezerwacja_id NUMBER);
END AnulujRezerwacje_Pkg;
/

        
CREATE OR REPLACE PACKAGE BODY AnulujRezerwacje_Pkg AS
    PROCEDURE AnulujRezerwacje (p_rezerwacja_id NUMBER) IS
        v_bilety_cursor SYS_REFCURSOR; -- Kursor na bilety
        v_rzad NUMBER;
        v_numer NUMBER;
        v_sala_id NUMBER;
    BEGIN
        -- Aktualizuj rezerwacj� na anulowan�
        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = p_rezerwacja_id;

        -- Pobierz bilety powi�zane z rezerwacj�
        OPEN v_bilety_cursor FOR
            SELECT b.rzad, b.miejsce, r.sala_ref.sala_id
            FROM Bilet_table b
            JOIN Repertuar_table r ON REF(r) = b.seans_ref
            WHERE b.bilet_id IN (
                SELECT COLUMN_VALUE.bilet_id
                FROM TABLE(
                    SELECT r.bilety FROM Rezerwacja_table r WHERE r.rezerwacja_id = p_rezerwacja_id
                )
            );

        -- Zwolnij miejsca w sali
        LOOP
            FETCH v_bilety_cursor INTO v_rzad, v_numer, v_sala_id;
            EXIT WHEN v_bilety_cursor%NOTFOUND;

            UPDATE TABLE(
                SELECT s.miejsca
                FROM Sala_table s
                WHERE s.sala_id = v_sala_id
            )
            SET czy_zajete = 0
            WHERE rzad = v_rzad AND numer = v_numer;
        END LOOP;

        CLOSE v_bilety_cursor;
    END AnulujRezerwacje;
END AnulujRezerwacje_Pkg;
/


CREATE OR REPLACE PACKAGE Repertuar_Pkg AS
    PROCEDURE PokazSeanseNaDzien(p_data DATE);
    PROCEDURE DodajSeans(
        p_film_id NUMBER,
        p_sala_id NUMBER,
        p_data_rozpoczecia DATE
    );
END Repertuar_Pkg;
/


        
CREATE OR REPLACE PACKAGE BODY Repertuar_Pkg AS
    PROCEDURE PokazSeanseNaDzien(p_data DATE) IS
    BEGIN
        FOR r IN (
            SELECT r.repertuar_id, f.tytul, r.data_rozpoczecia, s.nazwa
            FROM Repertuar_table r
            JOIN Film_table f ON REF(f) = r.film_ref
            JOIN Sala_table s ON REF(s) = r.sala_ref
            WHERE TRUNC(r.data_rozpoczecia) = TRUNC(p_data)
            ORDER BY r.data_rozpoczecia
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Seans ID: ' || r.repertuar_id || 
                                 ', Film: ' || r.tytul || 
                                 ', Data: ' || TO_CHAR(r.data_rozpoczecia, 'YYYY-MM-DD HH24:MI') || 
                                 ', Sala: ' || r.nazwa);
        END LOOP;
    END PokazSeanseNaDzien;

    PROCEDURE DodajSeans(
        p_film_id NUMBER,
        p_sala_id NUMBER,
        p_data_rozpoczecia DATE
    ) IS
        v_film REF Film;
        v_sala REF Sala;
        v_new_repertuar_id NUMBER;
    BEGIN
        -- Sprawd�, czy film istnieje
        BEGIN
            SELECT REF(f) INTO v_film FROM Film_table f WHERE f.film_id = p_film_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Film o podanym ID nie istnieje.');
        END;

        -- Sprawd�, czy sala istnieje
        BEGIN
            SELECT REF(s) INTO v_sala FROM Sala_table s WHERE s.sala_id = p_sala_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20002, 'Sala o podanym ID nie istnieje.');
        END;

        -- Sprawd� konflikt czasowy w sali
        DECLARE
            v_conflict_count NUMBER;
        BEGIN
            SELECT COUNT(*)
              INTO v_conflict_count
              FROM Repertuar_table r
             WHERE r.sala_ref = v_sala
               AND ABS((r.data_rozpoczecia - p_data_rozpoczecia) * 24 * 60) < 120; -- Konflikt w czasie 2h

            IF v_conflict_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20003, 'W tej sali jest ju� seans o zbli�onej godzinie.');
            END IF;
        END;

        -- Pobierz nowe ID dla repertuaru
        SELECT NVL(MAX(repertuar_id), 0) + 1 INTO v_new_repertuar_id FROM Repertuar_table;

        -- Dodaj seans
        BEGIN
            INSERT INTO Repertuar_table
            VALUES (
                Repertuar(v_new_repertuar_id, v_film, v_sala, p_data_rozpoczecia)
            );

            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Seans zosta� pomy�lnie dodany: ID ' || v_new_repertuar_id);
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE_APPLICATION_ERROR(-20004, 'Nie uda�o si� doda� seansu. Przyczyna: ' || SQLERRM);
        END;
    END DodajSeans;
END Repertuar_Pkg;
/