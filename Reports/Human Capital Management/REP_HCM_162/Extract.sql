REP_HCM_162 - SP-1111 - 28/01/2025
REP_HCM_162 - SP-2222 - 29/01/2025
REP_HCM_162 - SP-2222 - 29/01/2025 - 1
REP_HCM_162 - SP-2222 - 29/01/2025 - 2
REP_HCM_162 - SP-2222 - 29/01/2025 - 3
REP_HCM_162 - SP-2222 - 29/01/2025 - 4
REP_HCM_162 - SP-2222 - 29/01/2025 - 5
REP_HCM_162 - SP-2222 - 29/01/2025 - 6



SELECT 

hap.POSITION_CODE as "Position Code",hap.ORGANIZATION_ID,
hap.name as "Position Name",
--,hap.position_id

/*(
SELECT name
FROM per_grades_x pg,
PER_VALID_GRADES_F pvg
WHERE pg.grade_id IN (pvg.grade_id)
AND pvg.position_id = hap.position_id
) existing_grade,*/

(
SELECT hauft.NAME
FROM   HR_ORG_UNIT_CLASSIFICATIONS_F houcf,
HR_ALL_ORGANIZATION_UNITS_F haouf,
HR_ORGANIZATION_UNITS_F_TL hauft
WHERE   haouf.ORGANIZATION_ID = houcf.ORGANIZATION_ID
AND haouf.ORGANIZATION_ID = hauft.ORGANIZATION_ID
AND haouf.EFFECTIVE_START_DATE BETWEEN houcf.EFFECTIVE_START_DATE AND houcf.EFFECTIVE_END_DATE
AND hauft.LANGUAGE = 'US'
AND hauft.EFFECTIVE_START_DATE = haouf.EFFECTIVE_START_DATE
AND hauft.EFFECTIVE_END_DATE = haouf.EFFECTIVE_END_DATE
AND houcf.CLASSIFICATION_CODE = 'FUN_BUSINESS_UNIT'
AND SYSDATE BETWEEN hauft.effective_start_date AND hauft.effective_end_date
AND hap.BUSINESS_UNIT_ID = haouf.ORGANIZATION_ID
) AS "Businss Unit",

(
SELECT hauft.NAME
FROM   
HR_ORG_UNIT_CLASSIFICATIONS_F houcf, HR_ALL_ORGANIZATION_UNITS_F haouf, HR_ORGANIZATION_UNITS_F_TL hauft

WHERE   haouf.ORGANIZATION_ID = houcf.ORGANIZATION_ID
AND haouf.ORGANIZATION_ID = hauft.ORGANIZATION_ID
AND haouf.EFFECTIVE_START_DATE BETWEEN houcf.EFFECTIVE_START_DATE AND houcf.EFFECTIVE_END_DATE
AND hauft.LANGUAGE = 'US'
AND hauft.EFFECTIVE_START_DATE = haouf.EFFECTIVE_START_DATE
AND hauft.EFFECTIVE_END_DATE = haouf.EFFECTIVE_END_DATE
AND houcf.CLASSIFICATION_CODE = 'DEPARTMENT'
AND SYSDATE BETWEEN hauft.effective_start_date AND hauft.effective_end_date
AND hap.ORGANIZATION_ID = haouf.ORGANIZATION_ID 

) AS "Department",

/*(CASE WHEN LE.LegalEmployer = 'UK Research and Innovation' THEN DIV_UKRI.L2_DIVISION_NAME
	   WHEN LE.LegalEmployer = 'UK Shared Business Services Limited' THEN DIV_UKSBS.L1_DIVISION_NAME
	   ELSE ' '
	   END) AS "Division",
*/
DIV_UKRI.L2_DIVISION_NAME,
DIV_UKSBS.L1_DIVISION_NAME,
(
SELECT pjft.NAME
FROM 
per_jobs_x pjft
WHERE pjft.job_id = hap.JOB_ID
) AS "Job",

hap.FULL_PART_TIME as "Full Time/Part Time",

(
SELECT pld.LOCATION_NAME
FROM 
per_location_details_x pld
WHERE hap.location_id = pld.location_id(+)

)as "Location of Position",

hap.HIRING_STATUS AS "Hiring Status",


(
SELECT count(distinct paaf.person_id)
FROM per_all_assignments_f paaf,per_person_types_vl pptl,
per_periods_of_service_v ppos
WHERE paaf.person_id = ppos.person_id
AND paaf.assignment_type = 'E'
AND paaf.primary_assignment_flag = 'Y'
AND paaf.assignment_status_type = 'ACTIVE'
AND paaf.person_type_id = pptl.person_type_id	
AND pptl.system_person_type = 'EMP'	   
AND TRUNC(sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
AND paaf.position_id = hap.position_id
AND (
ppos.actual_termination_date IS NULL
OR ppos.actual_termination_date >= trunc(sysdate)
)
) AS incumbants,

hap.FTE ,

(CASE 
WHEN Incumb_FTE.INC_FTE IS NULL THEN 0
ELSE Incumb_FTE.INC_FTE 
END) AS "Incumbent_FTE",


(CASE WHEN Incumb_FTE.INC_FTE IS NULL THEN hap.FTE
ELSE (hap.FTE - Incumb_FTE.INC_FTE) END 
)as "Vacant FTE"


FROM 

HR_ALL_POSITIONS_X hap,

(
select PAAM.POSITION_ID,SUM(PAWMF.VALUE) AS INC_FTE
           from PER_ALL_ASSIGNMENTS_F PAAM,
                PER_ASSIGN_WORK_MEASURES_F PAWMF
		  where 
            TRUNC(SYSDATE)  BETWEEN PAAM.EFFECTIVE_START_DATE AND PAAM.EFFECTIVE_END_DATE
			AND TRUNC(SYSDATE)  BETWEEN PAWMF.EFFECTIVE_START_DATE AND PAWMF.EFFECTIVE_END_DATE
            AND PAAM.ASSIGNMENT_TYPE = 'E'
		    AND PAAM.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
			AND PAAM.primary_assignment_flag = 'Y'
            AND PAAM.ASSIGNMENT_ID = PAWMF.ASSIGNMENT_ID
            AND PAWMF.UNIT = 'FTE'
			GROUP BY PAAM.POSITION_ID
) Incumb_FTE,

/*-------------DIV START--------*/

(
SELECT DISTINCT
		
       hao.name               AS L2_DIVISION_NAME,
       haob.name              AS L1_DIVISION_NAME,
       CHILD3.name            AS L0_DIVISION_NAME,
       CHILD3.CHILD_DEPT_NAME AS CHILD_DEPT_NAME,
       CHILD3.CHILD_DEPT_ID 
		
        FROM   per_org_tree_node org,
               fnd_tree_version_vl ftvt,
               hr_all_organization_units_vl hao,
               hr_all_organization_units_vl haob,
               hr_org_unit_classifications_f HOUF,


(SELECT
       org.parent_pk1_value 
       ,haob.name              
       ,org.pk1_start_value 
       ,CHILD2.name            AS CHILD_DEPT_NAME
       ,CHILD2.pk1_start_value AS CHILD_DEPT_ID
        
		FROM   per_org_tree_node org,
               fnd_tree_version_vl ftvt,
               hr_all_organization_units_vl hao,
               hr_all_organization_units_vl haob,
               hr_org_unit_classifications_f HOUF,
               (SELECT org.parent_pk1_value,
                       haob2.name,
                       org.pk1_start_value
                FROM   per_org_tree_node org,
                       fnd_tree_version_vl ftvt,
                       hr_all_organization_units_vl hao,
                       hr_all_organization_units_vl haob2,
                       hr_org_unit_classifications_f HOUF
                WHERE  org.tree_structure_code = 'PER_ORG_TREE_STRUCTURE'
                       and org.tree_code = 'SHARP_ORG_TREE_UKRI'
                       AND ftvt.tree_structure_code = org.tree_structure_code
                       AND ftvt.tree_code = org.tree_code
                       AND ftvt.tree_version_id = org.tree_version_id
                       --AND ftvt.TREE_VERSION_NAME = 'UKRI Tree Version'
                       AND org.parent_pk1_value = hao.organization_id
                       AND haob2.organization_id = houf.organization_id
                       AND haob2.organization_id = org.pk1_start_value
                       --and org.depth= 4
                       AND Trunc (SYSDATE) BETWEEN hao.effective_start_date AND
                                                   hao.effective_end_date
                       AND Trunc (SYSDATE) BETWEEN haob2.effective_start_date
                                                   AND
                                                   haob2.effective_end_date
                       AND Trunc (SYSDATE) BETWEEN houf.effective_start_date AND
                                                   houf.effective_end_date
                       --and org.parent_pk1_value = '300000091524999'
                       --and haob.name IN ('MRC - CFM - Biological Services',  'STFC - P Finance - Administration')
                       AND haob2.name IN (SELECT hauft.name
                                          FROM   hr_organization_v hauft
                                          WHERE  hauft.classification_code =
                                                 'DEPARTMENT'
                                                 AND Trunc(SYSDATE) BETWEEN
                                                     hauft.effective_start_date
                                                     AND
                                                     hauft.effective_end_date
                                         --AND hauft.NAME = 'NERC - BAS IT Services'
                                         ))CHILD2
        WHERE  org.tree_structure_code = 'PER_ORG_TREE_STRUCTURE'
               and org.tree_code = 'SHARP_ORG_TREE_UKRI'
               AND ftvt.tree_structure_code = org.tree_structure_code
               AND ftvt.tree_code = org.tree_code
               AND ftvt.tree_version_id = org.tree_version_id
               --AND ftvt.TREE_VERSION_NAME = 'UKRI Tree Version'
               AND org.parent_pk1_value = hao.organization_id
               AND haob.organization_id = houf.organization_id
               AND haob.organization_id = org.pk1_start_value
               --and org.depth= 4
               AND Trunc (SYSDATE) BETWEEN hao.effective_start_date AND
                                           hao.effective_end_date
               AND Trunc (SYSDATE) BETWEEN haob.effective_start_date AND
                                           haob.effective_end_date
               AND Trunc (SYSDATE) BETWEEN houf.effective_start_date AND
                                           houf.effective_end_date
               --and org.parent_pk1_value = '300000091524999'
               --and haob.name IN ('MRC - CFM - Biological Services',  'STFC - P Finance - Administration')
               AND haob.name IN (SELECT hauft.name
                                 FROM   hr_organization_v hauft
                                 WHERE  hauft.classification_code =
                                        'HCM_DIVISION'
                                        AND Trunc(SYSDATE) BETWEEN
                                            hauft.effective_start_date
                                            AND
                                            hauft.effective_end_date
                                --AND hauft.NAME = 'STFC - Projects and Grants Section'
                                )
               AND org.pk1_start_value = CHILD2.parent_pk1_value) CHILD3
			   
WHERE  org.tree_structure_code = 'PER_ORG_TREE_STRUCTURE'
and org.tree_code = 'SHARP_ORG_TREE_UKRI'
AND ftvt.tree_structure_code = org.tree_structure_code
AND ftvt.tree_code = org.tree_code
AND ftvt.tree_version_id = org.tree_version_id
--AND ftvt.TREE_VERSION_NAME = 'UKRI Tree Version'
AND org.parent_pk1_value = hao.organization_id
AND haob.organization_id = houf.organization_id
AND haob.organization_id = org.pk1_start_value
--and org.depth= 4
AND Trunc (SYSDATE) BETWEEN hao.effective_start_date AND
                            hao.effective_end_date
AND Trunc (SYSDATE) BETWEEN haob.effective_start_date AND
                            haob.effective_end_date
AND Trunc (SYSDATE) BETWEEN houf.effective_start_date AND
                            houf.effective_end_date
--and org.parent_pk1_value = '300000091524999'
--and haob.name IN ('MRC - CFM - Biological Services',  'STFC - P Finance - Administration')
AND haob.name IN (SELECT hauft.name
                  FROM   hr_organization_v hauft
                  WHERE  hauft.classification_code =
                         'HCM_DIVISION'
                         AND Trunc(SYSDATE) BETWEEN
                             hauft.effective_start_date
                             AND
                             hauft.effective_end_date
                 --AND hauft.NAME = 'STFC - Projects and Grants Section'
                 )
AND org.pk1_start_value = CHILD3.parent_pk1_value
) DIV_UKRI
,

(
SELECT DISTINCT
       --2 LEVEL_Identifier,
       --haob.organization_id Record_Identifier,
       hao.name               AS L1_DIVISION_NAME,
       --org.parent_pk1_value AS PARENT_DIVISION_ID,
       haob.name              AS L0_DIVISION_NAME,
       --org.pk1_start_value AS CHILD_DIVISION_ID,
       --houf.status "Status",
       CHILD2.name            AS CHILD_DEPT_NAME,
       CHILD2.pk1_start_value AS CHILD_DEPT_ID
        --CHILD2.parent_pk1_value AS CHILD2_DIVISION_ID
        FROM   per_org_tree_node org,
               fnd_tree_version_vl ftvt,
               hr_all_organization_units_vl hao,
               hr_all_organization_units_vl haob,
               hr_org_unit_classifications_f HOUF,
               (SELECT org.parent_pk1_value,
                       haob2.name,
                       org.pk1_start_value
                --,hao.name,haob.name,houf.status 
                FROM   per_org_tree_node org,
                       fnd_tree_version_vl ftvt,
                       hr_all_organization_units_vl hao,
                       hr_all_organization_units_vl haob2,
                       hr_org_unit_classifications_f HOUF
                WHERE  org.tree_structure_code = 'PER_ORG_TREE_STRUCTURE'
                       and org.tree_code = 'SHARP_ORG_TREE_UKSBS'
                       AND ftvt.tree_structure_code = org.tree_structure_code
                       AND ftvt.tree_code = org.tree_code
                       AND ftvt.tree_version_id = org.tree_version_id
                       --AND ftvt.TREE_VERSION_NAME = 'UKRI Tree Version'
                       AND org.parent_pk1_value = hao.organization_id
                       AND haob2.organization_id = houf.organization_id
                       AND haob2.organization_id = org.pk1_start_value
                       --and org.depth= 4
                       AND Trunc (SYSDATE) BETWEEN hao.effective_start_date AND
                                                   hao.effective_end_date
                       AND Trunc (SYSDATE) BETWEEN haob2.effective_start_date
                                                   AND
                                                   haob2.effective_end_date
                       AND Trunc (SYSDATE) BETWEEN houf.effective_start_date AND
                                                   houf.effective_end_date
                       --and org.parent_pk1_value = '300000091524999'
                       --and haob.name IN ('MRC - CFM - Biological Services',  'STFC - P Finance - Administration')
                       AND haob2.name IN (SELECT hauft.name
                                          FROM   hr_organization_v hauft
                                          WHERE  hauft.classification_code =
                                                 'DEPARTMENT'
                                                 AND Trunc(SYSDATE) BETWEEN
                                                     hauft.effective_start_date
                                                     AND
                                                     hauft.effective_end_date
                                         --AND hauft.NAME = 'STFC - P Finance - Administration'
                                         ))CHILD2
        WHERE  org.tree_structure_code = 'PER_ORG_TREE_STRUCTURE'
               and org.tree_code = 'SHARP_ORG_TREE_UKSBS'
               AND ftvt.tree_structure_code = org.tree_structure_code
               AND ftvt.tree_code = org.tree_code
               AND ftvt.tree_version_id = org.tree_version_id
               --AND ftvt.TREE_VERSION_NAME = 'UKRI Tree Version'
               AND org.parent_pk1_value = hao.organization_id
               AND haob.organization_id = houf.organization_id
               AND haob.organization_id = org.pk1_start_value
               --and org.depth= 4
               AND Trunc (SYSDATE) BETWEEN hao.effective_start_date AND
                                           hao.effective_end_date
               AND Trunc (SYSDATE) BETWEEN haob.effective_start_date AND
                                           haob.effective_end_date
               AND Trunc (SYSDATE) BETWEEN houf.effective_start_date AND
                                           houf.effective_end_date
               --and org.parent_pk1_value = '300000091524999'
               --and haob.name IN ('MRC - CFM - Biological Services',  'STFC - P Finance - Administration')
               AND haob.name IN (SELECT hauft.name
                                 FROM   hr_organization_v hauft
                                 WHERE  hauft.classification_code =
                                        'HCM_DIVISION'
                                        AND Trunc(SYSDATE) BETWEEN
                                            hauft.effective_start_date
                                            AND
                                            hauft.effective_end_date
                                --AND hauft.NAME = 'STFC - Projects and Grants Section'
                                )
               AND org.pk1_start_value = CHILD2.parent_pk1_value

) DIV_UKSBS

/*-------------------DIV END---------*/ 

WHERE hap.NAME IN ('Customer Service Executive','BAS Engineering Advisor','Category Manager')

AND HAP.POSITION_ID = Incumb_FTE.POSITION_ID(+) 

AND HAP.ACTIVE_STATUS = 'A'

AND hap.organization_id = DIV_UKRI.CHILD_DEPT_ID (+)
AND hap.organization_id = DIV_UKSBS.CHILD_DEPT_ID (+)
--AND hap.organization_id = LE.organization_id(+)



---------------------------------------------------------------------------------------
300000002450582 - SHARP_POS_01048
300000092083508 - 1092486

--------------------------------------------------------------------------

POSITION_ID (300000002450582)
EFFECTIVE_START_DATE (1951-01-01T00:00:00.000+00:00)
EFFECTIVE_END_DATE (4712-12-31T00:00:00.000+00:00)
BUSINESS_UNIT_ID (300000002271993)
POSITION_CODE (SHARP_POS_01048)
NAME (BAS Engineering Advisor)
BUSINESS_GROUP_ID (1)
ORGANIZATION_ID (300000002379785)
JOB_ID (300000002384936)
LOCATION_ID (300000002366842)
ENTRY_GRADE_ID (300000002427270)
ACTION_OCCURRENCE_ID (300000002450581)
ACTIVE_STATUS (A)
HIRING_STATUS (APPROVED)
POSITION_TYPE (SINGLE)
PERMANENT_TEMPORARY_FLAG (R)
FULL_PART_TIME (FULL_TIME)
FTE (1)
CALCULATE_FTE (N)
MAX_PERSONS (1)
POSITION_SYNCHRONIZATION_FLAG (N)
OVERLAP_ALLOWED (N)
SEASONAL_FLAG (N)
OBJECT_VERSION_NUMBER (1)
CREATED_BY (FUSION_APPS_HCM_ESS_LOADER_APPID)
CREATION_DATE (2022-07-01T13:35:45.795+00:00)
LAST_UPDATED_BY (FUSION_APPS_HCM_ESS_LOADER_APPID)
LAST_UPDATE_DATE (2022-07-01T13:35:45.869+00:00)
LAST_UPDATE_LOGIN (E2BF0DFC105A6F40E0532D90D90AD951)

------------------------------------------------------------------






GRADE
--------------------------------

SELECT 'Position Grade Report' Header,
'US' as COUNTRY_CODE,
PSF.POSITION_CODE,
PGFT.NAME as GRADE,
TO_CHAR(PSF.EFFECTIVE_START_DATE,'MM/DD/YYYY') AS EFFECTIVE_START_DATE ,
TO_CHAR(PSF.EFFECTIVE_END_DATE,'MM/DD/YYYY') AS EFFECTIVE_END_DATE
FROM
HR_ALL_POSITIONS_F_TL PFT,
HR_ALL_POSITIONS_F PSF,
HR_ORGANIZATION_UNITS_F_TL PBU,
PER_GRADES_F_TL PGFT,
PER_VALID_GRADES_F PVG
WHERE
PSF.EFFECTIVE_START_DATE = PFT.EFFECTIVE_START_DATE AND PSF.EFFECTIVE_END_DATE = PFT.EFFECTIVE_END_DATE AND PSF.POSITION_ID = PFT.POSITION_ID
AND TRUNC(SYSDATE) BETWEEN PSF.EFFECTIVE_START_DATE AND PSF.EFFECTIVE_END_DATE AND PFT.LANGUAGE = 'US'
AND PSF.BUSINESS_UNIT_ID = PBU.ORGANIZATION_ID
AND PBU.LANGUAGE='US'
AND TRUNC(SYSDATE) BETWEEN PBU.EFFECTIVE_START_DATE AND PBU.EFFECTIVE_END_DATE
AND PSF.POSITION_ID=PVG.POSITION_ID
AND TRUNC(SYSDATE) BETWEEN PVG.EFFECTIVE_START_DATE AND PVG.EFFECTIVE_END_DATE
AND PVG.GRADE_ID=PGFT.GRADE_ID
AND PGFT.LANGUAGE='US'
AND TRUNC(SYSDATE) BETWEEN PGFT.EFFECTIVE_START_DATE AND PGFT.EFFECTIVE_END_DATE

AND PSF.POSITION_CODE = '1088637'


-----------------
DEPT
--------------------------

SELECT hap.NAME as POS , hauft.NAME AS DEPT
FROM   
HR_ORG_UNIT_CLASSIFICATIONS_F houcf, HR_ALL_ORGANIZATION_UNITS_F haouf, HR_ORGANIZATION_UNITS_F_TL hauft,HR_ALL_POSITIONS_X hap

WHERE   haouf.ORGANIZATION_ID = houcf.ORGANIZATION_ID
AND haouf.ORGANIZATION_ID = hauft.ORGANIZATION_ID
AND haouf.EFFECTIVE_START_DATE BETWEEN houcf.EFFECTIVE_START_DATE AND houcf.EFFECTIVE_END_DATE
AND hauft.LANGUAGE = 'US'
AND hauft.EFFECTIVE_START_DATE = haouf.EFFECTIVE_START_DATE
AND hauft.EFFECTIVE_END_DATE = haouf.EFFECTIVE_END_DATE
AND houcf.CLASSIFICATION_CODE = 'DEPARTMENT'
AND SYSDATE BETWEEN hauft.effective_start_date AND hauft.effective_end_date
AND hap.ORGANIZATION_ID = haouf.ORGANIZATION_ID 
AND hap.NAME IN ('Customer Service Executive','BAS Engineering Advisor')


-------------
BU
---------------

SELECT hap.NAME as POS ,hauft.NAME as BU

FROM   HR_ORG_UNIT_CLASSIFICATIONS_F houcf,HR_ALL_POSITIONS_X hap,
HR_ALL_ORGANIZATION_UNITS_F haouf,
HR_ORGANIZATION_UNITS_F_TL hauft
WHERE   haouf.ORGANIZATION_ID = houcf.ORGANIZATION_ID
AND haouf.ORGANIZATION_ID = hauft.ORGANIZATION_ID
AND haouf.EFFECTIVE_START_DATE BETWEEN houcf.EFFECTIVE_START_DATE AND houcf.EFFECTIVE_END_DATE
AND hauft.LANGUAGE = 'US'
AND hauft.EFFECTIVE_START_DATE = haouf.EFFECTIVE_START_DATE
AND hauft.EFFECTIVE_END_DATE = haouf.EFFECTIVE_END_DATE
AND houcf.CLASSIFICATION_CODE = 'FUN_BUSINESS_UNIT'
AND SYSDATE BETWEEN hauft.effective_start_date AND hauft.effective_end_date
AND hap.BUSINESS_UNIT_ID = haouf.ORGANIZATION_ID
AND hap.NAME IN ('Customer Service Executive','BAS Engineering Advisor')

-------------------------
JOB_ID
------------------

SELECT hap.NAME AS POS, pjft.NAME AS JOB

FROM 

HR_ALL_POSITIONS_X hap,per_jobs_x pjft

WHERE pjft.job_id = hap.JOB_ID

and hap.NAME IN ('Customer Service Executive','BAS Engineering Advisor')


LOC:
----------
SELECT hap.NAME AS POS, pld.LOCATION_NAME AS LOCATION

FROM 

HR_ALL_POSITIONS_X hap,per_location_details_x pld

WHERE hap.location_id = pld.location_id(+)

and hap.NAME IN ('Customer Service Executive','BAS Engineering Advisor')



----------------------------------
INCUMBENT_FTE
-------------------------------------
SELECT Positions.name 				"Position Name"
      ,Positions.FTE 				"Position Current FTE"
      ,Positions.INCUMBENT_FTE      "Current Incumbent FTE"
      ,(Positions.FTE - Positions.INCUMBENT_FTE)      "Difference FTE"
  FROM	  
(SELECT HAPFT.NAME,
        HAPF.FTE, 
	    (select SUM(PAWMF.VALUE)
           from PER_ALL_ASSIGNMENTS_M PAAM,
                PER_ASSIGN_WORK_MEASURES_F PAWMF
		  where 1=1
            AND PAAM.POSITION_ID = HAPF.POSITION_ID 
            AND TRUNC(SYSDATE)  BETWEEN PAAM.EFFECTIVE_START_DATE AND PAAM.EFFECTIVE_END_DATE
			AND TRUNC(SYSDATE)  BETWEEN PAWMF.EFFECTIVE_START_DATE AND PAWMF.EFFECTIVE_END_DATE
            AND PAAM.ASSIGNMENT_TYPE = 'E'
		    AND PAAM.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
            AND PAAM.ASSIGNMENT_ID = PAWMF.ASSIGNMENT_ID
            AND PAWMF.UNIT = 'FTE') AS INCUMBENT_FTE
   FROM HR_ALL_POSITIONS_F HAPF, 
        HR_ALL_POSITIONS_F_TL HAPFT
  WHERE HAPF.POSITION_ID = HAPFT.POSITION_ID 
    AND USERENV('LANG') = HAPFT.LANGUAGE 
    AND TRUNC(SYSDATE)  BETWEEN HAPF.EFFECTIVE_START_DATE AND HAPF.EFFECTIVE_END_DATE
    AND TRUNC(SYSDATE)  BETWEEN HAPFT.EFFECTIVE_START_DATE AND HAPFT.EFFECTIVE_END_DATE
    AND HAPFT.NAME IN('Test Position')
  ORDER BY HAPFT.NAME ) Positions
  
  
  
L2_DIVISION_NAME (NERC - British Antarctic Survey)
L1_DIVISION_NAME (NERC - BAS Operations and Engineering)
L0_DIVISION_NAME (NERC - BAS Operations and Engineering Section)
CHILD_DEPT_NAME (NERC - BAS Operations and Engineering Central)
CHILD_DEPT_ID (300000002380744)


ORGANIZATION_ID (300000002377146)
ACTION_CODE (ASG_CHANGE)
WORK_TERMS_ASSIGNMENT_ID (300000002824897)
ASSIGNMENT_ID (300000002824918)
ASSIGNMENT_NAME (Technical)
ASSIGNMENT_NUMBER (E9919)
ASSIGNMENT_SEQUENCE (1)
ASSIGNMENT_STATUS_TYPE (ACTIVE)
ASSIGNMENT_STATUS_TYPE_ID (1)
ASSIGNMENT_TYPE (E)
AUTO_END_FLAG (N)
BARGAINING_UNIT_CODE (SHARP_BOTH)
BUSINESS_GROUP_ID (1)
BUSINESS_UNIT_ID (300000002271993)
CREATED_BY (FUSION_APPS_HCM_ESS_LOADER_APPID)
CREATION_DATE (2022-07-06T05:27:32.884+00:00)
DATE_PROBATION_END (2010-02-28T00:00:00.000+00:00)
EFFECTIVE_END_DATE (4712-12-31T00:00:00.000+00:00)
EFFECTIVE_START_DATE (2023-01-20T00:00:00.000+00:00)
EFFECTIVE_SEQUENCE (1)
FREQUENCY (W)
GRADE_ID (300000002427270)
JOB_ID (300000002384936)
LAST_UPDATE_DATE (2023-02-23T07:01:09.809+00:00)
LAST_UPDATE_LOGIN (F4098EFC4C02EB35E0532D90D90A197B)
LAST_UPDATED_BY (tarunaggarwal@in.ibm.com)
LEGAL_ENTITY_ID (300000002007311)
LEGISLATION_CODE (GB)
LOCATION_ID (300000002366842)
MANAGER_FLAG (N)
NORMAL_HOURS (37)
NOTICE_PERIOD (1)
NOTICE_PERIOD_UOM (M)
OBJECT_VERSION_NUMBER (21)
PERIOD_OF_SERVICE_ID (100000000527392)
PERSON_ID (100000000527390)
PERSON_TYPE_ID (300000000343254)
POSITION_ID (300000002450582)
PRIMARY_WORK_TERMS_FLAG (N)
PRIMARY_ASSIGNMENT_FLAG (Y)
PRIMARY_WORK_RELATION_FLAG (Y)
PRIMARY_FLAG (Y)
PROBATION_PERIOD (6)
PROBATION_UNIT (M)
PROJECTED_ASSIGNMENT_END (2019-12-31T00:00:00.000+00:00)
REASON_CODE (SHARP_ACR_ASSIGNMENT_CHANGEFUN)
SET_OF_BOOKS_ID (300000002265976)
SYSTEM_PERSON_TYPE (EMP)
TIME_NORMAL_FINISH (17:00)
TIME_NORMAL_START (09:00)
WORK_AT_HOME (N)
ACTION_OCCURRENCE_ID (300000090654623)
EFFECTIVE_LATEST_CHANGE (Y)
POSITION_OVERRIDE_FLAG (N)
ALLOW_ASG_OVERRIDE_FLAG (N)
FREEZE_START_DATE (4712-12-31T00:00:00.000+00:00)
FREEZE_UNTIL_DATE (0001-12-30T00:00:00.000+00:00)
ID_FLEX_NUM (1)
SENIORITY_BASIS (ORA_PER_SNDT_DAYS)