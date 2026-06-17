# Progressio

> Content Progress · Recommender · Statistics · Social  
> Software Development II — FIT 2025/26

## Stack

| Layer | Technology |
|---|---|
| Backend | .NET 9 / ASP.NET Core 9 / EF Core 9 |
| Frontend | Flutter 3.x (Android + Windows) |
| Database | SQL Server 2022 (Docker) |
| Messaging | RabbitMQ 3.13 (Docker) |
| Auth | ASP.NET Identity + JWT + Refresh Tokens |
| Real-time | SignalR |
| Payments | Stripe Sandbox |
| Deployment | Docker + docker-compose |

---

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Flutter SDK 3.x](https://flutter.dev/docs/get-started/install)
- [Visual Studio 2022/2026](https://visualstudio.microsoft.com/) (for backend)
- [Visual Studio Code](https://code.visualstudio.com/) (for Flutter)

Each GitHub Release contains:
- `Progressio-android.apk` — Flutter Android build
- `Progressio-windows.zip` — Flutter Windows Release folder

---

## Running the backend (Docker)

The backend (API + Worker + SQL Server + RabbitMQ) is fully containerized and is the recommended way to run the project for review.

1. Copy the environment template and fill in real values (a working `.env` is also delivered separately as an encrypted `.env-tajne.zip`, see the submission notes for the password):
   ```bash
   cd Progressio_backend
   cp .env.example .env
   ```
2. Start all services:
   ```bash
   docker compose up --build
   ```
3. On first start, the API automatically applies EF Core migrations and seeds lookup data, roles and demo users — no manual DB setup is required.
4. Once the containers are healthy:
   - API base URL: `http://localhost:5193/api/`
   - Swagger UI (Development environment only): `http://localhost:5193/swagger`
   - RabbitMQ management UI: `http://localhost:15672` (user/password from `RABBITMQ_USER` / `RABBITMQ_PASS` in `.env`)
   - SQL Server: `localhost,1433` (user `sa`, password from `DB_PASSWORD` in `.env`)

To stop everything: `docker compose down` (add `-v` to also drop the database/RabbitMQ volumes).

### Running the backend without Docker (Visual Studio / `dotnet run`)

This is only needed for development; it is **not** required to review the submission.

1. Make sure a local SQL Server and RabbitMQ instance are reachable, and that `Progressio_backend/.env` contains valid connection details (the API reads `.env` from the solution root automatically on startup).
2. Run the API from `Progressio_backend/Progressio.WebApi`:
   ```bash
   dotnet run
   ```
   By default this listens on `http://localhost:5193`.
3. Run the Worker from `Progressio_backend/Progressio.Worker`:
   ```bash
   dotnet run
   ```

---

## Running the desktop app (Windows / Flutter)

```bash
cd ui/progressio_desktop
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5193/api/
```

## Running the mobile app (Android / Flutter)

Against the Android emulator (AVD), the API must be reached through the standard emulator host alias `10.0.2.2`:

```bash
cd ui/progressio_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5193/api/ --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
```

`STRIPE_PUBLISHABLE_KEY` must match the `STRIPE_PUBLISHABLE_KEY` configured on the backend (`.env`) for the in-app Stripe Payment Sheet (Premium subscription) to work.

---

## Demo credentials

The database is seeded automatically on first run of the API. The following accounts are available out of the box:

| Context | Username | Password | Role |
|---|---|---|---|
| Desktop app (admin panel) | `admin` | `Admin123!` | Admin |
| Mobile app (regular user) | `amar.hodzic` | `amar1234` | User |
| Additional regular users | `lejla.kovac` / `tarik.begic` / `amina.sarajlic` / `nedim.causevic` | `User1234!` | User |

The desktop app only allows sign-in for accounts with the `Admin` role; the mobile app is intended for `User` accounts.
