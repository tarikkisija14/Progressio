# Dokumentacija sistema preporuke — Progressio

## 1. Pregled

Progressio sistem preporuke je hibridni content-based/popularity-based engine implementiran unutar ASP.NET Core 9 backenda. Cilj sistema je predložiti korisniku sadržaj (filmove, serije, knjige, anime i sl.) koji još nije pratio, a koji odgovara njegovim ukusima na osnovu prethodne aktivnosti.

Sistem automatski odabire jedan od dva algoritma ovisno o statusu pretplate korisnika:

- **Free korisnici** → algoritam baziran na popularnosti
- **Premium korisnici** → hibridni algoritam sa šest signala

---

## 2. Arhitektura

### 2.1. Backend komponente

| Klasa/fajl | Uloga |
|---|---|
| `RecommenderService.cs` | Srž sistema — sadrži oba algoritma i sve pomoćne metode |
| `IRecommenderService.cs` | Interfejs koji se injektuje u controller |
| `RecommenderController.cs` | REST endpoint koji poziva servis |
| `RecommendationLog.cs` | Entitet za perzistenciju svake preporuke u bazi |
| `RecommendationResponse.cs` | DTO koji se šalje klijentu |

### 2.2. Mobile (Flutter) komponente

| Klasa/fajl | Uloga |
|---|---|
| `RecommendationProvider` | Provider koji poziva `/api/recommendations` endpoint |
| `Recommendation` (model) | Dart model koji mapira `RecommendationResponse` |

### 2.3. API endpoint

```
GET /api/recommendations?count={n}
Authorization: Bearer {token}
```

- `count` — broj preporuka (1–100, podrazumijevano 20)
- Endpoint zahtijeva autentifikovanu sesiju; userId se čita iz JWT tokena

---

## 3. Algoritmi

### 3.1. Algoritam baziran na popularnosti (Free korisnici)

Primjenjuje se kada korisnik nema aktivnu Premium pretplatu.

**Logika:**
1. Iz baze se učitava skup `contentId`-eva koje korisnik već prati (`UserContentProgress`)
2. Kandidati su svi aktivni sadržaji koji nisu u tom skupu i imaju barem jednu ocjenu
3. Svaki kandidat dobija `popularityScore` po formuli:

```
popularityScore = min( avgRating × ln(totalRatings + 1) / 50 , 1.0 )
```

Logaritam štiti od pretjeranog nagrađivanja sadržaja s jednom visokom ocjenom — sadržaj mora imati i kvantitet recenzija.

4. Rezultati se sortiraju po scoru silazno, vraća se top N
5. `ExplanationText`: `"Highly rated by the community (X.X/5, N ratings)"`

---

### 3.2. Hibridni algoritam (Premium korisnici)

Koristi se za korisnike s aktivnom Premium pretplatom. Sastavljen je od šest signala koji se kombinuju linearnom kombinacijom s fiksnim težinama:

| # | Signal | Težina | Izvor podataka |
|---|---|---|---|
| 1 | **Genre match** | 30% | `UserContentProgress` (completed + in-progress) |
| 2 | **Popularity** | 20% | `AvgRating` + `TotalRatings` na sadržaju |
| 3 | **Completion rate** | 15% | Stopa završenosti po žanru iz korisnikovog historijata |
| 4 | **Search affinity** | 18% | `SearchLog` — žanrovi pretraživani u posljednjih 30 dana |
| 5 | **Character vote** | 12% | `CharacterVote` — žanrovi sadržaja čije je likove korisnik ocjenjivao |
| 6 | **Freshness** | 5% | Godina izdanja sadržaja |

**Ukupna formula:**

```
totalScore = 0.30 × genreMatch
           + 0.20 × popularity
           + 0.15 × completionRate
           + 0.18 × searchAffinity
           + 0.12 × characterVote
           + 0.05 × freshness
```

---

## 4. Detaljan opis signala

### Signal 1 — Genre match (30%)

Iz `UserContentProgress` tabele se uzimaju svi sadržaji sa statusom `Completed` ili `InProgress`. Svaki žanr tog sadržaja dobija težinu:
- `Completed` → težina 2.0
- `InProgress` → težina 1.0

Zbroj po žanrovima se normalizuje na [0, 1] dijeljenjem s maksimalnom vrijednosti. Kandidatu se računa prosječni žanr-match score:

```
genreMatchScore = Σ(userWeight[genreId]) / broja_žanrova_sadržaja   (max 1.0)
```

### Signal 2 — Popularity (20%)

Ista formula kao kod free korisnika:

```
popularityScore = min( avgRating × ln(totalRatings + 1) / 50 , 1.0 )
```

### Signal 3 — Completion rate (15%)

Za svaki žanr se računa stopa završenosti iz korisnikovog historijata:

```
completionRate[genre] = completed_count / total_count
```

Ovaj signal je multiplikator genre match scorea:

```
completionRateScore = genreMatchScore × (0.5 + avgCompletionRateForCandidateGenres)
```

Faktor `0.5 +` znači da čak i žanrovi s niskom stopom završenosti ne dobijaju nulu.

### Signal 4 — Search affinity (18%)

Iz `SearchLog` tabele uzimaju se svi upiti korisnika u posljednjih 30 dana koji imaju asocirane žanrove (`GenreIds` kolona, serializovana kao JSON niz). Frekvencija pojavljivanja žanrova se normalizuje na [0, 1].

### Signal 5 — Character vote (12%)

Iz `CharacterVote` tabele se prikupljaju svi sadržaji čijim je likovima korisnik glasao. Žanrovi tih sadržaja se broje i normalizuju na [0, 1], analogno Signal 1.

### Signal 6 — Freshness (5%)

```
freshnessScore = max( 0.9^(currentYear - releaseYear) , 0.1 )
```

Eksponencijalni pad — sadržaj star jednu godinu ima score ~0.9, star deset godina ~0.35, stariji nikad ne pada ispod 0.1.

---

## 5. Explainability (objašnjivost)

Svaka preporuka nosi `ExplanationText` — kratki tekst koji objašnjava zašto je sadržaj preporučen. Tekst se generiše automatski na osnovu **dominantnog signala** (onaj koji je najviše doprinio ukupnom scoru):

| Dominantni signal | Tekst |
|---|---|
| Genre match | "Recommended based on genres you enjoy watching or reading" |
| Popularity | "Highly rated by the community (X.X/5, N ratings)" |
| Completion rate | "Recommended because you consistently finish this type of content (N% completion rate)" |
| Search affinity | "Matches your recent search interests" |
| Character vote | "Based on characters you have voted for" |
| Freshness | "Recently released content you might enjoy" |

---

## 6. Logiranje preporuka

Svaka generisana preporuka se upisuje u `RecommendationLog` tabelu s podacima:

| Kolona | Opis |
|---|---|
| `UserId` | ID korisnika |
| `ContentId` | ID preporučenog sadržaja |
| `Algorithm` | `"popularity"` ili `"hybrid"` |
| `Score` | Izračunati skor (4 decimale) |
| `ExplanationText` | Tekst objašnjenja |
| `ShownAt` | Timestamp generisanja |
| `ClickedAt` | (opcionalno) Timestamp klika korisnika |
| `ProgressStartedAt` | (opcionalno) Timestamp kad je korisnik počeo pratiti |

---

## 7. Zaštita od ponavljanja

Sistem uvijek isključuje sadržaje koje korisnik već prati. Na početku svakog poziva učitava se skup `contentId`-eva iz `UserContentProgress` za datog korisnika, i svi kandidati koji se u njemu nalaze se odbacuju.

---

## 8. Skalabilnost i ograničenja

- Algoritam radi **in-memory** scoringom nad skupom kandidata učitanim iz baze — pogodan za manje i srednje skupove podataka.
- Za veće kataloge preporučuje se uvođenje pretprocesiranja ili caching sloja.
- `SearchLog` signal koristi prozor od 30 dana — stariji upisi se zanemaruju.
