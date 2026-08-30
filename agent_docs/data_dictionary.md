# Data Dictionary: International Student Wellbeing Analytics

## Students Table

### Core Fields

| Field Name | Data Type | Valid Range | Description |
|-----------|-----------|-------------|-------------|
| id | INT | 1+ | Unique student identifier, auto-incremented primary key |
| inter_dom | VARCHAR(10) | 'Inter', 'Dom' | Student classification: Inter (International) or Dom (Domestic) |
| region | VARCHAR(50) | SEA, EA, SA, JAP, Others | Geographic region of origin |
| stay | INT | 1-10 | Duration of enrollment in years at institution |
| todep | DECIMAL(5,2) | 0-50 | PHQ-9 Depression Score (Patient Health Questionnaire-9) |
| tosc | DECIMAL(5,2) | 0-100 | Social Connectedness Scale Score (SCS) |
| toas | DECIMAL(5,2) | 0-100 | Anxiety Scale Score (ASISS) |
| created_at | TIMESTAMP | - | Time when record was created (system generated) |
| updated_at | TIMESTAMP | - | Time when record was last updated (system generated) |

---

## Field Definitions and Interpretations

### inter_dom (Student Classification)

**Values:**
- `Inter`: International student (primary focus of analysis)
- `Dom`: Domestic student (comparative group)

**Usage**: Primary segmentation dimension for comparative analysis between international and domestic student wellbeing

**Educational Context**: International students face unique challenges including cultural adaptation, language barriers, visa uncertainties, and geographic separation from support networks

---

### region (Geographic Origin)

**Valid Values:**
- `SEA`: Southeast Asia (Malaysia, Thailand, Indonesia, Vietnam, Philippines, etc.)
- `EA`: East Asia (China, South Korea, Taiwan, Hong Kong, etc.)
- `SA`: South Asia (India, Pakistan, Bangladesh, Sri Lanka, etc.)
- `JAP`: Japan
- `Others`: Other geographic regions

**Usage**: Secondary segmentation for cross-cultural wellbeing pattern analysis

**Analytical Purpose**: Identify cultural and regional variations in mental health outcomes and support needs

---

### stay (Duration of Enrollment)

**Valid Range**: 1 to 10 years

**Measurement**: Academic years or calendar years of continuous enrollment

**Mean-Centered Values**: 
- Short-term: 1-2 years
- Medium-term: 3-4 years  
- Long-term: 5-10 years

**Key Finding**: Stay duration shows strong correlation with wellbeing outcomes
- Students with shorter stays show higher anxiety
- Students with longer stays show improved social connectedness

**Analytical Questions**:
- Does wellbeing improve with length of stay?
- What is the optimal support timeline?
- When is intervention most critical?

---

### todep (PHQ-9 Depression Score)

**Assessment Tool**: Patient Health Questionnaire-9

**Valid Range**: 0-50 (but typically 0-27 in standard administration)

**Score Interpretation**:
- 0-4: None or minimal depression
- 5-9: Mild depression
- 10-14: Moderate depression
- 15-19: Moderately severe depression
- 20-27: Severe depression

**Calculation**: Sum of 9 items rated 0-3 each (Not at all, Several days, More than half the days, Nearly every day)

**Key Items Assessed**:
- Little interest or pleasure in doing activities
- Feeling down, depressed, or hopeless
- Trouble falling or staying asleep
- Feeling tired or having little energy
- Poor appetite or overeating
- Feeling bad about self
- Trouble concentrating on tasks
- Feeling slow or restless
- Thoughts that would be better off dead

**Portfolio Context**: International students frequently elevated scores due to:
- Academic pressure and adjustment
- Separation from family support systems
- Cultural and linguistic challenges
- Uncertainty about future opportunities

**Data Quality Note**: Values should typically range 0-27; values 28-50 may indicate data entry errors or extended rating scales

---

### tosc (Social Connectedness Scale Score)

**Assessment Tool**: Social Connectedness Scale (SCS or similar)

**Valid Range**: 0-100 (or 8-48 depending on specific instrument version)

**Score Interpretation**:
- Higher scores: Greater sense of social belonging and connection
- Lower scores: Social isolation and disconnection from community

**Dimensions Assessed**:
- Sense of belonging
- Social support availability
- Community integration
- Relationship quality
- Perceived acceptance by peers

**Key Finding**: International students with shorter stays show 28% lower social connectedness
- Limited time to build support networks
- Cultural and linguistic barriers
- Geographic distance from family
- Different social norms and expectations

**Portfolio Context**: Social connectedness is protective factor against depression and anxiety
- Strong predictor of mental health outcomes
- Indicates successful cultural adaptation
- Shows integration into host country community

**Data Quality Note**: Lower scores warrant early intervention for international student support services

---

### toas (Anxiety Scale Score)

**Assessment Tool**: Anxiety Sensitivity Index and Social Interaction Scales (ASISS or similar)

**Valid Range**: 0-100

**Score Interpretation**:
- 0-25: Low anxiety
- 26-50: Moderate anxiety  
- 51-75: High anxiety
- 76-100: Severe anxiety

**Dimensions Assessed**:
- Physical anxiety symptoms
- Fear of anxiety itself
- Social anxiety in interactions
- Fear of negative evaluation
- Academic performance anxiety

**Key Finding**: International students with shorter stays show 34% higher anxiety scores
- Academic acculturation stress
- Language proficiency concerns
- Social interaction anxiety
- Uncertainty about future outcomes

**Portfolio Context**: Anxiety is key operational metric for intervention planning
- Highest in first 6-12 months (critical window)
- Decreases with adaptation and time
- Strong correlation with study success

**Data Quality Note**: Sustained high scores indicate student at risk and requiring proactive support

---

## Data Quality Standards

### Completeness Requirements
- All key metrics (stay, todep, tosc, toas) must be present
- Missing values should be minimal (target: <1%)
- Student classification and region should be populated where possible

### Valid Range Checks
- stay: 1-10 (students outside this range excluded)
- todep: 0-50 (standard assessment range)
- tosc: 0-100 (standard assessment range)
- toas: 0-100 (standard assessment range)

### Outlier Handling
Values outside expected ranges may indicate:
- Data entry errors (should be investigated)
- Extended or non-standard assessment versions
- Special populations with different scoring
- Potential data quality issues

### Recommended Validation Queries
```sql
-- Check for out-of-range values
SELECT * FROM students 
WHERE stay NOT BETWEEN 1 AND 10 
   OR todep NOT BETWEEN 0 AND 50 
   OR tosc NOT BETWEEN 0 AND 100 
   OR toas NOT BETWEEN 0 AND 100;

-- Check for missing key values
SELECT COUNT(*) as missing_count
FROM students 
WHERE stay IS NULL 
   OR todep IS NULL 
   OR tosc IS NULL 
   OR toas IS NULL;
```

---

## Analytical Dimensions

### Primary Segmentation
- **Inter_dom**: Primary grouping for comparative analysis (International vs. Domestic)

### Secondary Segmentation  
- **region**: Cultural origin and geographic analysis
- **stay**: Temporal progression and duration-based risk stratification

### Outcome Metrics
- **todep**: Depression indicator (risk dimension 1)
- **tosc**: Social connectedness indicator (protective factor)
- **toas**: Anxiety indicator (risk dimension 2)

### Analysis Patterns

**By Duration**:
```sql
SELECT stay, AVG(todep), AVG(tosc), AVG(toas)
FROM students 
WHERE inter_dom = 'Inter'
GROUP BY stay
ORDER BY stay;
```

**By Region**:
```sql
SELECT region, AVG(todep), AVG(tosc), AVG(toas)
FROM students 
WHERE inter_dom = 'Inter'
GROUP BY region;
```

**Risk Stratification**:
```sql
SELECT 
    CASE 
        WHEN todep > 20 THEN 'High Risk - Depression'
        WHEN toas > 75 THEN 'High Risk - Anxiety'
        WHEN tosc < 25 THEN 'High Risk - Isolation'
        ELSE 'Moderate/Low Risk'
    END as risk_category,
    COUNT(*) as student_count
FROM students
WHERE inter_dom = 'Inter'
GROUP BY risk_category;
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 28, 2026 | Initial data dictionary creation for Phase 1 |

---

## References

- **PHQ-9**: Kroenke K, Spitzer RL. The PHQ-9: A new depression diagnostic and severity measure. Psychiatric Annals. 2002;32(9):509-521.
- **Social Connectedness Scale**: Lee RM, Draper M, Lee S. Social connectedness, extraversion, and subjective well-being: Testing a mediation model. Personality and Individual Differences. 2001;31(7):1033-1039.
- **Anxiety Scales**: Taylor S, Zvolensky MJ. Anxiety sensitivity: Theory, research, and treatment of the fear of anxiety. Mahwah: Lawrence Erlbaum Associates; 2006.

---

**Document Owner**: Data Analytics Team  
**Last Updated**: February 28, 2026  
**Status**: Active - Phase 1 Complete
