SET SERVEROUTPUT ON;
CREATE OR REPLACE PACKAGE Klient_Pkg AS
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
    
    PROCEDURE ZmienTypKonta(
        p_email VARCHAR2,
        p_typ_konta VARCHAR2
    );
    
    PROCEDURE SprawdzWiek(
    p_email VARCHAR2,
    p_tytul VARCHAR2
);


END Klient_Pkg;
/





CREATE OR REPLACE PACKAGE BODY Klient_Pkg AS
PROCEDURE SprawdzWiek(
    p_email VARCHAR2,
    p_tytul VARCHAR2
) IS
    v_wiek_usera NUMBER;
    v_wiek_filmu NUMBER;
BEGIN
    -- Pobranie wieku u¿ytkownika
    SELECT  u.wiek
    INTO v_wiek_usera
    FROM Uzytkownik_table u
    WHERE u.email = p_email;
    
    -- Pobranie wymaganego wieku dla filmu
    SELECT MIN(f.minimalny_wiek) 
    INTO v_wiek_filmu
    FROM Film_table f 
    WHERE f.tytul = p_tytul
    FETCH FIRST 1 ROW ONLY;
    
    -- Sprawdzenie wieku u¿ytkownika
    IF v_wiek_usera < v_wiek_filmu THEN
        RAISE_APPLICATION_ERROR(-20008, 'U¿ytkownik nie spe³nia wymaganego wieku dla tego filmu.');
    END IF;
END SprawdzWiek;

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
    v_rabat NUMBER := 1.0;
    v_typ_konta VARCHAR2(20);
BEGIN
            -- Sprawdzenie wieku u¿ytkownika przed rezerwacj¹
    BEGIN
        SprawdzWiek(p_email, p_tytul);
            EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('User nie spelnia minimalnego wieku by pojsc na film' );
            RETURN; -- Przerywamy rezerwacjê jeœli u¿ytkownik nie spe³nia wymagañ wiekowych
    END;
    
       SELECT rola INTO v_typ_konta FROM Uzytkownik_table WHERE email = p_email;
            IF v_typ_konta = 'premium' THEN
                v_rabat := 0.9; -- Rabat 10% dla u¿ytkowników premium
        END IF;
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
        v_cena_laczna := p_ilosc_miejsc * 50 * v_rabat;
        
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
        EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Nie znaleziono filmu lub sali.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nieznany b³¹d: ' || SQLERRM);
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
        v_data_seansu DATE;
    BEGIN
        -- Pobierz repertuar_id i sala_id na podstawie tytu³u filmu i daty seansu
        SELECT r.repertuar_id, r.sala_ref.sala_id, r.data_rozpoczecia
        INTO v_repertuar_id, v_sala_id, v_data_seansu
        FROM Repertuar_table r
        JOIN Film_table f ON REF(f) = r.film_ref
        WHERE f.tytul = p_tytul
        AND r.data_rozpoczecia = p_data_seansu;
    
    IF v_data_seansu - INTERVAL '1' HOUR < SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Nie mozna anulowac rezerwacji na mniej niz godzine przed seansem.');
        RETURN;
    END IF;
    
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

PROCEDURE ZmienTypKonta(
    p_email VARCHAR2,
    p_typ_konta VARCHAR2
) IS
    v_count NUMBER := 0;
BEGIN
    -- Sprawdzenie, czy u¿ytkownik istnieje
    SELECT COUNT(*) INTO v_count FROM Uzytkownik_table WHERE email = p_email;
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('U¿ytkownik o podanym emailu nie istnieje.');
        RETURN;
    END IF;
    
    -- Sprawdzenie, czy podany typ konta jest poprawny
    IF p_typ_konta NOT IN ('standard', 'premium') THEN
        DBMS_OUTPUT.PUT_LINE('Niepoprawny typ konta. Dozwolone wartoœci: standard, premium.');
        RETURN;
    END IF;
    
    -- Aktualizacja typu konta u¿ytkownika
    UPDATE Uzytkownik_table
    SET rola = p_typ_konta
    WHERE email = p_email;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Typ konta u¿ytkownika ' || p_email || ' zosta³ zmieniony na ' || p_typ_konta);
END ZmienTypKonta;

END Klient_Pkg;
/



