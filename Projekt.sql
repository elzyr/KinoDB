BEGIN
    -- Usuwanie tabel w odpowiedniej kolejnoœci (najbardziej zale¿ne najpierw)
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

    -- Usuwanie typów obiektów w odwrotnej kolejnoœci
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Bilety_Typ FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN -- ORA-04043: object does not exist
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE Rezerwacja FORCE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
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
END;
/


-- -------------------------------
-- Sekcja: Tworzenie typów obiektów
-- -------------------------------

-- Typ Rola
CREATE OR REPLACE TYPE Rola AS OBJECT (
    rola_id NUMBER,
    nazwa VARCHAR2(50) -- u¿ytkownik zwyk³y albo premium, który ma 10% zni¿ki
);
/

-- Typ Kategoria
CREATE OR REPLACE TYPE Kategoria AS OBJECT (
    kategoria_id NUMBER,
    nazwa VARCHAR2(100)
);
/

-- Typ Sala
CREATE OR REPLACE TYPE Sala AS OBJECT (
    sala_id NUMBER,
    nazwa VARCHAR2(50)
);
/

-- Typ Miejsce
CREATE OR REPLACE TYPE Miejsce AS OBJECT (
    miejsce_id NUMBER,
    rzad NUMBER,
    numer NUMBER,
    sala_ref REF Sala -- Referencja do Sala
);
/

-- Typ U¿ytkownik
CREATE OR REPLACE TYPE Uzytkownik AS OBJECT (
    user_id NUMBER,
    imie VARCHAR2(50),
    nazwisko VARCHAR2(50),
    wiek NUMBER,
    email VARCHAR2(100),
    rola_ref REF Rola
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

-- Typ Bilet (bez rezerwacja_ref)
CREATE OR REPLACE TYPE Bilet AS OBJECT (
    bilet_id NUMBER,
    cena NUMBER(5,2),
    seans_ref REF Repertuar,
    miejsce_ref REF Miejsce,
    MEMBER FUNCTION data_seansu RETURN DATE
);
/

-- Typ Bilety_Typ
CREATE OR REPLACE TYPE Bilety_Typ AS TABLE OF REF Bilet;
/

-- Typ Rezerwacja
CREATE OR REPLACE TYPE Rezerwacja AS OBJECT (
    rezerwacja_id NUMBER,
    data_rezerwacji DATE, -- Nie mo¿na rezerwowaæ biletów na seans, który siê zacz¹³
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

-- Typ Rola
CREATE TABLE Rola_table OF Rola (
    PRIMARY KEY (rola_id),
    CONSTRAINT rola_nazwa_ck CHECK (nazwa IN ('standard', 'premium'))
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ Kategoria
CREATE TABLE Kategoria_table OF Kategoria (
    PRIMARY KEY (kategoria_id),
    CONSTRAINT kategoria_nazwa_ck CHECK (nazwa IS NOT NULL)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ Sala
CREATE TABLE Sala_table OF Sala (
    PRIMARY KEY (sala_id),
    CONSTRAINT sala_nazwa_ck CHECK (nazwa IS NOT NULL)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Tworzenie tabeli Miejsce_table bez ponownego definiowania sala_ref
CREATE TABLE Miejsce_table OF Miejsce (
    PRIMARY KEY (miejsce_id),
    CONSTRAINT miejsce_rzad_ck CHECK (rzad > 0),
    CONSTRAINT miejsce_numer_ck CHECK (numer > 0)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ U¿ytkownik
CREATE TABLE Uzytkownik_table OF Uzytkownik (
    PRIMARY KEY (user_id),
    CONSTRAINT uzytkownik_email_unique UNIQUE(email),
    CONSTRAINT uzytkownik_wiek_ck CHECK (wiek > 15)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ Film
CREATE TABLE Film_table OF Film (
    PRIMARY KEY (film_id),
    CONSTRAINT film_czas_trwania_ck CHECK (czas_trwania > 0),
    CONSTRAINT film_minimalny_wiek_ck CHECK (minimalny_wiek >= 3 AND minimalny_wiek <= 18)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ Repertuar (Poprawiona Definicja)
CREATE TABLE Repertuar_table OF Repertuar (
    PRIMARY KEY (repertuar_id)
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ Bilet (bez rezerwacja_ref)
CREATE TABLE Bilet_table OF Bilet (
    PRIMARY KEY (bilet_id),
    CONSTRAINT bilet_cena_ck CHECK (cena > 0),
    FOREIGN KEY (seans_ref) REFERENCES Repertuar_table,
    FOREIGN KEY (miejsce_ref) REFERENCES Miejsce_table
) OBJECT IDENTIFIER IS PRIMARY KEY;
/

-- Typ Rezerwacja
CREATE TABLE Rezerwacja_table OF Rezerwacja (
    PRIMARY KEY (rezerwacja_id),
    -- Dodaj dodatkowe ograniczenia bez okreœlania typu danych
    CONSTRAINT rezerwacja_cena_laczna_ck CHECK (cena_laczna > 0),
    CONSTRAINT rezerwacja_czy_anulowane_ck CHECK (czy_anulowane IN (0, 1))
) OBJECT IDENTIFIER IS PRIMARY KEY
NESTED TABLE bilety STORE AS bilety_nt;
/

-- -------------------------------
-- Sekcja: Tworzenie cia³ typów obiektów
-- -------------------------------

-- Cia³o Repertuaru
CREATE OR REPLACE TYPE BODY Repertuar AS
    MEMBER FUNCTION ilosc_miejsc_zajetych RETURN NUMBER IS
        v_ilosc NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_ilosc
        FROM Bilet_table b
        WHERE b.seans_ref = REF(SELF);
        RETURN v_ilosc;
    END ilosc_miejsc_zajetych;
        
    MEMBER FUNCTION data_zakonczenia RETURN DATE IS
        v_czas_trwania NUMBER;
    BEGIN
        SELECT f.czas_trwania INTO v_czas_trwania
        FROM Film_table f
        WHERE REF(f) = SELF.film_ref;
    
        RETURN SELF.data_rozpoczecia + (v_czas_trwania / (24 * 60)); -- Zak³adam czas trwania w minutach
    END data_zakonczenia;
END;
/
    
-- Cia³o Biletu
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
    -- Pobierz datê rozpoczêcia repertuaru
    SELECT r.data_rozpoczecia INTO v_data_rozpoczecia
    FROM Repertuar_table r
    WHERE r.repertuar_id = :NEW.repertuar_ref.repertuar_id;
    
    -- SprawdŸ, czy data rezerwacji jest wczeœniejsza ni¿ rozpoczêcie repertuaru minus 1 godzina
    IF :NEW.data_rezerwacji > (v_data_rozpoczecia - (1/24)) THEN
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
    TYPE ref_bilet_table_type IS TABLE OF REF Bilet;
    ref_bilet_table ref_bilet_table_type := :NEW.bilety;
BEGIN
    -- Usuwanie ka¿dego biletu z kolekcji bilety
    FOR i IN 1 .. ref_bilet_table.COUNT LOOP
        DELETE FROM Bilet_table WHERE REF(bilet_table) = ref_bilet_table(i);
    END LOOP;
END;
/
        
-- Wyzwalacz na unikalnoœæ seansów w sali
CREATE OR REPLACE TRIGGER ensure_unique_seans_per_sala
BEFORE INSERT OR UPDATE ON Repertuar_table
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
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
        v_prev_numer NUMBER := NULL;
        v_count_sequential NUMBER := 0;
        v_miejsce_id NUMBER;
        v_rzad NUMBER;
        v_numer NUMBER;
    BEGIN
        OPEN v_miejsca FOR
            SELECT m.miejsce_id, m.rzad, m.numer
            FROM Miejsce_table m
            WHERE m.miejsce_id NOT IN (
                SELECT b.miejsce_ref.miejsce_id
                FROM Bilet_table b
                WHERE b.seans_ref = p_repertuar
            )
            AND (p_preferencja_rzad IS NULL OR m.rzad = p_preferencja_rzad)
            ORDER BY m.rzad, m.numer;

        LOOP
            FETCH v_miejsca INTO v_miejsce_id, v_rzad, v_numer;
            EXIT WHEN v_miejsca%NOTFOUND;

            IF v_prev_numer IS NULL THEN
                v_count_sequential := 1;
            ELSIF v_numer = v_prev_numer + 1 THEN
                v_count_sequential := v_count_sequential + 1;
            ELSE
                v_count_sequential := 1;
            END IF;

            IF v_count_sequential = p_ilosc THEN
                RETURN TRUE;
            END IF;

            v_prev_numer := v_numer;
        END LOOP;

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
        v_miejsca SYS_REFCURSOR;
        v_miejsce_id NUMBER;
        v_rzad NUMBER;
        v_numer NUMBER;
    BEGIN
        -- SprawdŸ u¿ytkownika
        SprawdzUzytkownika(p_email, v_uzytkownik);

        -- SprawdŸ film
        SprawdzFilm(p_film_tytul, v_film);

        -- SprawdŸ wiek u¿ytkownika wzglêdem wymagañ filmu
        SprawdzWiekUzytkownika(v_uzytkownik, v_film);

        -- Pobierz zni¿kê dla u¿ytkownika
        SELECT CASE WHEN r.nazwa = 'premium' THEN 0.9 ELSE 1 END
        INTO v_znizka
        FROM Rola_table r
        WHERE REF(r) = (SELECT u.rola_ref FROM Uzytkownik_table u WHERE REF(u) = v_uzytkownik);

        -- Szukaj seansów i miejsc
        FOR seans IN (
            SELECT REF(r) AS repertuar_ref
            FROM Repertuar_table r
            WHERE r.film_ref = v_film
              AND r.data_rozpoczecia > SYSDATE
            ORDER BY r.data_rozpoczecia
        ) LOOP
            IF SprawdzDostepneMiejsca(seans.repertuar_ref, p_preferencja_rzad, p_ilosc, v_miejsca) THEN
                -- Twórz rezerwacjê
                SELECT NVL(MAX(rezerwacja_id), 0) + 1 INTO v_rezerwacja_id FROM Rezerwacja_table;

                INSERT INTO Rezerwacja_table
                VALUES (
                    Rezerwacja(v_rezerwacja_id, SYSDATE, 0, 0, seans.repertuar_ref, v_uzytkownik, Bilety_Typ())
                );

                -- Pobierz referencjê do nowo utworzonej rezerwacji
                SELECT REF(r) INTO v_rezerwacja_ref
                FROM Rezerwacja_table r
                WHERE r.rezerwacja_id = v_rezerwacja_id;

                -- Wstawienie biletów i aktualizacja kolekcji bilety w rezerwacji
                FOR i IN 1..p_ilosc LOOP
                    FETCH v_miejsca INTO v_miejsce_id, v_rzad, v_numer;
                    EXIT WHEN v_miejsca%NOTFOUND;

                    -- Wstaw bilet
                    INSERT INTO Bilet_table VALUES (
                        Bilet(Bilet_SEQ.NEXTVAL, v_cena * v_znizka, seans.repertuar_ref, 
                              (SELECT REF(m) FROM Miejsce_table m WHERE m.miejsce_id = v_miejsce_id))
                    );

                    -- Dodaj REF Biletu do kolekcji bilety w Rezerwacji
                    UPDATE Rezerwacja_table
                    SET bilety = bilety MULTISET UNION
                        (SELECT REF(b) FROM Bilet_table b WHERE b.bilet_id = Bilet_SEQ.CURRVAL)
                    WHERE rezerwacja_id = v_rezerwacja_id;
                END LOOP;

                -- Aktualizuj cenê rezerwacji
                UPDATE Rezerwacja_table
                SET cena_laczna = v_cena * p_ilosc * v_znizka
                WHERE rezerwacja_id = v_rezerwacja_id;

                COMMIT;
                RETURN;
            END IF;
        END LOOP;

        RAISE_APPLICATION_ERROR(-20003, 'Nie znaleziono odpowiedniego seansu z wystarczaj¹c¹ liczb¹ miejsc obok siebie.');
    END UtworzRezerwacje;
END Rezerwacja_Pkg;
/
        
CREATE OR REPLACE PACKAGE AnulujRezerwacje_Pkg AS
    PROCEDURE AnulujRezerwacje (p_rezerwacja_id NUMBER);
END AnulujRezerwacje_Pkg;
/
        
CREATE OR REPLACE PACKAGE BODY AnulujRezerwacje_Pkg AS
    PROCEDURE AnulujRezerwacje (p_rezerwacja_id NUMBER) IS
    BEGIN
        -- Aktualizuj rezerwacjê na anulowan¹
        UPDATE Rezerwacja_table
        SET czy_anulowane = 1
        WHERE rezerwacja_id = p_rezerwacja_id;

        -- Usuwanie biletów powi¹zanych z rezerwacj¹ jest obs³ugiwane przez wyzwalacz
        COMMIT;
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
            DBMS_OUTPUT.PUT_LINE('Seans ID: ' || r.repertuar_id || ', Film: ' || r.tytul || ', Data: ' || r.data_rozpoczecia || ', Sala: ' || r.nazwa);
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
        -- Pobierz referencje do filmu i sali
        SELECT REF(f) INTO v_film FROM Film_table f WHERE f.film_id = p_film_id;
        SELECT REF(s) INTO v_sala FROM Sala_table s WHERE s.sala_id = p_sala_id;

        -- Pobierz nowe ID dla repertuaru
        SELECT NVL(MAX(repertuar_id), 0) + 1 INTO v_new_repertuar_id FROM Repertuar_table;

        BEGIN
            -- Dodaj seans
            INSERT INTO Repertuar_table
            VALUES (
                Repertuar(v_new_repertuar_id, v_film, v_sala, p_data_rozpoczecia)
            );

            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Seans zosta³ pomyœlnie dodany: ID ' || v_new_repertuar_id);
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE_APPLICATION_ERROR(-20006, 'Nie uda³o siê dodaæ seansu. Przyczyna: ' || SQLERRM);
        END;
    END DodajSeans;
END Repertuar_Pkg;
/

-- Tworzenie sekwencji dla biletów
CREATE SEQUENCE Bilet_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
/

-- -------------------------------
-- Sekcja: Inicjalizacja danych
-- -------------------------------

-- Dodanie ról
INSERT INTO Rola_table VALUES (Rola(1, 'standard'));
INSERT INTO Rola_table VALUES (Rola(2, 'premium'));

-- Dodanie kategorii
INSERT INTO Kategoria_table VALUES (Kategoria(1, 'Komedia'));
INSERT INTO Kategoria_table VALUES (Kategoria(2, 'Dramat'));
INSERT INTO Kategoria_table VALUES (Kategoria(3, 'Horror'));
INSERT INTO Kategoria_table VALUES (Kategoria(4, 'Akcja'));
INSERT INTO Kategoria_table VALUES (Kategoria(5, 'Animacja'));

-- Dodanie sal
INSERT INTO Sala_table VALUES (Sala(1, 'Sala A'));
INSERT INTO Sala_table VALUES (Sala(2, 'Sala B'));
INSERT INTO Sala_table VALUES (Sala(3, 'Sala C'));
INSERT INTO Sala_table VALUES (Sala(4, 'Sala D'));
INSERT INTO Sala_table VALUES (Sala(5, 'Sala E'));

-- Dodanie u¿ytkowników w ró¿nych grupach wiekowych
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(1, 'Jan', 'Kowalski', 12, 'jan.kowalski@example.com', 
    (SELECT REF(r) FROM Rola_table r WHERE r.rola_id = 1))
);
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(2, 'Anna', 'Nowak', 18, 'anna.nowak@example.com', 
    (SELECT REF(r) FROM Rola_table r WHERE r.rola_id = 2))
);
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(3, 'Piotr', 'Wiœniewski', 25, 'piotr.wisniewski@example.com', 
    (SELECT REF(r) FROM Rola_table r WHERE r.rola_id = 1))
);
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(4, 'Kasia', 'Zalewska', 16, 'kasia.zalewska@example.com', 
    (SELECT REF(r) FROM Rola_table r WHERE r.rola_id = 2))
);
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(5, 'Marek', 'Szymañski', 30, 'marek.szymanski@example.com', 
    (SELECT REF(r) FROM Rola_table r WHERE r.rola_id = 1))
);

-- Dodanie filmów z wymaganiami wiekowymi
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
    Repertuar_Pkg.DodajSeans(1, 1, TO_DATE('2025-01-15 10:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(2, 2, TO_DATE('2025-01-15 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(3, 3, TO_DATE('2025-01-15 14:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(4, 4, TO_DATE('2025-01-15 16:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(5, 5, TO_DATE('2025-01-15 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));
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
