-- Typy podstawowe
CREATE TYPE Rola AS OBJECT (
    rola_id NUMBER PRIMARY KEY,
    nazwa VARCHAR2(50) -- u¿ytkownik zwyk³y albo premium, który ma 10% zni¿ki
);
/

CREATE TYPE Kategoria AS OBJECT (
    kategoria_id NUMBER PRIMARY KEY,
    nazwa VARCHAR2(100)
);
/

-- Typ u¿ytkownika
CREATE TYPE U¿ytkownik AS OBJECT (
    user_id NUMBER PRIMARY KEY,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    wiek NUMBER,
    email VARCHAR2(100),
    rola_ref REF Rola
);
/

-- Typ filmu
CREATE TYPE Film AS OBJECT (
    film_id NUMBER PRIMARY KEY,
    tytu³ VARCHAR2(200),
    czas_trwania NUMBER,
    minimalny_wiek NUMBER,
    kategoria_ref REF Kategoria
);
/

-- Typ Sala
CREATE TYPE Sala AS OBJECT (
    sala_id NUMBER PRIMARY KEY,
    nazwa VARCHAR2(50),
    miejsca Miejsce_REF NESTED TABLE
) NESTED TABLE miejsca STORE AS Miejsca_Sala_Nested;
/
  
-- Typ Miejsce
CREATE TYPE Miejsce AS OBJECT (
    miejsce_id NUMBER PRIMARY KEY,
    rzad NUMBER,
    numer NUMBER
);
/

CREATE TYPE Miejsce_REF AS REF Miejsce;
/

-- Typ Repertuar
CREATE TYPE Repertuar AS OBJECT (
    repertuar_id NUMBER PRIMARY KEY,
    film_ref REF Film,
    sala_ref REF Sala,
    data_rozpoczecia DATE,
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER,
    MEMBER FUNCTION data_zakonczenia RETURN DATE
);
/

-- Typ Bilet
CREATE TYPE Bilet AS OBJECT (
    bilet_id NUMBER PRIMARY KEY,
    cena NUMBER(5,2),
    rezerwacja_ref REF Rezerwacja,
    seans_ref REF Repertuar,
    miejsce_ref REF Miejsce,
    MEMBER FUNCTION data_seansu RETURN DATE
);
/

-- Typ Bilety_Typ
CREATE TYPE Bilety_Typ AS TABLE OF REF Bilet;
/

-- Typ Rezerwacja
CREATE TYPE Rezerwacja AS OBJECT (
    rezerwacja_id NUMBER PRIMARY KEY,
    data_rezerwacji DATE, -- nie mo¿na rezerwowaæ biletów na seans, który siê zacz¹³
    cena_laczna NUMBER,
    status_platnosci NUMBER, -- 0 - nieop³acone  1 - op³acone  2 - anulowane
    repertuar_ref REF Repertuar,
    u¿ytkownik_ref REF U¿ytkownik,
    bilety Bilety_Typ
) NESTED TABLE bilety STORE AS Bilety_Nested;
/


-- cia³o repertuaru

CREATE OR REPLACE TYPE BODY Repertuar AS
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER IS
        v_ilosc NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_ilosc
        FROM Bilet_table b
        WHERE b.seans_ref = SELF;
        RETURN v_ilosc;
    END ilosc_miejsc_zajetych;
    
    MEMBER FUNCTION data_zakonczenia RETURN DATE IS
        v_data DATE;
    BEGIN
        -- Przyk³adowa logika: dodaj czas trwania filmu do daty rozpoczêcia
        SELECT f.czas_trwania INTO v_data
        FROM Film_table f
        WHERE REF(f) = SELF.film_ref;
        
        -- Zak³adam, ¿e `data_zakonczenia` to `data_rozpoczecia` + `czas_trwania` w minutach
        RETURN SELF.data_rozpoczecia + (f.czas_trwania / (24*60));
    END data_zakonczenia;
END;
/


-- cia³o biletu

CREATE OR REPLACE TYPE BODY Bilet AS
    MEMBER FUNCTION data_seansu RETURN DATE IS
        v_data DATE;
    BEGIN
        SELECT r.data_rozpoczecia INTO v_data
        FROM Repertuar_table r
        WHERE REF(r) = seans_ref;
        RETURN v_data;
    END data_seansu;
END;
/


-- tabele
-- Tabela Rola
CREATE TABLE Rola_table OF Rola (
    PRIMARY KEY (rola_id)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Kategoria
CREATE TABLE Kategoria_table OF Kategoria (
    PRIMARY KEY (kategoria_id)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela U¿ytkownik
CREATE TABLE U¿ytkownik_table OF U¿ytkownik (
    PRIMARY KEY (user_id),
    FOREIGN KEY (rola_ref) REFERENCES Rola_table
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Film
CREATE TABLE Film_table OF Film (
    PRIMARY KEY (film_id),
    FOREIGN KEY (kategoria_ref) REFERENCES Kategoria_table
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Sala
CREATE TABLE Sala_table OF Sala (
    PRIMARY KEY (sala_id)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Miejsce
CREATE TABLE Miejsce_table OF Miejsce (
    PRIMARY KEY (miejsce_id),
    FOREIGN KEY (sala_ref) REFERENCES Sala_table
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Repertuar
CREATE TABLE Repertuar_table OF Repertuar (
    PRIMARY KEY (repertuar_id),
    FOREIGN KEY (film_ref) REFERENCES Film_table,
    FOREIGN KEY (sala_ref) REFERENCES Sala_table
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Rezerwacja
CREATE TABLE Rezerwacja_table OF Rezerwacja (
    PRIMARY KEY (rezerwacja_id),
    FOREIGN KEY (repertuar_ref) REFERENCES Repertuar_table,
    FOREIGN KEY (u¿ytkownik_ref) REFERENCES U¿ytkownik_table,
    CHECK (status_platnosci IN (0, 1, 2))
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tabela Bilet
CREATE TABLE Bilet_table OF Bilet (
    PRIMARY KEY (bilet_id),
    FOREIGN KEY (rezerwacja_ref) REFERENCES Rezerwacja_table,
    FOREIGN KEY (seans_ref) REFERENCES Repertuar_table,
    FOREIGN KEY (miejsce_ref) REFERENCES Miejsce_table
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

