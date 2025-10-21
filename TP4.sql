DROP TABLE IF EXISTS Personne CASCADE;
DROP TABLE IF EXISTS Societe CASCADE;
DROP TABLE IF EXISTS Salarie CASCADE;
DROP TABLE IF EXISTS Actions CASCADE;
DROP TABLE IF EXISTS Histo_Annuel_Actionnaire CASCADE;

DROP TYPE IF EXISTS Tpersonne CASCADE;
DROP TYPE IF EXISTS Tsociete CASCADE;
DROP TYPE IF EXISTS Tsalarie CASCADE;
DROP TYPE IF EXISTS Taction CASCADE;
DROP TYPE IF EXISTS Thisto_Annuel_actionnaire CASCADE;

DROP SEQUENCE IF EXISTS S_numSecu; 
CREATE SEQUENCE S_numSecu; 

DROP SEQUENCE IF EXISTS S_codeSoc; 
CREATE SEQUENCE S_codeSoc; 

CREATE TYPE Tpersonne AS(
    NumSecu INTEGER,
    Nom VARCHAR(20),
    Prenom VARCHAR(20),
    Sexe VARCHAR(1),
    DateNais INTEGER
);

CREATE TYPE Tsociete AS(
    CodeSoc INTEGER,
    NomSoc VARCHAR(20),
    Adresse VARCHAR(20)
);

CREATE TYPE Tsalarie AS(
    Personne Tpersonne,
    Societe Tsociete,
    Salaire INTEGER
);

CREATE TYPE Taction AS(
    Personne Tpersonne,
    Societe Tsociete,
    DateAct INTEGER,
    NbreAct INTEGER,
    TypeAct VARCHAR(50)
);

CREATE TYPE Thisto_Annuel_actionnaire AS(
    Personne Tpersonne,
    Societe Tsociete,
    Annee INTEGER,
    NbrActTotal INTEGER,
    Nbr_Achat INTEGER,
    Nbr_Vente INTEGER
);

CREATE TABLE Personne OF Tpersonne (PRIMARY KEY (NumSecu));
CREATE TABLE Societe OF Tsociete (PRIMARY KEY (CodeSoc));
CREATE TABLE Salarie OF Tsalarie (PRIMARY KEY (Personne, Societe));
CREATE TABLE Actions OF Taction (PRIMARY KEY (Personne, Societe, DateAct));
CREATE TABLE Histo_Annuel_Actionnaire OF Thisto_Annuel_actionnaire (PRIMARY KEY (Personne, Societe, Annee));


DROP FUNCTION IF EXISTS forbidUpdateAndOutdatedAct();

CREATE FUNCTION forbidUpdateAndOutdatedAct() RETURNS TRIGGER AS $$
BEGIN

  IF TG_OP = 'INSERT' THEN

    IF 2023 > NEW.DateAct THEN  
        RAISE NOTICE 'HELLO';
        RETURN NULL;

    ELSE RETURN NEW;

    END IF;

  ELSE

    IF TG_OP = 'UPDATE' THEN
        RETURN OLD;
    END IF;

  END IF;

END
$$LANGUAGE plpgsql;


CREATE TRIGGER forbidUpdateAndOutdatedActTRIGGER 
  BEFORE INSERT OR UPDATE  
    ON Actions
  FOR EACH ROW
    EXECUTE PROCEDURE forbidUpdateAndOutdatedAct();


DROP FUNCTION IF EXISTS addActToHist();

CREATE FUNCTION addActToHist() RETURNS TRIGGER AS $$

BEGIN

    IF NOT EXISTS (SELECT * FROM Histo_Annuel_Actionnaire h WHERE h.Personne = NEW.Personne AND h.Societe = NEW.Societe AND h.Annee = NEW.DateAct) THEN

        IF NEW.TypeAct = 'achat' THEN
            INSERT INTO Histo_Annuel_Actionnaire VALUES(NEW.Personne, NEW.Societe, NEW.DateAct, NEW.NbreAct, NEW.NbreAct, 0);
    
        ELSE 
            INSERT INTO Histo_Annuel_Actionnaire VALUES(NEW.Personne, NEW.Societe, NEW.DateAct, NEW.NbreAct, 0, NEW.NbreAct);

        END IF;
        RETURN NEW;

    ELSE 

        IF NEW.TypeAct = 'achat' THEN
            UPDATE Histo_Annuel_Actionnaire h SET h.NbrActTotal = h.NbrActTotal + NEW.NbreAct, h.Nbr_Achat = h.Nbr_Achat + NEW.NbreAct
                WHERE h.Personne = NEW.Personne AND h.Societe = NEW.Societe AND h.Annee = NEW.DateAct;

        ELSE 
            UPDATE Histo_Annuel_Actionnaire h SET h.NbrActTotal = h.NbrActTotal + NEW.NbreAct, h.Nbr_Vente = h.Nbr_Achat + NEW.NbreAct
                WHERE h.Personne = NEW.Personne AND h.Societe = NEW.Societe AND h.Annee = NEW.DateAct;

        END IF;
        RETURN NEW;

    END IF;
END
$$LANGUAGE plpgsql;


CREATE TRIGGER addActToHistTRIGGER
  AFTER INSERT
    ON Actions
  FOR EACH ROW
    EXECUTE PROCEDURE addActToHist();

INSERT INTO Personne VALUES
(nextval('S_numSecu'), 'Lemonnier', 'Paul', 'H', 2003),
(nextval('S_numSecu'), 'Ronné', 'Kyllian', 'H', 2003),
(nextval('S_numSecu'), 'Fournnnier', 'Nicolas', 'H', 2003),
(nextval('S_numSecu'), 'Lemonnier', 'Laure', 'F', 2000);

INSERT INTO Societe VALUES
(nextval('S_codeSoc'), 'SOC1', 'ADR1'),
(nextval('S_codeSoc'), 'SOC2', 'ADR2'),
(nextval('S_codeSoc'), 'SOC3', 'ADR3'),
(nextval('S_codeSoc'), 'SOC4', 'ADR4');

INSERT INTO Salarie VALUES
((SELECT p FROM Personne p WHERE p.NumSecu = 1), (SELECT s FROM Societe s WHERE s.CodeSoc = 1), 2000),
((SELECT p FROM Personne p WHERE p.NumSecu = 2), (SELECT s FROM Societe s WHERE s.CodeSoc = 2), 1500),
((SELECT p FROM Personne p WHERE p.NumSecu = 3), (SELECT s FROM Societe s WHERE s.CodeSoc = 3), 1800),
((SELECT p FROM Personne p WHERE p.NumSecu = 4), (SELECT s FROM Societe s WHERE s.CodeSoc = 3), 1800);

INSERT INTO Actions VALUES
((SELECT p FROM Personne p WHERE p.NumSecu = 1), (SELECT s FROM Societe s WHERE s.CodeSoc = 1), 2050, 5,  'achat'),
((SELECT p FROM Personne p WHERE p.NumSecu = 2), (SELECT s FROM Societe s WHERE s.CodeSoc = 3), 2024, 8,  'vente'),
((SELECT p FROM Personne p WHERE p.NumSecu = 3), (SELECT s FROM Societe s WHERE s.CodeSoc = 3), 2023, 2,  'achat');

UPDATE Actions a SET DateAct = 2000 WHERE a.Personne = (SELECT p FROM Personne p WHERE p.NumSecu = 2);


SELECT * FROM Personne;
SELECT * FROM Societe;
SELECT * FROM Salarie;
SELECT * FROM Actions;
SELECT * FROM Histo_Annuel_Actionnaire;

DROP FUNCTION IF EXISTS anneeVenteSupAchat;

CREATE FUNCTION anneeVenteSupAchat(soc Tsociete) RETURNS SETOF INTEGER AS $$
DECLARE
    curs CURSOR FOR SELECT * FROM Histo_Annuel_Actionnaire a WHERE a.Societe = soc;

BEGIN
    FOR enreg IN curs LOOP

        IF enreg.nbr_vente > enreg.nbr_achat THEN
            
            RETURN NEXT enreg.Annee;

        END IF;

    END LOOP;
    RETURN;
END;
$$language plpgsql;

SELECT * FROM anneeVenteSupAchat((SELECT s FROM Societe s WHERE s.CodeSoc = 3));

DROP FUNCTION IF EXISTS noActions;

CREATE FUNCTION noActions() RETURNS SETOF Tpersonne AS $$

DECLARE
    curs CURSOR FOR SELECT * FROM Salarie;
BEGIN

    FOR enreg IN curs LOOP

    IF NOT EXISTS (SELECT * FROM Actions a WHERE enreg.Personne = a.Personne AND enreg.Societe = a.Societe) THEN

        RETURN NEXT enreg.Personne;

    END IF;

    END LOOP;

    RETURN;

END;
$$language plpgsql;

SELECT * FROM noActions();

DROP FUNCTION IF EXISTS Q7;


CREATE FUNCTION Q7() RETURNS SETOF text AS $$

DECLARE

    curs CURSOR FOR SELECT * FROM Histo_Annuel_Actionnaire h JOIN Salarie s ON h.Personne = s.Personne AND h.Societe = s.Societe;

BEGIN

    FOR enreg IN curs LOOP

        RETURN NEXT (enreg.Societe).NomSoc;

    END LOOP;

    RETURN;

END;
$$language plpgsql;

SELECT * FROM Q7();