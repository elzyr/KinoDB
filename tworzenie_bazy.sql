BEGIN
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rezerwacja_table CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Repertuar_table CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Sala_table CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Film_table CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Uzytkownik_table CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE Kategoria_table CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;

        BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE kategoria_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE sala_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE miejsce_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE uzytkownik_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE film_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE repertuar_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE rezerwacja_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Rezerwacja FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Bilety_Typ FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Bilet FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Repertuar FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Sala FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Miejsca_Typ FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Miejsce FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Film FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Uzytkownik FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TYPE Kategoria FORCE'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

-- Sekwencje
CREATE SEQUENCE kategoria_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sala_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE miejsce_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE uzytkownik_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE film_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE repertuar_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE rezerwacja_seq START WITH 1 INCREMENT BY 1;

-- Typy obiektowe
CREATE OR REPLACE TYPE Kategoria AS OBJECT (
    kategoria_id NUMBER,
    nazwa VARCHAR2(100)
);
/

CREATE OR REPLACE TYPE Miejsce AS OBJECT (
    miejsce_id NUMBER,
    rzad NUMBER,
    numer NUMBER,
    czy_zajete NUMBER
);
/

CREATE OR REPLACE TYPE Miejsca_Typ AS TABLE OF Miejsce;
/

CREATE OR REPLACE TYPE Sala AS OBJECT (
    sala_id NUMBER,
    nazwa VARCHAR2(50),
    miejsca Miejsca_Typ
);
/

CREATE OR REPLACE TYPE Uzytkownik AS OBJECT (
    user_id NUMBER,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    data_urodzenia DATE,
    email VARCHAR2(100),
    rola VARCHAR2(50)
);
/


CREATE OR REPLACE TYPE Film AS OBJECT (
    film_id NUMBER,
    tytul VARCHAR2(200),
    czas_trwania NUMBER,
    minimalny_wiek NUMBER,
    kategoria_ref REF Kategoria,
    czy_wycofany NUMBER
);
/

CREATE OR REPLACE TYPE Repertuar AS OBJECT (
    repertuar_id NUMBER,
    film_ref REF Film,
    sala_ref REF Sala,
    data_rozpoczecia DATE,
    MEMBER FUNCTION data_zakonczenia RETURN DATE
);
/

CREATE OR REPLACE TYPE Bilet AS OBJECT (
    bilet_id NUMBER,
    cena NUMBER(5,2),
    rzad NUMBER,
    miejsce NUMBER
);
/

CREATE OR REPLACE TYPE Bilety_Typ AS TABLE OF Bilet;
/

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

-- Tabele
CREATE TABLE Kategoria_table OF Kategoria (
    PRIMARY KEY (kategoria_id),
    CONSTRAINT kategoria_nazwa_unique UNIQUE(nazwa)
);
/

CREATE TABLE Sala_table OF Sala (
    PRIMARY KEY (sala_id),
    CONSTRAINT sala_nazwa_ck CHECK (nazwa IS NOT NULL)
) NESTED TABLE miejsca STORE AS miejsca_nt;
/

CREATE TABLE Uzytkownik_table OF Uzytkownik (
    PRIMARY KEY (user_id),
    CONSTRAINT uzytkownik_email_unique UNIQUE(email),
    CONSTRAINT uzytkownik_rola_ck CHECK (rola IN ('standard','premium'))
);
/

CREATE TABLE Film_table OF Film (
    PRIMARY KEY (film_id),
    CONSTRAINT film_czas_trwania_ck CHECK (czas_trwania > 0),
    CONSTRAINT film_minimalny_wiek_ck CHECK (minimalny_wiek BETWEEN 0 AND 18),
    SCOPE FOR (kategoria_ref) IS Kategoria_table 
);
/

CREATE TABLE Repertuar_table OF Repertuar (
    PRIMARY KEY (repertuar_id),
    SCOPE FOR (film_ref) IS Film_table,          
    SCOPE FOR (sala_ref) IS Sala_table           
);
/
CREATE TABLE Rezerwacja_table OF Rezerwacja (
    PRIMARY KEY (rezerwacja_id),
    CONSTRAINT rezerwacja_cena_laczna_ck CHECK (cena_laczna > 0),
    CONSTRAINT rezerwacja_czy_anulowane_ck CHECK (czy_anulowane IN (0, 1)),
    SCOPE FOR (repertuar_ref) IS Repertuar_table, 
    SCOPE FOR (uzytkownik_ref) IS Uzytkownik_table 
) NESTED TABLE bilety STORE AS bilety_nt;
/

-- Triggery
CREATE OR REPLACE TRIGGER trg_uzytkownik_age
BEFORE INSERT OR UPDATE ON Uzytkownik_table
FOR EACH ROW
BEGIN
    IF :NEW.data_urodzenia > ADD_MONTHS(SYSDATE, -12*15) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Uzytkownik musi miec co najmniej 15 lat.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER trg_kategoria_id
BEFORE INSERT ON Kategoria_table
FOR EACH ROW
BEGIN
    :NEW.kategoria_id := kategoria_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER trg_sala_id
BEFORE INSERT ON Sala_table
FOR EACH ROW
BEGIN
    :NEW.sala_id := sala_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER trg_uzytkownik_id
BEFORE INSERT ON Uzytkownik_table
FOR EACH ROW
BEGIN
    :NEW.user_id := uzytkownik_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER trg_film_id
BEFORE INSERT ON Film_table
FOR EACH ROW
BEGIN
    :NEW.film_id := film_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER trg_repertuar_id
BEFORE INSERT ON Repertuar_table
FOR EACH ROW
BEGIN
    :NEW.repertuar_id := repertuar_seq.NEXTVAL;
END;
/

CREATE OR REPLACE TRIGGER trg_rezerwacja_id
BEFORE INSERT ON Rezerwacja_table
FOR EACH ROW
BEGIN
    :NEW.rezerwacja_id := rezerwacja_seq.NEXTVAL;
END;
/


CREATE OR REPLACE TYPE BODY Repertuar AS
    MEMBER FUNCTION data_zakonczenia RETURN DATE IS
        czas_trwania NUMBER;
    BEGIN
        SELECT f.czas_trwania INTO czas_trwania
        FROM Film_table f
        WHERE REF(f) = film_ref;
        
        RETURN data_rozpoczecia + (czas_trwania + 30)/1440; --(24h w minutach)
    END;
END;
/

CREATE OR REPLACE TRIGGER release_seat_on_cancel
AFTER UPDATE OF czy_anulowane ON Rezerwacja_table
FOR EACH ROW
WHEN (NEW.czy_anulowane = 1)
DECLARE
    sala_id NUMBER;
BEGIN
    -- pobieranie id sali
    SELECT DEREF(:NEW.repertuar_ref).sala_ref.sala_id INTO sala_id
    FROM DUAL;

    -- Zwolnienie miejsc
    FOR bilet IN (SELECT b.rzad, b.miejsce FROM TABLE(:OLD.bilety) b) 
    LOOP
        UPDATE TABLE(SELECT s.miejsca FROM Sala_table s WHERE s.sala_id = sala_id) m
        SET m.czy_zajete = 0
        WHERE m.rzad = bilet.rzad AND m.numer = bilet.miejsce;
    END LOOP;
END;
/