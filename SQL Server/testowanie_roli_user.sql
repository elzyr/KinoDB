USE KinoDB;
GO

SELECT * FROM dbo.klient_PokazSeanse;
go

INSERT INTO Uzytkownicy
 (imie, nazwisko, data_urodzenia, email, rola)
VALUES
 (N'Marcin', N'Nowak', '2002-05-22', N'marcin.k@example.com', N'standard');
GO

EXEC dbo.klient_ZarezerwujSeans
  @UserId = 1,
  @TytulFilmu = N'The Conjuring',
  @DataSeansu = '2026-01-02 10:00',
  @PreferencjaRzad = 2,
  @IloscMiejsc = 1;

  EXEC dbo.klient_ZarezerwujSeans
  @UserId = 1,
  @TytulFilmu = N'Kraina Lodu',
  @DataSeansu = '2026-01-02 22:00',
  @PreferencjaRzad = 2,
  @IloscMiejsc = 1;


SELECT * FROM dbo.klient_PokazRezerwacje;
GO


EXEC dbo.klient_AnulujRezerwacje
  @UserId = 1,
  @TytulFilmu = N'Kraina Lodu',
  @DataSeansu = '2026-01-02 22:00';
GO

SELECT * FROM dbo.klient_PokazRezerwacje;
GO
