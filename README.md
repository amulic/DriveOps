# DriveOps — cjeloviti vodič za testiranje funkcionalnosti

> Napomena: u repozitoriju **nema automatiziranih .NET testova** (nema test projekata), a Flutter ima samo jedan smoke test (`driveops_management/test/widget_test.dart`). Zato je najveći dio testiranja **ručno / end-to-end**. Na kraju dokumenta su i prijedlozi automatizacije.

---

## 1. Arhitektura koju testirate

| Dio | Tehnologija | Port | Što testirati |
|---|---|---|---|
| `DriveOpsAPI` | .NET 8 REST | 5032 | CRUD, trip lifecycle, plaćanja, preporuke, geocoding |
| `DriveOpsRealtime` | .NET 8 SignalR + REST | 5033 | GPS, chat, notifikacije, RabbitMQ eventi |
| `driveops_management` | Flutter desktop | — | admin/dispatcher UI |
| `driveops_mobile` | Flutter Android | — | driver i customer tok |
| Keycloak | OIDC | 8081 | login, role, self-signup |
| MySQL | 8.0 | 3306 | perzistencija (`200081_api`, `200081_realtime`, `keycloak`) |
| RabbitMQ | 3.13 | 5672 / UI 15672 | async eventi |
| Adminer | web DB UI | 8089 | provjera podataka u bazi |

---

## 2. Priprema okruženja

### 2.1 Preduvjeti

- Docker Desktop
- .NET 8 SDK
- Flutter SDK
- Stripe CLI (`stripe login` jednom)
- Android SDK + `adb` (za mobile)
- `DriveOpsAPI/.env` (iz `.env-tajne.zip`, lozinka `fit`)
- `driveops_mobile/stripe_keys.json` s `pk_test_...`

### 2.2 Pokretanje cijelog sandboxa

```powershell
# prvi put na računalu
pwsh scripts/start-sandbox.ps1 -StripeSecretKey sk_test_...

# kasnije
pwsh scripts/start-sandbox.ps1
```

Skripta redom diže: Docker infra → čeka Keycloak realm → pokreće `stripe listen` i hvata `whsec_` → API → Realtime → `adb reverse` → mobile + desktop.

### 2.3 Ručno pokretanje (ako ne koristite skriptu)

```powershell
cd DriveOpsAPI
docker compose up -d

dotnet run --project DriveOps/            # :5032
dotnet run --project ..\DriveOpsRealtime\DriveOpsRealtime/   # :5033

cd ..\driveops_management
flutter run -d windows

cd ..\driveops_mobile
flutter run --dart-define-from-file=stripe_keys.json --dart-define=API_HOST=localhost
```

### 2.4 Adrese za provjeru

- Swagger: `http://localhost:5032/swagger/index.html`
- Realtime health/debug: `http://localhost:5033/api/chat/debug`
- Keycloak: `http://localhost:8081` (realm `driveops-dev`)
- RabbitMQ UI: `http://localhost:15672`
- Adminer: `http://localhost:8089`
- Stripe webhook log: `.sandbox/stripe-listen.log`

### 2.5 Sandbox korisnici

U sandboxu su lozinke jednake korisničkom imenu:

| Korisnik | Rola | Namjena |
|---|---|---|
| `admin` | admin | management |
| `dispatcher` | dispatcher | management |
| `marcusjohnson` | driver | dostupan, blizu centra (~0,6 km) |
| `sarahwilliams` | driver | dostupan, ~9 km |
| `davidchen` | driver | offline |
| `emilyrodriguez` | driver | Inactive |
| `jamesbrown` | driver | Suspended |
| `johndoe` | customer | demo kupac |
| `janesmith` | customer | kupac |
| `bobwilson` | customer | ima seedanu `Requested` vožnju |

### 2.6 Reset podataka

```powershell
cd DriveOpsAPI
docker compose down -v
docker compose up -d
```

(`down -v` je obavezan jer se Keycloak realm i MySQL inicijalizacija rade samo na svježem volumenu.)

---

## 3. Testiranje autentifikacije i autorizacije

### 3.1 Dobivanje tokena za REST testove

```powershell
$body = @{
  grant_type    = 'password'
  client_id     = 'driveops-backend'
  client_secret = '<DRIVEOPS_BACKEND_CLIENT_SECRET iz .env>'
  username      = 'admin'
  password      = 'admin'
  scope         = 'openid profile email roles'
}
$tok = Invoke-RestMethod -Method Post `
  -Uri 'http://localhost:8081/realms/driveops-dev/protocol/openid-connect/token' `
  -Body $body
$h = @{ Authorization = "Bearer $($tok.access_token)" }

Invoke-RestMethod 'http://localhost:5032/api/user/me' -Headers $h
```

Očekivano: `200` i decoded JWT claimovi (`sub`, `preferred_username`, role).

> Ako je password grant onemogućen, koristite token iz Flutter aplikacije ili Authorization Code tok. **Pazite:** `admin-cli` tokeni nemaju `realm_access` i zato daju `403` na role-gated endpointima.

### 3.2 Što provjeriti

- **Bez tokena** → `401` na svim `[Authorize]` endpointima.
- **Pogrešna rola** (npr. customer zove admin endpoint) → `403`.
- **Samo `POST /api/payment/webhook`** je anoniman (`[AllowAnonymous]`), ali mora proći Stripe potpis; bez potpisa → `400`.
- **Vlasništvo** se uvijek izvodi iz `sub`, ne iz body/route:
  - customer može kreirati vožnju samo za sebe (`POST /api/trip`, `customerId` mora odgovarati),
  - customer profil: `POST /api/customer` samo ako `keycloakId == sub`,
  - vožnju smije započeti/završiti/odbitti samo dodijeljeni vozač,
  - `start/complete/decline` **ne dopuštaju** management roli.
- **Self-signup rola:** novi Keycloak korisnik dobiva `customer` (default role). Provjerite da mobile routa ide u customer dio.

---

## 4. REST API — po funkcionalnostima

### 4.1 `UserController`

- `GET /api/user/me` → `200`, vraća claimove bez DB pristupa.
- Provjeriti da nema tablice `Users` i da podaci dolaze isključivo iz JWT-a.

### 4.2 `CustomerController`

| Test | Očekivano |
|---|---|
| `GET /api/customer/{id}` kao vlasnik | `200` |
| isto kao drugi customer | `403` |
| kao admin/dispatcher | `200` |
| `GET /api/customer/keycloak/{keycloakId}` | `200` za sebe/management |
| `POST /api/customer` s tuđim `keycloakId` | `403` |
| `POST /api/customer` bez `phoneNumber` | `400` |
| `PUT /api/customer/{id}` (prazan email) | `200`, email ostaje nepromijenjen |

### 4.3 `DriverController`

**CRUD i liste**

- `GET /api/driver` (admin/dispatcher) → paginirana lista.
- `GET /api/driver/available` → samo `IsOnline && Status == Active`.
- `GET /api/driver/nearby?lat=..&lng=..&radiusKm=..` → bounding-box filtrirani vozači.
- `GET /api/driver/{id}` / `GET /api/driver/keycloak/{id}` → self ili management.
- `POST /api/driver`:
  - validan payload → `201/200`, novi vozač je **`Pending`**;
  - duplikat `KeycloakId` → `409`;
  - istekao `LicenseExpiryDate` → `400`;
  - nevalidan email / kratak telefon → `400`.
- `PUT /api/driver/{id}` → management.
- `POST /api/driver/{id}/suspend` → `Suspended`.
- `POST /api/driver/{id}/activate` → `Active` (ujedno „Approve“ za Pending).

**Lokacija i online status**

- `PATCH /api/driver/{id}/location` kao sam vozač → `200`; provjeriti da se koordinate upišu i da se objavi `driver.location`.
- `PATCH /api/driver/{id}/status` (`isOnline`) → `200`; objavljuje `driver.availability`.
- Kao drugi vozač → `403`; kao management → dopušteno.

**Kandidati / promote / onboard**

- `GET /api/driver/candidates?search=...`:
  - vraća Keycloak korisnike, isključuje service accounte,
  - svaki ima `realmRoles` i `hasDriverProfile`,
  - postojeći vozači su označeni/disabled u UI-ju.
- `POST /api/driver/promote`:
  - validan postojeći Keycloak korisnik → vozač `Pending`,
  - duplikat → `409`,
  - nepostojeći Keycloak korisnik → `404`,
  - nevalidan payload → `400`,
  - Keycloak admin greška → `502`.
- `POST /api/driver/onboard`:
  - kreira novog Keycloak korisnika s privremenom lozinkom + lokalni profil,
  - postojeći username/email → `409`,
  - prekratka lozinka (<8) → `400`,
  - greška Keycloak admin API-ja → `502`.

### 4.4 `VehicleController`

- `GET /api/vehicle?page=1&pageSize=20` → envelope `{items,totalCount,page,pageSize,totalPages,hasNextPage,hasPreviousPage}`; `pageSize` clamp 1–100.
- `GET /api/vehicle/available` → samo `Available`.
- `GET /api/vehicle/{id}` → bilo koji autentificirani.
- `POST /api/vehicle` (admin/dispatcher):
  - validan payload → uspjeh;
  - VIN ≠ 17 znakova → `400`;
  - godina izvan 1900..(tekuća+1) → `400`;
  - duplikat registracije/VIN-a → `409`.
- `PUT` / `DELETE` → admin/dispatcher.
- `POST /api/vehicle/{id}/assign`:
  - dodjela vozaču → `200`;
  - `Retired` vozilo → odbijeno;
  - vozač koji već ima vozilo → drugo se automatski unassigna (jedno vozilo po vozaču);
  - objavljuje `vehicle.assigned`.
- `POST /api/vehicle/{id}/unassign` → objavljuje `vehicle.unassigned`.
- `POST /api/vehicle/{id}/defects` → vozač tog vozila ili management; objavljuje `vehicle.defect.reported`.
- `GET /api/vehicle/{id}/defects` → paginirano; vozač tog vozila ili management.

### 4.5 `TripController` — srce sustava

**Estimate (bez kreiranja vožnje)**

```powershell
$est = @{
  pickupLatitude=43.3438; pickupLongitude=17.8078
  dropoffLatitude=43.3500; dropoffLongitude=17.8200
  tripType=1
} | ConvertTo-Json
Invoke-RestMethod 'http://localhost:5032/api/trip/estimate' -Method Post -Headers $h -ContentType 'application/json' -Body $est
```

- `200` s `distanceKm`, `durationMinutes`, `estimatedFare`.
- Nevalidne koordinate → `400`.
- Pad OSRM-a → `502`.

**Kreiranje vožnje**

- `POST /api/trip` kao customer za sebe → `201/200`, status `Requested`, `PaymentStatus=Pending`, objavljuje `trip.requested`.
- `customerId` tuđi → `403`.
- Customer već ima aktivnu vožnju (`Requested/Assigned/DriverEnRoute/InProgress`) → `409`.
- Card/DebitCard bez spremljene kartice → `400`.
- Preduga adresa (>500) / prazna adresa → `400`.
- Pad OSRM-a → `502`.

**Lifecycle (testirati strogo redom)**

1. `GET /api/trip/{id}/recommended-drivers?count=5` (admin/dispatcher) → rangirana lista; provjeriti `score`, `distanceScore`, `ratingScore`, `vehicleId`, `vehiclePlate`.
   - za vožnju koja nije `Requested`/`NoDriverAvailable` → `400`.
2. `POST /api/trip/{id}/assign` (admin/dispatcher) → `Assigned`, vozač `OnTrip`, vozilo `InUse`, event `trip.assigned`.
   - vožnja nije `Requested` → `400`.
3. `POST /api/trip/{id}/start` kao dodijeljeni vozač → `InProgress`, `PickupTime` postavljen, event `trip.started`.
   - kao customer/management → `403`.
4. `POST /api/trip/{id}/route` kao vozač → dodaje route point, objavljuje `trip.route`.
5. `GET /api/trip/{id}/route` → paginirano (default 500, max 500).
6. `POST /api/trip/{id}/complete` kao vozač → `Completed`, izračunat `ActualFare`, ažurirani driver stats i kilometraža.
   - **Cash** → `PaymentStatus=Completed` odmah.
   - **Card** → ostaje `Pending`, nakon commita se izvršava off-session naplata; uspjeh → `Completed`, odbijanje → `Failed` + ledger red (vožnja se **ne** rollbacka).
   - Greška nakon commita (Stripe/publish) → endpoint i dalje vraća `200`.
7. `POST /api/trip/{id}/rate` kao učesnik → `200`; ocjena 1–5; smjer određuje `isCustomerRating`.
   - ocjena 0 ili 6 → `400`.

**Ostale akcije**

- `POST /api/trip/{id}/cancel` → customer ili management; status `Cancelled` + razlog; event `trip.cancelled`.
- `POST /api/trip/{id}/decline` → samo dodijeljeni vozač; status `Declined`, vozač `Active`, vozilo `Available`; event `trip.declined` (customer odmah dobije push).
- `GET /api/trip` → admin/dispatcher.
- `GET /api/trip/{id}` → customer/vozač te vožnje ili management.
- `GET /api/trip/customer/{id}` → self ili management.
- `GET /api/trip/driver/{id}` i `/driver/{id}/active` → self-vozač ili management; `/active` paginirano (default 20, max 100).

### 4.6 `GeocodeController`

- `GET /api/geocode/search?q=Mostar&limit=5` → top-N `{displayName, latitude, longitude}`.
- bez `q` → `400`; `limit` clamp 1–10.
- `GET /api/geocode/reverse?lat=..&lng=..` → `{displayName}`; ako ništa ne nađe → `404`.
- Pad Nominatim-a → `502`.
- Radi za svakog autentificiranog korisnika.

### 4.7 `DefectsController` (management)

- `GET /api/defects?status=&severity=&vehicleId=&driverId=&page=&pageSize=` → paginirano, otvoreni prvo pa najnoviji; DTO sadrži registraciju, interno ime i ime vozača.
- `POST /api/defects/{id}/resolve` s `{resolutionNotes}` → `Resolved`; već riješen → `400`; nepostojeći → `404`.
- `POST /api/defects/{id}/reopen` → samo ako je `Resolved`; vraća u `Reported`, briše `ResolvedAt`, čuva notes; event s `Reopened=true`.
- Provjeriti da driver-side prijava ide preko `POST /api/vehicle/{id}/defects`, ne ovdje.

### 4.8 `PaymentController` i Stripe

- `POST /api/payment/setup-intent` → `{setupIntentClientSecret, ephemeralKey, gatewayCustomerId}`; prvi put se stvara Stripe customer i upisuje `StripeCustomerId`.
- `GET /api/payment/methods` → lista `{id, brand, last4, expMonth, expYear}`.
- `DELETE /api/payment/methods/{paymentMethodId}` → `204`; tuđa kartica → odbijeno.
- `POST /api/payment/trips/{tripId}/retry`:
  - dozvoljeno samo za **vlastitu završenu** vožnju s failed/pending karticom → `200`,
  - tuđa vožnja → `403`, neispravno stanje → `400`.
- `POST /api/payment/trips/{tripId}/refund` (admin/dispatcher):
  - full/partial refund na stvarno naplaćeni iznos,
  - `amount` > preostalo → `400`; nepostojeća vožnja → `404`; Stripe odbijanje → `502` (ništa se ne upisuje),
  - full refund → trip `PaymentStatus=Refunded`.
- `POST /api/payment/webhook`:
  - bez potpisa → `400`,
  - `payment_intent.succeeded` → ledger `Completed` + trip `Completed`,
  - `payment_intent.payment_failed` → `Failed`,
  - idempotentno (ponovljeni event ne mijenja ništa),
  - nepoznat intent → `200`.

**Stripe test kartice**

| Kartica | Scenarij |
|---|---|
| `4242 4242 4242 4242` | uspjeh |
| `4000 0027 6000 3184` | 3DS |
| `4000 0000 0000 9995` | odbijanje → in-app retry |

---

## 5. Poslovna logika — ciljani testovi

### 5.1 FareCalculator

Formula:

```
fare = round((BaseFare + distanceKm * PerKmRate + durationMinutes * PerMinuteRate) * multiplier, 2)
```

- Standard: multiplier 1,0
- Premium: ×1,5
- Shared: ×0,7
- Defaulti: 2,50 / 1,50 / 0,25.
- Testirati zaokruživanje na 2 decimale i da se `estimate` i `actual` razlikuju kad stvarna kilometraža odstupa.

### 5.2 Recommender (seed primjer)

- Marcus (~0,6 km, 4,90) → score ≈ **0,956**.
- Sarah (~9 km, 4,85) → score ≈ **0,448**.
- David (offline), Emily (Inactive), James (Suspended) → ne smiju se pojaviti.
- Provjeriti „Why:“ prikaz u management UI-ju.
- Fallback: ugasiti sve vozače unutar 10 km → lista i dalje nije prazna (koristi sve dostupne).
- `count=0` → clamp na 1; `count=99` → clamp na 20.

---

## 6. Realtime — SignalR i RabbitMQ

### 6.1 Autentifikacija huba

Token se šalje kroz query string:

```
ws://localhost:5033/hubs/notifications?access_token=<JWT>
```

Bez tokena → odbijena konekcija.

### 6.2 LocationHub (`/hubs/location`)

- `SendDriverLocation(lat,lng)` → upis u cache, broadcast u `trip-location-{tripId}`, publish `driver.location.received`.
- `SubscribeToTripLocation(tripId)` → customer prima `ReceiveDriverLocation` dok je vožnja aktivna.
- `GetNearbyDrivers(lat,lng,radiusKm)` → Haversine filtrirana lista.
- **E2E test:** pokrenite driver i customer app; dok je vožnja `Assigned`, vozačev GPS se treba kretati na customer karti.

### 6.3 ChatHub (`/hubs/chat`)

- `SendTripMessage(tripId, content)` → poruka se persistira i broadcasta.
- `JoinConversation` / `LeaveConversation` / `MarkAsRead` / `GetConversation`.
- Provjeriti da se na reconnect ponovno pridružuje grupama.
- Povijest se vraća **najnovije prvo**; klijent je ne smije obrnuti.

### 6.4 NotificationHub (`/hubs/notifications`)

- `JoinAdminDashboard` radi samo za `admin`.
- `JoinAvailableDrivers` za vozače.
- Push događaji: `NewTripRequest`, `TripAssigned`, `TripStatusChanged`, `SystemNotification`, `FleetUpdate`.

### 6.5 REST na Realtimeu

- `GET /api/notifications?page=1&pageSize=20&unreadOnly=false` → `PagedNotificationsDto`.
- `POST /api/notifications/{id}/read` → `204`/`404`.
- `POST /api/notifications/read-all` → `204`.
- Chat REST endpointi → `404/403/400/500` mapiranja.

### 6.6 RabbitMQ tokovi koje treba dokazati

1. **Trip request:** mobile → `POST /api/trip` → `trip.requested` → Realtime broadcast `NewTripRequest` dostupnim vozačima.
2. **Assign:** management → `trip.assigned` → customer `TripAssigned` + auto-kreiran chat + driver `TripStatusChanged`.
3. **GPS:** driver → `LocationHub.SendDriverLocation` → `driver.location.received` → API persistira u `Drivers` i eventualno `TripRoutes`.
4. **Fleet:** assign/unassign vozila → `FleetUpdate` u `admin-dashboard`.
5. **Defects:** report/resolve/reopen → `FleetUpdate` s odgovarajućim tipom.
6. **Notifications:** svaki lifecycle event upisuje `Notifications` red za primatelja; provjeriti u Admineru i kroz REST.

---

## 7. Management desktop aplikacija (ručni scenariji)

1. **Login** s `admin/admin` → dashboard.
2. **Neautorizirani login** (customer/driver) → `/unauthorized`.
3. **Dashboard** — grafovi se učitavaju, nema grešaka u konzoli.
4. **Drivers**
   - Add → „Existing user“ → pretraga kandidata → promote.
   - Add → „New account“ → onboard s privremenom lozinkom.
   - Approve (Pending→Active), Activate (Suspended→Active), Suspend.
   - Assign Vehicle dijalog uvijek svježe učita dostupna vozila.
5. **Vehicles**
   - Add/Edit/Delete; validacije (VIN 17, godina).
   - Assign/Unassign.
   - Badge broja otvorenih defekata.
6. **Trips**
   - Row tap → detalji; refresh gumb osvježava listu.
   - Assign Driver → preporuke + „Why:“.
   - Cancel Trip s razlogom.
   - Refund za completed card payment (full/partial).
7. **Messages** — lista konverzacija, slanje poruke, realtime primanje.
8. **Defects** — filteri, Resolve s notes, Reopen, skok na vozača.
9. **Profile** — izmjena imena/emaila i lozinke preko Keycloak Account API-ja.
10. **Reconnect** — ugasiti/upaliti Realtime; UI se sam reconnecta i osvježi.

---

## 8. Mobile aplikacija

### 8.1 Driver tok

1. Login (`marcusjohnson/marcusjohnson`).
2. **Pending lockout:** novo-onboardan vozač vidi `PendingApprovalScreen`; nakon odobrenja „Check status“ otključava shell.
3. **Online toggle** → `PATCH /api/driver/{id}/status`; management ga odmah vidi kao dostupnog.
4. **Vehicle tab** → vozilo dodijeljeno u managementu; pull-to-refresh osvježava; defekti vidljivi.
5. **Nova vožnja** → stigne push/snackbar „New trip assigned“; Accept/Decline.
6. **Mapa** → GPS streaming samo dok je vožnja aktivna; Start/Complete.
7. **Chat** s customerom.
8. **History** → ocjenjivanje customerа.
9. **Notifikacije** → bell badge, označavanje pročitanog.

### 8.2 Customer tok

1. **Self-signup** preko Keycloak registracije.
2. **CustomerGate** → prvi login traži profil (ime/email prefilled, telefon obavezan) → `POST /api/customer`.
3. **Request**
   - mapa na trenutnoj poziciji,
   - tap-to-drop destinacija ili pretraga adrese,
   - estimate + preview rute,
   - odabir plaćanja (Cash/Card/Wallet); kartica bez spremljene kartice → snackbar i API `400`.
4. **Confirm** → `POST /api/trip`; ako već postoji aktivna → `409` + poruka.
5. **Trip screen** → status chip, živa lokacija vozača, vozilo/tablica, Cancel (u dozvoljenim statusima), Chat.
6. **History** → aktivna vožnja na vrhu, detalji, Rate, pull-to-refresh.
7. **Failed/pending plaćanje** → banner „Pay now“ → Stripe PaymentSheet retry.
8. **Payment methods** → dodavanje/brisanje kartica.
9. **Profil** → izmjena podataka.

---

## 9. Provjere perzistencije (Adminer / SQL)

Nakon scenarija provjeriti:

- `200081_api`: `Customers`, `Drivers`, `Vehicles`, `Trips`, `TripRoutes`, `Payments`, `VehicleDefectReports`.
- `200081_realtime`: `Conversations`, `ConversationParticipants`, `ChatMessages`, `DriverLocationCache`, `UserConnections`, `Notifications`.
- Konzistentnost: `Trips.PaymentStatus` ↔ zadnji `Payments` red; `Trips.DriverId`/`VehicleId`; `Drivers.Status`; `Vehicles.Status`.
- Zaustaviti i ponovno pokrenuti API/Realtime → podaci ostaju (nema in-memory stanja).

---

## 10. Rubni i negativni testovi

- **Jedna aktivna vožnja:** dva brza `POST /api/trip` → drugi `409`.
- **Idempotencija:** ponovljeni Stripe webhook ne mijenja stanje.
- **Concurrency:** dva assign zahtjeva na istu vožnju → samo jedan uspije.
- **Caching:** nakon mutacije u managementu lista se osvježi (driver caches se invalidiraju); „out-of-band“ DB insert zahtijeva refresh gumb na Trips.
- **Vremenske zone:** `DateTime` u notifikacijama dolazi s `Z`.
- **Enum kompatibilnost:** vrijednosti u Dart modelima moraju odgovarati .NET enumima (npr. `TripStatus.Declined = 8`).
- **Prekidi mreže:** ugasiti Keycloak/Realtime → aplikacije daju razumljive greške, ne crash.

---

## 11. Automatizirani testovi (trenutno stanje)

```powershell
# .NET build (nema test projekata)
dotnet build DriveOpsAPI/DriveOpsAPI.sln
dotnet build DriveOpsRealtime/DriveOpsRealtime.slnx

# Flutter
cd driveops_management; flutter analyze; flutter test
cd ..\driveops_mobile;     flutter analyze; flutter test
```

Trenutno postoji samo smoke test u `driveops_management/test/widget_test.dart` (provjerava login ekran). Preporuka za dalje:

- .NET: unit testovi za `FareCalculator`, `GeoHelper`, `DriverRecommendationService`; integracijski za Trip lifecycle i PaymentService (mock `IPaymentGateway`).
- Flutter: widget testovi za login, form validacije, request flow; `flutter_test` + `mocktail`.

---

## 12. Česti problemi pri testiranju

| Simptom | Uzrok / rješenje |
|---|---|
| Login ne radi odmah nakon `up` | Keycloak još importa realm (~30 s); čekajte `/realms/driveops-dev` |
| `403` na role endpointu | token bez `realm_access` (npr. `admin-cli`) |
| Mobile ne vidi API | fizički uređaj: `adb reverse` (8081/5032/5033); emulator: `10.0.2.2` |
| Stripe webhook ne radi | `stripe listen` nije pokrenut ili `whsec_` nije upisan prije starta API-ja |
| Prazni podaci | `docker compose down -v` pa ponovno `up` (seed se ne izvršava ako podaci postoje) |
| Defect/notification lista prazna | event nije prošao kroz RabbitMQ; provjerite UI i logove Realtimea |
