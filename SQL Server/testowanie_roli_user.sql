USE KinoDB;
GO

SELECT * FROM dbo.klient_PokazSeanse;
go

select * from uzytkownicy -- error brak dostepu

INSERT INTO Uzytkownicy
 (imie, nazwisko, data_urodzenia, email, rola)
VALUES
 (N'Marcin', N'Nowak', '2002-05-22', N'marcin.k@example.com', N'standard');
GO

  EXEC dbo.klient_ZarezerwujSeans
  @Email = N'marcin.k@example.com',
  @TytulFilmu = N'Kraina Lodu',
  @DataSeansu = '2026-01-02 22:00',
  @PreferencjaRzad = 2,
  @IloscMiejsc = 1;



SELECT * FROM dbo.klient_PokazRezerwacje;
GO


EXEC dbo.klient_AnulujRezerwacje
  @Email = N'marcin.k@example.com',
  @TytulFilmu = N'Kraina Lodu',
  @DataSeansu = '2026-01-02 22:00';
GO

SELECT * FROM dbo.klient_PokazRezerwacje;
GO
