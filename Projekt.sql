-- Dodanie u�ytkownik�w
INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(1, 'Jan', 'Kowalski', 16, 'jan.kowalski@example.com', 'standard')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(2, 'Anna', 'Nowak', 18, 'anna.nowak@example.com', 'premium')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(3, 'Piotr', 'Wi�niewski', 25, 'piotr.wisniewski@example.com', 'standard')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(4, 'Kasia', 'Zalewska', 16, 'kasia.zalewska@example.com', 'premium')
);

INSERT INTO Uzytkownik_table VALUES (
    Uzytkownik(5, 'Marek', 'Szyma�ski', 30, 'marek.szymanski@example.com', 'standard')
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

-- Dodanie film�w
INSERT INTO Film_table VALUES (
    Film(1, 'Komedia na weekend', 90, 0, 
    (SELECT REF(k) FROM Kategoria_table k WHERE k.kategoria_id = 1))
);

INSERT INTO Film_table VALUES (
    Film(2, 'Dramat �ycia', 120, 12, 
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

-- Dodanie seans�w za pomoc� pakietu Repertuar_Pkg
BEGIN
    Repertuar_Pkg.DodajSeans(1, 1, TO_DATE('2025-03-20 10:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(2, 2, TO_DATE('2025-03-21 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(3, 3, TO_DATE('2025-03-17 14:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(4, 4, TO_DATE('2025-03-18 16:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    Repertuar_Pkg.DodajSeans(5, 5, TO_DATE('2025-03-19 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));
END;
/
SELECT r.repertuar_id, r.data_rozpoczecia, r.film_ref, r.sala_ref
FROM Repertuar_table r;

-- Testowanie rezerwacji
BEGIN
    Rezerwacja_Pkg.UtworzRezerwacje('jan.kowalski@example.com', 'Komedia na weekend', 2, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('anna.nowak@example.com', 'Horror w lesie', 3, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('piotr.wisniewski@example.com', 'Dramat �ycia', 1, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('kasia.zalewska@example.com', 'Akcja bez granic', 2, NULL);
    Rezerwacja_Pkg.UtworzRezerwacje('marek.szymanski@example.com', 'Animacja dla dzieci', 4, NULL);
END;
/

BEGIN
    Rezerwacja_Pkg.UtworzRezerwacje('jan.kowalski@example.com', 'Komedia na weekend', 2, NULL);
END;
/

