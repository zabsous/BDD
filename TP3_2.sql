DROP TABLE IF EXISTS elevage CASCADE;
DROP TABLE IF EXISTS eleveur CASCADE;

DROP TYPE IF EXISTS Televage CASCADE;
DROP TYPE IF EXISTS Tadresse CASCADE;
DROP TYPE IF EXISTS Televeur CASCADE;

DROP SEQUENCE IF EXISTS numLicence;
CREATE SEQUENCE numLicence;

CREATE TYPE Televage AS (
    animalType VARCHAR(20),
    ageMin int,
    nbrMax int
);

CREATE TYPE Tadresse AS (
    nrue int,
    rue VARCHAR(30),
    ville VARCHAR(30),
    code_postal int
);

CREATE TYPE Televeur AS (
    numLic int,
    elevageE Televage,
    adresse Tadresse
);

CREATE TABLE elevage OF Televage (PRIMARY KEY (animalType));
CREATE TABLE eleveur OF Televeur (PRIMARY KEY (numLic));



drop function if exists elevageParisModif();

CREATE FUNCTION elevageParisModif() RETURNS TRIGGER AS $$
BEGIN

  IF((NEW.adresse).ville = 'Paris') THEN
    RAISE NOTICE 'Eleveur a paris. Il degage';
    RETURN NULL;

  ELSE 
    IF((NEW.adresse).ville = 'Angers') THEN 
        IF((NEW.elevagee).animalType = 'volaille') THEN
            RAISE NOTICE 'Eleveur angevins de volaille. Il degage';
            RETURN NULL;
        ELSE RETURN NEW;
        END IF;

    ELSE RETURN NEW;
    END IF;

END IF;

END
$$language plpgsql;


CREATE TRIGGER triggerFiltreElevage 
  BEFORE INSERT
    ON eleveur
  FOR EACH ROW
    EXECUTE PROCEDURE elevageParisModif();



INSERT INTO elevage VALUES('bovin', 20, 50),
                        ('ovin', 5, 40),
                        ('volaille', 15, 35),
                        ('poisson', 25, 47);



INSERT INTO eleveur VALUES(nextval('numLicence'), (select e from elevage e where animalType='poisson'), row(8, 'rue au pif', 'Paris', 97000)),
                        (nextval('numLicence'), (select e from elevage e where animalType='poisson'), row(24, 'rue au pif', 'Paris', 97000)),
                        (nextval('numLicence'), (select e from elevage e where animalType='ovin'), row(15, 'rue au pif', 'Saint clement', 59000)),
                        (nextval('numLicence'), (select e from elevage e where animalType='volaille'), row(5, 'rue au pif', 'Angers', 49070));

UPDATE eleveur SET elevageE=(select e from elevage e where animalType='bovin') WHERE numLic=3;

UPDATE eleveur e SET adresse = row((e.adresse).nrue, (e.adresse).rue, 'Bordeaux', 33300)  WHERE (e.elevageE).animalType = 'bovin';

SELECT * FROM eleveur;
SELECT * FROM elevage;