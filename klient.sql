-- Zintegrowany pakiet do obs³ugi klienta
CREATE OR REPLACE PACKAGE Klient_Pkg AS
    -- Wyœwietlanie seansów z danego dnia
    PROCEDURE PokazSeanseNaDzien(p_data DATE);

    -- Rezerwowanie miejsc
    PROCEDURE ZarezerwujMiejsca(
        p_email VARCHAR2,
        p_film_tytul VARCHAR2,
        p_ilosc NUMBER,
        p_preferencja_rzad NUMBER DEFAULT NULL
    );

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

    -- Rezerwowanie miejsc
    PROCEDURE ZarezerwujMiejsca(
        p_email VARCHAR2,
        p_film_tytul VARCHAR2,
        p_ilosc NUMBER,
        p_preferencja_rzad NUMBER DEFAULT NULL
    ) IS
        v_uzytkownik REF Uzytkownik;
        v_film REF Film;
        v_repertuar REF Repertuar;
        v_rezerwacja_id NUMBER;
        v_cena NUMBER := 50;
        v_znizka NUMBER := 1;
        v_cena_laczna NUMBER;
        v_miejsca SYS_REFCURSOR;
    BEGIN
        -- SprawdŸ u¿ytkownika
        SELECT REF(u) INTO v_uzytkownik FROM Uzytkownik_table u WHERE u.email = p_email;

        -- SprawdŸ film
        SELECT REF(f) INTO v_film FROM Film_table f WHERE f.tytul = p_film_tytul;

        -- Pobierz repertuar
        SELECT REF(r)
        INTO v_repertuar
        FROM Repertuar_table r
        WHERE r.film_ref = v_film
          AND r.data_rozpoczecia > SYSDATE
        FETCH FIRST 1 ROWS ONLY;

        -- Oblicz cenê z uwzglêdnieniem zni¿ki
        SELECT CASE WHEN u.rola = 'premium' THEN 0.9 ELSE 1 END
        INTO v_znizka
        FROM Uzytkownik_table u
        WHERE REF(u) = v_uzytkownik;

        v_cena_laczna := v_cena * p_ilosc * v_znizka;

        -- Utwórz rezerwacjê
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
        v_rezerwacja_id NUMBER;
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

        -- ZnajdŸ rezerwacjê
        SELECT r.rezerwacja_id
        INTO v_rezerwacja_id
        FROM Rezerwacja_table r
        WHERE r.uzytkownik_ref = v_uzytkownik
          AND r.repertuar_ref = v_repertuar;

        -- Aktualizuj rezerwacjê na anulowan¹
        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = v_rezerwacja_id;

        -- Pobierz bilety powi¹zane z rezerwacj¹
-- Pobierz bilety powi¹zane z rezerwacj¹
OPEN v_bilety_cursor FOR
    SELECT b.rzad, b.miejsce, rp.sala_ref.sala_id
    FROM Bilet_table b
    JOIN Rezerwacja_table r ON b.bilet_id MEMBER OF r.bilety
    JOIN Repertuar_table rp ON r.repertuar_ref = REF(rp)
    WHERE rp.repertuar_id = v_rezerwacja_id;


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
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Rezerwacja filmu "' || p_film_tytul || '" z dnia ' || TO_CHAR(p_data, 'YYYY-MM-DD') || ' zosta³a anulowana.');
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
END Klient_Pkg;
