drop function calculTemps();

DROP TABLE IF EXISTS Logiciel CASCADE;
DROP TABLE IF EXISTS Installer CASCADE;
DROP TABLE IF EXISTS Salle CASCADE;
DROP TABLE IF EXISTS Poste CASCADE;

CREATE TABLE Logiciel(
    nLog INTEGER PRIMARY KEY,
    nomLog VARCHAR(50),
    dateAch INTEGER,
    version VARCHAR(50),
    typeLog VARCHAR(50),
    prix INTEGER,
    nbInstal INTEGER
);


CREATE TABLE Segment(
    indIP VARCHAR PRIMARY KEY,
    nomSegment VARCHAR,
    nbPoste INTEGER
);

INSERT INTO Segment VALUES('130.120.80', 'segA', 0);
INSERT INTO Segment VALUES('130.500.80', 'segB', 0); 
INSERT INTO Segment VALUES('130.500.80', 'segC', 0);


CREATE TABLE Salle(
    nSalle INTEGER PRIMARY KEY,
    nomSalle VARCHAR,
    nbPoste INTEGER,
    indIP VARCHAR,
    FOREIGN KEY(indIP) REFERENCES Segment
);

CREATE TABLE Poste(
    nposte INTEGER PRIMARY KEY,
    nomPoste VARCHAR,
    typePoste VARCHAR,
    nSalle INTEGER,
    nblog INTEGER,
    FOREIGN KEY (nsalle) REFERENCES Salle
);

CREATE TABLE Installer(
    nposte INTEGER,
    nlog INTEGER,
    numIns INTEGER,
    dateIns INTEGER,
    delai INTEGER,
    FOREIGN KEY(nlog) REFERENCES Logiciel,
    FOREIGN KEY(nposte) REFERENCES Poste
);

drop function if exists modifNbPoste();

CREATE FUNCTION modifNbPoste() RETURNS TRIGGER AS $$
BEGIN

  IF TG_OP = 'INSERT' THEN

    UPDATE SALLE SET nbPoste = nbPoste + 1 WHERE nsalle = NEW.nsalle;
    RETURN NEW;

  ELSE
    IF TG_OP = 'DELETE' THEN

      UPDATE SALLE SET nbPoste = nbPoste - 1 WHERE nsalle = OLD.nsalle;
      RETURN OLD;

    END IF;

  END IF;

END
$$language plpgsql;


CREATE TRIGGER Trig_Apres_DI_Poste 
  AFTER INSERT OR DELETE  
    ON Poste
  FOR EACH ROW
    EXECUTE PROCEDURE modifNbPoste();

SELECT * FROM SALLE;

INSERT INTO Poste VALUES(3,3, 'fixe', 102, 3);

SELECT * FROM SALLE;

DELETE FROM Poste WHERE nposte=3; 

SELECT * FROM SALLE;


drop function if exists modifUpdateSalle();

CREATE FUNCTION modifUpdateSalle() RETURNS TRIGGER AS $$
BEGIN

  UPDATE SEGMENT SET nbPoste = nbPoste + (NEW.nbPoste - OLD.nbPoste) WHERE indIP = NEW.indIP;
  RETURN NEW;

END
$$language plpgsql;


CREATE TRIGGER Trig_Apres_DI_Salle 
  AFTER UPDATE
    ON Salle
  FOR EACH ROW
    EXECUTE PROCEDURE modifUpdateSalle();

SELECT * FROM SEGMENT;

DROP SEQUENCE IF EXISTS idLogiciel;
CREATE SEQUENCE idLogiciel;

DROP SEQUENCE IF EXISTS idInstall;
CREATE SEQUENCE idInstall;

INSERT INTO Salle VALUES(102, 'Ada Lovelace', 0, '130.120.80');
INSERT INTO Salle VALUES(2, 'Amphi L', 0, '130.500.80');
INSERT INTO Salle VALUES(3, 'Amphi B', 0, '130.500.80');

INSERT INTO Poste VALUES(1,1, 'fixe', 102, 0);
INSERT INTO Poste VALUES(2,2, 'fixe', 2, 0);
INSERT INTO Poste VALUES(3,3, 'fixe', 102, 0);
INSERT INTO Poste VALUES(4,4, 'fixe', 2, 0);

insert into Logiciel values
  (nextval('idLogiciel'),'nnn',2020,'2.1',null,10,0),
  (nextval('idLogiciel'),'3nn',2022,'2.1',null,10,0),
  (nextval('idLogiciel'),'22n',2023,'2.1',null,10,0),
  (nextval('idLogiciel'),'2nn',null,'2.1',null,10,0);
    
insert into Installer values
  (nextval('idInstall'),1,10,2023),
  (nextval('idInstall'),2,11,2022),
  (nextval('idInstall'),3,12,2021),
  (nextval('idInstall'),4,13,2022);

SELECT * FROM Installer;
SELECT * FROM Logiciel;

create or replace function calculTemps() returns void AS
$$

DECLARE
  curs CURSOR FOR SELECT l.dateAch, l.nomLog, i.dateIns, i.nPoste, i.nLog FROM Logiciel l JOIN Installer i ON i.nlog = l.nlog;
  attente float(4);

BEGIN
  FOR enreg IN curs LOOP

  IF enreg.dateIns IS NULL THEN
    RAISE NOTICE ' Pas de date d installation pour le logiciel =%', enreg.nlog;

  ELSE
    IF enreg.dateAch IS NULL THEN
      RAISE NOTICE 'Date achat inconnue pour le logiciel =%', enreg.nlog;

  ELSE 
    attente :=  enreg.dateIns - enreg.dateAch;

    IF attente < 0 THEN
    RAISE NOTICE 'Logiciel % installé sur % % jour(s) avant son achat !', enreg.nomLog, enreg.nPoste, attente;

    ELSE 
      IF attente = 0 THEN
      RAISE NOTICE 'Logiciel % sur % achecté et installé le meme jour !', enreg.nLog, enreg.nPoste;

    ELSE 
      UPDATE Installer SET delai = attente WHERE nPoste = enreg.nPoste AND nLog = enreg.nLog;
      RAISE NOTICE 'OK, attribut delai modifié';

  END IF; END IF; END IF; END IF; END LOOP;
END

$$ language plpgsql;

select calculTemps();
SELECT * FROM Installer;


CREATE OR REPLACE FUNCTION installLogSeg
        (numSeg text, numLog INTEGER, nomLog text, dateAchat INTEGER, vers text, typeLog text, prix INTEGER) 
            returns void as

$$

DECLARE

    curs CURSOR FOR SELECT p.nomPoste, p.nPoste, s.nomSalle, s.nSalle
        FROM Poste p JOIN Salle s ON p.nSalle = s.nSalle
            WHERE s.indIP = numSeg;

BEGIN



    INSERT INTO Logiciel VALUES(numLog, nomLog, dateAchat, vers, typeLog, prix, 0);
    RAISE NOTICE '% stocké dans la table logiciel.', nomLog;


    FOR enreg IN curs LOOP

        RAISE NOTICE 'Installation sur poste % dans la salle %', enreg.nPoste, enreg.nSalle;
        INSERT INTO Installer VALUES(enreg.nPoste, numLog, nextval('idInstall'), 2023, null);


    END LOOP;

END

$$ LANGUAGE plpgsql;

select * from Salle;

select * from Logiciel;
select * from Poste;
select * from Installer;

select installLogSeg('130.120.80', 22, 'SAS', 1999, '9.9', 'Wind', 999);

select * from Logiciel;
select * from Poste;

select * from Installer;

SELECT p.nomPoste, p.nPoste, s.nomSalle 
        FROM Poste p JOIN Salle s ON p.nSalle = s.nSalle
            WHERE s.indIP = '130.120.80';



drop function if exists modifNBLogiciel();

CREATE FUNCTION modifNBLogiciel() RETURNS TRIGGER AS $$

BEGIN
  IF TG_OP = 'INSERT' THEN 

    UPDATE LOGICIEL SET nbInstal = nbInstal+1 WHERE nLog = NEW.nLog;
    UPDATE POSTE SET nblog = nblog+1 WHERE nposte = NEW.nposte;

    RETURN NEW;

  ELSE 
    IF TG_OP = 'DELETE' THEN

      UPDATE LOGICIEL SET nbInstal = nbInstal-1 WHERE nLog = OLD.nLog;
      UPDATE POSTE SET nblog = nblog-1 WHERE nposte = OLD.nposte;

      RETURN OLD;
    
    END IF;

  END IF;

  RETURN NEW;
END
$$LANGUAGE plpgsql;


CREATE TRIGGER Trig_Apres_DI_Installer 
  AFTER INSERT OR DELETE
    ON Installer
  FOR EACH ROW
    EXECUTE PROCEDURE modifNBLogiciel();

SELECT * FROM POSTE;

INSERT INTO Installer VALUES(4,2,14,2024);
SELECT * FROM LOGICIEL;
SELECT * FROM POSTE;

DELETE FROM Installer WHERE nPoste = 4 AND nLog = 2;

SELECT * FROM LOGICIEL;
SELECT * FROM POSTE;

SELECT * from segment;