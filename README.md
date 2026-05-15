# MovieApp

A full-stack movie application with a .NET backend API and a Flutter Android mobile client.

---

## Checklist

| Requirement | Status |
|---|---|
| User registration and login | ✅ |
| JWT authentication | ✅ |
| Movies fetched from OMDb and stored in PostgreSQL | ✅ |
| Mobile application displays movie data | ✅ |
| Favorite movies work online and offline | ✅ |
| Application runs via Docker Compose | ✅ |
| Logs accessible in Kibana | ✅ |
| OMDb API key not exposed in mobile | ✅ |

---

## Tech Stack

**Backend**
- .NET 10 Minimal API
- PostgreSQL — persistent storage
- Entity Framework Core — ORM and migrations
- Serilog → Elasticsearch → Kibana — structured logging
- BCrypt — password hashing
- JWT + Refresh tokens — authentication

**Mobile**
- Flutter (Android only)
- BLoC — state management
- SQLite (`sqflite`) — local offline storage
- `connectivity_plus` — network detection for auto-sync

**Infrastructure**
- Docker + Docker Compose — runs all services

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android emulator (API 34, arm64) or physical device
- OMDb API key — get one free at [omdbapi.com](https://www.omdbapi.com/apikey.aspx)

---

## How to Run

### 1. Configure environment variables

Create a `.env` file in the project root:

```
OMDB_API_KEY=your_omdb_key_here
JWT_KEY=your-secret-key-minimum-32-characters
```

### 2. Start the backend

```bash
docker compose up -d
```

This starts four services:

| Service | URL |
|---|---|
| API | http://localhost:5001 |
| PostgreSQL | localhost:5432 |
| Elasticsearch | http://localhost:9200 |
| Kibana | http://localhost:5601 |

The database schema is created automatically on first startup.

### 3. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

> The app connects to `10.0.2.2:5001` which maps to `localhost` on the Android emulator.  
> For a physical device, update `baseUrl` in `mobile/lib/core/constants/api_constants.dart` to your machine's local IP.

---

## API Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | Open | Register a new user |
| POST | `/auth/login` | Open | Login, returns JWT |
| POST | `/auth/refresh` | Open | Refresh access token |
| POST | `/auth/revoke` | Open | Revoke refresh token |
| GET | `/movies` | JWT | List stored movies (paginated) |
| GET | `/movies?search=X` | JWT | Search OMDb and store results |
| GET | `/movies/{imdbId}` | JWT | Get movie detail |
| GET | `/favorites` | JWT | Get user's favorites |
| POST | `/favorites/{imdbId}` | JWT | Add to favorites |
| DELETE | `/favorites/{imdbId}` | JWT | Remove from favorites |

---

## Functionalities

### Authentication
- Register with username, email, and password
- Login returns a short-lived JWT access token and a refresh token
- Access token is sent as a Bearer header on all protected requests
- When the access token expires, the mobile client automatically refreshes it silently
- Logout clears all tokens from the device

### Movies
- Search for movies by title — results are fetched from the OMDb API and stored in PostgreSQL
- Browse all previously fetched movies (paginated)
- View full movie details: poster, rating, genre, director, actors, plot

### Favorites
- Add or remove any movie from favorites
- Favorites are stored locally in SQLite immediately (offline-first)
- When offline: favorites load from local storage, add/remove actions are queued
- When connectivity is restored: pending changes sync automatically to the server

### Offline Support
- Searched movies are cached in SQLite
- Favorites screen works with no internet connection
- Offline search filters the local cache by title

### Logging
- Every API request is logged with method, path, status code, and duration
- Logs are shipped to Elasticsearch via Serilog
- View logs in Kibana at http://localhost:5601 → Discover → `movieapp-logs-*`

---

## Project Structure

```
MovieApp/
├── MovieApp.Domain/          # Entities (User, Movie, UserFavoriteMovie)
├── MovieApp.Application/     # Services, interfaces, DTOs, exceptions
├── MovieApp.Infrastructure/  # EF Core, repositories, OMDb client, token service
├── MovieApp.API/             # Minimal API endpoints
├── MovieApp.Tests/           # Unit tests (xUnit + Moq + FluentAssertions)
├── mobile/                   # Flutter Android app
│   └── lib/
│       ├── core/             # API client, local DB, connectivity service
│       └── features/
│           ├── auth/         # Login, register (BLoC)
│           ├── movies/       # Search, detail (BLoC)
│           └── favorites/    # Favorites with offline sync (BLoC)
└── docker-compose.yml
```

---

## Running Tests

```bash
cd MovieApp.Tests
dotnet test
```

16 unit tests covering authentication, movie search, and favorites logic.

---

## AI Usage

AI assistance (Claude) was used in the following areas:

- **Flutter mobile app** — BLoC state management setup, offline-first favorites with SQLite sync logic, connectivity-aware auto-sync, and screen implementation. Flutter was a new technology in this project and AI helped accelerate the learning and implementation.
- **Serilog + Elasticsearch + Kibana** — configuring the logging pipeline, setting up the Elasticsearch sink with correct index format, and understanding how to create data views in Kibana.
- **Docker Compose** — structuring the multi-service setup with health checks and service dependencies.
- **Debugging** — AI helped identify and fix several bugs that were not immediately obvious: a nested Scaffold issue in the movie detail screen that caused rendering problems, an unhandled `AuthError` state that made the app show a loading spinner forever instead of an error message when wrong credentials were entered, and a missing try/catch in the offline search fallback that caused a crash instead of gracefully loading cached results. These were found through code review and fixed with AI assistance.

All backend architecture decisions, clean architecture layering, and core business logic were implemented and understood independently.
