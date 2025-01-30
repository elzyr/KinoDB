SET SERVEROUTPUT ON;
CREATE OR REPLACE PACKAGE Rezerwacja_Pkg AS
PROCEDURE ZarezerwujSeans(
    p_email VARCHAR2,
    p_tytul VARCHAR2,
    p_data_seansu DATE,
    p_rzad NUMBER,
    p_ilosc_miejsc NUMBER
);
  
    PROCEDURE AnulujRezerwacje(
        p_tytul VARCHAR2,
        p_data_seansu DATE,
        p_email VARCHAR2
    );
    
    PROCEDURE PokazRezerwacje(
        p_email VARCHAR2
    );
    
    PROCEDURE PokazSeanse(
        p_data_seansu DATE
    );
END Rezerwacja_Pkg;
/




CREATE OR REPLACE PACKAGE BODY Rezerwacja_Pkg AS
PROCEDURE ZarezerwujSeans(
    p_email VARCHAR2,
    p_tytul VARCHAR2,
    p_data_seansu DATE,
    p_rzad NUMBER,
    p_ilosc_miejsc NUMBER
) IS
    v_cena_laczna NUMBER := 0;
    v_rezerwacja_id NUMBER;
    v_sala_id NUMBER;
    v_repertuar_id NUMBER;
    v_uzytkownik_ref REF Uzytkownik;
    v_miejsce NUMBER;
BEGIN
        -- Pobierz repertuar_id na podstawie tytu³u filmu
        SELECT r.repertuar_id
        INTO v_repertuar_id
        FROM Repertuar_table r
        JOIN Film_table f ON REF(f) = r.film_ref
        WHERE f.tytul = p_tytul
        AND r.data_rozpoczecia = p_data_seansu;
        
        -- Pobierz sala_id
        SELECT r.sala_ref.sala_id
        INTO v_sala_id
        FROM Repertuar_table r
        WHERE r.repertuar_id = v_repertuar_id;
        
        -- Pobierz referencjê u¿ytkownika
        SELECT REF(u)
        INTO v_uzytkownik_ref
        FROM Uzytkownik_table u
        WHERE u.email = p_email;
        
        -- Tworzenie rezerwacji
        v_cena_laczna := p_ilosc_miejsc * 50; -- do zmiany cena
        
        INSERT INTO Rezerwacja_table (rezerwacja_id, data_rezerwacji, cena_laczna, czy_anulowane, repertuar_ref, uzytkownik_ref, bilety)
        VALUES (
            rezerwacja_seq.NEXTVAL, SYSDATE, v_cena_laczna, 0,
            (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = v_repertuar_id),
            v_uzytkownik_ref,
            Bilety_Typ()
        )
        RETURNING rezerwacja_id INTO v_rezerwacja_id;
        
        -- Tworzenie biletów i aktualizacja statusu miejsc
        FOR i IN 1 .. p_ilosc_miejsc LOOP
            -- Pobierz pierwsze dostêpne miejsce w rzêdzie
            SELECT MIN(m.numer)
            INTO v_miejsce
            FROM TABLE(
                SELECT s.miejsca FROM Sala_table s WHERE s.sala_id = v_sala_id
            ) m
            WHERE m.rzad = p_rzad AND m.czy_zajete = 0;
            
            IF v_miejsce IS NULL THEN
                RAISE_APPLICATION_ERROR(-20007, 'Brak dostêpnych miejsc w wybranym rzêdzie.');
            END IF;
            
            -- Dodanie biletu
            INSERT INTO Bilet_table (bilet_id, cena, seans_ref, rzad, miejsce)
            VALUES (
                bilet_seq.NEXTVAL, 25,
                (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = v_repertuar_id),
                p_rzad, v_miejsce
            );
            
            -- Oznaczenie miejsca jako zajête
UPDATE TABLE (
    SELECT s.miejsca FROM Sala_table s
    WHERE s.sala_id = v_sala_id
) m
SET m.czy_zajete = 1
WHERE m.rzad = p_rzad AND m.numer = v_miejsce
AND EXISTS (
    SELECT 1 FROM Repertuar_table r
    WHERE r.repertuar_id = v_repertuar_id
    AND r.sala_ref.sala_id = v_sala_id
);
        END LOOP;
    END ZarezerwujSeans;
    
    


    PROCEDURE AnulujRezerwacje(
        p_tytul VARCHAR2,
        p_data_seansu DATE,
        p_email VARCHAR2
    ) IS
        v_repertuar_id NUMBER;
        v_uzytkownik_ref REF Uzytkownik;
        v_sala_id NUMBER;
        v_rezerwacja_id NUMBER;
    BEGIN
        -- Pobierz repertuar_id i sala_id na podstawie tytu³u filmu i daty seansu
        SELECT r.repertuar_id, r.sala_ref.sala_id
        INTO v_repertuar_id, v_sala_id
        FROM Repertuar_table r
        JOIN Film_table f ON REF(f) = r.film_ref
        WHERE f.tytul = p_tytul
        AND r.data_rozpoczecia = p_data_seansu;
    
        -- Pobierz referencjê u¿ytkownika
        SELECT REF(u)
        INTO v_uzytkownik_ref
        FROM Uzytkownik_table u
        WHERE u.email = p_email;
    
        -- Pobierz ID rezerwacji u¿ytkownika na dany seans
        SELECT r.rezerwacja_id
        INTO v_rezerwacja_id
        FROM Rezerwacja_table r
        WHERE r.uzytkownik_ref = v_uzytkownik_ref
        AND r.repertuar_ref = (SELECT REF(r) FROM Repertuar_table r WHERE r.repertuar_id = v_repertuar_id)
        AND r.czy_anulowane = 0;
    
        -- Anulowanie rezerwacji dla u¿ytkownika
        DBMS_OUTPUT.PUT_LINE('Rezerwacja anulowana. Zwolnienie miejsc obs³u¿y wyzwalacz.');
        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = v_rezerwacja_id;
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
    END AnulujRezerwacje;


    
    PROCEDURE PokazRezerwacje(
        p_email VARCHAR2
    ) IS
        v_uzytkownik_ref REF Uzytkownik;
        v_count NUMBER := 0;
    BEGIN
        -- Pobierz referencjê u¿ytkownika
        SELECT REF(u)
        INTO v_uzytkownik_ref
        FROM Uzytkownik_table u
        WHERE u.email = p_email;
        
            SELECT COUNT(*)
    INTO v_count
    FROM Rezerwacja_table r
    WHERE r.uzytkownik_ref = v_uzytkownik_ref;
    
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Brak rezerwacji dla u¿ytkownika ' || p_email);
        RETURN;
    END IF;
        
        FOR r IN (
            SELECT r.rezerwacja_id, f.tytul, rep.data_rozpoczecia,TO_CHAR(rep.data_rozpoczecia, 'HH24:MI') AS godzina_seansu
            , r.cena_laczna, r.czy_anulowane
            FROM Rezerwacja_table r
            JOIN Repertuar_table rep ON REF(rep) = r.repertuar_ref
            JOIN Film_table f ON REF(f) = rep.film_ref
            WHERE r.uzytkownik_ref = v_uzytkownik_ref
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Rezerwacja ID: ' || r.rezerwacja_id || ' | Film: ' || r.tytul || ' | Data: ' || r.data_rozpoczecia  || 
                             ' | Godzina: ' || r.godzina_seansu|| ' | Cena: ' || r.cena_laczna || ' | Anulowana: ' || r.czy_anulowane);
        END LOOP;
    END PokazRezerwacje;
    
    
PROCEDURE PokazSeanse(
    p_data_seansu DATE
) IS
BEGIN
    FOR r IN (
        SELECT f.tytul, 
               rep.data_rozpoczecia, 
               TO_CHAR(rep.data_rozpoczecia, 'HH24:MI') AS godzina_seansu,
               -- Obliczamy liczbê dostêpnych miejsc poprawnie
               (SELECT COUNT(*) FROM TABLE(
                   SELECT s.miejsca FROM Sala_table s 
                   WHERE s.sala_id = rep.sala_ref.sala_id
               ) WHERE czy_zajete = 0) AS dostepne_miejsca
        FROM Repertuar_table rep
        JOIN Film_table f ON REF(f) = rep.film_ref
        WHERE TRUNC(rep.data_rozpoczecia) = TRUNC(p_data_seansu)
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Film: ' || r.tytul || 
                             ' | Data: ' || TO_CHAR(r.data_rozpoczecia, 'YYYY-MM-DD') || 
                             ' | Godzina: ' || r.godzina_seansu || 
                             ' | Dostêpne miejsca: ' || r.dostepne_miejsca);
    END LOOP;
END PokazSeanse;


END Rezerwacja_Pkg;
/



