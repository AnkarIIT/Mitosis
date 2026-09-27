# Exam Engine Blueprint
## NEET Mitos — Complete System Design

---

## 1. What Is an Exam Engine?

An **exam engine** is the core software system that delivers, manages, and evaluates an examination. It is not just a quiz app — it is a **real-time, stateful, secure testing platform** that handles:

- **Question delivery** in the right order/shuffle/section
- **Timer management** with section-wise and total time limits
- **Answer persistence** with autosave and crash recovery
- **Marking scheme enforcement** (positive/negative marking, optional sections)
- **Session integrity** (prevent tab-switch cheating, fullscreen enforcement)
- **Result calculation** with analytics and reporting
- **Audit logging** for every action

---

## 2. How NTA's Exam Engine Works

Based on NTA tender documents and official CBT guidelines:

### 2.1 Overview
NTA conducts **Computer-Based Tests (CBT)** at authorized centers across India. The exam is delivered via **Intranet/LAN** — not internet. This means:

- Questions are pre-loaded on local servers at each center
- Candidates sit at computer terminals allocated by roll number
- The system prevents question paper leakage
- No post-test OMR malpractice
- Real-time editing of answers before submission

### 2.2 Key Characteristics

| Feature | NTA Implementation |
|---------|-------------------|
| **Mode** | CBT (Computer-Based Test) via Intranet/LAN |
| **Duration** | 1-3 hours per shift |
| **Shifts** | 1-3 shifts per day |
| **Volume** | ~1 crore candidates across exams annually |
| **Questions** | Pre-defined pool, psychometrically indexed |
| **Delivery** | Mouse-based selection, on-screen questions |
| **Marking** | +4 correct, -1 incorrect (NEET pattern) |
| **Accessibility** | Bigger fonts, customized colors, scribe support, extra time |
| **Security** | Biometric registration, no leakage, no post-test malpractice |

### 2.3 NTA Exam Flow

```
Candidate Registration
        ↓
Admit Card Generation (with center/seat)
        ↓
Biometric Verification at Center
        ↓
Login at Allocated Terminal
        ↓
Instructions Screen (5-10 mins)
        ↓
Exam Starts (Timer begins)
        ↓
Question Display (one at a time or grid)
       ↓
Answer Selection (mouse click)
        ↓
Section Navigation (if multi-section)
        ↓
Auto-save every few seconds
        ↓
Time Up OR Manual Submit
        ↓
Confirmation Screen
        ↓
Result Processing (server-side)
        ↓
Scorecard / Percentile / Rank
```

### 2.4 NTA CBT Features

1. **Question Delivery**: Questions appear on screen; candidate uses mouse to select answer
2. **Navigation**: Move between questions, mark for review, section-wise navigation
3. **Timer**: Countdown timer visible; auto-submit when time expires
4. **Color Coding**: 
   - Unattempted: default
   - Attempted: colored
   - Marked for review: different color
   - Unattempted + Marked: combined indicator
5. **Language Selection**: Choose medium of exam
6. **Accessibility**: High contrast, larger fonts, screen reader support
7. **Biometric**: Fingerprint/iris verification at entry
8. **No Back Button**: Once submitted, cannot return

---

## 3. Complete Exam Engine Blueprint

### 3.1 Feature Breakdown

#### A. Pre-Exam Features
| Feature | Description |
|---------|-------------|
| **Exam Catalog** | List available exams with schedules, duration, marks |
| **Registration** | User registration, eligibility checks, slot booking |
| **Admit Card** | Generate hall ticket with center, seat, timing |
| **System Check** | Pre-exam demo/test to verify camera, mic, internet |
| **Instructions** | Detailed exam rules, marking scheme, navigation help |

#### B. During-Exam Features
| Feature | Description |
|---------|-------------|
| **Fullscreen Mode** | Prevent tab-switching, detect focus loss |
| **Timer** | Total time + section-wise timers with warning alerts |
| **Question Palette** | Grid showing attempted/unattempted/marked status |
| **Question Navigation** | Next/prev/section jump, bookmark for review |
| **Answer Selection** | Single-choice, multi-choice, integer type, drag-drop |
| **Auto-save** | Save answer every 2-3 seconds to local + server |
| **Calculater** | On-screen calculator for numeric subjects |
| **Highlight/Notes** | Mark important text in passage questions |
| **Language Switch** | Change question language mid-exam |
| **Zoom** | Magnify question text/images |
| **Break Management** | Optional break between sections |
| **Chat/Support** | Raise technical queries during exam |

#### C. Post-Exam Features
| Feature | Description |
|---------|-------------|
| **Auto-submit** | Submit automatically when timer hits zero |
| **Confirmation** | "Are you sure?" dialog before final submit |
| **Response Review** | Show submitted answers vs correct answers |
| **Score Calculation** | Apply marking scheme, negative marking |
| **Analytics** | Subject-wise performance, time per question, accuracy |
| **Rank/Percentile** | Compare with all test-takers |
| **Solutions** | Detailed explanation for each question |
| **Certificate** | Generate scorecard/certificate for qualifying exams |

#### D. Admin Features
| Feature | Description |
|---------|-------------|
| **Question Bank** | CRUD for questions with tags, difficulty, subjects |
| **Exam Builder** | Create exam with sections, duration, marking scheme |
| **Randomization** | Shuffle questions/options per candidate |
| **Scheduling** | Set exam date/time, duration, allowed attempts |
| **Proctoring** | Live video monitoring, tab-switch detection |
| **Result Publishing** | Release results, generate reports |
| **Analytics Dashboard** | Pass rates, average scores, difficult questions |

---

### 3.2 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Web App    │  │ Mobile App   │  │ Desktop/Kiosk    │  │
│  │  (React/Next)│  │  (Flutter)   │  │  (Electron)      │  │
│  └──────┬───────┘  └──────┬───────┘  └───────┬──────────┘  │
└─────────┼─────────────────┼──────────────────┼─────────────┘
          │                 │                  │
          └─────────────────┼──────────────────┘
                            │ HTTPS/WSS
┌───────────────────────────▼─────────────────────────────────┐
│                      API GATEWAY                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Load Balancer → Rate Limiting → Auth → Routing     │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    APPLICATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Exam Service │  │ Auth Service │  │ Proctoring Svc   │   │
│  │ - Start exam │  │ - Login/Reg  │  │ - Video capture  │   │
│  │ - Timer      │  │ - JWT/SSO    │  │ - Tab detection  │   │
│  │ - Submit     │  │ - RBAC       │  │ - AI flags       │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Question Svc │  │ Result Svc   │  │ Notification Svc │   │
│  │ - Bank mgmt  │  │ - Auto grade │  │ - Email/SMS      │   │
│  │ - Randomize  │  │ - Analytics  │  │ - Push notify    │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                       DATA LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ PostgreSQL   │  │    Redis     │  │   S3/Blob        │   │
│  │ - Users      │  │ - Sessions   │  │ - Images/PDFs    │   │
│  │ - Exams      │  │ - Rate limit │  │ - Attachments    │   │
│  │ - Questions  │  │ - Cache      │  │                  │   │
│  │ - Responses  │  │ - Queues     │  │                  │   │
│  │ - Results    │  │              │  │                  │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    EXTERNAL SERVICES                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │   Email      │  │   Payment    │  │   Proctoring AI  │   │
│  │   (SendGrid) │  │  (Razorpay)  │  │  (Face/Screen)   │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 Data Model

#### Core Entities

```sql
-- Users & Roles
users (id, email, phone, role, created_at)
candidates (id, user_id, roll_number, center_id, dob, category)
centers (id, name, address, city, capacity, intranet_ip)

-- Exam Structure
exams (id, name, code, mode, duration_minutes, total_marks, negative_marks, is_published)
exam_sections (id, exam_id, name, duration_seconds, question_count, order_index)
questions (id, exam_id, section_id, text, image_url, type, difficulty, tags, marks, negative_marks)
options (id, question_id, text, is_correct, order_index)
question_tags (id, question_id, tag, weight)

-- Exam Sessions
exam_sessions (id, exam_id, candidate_id, start_time, end_time, status, score, percentile, rank)
session_events (id, session_id, event_type, timestamp, metadata)
-- event_type: START, SUBMIT, AUTOSAVE, TAB_SWITCH, FLAG, BREAK_START, BREAK_END

-- Responses
responses (id, session_id, question_id, selected_option_ids, is_marked_for_review, time_spent_seconds, answered_at)
submissions (id, session_id, submitted_at, ip_address, user_agent, proctoring_data)

-- Results & Analytics
results (id, session_id, total_score, correct_count, wrong_count, unattempted_count, percentile, rank)
subject_wise_scores (id, result_id, subject, score, max_score, accuracy)
question_analytics (id, question_id, exam_id, total_attempts, correct_count, avg_time_seconds)
```

#### Key Relationships
- One `exam` → Many `exam_sections`
- One `exam_section` → Many `questions`
- One `question` → Many `options`
- One `candidate` → Many `exam_sessions`
- One `exam_session` → Many `responses`
- One `exam_session` → One `result`

### 3.4 API Design

#### RESTful Endpoints

```yaml
# Exam Catalog
GET    /api/v1/exams                    # List available exams
GET    /api/v1/exams/{id}               # Exam details
GET    /api/v1/exams/{id}/sections      # Get sections

# Exam Session
POST   /api/v1/exams/{id}/start         # Start exam → returns session_id
GET    /api/v1/sessions/{id}            # Get session state
POST   /api/v1/sessions/{id}/save       # Autosave response
POST   /api/v1/sessions/{id}/submit     # Submit exam
GET    /api/v1/sessions/{id}/result     # Get result

# Questions (served in batches)
GET    /api/v1/sessions/{id}/questions  # Get next set of questions
GET    /api/v1/sessions/{id}/question/{qid}  # Get specific question

# Proctoring
POST   /api/v1/sessions/{id}/events     # Log proctoring events
POST   /api/v1/sessions/{id}/snapshot   # Upload webcam snapshot

# Admin
POST   /api/v1/admin/questions          # Create question
PUT    /api/v1/admin/questions/{id}     # Update question
POST   /api/v1/admin/exams              # Create exam
POST   /api/v1/admin/exams/{id}/publish # Publish exam
GET    /api/v1/admin/exams/{id}/analytics  # Get exam analytics
```

#### WebSocket Events (Real-time)

```yaml
# Server → Client
session:timer_update       # Every second: remaining time
session:warning            # 5 min left, 1 min left
session:auto_submit        # Time's up — submitting
session:force_submit       # Admin forced submit
session:disconnect         # Network lost — retry

# Client → Server
question:answer           # Save answer
question:flag             # Mark for review
question:navigate         # Jump to question
session:heartbeat         # Keep-alive ping
```

### 3.5 Implementation Plan

#### Phase 1: Core Exam Engine (Weeks 1-3)
- [ ] Database schema design & migrations
- [ ] Question bank CRUD with tags/difficulty
- [ ] Exam builder with sections, duration, marking
- [ ] Question randomization engine
- [ ] Basic exam session creation
- [ ] Question delivery API (paginated)

#### Phase 2: Exam Delivery (Weeks 4-6)
- [ ] Timer service (total + section-wise)
- [ ] Autosave mechanism (local + server)
- [ ] Answer persistence & recovery
- [ ] Question palette UI
- [ ] Navigation (next/prev/section jump)
- [ ] Mark for review functionality

#### Phase 3: Advanced Features (Weeks 7-9)
- [ ] Negative marking calculation
- [ ] Optional sections ("attempt any N of M")
- [ ] Break management between sections
- [ ] Proctoring integration (tab-switch, fullscreen)
- [ ] Image/equation rendering in questions
- [ ] Multi-language support

#### Phase 4: Results & Analytics (Weeks 10-11)
- [ ] Auto-evaluation engine
- [ ] Score calculation with analytics
- [ ] Subject-wise performance breakdown
- [ ] Time-per-question analytics
- [ ] Percentile/rank calculation
- [ ] Result PDF generation

#### Phase 5: Polish & Scale (Weeks 12-13)
- [ ] Stress testing (1000+ concurrent)
- [ ] Offline mode with sync
- [ ] Accessibility (screen reader, high contrast)
- [ ] Mobile optimization
- [ ] CI/CD for exam deployments

---

## 4. Exam Engine in NEET Mitos (Current State)

### What Exists
| Component | Status |
|-----------|--------|
| `exam_engine_service.dart` | Core engine with `ExamConfig`, `ExamSection`, `ExamSession` |
| `cbt_test_screen.dart` | Main exam UI with timer, palette, navigation |
| `cbt_result_screen.dart` | Result screen with score breakdown |
| `exam_checkpoint_service.dart` | Autosave/recovery service |
| Question model | `QuestionModel` with options, subject, difficulty |
| DPP Engine | `dpp_engine.dart` for practice papers |

### What Needs Enhancement
| Gap | Description |
|-----|-------------|
| **Proctoring** | No tab-switch detection, no fullscreen enforcement |
| **Section Lock** | Section-wise timer not fully implemented |
| **Break Management** | No break between sections |
| **Auto-submit** | Needs robust crash recovery |
| **Analytics** | Limited post-exam analytics |
| **Randomization** | Question/option shuffle needs verification |
| **Accessibility** | No screen reader, no high contrast mode |
| **Offline** | No offline exam mode |

---

## 5. Key Design Principles

### 5.1 Backend-First Validation
Never trust the client. All exam logic must be validated server-side:
- Timer must be server-enforced, not just client-side
- Answers must be validated against question bank
- Score must be calculated server-side

### 5.2 Session-Centric Design
Everything ties to `session_id`:
- All responses linked to session
- All events logged with session_id
- Autosave uses session_id as key
- Proctoring data tied to session

### 5.3 Graceful Degradation
- Network drop → continue exam offline, sync when back
- Server error → local autosave, retry mechanism
- Browser crash → recover from last saved state

### 5.4 Security
- Questions never sent in bulk — paginated delivery
- Answers encrypted in transit
- Proctoring data signed and timestamped
- No client-side score calculation

---

## 6. Technology Stack Recommendations

| Layer | Technology | Reason |
|-------|-----------|--------|
| **Frontend** | Flutter / React | Cross-platform, offline support |
| **Backend** | Node.js / FastAPI / Go | High concurrency, real-time |
| **Database** | PostgreSQL | Relational integrity for results |
| **Cache** | Redis | Session state, rate limiting, leaderboard |
| **Queue** | BullMQ / Celery | Async grading, report generation |
| **Storage** | S3 / MinIO | Question images, PDFs, attachments |
| **Proctoring** | WebRTC + AI | Face detection, tab-switch, screen recording |
| **Real-time** | WebSockets / Socket.io | Timer, autosave, warnings |

---

## 7. NTA-Specific Requirements for NEET

Based on NTA CBT guidelines and NEET pattern:

| Requirement | Implementation |
|-------------|----------------|
| **180 questions** | 180 MCQ questions in 180 minutes |
| **3 subjects** | Physics (45), Chemistry (45), Biology (90) |
| **Marking** | +4 correct, -1 wrong, 0 unattempted |
| **Max marks** | 720 |
| **Language** | English + 13 regional languages |
| **Mode** | CBT (mouse-based selection) |
| **Accessibility** | Larger fonts, high contrast, scribe support |
| **Security** | Biometric verification, no cheating tools |

---

## 8. References

1. NTA Test Administration — https://www.nta.ac.in/TestAdministration
2. NTA CBT Tender 2024 — http://nta.ac.in/Download/Tender/Tender_20260302181817.pdf
3. SafeExam Architecture — https://safexam.in/docs/architecture
4. Backend Architecture of Online Exam — https://medium.com/@alfaz1873/designing-the-backend-architecture-of-an-online-examination-system-8911d72f4c77
5. NEET 2027 CBT Pattern — https://unacademy.com/content/neet-ug/neet-2027-cbt-mode-exam-pattern/

---

*Generated for NEET Mitos Project*
*Date: 2025*
