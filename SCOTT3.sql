-- typy obiektów
-- -------------------------------

CREATE OR REPLACE TYPE Kategoria AS OBJECT (
    kategoria_id NUMBER,
    nazwa VARCHAR2(100)
);


CREATE OR REPLACE TYPE Miejsce AS OBJECT (
    miejsce_id NUMBER,
    rzad NUMBER,
    numer NUMBER,
    czy_zajete NUMBER
);


CREATE OR REPLACE TYPE Miejsca_Typ AS TABLE OF Miejsce;

CREATE OR REPLACE TYPE Sala AS OBJECT (
    sala_id NUMBER,
    nazwa VARCHAR2(50),
    miejsca Miejsca_Typ
);


CREATE OR REPLACE TYPE Uzytkownik AS OBJECT (
    user_id NUMBER,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    wiek NUMBER,
    email VARCHAR2(100),
    rola VARCHAR2(50)
);

CREATE OR REPLACE TYPE Film AS OBJECT (
    film_id NUMBER,
    tytul VARCHAR2(200),
    czas_trwania NUMBER,  -- w minutach
    minimalny_wiek NUMBER,
    kategoria_ref REF Kategoria
);

CREATE OR REPLACE TYPE Repertuar AS OBJECT (
    repertuar_id NUMBER,
    film_ref REF Film,
    sala_ref REF Sala,
    data_rozpoczecia DATE,
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER,
    MEMBER FUNCTION data_zakonczenia RETURN DATE
);

CREATE OR REPLACE TYPE Bilet AS OBJECT (
    bilet_id NUMBER,
    cena NUMBER(5,2),
    seans_ref REF Repertuar,
    rzad NUMBER,
    miejsce NUMBER,
    MEMBER FUNCTION data_seansu RETURN DATE
);

CREATE OR REPLACE TYPE Bilety_Typ AS TABLE OF REF Bilet;

CREATE OR REPLACE TYPE Rezerwacja AS OBJECT (
    rezerwacja_id NUMBER,
    data_rezerwacji DATE, a
    cena_laczna NUMBER,
    czy_anulowane NUMBER,  -- 0 - oplacone, 1 - anulowane
    repertuar_ref REF Repertuar,
    uzytkownik_ref REF Uzytkownik,
    bilety Bilety_Typ
);
/


-- -------------------------------
-- tabele
-- -------------------------------

CREATE TABLE Kategoria_table OF Kategoria (
    PRIMARY KEY (kategoria_id),
    CONSTRAINT kategoria_nazwa_ck CHECK (nazwa IS NOT NULL)
);

CREATE TABLE Sala_table OF Sala (
    PRIMARY KEY (sala_id),
    CONSTRAINT sala_nazwa_ck CHECK (nazwa IS NOT NULL)
)NESTED TABLE miejsca STORE AS miejsca_nt;

CREATE TABLE Miejsce_table OF Miejsce
(
  primary key (miejsce_id),
  CONSTRAINT miejsce_rzad_ck CHECK (rzad > 0),
  CONSTRAINT miejsce_numer_ck CHECK (numer > 0)
)
OBJECT IDENTIFIER IS PRIMARY KEY;

CREATE TABLE Uzytkownik_table OF Uzytkownik (
    PRIMARY KEY (user_id),
    CONSTRAINT uzytkownik_email_unique UNIQUE(email),
    CONSTRAINT uzytkownik_wiek_ck CHECK (wiek > 15),
    CONSTRAINT uzytkownik_rola_ck CHECK (rola IN ('standard','premium'))
);

CREATE TABLE Film_table OF Film (
    PRIMARY KEY (film_id),
    CONSTRAINT film_czas_trwania_ck CHECK (czas_trwania > 0),
    CONSTRAINT film_minimalny_wiek_ck CHECK (minimalny_wiek >= 0 AND minimalny_wiek <= 18)
);


CREATE TABLE Repertuar_table OF Repertuar (
    PRIMARY KEY (repertuar_id)
);

CREATE TABLE Bilet_table OF Bilet (
    PRIMARY KEY (bilet_id),
    SCOPE FOR (seans_ref) IS repertuar_table,
    CONSTRAINT bilet_cena_ck CHECK (cena > 0)
) OBJECT IDENTIFIER IS PRIMARY KEY;

CREATE TABLE Rezerwacja_table OF Rezerwacja (
    PRIMARY KEY (rezerwacja_id),
    SCOPE FOR(repertuar_ref) is repertuar_table,
    SCOPE FOR(uzytkownik_ref) is uzytkownik_table,
    CONSTRAINT rezerwacja_cena_laczna_ck CHECK (cena_laczna > 0),
    CONSTRAINT rezerwacja_czy_anulowane_ck CHECK (czy_anulowane IN (0, 1))
) OBJECT IDENTIFIER IS PRIMARY KEY
NESTED TABLE bilety STORE AS bilety_nt;



-- -------------------------------
-- ciala obiektow
-- -------------------------------
CREATE OR REPLACE TYPE BODY Repertuar AS
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER IS
        ilosc NUMBER;
        sala_filmu NUMBER;
    BEGIN
        SELECT s.sala_id
          INTO sala_filmu
          FROM Sala_table s
         WHERE REF(s) = SELF.sala_ref;

        SELECT COUNT(*)
          INTO ilosc
          FROM TABLE(
              SELECT s.miejsca 
              FROM Sala_table s
              WHERE s.sala_id = sala_filmu
          )
         WHERE czy_zajete = 1;

        RETURN ilosc;
    END ilosc_miejsc_zajetych;

    MEMBER FUNCTION data_zakonczenia RETURN DATE IS
        v_czas_trwania NUMBER;
    BEGIN
        SELECT f.czas_trwania 
          INTO v_czas_trwania
          FROM Film_table f
         WHERE REF(f) = SELF.film_ref;
        RETURN SELF.data_rozpoczecia + (v_czas_trwania / (24 * 60));
    END data_zakonczenia;
END;


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



-- -------------------------------
-- wyzwalacze
-- -------------------------------

CREATE OR REPLACE TRIGGER trg_rezerwacja_data
BEFORE INSERT OR UPDATE ON Rezerwacja_table
FOR EACH ROW
DECLARE
    data_roz DATE;
BEGIN
    BEGIN
        SELECT r.data_rozpoczecia 
        INTO data_roz
        FROM Repertuar_table r
        WHERE REF(r) = :NEW.repertuar_ref;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono repertuaru dla wskazanej rezerwacji');
    END;
    IF :NEW.data_rezerwacji > data_roz THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie mozna rezerwowa? biletow na seans, ktory juz sie zaczal');
    END IF;
END;
        
-- Wyzwalacz na zwalnianie miejsc przy anulowaniu rezerwacji
CREATE OR REPLACE TRIGGER release_seat_on_cancel
AFTER UPDATE OF czy_anulowane ON Rezerwacja_table
FOR EACH ROW
WHEN (NEW.czy_anulowane = 1)
DECLARE
    sala_filmu NUMBER;
    znaleziony_rzad NUMBER;
    znaleziony_numer NUMBER;
BEGIN
    SELECT r.sala_ref.sala_id
      INTO sala_filmu
      FROM Repertuar_table r
     WHERE REF(r) = :OLD.repertuar_ref;

    FOR miejsce_rec IN (
        SELECT COLUMN_VALUE AS bilet_ref
        FROM TABLE(:OLD.bilety)
    ) LOOP
        SELECT b.rzad, b.miejsce
          INTO znaleziony_rzad, znaleziony_numer
          FROM Bilet_table b
         WHERE REF(b) = miejsce_rec.bilet_ref;
        UPDATE TABLE(SELECT s.miejsca 
                     FROM Sala_table s 
                     WHERE s.sala_id = sala_filmu)
        SET czy_zajete = 0
        WHERE rzad = znaleziony_rzad AND numer = znaleziony_numer;
    END LOOP;
    DELETE FROM Bilet_table b
    WHERE REF(b) IN (
        SELECT COLUMN_VALUE 
        FROM TABLE(:OLD.bilety)
    );
END;




        
-- Wyzwalacz na unikalnosci seansow w sali
CREATE OR REPLACE TRIGGER ensure_unique_seans_per_sala
BEFORE INSERT OR UPDATE ON Repertuar_table
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM Repertuar_table r
     WHERE r.sala_ref = :NEW.sala_ref
       AND r.data_rozpoczecia = :NEW.data_rozpoczecia
       AND r.repertuar_id != :NEW.repertuar_id;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'W jednej sali w tym samym czasie mo?e by? tylko jeden seans.');
    END IF;
END;
