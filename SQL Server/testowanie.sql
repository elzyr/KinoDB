use kinoDB;
go

insert into dbo.Kina (nazwa) values ('kinolodz');
go

INSERT INTO dbo.Uzytkownicy
       (imie , nazwisko , data_urodzenia ,          email             , rola)
VALUES (N'Jan', N'Kowalski', '2000-05-22', N'jan.k@example.com', N'premium');
GO

EXEC dbo.ZarezerwujSeans
  @UserId          = 1,
  @TytulFilmu      = N'The Conjuring',
  @DataSeansu      = '2026-01-02 10:00',
  @PreferencjaRzad = 2,
  @IloscMiejsc     = 10,
  @KinoID          = 1; -- lodz
GO

EXEC dbo.AnulujRezerwacje
  @UserId     = 1,
  @TytulFilmu = N'The Conjuring',
  @DataSeansu = '2026-01-02 10:00',
  @KinoID     = 1;
GO

SELECT * FROM dbo.v_rezerwacje;
GO
