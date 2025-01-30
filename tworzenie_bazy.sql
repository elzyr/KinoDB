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

    -- 2. Usuwanie Pakietï¿½w i Ich Ciaï¿½ (Packages and Package Bodies)
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

    -- 5. Usuwanie Typï¿½w Obiektowych (Object Types)
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
    
    -- Usuwanie innych typï¿½w, jeï¿½li istniejï¿½ (np. Bilety_Typ)
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

    
-- Usuniêcie sekwencji, jeœli istniej¹
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE kategoria_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE sala_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE miejsce_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE uzytkownik_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE film_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE repertuar_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE bilet_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE rezerwacja_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/

-- -------------------------------
-- Sekcja: Tworzenie sekwencji
-- -------------------------------
CREATE SEQUENCE kategoria_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sala_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE miejsce_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE uzytkownik_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE film_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE repertuar_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE bilet_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE rezerwacja_seq START WITH 1 INCREMENT BY 1;

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
/

-- Typ Sala
CREATE OR REPLACE TYPE Sala AS OBJECT (
    sala_id NUMBER,
    nazwa VARCHAR2(50),
    miejsca Miejsca_Typ
);
/

-- Typ Uzytkownik
CREATE OR REPLACE TYPE Uzytkownik AS OBJECT (
    user_id    NUMBER,
    imie       VARCHAR2(50),
    nazwisko   VARCHAR2(50),
    wiek       NUMBER,
    email      VARCHAR2(100),
    rola       VARCHAR2(50)
);
/

-- Typ Film
CREATE OR REPLACE TYPE Film AS OBJECT (
    film_id NUMBER,
    tytul VARCHAR2(200),
    czas_trwania NUMBER,
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
    czy_anulowane NUMBER,
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

-- Wyzwalacz dla Kategoria_table
CREATE OR REPLACE TRIGGER trg_kategoria_id
BEFORE INSERT ON Kategoria_table
FOR EACH ROW
BEGIN
    IF :NEW.kategoria_id IS NULL THEN
        :NEW.kategoria_id := kategoria_seq.NEXTVAL;
    END IF;
END;
/

-- Tabela Sala_table
CREATE TABLE Sala_table OF Sala (
    PRIMARY KEY (sala_id),
    CONSTRAINT sala_nazwa_ck CHECK (nazwa IS NOT NULL)
) NESTED TABLE miejsca STORE AS miejsca_nt;
/

-- Wyzwalacz dla Sala_table
CREATE OR REPLACE TRIGGER trg_sala_id
BEFORE INSERT ON Sala_table
FOR EACH ROW
BEGIN
    IF :NEW.sala_id IS NULL THEN
        :NEW.sala_id := sala_seq.NEXTVAL;
    END IF;
END;
/

-- Tabela Uzytkownik_table
CREATE TABLE Uzytkownik_table OF Uzytkownik (
    PRIMARY KEY (user_id),
    CONSTRAINT uzytkownik_email_unique UNIQUE(email),
    CONSTRAINT uzytkownik_wiek_ck CHECK (wiek > 15),
    CONSTRAINT uzytkownik_rola_ck CHECK (rola IN ('standard','premium'))
);
/

-- Wyzwalacz dla Uzytkownik_table
CREATE OR REPLACE TRIGGER trg_uzytkownik_id
BEFORE INSERT ON Uzytkownik_table
FOR EACH ROW
BEGIN
    IF :NEW.user_id IS NULL THEN
        :NEW.user_id := uzytkownik_seq.NEXTVAL;
    END IF;
END;
/

-- Tabela Film_table
CREATE TABLE Film_table OF Film (
    PRIMARY KEY (film_id),
    CONSTRAINT film_czas_trwania_ck CHECK (czas_trwania > 0),
    CONSTRAINT film_minimalny_wiek_ck CHECK (minimalny_wiek >= 0 AND minimalny_wiek <= 18)
);
/

-- Wyzwalacz dla Film_table
CREATE OR REPLACE TRIGGER trg_film_id
BEFORE INSERT ON Film_table
FOR EACH ROW
BEGIN
    IF :NEW.film_id IS NULL THEN
        :NEW.film_id := film_seq.NEXTVAL;
    END IF;
END;
/

-- Tabela Repertuar_table
CREATE TABLE Repertuar_table OF Repertuar (
    PRIMARY KEY (repertuar_id)
);
/

-- Wyzwalacz dla Repertuar_table
CREATE OR REPLACE TRIGGER trg_repertuar_id
BEFORE INSERT ON Repertuar_table
FOR EACH ROW
BEGIN
    IF :NEW.repertuar_id IS NULL THEN
        :NEW.repertuar_id := repertuar_seq.NEXTVAL;
    END IF;
END;
/

-- Tabela Bilet_table
CREATE TABLE Bilet_table OF Bilet (
    PRIMARY KEY (bilet_id),
    SCOPE FOR (seans_ref) IS Repertuar_table,
    CONSTRAINT bilet_cena_ck CHECK (cena > 0)
);
/

-- Wyzwalacz dla Bilet_table
CREATE OR REPLACE TRIGGER trg_bilet_id
BEFORE INSERT ON Bilet_table
FOR EACH ROW
BEGIN
    IF :NEW.bilet_id IS NULL THEN
        :NEW.bilet_id := bilet_seq.NEXTVAL;
    END IF;
END;
/

-- Tabela Rezerwacja_table
CREATE TABLE Rezerwacja_table OF Rezerwacja (
    PRIMARY KEY (rezerwacja_id),
    SCOPE FOR (repertuar_ref) IS Repertuar_table,
    SCOPE FOR (uzytkownik_ref) IS Uzytkownik_table,
    CONSTRAINT rezerwacja_cena_laczna_ck CHECK (cena_laczna > 0),
    CONSTRAINT rezerwacja_czy_anulowane_ck CHECK (czy_anulowane IN (0, 1))
) NESTED TABLE bilety STORE AS bilety_nt;
/

-- Wyzwalacz dla Rezerwacja_table
CREATE OR REPLACE TRIGGER trg_rezerwacja_id
BEFORE INSERT ON Rezerwacja_table
FOR EACH ROW
BEGIN
    IF :NEW.rezerwacja_id IS NULL THEN
        :NEW.rezerwacja_id := rezerwacja_seq.NEXTVAL;
    END IF;
END;
/

-- -------------------------------
-- Sekcja: Tworzenie ciaï¿½ typï¿½w obiektï¿½w
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

        -- Zlicz zajï¿½te miejsca w zagnieï¿½dï¿½onej tabeli
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

        -- Oblicz datï¿½ zakoï¿½czenia seansu
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
END;
/


        
-- Wyzwalacz na zwalnianie miejsc przy anulowaniu rezerwacji
CREATE OR REPLACE TRIGGER release_seat_on_cancel
AFTER UPDATE OF czy_anulowane ON Rezerwacja_table
FOR EACH ROW
WHEN (NEW.czy_anulowane = 1)
DECLARE
    v_sala_id NUMBER;
BEGIN
    -- Pobranie ID sali z powi¹zanego repertuaru
    BEGIN
        SELECT r.sala_ref.sala_id
        INTO v_sala_id
        FROM Repertuar_table r
        WHERE REF(r) = :NEW.repertuar_ref;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('B³¹d: Nie znaleziono powi¹zanej sali dla rezerwacji.');
            RETURN;
    END;

    -- Iteracja po biletach z rezerwacji
    FOR bilet_rec IN (
        SELECT b.rzad, b.miejsce
        FROM Bilet_table b
        WHERE b.bilet_id IN (
            SELECT COLUMN_VALUE
            FROM TABLE(CAST(:OLD.bilety AS Bilety_Typ))
        )
    ) LOOP
        -- Aktualizacja statusu miejsc w Sala_table
        UPDATE TABLE (
            SELECT s.miejsca FROM Sala_table s WHERE s.sala_id = v_sala_id
        ) m
        SET m.czy_zajete = 0
        WHERE m.rzad = bilet_rec.rzad AND m.numer = bilet_rec.miejsce
        AND EXISTS (
            SELECT 1 FROM Sala_table s WHERE s.sala_id = v_sala_id
        );
    END LOOP;
END;
/




        
-- Wyzwalacz na unikalnoï¿½ï¿½ seansï¿½w w sali
CREATE OR REPLACE TRIGGER ensure_unique_seans_per_sala
BEFORE INSERT OR UPDATE ON Repertuar_table
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Sprawdï¿½, czy w tej samej sali i o tej samej godzinie nie ma innego seansu
    SELECT COUNT(*)
      INTO v_count
      FROM Repertuar_table r
     WHERE r.sala_ref = :NEW.sala_ref
       AND r.data_rozpoczecia = :NEW.data_rozpoczecia
       AND r.repertuar_id != :NEW.repertuar_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'W jednej sali w tym samym czasie moï¿½e byï¿½ tylko jeden seans.');
    END IF;
END;
/