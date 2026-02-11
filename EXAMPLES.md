# Adobe-Specific Workflow Examples

## Example 1: Complete Developer Journey - Zero to Feature Delivery

### Scenario
You're a new developer assigned to add a "password reset via email" feature to an existing user management service. You have **zero knowledge** of the codebase.

### Day 0: Project Setup & Understanding (1 hour)

#### Step 1: Setup Environment
```bash
cd ~/user-management-service
setup-claude-config
# Detected: python (+ docker, kubernetes)
```

#### Step 2: Understand Overall Architecture
```bash
# Use code-archaeologist to reverse-engineer existing codebase
@code-archaeologist "Analyze this project's architecture, tech stack, and existing patterns"
```

**Agent Deployed:** `@code-archaeologist`

**What You Learn:**
```
🔍 Code Archaeology Report: Project Architecture
├── Tech Stack: Python 3.11, FastAPI, PostgreSQL, Redis
├── Auth System: JWT with Adobe IMS integration
├── Email Service: SendGrid integration exists!
├── Deployment: Docker + Kubernetes on Ethos
└── Security: Input validation, rate limiting present

Dependency Graph:
API Layer → Service Layer → Data Layer
     ↓           ↓            ↓
  FastAPI   Email/Auth    PostgreSQL/Redis

Technical Debt:
✓ Well-structured with clear separation of concerns
✓ Security patterns already in place
```

**Key Discovery:** Email service already exists - you can reuse it!

---

### Day 1: Feature Exploration & Planning (2 hours)

#### Step 3: Explore Existing Auth System
```bash
# Use epcc-explore to understand auth system in context of implementing password reset
/epcc:epcc-explore --deep "understand how authentication and user management works"
```

**Agent Deployed:** `@code-archaeologist` (via EPCC workflow)

**What You Discover:**
```
🔍 Authentication Flow Analysis
├── User model: src/models/user.py
│   └── Fields: id, email, password_hash, created_at
│   ⚠️  Missing: reset_token, reset_token_expires
│
├── Auth endpoints: src/api/auth.py
│   ├── POST /auth/login (exists)
│   ├── POST /auth/register (exists)
│   └── POST /auth/reset-password (MISSING - your task!)
│
├── Email service: src/services/email_service.py
│   ✓ send_welcome_email() exists
│   ✓ send_verification_email() exists
│   → Can create send_password_reset_email()
│
└── Security patterns:
    ✓ Rate limiting: 5 req/min on auth endpoints
    ✓ Input validation with Pydantic
    ✓ Secrets in AWS Secrets Manager
```

#### Step 4: Design Your Feature
```bash
/architecture-design "Password reset via email feature:
- POST /auth/forgot-password (request reset)
- POST /auth/reset-password (complete reset with token)
- Email with time-limited reset link (15 min expiry)
- Rate limiting: 3 requests per hour per email
- Follow Adobe security standards"
```

**Agents Deployed:** `@architect` + `@security-reviewer`

**Output:**
```
📐 Feature Design

API Endpoints:
1. POST /auth/forgot-password
   Input: { email: string }
   Output: { message: "Reset email sent" }
   Rate Limit: 3/hour per email

2. POST /auth/reset-password
   Input: { token: string, new_password: string }
   Output: { message: "Password updated" }

Database Changes:
ALTER TABLE users ADD COLUMN reset_token VARCHAR(64);
ALTER TABLE users ADD COLUMN reset_token_expires TIMESTAMP;

Security Requirements:
✓ Token: Cryptographically random (32 bytes)
✓ Expiry: 15 minutes
✓ One-time use: Token invalidated after use
✓ Rate limiting: Prevent abuse
✓ Password validation: Min 12 chars, complexity rules
✓ Audit logging: Log all reset attempts

Skills Applied:
✓ adobe-security-services/authentication-authorization.md
✓ adobe-security-foundations/INJECTION_PREVENTION.md
✓ adobe-security-services/api-security.md
```

---

### Day 2: Implementation with EPCC (3 hours)

#### Step 5: Implement the Feature
```bash
/epcc "implement password reset via email feature with:
- POST /auth/forgot-password endpoint
- POST /auth/reset-password endpoint
- Database migration for reset tokens
- Email template for reset link
- Rate limiting and security validations"
```

**Agents Deployed:** Full EPCC workflow

**Explore Phase:**
```
🔍 Analyzing codebase...
✓ Found email service in src/services/email_service.py
✓ Found auth endpoints in src/api/auth.py
✓ Found user model in src/models/user.py
✓ Found database migrations in migrations/
```

**Plan Phase:**
```
📋 Implementation Plan:
1. Create database migration for reset token fields
2. Update User model with reset token fields
3. Create password reset request endpoint
4. Create password reset completion endpoint
5. Create email template for reset link
6. Add rate limiting middleware
7. Write comprehensive tests
```

**Code Phase:** Generates secure implementation
```python
# src/api/auth.py - Generated code

@router.post("/auth/forgot-password")
@limiter.limit("3/hour")  # Rate limiting
async def forgot_password(
    request: ForgotPasswordRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    # Input validation (adobe-security-foundations)
    if not re.match(r'^[a-zA-Z0-9._%+-]+@adobe.com$', request.email):
        raise HTTPException(400, "Invalid email")

    user = await db.get_user_by_email(request.email)
    if not user:
        # Same response for security (don't leak user existence)
        return {"message": "If email exists, reset link sent"}

    # Generate secure token (adobe-security-services)
    reset_token = secrets.token_urlsafe(32)
    expires = datetime.utcnow() + timedelta(minutes=15)

    # Store token (hashed) in database
    await db.update_user(
        user.id,
        reset_token=hashlib.sha256(reset_token.encode()).hexdigest(),
        reset_token_expires=expires
    )

    # Send email in background
    background_tasks.add_task(
        email_service.send_password_reset_email,
        user.email,
        reset_token
    )

    # Audit log (adobe-security-foundations)
    await audit_log.log(
        "password_reset_requested",
        user_id=user.id,
        ip=request.client.host
    )

    return {"message": "If email exists, reset link sent"}

# ... /auth/reset-password endpoint with similar security patterns
```

**Commit Phase:**
```
✅ Commit created:

feat: implement password reset via email

- Add database migration for reset tokens
- Implement /auth/forgot-password endpoint
- Implement /auth/reset-password endpoint
- Add rate limiting (3/hour per email)
- Secure token generation (32 bytes random)
- 15-minute token expiry
- One-time token use with invalidation
- Email template with reset link
- Audit logging for all reset attempts

Security:
- Cryptographically secure tokens (adobe-security-services)
- Input validation and rate limiting (adobe-security-foundations)
- Same response for existing/non-existing emails (prevent enumeration)
- Password complexity validation (adobe-security-services)

🤖 Generated with Claude Code
```

---

### Day 3: Testing (2 hours)

#### Step 6: Generate Comprehensive Tests
```bash
/generate-tests src/api/auth.py --unit --integration --security
```

**Agents Deployed:** `@test-generator` + `@security-reviewer`

**Output:**
```python
# tests/test_password_reset.py

class TestPasswordReset:
    # Unit tests
    def test_forgot_password_valid_email(self):
        """Test valid email triggers reset flow"""

    def test_forgot_password_invalid_email_format(self):
        """Test invalid email format is rejected"""

    def test_reset_password_valid_token(self):
        """Test password reset with valid token"""

    def test_reset_password_expired_token(self):
        """Test expired token is rejected"""

    # Security tests (adobe-security-foundations)
    def test_rate_limiting_enforced(self):
        """Test rate limiting: 3 requests/hour per email"""
        for i in range(4):
            response = client.post("/auth/forgot-password", ...)
        assert response.status_code == 429

    def test_token_single_use_only(self):
        """Test token cannot be reused after successful reset"""

    def test_sql_injection_in_email_field(self):
        """Test SQL injection is prevented"""
        malicious_email = "'; DROP TABLE users; --@adobe.com"
        response = client.post("/auth/forgot-password",
                                json={"email": malicious_email})
        assert response.status_code == 400

    def test_user_enumeration_prevention(self):
        """Test same response for existing/non-existing emails"""
        response1 = client.post("/auth/forgot-password",
                                 json={"email": "exists@adobe.com"})
        response2 = client.post("/auth/forgot-password",
                                 json={"email": "notexists@adobe.com"})
        assert response1.json() == response2.json()

    # Integration tests
    @pytest.mark.integration
    async def test_end_to_end_password_reset_flow(self):
        """Test complete password reset flow with real database"""

Coverage: 94% (target: 90%) ✅
```

---

### Day 4: Quality Assurance (1 hour)

#### Step 7: Security Scan
```bash
/security-scan src/api/auth.py --deep --focus:authentication
```

**Agents Deployed:** `@security-reviewer` + `@qa-engineer`

**Output:**
```
🔒 Security Scan Results

✅ PASSED (15 checks)
├── ✓ Rate limiting configured (3/hour)
├── ✓ Cryptographically secure token generation
├── ✓ Token expiry enforced (15 minutes)
├── ✓ One-time token use
├── ✓ Input validation (email format)
├── ✓ User enumeration prevention
├── ✓ SQL injection prevention
├── ✓ Audit logging present
├── ✓ Password complexity validation
├── ✓ No hardcoded secrets
├── ✓ Secure token storage (hashed)
├── ✓ Background task for email (non-blocking)
├── ✓ No sensitive data in logs
├── ✓ Error handling without info leakage
└── ✓ HTTPS enforced

Overall: APPROVED FOR DEPLOYMENT ✅
```

#### Step 8: Code Review
```bash
/code-review src/api/auth.py src/services/email_service.py
```

**Agents Deployed:** `@architect` + `@security-reviewer` + `@qa-engineer`

**Output:**
```
📊 Code Review Report

🏗️  ARCHITECTURE (@architect)
✅ Good:
- Clear separation: API → Service → Database
- Background tasks for email (non-blocking)
- Proper error handling

🔒 SECURITY (@security-reviewer)
✅ Good:
- All OWASP checks passed
- Rate limiting properly configured
- No security vulnerabilities found

🧪 TESTING (@qa-engineer)
✅ Good:
- Test coverage: 94%
- Security test cases included
- Integration tests present

OVERALL: ✅ APPROVED FOR MERGE
```

---

### Day 5: Documentation & Deployment (1 hour)

#### Step 9: Generate Documentation
```bash
/docs/docs-create "password reset feature" --complete
```

**Agents Deployed:** `@docs-tutorial`, `@docs-howto`, `@docs-reference`, `@docs-explanation`

**Output:**
```
docs/
├── tutorial-password-reset.md      # Step-by-step guide for new devs
├── howto-implement-reset.md        # How to add similar features
├── reference-reset-api.md          # API specification
└── explanation-reset-security.md   # Security design rationale
```

#### Step 10: Create Commit
```bash
/conventional-commit
```

**Output:**
```
feat(auth): implement password reset via email

- Add POST /auth/forgot-password endpoint
- Add POST /auth/reset-password endpoint
- Secure token generation (32 bytes, 15 min expiry)
- Rate limiting: 3 requests/hour per email
- User enumeration prevention
- Complete test coverage (94%)
- Comprehensive documentation

Security validation:
✓ OWASP checks passed
✓ Adobe security standards compliant
✓ Security scan approved

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

### Summary

**Total Time:** 10 hours (2 work days)
**Test Coverage:** 94%
**Security:** Adobe standards compliant
**Documentation:** Complete

**Tools & Agents Used:**
1. `setup-claude-config` - Project setup
2. `@code-archaeologist` - Understand existing codebase architecture
3. `/epcc:epcc-explore` - Explore auth system for feature work
4. `/architecture-design` - Design new password reset feature
5. `/epcc` - Implement feature with EPCC workflow
6. `/generate-tests` - Create comprehensive tests
7. `/security-scan` - Security validation
8. `/code-review` - Multi-agent review
9. `/docs/docs-create` - Generate documentation
10. `/conventional-commit` - Create commit

**Key Success Factors:**
- Started with understanding before coding
- Used architecture analysis to find existing patterns
- Followed EPCC workflow for structured implementation
- Security built-in from design phase
- Comprehensive testing before review
- Complete documentation for future developers

---

## Example 2: Understanding an Existing Project's Architecture

### Scenario
You've just joined a team or inherited a codebase and need to understand its design, architecture, and component relationships.

### Workflow

```bash
cd ~/existing-project
setup-claude-config
# Detected: python (+ docker)

# Comprehensive architecture analysis of existing codebase
@code-archaeologist "Perform complete architecture analysis: map all components, trace data flows, identify patterns, document dependencies, and assess technical debt"
```

**What Happens:**
- Agent `@code-archaeologist` reverse-engineers the existing architecture
- Traces data flows from API to database
- Maps all component dependencies and relationships
- Identifies design patterns and coding conventions
- Generates comprehensive system documentation

**Output:**
```
🔍 Code Archaeology Report: Complete Architecture Analysis

System Documentation Generated:
├── Dependency Graph (visual map of all connections)
├── Data Flow Diagrams (how information moves)
├── Component Relationships (what depends on what)
└── Technical Debt Assessment (prioritized issues)

Key Findings:
├── Architecture Pattern: Layered Architecture
│   ├── API Layer: FastAPI REST endpoints
│   ├── Service Layer: Business logic
│   ├── Data Layer: PostgreSQL + Redis
│   └── Integration Layer: Adobe IMS, S3
│
├── Tech Stack:
│   ├── Language: Python 3.11
│   ├── Framework: FastAPI 0.104
│   ├── Database: PostgreSQL 14
│   ├── Cache: Redis 7
│   └── Deployment: Docker + Kubernetes
│
├── Security Posture:
│   ✓ JWT authentication with Adobe IMS
│   ✓ Input validation with Pydantic
│   ✓ Parameterized SQL queries
│   ⚠️  Missing rate limiting on admin endpoints
│
└── Design Decisions (ADRs):
    ├── Why FastAPI over Flask: Performance needs
    ├── Why PostgreSQL: ACID compliance required
    └── Why Redis: Session management + caching

Skills Applied:
✓ adobe-security-foundations (architecture analysis)
✓ adobe-security-services (authentication patterns)
✓ adobe-security-cloud/kubernetes (deployment analysis)

Total Time: ~3 minutes
```

### When to Use
- **First day on a new project** - Get comprehensive overview
- **Before major refactoring** - Understand current state
- **Inheriting legacy code** - Reverse-engineer undocumented systems
- **Team onboarding** - Create documentation for new members

---

## Example 3: Exploring Specific Features in Legacy Code

### Scenario
You need to understand how a specific feature works in an undocumented legacy codebase before making changes.

### Workflow

```bash
cd ~/legacy-service

# Deep exploration of authentication flow in legacy code
@code-archaeologist "Deep dive into authentication flow: trace from entry point to database, identify all middleware, uncover hidden dependencies, map business logic, and find security vulnerabilities"
```

**What Happens:**
- Agent `@code-archaeologist` reverse-engineers the authentication system
- Traces complete data flow from API request to database query
- Uncovers hidden dependencies (Adobe IMS, Redis, Elasticsearch)
- Identifies technical debt and security issues
- Maps business logic embedded in code

**Output:**
```
🔍 Code Archaeology Report: Authentication Flow

Data Flow Discovered:
1. Request Entry Point
   └── src/api/auth.py:45 - POST /auth/login
       ├── Input: username, password
       └── Headers: X-API-Key, User-Agent

2. Validation Layer
   └── src/middleware/auth_validator.py:23
       ├── Checks: API key validation
       ├── Rate limiting: 10 req/min per IP
       └── ⚠️ WARNING: No CAPTCHA for brute force

3. Authentication Logic
   └── src/services/auth_service.py:67
       ├── Password check: bcrypt comparison
       ├── MFA validation: Time-based OTP
       └── Session creation: JWT + Redis

4. Token Generation
   └── src/utils/jwt_helper.py:89
       ├── Algorithm: HS256 ⚠️ Should use RS256
       ├── Expiry: 24 hours
       └── Payload: user_id, email, roles

5. Database Interactions
   └── src/db/user_repository.py:34
       ├── Query: "SELECT * FROM users WHERE username = %s"
       ✓ Parameterized (no SQL injection)
       └── Connection pool: asyncpg

Hidden Dependencies Found:
├── Adobe IMS (undocumented)
│   └── Fallback auth when local fails
├── Redis session store (not in docs)
│   └── TTL: 86400 seconds
└── Elasticsearch audit logs (surprise!)
    └── All login attempts logged

Technical Debt Identified:
❌ CRITICAL: HS256 JWT signing (should be RS256)
⚠️  HIGH: No brute force protection (missing CAPTCHA)
⚠️  MEDIUM: Hardcoded JWT secret in config file
✓ LOW: Consider adding refresh token flow

Recommendations:
1. Upgrade JWT to RS256 signing
2. Move secrets to AWS Secrets Manager
3. Add CAPTCHA after 3 failed attempts
4. Implement refresh token mechanism
5. Document Adobe IMS integration

Skills Applied:
✓ adobe-security-services/authentication-authorization.md
✓ adobe-security-foundations/INJECTION_PREVENTION.md
✓ adobe-security-audit/vulnerability-detection.md

Total Time: ~5 minutes
Files Analyzed: 23 files across 8 directories
```

### When to Use
- **Understanding specific features** - How does payment processing work?
- **Before bug fixes** - Trace the issue root cause
- **Refactoring preparation** - Map dependencies before changes
- **Security audit** - Find hidden vulnerabilities
- **Knowledge transfer** - Document tribal knowledge

---

## Example 4: Building a Microservice for Ethos

### Scenario
Create a Python FastAPI microservice that:
- Handles user authentication with JWT
- Connects to PostgreSQL database
- Uses Redis for caching
- Deploys to Adobe Ethos (Kubernetes)
- Follows Adobe security standards

### Workflow

```bash
cd ~/my-service
setup-claude-config
# Detected: python (+ docker)
```

#### Phase 1: Architecture & Design (30 minutes)

```bash
/architecture-design "FastAPI microservice:
- REST API for user management
- PostgreSQL for persistence
- Redis for session cache
- JWT authentication
- Deploy on Ethos Kubernetes
- Follow Adobe security standards"
```

**What Happens:**
- Agent `@architect` designs system architecture
- Agent `@security-reviewer` validates security design
- Skills applied:
  - `adobe-security-foundations` → Security principles
  - `adobe-security-cloud/kubernetes` → Ethos patterns
  - `adobe-security-services` → API security

**Output:**
```
📐 Architecture Design
├── Components
│   ├── FastAPI application (Python 3.11)
│   ├── PostgreSQL 14 (Docker container)
│   ├── Redis 7 (Docker container)
│   └── Nginx reverse proxy
├── Security
│   ├── JWT with RS256 signing
│   ├── Rate limiting (100 req/min)
│   ├── Input validation with Pydantic
│   └── Secrets management with environment variables
└── Local Development
    ├── Dockerfile for application
    ├── docker-compose.yml for full stack
    └── Health checks: /health and /ready
```

#### Phase 2: Implementation with EPCC (2-3 hours)

```bash
/epcc "implement JWT authentication with Adobe IMS integration"
```

**Explore Phase:**
```
🔍 Analyzing codebase...
- No existing auth implementation
- Need to integrate with Adobe IMS
- FastAPI security dependencies required

Skills referenced:
✓ adobe-security-services/authentication-authorization.md
✓ adobe-security-lang/python.md
✓ adobe-security-foundations/INJECTION_PREVENTION.md
```

**Plan Phase:**
```
📋 Implementation Plan:
1. Install dependencies: pyjwt, cryptography
2. Create auth middleware
3. Implement token validation
4. Add rate limiting
5. Write security tests
6. Document API endpoints
```

**Code Phase:**
```python
# Generated with security patterns from skills

from fastapi import Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from pydantic import BaseModel, validator

# Input validation (adobe-security-foundations)
class TokenPayload(BaseModel):
    user_id: str
    email: str
    exp: int

    @validator('email')
    def validate_email(cls, v):
        # Prevent injection in email field
        if not re.match(r'^[a-zA-Z0-9._%+-]+@adobe.com$', v):
            raise ValueError('Invalid Adobe email')
        return v

# Secure token validation (adobe-security-services)
async def validate_adobe_token(
    credentials: HTTPAuthorizationCredentials = Security(HTTPBearer())
):
    try:
        # RS256 signing (adobe-security-services/auth)
        payload = jwt.decode(
            credentials.credentials,
            PUBLIC_KEY,
            algorithms=['RS256'],
            audience='your-service'
        )
        return TokenPayload(**payload)
    except jwt.InvalidTokenError as e:
        # Secure error handling (adobe-security-foundations)
        logger.warning(f"Invalid token: {type(e).__name__}")
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication credentials"
        )

# Rate limiting (adobe-security-services/api-security)
@app.get("/api/users/me")
@limiter.limit("100/minute")
async def get_current_user(
    token: TokenPayload = Depends(validate_adobe_token)
):
    # Query with parameterized statements (adobe-security-lang/python)
    query = "SELECT * FROM users WHERE id = %s"
    async with db.acquire() as conn:
        user = await conn.fetchrow(query, token.user_id)
    return user
```

**Commit Phase:**
```
✅ Commit created:

feat: implement JWT authentication with Adobe IMS

- Add RS256 JWT validation with public key
- Implement rate limiting (100 req/min)
- Add input validation for all auth endpoints
- Use parameterized queries for user lookup
- Secure error handling without leaking details

Security:
- Follows adobe-security-services patterns
- Input validation per adobe-security-foundations
- Python secure coding per adobe-security-lang/python

🤖 Generated with Claude Code
```

#### Phase 3: Testing (45 minutes)

```bash
/generate-tests src/api/auth.py --unit --integration --security
```

**What Happens:**
- Agent `@test-generator` creates comprehensive tests
- Agent `@security-reviewer` adds security test cases
- Skills applied:
  - `adobe-security-foundations` → Security test scenarios
  - `adobe-security-audit` → Vulnerability testing

**Output:**
```python
# tests/test_auth.py - Generated with security focus

import pytest
from fastapi.testclient import TestClient

# Unit tests
def test_valid_jwt_token():
    """Test valid Adobe JWT token is accepted"""
    token = create_test_token(user_id="test123", email="test@adobe.com")
    response = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200

# Security tests (from adobe-security-foundations)
def test_sql_injection_prevention():
    """Test SQL injection is prevented in user lookup"""
    malicious_id = "'; DROP TABLE users; --"
    token = create_test_token(user_id=malicious_id)
    # Should fail validation, not reach database
    response = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 401

def test_rate_limiting():
    """Test rate limiting enforces 100 req/min"""
    token = create_valid_token()
    # Make 101 requests
    for i in range(101):
        response = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 429  # Too Many Requests

def test_invalid_email_domain():
    """Test non-Adobe email domains are rejected"""
    token = create_test_token(email="hacker@evil.com")
    response = client.get("/api/users/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 401

# Integration tests
@pytest.mark.integration
async def test_end_to_end_auth_flow():
    """Test complete authentication flow with real database"""
    # ... full E2E test
```

#### Phase 4: Security Audit (30 minutes)

```bash
/security-scan --deep --focus:authentication
```

**What Happens:**
- Agents `@security-reviewer`, `@qa-engineer` analyze in parallel
- ALL 48 Adobe security skills are referenced
- Comprehensive vulnerability scan

**Output:**
```
🔒 Security Scan Results

Target: src/
Depth: Deep scan with extended analysis
Focus: Authentication & Authorization

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ PASSED (12 checks)
├── ✓ Input validation present (Pydantic models)
├── ✓ Parameterized SQL queries
├── ✓ JWT RS256 signing (not HS256)
├── ✓ Rate limiting configured
├── ✓ No hardcoded secrets
├── ✓ Secure error handling
├── ✓ Email validation (Adobe domain only)
├── ✓ HTTPS enforced
├── ✓ CORS properly configured
├── ✓ No sensitive data in logs
├── ✓ Dependencies have no known CVEs
└── ✓ Password hashing uses bcrypt

⚠️  WARNINGS (2 recommendations)
├── Consider adding request signing for API-to-API calls
└── Add IP allowlisting for admin endpoints

Skills Applied:
✓ adobe-security-foundations (4 references)
✓ adobe-security-services (3 references)
✓ adobe-security-lang/python (6 references)
✓ adobe-security-cloud/aws (2 references)

Overall: APPROVED FOR DEPLOYMENT ✅
```

#### Phase 5: Documentation (20 minutes)

```bash
/docs/docs-create "authentication API" --complete
```

**What Happens:**
- Agents: `@docs-tutorial`, `@docs-howto`, `@docs-reference`, `@docs-explanation`
- Creates 4 types of documentation (Diataxis framework)

**Output:**
```
docs/
├── tutorial-getting-started.md     # For new developers
├── howto-integrate-auth.md         # Task-oriented guide
├── reference-api-endpoints.md      # API specification
└── explanation-jwt-architecture.md # Conceptual understanding
```

#### Phase 6: Dockerize Application (1 hour)

```bash
# Create Docker setup
/architecture-design "Dockerfile and docker-compose.yml for local development"

# Review before building
/code-review Dockerfile docker-compose.yml

# Build and run
docker-compose up --build
```

**Output:**
```yaml
# docker-compose.yml includes:
# - FastAPI app container
# - PostgreSQL 14 container
# - Redis 7 container
# - Volume mounts for local development
# - Network configuration
# - Health checks
```

### Total Time: ~5 hours
### Test Coverage: 92%
### Security: Adobe standards compliant
### Documentation: Complete

---

## Example 5: Terraform Module for Azure Resources

### Scenario
Create reusable Terraform module for Azure VM with security best practices.

```bash
cd ~/terraform-modules/azure-vm
setup-claude-config
# Detected: terraform

/epcc "create Terraform module for Azure VM with:
- Network security group
- Managed identity
- Azure Monitor integration
- Backup enabled
- Follow Adobe cloud security standards"
```

**Skills Applied:**
- `adobe-security-cloud/azure-compute.md`
- `adobe-security-cloud/azure-identity.md`
- `adobe-security-cloud/azure-network.md`
- `adobe-security-cloud/terraform.md`

**Output:**
```hcl
# Generated with adobe-security-cloud patterns

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size

  # Managed identity (adobe-security-cloud/azure-identity)
  identity {
    type = "SystemAssigned"
  }

  # Encrypted OS disk (adobe-security-cloud/azure-compute)
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"

    # Encryption at rest
    encryption_settings {
      enabled = true
    }
  }

  # Disable password auth (adobe-security-cloud/azure-compute)
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # Azure Monitor agent (adobe-security-cloud/azure-compute)
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diagnostics.primary_blob_endpoint
  }

  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Security  = "Adobe-Standards"
    }
  )
}

# Network Security Group (adobe-security-cloud/azure-network)
resource "azurerm_network_security_group" "this" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Deny all inbound by default
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH from Adobe IP ranges only
  security_rule {
    name                       = "AllowSSHFromAdobe"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.adobe_ip_ranges
    destination_address_prefix = "*"
  }
}
```

---

## Example 6: Code Review Before Merge

```bash
# Before creating PR
/code-review src/

# Parallel agent deployment
# @architect - Design review
# @security-reviewer - Security audit
# @qa-engineer - Test coverage check
```

**Output:**
```
📊 Code Review Report

Repository: user-management-service
Branch: feature/add-user-roles
Files Changed: 12 files

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏗️  ARCHITECTURE REVIEW (@architect)

✅ Good:
- Clear separation of concerns
- Proper dependency injection
- RESTful API design

⚠️  Improvements:
1. Consider caching user roles in Redis
   File: src/api/users.py:45

2. Add circuit breaker for external IMS calls
   File: src/services/ims_client.py:23

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔒 SECURITY REVIEW (@security-reviewer)

✅ Good:
- Input validation present
- No SQL injection vulnerabilities
- Secrets stored in AWS Secrets Manager

❌ Critical:
1. Missing authorization check in role update
   File: src/api/roles.py:67
   Fix:
   ```python
   @router.put("/roles/{role_id}")
   async def update_role(
       role_id: str,
       role_data: RoleUpdate,
       current_user: User = Depends(get_current_user)
   ):
       # ADD THIS CHECK
       if not current_user.has_permission("roles:update"):
           raise HTTPException(403, "Insufficient permissions")

       # ... rest of implementation
   ```

Skills Referenced:
✓ adobe-security-services/authentication-authorization.md
✓ adobe-security-foundations/INJECTION_PREVENTION.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧪 TEST COVERAGE (@qa-engineer)

Coverage: 87% (target: 90%)

Missing Tests:
1. src/api/roles.py - Role deletion
2. src/services/role_manager.py - Error scenarios

Recommendation: Add tests before merging

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OVERALL: ⚠️  REQUIRES CHANGES

Action Items:
1. [CRITICAL] Fix authorization check in roles.py:67
2. [HIGH] Add missing test coverage
3. [MEDIUM] Consider caching optimization
4. [LOW] Add circuit breaker for resilience
```

---

These examples show how **skills + agents + commands** work together to deliver Adobe-standard code with security built-in!
