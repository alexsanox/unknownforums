# UnknownForums — Full Technical Documentation

> Last updated: 2026-05-04  
> Rails 8.1.3 · Ruby 4.0.3 · PostgreSQL · Cloudflare R2

---

## Table of Contents

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Architecture](#architecture)
4. [Environment Variables](#environment-variables)
5. [Database Schema](#database-schema)
6. [Models](#models)
7. [Controllers & Routes](#controllers--routes)
8. [Services](#services)
9. [Jobs](#jobs)
10. [File Uploads & VirusTotal](#file-uploads--virustotal)
11. [Authentication & Authorization](#authentication--authorization)
12. [Admin Panel](#admin-panel)
13. [Caching](#caching)
14. [Deployment](#deployment)
15. [CI/CD](#cicd)

---

## Overview

UnknownForums is a full-featured Rails forum application with:
- Threaded discussion boards (categories → subforums → threads → posts)
- File attachments with VirusTotal scanning
- Public downloads page and leaderboard
- Private messaging
- Reputation system
- Thread subscriptions and notifications
- User reports and moderation tools
- Email OTP two-factor authentication
- Admin panel with dashboard, user management, moderation

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Ruby on Rails 8.1.3 |
| Language | Ruby 4.0.3 |
| Database | PostgreSQL (via `pg` gem) |
| Background Jobs | Solid Queue |
| Cache Store | Solid Cache |
| Action Cable | Solid Cable |
| File Storage | Cloudflare R2 (S3-compatible, via `aws-sdk-s3`) |
| Frontend | Turbo + Stimulus + Tailwind CSS |
| Asset Pipeline | Propshaft + Importmap |
| Email | Resend API (`resend` gem) |
| Markdown | Kramdown + sanitize |
| Pagination | Kaminari |
| Password Hashing | BCrypt |
| Image Processing | ImageProcessing (libvips) |
| Web Server | Puma + Thruster |
| Security Analysis | Brakeman + Bundler-Audit + RuboCop |

---

## Architecture

```
Browser
  │
  ▼
Thruster (HTTP/2, asset compression)
  │
  ▼
Puma (Rails app server)
  │
  ├── ActionController (request handling)
  ├── ActiveRecord (PostgreSQL)
  ├── ActiveStorage → Cloudflare R2 (file storage)
  ├── Solid Queue (background jobs: VT scanning)
  ├── Solid Cache (leaderboard, forum stats caching)
  └── Solid Cable (ActionCable: live message badges)
```

### Key Design Decisions
- **No Devise** — custom authentication with `has_secure_password`, session cookie, brute-force lockout
- **No ActionMailer SMTP** — email sent directly via Resend HTTP API
- **Turbo Drive disabled on auth forms** — login/logout do full page reloads to ensure session state is reflected immediately
- **Filename branding** — uploaded files get a `[prefix]basename[unknownforums].ext` format based on category/thread context

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | ✅ | Rails session signing key |
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `VIRUSTOTAL_API_KEY` | ✅ | VirusTotal v3 API key for file scanning |
| `RESEND_API_KEY` | ✅ | Resend API key for email OTP delivery |
| `R2_ACCESS_KEY_ID` | ✅ | Cloudflare R2 access key |
| `R2_SECRET_ACCESS_KEY` | ✅ | Cloudflare R2 secret key |
| `R2_BUCKET` | ✅ | R2 bucket name |
| `R2_ENDPOINT` | ✅ | R2 endpoint URL |
| `APP_HOST` | ✅ | Production hostname (e.g. `unknownforums.fun`) |
| `FORUM_NAME` | ⬜ | Site name shown in UI (default: `UnknownForums`) |
| `FORUM_DESCRIPTION` | ⬜ | Site meta description |
| `MAIL_FROM` | ⬜ | From address for emails |
| `RAILS_LOG_LEVEL` | ⬜ | Log level (default: `info`) |

---

## Database Schema

### Tables

#### `users`
| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | |
| `username` | string | unique, 3–30 chars, alphanumeric+_- |
| `email` | string | unique |
| `password_digest` | string | BCrypt hash |
| `role` | integer | 0=user, 1=moderator, 2=admin |
| `reputation` | integer | default 0 |
| `posts_count` | integer | counter cache |
| `banned` | boolean | |
| `locked_until` | datetime | brute-force lockout |
| `failed_login_attempts` | integer | |
| `email_two_factor_enabled` | boolean | |
| `email_otp_digest` | string | BCrypt hash of OTP |
| `email_otp_expires_at` | datetime | |
| `email_otp_attempts` | integer | |
| `last_seen_at` | datetime | |
| `last_login_at` | datetime | |
| `last_login_ip` | string | |
| `previous_usernames` | string[] | array of old usernames |

#### `forum_threads`
| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | |
| `title` | string | |
| `subforum_id` | bigint FK | |
| `user_id` | bigint FK | |
| `posts_count` | integer | counter cache |
| `views` | integer | |
| `pinned` | boolean | |
| `locked` | boolean | |
| `edited_at` | datetime | set on title change |

#### `posts`
| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | |
| `body` | text | Markdown |
| `forum_thread_id` | bigint FK | |
| `user_id` | bigint FK | |
| `deleted` | boolean | soft-delete |
| `edited_at` | datetime | set on body change |
| `quote_post_id` | bigint FK | self-referential |

#### `attachments`
| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | |
| `filename` | string | branded name |
| `content_type` | string | validated MIME type |
| `byte_size` | bigint | max 100MB |
| `download_count` | integer | default 0 |
| `approved` | boolean | set true after VT clean or skip |
| `vt_status` | string | pending/scanning/clean/suspicious/malicious/skipped |
| `vt_scan_id` | string | VT analysis ID |
| `vt_report` | jsonb | raw VT API response |
| `version` | integer | default 1 |
| `parent_attachment_id` | bigint FK | for version chains |
| `attachable_type` / `attachable_id` | polymorphic | Post or PrivateMessage |
| `user_id` | bigint FK | uploader |
| `is_video` | boolean | |

#### `categories`
Organise subforums. Has `name`, `position`, `description`.

#### `subforums`
Belong to categories. Have `name`, `description`, `position`, `posts_count`, `threads_count`.

#### `private_messages`
| Column | Notes |
|--------|-------|
| `sender_id` / `recipient_id` | User FKs |
| `subject` / `body` | |
| `read_at` | nil = unread |
| `sender_deleted` / `recipient_deleted` | soft-delete per side |

#### `reputations`
Join table: `giver_id`, `receiver_id`, `post_id`, `value` (+1 or -1), unique per giver+post.

#### `notifications`
| Column | Notes |
|--------|-------|
| `user_id` | recipient |
| `notifiable_type` / `notifiable_id` | polymorphic (Post, etc.) |
| `read_at` | nil = unread |
| `event` | string (e.g. `replied`) |

#### `thread_subscriptions`
`user_id`, `forum_thread_id`, `last_read_at` — unique per user+thread.

#### `reports`
`reporter_id`, `reportable_type/id`, `reason`, `status` (pending/reviewed/dismissed).

#### `user_warnings`
`user_id`, `issued_by_id`, `reason`, `expires_at`.

#### `virus_total_quotas`
DB-backed API quota tracking. Columns: `period`, `period_start`, `request_count`.
Limits: 4 req/min, 500/day, 15,500/month.

#### `attack_events`
Logs suspicious requests: `ip`, `event_type`, `matched_rule`, `occurred_at`.

---

## Models

### `User`
- `has_secure_password` (BCrypt)
- Roles: `user`, `moderator`, `admin`
- Methods: `authenticate`, `locked?`, `banned?`, `can_moderate?`, `online?`
- Login security: `register_failed_login!`, `register_successful_login!`, `lockout_remaining`
- Email OTP: `send_otp!`, `verify_otp!(code)`, `otp_resend_wait`
- Password validation: 8+ chars, mixed case + number, not equal to username

### `Attachment`
- `ALLOWED_TYPES`: images, videos, PDF, text, zip, torrent, executables/scripts
- `VT_SCAN_TYPES`: zip, pdf, torrent, executables (scanned) — images/videos auto-approved
- `vt_scannable?`: returns true if file attached AND content_type in VT_SCAN_TYPES
- `increment_download!`: atomic counter increment
- `vt_warning_required?`: shows download interstitial if file has non-clean VT status
- Versioning: `parent_attachment_id`, `version`, `root_attachment`, `all_versions`

### `Post`
- Markdown body via `ApplicationHelper#markdown_post_body` (kramdown + sanitize)
- Soft delete: `deleted = true`
- Counter decrements: `decrement_visible_counters_after_soft_delete` on Post, ForumThread, Subforum, User

### `ForumThread`
- `increment_views!` (atomic)
- `locked?`, `pinned?`

### `Reputation`
- `value`: +1 (upvote) or -1 (downvote)
- Unique per giver+post
- Cannot rate own posts

### `ThreadSubscription`
- `mark_read!` updates `last_read_at`
- Used for unread notification badges

---

## Controllers & Routes

### Public Routes

| Route | Controller#Action | Auth |
|-------|------------------|------|
| `GET /` | `forum#index` | — |
| `GET /categories/:id` | `categories#show` | — |
| `GET /subforums/:id` | `subforums#show` | — |
| `GET /threads/:id` | `forum_threads#show` | — |
| `GET /search` | `search#index` | — |
| `GET /downloads` | `downloads#index` | login |
| `GET /leaderboard` | `leaderboards#index` | — |
| `GET /users/:id` | `users#show` | — |
| `GET /attachments/:id/download` | `attachments#download` | login |
| `GET /login` | `sessions#new` | guest |
| `POST /login` | `sessions#create` | guest |
| `DELETE /logout` | `sessions#destroy` | — |
| `GET /register` | `registrations#new` | guest |
| `POST /register` | `registrations#create` | guest |
| `GET /email-otp` | `email_otps#show` | — |
| `POST /email-otp` | `email_otps#create` | — |

### Authenticated Routes

| Route | Controller#Action |
|-------|------------------|
| `POST /threads/:id/posts` | `posts#create` |
| `POST /categories/:id/threads` | `forum_threads#create` |
| `GET /messages` | `private_messages#index` |
| `POST /messages` | `private_messages#create` |
| `GET /notifications` | `notifications#index` |
| `POST /threads/:id/watch` | `thread_subscriptions#create` |
| `POST /reputations` | `reputations#create` |
| `POST /reports` | `reports#create` |
| `GET /users/:id/edit` | `users#edit` |
| `PATCH /users/:id` | `users#update` |

### Admin Routes (`/admin/*`)

| Route | Notes |
|-------|-------|
| `GET /admin` | Dashboard: stats, recent activity |
| `/admin/users` | List, edit, ban, warn, staff notes |
| `/admin/categories` | CRUD |
| `/admin/subforums` | CRUD |
| `/admin/threads` | View/delete threads per subforum |
| `/admin/reports` | Pending reports queue |
| `/admin/file_leaderboard` | Top downloaded files |
| `/admin/attack_events` | Security event log |
| `/admin/site_pages` | Static page editor |
| `/admin/user_warnings` | Issue/manage warnings |
| `/admin/staff_notes` | Private notes on users |

---

## Services

### `AttachmentCreator`
Handles file attachment creation for posts and DMs.
- `attach(attachable:, user:, files:)` — iterates files, validates, saves, queues VT scan or auto-approves
- `stored_filename_for(attachable, filename)` — brands filename: `[prefix]name[unknownforums].ext`
- `dm_file_key(...)` — generates R2 key for DM files: `dmfile/YYYY/MM/DD/user-ID/message-ID/UUID-filename`
- Returns array of error strings for any files that failed validation

### `VirusTotalScanner`
Wraps the VT v3 API.
- `scan(attachment)` — uploads file (or URL fallback), polls analysis, updates `vt_status`
- Large files (>32MB) use VT's large-file upload URL endpoint
- Falls back to URL scan if direct upload fails
- Quota-aware: raises `VirusTotalQuota::RateLimited` on 429 or quota exhaustion; job requeues with wait
- Results: `clean` → auto-approves; `suspicious`/`malicious` → leaves unapproved with warning

### `PostCreator`
Creates a Post within a thread. Handles locked thread checks, spam detection, counter increments.

### `ThreadCreator`
Creates a ForumThread + first Post. Returns the thread or nil with errors on failure.

### `ReputationGiver`
Handles upvote/downvote logic: prevents self-rating, handles toggling, updates receiver reputation.

### `EmailOtpSender`
Sends OTP emails via Resend HTTP API. Raises `DeliveryDisabled` if no API key configured, `DeliveryFailed` on API errors.

---

## Jobs

### `VirusTotalScanJob`
- Queue: `virus_total`
- Calls `VirusTotalScanner.scan(attachment)`
- If quota rate-limited: requeues itself with `wait:` seconds from the error
- If scan pending (analysis not ready): requeues with short delay to poll again

---

## File Uploads & VirusTotal

### Upload Flow
1. User submits a form with `files[]` param
2. Controller calls `AttachmentCreator.attach(...)`
3. For each file:
   - Validates MIME type (against `ALLOWED_TYPES`)
   - Validates size (≤ 100MB)
   - Generates branded filename
   - Attaches to Active Storage (R2 for production)
   - Saves `Attachment` record
   - If `vt_scannable?` → enqueues `VirusTotalScanJob`
   - Else → marks `vt_status: "skipped"`, `approved: true` immediately
4. Validation errors returned as array, flashed to user

### Types That Get VT Scanned
`application/zip`, `application/x-zip-compressed`, `application/x-bittorrent`, `application/pdf`, `application/x-msdownload`, `application/x-msdos-program`, `application/x-dosexec`, `application/octet-stream`, `application/x-sh`, `application/x-powershell`, `application/javascript`, `text/javascript`, `application/x-apple-diskimage`

### Types Auto-Approved (no scan)
`image/jpeg`, `image/png`, `image/gif`, `image/webp`, `video/mp4`, `video/webm`, `video/ogg`, `text/plain`

### Download Flow
1. User clicks download link (`/attachments/:id/download`)
2. If `vt_warning_required?` → renders warning interstitial page
3. User confirms → `increment_download!` → redirect to R2 signed URL
4. All download links have `data-turbo="false"` to prevent Turbo double-counting

### VT Status Labels
| Status | Meaning |
|--------|---------|
| `pending` | Queued, not yet sent to VT |
| `scanning` | Submitted to VT, waiting for result |
| `clean` | VT found no threats → auto-approved |
| `suspicious` | VT flagged as suspicious → warning shown |
| `malicious` | VT flagged as malicious → danger warning |
| `skipped` | Not scanned (image/video/no API key) → auto-approved |

---

## Authentication & Authorization

### Login Flow
1. POST `/login` with username + password
2. Checks lockout, authenticates with BCrypt
3. If 2FA enabled → sends OTP email, redirects to `/email-otp`
4. If 2FA not enabled → `reset_session`, sets `session[:user_id]`, redirects
5. Failed attempt → `register_failed_login!`, locks after 5 failures

### Session
- Cookie-based (`_forums_session`)
- `httponly: true`, `secure: true`, `same_site: :lax`
- 24-hour expiry
- `reset_session` called on login and logout (prevents fixation)

### Authorization Layers
```
require_login          → any logged-in user
require_guest          → only non-logged-in (login/register pages)
require_admin          → role == admin
require_moderator      → role == moderator OR admin
require_owner_or_moderator(user) → current_user == user OR moderator/admin
```

---

## Admin Panel

Located at `/admin/*`, all routes require `require_moderator` minimum.

### Dashboard (`/admin`)
- Site stats: users, threads, posts, files, pending reports
- Recent registrations, recent posts, flagged users
- Cached for performance

### User Management (`/admin/users`)
- Search by username, email, moderation notes
- Edit role, banned status, reputation, flag reason
- Issue warnings with expiry dates
- Add private staff notes (not visible to user)
- View login history, ban/unban

### Content Moderation
- Reports queue with approve/dismiss actions
- Thread management (lock, pin, move, delete)
- File leaderboard with download counts

### Attack Events (`/admin/attack_events`)
- Log of suspicious requests (rate limit hits, blocked patterns)

### Site Pages (`/admin/site_pages`)
- Edit static pages (terms, rules, etc.) via built-in editor

---

## Caching

| Cache Key | TTL | Contents |
|-----------|-----|----------|
| `forum_stats` | 5 min | thread/post/member/file counts |
| `forum/last_posts/:hash` | 2 min | last post per subforum |
| `leaderboard/top_posters` | 5 min | top 10 users by post count |
| `leaderboard/top_reputation` | 5 min | top 10 by reputation |
| `leaderboard/top_uploaders` | 5 min | top 10 uploaders |
| `leaderboard/top_downloaders` | 5 min | top 10 by file downloads |
| `leaderboard/top_files` | 5 min | top 10 downloaded files |

Cache store: **Solid Cache** (DB-backed) in production.

All HTML responses also get `Cache-Control: no-store, no-cache, private` headers to prevent browser/proxy caching of auth-sensitive pages.

---

## Deployment

### Requirements
- Docker + Docker Compose
- PostgreSQL (via Docker or external)
- Environment variables configured (`.env` or Docker secrets)

### Commands

```bash
# Normal deploy (with build cache)
forums-deploy

# Full deploy (with migrations + cache clear)
forums-deploy --full

# Rebuild from scratch (when gems or Dockerfile changed)
forums-deploy --no-cache

# Full clean rebuild
forums-deploy --no-cache --full
```

### Manual Steps

```bash
git pull
docker compose build
docker compose up -d
docker compose exec web bin/rails db:migrate   # if new migrations
```

### First-Time Setup

```bash
docker compose up -d
docker compose exec web bin/rails db:setup     # creates + seeds DB
docker compose exec web bin/rails db:seed      # loads seed data
```

---

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`) runs on every push to `main` and all PRs.

### Jobs

| Job | Tool | Checks |
|-----|------|--------|
| `scan_ruby` | Brakeman | Static security analysis |
| `scan_ruby` | Bundler-Audit | Known CVEs in gems |
| `scan_js` | Importmap Audit | JavaScript dependency CVEs |
| `lint` | RuboCop | Code style (rails-omakase config) |

### Brakeman Ignores
`config/brakeman.ignore` — intentionally accepted warnings (admin mass assignment behind `require_admin`).

### Keeping CI Green
- Run `bin/rubocop --autocorrect-all` before committing
- Run `bin/brakeman --no-pager --ignore-config config/brakeman.ignore` before committing
- Run `bin/bundler-audit` to check for new gem CVEs
