CREATE OR REPLACE PACKAGE Klient_Pkg AS
    -- Wyœwietlanie seansów z danego dnia
    PROCEDURE PokazSeanseNaDzien(p_data DATE);

    -- Rezerwowanie miejsc
    PROCEDURE ZarezerwujMiejsca(
        p_email VARCHAR2,
        p_film_tytul VARCHAR2,
        p_ilosc NUMBER,
        p_data DATE,
        p_preferencja_rzad NUMBER DEFAULT NULL
    );
    
    -- pokazywanie rezerwacji
        PROCEDURE PokazRezerwacjeUzytkownika(p_email VARCHAR2);

    -- Anulowanie rezerwacji
    PROCEDURE AnulujRezerwacje(p_email VARCHAR2, p_film_tytul VARCHAR2, p_data DATE);

    -- Obs³uga subskrypcji (zmiana roli u¿ytkownika)
    PROCEDURE UstawRoleUzytkownika(
        p_email VARCHAR2,
        p_nowa_rola VARCHAR2
    );
END Klient_Pkg;
/

CREATE OR REPLACE PACKAGE BODY Klient_Pkg AS

    -- Wyœwietlanie seansów z danego dnia
    PROCEDURE PokazSeanseNaDzien(p_data DATE) IS
        v_count NUMBER := 0; -- Licznik seansów
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
            v_count := v_count + 1; -- Zwiêkszenie licznika seansów
        END LOOP;

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Brak seansów na dzieñ ' || TO_CHAR(p_data, 'YYYY-MM-DD') || '.');
        END IF;
    END PokazSeanseNaDzien;

     -- Rezerwowanie miejsc
    PROCEDURE ZarezerwujMiejsca(
        p_email VARCHAR2,
        p_film_tytul VARCHAR2,
        p_ilosc NUMBER,
        p_data DATE,
        p_preferencja_rzad NUMBER DEFAULT NULL
    ) IS
        v_uzytkownik REF Uzytkownik;
        v_film REF Film;
        v_repertuar REF Repertuar;
        v_rezerwacja_id NUMBER;
        v_cena NUMBER := 50;
        v_znizka NUMBER := 1;
        v_cena_laczna NUMBER;
        v_dostepne_miejsca NUMBER;
        v_najblizszy_repertuar REF Repertuar;
        v_najblizsza_data DATE;
        v_dostepne_miejsca_najblizszy NUMBER;
        v_wybrane_miejsca Miejsca_Typ;
    BEGIN
        -- SprawdŸ u¿ytkownika
        DBMS_OUTPUT.PUT_LINE('Sprawdzenie u¿ytkownika: ' || p_email);
        SELECT REF(u) INTO v_uzytkownik FROM Uzytkownik_table u WHERE u.email = p_email;

        -- SprawdŸ film
        DBMS_OUTPUT.PUT_LINE('Sprawdzenie filmu: ' || p_film_tytul);
        SELECT REF(f) INTO v_film FROM Film_table f WHERE f.tytul = p_film_tytul;

        -- Pobierz repertuar na dan¹ datê i godzinê
        DBMS_OUTPUT.PUT_LINE('Sprawdzenie repertuaru dla filmu: ' || p_film_tytul || ' na datê: ' || TO_CHAR(p_data, 'YYYY-MM-DD HH24:MI'));
        BEGIN
            SELECT REF(r)
            INTO v_repertuar
            FROM Repertuar_table r
            WHERE r.film_ref = v_film
              AND r.data_rozpoczecia = p_data;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Brak dostêpnych seansów dla filmu ' || p_film_tytul || ' na datê: ' || TO_CHAR(p_data, 'YYYY-MM-DD HH24:MI'));

                -- Pobierz najbli¿szy seans dla tego filmu
                SELECT MIN(r.data_rozpoczecia)
                INTO v_najblizsza_data
                FROM Repertuar_table r
                WHERE r.film_ref = v_film
                  AND r.data_rozpoczecia > p_data;

                IF v_najblizsza_data IS NOT NULL THEN
                    SELECT REF(r)
                    INTO v_najblizszy_repertuar
                    FROM Repertuar_table r
                    WHERE r.film_ref = v_film
                      AND r.data_rozpoczecia = v_najblizsza_data;

                    -- SprawdŸ dostêpnoœæ miejsc w najbli¿szym seansie
                    SELECT COUNT(*) INTO v_dostepne_miejsca_najblizszy
                    FROM TABLE(
                        SELECT s.miejsca 
                        FROM Sala_table s
                        WHERE REF(s) = (SELECT r.sala_ref FROM Repertuar_table r WHERE REF(r) = v_najblizszy_repertuar)
                    )
                    WHERE czy_zajete = 0;

                    DBMS_OUTPUT.PUT_LINE('Najbli¿szy dostêpny seans dla filmu ' || p_film_tytul || ' jest na datê: ' || TO_CHAR(v_najblizsza_data, 'YYYY-MM-DD HH24:MI'));
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Nie ma ¿adnych dostêpnych seansów dla filmu ' || p_film_tytul);
                END IF;

                RETURN;
        END;

        -- SprawdŸ dostêpnoœæ miejsc
        DBMS_OUTPUT.PUT_LINE('Sprawdzanie dostêpnoœci miejsc w sali na dany seans');
        SELECT COUNT(*) INTO v_dostepne_miejsca
        FROM TABLE(
            SELECT s.miejsca 
            FROM Sala_table s
            WHERE REF(s) = (SELECT r.sala_ref FROM Repertuar_table r WHERE REF(r) = v_repertuar)
        )
        WHERE czy_zajete = 0;

        IF p_ilosc > v_dostepne_miejsca THEN
            DBMS_OUTPUT.PUT_LINE('Brak wystarczaj¹cej liczby wolnych miejsc na dany seans. Dostêpne miejsca: ' || v_dostepne_miejsca);

            -- Pobierz najbli¿szy seans dla tego filmu
            SELECT MIN(r.data_rozpoczecia)
            INTO v_najblizsza_data
            FROM Repertuar_table r
            WHERE r.film_ref = v_film
              AND r.data_rozpoczecia > p_data;

            IF v_najblizsza_data IS NOT NULL THEN
                SELECT REF(r)
                INTO v_najblizszy_repertuar
                FROM Repertuar_table r
                WHERE r.film_ref = v_film
                  AND r.data_rozpoczecia = v_najblizsza_data;

                -- SprawdŸ dostêpnoœæ miejsc w najbli¿szym seansie
                SELECT COUNT(*) INTO v_dostepne_miejsca_najblizszy
                FROM TABLE(
                    SELECT s.miejsca 
                    FROM Sala_table s
                    WHERE REF(s) = (SELECT r.sala_ref FROM Repertuar_table r WHERE REF(r) = v_najblizszy_repertuar)
                )
                WHERE czy_zajete = 0;

                DBMS_OUTPUT.PUT_LINE('Najbli¿szy dostêpny seans dla filmu ' || p_film_tytul || ' jest na datê: ' || TO_CHAR(v_najblizsza_data, 'YYYY-MM-DD HH24:MI'));
            ELSE
                DBMS_OUTPUT.PUT_LINE('Nie ma ¿adnych dostêpnych seansów dla filmu ' || p_film_tytul);
            END IF;

            RETURN;
        END IF;

        -- Wybierz miejsca do rezerwacji
        SELECT CAST(COLLECT(Miejsce(m.miejsce_id, m.rzad, m.numer, 1)) AS Miejsca_Typ) INTO v_wybrane_miejsca
        FROM TABLE(
            SELECT s.miejsca 
            FROM Sala_table s
            WHERE REF(s) = (SELECT r.sala_ref FROM Repertuar_table r WHERE REF(r) = v_repertuar)
        ) m
        WHERE m.czy_zajete = 0
        FETCH FIRST p_ilosc ROWS ONLY;

        -- Aktualizuj status miejsc na zajête
        FOR i IN 1..v_wybrane_miejsca.COUNT LOOP
            UPDATE TABLE(
                SELECT s.miejsca 
                FROM Sala_table s 
                WHERE REF(s) = (SELECT r.sala_ref FROM Repertuar_table r WHERE REF(r) = v_repertuar)
            ) m
            SET m.czy_zajete = 1
            WHERE m.miejsce_id = v_wybrane_miejsca(i).miejsce_id;
        END LOOP;

        -- Oblicz cenê z uwzglêdnieniem zni¿ki
        DBMS_OUTPUT.PUT_LINE('Obliczanie ceny z uwzglêdnieniem zni¿ki dla u¿ytkownika: ' || p_email);
        SELECT CASE WHEN u.rola = 'premium' THEN 0.9 ELSE 1 END
        INTO v_znizka
        FROM Uzytkownik_table u
        WHERE REF(u) = v_uzytkownik;

        v_cena_laczna := v_cena * p_ilosc * v_znizka;

        -- Utwórz rezerwacjê
        DBMS_OUTPUT.PUT_LINE('Tworzenie rezerwacji dla u¿ytkownika: ' || p_email);
        SELECT NVL(MAX(rezerwacja_id), 0) + 1 INTO v_rezerwacja_id FROM Rezerwacja_table;

        INSERT INTO Rezerwacja_table
        VALUES (
            Rezerwacja(
                v_rezerwacja_id, 
                SYSDATE, 
                v_cena_laczna, 
                0, 
                v_repertuar, 
                v_uzytkownik, 
                Bilety_Typ()
            )
        );

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Rezerwacja zosta³a pomyœlnie utworzona: ID ' || v_rezerwacja_id);
    END ZarezerwujMiejsca;

    -- Anulowanie rezerwacji
    
    PROCEDURE AnulujRezerwacje(p_email VARCHAR2, p_film_tytul VARCHAR2, p_data DATE) IS
        v_uzytkownik REF Uzytkownik;
        v_repertuar REF Repertuar;
        v_bilety_cursor SYS_REFCURSOR;
        v_rzad NUMBER;
        v_numer NUMBER;
        v_sala_id NUMBER;
    BEGIN
        -- SprawdŸ u¿ytkownika
        SELECT REF(u) INTO v_uzytkownik FROM Uzytkownik_table u WHERE u.email = p_email;

        -- SprawdŸ repertuar
        SELECT REF(r)
        INTO v_repertuar
        FROM Repertuar_table r
        JOIN Film_table f ON r.film_ref = REF(f)
        WHERE f.tytul = p_film_tytul AND TRUNC(r.data_rozpoczecia) = TRUNC(p_data);

        -- ZnajdŸ wszystkie rezerwacje u¿ytkownika na dany seans
        FOR r IN (
            SELECT r.rezerwacja_id
            FROM Rezerwacja_table r
            WHERE r.uzytkownik_ref = v_uzytkownik
              AND r.repertuar_ref = v_repertuar
        ) LOOP
            -- Aktualizuj rezerwacjê na anulowan¹
            UPDATE Rezerwacja_table
            SET czy_anulowane = 1
            WHERE rezerwacja_id = r.rezerwacja_id;

            -- Pobierz bilety powi¹zane z rezerwacj¹
            OPEN v_bilety_cursor FOR
                SELECT b.rzad, b.miejsce, rp.sala_ref.sala_id
                FROM Bilet_table b
                JOIN Rezerwacja_table r ON b.bilet_id MEMBER OF r.bilety
                JOIN Repertuar_table rp ON r.repertuar_ref = REF(rp)
                WHERE rp.repertuar_id = r.rezerwacja_id;

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
        END LOOP;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Rezerwacje filmu "' || p_film_tytul || '" z dnia ' || TO_CHAR(p_data, 'YYYY-MM-DD') || ' zosta³y anulowane.');
    END AnulujRezerwacje;

    -- Obs³uga subskrypcji (zmiana roli u¿ytkownika)
    PROCEDURE UstawRoleUzytkownika(
        p_email VARCHAR2,
        p_nowa_rola VARCHAR2
    ) IS
    BEGIN
        IF p_nowa_rola NOT IN ('premium', 'standard') THEN
            RAISE_APPLICATION_ERROR(-20001, 'Nieprawid³owa rola: ' || p_nowa_rola || '. Dozwolone wartoœci to ''premium'' lub ''standard''.');
        END IF;

        UPDATE Uzytkownik_table
        SET rola = p_nowa_rola
        WHERE email = p_email;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Rola u¿ytkownika ' || p_email || ' zosta³a zaktualizowana na: ' || p_nowa_rola);
    END UstawRoleUzytkownika;

    PROCEDURE PokazRezerwacjeUzytkownika(p_email VARCHAR2) IS
        v_uzytkownik REF Uzytkownik;
    BEGIN
        -- SprawdŸ u¿ytkownika
        DBMS_OUTPUT.PUT_LINE('Sprawdzenie u¿ytkownika: ' || p_email);
        SELECT REF(u) INTO v_uzytkownik FROM Uzytkownik_table u WHERE u.email = p_email;

        -- Pobierz rezerwacje u¿ytkownika
        FOR r IN (
            SELECT r.rezerwacja_id, r.data_rezerwacji, r.cena_laczna, f.tytul, rp.data_rozpoczecia, s.nazwa
            FROM Rezerwacja_table r
            JOIN Repertuar_table rp ON r.repertuar_ref = REF(rp)
            JOIN Film_table f ON rp.film_ref = REF(f)
            JOIN Sala_table s ON rp.sala_ref = REF(s)
            WHERE r.uzytkownik_ref = v_uzytkownik
            AND r.czy_anulowane = 0
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Rezerwacja ID: ' || r.rezerwacja_id || 
                                 ', Data rezerwacji: ' || TO_CHAR(r.data_rezerwacji, 'YYYY-MM-DD HH24:MI') || 
                                 ', Cena: ' || r.cena_laczna || ' PLN' || 
                                 ', Film: ' || r.tytul || 
                                 ', Data seansu: ' || TO_CHAR(r.data_rozpoczecia, 'YYYY-MM-DD HH24:MI') || 
                                 ', Sala: ' || r.nazwa);
        END LOOP;
    END PokazRezerwacjeUzytkownika;
END Klient_Pkg;
/

