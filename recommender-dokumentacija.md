# DriveOps — Recommender sistem (dokumentacija)

> Dokument opisuje stvarnu implementaciju preporuke vozača u DriveOps backendu.
> Kod: `DriveOpsAPI/DriveOps.Application/Services/DriverRecommendationService.cs`,
> `DriveOpsAPI/DriveOps.Application/DTOs/RecommendationDtos.cs`, `DriveOpsAPI/DriveOps.API/Controllers/TripController.cs`.

## 1. Svrha

Recommender podržava **dispatchera/admina** u management aplikaciji pri dodjeli vozača na
zahtjev za vožnju (`POST /api/trip/{id}/assign`). Za odabranu vožnju u statusu
`Requested` ili `NoDriverAvailable` vraća rangiranu listu kandidata
(`GET /api/trip/{id}/recommended-drivers?count=5`), tako da dispečer ne mora ručno
pretraživati sve vozače. Preporuka je **objašnjiva**: svaki kandidat nosi komponente
skora (blizina i rejting), a management UI ih prikazuje kao liniju „Why: …“.

## 2. Ulazni podaci

Svi signali se čitaju iz MySQL baze (`200081_api`), iz tabele `Drivers`:

| Signal | Kolona | Gdje se upisuje u aplikaciji |
|---|---|---|
| Trenutna GPS lokacija | `CurrentLatitude`, `CurrentLongitude`, `LastLocationUpdate` | `PATCH /api/driver/{id}/location` (`DriverService.UpdateDriverLocationAsync`) i Realtime GPS tok: `LocationHub.SendDriverLocation` → `driver.location.received` → `DriverLocationReceivedConsumer` (API) perzistira lokaciju. Mobilna aplikacija šalje GPS dok je vožnja aktivna (geolocator, filter 25 m). |
| Online status | `IsOnline` | `PATCH /api/driver/{id}/status` (`DriverService.SetDriverOnlineStatusAsync`) — vozač uključuje/isključuje dostupnost u mobilnoj aplikaciji; objavljuje `driver.availability`. |
| Životni status | `Status` | `POST /api/driver/{id}/activate`, `/suspend`, onboarding/promote (novi vozači su `Pending` dok ih dispečer ne odobri). |
| Rejting | `Rating` | Perzistirana kolona profila vozača; puni se pri kreiranju/seed-u (demo podaci) i predstavlja prosječnu ocjenu vozača. Ocjene pojedinačnih vožnji se upisuju u `Trips.CustomerRating` / `Trips.DriverRating` preko `POST /api/trip/{id}/rate` (`TripService.RateTripAsync`). |
| Broj vožnji | `TotalTrips` | Inkrementira se u `TripService.CompleteTripAsync` pri završetku vožnje. |

Napomena: lokacija je jedini signal koji se mijenja u realnom vremenu tokom rada
aplikacije; rejting i `TotalTrips` su perzistirane vrijednosti profila. Zato se
preporuke računaju **na zahtjev** (nema keširanja), nad svježim podacima iz baze.

## 3. Hard filteri

Prije bodovanja kandidati moraju zadovoljiti sve uslove:

1. **Stanje vožnje** — preporuke se vraćaju samo za vožnje u statusu `Requested`
   ili `NoDriverAvailable`; u suprotnom servis baca `InvalidOperationException`
   (kontroler → 400).
2. **Dostupnost** — `IDriverRepository.GetNearbyDriversAsync` vraća samo vozače sa
   `IsOnline == true` i `Status == Active`, koji imaju GPS koordinate. Vozači na
   vožnji (`OnTrip`) su po konstrukciji isključeni.
3. **Radijus 10 km** — kandidati moraju biti unutar 10 km od pickup tačke
   (`SearchRadiusKm = 10`), računato Haversine formulom (`GeoHelper.DistanceKm`).
4. **Fallback** — ako unutar 10 km nema kandidata, koristi se
   `GetAvailableDriversAsync()` (svi online/aktivni vozači), pa preporuka nikad nije
   prazna zbog samog radijusa.
5. **Vozilo za dodjelu** — svaki kandidat se obogaćuje prvim vozilom u statusu
   `Available` (`VehicleId`, `VehiclePlate`). Bez vozila dugme za dodjelu je
   onemogućeno u UI-ju.

## 4. Formula bodovanja

Za svakog kandidata:

```
distanceScore = max(0, 1 − distanceKm / 10)          // 0–1; null ako nema GPS-a
ratingScore   = (rating ?? 5.0) / 5                   // 0–1
score         = 0.6 · distanceScore + 0.4 · ratingScore
```

Kandidati se sortiraju opadajuće po `score` i vraća se top `count` (1–20, default 5).

**Zašto težine 0.6 / 0.4?**

- **Blizina (0.6)** dominira jer direktno određuje vrijeme dolaska vozača po
  korisnika (ETA) i najveći je operativni trošak kod ride-hailinga. Vozač udaljen
  1 km praktično je bolji izbor od vozača udaljenog 9 km čak i uz nešto slabiji rejting.
- **Rejting (0.4)** razbija izjednačenja među bliskim kandidatima i nagrađuje
  kvalitet usluge. Dovoljno je jak da istakne odličnog vozača, ali ne može sam
  nadjačati veliku razliku u udaljenosti.
- Zbir težina je 1.0, pa je `score` uvijek u intervalu 0–1 i direktno se prikazuje
  kao progress bar u management UI-ju.

## 5. Primjer iz Mostar demo seed-a

Seed (`SeedData.SeedAsync`) ima tačno dva rezervabilna vozača:

| Vozač | Udaljenost od centra | Rejting | distanceScore | ratingScore | score |
|---|---|---|---|---|---|
| Marcus Johnson | ~0.6 km | 4.90 | 1 − 0.6/10 = **0.94** | 4.90/5 = **0.98** | 0.6·0.94 + 0.4·0.98 = **0.956** |
| Sarah Williams | ~9.0 km | 4.85 | 1 − 9/10 = **0.10** | 4.85/5 = **0.97** | 0.6·0.10 + 0.4·0.97 = **0.448** |

Marcus je rangiran prvi (0.956 > 0.448): blizina prevladava, iako Sarah ima
praktično isti rejting. David (offline), Emily (`Inactive`) i James (`Suspended`)
ne prolaze tvrdi filter dostupnosti.

## 6. Objašnjive preporuke (explainability)

`RecommendedDriverDto` (API) i `RecommendedDriver` (Flutter model) nose komponente
skora pored konačnog `score`:

```json
{
  "driverId": "...",
  "driverName": "Marcus Johnson",
  "rating": 4.90,
  "distanceKm": 0.6,
  "distanceScore": 0.94,
  "ratingScore": 0.98,
  "score": 0.956
}
```

Management UI (`recommended_drivers_section.dart`, kartica vozača) prikazuje:

```
Why: 94% proximity (0.6 km) · 98% rating (4.9★) → score 0.96
```

Time korisnik (dispečer) vidi **zašto** je neki vozač preporučen, a ne samo
rangirani redni broj. `distanceScore` je `null` kada vozač nema GPS fix, pa UI
prikazuje „no GPS“.

## 7. Ograničenja i budući signali

- **Rejting se ne rekalkuliše automatski** iz pojedinačnih ocjena vožnji u ovoj
  verziji; koristi se perzistirana vrijednost `Drivers.Rating`. Prirodno proširenje
  je agregacija `Trips.CustomerRating` po vozaču nakon `RateTrip`.
- **Nema istorije prihvatanja** — stopa prihvatanja/odbijanja (`trip.declined`) i
  prosječno vrijeme do dolaska nisu uključeni u skor.
- **Nema predikcije saobraćaja** — udaljenost je Haversine (prava linija), ne OSRM
  vrijeme vožnje; OSRM se koristi za estimate fare/distance, ali ne u samom skoru.
- Fallback na sve dostupne vozače može vratiti kandidate dalje od 10 km; to je
  namjerno (dostupnost ispred radijusa), ali UI to jasno prikazuje kroz `distanceKm`.

## 8. Glavna logika (tok izvršavanja)

Implementacija je u `DriverRecommendationService.GetRecommendedDriversAsync`
(`DriveOpsAPI/DriveOps.Application/Services/DriverRecommendationService.cs`), a
poziva se iz `TripController.GetRecommendedDrivers` na ruti
`GET /api/trip/{id}/recommended-drivers?count=5` (samo role `admin` i `dispatcher`).

### 8.1 Koraci algoritma

1. **Učitaj vožnju**
2. **Provjeri stanje**
3. **Pripremi filter radijusa** — `SearchRadiusKm = 10`. Repozitorij
   `GetNearbyDriversAsync` prvo radi **bounding-box prefiltriranje** a zatim servis računa
   **tačnu Haversine udaljenost** (`GeoHelper.DistanceKm`).
4. **Učitaj kandidate** — `GetNearbyDriversAsync` vraća samo `IsOnline == true`,
   `Status == Active`, sa postavljenim koordinatama, unutar bounding boxa, najviše
   `pageSize = 50` vozača. Vozači bez GPS-a i vozači koji nisu aktivni/online su
   isključeni već u SQL upitu.
5. **Fallback** — ako lista kandidata iz koraka 4 nije prazna, koristi se ona. Ako
   jeste prazna, poziva se `GetAvailableDriversAsync()` (svi online/aktivni vozači,
   takođe do 50) i nastavlja se sa tom listom.
6. **Bodovanje** — za svakog kandidata (`Select`):
   - ako ima koordinate: `distanceKm = Haversine(...)`,
     `distanceScore = max(0, 1 − distanceKm / 10)`;
   - ako nema koordinata: `distanceKm = null`, `DistanceScore = null` (u praksi se
     ne pojavljuje jer `GetNearbyDriversAsync` zahtijeva koordinate, ali fallback
     `GetAvailableDriversAsync` može vratiti vozača bez GPS-a);
   - `ratingScore = (Rating ?? 5.0) / 5.0`;
   - `score = 0.6 · distanceScore + 0.4 · ratingScore`.
7. **Sortiraj i ograniči** — `OrderByDescending(Score).Take(count)`. Kontroler
   prosljeđuje `Math.Clamp(count, 1, 20)`, pa je izlaz između 1 i 20 kandidata
   (default 5).
8. **Obogati vozilom** — za svakog vraćenog kandidata poziva se
   `GetWithVehiclesAsync(driverId)` i bira prvo vozilo sa
   `VehicleStatus.Available`; ako ga nema, `VehicleId`/`VehiclePlate` ostaju `null`.
9. **Vrati DTO listu** — `RecommendedDriverDto` nosi `DistanceKm`, `DistanceScore`,
   `RatingScore`, `Score`, `VehicleId` i `VehiclePlate` (vidi sekciju 6).

### 8.2 Pseudokod

```text
GetRecommendedDriversAsync(tripId, count):
    trip = tripRepo.GetByIdAsync(tripId) or throw NotFound

    if trip.TripStatus not in {Requested, NoDriverAvailable}:
        throw InvalidOperation("Trip is not in an assignable state.")

    candidates = driverRepo.GetNearbyDriversAsync(
        trip.PickupLatitude, trip.PickupLongitude, radiusKm = 10)

    if candidates is empty:
        candidates = driverRepo.GetAvailableDriversAsync()

    scored = []
    for driver in candidates:
        distanceKm = null
        distanceScore = 0

        if driver.CurrentLatitude != null and driver.CurrentLongitude != null:
            distanceKm = Haversine(driver.location, trip.pickup)
            distanceScore = max(0, 1 - distanceKm / 10)

        ratingScore = (driver.Rating ?? 5.0) / 5.0
        score = 0.6 * distanceScore + 0.4 * ratingScore

        scored.add(RecommendedDriverDto(driver, distanceKm,
                    distanceScore or null, ratingScore, score))

    scored = scored.OrderByDescending(Score).Take(count)

    for dto in scored:
        driver = driverRepo.GetWithVehiclesAsync(dto.DriverId)
        vehicle = driver.Vehicles.FirstOrDefault(v => v.Status == Available)
        if vehicle != null:
            dto.VehicleId = vehicle.Id
            dto.VehiclePlate = vehicle.LicensePlate

    return scored
```

### 8.3 Napomene o implementaciji

- **Nema keširanja** — svaki poziv ponovo čita bazu, pa je preporuka uvijek nad
  svježim lokacijama i statusima.
- **Dva nivoa filtriranja udaljenosti** — bounding box u repozitoriju je samo
  jeftin prefiltar; konačna udaljenost i `distanceScore` uvijek se računaju tačno
  Haversine formulom u servisu.
- **Maksimalno 50 kandidata po upitu** — i `GetNearbyDriversAsync` i
  `GetAvailableDriversAsync` koriste default `pageSize = 50`. U rijetkim slučajevima
  sa više dostupnih vozača, ostatak se ne razmatra.
- **N+1 upit za vozila** — `GetWithVehiclesAsync` se poziva u petlji za svakog
  vraćenog kandidata; prihvatanje ovog troška je namjerno jer je `count` mali
  (default 5), a pojednostavljuje obogaćivanje vozilom.
- **Fallback ne ponavlja radijus** — kada se koristi `GetAvailableDriversAsync`,
  kandidati mogu biti i dalje od 10 km; tada `distanceScore` može biti 0, ali
  kandidat ostaje u listi (dostupnost ispred radijusa).
