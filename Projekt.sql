BEGIN
    -- 1. Usuwanie Wyzwalaczy (Triggers)
    BEGIN
        EXECUTE IMMEDIATE 'DROP TRIGGER trg_rezerwacja_data';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4080 THEN -- ORA-04080: trigger does not exist
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TRIGGER release_seat_on_cancel';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4080 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TRIGGER ensure_unique_seans_per_sala';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4080 THEN
                RAISE;
            END IF;
    END;

    -- 2. Usuwanie Pakietów i Ich Cia³ (Packages and Package Bodies)
    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE BODY Rezerwacja_Pkg';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN -- ORA-04043: object does not exist
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE Rezerwacja_Pkg';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE BODY AnulujRezerwacje_Pkg';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE AnulujRezerwacje_Pkg';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE BODY Repertuar_Pkg';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP PACKAGE Repertuar_Pkg';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- 3. Usuwanie Sekwencji (Sequences)
    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE Bilet_SEQ';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -2289 THEN -- ORA-02289: sequence does not exist
                RAISE;
            END IF;
    END;

    -- 4. Usuwanie Tabel Obiektowych (Object Tables)
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Rezerwacja_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN -- ORA-00942: table or view does not exist
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Bilet_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Repertuar_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Miejsce_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Sala_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Film_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Uzytkownik_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Kategoria_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Rola_table CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;

    -- 5. Usuwanie Typów Obiektowych (Object Types)
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Rezerwacja FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN -- ORA-04043: object does not exist
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Bilet FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Repertuar FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Miejsce FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Sala FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Film FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Uzytkownik FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Kategoria FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Rola FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
    
    -- Usuwanie innych typów, jeœli istniej¹ (np. Bilety_Typ)
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Bilety_Typ FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;
END;
/

    
-- -------------------------------
-- Sekcja: Tworzenie typów obiektów
-- -------------------------------

-- Typ Kategoria
CREATE OR REPLACE TYPE Kategoria AS OBJECT (
    kategoria_id NUMBER,
    nazwa VARCHAR2(100)
);
/

-- Typ Miejsce
CREATE OR REPLACE TYPE Miejsce AS OBJECT (
    miejsce_id NUMBER,
    rzad NUMBER,
    numer NUMBER,
    czy_zajete NUMBER
);
/

CREATE OR REPLACE TYPE Miejsca_Typ AS TABLE OF Miejsce;

-- Typ Sala
CREATE OR REPLACE TYPE Sala AS OBJECT (
    sala_id NUMBER,
    nazwa VARCHAR2(50),
    miejsca Miejsca_Typ
);
/

CREATE OR REPLACE TYPE Uzytkownik AS OBJECT (
    user_id    NUMBER,
    imie       VARCHAR2(50),
    nazwisko   VARCHAR2(50),
    wiek       NUMBER,
    email      VARCHAR2(100),
    rola       VARCHAR2(50) -- zamiast rola_ref
);
/

-- Typ Film
CREATE OR REPLACE TYPE Film AS OBJECT (
    film_id NUMBER,
    tytul VARCHAR2(200),
    czas_trwania NUMBER,  -- w minutach
    minimalny_wiek NUMBER,
    kategoria_ref REF Kategoria
);
/

-- Typ Repertuar
CREATE OR REPLACE TYPE Repertuar AS OBJECT (
    repertuar_id NUMBER,
    film_ref REF Film,
    sala_ref REF Sala,
    data_rozpoczecia DATE,
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER,
    MEMBER FUNCTION data_zakonczenia RETURN DATE
);
/

-- Typ Bilet
CREATE OR REPLACE TYPE Bilet AS OBJECT (
    bilet_id NUMBER,
    cena NUMBER(5,2),
    seans_ref REF Repertuar,
    rzad NUMBER,
    miejsce NUMBER,
    MEMBER FUNCTION data_seansu RETURN DATE
);
/

-- Typ Bilety_Typ
CREATE OR REPLACE TYPE Bilety_Typ AS TABLE OF REF Bilet;
/

-- Typ Rezerwacja
CREATE OR REPLACE TYPE Rezerwacja AS OBJECT (
    rezerwacja_id NUMBER,
    data_rezerwacji DATE, 
    cena_laczna NUMBER,
    czy_anulowane NUMBER,  -- 0 - op³acone, 1 - anulowane
    repertuar_ref REF Repertuar,
    uzytkownik_ref REF Uzytkownik,
    bilety Bilety_Typ
);
/


-- -------------------------------
-- Sekcja: Tworzenie tabel
-- -------------------------------

-- Tabela Kategoria_table
CREATE TABLE Kategoria_table OF Kategoria (
    PRIMARY KEY (kategoria_id),
    CONSTRAINT kategoria_nazwa_ck CHECK (nazwa IS NOT NULL)
);
/


-- Tabela Sala_table
CREATE TABLE Sala_table OF Sala (
    PRIMARY KEY (sala_id),
    CONSTRAINT sala_nazwa_ck CHECK (nazwa IS NOT NULL)
)NESTED TABLE miejsca STORE AS miejsca_nt;
/
    
CREATE TABLE Miejsce_table OF Miejsce
(
  primary key (miejsce_id),
  CONSTRAINT miejsce_rzad_ck CHECK (rzad > 0),
  CONSTRAINT miejsce_numer_ck CHECK (numer > 0)
)
OBJECT IDENTIFIER IS PRIMARY KEY;

-- Tabela Uzytkownik_table
CREATE TABLE Uzytkownik_table OF Uzytkownik (
    PRIMARY KEY (user_id),
    CONSTRAINT uzytkownik_email_unique UNIQUE(email),
    CONSTRAINT uzytkownik_wiek_ck CHECK (wiek > 15),
    CONSTRAINT uzytkownik_rola_ck CHECK (rola IN ('standard','premium'))
);
/

-- Tabela Film_table
CREATE TABLE Film_table OF Film (
    PRIMARY KEY (film_id),
    CONSTRAINT film_czas_trwania_ck CHECK (czas_trwania > 0),
    CONSTRAINT film_minimalny_wiek_ck CHECK (minimalny_wiek >= 0 AND minimalny_wiek <= 18)
);
/

-- Tabela Repertuar_table
CREATE TABLE Repertuar_table OF Repertuar (
    PRIMARY KEY (repertuar_id)
);
/

-- Tabela Bilet_table
CREATE TABLE Bilet_table OF Bilet (
    PRIMARY KEY (bilet_id),
    SCOPE FOR (seans_ref) IS repertuar_table,
    CONSTRAINT bilet_cena_ck CHECK (cena > 0)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Rezerwacja_table
CREATE TABLE Rezerwacja_table OF Rezerwacja (
    PRIMARY KEY (rezerwacja_id),
    SCOPE FOR(repertuar_ref) is repertuar_table,
    SCOPE FOR(uzytkownik_ref) is uzytkownik_table,
    CONSTRAINT rezerwacja_cena_laczna_ck CHECK (cena_laczna > 0),
    CONSTRAINT rezerwacja_czy_anulowane_ck CHECK (czy_anulowane IN (0, 1))
) OBJECT IDENTIFIER IS PRIMARY KEY
NESTED TABLE bilety STORE AS bilety_nt;
/


-- -------------------------------
-- Sekcja: Tworzenie cia³ typów obiektów
-- -------------------------------
CREATE OR REPLACE TYPE BODY Repertuar AS
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER IS
        v_ilosc NUMBER;
        v_sala_id NUMBER;
    BEGIN
        -- Pobierz sala_id z referencji SELF.sala_ref
        SELECT s.sala_id
          INTO v_sala_id
          FROM Sala_table s
         WHERE REF(s) = SELF.sala_ref;

        -- Zlicz zajête miejsca w zagnie¿d¿onej tabeli
        SELECT COUNT(*)
          INTO v_ilosc
          FROM TABLE(
              SELECT s.miejsca 
              FROM Sala_table s
              WHERE s.sala_id = v_sala_id
          )
         WHERE czy_zajete = 1;

        RETURN v_ilosc;
    END ilosc_miejsc_zajetych;

    MEMBER FUNCTION data_zakonczenia RETURN DATE IS
        v_czas_trwania NUMBER;
    BEGIN
        -- Pobierz czas trwania filmu
        SELECT f.czas_trwania 
          INTO v_czas_trwania
          FROM Film_table f
         WHERE REF(f) = SELF.film_ref;

        -- Oblicz datê zakoñczenia seansu
        RETURN SELF.data_rozpoczecia + (v_czas_trwania / (24 * 60));
    END data_zakonczenia;
END;
/

CREATE OR REPLACE TYPE BODY Bilet AS
    MEMBER FUNCTION data_seansu RETURN DATE IS
        v_data DATE;
    BEGIN
        SELECT r.data_rozpoczecia 
          INTO v_data
          FROM Repertuar_table r
         WHERE REF(r) = seans_ref;

        RETURN v_data;
    END data_seansu;
END;
/


-- -------------------------------
-- Sekcja: Tworzenie wyzwalaczy
-- -------------------------------

-- Wyzwalacz dla sprawdzenia daty rezerwacji
CREATE OR REPLACE TRIGGER trg_rezerwacja_data
BEFORE INSERT OR UPDATE ON Rezerwacja_table
FOR EACH ROW
DECLARE
    v_data_rozpoczecia DATE;
BEGIN
    BEGIN
        SELECT r.data_rozpoczecia 
        INTO v_data_rozpoczecia
        FROM Repertuar_table r
        WHERE REF(r) = :NEW.repertuar_ref;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono repertuaru dla wskazanej rezerwacji.');
    END;

    -- SprawdŸ, czy data rezerwacji jest póŸniejsza ni¿ rozpoczêcie repertuaru
    IF :NEW.data_rezerwacji > v_data_rozpoczecia THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie mo¿na rezerwowaæ biletów na seans, który ju¿ siê zacz¹³.');
    END IF;
END;
/


        
-- Wyzwalacz na zwalnianie miejsc przy anulowaniu rezerwacji
CREATE OR REPLACE TRIGGER release_seat_on_cancel
AFTER UPDATE OF czy_anulowane ON Rezerwacja_table
FOR EACH ROW
WHEN (NEW.czy_anulowane = 1)
DECLARE
    v_sala_id NUMBER;
    v_rzad NUMBER;
    v_numer NUMBER;
BEGIN
    -- Pobierz sala_id z powi¹zanego repertuaru
    SELECT r.sala_ref.sala_id
      INTO v_sala_id
      FROM Repertuar_table r
     WHERE REF(r) = :OLD.repertuar_ref;

    -- Iteruj po biletach i aktualizuj odpowiednie miejsca
    FOR miejsce_rec IN (
        SELECT COLUMN_VALUE AS bilet_ref
        FROM TABLE(:OLD.bilety)
    ) LOOP
        -- Pobierz informacje o rzêdzie i numerze miejsca z biletów
        SELECT b.rzad, b.miejsce
          INTO v_rzad, v_numer
          FROM Bilet_table b
         WHERE REF(b) = miejsce_rec.bilet_ref;

        -- Oznacz miejsce jako wolne w nested table
        UPDATE TABLE(SELECT s.miejsca 
                     FROM Sala_table s 
                     WHERE s.sala_id = v_sala_id)
        SET czy_zajete = 0
        WHERE rzad = v_rzad AND numer = v_numer;
    END LOOP;

    -- Usuñ bilety powi¹zane z rezerwacj¹
    DELETE FROM Bilet_table b
    WHERE REF(b) IN (
        SELECT COLUMN_VALUE 
        FROM TABLE(:OLD.bilety)
    );
END;
/



        
-- Wyzwalacz na unikalnoœæ seansów w sali
CREATE OR REPLACE TRIGGER ensure_unique_seans_per_sala
BEFORE INSERT OR UPDATE ON Repertuar_table
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- SprawdŸ, czy w tej samej sali i o tej samej godzinie nie ma innego seansu
    SELECT COUNT(*)
      INTO v_count
      FROM Repertuar_table r
     WHERE r.sala_ref = :NEW.sala_ref
       AND r.data_rozpoczecia = :NEW.data_rozpoczecia
       AND r.repertuar_id != :NEW.repertuar_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'W jednej sali w tym samym czasie mo¿e byæ tylko jeden seans.');
    END IF;
END;
/

-- -------------------------------
-- Sekcja: Tworzenie pakietów
-- -------------------------------

-- Pakiet do obs³ugi rezerwacji
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

    -- Procedura sprawdzaj¹ca istnienie u¿ytkownika
    PROCEDURE SprawdzUzytkownika (p_email VARCHAR2, v_uzytkownik OUT REF Uzytkownik) IS
    BEGIN
        SELECT REF(u)
        INTO v_uzytkownik
        FROM Uzytkownik_table u
        WHERE u.email = p_email;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'U¿ytkownik o podanym e-mailu nie istnieje.');
    END SprawdzUzytkownika;

    -- Procedura sprawdzaj¹ca istnienie filmu
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

    -- Procedura sprawdzaj¹ca wiek u¿ytkownika wzglêdem wymagañ filmu
    PROCEDURE SprawdzWiekUzytkownika (
        v_uzytkownik REF Uzytkownik,
        v_film REF Film
    ) IS
        v_wiek NUMBER;
        v_minimalny_wiek NUMBER;
    BEGIN
        -- Pobierz wiek u¿ytkownika
        SELECT u.wiek INTO v_wiek
        FROM Uzytkownik_table u
        WHERE REF(u) = v_uzytkownik;

        -- Pobierz minimalny wiek dla filmu
        SELECT f.minimalny_wiek INTO v_minimalny_wiek
        FROM Film_table f
        WHERE REF(f) = v_film;

        -- SprawdŸ, czy u¿ytkownik spe³nia minimalny wiek
        IF v_wiek < v_minimalny_wiek THEN
            RAISE_APPLICATION_ERROR(-20007, 'U¿ytkownik nie spe³nia wymagañ wiekowych dla wybranego filmu.');
        END IF;
    END SprawdzWiekUzytkownika;

    -- Funkcja sprawdzaj¹ca dostêpnoœæ miejsc
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
        -- Pobierz sala_id z powi¹zanego repertuaru
        SELECT r.sala_ref.sala_id
          INTO v_sala_id
          FROM Repertuar_table r
         WHERE REF(r) = p_repertuar;
    
        -- Otwórz kursor z dostêpnymi miejscami
        OPEN v_miejsca FOR
            SELECT m.rzad, m.numer
            FROM TABLE(
                SELECT s.miejsca
                FROM Sala_table s
                WHERE s.sala_id = v_sala_id
            ) m
            WHERE m.czy_zajete = 0 -- Sprawdzamy tylko wolne miejsca
              AND (p_preferencja_rzad IS NULL OR m.rzad = p_preferencja_rzad) -- Uwzglêdniamy preferencjê rzêdu
            ORDER BY m.rzad, m.numer;
    
        -- SprawdŸ, czy s¹ wystarczaj¹ce miejsca obok siebie
        LOOP
            FETCH v_miejsca INTO v_rzad, v_numer;
            EXIT WHEN v_miejsca%NOTFOUND;
    
            -- SprawdŸ, czy miejsca s¹ w tym samym rzêdzie
            IF v_prev_rzad IS NULL THEN
                v_prev_rzad := v_rzad; -- Ustaw pierwszy rz¹d
            ELSIF v_prev_rzad != v_rzad THEN
                v_count_sequential := 1; -- Resetuj licznik, jeœli zmieni³ siê rz¹d
                v_prev_rzad := v_rzad;
            END IF;
    
            -- SprawdŸ ci¹g³oœæ miejsc
            IF v_prev_numer IS NULL THEN
                v_count_sequential := 1; -- Rozpocznij odliczanie
            ELSIF v_numer = v_prev_numer + 1 THEN
                v_count_sequential := v_count_sequential + 1; -- Zwiêksz licznik ci¹g³ych miejsc
            ELSE
                v_count_sequential := 1; -- Reset licznika, jeœli brak ci¹g³oœci
            END IF;
    
            -- Jeœli znaleziono wystarczaj¹c¹ liczbê miejsc
            IF v_count_sequential = p_ilosc THEN
                RETURN TRUE;
            END IF;
    
            -- Zapisz poprzednie wartoœci
            v_prev_numer := v_numer;
        END LOOP;
    
        -- Jeœli nie znaleziono wystarczaj¹cych miejsc
        RETURN FALSE;
    END SprawdzDostepneMiejsca;


    -- Procedura tworz¹ca rezerwacjê
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
    -- SprawdŸ u¿ytkownika
    SprawdzUzytkownika(p_email, v_uzytkownik);

    -- SprawdŸ film
    SprawdzFilm(p_film_tytul, v_film);

    -- Pobierz zni¿kê dla u¿ytkownika
    SELECT CASE WHEN u.rola = 'premium' THEN 0.9 ELSE 1 END
    INTO v_znizka
    FROM Uzytkownik_table u 
    WHERE REF(u) = v_uzytkownik;

    -- ZnajdŸ repertuar (tu powinien byæ wywo³any odpowiedni blok logiczny)

    -- Oblicz cenê ca³kowit¹
    v_cena_laczna := v_cena * p_ilosc * v_znizka;

    -- Utwórz rezerwacjê
    SELECT NVL(MAX(rezerwacja_id), 0) + 1 INTO v_rezerwacja_id FROM Rezerwacja_table;

    INSERT INTO Rezerwacja_table
    VALUES (
        Rezerwacja(
            v_rezerwacja_id, 
            SYSDATE, 
            v_cena_laczna, -- Cena ca³kowita
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
        -- Aktualizuj rezerwacjê na anulowan¹
        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = p_rezerwacja_id;

        -- Pobierz bilety powi¹zane z rezerwacj¹
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
        -- SprawdŸ, czy film istnieje
        BEGIN
            SELECT REF(f) INTO v_film FROM Film_table f WHERE f.film_id = p_film_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Film o podanym ID nie istnieje.');
        END;

        -- SprawdŸ, czy sala istnieje
        BEGIN
            SELECT REF(s) INTO v_sala FROM Sala_table s WHERE s.sala_id = p_sala_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20002, 'Sala o podanym ID nie istnieje.');
        END;

        -- SprawdŸ konflikt czasowy w sali
        DECLARE
            v_conflict_count NUMBER;
        BEGIN
            SELECT COUNT(*)
              INTO v_conflict_count
              FROM Repertuar_table r
             WHERE r.sala_ref = v_sala
               AND ABS((r.data_rozpoczecia - p_data_rozpoczecia) * 24 * 60) < 120; -- Konflikt w czasie 2h

            IF v_conflict_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20003, 'W tej sali jest ju¿ seans o zbli¿onej godzinie.');
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
            DBMS_OUTPUT.PUT_LINE('Seans zosta³ pomyœlnie dodany: ID ' || v_new_repertuar_id);
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE_APPLICATION_ERROR(-20004, 'Nie uda³o siê dodaæ seansu. Przyczyna: ' || SQLERRM);
        END;
    END DodajSeans;
END Repertuar_Pkg;
/


-- -------------------------------
-- Sekcja: Inicjalizacja danych
-- -------------------------------


-- Dodanie u¿ytkowników
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(1, 'Jan', 'Kowalski', 16, 'jan.kowalski@example.com', 'standard')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(2, 'Anna', 'Nowak', 18, 'anna.nowak@example.com', 'premium')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(3, 'Piotr', 'Wiœniewski', 25, 'piotr.wisniewski@example.com', 'standard')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(4, 'Kasia', 'Zalewska', 16, 'kasia.zalewska@example.com', 'premium')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(5, 'Marek', 'Szymañski', 30, 'marek.szymanski@example.com', 'standard')
);



-- Dodanie kategorii
INSERT INTO Kategoria_table VALUES (Kategoria(1, 'Komedia'));
INSERT INTO Kategoria_table VALUES (Kategoria(2, 'Dramat'));
INSERT INTO Kategoria_table VALUES (Kategoria(3, 'Horror'));
INSERT INTO Kategoria_table VALUES (Kategoria(4, 'Akcja'));
INSERT INTO Kategoria_table VALUES (Kategoria(5, 'Animacja'));

-- Dodanie sal
-- Dodanie sal wraz z miejscami
INSERT INTO Sala_table VALUES (
    Sala(1, 'Sala A', Miejsca_Typ(
        Miejsce(1, 1, 1, 0), Miejsce(2, 1, 2, 0), Miejsce(3, 1, 3, 0),
        Miejsce(4, 2, 1, 0), Miejsce(5, 2, 2, 0), Miejsce(6, 2, 3, 0)
    ))
);

INSERT INTO Sala_table VALUES (
    Sala(2, 'Sala B', Miejsca_Typ(
        Miejsce(7, 1, 1, 0), Miejsce(8, 1, 2, 0), Miejsce(9, 1, 3, 0),
        Miejsce(10, 2, 1, 0), Miejsce(11, 2, 2, 0), Miejsce(12, 2, 3, 0)
    ))
);

INSERT INTO Sala_table VALUES (
    Sala(3, 'Sala C', Miejsca_Typ(
        Miejsce(13, 1, 1, 0), Miejsce(14, 1, 2, 0), Miejsce(15, 1, 3, 0),
        Miejsce(16, 2, 1, 0), Miejsce(17, 2, 2, 0), Miejsce(18, 2, 3, 0)
    ))
);

INSERT INTO Sala_table VALUES (
    Sala(4, 'Sala D', Miejsca_Typ(
        Miejsce(19, 1, 1, 0), Miejsce(20, 1, 2, 0), Miejsce(21, 1, 3, 0),
        Miejsce(22, 2, 1, 0), Miejsce(23, 2, 2, 0), Miejsce(24, 2, 3, 0)
    ))
);

INSERT INTO Sala_table VALUES (
    Sala(5, 'Sala E', Miejsca_Typ(
        Miejsce(25, 1, 1, 0), Miejsce(26, 1, 2, 0), Miejsce(27, 1, 3, 0),
        Miejsce(28, 2, 1, 0), Miejsce(29, 2, 2, 0), Miejsce(30, 2, 3, 0)
    ))
);

-- Dodanie filmów
INSERT INTO Film_table VALUES (
    Film(1, 'Komedia na weekend', 90, 0, 
    (SELECT REF(k) FROM Kategoria_table k WHERE k.kategoria_id = 1))
);

INSERT INTO Film_table VALUES (
    Film(2, 'Dramat ¿ycia', 120, 12, 
    (SELECT REF(k) FROM Kategoria_table k WHERE k.kategoria_id = 2))
);

INSERT INTO Film_table VALUES (
    Film(3, 'Horror w lesie', 100, 18, 
    (SELECT REF(k) FROM Kategoria_table k WHERE k.kategoria_id = 3))
);

INSERT INTO Film_table VALUES (
    Film(4, 'Akcja bez granic', 140, 16, 
    (SELECT REF(k) FROM Kategoria_table k WHERE k.kategoria_id = 4))
);

INSERT INTO Film_table VALUES (
    Film(5, 'Animacja dla dzieci', 80, 0, 
    (SELECT REF(k) FROM Kategoria_table k WHERE k.kategoria_id = 5))
);

-- Dodanie seansów za pomoc¹ pakietu Repertuar_Pkg
BEGIN
    Repertuar_Pkg.DodajSeans(1, 1, TO_DATE('2025-03-20 10:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(2, 2, TO_DATE('2025-03-21 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(3, 3, TO_DATE('2025-03-17 14:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(4, 4, TO_DATE('2025-03-18 16:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(5, 5, TO_DATE('2025-03-19 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));
END;
/


-- Testowanie rezerwacji
BEGIN
    Rezerwacja_Pkg.UtworzRezerwacje('jan.kowalski@example.com', 'Komedia na weekend', 2, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('anna.nowak@example.com', 'Horror w lesie', 3, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('piotr.wisniewski@example.com', 'Dramat ¿ycia', 1, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('kasia.zalewska@example.com', 'Akcja bez granic', 2, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('marek.szymanski@example.com', 'Animacja dla dzieci', 4, NULL);
END;
/

BEGIN
    Rezerwacja_Pkg.UtworzRezerwacje('jan.kowalski@example.com', 'Komedia na weekend', 2, NULL);
END;
/

