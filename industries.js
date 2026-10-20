/* UNDIVIDED · Industry packs
   Same 11 elements, same mirrors, same scoring in every pack. A pack changes WHOSE world the guide writes for
   and WHERE integrity is under pressure in that world. Edit freely: this file is plain data.
   focus = elements that matter most in this field (shown on results and used by the Pathfinder; scoring is unchanged).
   seen  = how the watched / unwatched pair is dressed in this field.
   group = how group programme advice is worded for this field. */
window.INDUSTRIES = {
  general: {
    label: "everyday life", worlds: [],
    name: "General (any walk of life)", short: "General",
    roles: ["Individual", "Team lead", "Senior leader"],
    pressures: [], vocabulary: "", code: "", focus: [], seen: "", group: "", safety: ""
  },
  banking: {
    label: "banking and finance", worlds: ["a busy commercial bank branch", "a microfinance bank in a market town", "an investment desk at quarter end", "a credit committee meeting", "a bureau de change and remittance office", "a bank's internal audit team", "a pension fund office"],
    name: "Banking & finance", short: "Banking",
    roles: ["Teller / officer", "Relationship or branch manager", "Executive / board"],
    pressures: ["sales targets versus what is suitable for the customer", "covering up a reconciliation or posting error", "insider or price-sensitive information", "a high-value client with questionable source of funds", "pressure to approve a loan for a connected person", "bonus-driven shortcuts at quarter end"],
    vocabulary: "tellers, relationship managers, compliance officers, auditors, branch heads, KYC, AML, credit committee, fiduciary duty",
    code: "fiduciary duty to customers; know-your-customer and anti-money-laundering obligations; confidentiality of client information; fair dealing; accurate books and records; escalation of suspicious activity",
    focus: ["hon", "trans", "just"],
    seen: "audit week versus an ordinary Tuesday with no reviewer",
    group: "Pair the Diligence journey with your conduct-risk and AML refresher; run a Council for branch and relationship teams on targets versus suitability.",
    safety: ""
  },
  police: {
    label: "law enforcement", worlds: ["a city police division", "a highway patrol unit", "a police station front desk on a busy night", "a detective unit", "a community policing post", "a traffic checkpoint", "a police training academy"],
    name: "Law enforcement", short: "Law enforcement",
    roles: ["Officer / constable", "Sergeant / inspector", "Command / chief"],
    pressures: ["the code of silence when a colleague crosses a line", "evidence handling and report accuracy", "discretion with a well-connected or familiar suspect", "gifts or 'appreciation' from businesses on the beat", "writing a report that protects the team rather than the truth", "fairness across communities"],
    vocabulary: "officers, partners, sergeants, body-worn camera, incident report, evidence room, internal affairs, community, chain of custody",
    code: "the duty to tell the truth in reports and testimony; impartial treatment of all citizens; refusal of gratuities; the duty to report and intervene in misconduct; protection of evidence",
    focus: ["hon", "just", "pow", "trans"],
    seen: "camera on with a supervisor present versus camera off on a quiet night shift",
    group: "Run Councils by shift or unit on the duty to intervene and report; pair with The Three Fires (Korah) for supervisors.",
    safety: "Keep scenes non-graphic. No weapons handling, tactics, or use-of-force procedure. Focus on honesty, loyalty and fairness, not violence."
  },
  military: {
    label: "military service", worlds: ["a barracks during inspection week", "a unit's supply and logistics office", "a training base", "a staff headquarters", "a military academy", "a peacekeeping camp's admin office", "a unit preparing a readiness report"],
    name: "Military", short: "Military",
    roles: ["Enlisted / junior", "NCO / junior officer", "Senior officer / command"],
    pressures: ["chain of command versus conscience", "reporting readiness, inspection or training results truthfully up the line", "protecting a friend who broke a rule", "misuse of government property or travel funds", "taking credit for a unit's work", "care for subordinates when no one senior is watching"],
    vocabulary: "unit, squad, platoon, NCO, commanding officer, inspection, readiness report, honour code, after-action review",
    code: "honour codes (do not lie, cheat or steal, or tolerate those who do); truthful reporting up the chain; stewardship of government resources; care for subordinates; lawful orders and moral courage",
    focus: ["hon", "pow", "trans", "fam"],
    seen: "an inspection by the command team versus an unsupervised field exercise",
    group: "Use Councils as after-action reviews on moral courage; pair with The Three Fires (Korah) for leaders.",
    safety: "Keep scenes non-graphic and non-tactical. No combat, weapons or operational detail. Focus on honesty, honour and care for people."
  },
  sales: {
    label: "sales", worlds: ["a car dealership", "a pharmaceutical sales team", "an insurance agency", "a software sales team at quarter end", "a real-estate agency", "a retail electronics store", "a telecom sales call centre"],
    name: "Sales", short: "Sales",
    roles: ["Sales representative", "Sales manager", "Sales director / VP"],
    pressures: ["overpromising to close the deal", "hiding a known defect or limitation", "gaming commission or booking deals early", "poaching a colleague's client", "a customer who cannot really afford it", "quota pressure at month end"],
    vocabulary: "pipeline, quota, commission, close, upsell, account, CRM, territory, customer",
    code: "truthful representation of products; fair treatment of customers; accurate booking of revenue; respect for colleagues' accounts",
    focus: ["hon", "cont", "fair"],
    seen: "a deal reviewed by the sales director versus a deal no one will ever audit",
    group: "Run a Council on quota versus customer; the Diligence journey for reps; The Three Fires (Balaam) for managers.",
    safety: ""
  },
  education: {
    label: "education", worlds: ["a public secondary school", "a private primary school", "a university department", "an exam board marking centre", "a boarding school", "a vocational college", "a school staff room during exam season"],
    name: "Education (teachers & staff)", short: "Education",
    roles: ["Teacher / lecturer", "Head of department", "Principal / dean"],
    pressures: ["grade inflation or pressure to change a mark", "favouritism toward a child of a colleague, donor or official", "staff covering for a colleague's misconduct", "exam security and leaked papers", "safeguarding concerns that are easier to ignore", "honest reporting of results to inspectors"],
    vocabulary: "students, parents, staff room, head of department, exams, marking, inspection, safeguarding",
    code: "fairness in assessment; safeguarding of children; honesty in records and results; professional boundaries; confidentiality",
    focus: ["fair", "just", "hon", "trans"],
    seen: "an inspection visit versus an ordinary week of marking",
    group: "Councils for staff on fairness in marking and safeguarding; the Diligence journey as a professional-growth track.",
    safety: "Safeguarding scenes stay non-graphic and never describe abuse; focus on the duty to report."
  },
  healthcare: {
    label: "healthcare", worlds: ["a hospital ward on night shift", "a community clinic", "a pharmacy", "a dental practice", "a care home", "an emergency department", "a hospital billing office"],
    name: "Healthcare", short: "Healthcare",
    roles: ["Nurse / clinician / therapist", "Unit manager / consultant", "Medical director / executive"],
    pressures: ["documentation that matches what really happened", "covering a colleague's error", "billing and coding for more than was done", "patient privacy and gossip", "gifts or incentives from suppliers", "honesty with a patient about a mistake"],
    vocabulary: "patients, ward, chart, handover, consultant, billing, incident report, confidentiality",
    code: "patient safety first; honest documentation; patient confidentiality; disclosure of errors; avoidance of conflicts of interest",
    focus: ["hon", "trans", "char"],
    seen: "an accreditation visit versus a quiet night shift",
    group: "Councils on error disclosure and documentation; pair with the Diligence journey for clinical teams.",
    safety: "No graphic medical detail."
  },
  ministry: {
    label: "church and ministry", worlds: ["a 400-member city church", "a rural congregation", "a church finance committee", "a youth ministry", "a Christian charity", "a church building project", "a ministry's counselling team"],
    name: "Church & ministry", short: "Ministry",
    roles: ["Worker / volunteer", "Pastor / department head", "Senior pastor / board"],
    pressures: ["offerings, tithes and church finances", "pastoral confidentiality", "favouritism toward big givers or family", "the leader's private life", "inflating attendance or testimonies", "using the pulpit for personal disputes"],
    vocabulary: "congregation, elders, deacons, offering, treasurer, ministry, pulpit, counselling, board",
    code: "faithful stewardship of offerings; confidentiality in counselling; integrity in the leader's private life; fairness without favouritism; truthfulness in reports",
    focus: ["trans", "cont", "chas", "just"],
    seen: "a Sunday service in front of the congregation versus a Tuesday alone with the books",
    group: "A seven-week Council series (one gate a week) with sermons on Job 31; The Three Fires for elders.",
    safety: ""
  },
  government: {
    label: "public service", worlds: ["a ministry procurement unit", "a state licensing office", "a local government council", "a customs post", "a land registry office", "a public hospital board", "a federal agency's budget office"],
    name: "Government & public service", short: "Public service",
    roles: ["Officer / clerk", "Director / head of unit", "Permanent secretary / commissioner"],
    pressures: ["bribes presented as 'gifts' or 'settlement'", "procurement steered to a friend or relative", "family and community expectations to 'help our own'", "fast-tracking a file for a connected person", "honest reporting of budgets and project completion", "using official vehicles and resources privately"],
    vocabulary: "ministry, file, procurement, tender, memo, permanent secretary, citizens, constituency",
    code: "public office is a public trust; impartial service to every citizen; declaration of conflicts and gifts; transparent procurement; stewardship of public resources",
    focus: ["just", "fair", "trans", "cont"],
    seen: "an anti-corruption audit versus an ordinary file on an ordinary afternoon",
    group: "Councils by department on gifts, procurement and family pressure; The Three Fires (Balaam) for directors.",
    safety: ""
  },
  legal: {
    label: "the law", worlds: ["a mid-sized law firm", "a corporate legal department", "a public defender's office", "a property law practice", "a litigation team before trial", "a court registry", "a legal aid clinic"],
    name: "Legal", short: "Legal",
    roles: ["Associate / paralegal", "Partner / senior counsel", "Managing partner / general counsel"],
    pressures: ["duty to the court versus the client's wishes", "conflicts of interest", "billing more hours than worked", "a document that hurts your own client", "confidentiality with a tempting third party", "misleading by technically true statements"],
    vocabulary: "client, matter, filing, discovery, billable hours, partner, court, privilege",
    code: "candour to the court; loyalty and confidentiality to the client; honest billing; avoidance and disclosure of conflicts",
    focus: ["hon", "just", "trans"],
    seen: "a filing a judge will scrutinize versus a timesheet no one checks",
    group: "Councils on candour and billing; the IPI for partners.",
    safety: ""
  },
  technology: {
    label: "technology", worlds: ["a fintech start-up", "a large software company", "an AI product team", "a data analytics agency", "a mobile app studio", "an IT support company", "a cybersecurity consultancy"],
    name: "Technology & AI", short: "Technology",
    roles: ["Engineer / analyst", "Engineering or product manager", "CTO / executive"],
    pressures: ["shipping with a known flaw to hit a deadline", "quietly fixing a data breach instead of disclosing it", "using customer data in ways they didn't agree to", "dark patterns that trick users", "taking credit for a teammate's code", "overstating what the AI can do"],
    vocabulary: "release, sprint, incident, user data, product, dashboard, model, launch, postmortem",
    code: "honest disclosure of incidents; respect for user data and consent; truthful claims about capabilities; credit where it is due",
    focus: ["hon", "trans", "just"],
    seen: "a launch review with leadership versus a late-night commit no one reviews",
    group: "Councils on incident disclosure and user data; the Diligence journey for engineering teams.",
    safety: ""
  },
  construction: {
    label: "construction and engineering", worlds: ["a high-rise building site", "a road-construction project", "an engineering consultancy", "a bridge repair project", "a housing estate development", "a pipeline contractor", "a materials supplier's yard"],
    name: "Construction & engineering", short: "Construction",
    roles: ["Site worker / technician", "Site engineer / foreman", "Project director"],
    pressures: ["safety shortcuts to beat a deadline", "signing off on substandard work", "inspection fraud", "substituting cheaper materials", "under-reporting a near-miss", "paying 'facilitation' to move a permit"],
    vocabulary: "site, foreman, inspection, sign-off, permit, materials, near-miss, client, contractor",
    code: "safety above schedule; honest inspection and sign-off; materials as specified; reporting of near-misses",
    focus: ["just", "hon", "trans"],
    seen: "an inspector on site versus a Saturday shift with no one checking",
    group: "Toolbox-talk Councils on safety and sign-off; the Diligence journey for site leaders.",
    safety: "No graphic injury detail."
  },
  students: {
    label: "school", worlds: [],
    name: "Students (school)", short: "Students",
    roles: ["Student", "Class or team captain", "Student leader / prefect"],
    pressures: ["exams and homework honesty", "group chats and sharing about others", "team selection and loyalty", "AI and copying", "standing up for someone being targeted", "honesty with parents and teachers"],
    vocabulary: "class, teacher, group chat, team, exam, prefect, captain, parents",
    code: "academic honesty; kindness and respect online; fairness in teams; telling the truth to teachers and parents",
    focus: ["hon", "fair", "mercy"],
    seen: "a test with the teacher watching versus homework done alone",
    group: "Class Councils; student-led replays; a 30-day promise challenge with buddies.",
    safety: "Age-appropriate only."
  },
  mit: {
    label: "manufacturing", worlds: ["a heavy-equipment assembly line", "a machining and welding cell", "a parts warehouse", "a paint and finishing shop", "a quality inspection station", "a night shift on the main line", "a new-hire apprenticeship crew"],
    name: "Manufacturing Identity Track (Rebuilt Workplace)", short: "Manufacturing (MIT)",
    roles: ["Apprentice / new hire", "Operator / team lead", "Supervisor / plant manager"],
    pressures: ["safety and lockout procedures when the line is behind", "quality sign-off on parts that are 'close enough'", "time-card and break honesty", "scrap, tools and materials walking out the door", "reporting a near-miss that would embarrass the crew", "peer pressure from the old crew versus the new identity", "a second-chance hire being tested or set up by others", "favouritism in overtime and shift assignments"],
    vocabulary: "plant floor, line, shift, lead hand, supervisor, quality check, lockout/tagout, near-miss, overtime, apprentice, crew",
    code: "safety first for yourself and your crew; honest quality sign-off; honest time and materials; reporting near-misses; dignity and second chances for every worker",
    focus: ["hon", "just", "opp", "fam"],
    seen: "a quality audit with the plant manager on the floor versus the last hour of a night shift",
    group: "Run Undivided at Day 0 and Day 100 of the Manufacturing Identity Track as a behavioural outcome measure; follow with the Integrity Track (Integrity Commons) and the Culture Track (The Three Fires).",
    safety: "No graphic injury detail. Treat second-chance workers with dignity; never stereotype."
  }
};
window.INDUSTRY_ORDER = ["general","banking","police","military","sales","education","healthcare","ministry","government","legal","technology","construction","students","mit"];
