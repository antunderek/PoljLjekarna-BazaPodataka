-------------------------------------------------------------------------------------------------------
-- TABLICE --
-------------------------------------------------------------------------------------------------------
CREATE TABLE djelatnik(
    OIB CHAR(11),
    ime NVARCHAR(30) NOT NULL,
    prezime NVARCHAR(30) NOT NULL,
    uloga NCHAR(17) DEFAULT 'RADNIK',
    placa DECIMAL(7, 2) NOT NULL,
    broj_telefona CHAR(10),
	aktivan CHAR(2) DEFAULT 'DA',
    CONSTRAINT pk_djelatnik PRIMARY KEY (OIB),
    CONSTRAINT chk_djelatnik CHECK (uloga IN ('ŠEF', 'RADNIK', 'PRIVREMENI RADNIK')),
	CONSTRAINT chk_status CHECK (aktivan IN ('DA', 'NE'))
);

CREATE TABLE poslovni_partner(
    OIB CHAR(11),
    ime NVARCHAR(30) NOT NULL,
    prezime NVARCHAR(30) NOT NULL,
    pbr CHAR(5),
    mjesto NVARCHAR(30),
    adresa NVARCHAR(50),
    broj_telefona CHAR(10),
    IBAN CHAR(21),
	aktivan CHAR(2) DEFAULT 'DA',
    CONSTRAINT pk_poslPartner PRIMARY KEY (OIB),
	CONSTRAINT chk_poslPartner CHECK (aktivan IN ('DA', 'NE'))
);

CREATE TABLE dobavljac(
    OIB CHAR(11),
    naziv NVARCHAR(100) NOT NULL,
    pbr CHAR(5),
    mjesto NVARCHAR(30),
    adresa NVARCHAR(50),
    broj_telefona CHAR(10),
    IBAN CHAR(21),
	aktivan CHAR(2) DEFAULT 'DA',
    CONSTRAINT pk_dobavljac PRIMARY KEY (OIB),
	CONSTRAINT chk_dobavljac CHECK (aktivan IN ('DA', 'NE'))
);

CREATE TABLE artikl(
    sifra CHAR(5),
    naziv NVARCHAR(50),
    jedinicaMjere CHAR(3),
    kolicina INT,
    cijena DECIMAL(7, 2) NOT NULL,
    dobavljac CHAR(11),
	uprodaji CHAR(2) DEFAULT 'DA',
    CONSTRAINT chk_jedinicaMjere CHECK (jedinicaMjere IN ('kom', 'kg', 'm', 'l')),
    CONSTRAINT chk_uprodaji CHECK (uprodaji IN ('DA', 'NE')),
	CONSTRAINT pk_artikl PRIMARY KEY (sifra),
    CONSTRAINT fk_dobavljac FOREIGN KEY (dobavljac) REFERENCES dobavljac(OIB)
);

CREATE TABLE racunR2(
    sifra CHAR(5),
    djelatnik CHAR(11),
    poslovni_partner CHAR(11),
    datum_izdavanja DATETIME,
    CONSTRAINT pk_racunR2 PRIMARY KEY (sifra),
    CONSTRAINT fk_djelatnik FOREIGN KEY (djelatnik) REFERENCES djelatnik(OIB),
    CONSTRAINT fk_poslovniPartner FOREIGN KEY (poslovni_partner) REFERENCES poslovni_partner(OIB)
);

CREATE TABLE popis_robe(
    sifra INT IDENTITY(1,1),
    racun CHAR(5),
    artikl CHAR(5),
    kolicina INT,
    CONSTRAINT chk_kolicina CHECK (kolicina > 0),
    CONSTRAINT pk_sifra PRIMARY KEY (sifra),
    CONSTRAINT fk_racun FOREIGN KEY (racun) REFERENCES racunR2(sifra)
);


-------------------------------------------------------------------------------------------------------
-- FUNKCIJE --
-------------------------------------------------------------------------------------------------------

CREATE FUNCTION ukupan_iznos_racuna (@racun_sifra CHAR(5))
RETURNS FLOAT
AS
BEGIN
	DECLARE @ukupni_iznos FLOAT
	SELECT @ukupni_iznos = SUM(artikl.cijena * popis_robe.kolicina)
	FROM artikl, popis_robe, racunR2
	WHERE artikl.sifra = popis_robe.artikl
	AND popis_robe.racun = @racun_sifra
	AND @racun_sifra = racunR2.sifra
	GROUP BY popis_robe.racun;
RETURN @ukupni_iznos
END;

CREATE FUNCTION ukupan_iznos_racuna_PDV (@racun_sifra CHAR(5))
RETURNS FLOAT
AS
BEGIN
DECLARE @ukupni_iznos FLOAT
DECLARE @pdv DECIMAL (3, 2)
SET @pdv = '1.25'
SELECT @ukupni_iznos = SUM(artikl.cijena * popis_robe.kolicina) * @pdv
FROM artikl, popis_robe, racunR2
WHERE artikl.sifra = popis_robe.artikl
AND popis_robe.racun = @racun_sifra
AND @racun_sifra = racunR2.sifra;
RETURN @ukupni_iznos
END;


-------------------------------------------------------------------------------------------------------
-- POGLEDI --
-------------------------------------------------------------------------------------------------------

--ARTIKLI
CREATE VIEW stanje_skladista
AS
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB;


CREATE VIEW artikli_uprodaji
AS
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB
AND artikl.uprodaji = 'DA';


CREATE VIEW artikli_nisu_uprodaji
AS
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB
AND artikl.uprodaji = 'NE';


CREATE VIEW artikli_kojih_nema
AS
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač',
	dobavljac.broj_telefona AS 'Broj telefona'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB
AND artikl.kolicina = 0;


CREATE VIEW artikli_pri_kraju
AS
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač',
	dobavljac.broj_telefona AS 'Broj telefona'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB
AND artikl.kolicina < 6;


--DOBAVLJACI
CREATE VIEW svi_dobavljaci
AS
SELECT naziv AS 'Naziv',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN',
	aktivan AS 'Aktivan'
FROM dobavljac;


CREATE VIEW aktivni_dobavljaci
AS
SELECT naziv AS 'Naziv',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN'
FROM dobavljac
WHERE aktivan = 'DA';


CREATE VIEW neaktivni_dobavljaci
AS
SELECT naziv AS 'Naziv',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN'
FROM dobavljac
WHERE aktivan = 'NE';


--DJELATNICI
CREATE VIEW svi_djelatnici
AS
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona',
	aktivan AS 'Aktivan'
FROM djelatnik;


CREATE VIEW aktivni_djelatnici
AS
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona'
FROM djelatnik
WHERE aktivan = 'DA';


CREATE VIEW neaktivni_djelatnici
AS
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona'
FROM djelatnik
WHERE aktivan = 'NE';


CREATE VIEW sef
AS
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona',
	aktivan AS 'Aktivan'
FROM djelatnik
WHERE uloga = 'ŠEF';


CREATE VIEW radnici
AS
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona',
	aktivan AS 'Aktivan'
FROM djelatnik
WHERE uloga = 'RADNIK';


CREATE VIEW privremeni_radnici
AS
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona',
	aktivan AS 'Aktivan'
FROM djelatnik
WHERE uloga = 'PRIVREMENI RADNIK';


--POSLOVNI PARTNERI
CREATE VIEW svi_poslovni_partneri
AS
SELECT ime + ' ' + prezime AS 'Ime i prezime',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN',
	aktivan AS 'Aktivan'
FROM poslovni_partner;


CREATE VIEW aktivni_poslovni_partneri
AS
SELECT ime + ' ' + prezime AS 'Ime i prezime',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN'
FROM poslovni_partner
WHERE aktivan = 'DA';


CREATE VIEW neaktivni_poslovni_partneri
AS
SELECT ime + ' ' + prezime AS 'Ime i prezime',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN'
FROM poslovni_partner
WHERE aktivan = 'NE';


--RACUN
CREATE VIEW racuniR2
AS
SELECT DISTINCT racunR2.sifra AS 'Sifra racuna',
    dbo.ukupan_iznos_racuna(racunR2.sifra) AS 'Ukupan iznos u kn',
    djelatnik.ime + ' ' + djelatnik.prezime AS 'Izdavatelj računa',
    poslovni_partner.ime + ' ' + poslovni_partner.prezime AS 'Izdano',
    racunR2.datum_izdavanja AS 'Datuma'
FROM djelatnik, racunR2, poslovni_partner, artikl, popis_robe
WHERE artikl.sifra = popis_robe.artikl
AND popis_robe.racun = racunR2.sifra
AND racunR2.djelatnik = djelatnik.OIB
AND racunR2.poslovni_partner = poslovni_partner.OIB;


-------------------------------------------------------------------------------------------------------
-- TRIGGERI --
-------------------------------------------------------------------------------------------------------

CREATE TRIGGER unos_popisa_robe
ON popis_robe
INSTEAD OF INSERT
AS
    DECLARE @kolicina_skladiste INT
    DECLARE @sifra_artikla CHAR(5)
    DECLARE @sifra_racuna CHAR(5)
    DECLARE @kolicina INT

    SELECT @kolicina_skladiste=artikl.kolicina, @sifra_artikla = i.artikl
    FROM inserted i, artikl
    WHERE artikl.sifra = i.artikl;
    SELECT @sifra_racuna = i.racun FROM inserted i;
    SELECT @kolicina = i.kolicina FROM inserted i;

    IF @kolicina <= @kolicina_skladiste AND @kolicina > 0
    BEGIN
        UPDATE artikl SET kolicina = kolicina - @kolicina WHERE artikl.sifra = @sifra_artikla;
		IF @sifra_racuna = (SELECT popis_robe.racun FROM popis_robe WHERE popis_robe.artikl = @sifra_artikla AND @sifra_racuna = popis_robe.racun)
			UPDATE popis_robe SET kolicina = kolicina + @kolicina WHERE popis_robe.artikl = @sifra_artikla AND popis_robe.racun = @sifra_racuna;

		ELSE
        	INSERT INTO popis_robe VALUES (@sifra_racuna, @sifra_artikla, @kolicina);

	END

    ELSE
    BEGIN
        PRINT 'Navedena količina artikla nije dostupna';
    END


CREATE TRIGGER unos_robe_u_skladiste
ON artikl
INSTEAD OF INSERT
AS
	DECLARE @sifra CHAR(5)
	DECLARE @naziv NVARCHAR(50)
	DECLARE @jed_mjere CHAR(3)
	DECLARE @kolicina INT
	DECLARE @cijena DECIMAL(7,2)
	DECLARE @dobavljac CHAR(11)

	SELECT @sifra = i.sifra FROM inserted i;
	SELECT @naziv = i.naziv FROM inserted i;
	SELECT @jed_mjere = i.jedinicaMjere FROM inserted i;
	SELECT @kolicina = i.kolicina FROM inserted i;
	SELECT @cijena = i.cijena FROM inserted i;
	SELECT @dobavljac = i.dobavljac FROM inserted i;

	IF @naziv IN (SELECT artikl.naziv FROM artikl)
	BEGIN
		UPDATE artikl SET kolicina = kolicina + @kolicina
		WHERE @naziv IN (SELECT artikl.naziv FROM artikl);
	END
	ELSE
	BEGIN
		INSERT INTO artikl VALUES (@sifra, @naziv, @jed_mjere,
		@kolicina, @cijena, @dobavljac, 'DA');
	END


-------------------------------------------------------------------------------------------------------
-- UNOS PODATAKA --
-------------------------------------------------------------------------------------------------------

BULK
INSERT djelatnik -- ime tablice
FROM 'D:\Antun\Fakultet\FERIT\Semestar 4\Baze podataka\Seminar\podaci\djelatnici.txt' -- putanja do datoteke
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

BULK
INSERT dobavljac -- ime tablice
FROM 'D:\Antun\Fakultet\FERIT\Semestar 4\Baze podataka\Seminar\podaci\dobavljaci.txt' -- putanja do datoteke
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

BULK
INSERT poslovni_partner -- ime tablice
FROM 'D:\Antun\Fakultet\FERIT\Semestar 4\Baze podataka\Seminar\podaci\poslovni_partneri.txt' -- putanja do datoteke
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

BULK
INSERT artikl -- ime tablice
FROM 'D:\Antun\Fakultet\FERIT\Semestar 4\Baze podataka\Seminar\podaci\artikli.txt' -- putanja do datoteke
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

BULK
INSERT racunR2 -- ime tablice
FROM 'D:\Antun\Fakultet\FERIT\Semestar 4\Baze podataka\Seminar\podaci\racuniR2.txt' -- putanja do datoteke
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

BULK
INSERT popis_robe -- ime tablice
FROM 'D:\Antun\Fakultet\FERIT\Semestar 4\Baze podataka\Seminar\podaci\popis_robe.txt' -- putanja do datoteke
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);


-------------------------------------------------------------------------------------------------------
-- PRIKAZ POGLEDA --
-------------------------------------------------------------------------------------------------------
SELECT * FROM stanje_skladista;
SELECT * FROM svi_dobavljaci;
SELECT * FROM svi_djelatnici;
SELECT * FROM sef;
SELECT * FROM privremeni_radnici;
SELECT * FROM radnici;
SELECT * FROM svi_poslovni_partneri;
SELECT * FROM racuniR2;
SELECT * FROM artikli_kojih_nema;


-------------------------------------------------------------------------------------------------------
-- PROCEDURE --
-------------------------------------------------------------------------------------------------------

--RACUN
CREATE PROC nadi_racunR2 @sifra_racuna CHAR(5)
AS
BEGIN
SELECT DISTINCT racunR2.sifra AS 'Sifra racuna',
    djelatnik.ime + ' ' + djelatnik.prezime AS 'Izdavatelj računa',
    poslovni_partner.ime + ' ' + poslovni_partner.prezime AS 'Izdano',
    racunR2.datum_izdavanja AS 'Datuma'
	FROM djelatnik, racunR2, poslovni_partner
	WHERE racunR2.djelatnik = djelatnik.OIB
	AND racunR2.poslovni_partner = poslovni_partner.OIB
	AND racunR2.sifra = @sifra_racuna;

SELECT DISTINCT artikl.naziv AS 'Naziv artikla',
	artikl.jedinicaMjere AS 'Jedinica mjere',
	popis_robe.kolicina AS 'Kolicina',
	artikl.cijena AS 'Cijena kn',
	popis_robe.kolicina * artikl.cijena AS 'Iznos kn'
	FROM racunR2, artikl, popis_robe
	WHERE artikl.sifra = popis_robe.artikl
	AND popis_robe.racun = racunR2.sifra
	AND racunR2.sifra = @sifra_racuna;

SELECT DISTINCT	dbo.ukupan_iznos_racuna(@sifra_racuna) AS 'Ukupan iznos u kn',
	dbo.ukupan_iznos_racuna_PDV(@sifra_racuna) - dbo.ukupan_iznos_racuna(@sifra_racuna) AS 'PDV (25%) u kn',
	dbo.ukupan_iznos_racuna_PDV(@sifra_racuna) AS 'Ukupan iznos u kn s PDV(25%)'
	FROM racunR2, artikl, popis_robe;
END;


--ARTIKLI
CREATE PROC nadi_artikl_po_sifri @sifra_artikla CHAR(5)
AS
BEGIN
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač',
	dobavljac.broj_telefona AS 'Broj telefona'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB
AND @sifra_artikla = artikl.sifra;
END;


CREATE PROC nadi_artikl_po_nazivu @naziv_artikla NVARCHAR(50)
AS
BEGIN
SELECT artikl.sifra AS 'Sifra',
    artikl.naziv AS 'Naziv',
    artikl.jedinicaMjere AS 'Jedinica mjere',
    artikl.kolicina AS 'Količina',
    artikl.cijena AS 'Cijena u kn',
    artikl.cijena * artikl.kolicina AS 'Ukupni iznos u kn',
	artikl.uprodaji AS 'U prodaji',
    dobavljac.naziv AS 'Dobavljač',
	dobavljac.broj_telefona AS 'Broj telefona'
FROM artikl, dobavljac
WHERE artikl.dobavljac = dobavljac.OIB
AND @naziv_artikla = artikl.naziv;
END;


CREATE PROC povecaj_kolicinu_artikla @sifra_artikla CHAR(5), @kolicina INT
AS
BEGIN
	UPDATE artikl SET kolicina = kolicina + @kolicina
	WHERE sifra = @sifra_artikla;
END;


--DJELATNIK
CREATE PROC nadi_djelatnika_po_OIB @OIB_djelatnika CHAR(11)
AS
BEGIN
SELECT ime + ' ' + prezime AS 'Djelatnik',
    OIB AS 'OIB',
    UPPER(uloga) AS 'Uloga',
    placa AS 'Plaća',
    broj_telefona AS 'Broj telefona',
	aktivan AS 'Aktivan'
FROM djelatnik
WHERE @OIB_djelatnika = OIB;
END;

--POSLOVNI PARTNER
CREATE PROC nadi_poslPartnera_po_OIB @OIB_poslPartnera CHAR(11)
AS
BEGIN
SELECT ime + ' ' + prezime AS 'Ime i prezime',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN',
	aktivan AS 'Aktivan'
FROM poslovni_partner
WHERE @OIB_poslPartnera = OIB;
END;

--DOBAVLJAC
CREATE PROC nadi_dobavljaca_po_OIB @OIB_dobavljaca CHAR(11)
AS
BEGIN
SELECT naziv AS 'Naziv',
    OIB AS 'OIB',
    pbr AS 'PBR',
    mjesto AS 'Mjesto',
    adresa AS 'Adresa',
    broj_telefona AS 'Broj telefona',
    IBAN AS 'IBAN',
	aktivan AS 'Aktivan'
FROM dobavljac
WHERE OIB = @OIB_dobavljaca;
END;


-------------------------------------------------------------------------------------------------------
-- PROCEDURE BRISANJA
-------------------------------------------------------------------------------------------------------

--RACUN
CREATE PROC obrisi_racunR2 @sifra_racuna CHAR(5)
AS
BEGIN
	DELETE popis_robe WHERE racun = @sifra_racuna;
	DELETE racunR2 WHERE sifra = @sifra_racuna;
END;

--ARTIKL
CREATE PROC obrisi_artikl @sifra_artikla CHAR(5)
AS
BEGIN
	DELETE popis_robe WHERE artikl IN (SELECT sifra FROM artikl WHERE sifra = @sifra_artikla);
	DELETE artikl WHERE sifra = @sifra_artikla;
END;

--DJELATNIK
CREATE PROC obrisi_djelatnika @OIB_djelatnika CHAR(11)
AS
BEGIN
	DELETE popis_robe WHERE racun IN (SELECT sifra FROM racunR2 WHERE djelatnik = @OIB_djelatnika);
	DELETE racunR2 WHERE djelatnik = @OIB_djelatnika;
	DELETE djelatnik WHERE OIB = @OIB_djelatnika;
END;

--POSLOVNI PARTNER
CREATE PROC obrisi_poslPartnera @OIB_poslPartner CHAR(11)
AS
BEGIN
	DELETE popis_robe WHERE racun IN (SELECT sifra FROM racunR2 WHERE poslovni_partner = @OIB_poslPartner);
	DELETE racunR2 WHERE poslovni_partner = @OIB_poslPartner;
	DELETE poslovni_partner WHERE OIB = @OIB_poslPartner;
END;

--DOBAVLJAC
CREATE PROC obrisi_dobavljaca @OIB_dobavljaca CHAR(11)
AS
BEGIN
	DELETE popis_robe WHERE artikl IN (SELECT sifra FROM artikl WHERE dobavljac = @OIB_dobavljaca);
	DELETE artikl WHERE dobavljac = @OIB_dobavljaca;
	DELETE dobavljac WHERE OIB = @OIB_dobavljaca;
END;


-------------------------------------------------------------------------------------------------------
--KORISTENJE PROCEDURA
-------------------------------------------------------------------------------------------------------

EXEC nadi_racunR2 '1';
EXEC nadi_artikl_po_sifri '1';
EXEC nadi_artikl_po_nazivu 'harmony';
EXEC povecaj_kolicinu_artikla '1', '1000';
EXEC nadi_djelatnika_po_OIB '981728169XX';
EXEC nadi_dobavljaca_po_OIB '03834418154';
EXEC nadi_poslPartnera_po_OIB '715716313XX';

EXEC obrisi_racunR2 '1';
EXEC obrisi_artikl '1';
EXEC obrisi_djelatnika '981728169XX';
EXEC obrisi_poslPartnera '715716313XX';
EXEC obrisi_dobavljaca '03834418154';


-------------------------------------------------------------------------------------------------------
-- PROMJENA AKTIVNOSTI OSOBE, PROMJENA ARTIKLA U PRODAJI
-------------------------------------------------------------------------------------------------------

UPDATE ime_tablice SET stanje = 'NE' WHERE OIB = OIB_osobe_željene_osobe;
UPDATE artikl SET uprodaji = 'NE' WHERE sifra = sifra_željenog_artikla;
